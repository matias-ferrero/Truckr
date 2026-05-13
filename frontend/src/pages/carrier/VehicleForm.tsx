import { cloneElement, isValidElement, useEffect, useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import PhotoUploader, { UploaderFile } from "./PhotoUploader";
import {
    createVehicle,
    getMyVehicle,
    updateVehicle,
    Vehicle,
} from "../../api/vehicles";
import { carrierContent } from "./carrierContent";

type Mode = "primary" | "new" | "edit";

const f = carrierContent.form;

const VEHICLE_TYPES = Object.entries(carrierContent.vehicleTypes).map(
    ([value, label]) => ({ value, label }),
);

const PLATE_HINT = /^[A-Z0-9]{6,8}$/i;

type Draft = {
    make: string;
    model: string;
    year: string;
    plate: string;
    vehicle_type: string;
    max_load_kg: string;
    length_cm: string;
    width_cm: string;
    height_cm: string;
    description: string;
    gps_enabled: boolean;
};

const empty: Draft = {
    make: "",
    model: "",
    year: "",
    plate: "",
    vehicle_type: "truck_small",
    max_load_kg: "",
    length_cm: "",
    width_cm: "",
    height_cm: "",
    description: "",
    gps_enabled: false,
};

function fromVehicle(v: Vehicle): Draft {
    return {
        make: v.make,
        model: v.model,
        year: v.year != null ? String(v.year) : "",
        plate: v.plate,
        vehicle_type: v.vehicle_type,
        max_load_kg: v.max_load_kg,
        length_cm: v.length_cm != null ? String(v.length_cm) : "",
        width_cm: v.width_cm != null ? String(v.width_cm) : "",
        height_cm: v.height_cm != null ? String(v.height_cm) : "",
        description: v.description ?? "",
        gps_enabled: v.gps_enabled,
    };
}

type Props = { mode: Mode };

export default function VehicleForm({ mode }: Props) {
    const navigate = useNavigate();
    const params = useParams();
    const editingId = mode === "edit" && params.id ? Number(params.id) : null;

    const [draft, setDraft] = useState<Draft>(empty);
    const [photos, setPhotos] = useState<UploaderFile[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [serverErrors, setServerErrors] = useState<Record<string, string[]>>({});
    const [hydrating, setHydrating] = useState(editingId != null);

    useEffect(() => {
        if (editingId == null) return;
        let cancelled = false;
        (async () => {
            try {
                const v = await getMyVehicle(editingId);
                if (cancelled) return;
                setDraft(fromVehicle(v));
            } catch (e) {
                if (!cancelled) setError((e as Error).message);
            } finally {
                if (!cancelled) setHydrating(false);
            }
        })();
        return () => {
            cancelled = true;
        };
    }, [editingId]);

    const volumePreview = useMemo(() => {
        const l = Number(draft.length_cm);
        const w = Number(draft.width_cm);
        const h = Number(draft.height_cm);
        if (!l || !w || !h) return null;
        return l * w * h;
    }, [draft.length_cm, draft.width_cm, draft.height_cm]);

    const plateWarning = useMemo(() => {
        const v = draft.plate.trim();
        if (!v) return null;
        if (!PLATE_HINT.test(v)) return f.plateHint;
        return null;
    }, [draft.plate]);

    function update<K extends keyof Draft>(key: K, value: Draft[K]) {
        setDraft((d) => ({ ...d, [key]: value }));
    }

    async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
        e.preventDefault();
        setError(null);
        setServerErrors({});
        setLoading(true);
        try {
            const fd = new FormData();
            const payload = {
                ...draft,
                year: draft.year ? Number(draft.year) : "",
                length_cm: draft.length_cm ? Number(draft.length_cm) : "",
                width_cm: draft.width_cm ? Number(draft.width_cm) : "",
                height_cm: draft.height_cm ? Number(draft.height_cm) : "",
            };
            for (const [k, v] of Object.entries(payload)) {
                fd.append(`vehicle[${k}]`, String(v));
            }
            for (const p of photos) {
                fd.append("vehicle[photos][]", p.file, p.file.name);
            }
            const saved = editingId != null
                ? await updateVehicle(editingId, fd)
                : await createVehicle(fd);
            navigate(`/carrier/vehicles`, {
                state: { highlightId: saved.id, mode },
            });
        } catch (e) {
            const err = e as Error & {
                body?: { error?: string; details?: Record<string, string[]> };
            };
            if (err.body?.details) setServerErrors(err.body.details);
            setError(err.message ?? f.saveError);
        } finally {
            setLoading(false);
        }
    }

    if (hydrating) {
        return (
            <main className="page carrierMain" id="main" aria-busy="true" aria-label={f.hydrating}>
                <div className="container">
                    <header className="formHeader">
                        <h1 className="sectionTitle skeletonText" aria-hidden="true">&nbsp;</h1>
                    </header>
                    <div className="vehicleForm skeleton">
                        <div className="skeletonCard" style={{ height: 280 }} />
                    </div>
                </div>
            </main>
        );
    }

    const title = mode === "edit"
        ? f.editTitle
        : mode === "new"
        ? f.newTitle
        : f.primaryTitle;

    return (
        <main className="page carrierMain" id="main">
            <div className="container">
                <header className="formHeader">
                    <h1 className="sectionTitle">{title}</h1>
                    <p className="sectionLead">{f.lead}</p>
                </header>

                <form className="form vehicleForm" onSubmit={handleSubmit} noValidate>
                    {error && (
                        <div className="error" role="alert">
                            {error}
                        </div>
                    )}

                    <div className="fieldGrid">
                        <Field label={f.fields.make} id="make" error={serverErrors.make?.[0]}>
                            <input
                                id="make"
                                className="input"
                                value={draft.make}
                                onChange={(e) => update("make", e.target.value)}
                                required
                                maxLength={64}
                            />
                        </Field>
                        <Field label={f.fields.model} id="model" error={serverErrors.model?.[0]}>
                            <input
                                id="model"
                                className="input"
                                value={draft.model}
                                onChange={(e) => update("model", e.target.value)}
                                required
                                maxLength={64}
                            />
                        </Field>
                        <Field label={f.fields.year} id="year" error={serverErrors.year?.[0]}>
                            <input
                                id="year"
                                className="input"
                                inputMode="numeric"
                                value={draft.year}
                                onChange={(e) => update("year", e.target.value)}
                            />
                        </Field>
                        <Field
                            label={f.fields.plate}
                            id="plate"
                            error={serverErrors.plate?.[0]}
                            help={plateWarning ?? undefined}
                        >
                            <input
                                id="plate"
                                className="input"
                                value={draft.plate}
                                onChange={(e) => update("plate", e.target.value.toUpperCase())}
                                required
                            />
                        </Field>
                        <Field
                            label={f.fields.vehicleType}
                            id="vehicle_type"
                            error={serverErrors.vehicle_type?.[0]}
                        >
                            <select
                                id="vehicle_type"
                                className="input"
                                value={draft.vehicle_type}
                                onChange={(e) => update("vehicle_type", e.target.value)}
                            >
                                {VEHICLE_TYPES.map((t) => (
                                    <option key={t.value} value={t.value}>
                                        {t.label}
                                    </option>
                                ))}
                            </select>
                        </Field>
                        <Field
                            label={f.fields.maxLoadKg}
                            id="max_load_kg"
                            error={serverErrors.max_load_kg?.[0]}
                        >
                            <input
                                id="max_load_kg"
                                className="input"
                                inputMode="decimal"
                                value={draft.max_load_kg}
                                onChange={(e) => update("max_load_kg", e.target.value)}
                                required
                            />
                        </Field>
                    </div>

                    <fieldset className="dimensions">
                        <legend>{f.fields.dimensions}</legend>
                        <div className="fieldGrid">
                            <Field label={f.fields.length} id="length_cm">
                                <input
                                    id="length_cm"
                                    className="input"
                                    inputMode="numeric"
                                    value={draft.length_cm}
                                    onChange={(e) => update("length_cm", e.target.value)}
                                />
                            </Field>
                            <Field label={f.fields.width} id="width_cm">
                                <input
                                    id="width_cm"
                                    className="input"
                                    inputMode="numeric"
                                    value={draft.width_cm}
                                    onChange={(e) => update("width_cm", e.target.value)}
                                />
                            </Field>
                            <Field label={f.fields.height} id="height_cm">
                                <input
                                    id="height_cm"
                                    className="input"
                                    inputMode="numeric"
                                    value={draft.height_cm}
                                    onChange={(e) => update("height_cm", e.target.value)}
                                />
                            </Field>
                        </div>
                        {volumePreview != null && (
                            <p className="help" aria-live="polite">
                                {f.volumeLabel(volumePreview.toLocaleString("es-AR"))}
                            </p>
                        )}
                    </fieldset>

                    <Field label={f.fields.description} id="description">
                        <textarea
                            id="description"
                            className="input textarea"
                            rows={3}
                            value={draft.description}
                            onChange={(e) => update("description", e.target.value)}
                            maxLength={500}
                        />
                    </Field>

                    <label className="toggleRow">
                        <input
                            type="checkbox"
                            checked={draft.gps_enabled}
                            onChange={(e) => update("gps_enabled", e.target.checked)}
                        />
                        <span>{f.fields.gps}</span>
                    </label>

                    <PhotoUploader files={photos} onChange={setPhotos} />

                    <div className="ctaRow">
                        <button
                            type="submit"
                            className="button buttonPrimary"
                            disabled={loading}
                        >
                            {loading
                                ? f.submit.saving
                                : editingId
                                ? f.submit.update
                                : f.submit.create}
                        </button>
                        <button
                            type="button"
                            className="button buttonGhost"
                            onClick={() => navigate("/carrier/vehicles")}
                        >
                            {f.submit.cancel}
                        </button>
                    </div>
                </form>
            </div>
        </main>
    );
}

type FieldProps = {
    label: string;
    id: string;
    error?: string;
    help?: string;
    children: React.ReactNode;
};

function Field({ label, id, error, help, children }: FieldProps) {
    const errorId = `${id}-error`;
    const helpId = `${id}-help`;
    const describedBy = error ? errorId : help ? helpId : undefined;

    let control: React.ReactNode = children;
    if (isValidElement(children)) {
        control = cloneElement(
            children as React.ReactElement<Record<string, unknown>>,
            {
                "aria-invalid": error ? "true" : undefined,
                "aria-describedby": describedBy,
            } as Record<string, unknown>,
        );
    }

    return (
        <div className="field">
            <div className="labelRow">
                <label htmlFor={id}>{label}</label>
            </div>
            {control}
            {error && (
                <div id={errorId} className="error" role="alert">
                    {error}
                </div>
            )}
            {!error && help && <div id={helpId} className="help">{help}</div>}
        </div>
    );
}
