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
import { AddressPicker, type AddressPickerValue } from "../../components/AddressPicker";
import {
    RadiusControl,
    RADIUS_DEFAULT_KM,
    RADIUS_MAX_KM,
    RADIUS_MIN_KM,
} from "../../components/RadiusControl";
import { carrierContent } from "./carrierContent";
import { Alert } from "../../components/ui/alert";
import { Button } from "../../components/ui/button";
import { FormField } from "../../components/ui/form-field";
import { Input } from "../../components/ui/input";

type Mode = "new" | "edit";

const f = carrierContent.availability.form;

// REQ-BE-00039 / ADR-014: the form holds origin + optional destination as
// AddressPickerValue (which now carries locality + admin_area parsed by the
// shared `parsePlace` helper). Two RadiusControl mounts share the same min/max.
type Draft = {
    vehicle_id: number | null;
    origin: AddressPickerValue | null;
    destination: AddressPickerValue | null;
    price_per_km: string;
    max_km: string;
    pickup_radius_km: number;
    dropoff_radius_km: number;
    available_from: string;
    available_to: string;
};

const empty: Draft = {
    vehicle_id:        null,
    origin:            null,
    destination:       null,
    price_per_km:      "",
    max_km:            "",
    pickup_radius_km:  RADIUS_DEFAULT_KM,
    dropoff_radius_km: RADIUS_DEFAULT_KM,
    available_from:    "",
    available_to:      "",
};

