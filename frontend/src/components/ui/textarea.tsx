import { forwardRef } from "react";
import { cn } from "../../lib/utils";

export type TextareaProps = React.TextareaHTMLAttributes<HTMLTextAreaElement>;

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(
    ({ className, rows = 3, ...props }, ref) => (
        <textarea
            ref={ref}
            rows={rows}
            className={cn(
                "flex w-full min-h-24 rounded-sm border border-stroke bg-paper px-3.5 py-3 text-base text-ink",
                "placeholder:text-ink-faint resize-y",
                "transition-[border-color,box-shadow] duration-150 ease-[var(--ease-out-soft)]",
                "focus-visible:outline-none focus-visible:ring-[3px] focus-visible:ring-ring",
                "focus-visible:border-[color-mix(in_oklab,var(--color-brand)_70%,var(--color-ink))]",
                "aria-invalid:border-[color-mix(in_oklab,var(--color-brand-error)_80%,var(--color-ink))]",
                "disabled:cursor-not-allowed disabled:opacity-50",
                className,
            )}
            {...props}
        />
    ),
);
Textarea.displayName = "Textarea";
