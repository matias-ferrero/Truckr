import { useEffect, useRef, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import {
    createTransportWindow,
    getMyTransportWindow,
    TransportWindow,
    TransportWindowDraft,
    updateTransportWindow,
} from "../../api/transport_windows";
import VehicleSelect from "../../components/VehicleSelect";
import ProvinceSelect from "../../components/ProvinceSelect";
import { carrierContent } from "./carrierContent";
import { Alert } from "../../components/ui/alert";
import { Button } from "../../components/ui/button";
import { FormField } from "../../components/ui/form-field";
import { Input } from "../../components/ui/input";

type Mode = "new" | "edit";

const f = carrierContent.availability.form;
const l = carrierContent.availability.list;

type Draft = {
    vehicle_id: number | null;
    origin_province: string;
    origin_locality: string;
    destination_province: string;
    destination_locality: string;
    price_per_km: string;
    max_km: string;
    available_from: string;
    available_to: string;
};

const empty: Draft = {
    vehicle_id:           null,
    origin_province:      "Buenos Aires",
    origin_locality:      "",
    destination_province: "",
    destination_locality: "",
    price_per_km:         "",
    max_km:               "",
    available_from:       "",
    available_to:         "",
};

function toLocalDate(iso: string | null | undefined): string {
    if (!iso) return "";
    return iso.slice(0, 10);
}

function todayDate(): string {
    const d = new Date();
    const pad = (n: number) => String(n).padStart(2, "0");
    return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
}

function fromWindow(tw: TransportWindow): Draft {
    return {
        vehicle_id:           tw.vehicle_id,
        origin_province:      tw.origin_province,
        origin_locality:      tw.origin_locality ?? "",
        destination_province: tw.destination_province ?? "",
        destination_locality: tw.destination_locality ?? "",
        price_per_km:         tw.price_per_km,
        max_km:               String(tw.max_km),
        available_from:       toLocalDate(tw.available_from),
        available_to:         toLocalDate(tw.available_to),
    };
}

type Props = { mode: Mode };

export default function TransportWindowForm({ mode }: Props) {
    const navigate  = useNavigate();
    const params    = useParams();
    const editingId = mode === "edit" && params.id ? Number(params.id) : null;

    const [draft, setDraft]               = useState<Draft>(empty);
    const initialAvailableFromRef         = useRef<string>("");
    const [vehicleInfo, setVehicleInfo]   = useState<{ make: string; model: string; plate: string } | null>(null);
    const [loading, setLoading]           = useState(false);
    const [error, setError]               = useState<string | null>(null);
    const [serverErrors, setServerErrors] = useState<Record<string, string[]>>({});
    const [hydrating, setHydrating]       = useState(editingId != null);
    const [noVehicles, setNoVehicles]     = useState(false);

    useEffect(() => {
        if (editingId == null) return;
        let cancelled = false;
        (async () => {
            try {
                const tw = await getMyTransportWindow(editingId);
                if (!cancelled) {
                    setDraft(fromWindow(tw));
                    initialAvailableFromRef.current = toLocalDate(tw.available_from);
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
        if (!draft.available_from || !draft.available_to) {
            setError(f.saveError);
            return;
        }
        setLoading(true);
        setError(null);
        setServerErrors({});
        try {
            const payload: TransportWindowDraft = {
                vehicle_id:           draft.vehicle_id,
                origin_province:      draft.origin_province,
                origin_locality:      draft.origin_locality.trim() || null,
                destination_province: draft.destination_province.trim() || null,
                destination_locality: draft.destination_locality.trim() || null,
                price_per_km:         draft.price_per_km,
                max_km:               draft.max_km,
                available_from:       draft.available_from + "T00:00",
                available_to:         draft.available_to + "T23:59",
            };
            if (editingId) {
                await updateTransportWindow(editingId, payload);
            } else {
                await createTransportWindow(payload);
            }
            navigate("/carrier/availability", { state: { justSaved: true, isNew: mode === "new" } });
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

    const todayMin = todayDate();

    if (hydrating) {
        return (
            <main className="page carrierMain" id="main">
                <div className="container" role="status" aria-busy="true" aria-label={f.hydrating}>
                    <div className="formSkeleton">
                        <div className="formSkeletonTitle" />
                        <div className="formSkeletonBlock" />
                        <div className="formSkeletonRow">
                            <div className="formSkeletonField" />
                            <div className="formSkeletonField" />
                        </div>
                        <div className="formSkeletonRow">
                            <div className="formSkeletonField" />
                            <div className="formSkeletonField" />
                        </div>
                        <div className="formSkeletonActions" />
                    </div>
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
                    className="windowForm"
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
                            onEmpty={() => setNoVehicles(true)}
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

                    <p className="requiredNote">
                        <span aria-hidden="true">* </span>{f.requiredLegend}
                    </p>

                    <fieldset className="zoneGroup">
                        <legend className="zoneGroupLegend">{f.originLegend}</legend>
                        <div className="zoneGroupFields">
                            <FormField
                                id="origin_province"
                                label={<>{f.fields.originProvince} <span aria-hidden="true" className="requiredStar">*</span></>}
                                error={fieldError("origin_province")}
                            >
                                <ProvinceSelect
                                    id="origin_province"
                                    value={draft.origin_province}
                                    onChange={(v) => {
                                        set("origin_province", v);
                                        if (!v) set("origin_locality", "");
                                    }}
                                    required
                                />
                            </FormField>

                            <FormField
                                id="origin_locality"
                                label={f.fields.originLocality}
                                help={f.fields.originLocalityHelp}
                                error={fieldError("origin_locality")}
                            >
                                <Input
                                    id="origin_locality"
                                    type="text"
                                    value={draft.origin_locality}
                                    onChange={(e) => set("origin_locality", e.target.value)}
                                    disabled={!draft.origin_province}
                                />
                            </FormField>
                        </div>
                    </fieldset>

                    <fieldset className="zoneGroup zoneGroupDestination">
                        <legend className="zoneGroupLegend">{f.destinationLegend}</legend>
                        <div className="zoneGroupFields">
                            <FormField
                                id="destination_province"
                                label={f.fields.destinationProvince}
                                help={f.fields.destinationProvinceHelp}
                                error={fieldError("destination_province")}
                            >
                                <ProvinceSelect
                                    id="destination_province"
                                    value={draft.destination_province}
                                    onChange={(v) => {
                                        set("destination_province", v);
                                        if (!v) set("destination_locality", "");
                                    }}
                                    placeholder={l.destinationAny}
                                />
                            </FormField>

                            <FormField
                                id="destination_locality"
                                label={f.fields.destinationLocality}
                                help={f.fields.destinationLocalityHelp}
                                error={fieldError("destination_locality")}
                            >
                                <Input
                                    id="destination_locality"
                                    type="text"
                                    value={draft.destination_locality}
                                    onChange={(e) => set("destination_locality", e.target.value)}
                                    disabled={!draft.destination_province}
                                />
                            </FormField>
                        </div>
                    </fieldset>

                    <div className="windowFormNumericFields">
                        <FormField
                            id="price_per_km"
                            label={<>{f.fields.pricePerKm} <span aria-hidden="true" className="requiredStar">*</span></>}
                            help={f.fields.pricePerKmHelp}
                            error={fieldError("price_per_km")}
                        >
                            <Input
                                id="price_per_km"
                                type="text"
                                inputMode="decimal"
                                value={draft.price_per_km}
                                onChange={(e) => set("price_per_km", e.target.value)}
                                onBlur={(e) => {
                                    const normalized = e.target.value.replace(",", ".");
                                    set("price_per_km", normalized);
                                    const val = parseFloat(normalized);
                                    if (normalized && (isNaN(val) || val <= 0)) {
                                        setServerErrors((prev) => ({ ...prev, price_per_km: [f.fields.pricePerKmInvalid] }));
                                    }
                                }}
                                required
                            />
                        </FormField>

                        <FormField
                            id="max_km"
                            label={<>{f.fields.maxKm} <span aria-hidden="true" className="requiredStar">*</span></>}
                            help={f.fields.maxKmHelp}
                            error={fieldError("max_km")}
                        >
                            <Input
                                id="max_km"
                                type="text"
                                inputMode="numeric"
                                pattern="[0-9]*"
                                value={draft.max_km}
                                onChange={(e) => set("max_km", e.target.value)}
                                onBlur={(e) => {
                                    const val = parseInt(e.target.value, 10);
                                    if (e.target.value && (isNaN(val) || val <= 0)) {
                                        setServerErrors((prev) => ({ ...prev, max_km: [f.fields.maxKmInvalid] }));
                                    }
                                }}
                                required
                            />
                        </FormField>
                    </div>

                    <fieldset className="dateRange">
                        <legend>{f.periodLegend}</legend>
                        <FormField
                            id="available_from"
                            label={f.fields.availableFrom}
                            help={f.fields.availableFromHelp}
                            error={fieldError("available_from")}
                        >
                            <Input
                                id="available_from"
                                type="date"
                                min={mode === "new"
                                    ? todayMin
                                    : (initialAvailableFromRef.current && initialAvailableFromRef.current < todayMin
                                        ? initialAvailableFromRef.current
                                        : todayMin)}
                                value={draft.available_from}
                                onChange={(e) => set("available_from", e.target.value)}
                                required
                            />
                        </FormField>

                        <FormField
                            id="available_to"
                            label={f.fields.availableTo}
                            help={f.fields.availableToHelp}
                            error={fieldError("available_to")}
                        >
                            <Input
                                id="available_to"
                                type="date"
                                min={draft.available_from || todayMin}
                                value={draft.available_to}
                                onChange={(e) => set("available_to", e.target.value)}
                                required
                            />
                        </FormField>
                    </fieldset>

                    {noVehicles && mode === "new" && (
                        <div className="noVehiclesCallout" role="note">
                            <span>{f.noVehiclesAlert}</span>
                            <Link to="/carrier/vehicle/new" className="noVehiclesCtaLink">
                                {f.noVehiclesCta}
                            </Link>
                        </div>
                    )}

                    <div className="windowFormActions">
                        <Button type="submit" disabled={loading || (mode === "new" && noVehicles)}>
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