function toNumber(n: string | number | null | undefined): number | null {
    if (n === null || n === undefined || n === "") return null;
    const v = typeof n === "number" ? n : Number(n);
    return Number.isFinite(v) ? v : null;
}

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
    const oLat = toNumber(tw.origin_lat);
    const oLng = toNumber(tw.origin_lng);
    const dLat = toNumber(tw.destination_lat);
    const dLng = toNumber(tw.destination_lng);
    return {
        vehicle_id: tw.vehicle_id,
        origin:     oLat != null && oLng != null
            ? {
                text:       tw.origin_address,
                lat:        oLat,
                lng:        oLng,
                locality:   tw.origin_locality,
                admin_area: tw.origin_admin_area,
            }
            : null,
        destination: dLat != null && dLng != null
            ? {
                text:       tw.destination_address ?? "",
                lat:        dLat,
                lng:        dLng,
                locality:   tw.destination_locality ?? "",
                admin_area: tw.destination_admin_area ?? "",
            }
            : null,
        price_per_km:      tw.price_per_km,
        max_km:            String(tw.max_km),
        pickup_radius_km:  tw.pickup_radius_km,
        dropoff_radius_km: tw.dropoff_radius_km ?? RADIUS_DEFAULT_KM,
        available_from:    toLocalDate(tw.available_from),
        available_to:      toLocalDate(tw.available_to),
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

    function set<K extends keyof Draft>(key: K, value: Draft[K]) {
        setDraft((prev) => {
            const next = { ...prev, [key]: value };
            // Clearing the destination address must also reset the dropoff radius
            // so a partially-filled destination block never reaches the server.
            if (key === "destination" && value === null) {
                next.dropoff_radius_km = RADIUS_DEFAULT_KM;
            }
            return next;
        });
        if (serverErrors[key as string]) setServerErrors((prev) => ({ ...prev, [key as string]: [] }));
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
        if (!draft.origin) {
            setError(f.originPinRequired);
            return;
        }
        if (!draft.available_from || !draft.available_to) {
            setError(f.saveError);
            return;
        }
        if (
            !Number.isInteger(draft.pickup_radius_km) ||
            draft.pickup_radius_km < RADIUS_MIN_KM ||
            draft.pickup_radius_km > RADIUS_MAX_KM
        ) {
            setError(f.pickupRadiusOutOfRange);
            return;
        }
        if (
            draft.destination && (
                !Number.isInteger(draft.dropoff_radius_km) ||
                draft.dropoff_radius_km < RADIUS_MIN_KM ||
                draft.dropoff_radius_km > RADIUS_MAX_KM
            )
        ) {
            setError(f.dropoffRadiusOutOfRange);
            return;
        }
        setLoading(true);
        setError(null);
        setServerErrors({});
        try {
            const payload: TransportWindowDraft = {
                vehicle_id:             draft.vehicle_id,
                origin_address:         draft.origin.text.trim(),
                origin_locality:        (draft.origin.locality ?? "").trim(),
                origin_admin_area:      (draft.origin.admin_area ?? "").trim(),
                origin_lat:             draft.origin.lat,
                origin_lng:             draft.origin.lng,
                destination_address:    draft.destination ? draft.destination.text.trim() : null,
                destination_locality:   draft.destination ? (draft.destination.locality ?? "").trim() : null,
                destination_admin_area: draft.destination ? (draft.destination.admin_area ?? "").trim() : null,
                destination_lat:        draft.destination?.lat ?? null,
                destination_lng:        draft.destination?.lng ?? null,
                price_per_km:           draft.price_per_km,
                max_km:                 draft.max_km,
                pickup_radius_km:       draft.pickup_radius_km,
                dropoff_radius_km:      draft.destination ? draft.dropoff_radius_km : null,
                available_from:         draft.available_from + "T00:00",
                available_to:           draft.available_to + "T23:59",
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
    const destinationPin = draft.destination
        ? { lat: draft.destination.lat, lng: draft.destination.lng }
        : null;
    const originPin = draft.origin
        ? { lat: draft.origin.lat, lng: draft.origin.lng }
        : null;

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
                                id="origin_address"
                                label={<>{f.fields.originAddress} <span aria-hidden="true" className="requiredStar">*</span></>}
                                help={f.fields.originAddressHelp}
                                error={
                                    fieldError("origin_address")
                                    ?? fieldError("origin_locality")
                                    ?? fieldError("origin_admin_area")
                                    ?? fieldError("origin_lat")
                                    ?? fieldError("origin_lng")
                                }
                            >
                                <AddressPicker
                                    id="origin_address"
                                    name="origin"
                                    value={draft.origin}
                                    onChange={(v) => set("origin", v)}
                                    required
                                />
                            </FormField>
                        </div>
                        <RadiusControl
                            id="pickup_radius_km"
                            name="pickup_radius_km"
                            role="pickup"
                            pin={originPin}
                            value={draft.pickup_radius_km}
                            onChange={(v) => set("pickup_radius_km", v)}
                            label={f.fields.pickupRadiusKm}
                            help={f.fields.pickupRadiusKmHelp}
                            placeholderWhenNoPin={f.fields.pickupRadiusKmNoOrigin}
                            error={fieldError("pickup_radius_km")}
                            required
                        />
                    </fieldset>

                    <fieldset className="zoneGroup zoneGroupDestination">
                        <legend className="zoneGroupLegend">{f.destinationLegend}</legend>
                        <div className="zoneGroupFields">
                            <FormField
                                id="destination_address"
                                label={f.fields.destinationAddress}
                                help={f.fields.destinationAddressHelp}
                                error={
                                    fieldError("destination_address")
                                    ?? fieldError("destination_locality")
                                    ?? fieldError("destination_admin_area")
                                    ?? fieldError("destination_lat")
                                    ?? fieldError("destination_lng")
                                    ?? fieldError("base")
                                }
                            >
                                <AddressPicker
                                    id="destination_address"
                                    name="destination"
                                    value={draft.destination}
                                    onChange={(v) => set("destination", v)}
                                />
                            </FormField>
                        </div>
                        {destinationPin && (
                            <RadiusControl
                                id="dropoff_radius_km"
                                name="dropoff_radius_km"
                                role="dropoff"
                                pin={destinationPin}
                                value={draft.dropoff_radius_km}
                                onChange={(v) => set("dropoff_radius_km", v)}
                                label={f.fields.dropoffRadiusKm}
                                help={f.fields.dropoffRadiusKmHelp}
                                placeholderWhenNoPin={f.fields.dropoffRadiusKmNoDestination}
                                error={fieldError("dropoff_radius_km")}
                                required
                            />
                        )}
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
