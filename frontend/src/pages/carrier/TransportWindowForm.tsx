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
import { Alert } from "../../components/ui/alert";
import { Button } from "../../components/ui/button";
import { FormField } from "../../components/ui/form-field";
import { Input } from "../../components/ui/input";

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

                <form
                    className="grid gap-6 bg-paper p-6 rounded-md shadow-[0_6px_24px_color-mix(in_oklab,var(--color-ink)_6%,transparent)]"
                    aria-labelledby="form-title"
                    onSubmit={handleSubmit}
                    noValidate
                >
                    {error && (
                        <Alert tone="error" aria-live="assertive">
                            {error}
                        </Alert>
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

                    <p className="requiredNote">{f.allRequired}</p>

                    <div className="grid gap-4 grid-cols-[repeat(auto-fit,minmax(220px,1fr))]">
                        <FormField
                            id="origin_zone"
                            label={f.fields.originZone}
                            error={fieldError("origin_zone")}
                        >
                            <Input
                                id="origin_zone"
                                type="text"
                                value={draft.origin_zone}
                                onChange={(e) => set("origin_zone", e.target.value)}
                                required
                            />
                        </FormField>

                        <FormField
                            id="destination_zone"
                            label={f.fields.destinationZone}
                            error={fieldError("destination_zone")}
                        >
                            <Input
                                id="destination_zone"
                                type="text"
                                value={draft.destination_zone}
                                onChange={(e) => set("destination_zone", e.target.value)}
                                required
                            />
                        </FormField>

                        <FormField
                            id="price_per_km"
                            label={f.fields.pricePerKm}
                            error={fieldError("price_per_km")}
                        >
                            <Input
                                id="price_per_km"
                                type="text"
                                inputMode="decimal"
                                value={draft.price_per_km}
                                onChange={(e) => set("price_per_km", e.target.value)}
                                required
                            />
                        </FormField>

                        <FormField
                            id="max_km"
                            label={f.fields.maxKm}
                            error={fieldError("max_km")}
                        >
                            <Input
                                id="max_km"
                                type="text"
                                inputMode="numeric"
                                pattern="[0-9]*"
                                value={draft.max_km}
                                onChange={(e) => set("max_km", e.target.value)}
                                required
                            />
                        </FormField>
                    </div>

                    <fieldset className="border border-stroke rounded-sm p-4">
                        <legend className="px-2 font-semibold text-ink">
                            {f.periodLegend}
                        </legend>
                        <div className="grid gap-4 grid-cols-[repeat(auto-fit,minmax(220px,1fr))]">
                            <FormField
                                id="available_from"
                                label={f.fields.availableFrom}
                                error={fieldError("available_from")}
                            >
                                <Input
                                    id="available_from"
                                    type="datetime-local"
                                    min={todayMin}
                                    value={draft.available_from}
                                    onChange={(e) => set("available_from", e.target.value)}
                                    required
                                />
                            </FormField>

                            <FormField
                                id="available_to"
                                label={f.fields.availableTo}
                                error={fieldError("available_to")}
                            >
                                <Input
                                    id="available_to"
                                    type="datetime-local"
                                    min={draft.available_from || todayMin}
                                    value={draft.available_to}
                                    onChange={(e) => set("available_to", e.target.value)}
                                    required
                                />
                            </FormField>
                        </div>
                    </fieldset>

                    <div className="flex flex-wrap gap-3">
                        <Button type="submit" disabled={loading}>
                            {loading
                                ? f.submit.saving
                                : mode === "edit" ? f.submit.update : f.submit.create}
                        </Button>
                        <Button
                            type="button"
                            variant="ghost"
                            onClick={() =>
                                window.history.length > 1
                                    ? navigate(-1)
                                    : navigate("/carrier/availability")}
                        >
                            {f.submit.cancel}
                        </Button>
                    </div>
                </form>
            </div>
        </main>
    );
}
