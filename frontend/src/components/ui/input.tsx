import { forwardRef } from "react";
import { cn } from "../../lib/utils";

export type InputProps = React.InputHTMLAttributes<HTMLInputElement>;

export const Input = forwardRef<HTMLInputElement, InputProps>(
    ({ className, type = "text", ...props }, ref) => (
        <input
            ref={ref}
            type={type}
            className={cn(
                "flex w-full min-h-11 rounded-sm border border-stroke bg-paper px-3.5 py-3 text-base text-ink",
                "placeholder:text-ink-faint",
                "transition-[border-color,box-shadow] duration-150 ease-[var(--ease-out-soft)]",
                "focus-visible:outline-none focus-visible:ring-[3px] focus-visible:ring-ring focus-visible:ring-offset-0",
                "focus-visible:border-[color-mix(in_oklab,var(--color-brand)_70%,var(--color-ink))]",
                "aria-invalid:border-[color-mix(in_oklab,var(--color-brand-error)_80%,var(--color-ink))]",
                "disabled:cursor-not-allowed disabled:opacity-50",
                className,
            )}
            {...props}
        />
    ),
);
Input.displayName = "Input";
