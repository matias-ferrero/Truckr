import { forwardRef } from "react";
import { cn } from "../../lib/utils";

export type RadioGroupProps = React.HTMLAttributes<HTMLDivElement>;

// Container only — actual <input type="radio"> elements are RadioOption below.
// Native radios + `:has()` selectors keep the keyboard-first behavior intact.
export const RadioGroup = forwardRef<HTMLDivElement, RadioGroupProps>(
    ({ className, ...props }, ref) => (
        <div
            ref={ref}
            role="radiogroup"
            className={cn("flex flex-col gap-2", className)}
            {...props}
        />
    ),
);
RadioGroup.displayName = "RadioGroup";

export type RadioOptionProps =
    & Omit<React.InputHTMLAttributes<HTMLInputElement>, "type">
    & { label: React.ReactNode };

export const RadioOption = forwardRef<HTMLInputElement, RadioOptionProps>(
    ({ className, label, id, ...props }, ref) => (
        <label
            htmlFor={id}
            className={cn(
                "flex items-center gap-3 min-h-11 px-3.5 py-3 rounded-sm border border-stroke bg-paper text-sm text-ink cursor-pointer",
                "transition-[background-color,border-color] duration-150 ease-[var(--ease-out-soft)]",
                "hover:bg-surface-warm",
                "has-[input:checked]:bg-[color-mix(in_oklab,var(--color-brand)_35%,var(--color-paper))]",
                "has-[input:checked]:border-[color-mix(in_oklab,var(--color-brand)_60%,var(--color-ink))]",
                "has-[input:focus-visible]:ring-[3px] has-[input:focus-visible]:ring-ring",
                className,
            )}
        >
            <input
                ref={ref}
                id={id}
                type="radio"
                className="size-4 accent-ink focus:outline-none"
                {...props}
            />
            <span>{label}</span>
        </label>
    ),
);
RadioOption.displayName = "RadioOption";
