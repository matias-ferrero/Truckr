import { useCallback, useEffect, useMemo } from "react";
import { useDropzone } from "react-dropzone";
import { carrierContent } from "./carrierContent";

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
        <div className="uploader">
            <div className="labelRow">
                <label htmlFor="photo-uploader-input">{label}</label>
                <em>{u.accept} — {u.max(max)}</em>
            </div>
            <div
                {...getRootProps({
                    className: `uploaderDrop${isDragActive ? " isActive" : ""}${
                        isDragReject ? " isReject" : ""
                    }${remaining <= 0 ? " isDisabled" : ""}`,
                    role: "button",
                    "aria-label": label,
                })}
            >
                <input id="photo-uploader-input" {...getInputProps({ "aria-label": label })} />
                <p className="uploaderHint">{helper}</p>
            </div>
            {files.length > 0 && (
                <ul className="uploaderGrid" aria-label={u.gridLabel}>
                    {files.map((f, idx) => (
                        <li key={`${f.file.name}-${idx}`} className="uploaderItem">
                            <img
                                src={f.preview}
                                alt={f.file.name}
                                loading="lazy"
                                decoding="async"
                            />
                            <button
                                type="button"
                                onClick={() => removeAt(idx)}
                                aria-label={u.removeFile(f.file.name)}
                            >
                                {u.remove}
                            </button>
                        </li>
                    ))}
                </ul>
            )}
        </div>
    );
}
