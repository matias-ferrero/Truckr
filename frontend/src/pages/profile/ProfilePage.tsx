import { useEffect, useMemo, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { ApiError } from "../../api";
import { useCurrentUser } from "../../auth/useCurrentUser";
import { Alert } from "../../components/ui/alert";
import { Button } from "../../components/ui/button";
import { FormField } from "../../components/ui/form-field";
import { Input } from "../../components/ui/input";
import { profileContent as c } from "./profileContent";

// Form-side draft. All values are strings so empty inputs round-trip
// predictably (vs. an undefined / null mix that would force special
// casing in the dirty-state comparator).
type Draft = {
    name: string;
    email: string;
    phone: string;
};

type FieldErrors = Partial<Record<keyof Draft, string>>;

// Same loose email shape used by LoginPage / RegisterPage. The server
// re-validates with URI::MailTo::EMAIL_REGEXP; we just want to catch
// obvious typos before the round trip.
const EMAIL_RE = /.+@.+\..+/;

// Permissive phone shape — the actual canonical form is enforced (or
// not) by the backend; the frontend just rejects obvious garbage so we
// don't ship `;DROP TABLE` into a tel: link somewhere.
const PHONE_RE = /^[0-9+\-\s()]+$/;

function draftFromMe(me: { full_name?: string | null; email: string; phone?: string | null }): Draft {
    return {
        name: me.full_name ?? "",
        email: me.email,
        phone: me.phone ?? "",
    };
}

function validate(draft: Draft): FieldErrors {
    const errs: FieldErrors = {};
    if (!draft.name.trim()) errs.name = c.errors.nameRequired;
    if (!draft.email.trim()) errs.email = c.errors.emailRequired;
    else if (!EMAIL_RE.test(draft.email)) errs.email = c.errors.emailInvalid;
    if (draft.phone.trim() && !PHONE_RE.test(draft.phone.trim())) {
        errs.phone = c.errors.phoneInvalid;
    }
    return errs;
}

// Build the PATCH payload, sending only the fields that actually changed.
// Trims strings; an emptied phone is sent as "" so the backend can clear
// the column (Devise/AR will store it as nil after canonicalisation).
function diff(initial: Draft, current: Draft) {
    const out: { name?: string; email?: string; phone?: string } = {};
    if (initial.name.trim() !== current.name.trim()) out.name = current.name.trim();
    if (initial.email.trim().toLowerCase() !== current.email.trim().toLowerCase()) {
        out.email = current.email.trim();
    }
    if (initial.phone.trim() !== current.phone.trim()) out.phone = current.phone.trim();
    return out;
}

export default function ProfilePage() {
    const { me, loading, updateMe } = useCurrentUser();
    const navigate = useNavigate();

    // `initial` is the last server-confirmed snapshot; `draft` is what
    // the user has typed. Dirty-state compares against `initial`, so a
    // successful save re-baselines both.
    const [initial, setInitial] = useState<Draft | null>(null);
    const [draft, setDraft] = useState<Draft | null>(null);
    const [fieldErrors, setFieldErrors] = useState<FieldErrors>({});
    const [serverError, setServerError] = useState<string | null>(null);
    const [submitting, setSubmitting] = useState(false);
    const [savedMessage, setSavedMessage] = useState<string | null>(null);

    // Seed the form once `me` is available. We DON'T re-seed on every
    // `me` change: that would clobber unsaved edits if AuthContext
    // refreshes for any reason. Only the initial bootstrap and an
    // explicit successful save reset the baseline.
    useEffect(() => {
        if (me && initial === null) {
            const d = draftFromMe(me);
            setInitial(d);
            setDraft(d);
        }
    }, [me, initial]);

    const dirty = useMemo(() => {
        if (!initial || !draft) return false;
        return Object.keys(diff(initial, draft)).length > 0;
    }, [initial, draft]);

    const isCarrier = me?.roles.includes("carrier") ?? false;

    if (loading || !me || !draft || !initial) {
        return (
            <main
                id="main"
                className="flex-1 flex items-start justify-center px-5 py-12"
                aria-busy="true"
                aria-label={c.errors.loading}
            >
                <div className="w-full max-w-[560px] bg-paper border border-stroke rounded-md p-8">
                    <div
                        className="h-8 rounded animate-[skeleton_1.4s_linear_infinite] bg-[linear-gradient(90deg,color-mix(in_oklab,var(--color-ink)_4%,transparent),color-mix(in_oklab,var(--color-ink)_8%,transparent),color-mix(in_oklab,var(--color-ink)_4%,transparent))] bg-[length:200%_100%] motion-reduce:animate-none"
                    />
                </div>
            </main>
        );
    }

    const update = <K extends keyof Draft>(key: K, value: Draft[K]) => {
        setDraft((d) => (d ? { ...d, [key]: value } : d));
        // Clear the saved toast as soon as the user edits again — the
        // confirmation belongs to the previous save, not this one.
        if (savedMessage) setSavedMessage(null);
        // Clear inline error for the field being edited so the user
        // gets immediate positive feedback as they type.
        if (fieldErrors[key]) {
            setFieldErrors((errs) => {
                const next = { ...errs };
                delete next[key];
                return next;
            });
        }
    };

    const handleCancel = () => {
        // Walk back to wherever the user came from (carrier show page,
        // dashboard, etc.). The header is the only entry point for the
        // edit form, so there's always a prior history entry to return to.
        navigate(-1);
    };

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        const errs = validate(draft);
        setFieldErrors(errs);
        if (Object.keys(errs).length > 0) return;

        const patch = diff(initial, draft);
        if (Object.keys(patch).length === 0) return;

        setSubmitting(true);
        setServerError(null);
        setSavedMessage(null);
        try {
            const next = await updateMe(patch);
            // Re-baseline from the server response (canonicalised email,
            // trimmed strings, etc.) so future dirty checks are honest
            // about what's persisted.
            const persisted = draftFromMe(next);
            setInitial(persisted);
            setDraft(persisted);
            // If the email changed, surface the re-verification notice
            // alongside the standard success toast.
            const emailChanged = "email" in patch;
            setSavedMessage(
                emailChanged
                    ? `${c.feedback.saved} ${c.feedback.emailReverify}`
                    : c.feedback.saved,
            );
        } catch (err) {
            if (err instanceof ApiError && err.status === 422) {
                // Backend envelope: { error: { details: { field: [msgs] } } }
                const details = (err.details ?? {}) as Record<string, string[] | undefined>;
                const next: FieldErrors = {};
                if (details.email?.length) {
                    // Most common 422 here is uniqueness; map to a friendly
                    // copy. Devise/AR will also send format errors, which
                    // we mirror onto the same field.
                    next.email = details.email[0]?.match(/(taken|tomado|en uso)/i)
                        ? c.errors.emailTaken
                        : details.email[0] ?? c.errors.emailInvalid;
                }
                if (details.full_name?.length) next.name = details.full_name[0];
                if (details.phone?.length) next.phone = details.phone[0];
                if (Object.keys(next).length > 0) {
                    setFieldErrors(next);
                } else {
                    setServerError(c.errors.saveGeneric);
                }
            } else if (err instanceof ApiError) {
                setServerError(err.message || c.errors.saveGeneric);
            } else {
                setServerError(c.errors.saveGeneric);
            }
        } finally {
            setSubmitting(false);
        }
    };

    return (
        <main
            id="main"
            className="flex-1 flex items-start justify-center px-5 py-12"
        >
            <section
                aria-labelledby="profile-title"
                className="w-full max-w-[560px] bg-paper border border-stroke rounded-md p-8 shadow-[0_4px_18px_color-mix(in_oklab,var(--color-ink)_8%,transparent)]"
            >
                <h1
                    id="profile-title"
                    className="font-display text-3xl font-bold tracking-tight mb-2"
                >
                    {c.title}
                </h1>
                <p className="text-sm text-ink-soft mb-6 max-w-[65ch] leading-relaxed">
                    {c.lead}
                </p>

                {savedMessage ? (
                    <Alert tone="success" aria-live="polite" className="mb-4">
                        {savedMessage}
                    </Alert>
                ) : null}

                {serverError ? (
                    <Alert tone="error" aria-live="polite" className="mb-4">
                        {serverError}
                    </Alert>
                ) : null}

                <form className="flex flex-col gap-6" onSubmit={handleSubmit} noValidate>
                    <fieldset
                        className="flex flex-col gap-4 border-0 p-0 m-0"
                        aria-labelledby="profile-personal-title"
                    >
                        <legend
                            id="profile-personal-title"
                            className="font-display text-lg font-semibold mb-1"
                        >
                            {c.sections.personal.title}
                        </legend>
                        <p className="text-xs text-ink-faint -mt-2">
                            {c.sections.personal.description}
                        </p>

                        <FormField id="name" label={c.fields.name} error={fieldErrors.name}>
                            <Input
                                id="name"
                                value={draft.name}
                                autoComplete="name"
                                onChange={(e) => update("name", e.target.value)}
                            />
                        </FormField>

                        <FormField
                            id="email"
                            label={c.fields.email}
                            error={fieldErrors.email}
                            help={c.fields.emailHelp}
                        >
                            <Input
                                id="email"
                                type="email"
                                value={draft.email}
                                autoComplete="email"
                                onChange={(e) => update("email", e.target.value)}
                            />
                        </FormField>

                        <FormField
                            id="phone"
                            label={c.fields.phone}
                            error={fieldErrors.phone}
                            help={c.fields.phoneHelp}
                        >
                            <Input
                                id="phone"
                                type="tel"
                                value={draft.phone}
                                autoComplete="tel"
                                onChange={(e) => update("phone", e.target.value)}
                            />
                        </FormField>
                    </fieldset>

                    {isCarrier ? (
                        <section
                            aria-labelledby="profile-vehicle-title"
                            className="rounded-md border border-stroke bg-surface-warm p-4 flex flex-col gap-2"
                        >
                            <h2
                                id="profile-vehicle-title"
                                className="font-display text-lg font-semibold"
                            >
                                {c.sections.vehicle.title}
                            </h2>
                            <p className="text-sm text-ink-soft">
                                {c.sections.vehicle.description}
                            </p>
                            <Link
                                to="/carrier/vehicles"
                                className="text-ink font-semibold underline underline-offset-2 self-start"
                            >
                                {c.sections.vehicle.link}
                            </Link>
                        </section>
                    ) : null}

                    <div className="flex flex-wrap items-center gap-3">
                        <Button
                            type="submit"
                            disabled={!dirty || submitting}
                            aria-busy={submitting ? "true" : "false"}
                        >
                            {submitting ? c.submit.saving : c.submit.save}
                        </Button>
                        <Button
                            type="button"
                            variant="ghost"
                            onClick={handleCancel}
                            disabled={submitting}
                        >
                            {c.submit.cancel}
                        </Button>
                    </div>
                </form>
            </section>
        </main>
    );
}
