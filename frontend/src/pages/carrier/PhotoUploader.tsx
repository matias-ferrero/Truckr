import { useCallback, useEffect, useMemo } from "react";
import { useDropzone } from "react-dropzone";
import { carrierContent } from "./carrierContent";
import { cn } from "../../lib/utils";

const u = carrierContent.uploader;

const ACCEPTED = {
    "image/jpeg": [".jpg", ".jpeg"],
    "image/png": [".png"],
    "image/webp": [".webp"],
};

export type UploaderFile = {
    file: File;
    preview: string;
};

export type PhotoUploaderProps = {
    files: UploaderFile[];
    onChange: (files: UploaderFile[]) => void;
    max?: number;
    label?: string;
};

const DEFAULT_MAX = 5;

// Drag-drop wrapper around react-dropzone. Manages object URLs so previews
// don't leak. Caller owns the array; this component just emits the next
// value via `onChange`.
export default function PhotoUploader({
    files,
    onChange,
    max = DEFAULT_MAX,
    label = u.defaultLabel,
}: PhotoUploaderProps) {
    const remaining = max - files.length;

    const onDrop = useCallback(
        (accepted: File[]) => {
            if (accepted.length === 0) return;
            const next = [...files];
            for (const file of accepted) {
                if (next.length >= max) break;
                next.push({ file, preview: URL.createObjectURL(file) });
            }
            onChange(next);
        },
        [files, max, onChange],
    );

    const { getRootProps, getInputProps, isDragActive, isDragReject } = useDropzone({
        onDrop,
        accept: ACCEPTED,
        disabled: remaining <= 0,
        multiple: true,
        maxFiles: remaining,
    });

    useEffect(() => {
        return () => {
            for (const f of files) URL.revokeObjectURL(f.preview);
        };
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

    const removeAt = useCallback(
        (idx: number) => {
            const next = files.slice();
            const [gone] = next.splice(idx, 1);
            if (gone) URL.revokeObjectURL(gone.preview);
            onChange(next);
        },
        [files, onChange],
    );

    const helper = useMemo(() => {
        if (remaining <= 0) return u.limitReached(max);
        if (isDragReject) return u.rejected;
        if (isDragActive) return u.active;
        return u.prompt(remaining);
    }, [remaining, isDragActive, isDragReject, max]);

    return (
        <div className="grid gap-3">
            <div className="flex items-baseline justify-between gap-3">
                <label
                    htmlFor="photo-uploader-input"
                    className="text-sm font-semibold text-ink"
                >
                    {label}
                </label>
                <em className="text-xs text-ink-faint not-italic">
                    {u.accept} — {u.max(max)}
                </em>
            </div>
            <div
                {...getRootProps({
                    className: cn(
                        "rounded-sm border-2 border-dashed border-stroke-strong px-6 py-8 text-center cursor-pointer outline-none",
                        "transition-[border-color,background-color] duration-150 ease-[var(--ease-out-soft)]",
                        "focus-visible:shadow-[0_0_0_3px_color-mix(in_oklab,var(--color-brand)_50%,transparent)]",
                        isDragActive &&
                            "border-brand bg-[color-mix(in_oklab,var(--color-brand)_10%,transparent)]",
                        isDragReject && "border-brand-error text-brand-error",
                        remaining <= 0 && "opacity-50 cursor-not-allowed",
                    ),
                    role: "button",
                    "aria-label": label,
                })}
            >
                <input id="photo-uploader-input" {...getInputProps({ "aria-label": label })} />
                <p className="m-0 text-ink-soft">{helper}</p>
            </div>
            {files.length > 0 && (
                <ul
                    className="m-0 p-0 list-none grid gap-3 grid-cols-[repeat(auto-fill,minmax(140px,1fr))]"
                    aria-label={u.gridLabel}
                >
                    {files.map((f, idx) => (
                        <li
                            key={`${f.file.name}-${idx}`}
                            className="relative rounded-sm overflow-hidden aspect-[4/3] bg-[color-mix(in_oklab,var(--color-ink)_4%,transparent)]"
                        >
                            <img
                                src={f.preview}
                                alt={f.file.name}
                                loading="lazy"
                                decoding="async"
                                className="w-full h-full object-cover block"
                            />
                            <button
                                type="button"
                                onClick={() => removeAt(idx)}
                                aria-label={u.removeFile(f.file.name)}
                                title={u.remove}
                                className="absolute bottom-1.5 right-1.5 inline-flex items-center justify-center gap-1.5 min-w-11 min-h-11 px-3.5 rounded-full bg-[color-mix(in_oklab,var(--color-ink)_78%,transparent)] text-paper text-xs font-semibold border-0 cursor-pointer transition-[background-color] duration-150 ease-[var(--ease-out-soft)] hover:bg-[color-mix(in_oklab,var(--color-ink)_88%,transparent)] focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-paper focus-visible:ring-offset-2"
                            >
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
                                <span>{u.remove}</span>
                            </button>
                        </li>
                    ))}
                </ul>
            )}
        </div>
    );
}
