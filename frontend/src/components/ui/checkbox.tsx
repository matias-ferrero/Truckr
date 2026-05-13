import { forwardRef } from "react";
import { cn } from "../../lib/utils";

export type CheckboxProps =
    & Omit<React.InputHTMLAttributes<HTMLInputElement>, "type">
    & { label?: React.ReactNode };

// Native checkbox styled with Tailwind. Wraps in a label so the click target
// covers the full row — keeps the existing carrier "GPS habilitado" UX.
export const Checkbox = forwardRef<HTMLInputElement, CheckboxProps>(
    ({ className, label, ...props }, ref) => {
        const input = (
            <input
                ref={ref}
                type="checkbox"
                className={cn(
                    "size-5 shrink-0 rounded-[4px] border border-stroke bg-paper accent-ink",
                    "focus-visible:outline-none focus-visible:ring-[3px] focus-visible:ring-ring",
                    "disabled:cursor-not-allowed disabled:opacity-50",
                    className,
                )}
                {...props}
            />
        );
        if (label === undefined) return input;
        return (
            <label className="inline-flex items-center gap-3 text-sm text-ink cursor-pointer select-none">
                {input}
                <span>{label}</span>
            </label>
        );
    },
);
Checkbox.displayName = "Checkbox";
