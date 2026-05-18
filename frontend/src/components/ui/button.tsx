import { forwardRef } from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "../../lib/utils";

const buttonVariants = cva(
    "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-full font-semibold " +
        "transition-[background-color,border-color,color,box-shadow,transform] duration-200 ease-[var(--ease-out-soft)] " +
        "focus-visible:outline-none focus-visible:ring-[3px] focus-visible:ring-ring focus-visible:ring-offset-2 " +
        "focus-visible:ring-offset-paper disabled:pointer-events-none disabled:opacity-50 " +
        "[&_svg]:size-4 [&_svg]:shrink-0",
    {
        variants: {
            variant: {
                primary:
                    "bg-[color-mix(in_oklab,var(--color-brand-warm)_58%,var(--color-paper))] text-ink " +
                    "border border-[color-mix(in_oklab,var(--color-brand-warm)_62%,var(--color-ink))] " +
                    "shadow-[0_8px_24px_color-mix(in_oklab,var(--color-brand-warm)_22%,transparent)] " +
                    "hover:-translate-y-px hover:shadow-[0_12px_28px_color-mix(in_oklab,var(--color-brand-warm)_30%,transparent)] " +
                    "hover:bg-[color-mix(in_oklab,var(--color-brand-warm)_70%,var(--color-paper))] " +
                    "hover:border-[color-mix(in_oklab,var(--color-brand-warm)_70%,var(--color-ink))]",
                ghost:
                    "bg-transparent text-ink border border-ink " +
                    "hover:bg-[color-mix(in_oklab,var(--color-ink)_6%,transparent)]",
                danger:
                    "bg-brand-error text-paper border border-brand-error " +
                    "hover:bg-[color-mix(in_oklab,var(--color-brand-error)_88%,var(--color-ink))]",
                outline:
                    "bg-paper text-ink border border-stroke hover:bg-surface-warm",
            },
            size: {
                default: "min-h-11 px-5 py-3 text-base",
                sm: "min-h-9 px-4 py-2 text-sm",
                icon: "size-11 p-0",
            },
        },
        defaultVariants: {
            variant: "primary",
            size: "default",
        },
    },
);

type ButtonProps =
    & React.ButtonHTMLAttributes<HTMLButtonElement>
    & VariantProps<typeof buttonVariants>;

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
    ({ className, variant, size, type = "button", ...props }, ref) => (
        <button
            ref={ref}
            type={type}
            className={cn(buttonVariants({ variant, size }), className)}
            {...props}
        />
    ),
);
Button.displayName = "Button";

export { buttonVariants };
