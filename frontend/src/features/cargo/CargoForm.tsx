import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { createCargo, fieldErrorsFrom, getCargo, updateCargo } from "./api";
import type { Cargo, CargoDraft } from "../../types/Cargo";
import { cargosContent } from "./cargosContent";
import { Alert } from "../../components/ui/alert";
import { Button } from "../../components/ui/button";
import { FormField } from "../../components/ui/form-field";
import { Input } from "../../components/ui/input";
import { Select } from "../../components/ui/select";
import { Textarea } from "../../components/ui/textarea";

const f = cargosContent.form;

type Mode = "new" | "edit";

const EMPTY: CargoDraft = {
    cargo_description: "",
    pickup_address: "",
    delivery_address: "",
    pickup_zone: "",
    delivery_zone: "",
    pickup_window_start: "",
    pickup_window_end: "",
    weight_kg: "",
    volume_cm3: "",
    declared_value_cents: "",
};

/** Trims an ISO datetime to the `<input type="datetime-local">` shape. */
function toLocalDatetime(iso: string): string {
    if (!iso) return "";
    const d = new Date(iso);
    const pad = (n: number) => String(n).padStart(2, "0");
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

function draftFromCargo(c: Cargo): CargoDraft {
    return {
        cargo_description: c.cargo_description,
        pickup_address: c.pickup_address,
        delivery_address: c.delivery_address,
        pickup_zone: c.pickup_zone,
        delivery_zone: c.delivery_zone,
        pickup_window_start: toLocalDatetime(c.pickup_window_start),
        pickup_window_end: toLocalDatetime(c.pickup_window_end),
        weight_kg: c.weight_kg,
        volume_cm3: c.volume_cm3 != null ? String(c.volume_cm3) : "",
        declared_value_cents: String(c.declared_value_cents),
    };
}

/** Inline client-side validation — plain rules, no form library (plan §2.6). */
function validate(draft: CargoDraft): Record<string, string> {
    const e = f.errors;
    const errors: Record<string, string> = {};

    const desc = draft.cargo_description.trim();
    if (desc.length === 0) errors.cargo_description = e.cargoDescriptionRequired;
    else if (desc.length > 200) errors.cargo_description = e.cargoDescriptionTooLong;

    if (draft.pickup_address.trim() === "") errors.pickup_address = e.pickupAddressRequired;
    if (draft.delivery_address.trim() === "") {
        errors.delivery_address = e.deliveryAddressRequired;
    }
    if (draft.pickup_zone === "") errors.pickup_zone = e.pickupZoneRequired;
    if (draft.delivery_zone === "") errors.delivery_zone = e.deliveryZoneRequired;

    if (draft.pickup_window_start === "") {
        errors.pickup_window_start = e.pickupWindowStartRequired;
    }
    if (draft.pickup_window_end === "") {
        errors.pickup_window_end = e.pickupWindowEndRequired;
    } else if (
        draft.pickup_window_start !== "" &&
        new Date(draft.pickup_window_end) <= new Date(draft.pickup_window_start)
    ) {
        errors.pickup_window_end = e.pickupWindowEndBeforeStart;
    }

    if (draft.weight_kg.trim() === "") errors.weight_kg = e.weightRequired;
    else if (!(parseFloat(draft.weight_kg) > 0)) errors.weight_kg = e.weightPositive;

    if (draft.volume_cm3.trim() !== "" && !(parseInt(draft.volume_cm3, 10) > 0)) {
        errors.volume_cm3 = e.volumePositive;
    }

    if (draft.declared_value_cents.trim() === "") {
        errors.declared_value_cents = e.declaredValueRequired;
    } else if (parseInt(draft.declared_value_cents, 10) < 0) {
        errors.declared_value_cents = e.declaredValueNonNegative;
    }

    return errors;
}

type Props = { mode: Mode };

export default function CargoForm({ mode }: Props) {
    const navigate = useNavigate();
    const params = useParams<{ id: string }>();
    const editingId = mode === "edit" && params.id ? Number(params.id) : null;

    const [draft, setDraft] = useState<CargoDraft>(EMPTY);
    const [errors, setErrors] = useState<Record<string, string>>({});
    const [submitError, setSubmitError] = useState<string | null>(null);
    const [loadError, setLoadError] = useState<string | null>(null);
    const [hydrating, setHydrating] = useState(editingId != null);
    const [submitting, setSubmitting] = useState(false);

    useEffect(() => {
        if (editingId == null) return;
        let cancelled = false;
        (async () => {
            try {
                const cargo = await getCargo(editingId);
                if (!cancelled) setDraft(draftFromCargo(cargo));
            } catch {
                if (!cancelled) setLoadError(f.loadError);
            } finally {
                if (!cancelled) setHydrating(false);
            }
        })();
        return () => {
            cancelled = true;
        };
    }, [editingId]);

    function set(key: keyof CargoDraft, value: string) {
        setDraft((prev) => ({ ...prev, [key]: value }));
        setErrors((prev) => {
            if (!prev[key]) return prev;
            const next = { ...prev };
            delete next[key];
            return next;
        });
    }

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        const clientErrors = validate(draft);
        if (Object.keys(clientErrors).length > 0) {
            setErrors(clientErrors);
            setSubmitError(null);
            return;
        }
        setSubmitting(true);
        setSubmitError(null);
        try {
            const saved = editingId != null
                ? await updateCargo(editingId, draft)
                : await createCargo(draft);
            navigate(`/shipper/cargos/${saved.id}`);
        } catch (err) {
            const fieldErrors = fieldErrorsFrom(err);
            if (Object.keys(fieldErrors).length > 0) setErrors(fieldErrors);
            setSubmitError(f.saveError);
        } finally {
            setSubmitting(false);
        }
    }

    if (hydrating) {
        return (
            <main className="page" id="main">
                <div className="container">
                    <p className="sectionLead" role="status" aria-busy="true">
                        {f.hydrating}
                    </p>
                </div>
            </main>
        );
    }

    if (loadError) {
        return (
            <main className="page" id="main">
                <div className="container">
                    <Alert tone="error" aria-live="assertive">
                        {loadError}
                    </Alert>
                    <Button
                        variant="ghost"
                        onClick={() => navigate("/shipper/cargos")}
                    >
                        {cargosContent.detail.backToList}
                    </Button>
                </div>
            </main>
        );
    }

    return (
        <main className="page" id="main">
            <div className="container">
                <header className="formHeader">
                    <h1 className="sectionTitle" id="cargo-form-title">
                        {mode === "edit" ? f.editTitle : f.newTitle}
                    </h1>
                    <p className="sectionLead">
                        {mode === "edit" ? f.editLead : f.newLead}
                    </p>
                </header>

                <form
                    className="cargoForm"
                    aria-labelledby="cargo-form-title"
                    onSubmit={handleSubmit}
                    noValidate
                >
                    {submitError && (
                        <Alert tone="error" aria-live="assertive">
                            {submitError}
                        </Alert>
                    )}
                    <p className="requiredNote">{f.allRequired}</p>

                    <fieldset className="cargoFormSection">
                        <legend className="cargoFormLegend">
                            {f.sections.what}
                        </legend>
                        <FormField
                            id="cargo_description"
                            label={f.fields.cargoDescription}
                            help={f.fields.cargoDescriptionHelp}
                            error={errors.cargo_description}
                            required
                        >
                            <Textarea
                                id="cargo_description"
                                value={draft.cargo_description}
                                onChange={(e) =>
                                    set("cargo_description", e.target.value)}
                                rows={3}
                                maxLength={200}
                            />
                        </FormField>
                        <div className="cargoFormGrid">
                            <FormField
                                id="weight_kg"
                                label={f.fields.weightKg}
                                error={errors.weight_kg}
                                required
                            >
                                <Input
                                    id="weight_kg"
                                    type="number"
                                    min="0.1"
                                    step="0.1"
                                    value={draft.weight_kg}
                                    onChange={(e) =>
                                        set("weight_kg", e.target.value)}
                                />
                            </FormField>
                            <FormField
                                id="volume_cm3"
                                label={f.fields.volumeCm3}
                                help={f.fields.volumeOptional}
                                error={errors.volume_cm3}
                            >
                                <Input
                                    id="volume_cm3"
                                    type="number"
                                    min="1"
                                    step="1"
                                    value={draft.volume_cm3}
                                    onChange={(e) =>
                                        set("volume_cm3", e.target.value)}
                                />
                            </FormField>
                            <FormField
                                id="declared_value_cents"
                                label={f.fields.declaredValue}
                                error={errors.declared_value_cents}
                                required
                            >
                                <Input
                                    id="declared_value_cents"
                                    type="number"
                                    min="0"
                                    step="1"
                                    value={draft.declared_value_cents}
                                    onChange={(e) =>
                                        set("declared_value_cents", e.target.value)}
                                />
                            </FormField>
                        </div>
                    </fieldset>

                    <fieldset className="cargoFormSection">
                        <legend className="cargoFormLegend">
                            {f.sections.where}
                        </legend>
                        <FormField
                            id="pickup_address"
                            label={f.fields.pickupAddress}
                            error={errors.pickup_address}
                            required
                        >
                            <Input
                                id="pickup_address"
                                value={draft.pickup_address}
                                onChange={(e) =>
                                    set("pickup_address", e.target.value)}
                                autoComplete="shipping street-address"
                            />
                        </FormField>
                        <FormField
                            id="delivery_address"
                            label={f.fields.deliveryAddress}
                            error={errors.delivery_address}
                            required
                        >
                            <Input
                                id="delivery_address"
                                value={draft.delivery_address}
                                onChange={(e) =>
                                    set("delivery_address", e.target.value)}
                                autoComplete="billing street-address"
                            />
                        </FormField>
                        <div className="cargoFormGrid">
                            <FormField
                                id="pickup_zone"
                                label={f.fields.pickupZone}
                                help={f.fields.zoneHelp}
                                error={errors.pickup_zone}
                                required
                            >
                                <Select
                                    id="pickup_zone"
                                    value={draft.pickup_zone}
                                    onChange={(e) =>
                                        set("pickup_zone", e.target.value)}
                                >
                                    <option value="">
                                        {f.fields.zoneDefault}
                                    </option>
                                    {f.provinces.map((p) => (
                                        <option key={p} value={p}>
                                            {p}
                                        </option>
                                    ))}
                                </Select>
                            </FormField>
                            <FormField
                                id="delivery_zone"
                                label={f.fields.deliveryZone}
                                help={f.fields.zoneHelp}
                                error={errors.delivery_zone}
                                required
                            >
                                <Select
                                    id="delivery_zone"
                                    value={draft.delivery_zone}
                                    onChange={(e) =>
                                        set("delivery_zone", e.target.value)}
                                >
                                    <option value="">
                                        {f.fields.zoneDefault}
                                    </option>
                                    {f.provinces.map((p) => (
                                        <option key={p} value={p}>
                                            {p}
                                        </option>
                                    ))}
                                </Select>
                            </FormField>
                        </div>
                    </fieldset>

                    <fieldset className="cargoFormSection">
                        <legend className="cargoFormLegend">
                            {f.sections.when}
                        </legend>
                        <div className="cargoFormGrid">
                            <FormField
                                id="pickup_window_start"
                                label={f.fields.pickupWindowStart}
                                error={errors.pickup_window_start}
                                required
                            >
                                <Input
                                    id="pickup_window_start"
                                    type="datetime-local"
                                    value={draft.pickup_window_start}
                                    onChange={(e) =>
                                        set("pickup_window_start", e.target.value)}
                                />
                            </FormField>
                            <FormField
                                id="pickup_window_end"
                                label={f.fields.pickupWindowEnd}
                                error={errors.pickup_window_end}
                                required
                            >
                                <Input
                                    id="pickup_window_end"
                                    type="datetime-local"
                                    min={draft.pickup_window_start || undefined}
                                    value={draft.pickup_window_end}
                                    onChange={(e) =>
                                        set("pickup_window_end", e.target.value)}
                                />
                            </FormField>
                        </div>
                    </fieldset>

                    <div className="cargoFormActions">
                        <Button type="submit" disabled={submitting}>
                            {submitting
                                ? f.submit.saving
                                : mode === "edit"
                                ? f.submit.update
                                : f.submit.create}
                        </Button>
                        <Button
                            type="button"
                            variant="ghost"
                            onClick={() =>
                                navigate(
                                    editingId != null
                                        ? `/shipper/cargos/${editingId}`
                                        : "/shipper/cargos",
                                )}
                        >
                            {f.submit.cancel}
                        </Button>
                    </div>
                </form>
            </div>
        </main>
    );
}
