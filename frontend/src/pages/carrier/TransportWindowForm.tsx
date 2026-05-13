import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import {
    createTransportWindow,
    getMyTransportWindow,
    TransportWindow,
    TransportWindowDraft,
    updateTransportWindow,
} from "../../api/transport_windows";
import VehicleSelect from "../../components/VehicleSelect";
import { carrierContent } from "./carrierContent";

type Mode = "new" | "edit";

const f = carrierContent.availability.form;

type Draft = {
    vehicle_id: number | null;
    origin_zone: string;
    destination_zone: string;
    price_per_km: string;
    max_km: string;
    available_from: string;
    available_to: string;
};

const empty: Draft = {
    vehicle_id:       null,
    origin_zone:      "",
    destination_zone: "",
    price_per_km:     "",
    max_km:           "",
    available_from:   "",
    available_to:     "",
};

function toLocalDatetime(iso: string | null | undefined): string {
    if (!iso) return "";
    const d = new Date(iso);
    const pad = (n: number) => String(n).padStart(2, "0");
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}T${pad(d.getHours())}:${pad(d.getMinutes())}`;
}

function fromWindow(tw: TransportWindow): Draft {
    return {
        vehicle_id:       tw.vehicle_id,
        origin_zone:      tw.origin_zone,
        destination_zone: tw.destination_zone,
        price_per_km:     tw.price_per_km,
        max_km:           String(tw.max_km),
        available_from:   toLocalDatetime(tw.available_from),
        available_to:     toLocalDatetime(tw.available_to),
    };
}

type Props = { mode: Mode };

export default function TransportWindowForm({ mode }: Props) {
    const navigate  = useNavigate();
    const params    = useParams();
    const editingId = mode === "edit" && params.id ? Number(params.id) : null;

    const [draft, setDraft]               = useState<Draft>(empty);
    const [vehicleInfo, setVehicleInfo]   = useState<{ make: string; model: string; plate: string } | null>(null);
    const [loading, setLoading]           = useState(false);
    const [error, setError]               = useState<string | null>(null);
    const [serverErrors, setServerErrors] = useState<Record<string, string[]>>({});
    const [hydrating, setHydrating]       = useState(editingId != null);

    useEffect(() => {
        if (editingId == null) return;
        let cancelled = false;
        (async () => {
            try {
                const tw = await getMyTransportWindow(editingId);
                if (!cancelled) {
                    setDraft(fromWindow(tw));
                    setVehicleInfo({ make: tw.vehicle.make, model: tw.vehicle.model, plate: tw.vehicle.plate });
                }
            } catch (e) {
                if (!cancelled) setError((e as Error).message);
            } finally {
                if (!cancelled) setHydrating(false);
            }
        })();
        return () => { cancelled = true; };
    }, [editingId]);

    function set(key: keyof Draft, value: string | number | null) {
        setDraft((prev) => ({ ...prev, [key]: value }));
        if (serverErrors[key]) setServerErrors((prev) => ({ ...prev, [key]: [] }));
    }

    function fieldError(key: string): string | undefined {
        return serverErrors[key]?.[0];
    }

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        if (draft.vehicle_id == null) {
            setError(f.vehicleRequired);
            return;
        }
        setLoading(true);
        setError(null);
        setServerErrors({});
        try {
            const payload: TransportWindowDraft = {
                vehicle_id:       draft.vehicle_id,
                origin_zone:      draft.origin_zone,
                destination_zone: draft.destination_zone,
                price_per_km:     draft.price_per_km,
                max_km:           draft.max_km,
                available_from:   draft.available_from,
                available_to:     draft.available_to,
            };
            if (editingId) {
                await updateTransportWindow(editingId, payload);
            } else {
                await createTransportWindow(payload);
            }
            navigate("/carrier/availability");
        } catch (e: unknown) {
            const err = e as { body?: { error?: { details?: Record<string, string[]> } }; message?: string };
            const details = err?.body?.error?.details;
            if (details) {
                setServerErrors(details);
                setError(f.saveError);
            } else {
                setError(err?.message ?? f.saveError);
            }
        } finally {
            setLoading(false);
        }
    }

    const todayMin = toLocalDatetime(new Date().toISOString());

    if (hydrating) {
        return (
            <main className="page carrierMain" id="main">
                <div className="container">
                    <p className="sectionLead" role="status" aria-busy="true">{f.hydrating}</p>
                </div>
            </main>
        );
    }

    return (
        <main className="page carrierMain" id="main">
            <div className="container">
                <header className="formHeader">
                    <h1 className="sectionTitle" id="form-title">
                        {mode === "edit" ? f.editTitle : f.newTitle}
                    </h1>
                    <p className="sectionLead">{f.lead}</p>
                </header>

                <form className="vehicleForm" aria-labelledby="form-title" onSubmit={handleSubmit} noValidate>
                    {error && (
                        <div className="errorPanel" role="alert">
                            <p>{error}</p>
                        </div>
                    )}

                    {mode === "new" && (
                        <VehicleSelect
                            value={draft.vehicle_id}
                            onChange={(id) => set("vehicle_id", id)}
                            label={f.fields.vehicle}
                        />
                    )}
                    {mode === "edit" && vehicleInfo && (
                        <dl className="field fieldReadonly">
                            <dt>{f.fields.vehicle}</dt>
                            <dd className="windowMeta">
                                {vehicleInfo.make} {vehicleInfo.model} — <strong>{vehicleInfo.plate}</strong>
                            </dd>
                        </dl>
                    )}

                    <div className="fieldSection">
                    <p className="requiredNote">{f.allRequired}</p>
                    <div className="fieldGrid">
                        <Field
                            label={f.fields.originZone}
                            error={fieldError("origin_zone")}
                        >
                            <input
                                id="origin_zone"
                                className="input"
                                type="text"
                                value={draft.origin_zone}
                                onChange={(e) => set("origin_zone", e.target.value)}
                                required
                                aria-invalid={!!fieldError("origin_zone")}
                                aria-describedby={fieldError("origin_zone") ? "origin_zone-error" : undefined}
                            />
                        </Field>

                        <Field
                            label={f.fields.destinationZone}
                            error={fieldError("destination_zone")}
                        >
                            <input
                                id="destination_zone"
                                className="input"
                                type="text"
                                value={draft.destination_zone}
                                onChange={(e) => set("destination_zone", e.target.value)}
                                required
                                aria-invalid={!!fieldError("destination_zone")}
                                aria-describedby={fieldError("destination_zone") ? "destination_zone-error" : undefined}
                            />
                        </Field>

                        <Field
                            label={f.fields.pricePerKm}
                            error={fieldError("price_per_km")}
                        >
                            <input
                                id="price_per_km"
                                className="input"
                                type="text"
                                inputMode="decimal"
                                value={draft.price_per_km}
                                onChange={(e) => set("price_per_km", e.target.value)}
                                required
                                aria-invalid={!!fieldError("price_per_km")}
                                aria-describedby={fieldError("price_per_km") ? "price_per_km-error" : undefined}
                            />
                        </Field>

                        <Field
                            label={f.fields.maxKm}
                            error={fieldError("max_km")}
                        >
                            <input
                                id="max_km"
                                className="input"
                                type="text"
                                inputMode="numeric"
                                pattern="[0-9]*"
                                value={draft.max_km}
                                onChange={(e) => set("max_km", e.target.value)}
                                required
                                aria-invalid={!!fieldError("max_km")}
                                aria-describedby={fieldError("max_km") ? "max_km-error" : undefined}
                            />
                        </Field>
                    </div>

                    <fieldset className="dateRange">
                        <legend>{f.periodLegend}</legend>
                        <Field
                            label={f.fields.availableFrom}
                            error={fieldError("available_from")}
                        >
                            <input
                                id="available_from"
                                className="input"
                                type="datetime-local"
                                min={todayMin}
                                value={draft.available_from}
                                onChange={(e) => set("available_from", e.target.value)}
                                required
                                aria-invalid={!!fieldError("available_from")}
                                aria-describedby={fieldError("available_from") ? "available_from-error" : undefined}
                            />
                        </Field>

                        <Field
                            label={f.fields.availableTo}
                            error={fieldError("available_to")}
                        >
                            <input
                                id="available_to"
                                className="input"
                                type="datetime-local"
                                min={draft.available_from || todayMin}
                                value={draft.available_to}
                                onChange={(e) => set("available_to", e.target.value)}
                                required
                                aria-invalid={!!fieldError("available_to")}
                                aria-describedby={fieldError("available_to") ? "available_to-error" : undefined}
                            />
                        </Field>
                    </fieldset>
                    </div>

                    <div className="cardActions">
                        <button
                            type="button"
                            className="button buttonGhost"
                            onClick={() => navigate("/carrier/availability")}
                        >
                            {f.submit.cancel}
                        </button>
                        <button
                            type="submit"
                            className="button buttonPrimary"
                            disabled={loading}
                        >
                            {loading
                                ? f.submit.saving
                                : mode === "edit" ? f.submit.update : f.submit.create}
                        </button>
                    </div>
                </form>
            </div>
        </main>
    );
}

type FieldProps = {
    label: string;
    error?: string;
    children: React.ReactNode;
};

function Field({ label, error, children }: FieldProps) {
    const child = children as React.ReactElement<{ id?: string }>;
    const id    = child?.props?.id ?? label.toLowerCase().replace(/\s+/g, "_");
    return (
        <div className="field">
            <label htmlFor={id}>{label}</label>
            {children}
            {error && (
                <p id={`${id}-error`} className="fieldError">
                    {error}
                </p>
            )}
        </div>
    );
}
