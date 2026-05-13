import { forwardRef } from "react";
import { cn } from "../../lib/utils";

export type SelectProps = React.SelectHTMLAttributes<HTMLSelectElement>;

const CARET_SVG = encodeURIComponent(
    "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16' fill='none' stroke='currentColor' stroke-width='1.75' stroke-linecap='round' stroke-linejoin='round'><polyline points='4 6 8 10 12 6'/></svg>",
);

// Native `<select>` styled to match shadcn's input rhythm. We keep the native
// element for accessibility — Radix-based Select is heavier than this surface
// needs.
export const Select = forwardRef<HTMLSelectElement, SelectProps>(
    ({ className, children, ...props }, ref) => (
        <select
            ref={ref}
            className={cn(
                "flex w-full min-h-11 rounded-sm border border-stroke bg-paper py-3 pl-3.5 pr-10 text-base text-ink",
                "appearance-none bg-no-repeat bg-[right_0.85rem_center]",
                "transition-[border-color,box-shadow] duration-150 ease-[var(--ease-out-soft)]",
                "focus-visible:outline-none focus-visible:ring-[3px] focus-visible:ring-ring",
                "focus-visible:border-[color-mix(in_oklab,var(--color-brand)_70%,var(--color-ink))]",
                "aria-invalid:border-[color-mix(in_oklab,var(--color-brand-error)_80%,var(--color-ink))]",
                "disabled:cursor-not-allowed disabled:opacity-50",
                className,
            )}
            style={{
                backgroundImage: `url("data:image/svg+xml,${CARET_SVG}")`,
                backgroundSize: "16px 16px",
            }}
            {...props}
        >
            {children}
        </select>
    ),
);
Select.displayName = "Select";
