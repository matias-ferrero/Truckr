import { useEffect, useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { createCargo, fieldErrorsFrom, getCargo, updateCargo } from "./api";
import type { Cargo, CargoDraft } from "../../types/Cargo";
import { cargosContent } from "./cargosContent";
import { Alert } from "../../components/ui/alert";
import { AddressPicker, type AddressPickerValue } from "../../components/AddressPicker";
import { Button } from "../../components/ui/button";
import { FormField } from "../../components/ui/form-field";
import { Input } from "../../components/ui/input";
import { Textarea } from "../../components/ui/textarea";
import CargoMapPreview from "./CargoMapPreview";

const f = cargosContent.form;

type Mode = "new" | "edit";

// REQ-BE-00039 / ADR-014: the form holds pickup + delivery as
// AddressPickerValue (now carrying parsed locality + admin_area). No separate
// zone selects — locality/admin_area are derived at the wire boundary.
type Draft = {
    cargo_description: string;
    pickup: AddressPickerValue | null;
    delivery: AddressPickerValue | null;
    pickup_window_start: string;
    pickup_window_end: string;
    weight_kg: string;
    volume_cm3: string;
    /** Whole ARS pesos as typed; converted to cents at the wire boundary. */
    declared_value_cents: string;
};

const EMPTY: Draft = {
    cargo_description:    "",
    pickup:               null,
    delivery:             null,
    pickup_window_start:  "",
    pickup_window_end:    "",
    weight_kg:            "",
    volume_cm3:           "",
    declared_value_cents: "",
};

const declaredValueFormatter = new Intl.NumberFormat("es-AR", {
    style: "currency",
    currency: "ARS",
    currencyDisplay: "code",
    maximumFractionDigits: 0,
});

function toLocalDatetime(iso: string): string {
    if (!iso) return "";
    const d = new Date(iso);
    const pad = (n: number) => String(n).padStart(2, "0");
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

function toNumber(n: string | number | null | undefined): number | null {
    if (n === null || n === undefined || n === "") return null;
    const v = typeof n === "number" ? n : Number(n);
    return Number.isFinite(v) ? v : null;
}

function draftFromCargo(c: Cargo): Draft {
    const pLat = toNumber(c.pickup_lat);
    const pLng = toNumber(c.pickup_lng);
    const dLat = toNumber(c.delivery_lat);
    const dLng = toNumber(c.delivery_lng);
    return {
        cargo_description: c.cargo_description,
        pickup:            pLat != null && pLng != null
            ? {
                text:       c.pickup_address,
                lat:        pLat,
                lng:        pLng,
                locality:   c.pickup_locality,
                admin_area: c.pickup_admin_area,
            }
            : null,
        delivery: dLat != null && dLng != null
            ? {
                text:       c.delivery_address,
                lat:        dLat,
                lng:        dLng,
                locality:   c.delivery_locality,
                admin_area: c.delivery_admin_area,
            }
            : null,
        pickup_window_start:  toLocalDatetime(c.pickup_window_start),
        pickup_window_end:    toLocalDatetime(c.pickup_window_end),
        weight_kg:            c.weight_kg,
        volume_cm3:           c.volume_cm3 != null ? String(c.volume_cm3) : "",
        declared_value_cents: String(Math.round(c.declared_value_cents / 100)),
    };
}

function validate(draft: Draft): Record<string, string> {
    const e = f.errors;
    const errors: Record<string, string> = {};

    const desc = draft.cargo_description.trim();
    if (desc.length === 0) errors.cargo_description = e.cargoDescriptionRequired;
    else if (desc.length > 200) errors.cargo_description = e.cargoDescriptionTooLong;

    if (draft.pickup === null) errors.pickup_address = e.pickupAddressRequired;
    if (draft.delivery === null) errors.delivery_address = e.deliveryAddressRequired;

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

function arsToCents(ars: string): string {
    const v = parseFloat(ars);
    if (!Number.isFinite(v)) return ars;
    return String(Math.round(v * 100));
}

function toWireDraft(draft: Draft): CargoDraft {
    // `validate` guarantees pickup/delivery are non-null by the time we reach here.
    const p = draft.pickup!;
    const d = draft.delivery!;
    return {
        cargo_description:    draft.cargo_description,
        pickup_address:       p.text,
        pickup_lat:           p.lat,
        pickup_lng:           p.lng,
        pickup_locality:      (p.locality ?? "").trim(),
        pickup_admin_area:    (p.admin_area ?? "").trim(),
        delivery_address:     d.text,
        delivery_lat:         d.lat,
        delivery_lng:         d.lng,
        delivery_locality:    (d.locality ?? "").trim(),
        delivery_admin_area:  (d.admin_area ?? "").trim(),
        pickup_window_start:  draft.pickup_window_start,
        pickup_window_end:    draft.pickup_window_end,
        weight_kg:            draft.weight_kg,
        volume_cm3:           draft.volume_cm3,
        declared_value_cents: arsToCents(draft.declared_value_cents),
    };
}

type Props = { mode: Mode };

export default function CargoForm({ mode }: Props) {
    const navigate = useNavigate();
    const params = useParams<{ id: string }>();
    const editingId = mode === "edit" && params.id ? Number(params.id) : null;

    const [draft, setDraft] = useState<Draft>(EMPTY);
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

    const declaredValuePreview = useMemo(() => {
        const raw = draft.declared_value_cents.trim();
        if (!raw) return null;
        const value = Number(raw);
        if (!Number.isFinite(value)) return null;
        return declaredValueFormatter.format(value);
    }, [draft.declared_value_cents]);

    function set<K extends keyof Draft>(key: K, value: Draft[K]) {
        setDraft((prev) => ({ ...prev, [key]: value }));
        setErrors((prev) => {
            if (!prev[key as string]) return prev;
            const next = { ...prev };
            delete next[key as string];
            return next;
        });
    }

    function setAddress(side: "pickup" | "delivery", value: AddressPickerValue | null) {
        setDraft((prev) => ({ ...prev, [side]: value }));
        setErrors((prev) => {
            const key = side === "pickup" ? "pickup_address" : "delivery_address";
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
            const wire = toWireDraft(draft);
            const saved = editingId != null
                ? await updateCargo(editingId, wire)
                : await createCargo(wire);
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
                    <p className="requiredNote">{f.allRequired}</p>
                </header>

                <form
                    className="cargoForm"
                    aria-labelledby="cargo-form-title"
                    aria-busy={submitting}
                    onSubmit={handleSubmit}
                    noValidate
                >
                    {submitError && (
                        <Alert tone="error" aria-live="assertive">
                            {submitError}
                        </Alert>
                    )}

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
                                help={f.fields.weightKgHelp}
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
                                help={
                                    declaredValuePreview
                                        ? (
                                            <>
                                                {f.fields.declaredValueHelp}
                                                <span className="mt-1 block font-medium text-ink">
                                                    {f.declaredValuePreview(declaredValuePreview)}
                                                </span>
                                            </>
                                        )
                                        : f.fields.declaredValueHelp
                                }
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
                            help={f.fields.pickupAddressHelp}
                            error={errors.pickup_address}
                            required
                        >
                            <AddressPicker
                                id="pickup_address"
                                name="pickup_address"
                                value={draft.pickup}
                                onChange={(v) => setAddress("pickup", v)}
                                required
                            />
                        </FormField>
                        <FormField
                            id="delivery_address"
                            label={f.fields.deliveryAddress}
                            help={f.fields.deliveryAddressHelp}
                            error={errors.delivery_address}
                            required
                        >
                            <AddressPicker
                                id="delivery_address"
                                name="delivery_address"
                                value={draft.delivery}
                                onChange={(v) => setAddress("delivery", v)}
                                required
                            />
                        </FormField>
                        <CargoMapPreview
                            pickup={draft.pickup}
                            delivery={draft.delivery}
                        />
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
