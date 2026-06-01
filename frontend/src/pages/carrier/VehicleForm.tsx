import { useEffect, useMemo, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import PhotoUploader, { UploaderFile } from "./PhotoUploader";
import {
    createVehicle,
    getMyVehicle,
    updateVehicle,
    Vehicle,
    VehiclePhoto,
} from "../../api/vehicles";
import { carrierContent } from "./carrierContent";
import { Button } from "../../components/ui/button";
import { Input } from "../../components/ui/input";
import { Textarea } from "../../components/ui/textarea";
import { Select } from "../../components/ui/select";
import { Checkbox } from "../../components/ui/checkbox";
import { Alert } from "../../components/ui/alert";
import { FormField } from "../../components/ui/form-field";

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
    const [existingPhotos, setExistingPhotos] = useState<VehiclePhoto[]>([]);
    const [removedPhotoIds, setRemovedPhotoIds] = useState<Set<number>>(new Set());
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
                setExistingPhotos(v.photos);
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

    // Photos the user hasn't marked for removal.
    const keptExistingPhotos = useMemo(
        () => existingPhotos.filter((p) => !removedPhotoIds.has(p.id)),
        [existingPhotos, removedPhotoIds],
    );

    const toggleRemoveExisting = (id: number) => {
        setRemovedPhotoIds((prev) => {
            const next = new Set(prev);
            if (next.has(id)) next.delete(id);
            else next.add(id);
            return next;
        });
    };

    // Backend enforces MAX_PHOTOS=5 on the total set. Constrain the uploader
    // by what's still available after kept-existing so the count agrees.
    const PHOTO_LIMIT = 5;
    const remainingPhotoSlots = Math.max(0, PHOTO_LIMIT - keptExistingPhotos.length);

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

    const plateHelp = mode === "edit" ? f.plateLockedHelp : plateWarning ?? undefined;

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
            for (const id of removedPhotoIds) {
                fd.append("vehicle[remove_photo_ids][]", String(id));
            }
            const saved = editingId != null
                ? await updateVehicle(editingId, fd)
                : await createVehicle(fd);
            navigate(`/carrier/vehicles`, {
                state: { highlightId: saved.id, mode },
            });
        } catch (e) {
            const err = e as Error & {
                body?: { error?: { details?: Record<string, string[]> } };
            };
            const details = err.body?.error?.details;
            if (details) setServerErrors(details);
            // When the backend returned per-field details, the inline
            // FormField messages are the real signal — keep the banner
            // generic to avoid showing the [object Object]-shaped fallback.
            setError(details ? f.saveError : (err.message ?? f.saveError));
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
                    <div className="grid gap-6">
                        <div
                            className="rounded-md animate-[skeleton_1.4s_linear_infinite] bg-[linear-gradient(90deg,color-mix(in_oklab,var(--color-ink)_4%,transparent),color-mix(in_oklab,var(--color-ink)_8%,transparent),color-mix(in_oklab,var(--color-ink)_4%,transparent))] bg-[length:200%_100%] motion-reduce:animate-none"
                            style={{ height: 280 }}
                        />
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

                <form
                    className="grid gap-6 bg-paper p-6 rounded-md shadow-[0_6px_24px_color-mix(in_oklab,var(--color-ink)_6%,transparent)]"
                    onSubmit={handleSubmit}
                    noValidate
                >
                    {error && (
                        <Alert tone="error" aria-live="assertive">
                            {error}
                        </Alert>
                    )}

                    <div className="grid gap-4 grid-cols-[repeat(auto-fit,minmax(220px,1fr))]">
                        <FormField label={f.fields.make} id="make" error={serverErrors.make?.[0]}>
                            <Input
                                id="make"
                                value={draft.make}
                                onChange={(e) => update("make", e.target.value)}
                                required
                                maxLength={64}
                            />
                        </FormField>
                        <FormField label={f.fields.model} id="model" error={serverErrors.model?.[0]}>
                            <Input
                                id="model"
                                value={draft.model}
                                onChange={(e) => update("model", e.target.value)}
                                required
                                maxLength={64}
                            />
                        </FormField>
                        <FormField label={f.fields.year} id="year" error={serverErrors.year?.[0]}>
                            <Input
                                id="year"
                                inputMode="numeric"
                                value={draft.year}
                                onChange={(e) => update("year", e.target.value)}
                            />
                        </FormField>
                        <FormField
                            label={f.fields.plate}
                            id="plate"
                            error={serverErrors.plate?.[0]}
                            help={plateHelp}
                        >
                            <Input
                                id="plate"
                                value={draft.plate}
                                onChange={(e) => update("plate", e.target.value.toUpperCase())}
                                required
                                disabled={mode === "edit"}
                            />
                        </FormField>
                        <FormField
                            label={f.fields.vehicleType}
                            id="vehicle_type"
                            error={serverErrors.vehicle_type?.[0]}
                        >
                            <Select
                                id="vehicle_type"
                                value={draft.vehicle_type}
                                onChange={(e) => update("vehicle_type", e.target.value)}
                            >
                                {VEHICLE_TYPES.map((t) => (
                                    <option key={t.value} value={t.value}>
                                        {t.label}
                                    </option>
                                ))}
                            </Select>
                        </FormField>
                        <FormField
                            label={f.fields.maxLoadKg}
                            id="max_load_kg"
                            error={serverErrors.max_load_kg?.[0]}
                        >
                            <Input
                                id="max_load_kg"
                                inputMode="decimal"
                                value={draft.max_load_kg}
                                onChange={(e) => update("max_load_kg", e.target.value)}
                                required
                            />
                        </FormField>
                    </div>

                    <fieldset className="border border-stroke rounded-sm p-4">
                        <legend className="px-2 font-semibold text-ink">
                            {f.fields.dimensions}
                        </legend>
                        <div className="grid gap-4 grid-cols-[repeat(auto-fit,minmax(220px,1fr))]">
                            <FormField label={f.fields.length} id="length_cm">
                                <Input
                                    id="length_cm"
                                    inputMode="numeric"
                                    value={draft.length_cm}
                                    onChange={(e) => update("length_cm", e.target.value)}
                                />
                            </FormField>
                            <FormField label={f.fields.width} id="width_cm">
                                <Input
                                    id="width_cm"
                                    inputMode="numeric"
                                    value={draft.width_cm}
                                    onChange={(e) => update("width_cm", e.target.value)}
                                />
                            </FormField>
                            <FormField label={f.fields.height} id="height_cm">
                                <Input
                                    id="height_cm"
                                    inputMode="numeric"
                                    value={draft.height_cm}
                                    onChange={(e) => update("height_cm", e.target.value)}
                                />
                            </FormField>
                        </div>
                        {volumePreview != null && (
                            <p className="text-xs text-ink-faint mt-3" aria-live="polite">
                                {f.volumeLabel(volumePreview.toLocaleString("es-AR"))}
                            </p>
                        )}
                    </fieldset>

                    <FormField label={f.fields.description} id="description">
                        <Textarea
                            id="description"
                            rows={3}
                            value={draft.description}
                            onChange={(e) => update("description", e.target.value)}
                            maxLength={500}
                        />
                    </FormField>

                    <Checkbox
                        checked={draft.gps_enabled}
                        onChange={(e) => update("gps_enabled", e.target.checked)}
                        label={f.fields.gps}
                    />

                    {existingPhotos.length > 0 && (
                        <section
                            className="grid gap-3"
                            aria-labelledby="existing-photos-title"
                        >
                            <header className="flex items-baseline justify-between gap-3 flex-wrap">
                                <h3
                                    id="existing-photos-title"
                                    className="m-0 text-sm font-semibold text-ink"
                                >
                                    {f.existingPhotosTitle}
                                </h3>
                                <em
                                    className="not-italic text-xs tabular-nums text-ink-faint"
                                    aria-live="polite"
                                >
                                    {f.existingPhotosCount(keptExistingPhotos.length, PHOTO_LIMIT)}
                                </em>
                            </header>
                            <ul
                                className="list-none m-0 p-0 grid gap-3 grid-cols-[repeat(auto-fill,minmax(140px,1fr))]"
                                aria-label={f.existingPhotosTitle}
                            >
                                {existingPhotos.map((p) => {
                                    const removed = removedPhotoIds.has(p.id);
                                    const photoLabel = f.photoAlt(
                                        `${draft.make} ${draft.model}`.trim(),
                                    );
                                    return (
                                        <li
                                            key={p.id}
                                            className="relative rounded-sm overflow-hidden aspect-[4/3] bg-[color-mix(in_oklab,var(--color-ink)_4%,transparent)] ring-1 ring-inset ring-stroke"
                                        >
                                            <img
                                                src={p.thumbnail}
                                                alt={photoLabel}
                                                loading="lazy"
                                                decoding="async"
                                                className={`w-full h-full object-cover block transition-[opacity,filter] duration-200 ease-[var(--ease-out-soft)] ${
                                                    removed
                                                        ? "opacity-25 grayscale"
                                                        : "opacity-100 grayscale-0"
                                                }`}
                                            />
                                            {removed && (
                                                <div
                                                    className="pointer-events-none absolute inset-0 flex items-start p-2 bg-[color-mix(in_oklab,var(--color-brand-error)_22%,transparent)]"
                                                    aria-hidden="true"
                                                >
                                                    <span className="inline-flex items-center gap-1 rounded-full bg-brand-error text-paper text-[10px] font-semibold uppercase tracking-wide px-2 py-0.5">
                                                        <svg
                                                            viewBox="0 0 16 16"
                                                            width="10"
                                                            height="10"
                                                            aria-hidden="true"
                                                            fill="none"
                                                            stroke="currentColor"
                                                            strokeWidth="2"
                                                            strokeLinecap="round"
                                                            strokeLinejoin="round"
                                                        >
                                                            <path d="M3 5h10M6 5V3.5A.5.5 0 0 1 6.5 3h3a.5.5 0 0 1 .5.5V5M4.5 5l.6 7.5a1 1 0 0 0 1 .9h3.8a1 1 0 0 0 1-.9L11.5 5" />
                                                        </svg>
                                                        {f.existingPhotoMarked}
                                                    </span>
                                                </div>
                                            )}
                                            <button
                                                type="button"
                                                onClick={() => toggleRemoveExisting(p.id)}
                                                aria-pressed={removed}
                                                aria-label={(removed
                                                    ? f.existingPhotoUndoAria
                                                    : f.existingPhotoRemoveAria)(photoLabel)}
                                                title={removed ? f.existingPhotoUndo : f.existingPhotoRemove}
                                                className={`absolute bottom-1.5 right-1.5 inline-flex items-center justify-center gap-1.5 min-h-11 px-3.5 rounded-full border-0 text-xs font-semibold cursor-pointer transition-[background-color,color,box-shadow] duration-150 ease-[var(--ease-out-soft)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-paper focus-visible:ring-offset-2 ${
                                                    removed
                                                        ? "bg-paper text-ink shadow-[0_2px_8px_color-mix(in_oklab,var(--color-ink)_22%,transparent)] hover:bg-[color-mix(in_oklab,var(--color-paper)_92%,var(--color-ink))]"
                                                        : "bg-[color-mix(in_oklab,var(--color-ink)_78%,transparent)] text-paper hover:bg-[color-mix(in_oklab,var(--color-ink)_88%,transparent)]"
                                                }`}
                                            >
                                                {removed
                                                    ? (
                                                        <svg
                                                            viewBox="0 0 16 16"
                                                            width="12"
                                                            height="12"
                                                            aria-hidden="true"
                                                            fill="none"
                                                            stroke="currentColor"
                                                            strokeWidth="2"
                                                            strokeLinecap="round"
                                                            strokeLinejoin="round"
                                                        >
                                                            <path d="M3 8a5 5 0 1 0 1.5-3.5" />
                                                            <path d="M3 3v3h3" />
                                                        </svg>
                                                    )
                                                    : (
                                                        <svg
                                                            viewBox="0 0 16 16"
                                                            width="12"
                                                            height="12"
                                                            aria-hidden="true"
                                                            fill="none"
                                                            stroke="currentColor"
                                                            strokeWidth="2"
                                                            strokeLinecap="round"
                                                            strokeLinejoin="round"
                                                        >
                                                            <path d="M3 5h10M6 5V3.5A.5.5 0 0 1 6.5 3h3a.5.5 0 0 1 .5.5V5M4.5 5l.6 7.5a1 1 0 0 0 1 .9h3.8a1 1 0 0 0 1-.9L11.5 5" />
                                                        </svg>
                                                    )}
                                                <span>{removed ? f.existingPhotoUndo : f.existingPhotoRemove}</span>
                                            </button>
                                        </li>
                                    );
                                })}
                            </ul>
                            {removedPhotoIds.size > 0 && (
                                <p
                                    className="m-0 text-xs text-brand-error font-medium"
                                    aria-live="polite"
                                >
                                    {f.existingPhotosPending(removedPhotoIds.size)}
                                </p>
                            )}
                        </section>
                    )}

                    <PhotoUploader
                        files={photos}
                        onChange={setPhotos}
                        max={remainingPhotoSlots}
                    />

                    <div className="flex flex-wrap gap-3">
                        <Button type="submit" disabled={loading}>
                            {loading
                                ? f.submit.saving
                                : editingId
                                ? f.submit.update
                                : f.submit.create}
                        </Button>
                        <Button
                            type="button"
                            variant="ghost"
                            onClick={() =>
                                window.history.length > 1
                                    ? navigate(-1)
                                    : navigate("/carrier/vehicles")}
                        >
                            {f.submit.cancel}
                        </Button>
                    </div>
                </form>
            </div>
        </main>
    );
}
