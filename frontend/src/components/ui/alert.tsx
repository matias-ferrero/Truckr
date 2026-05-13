import { forwardRef } from "react";
import { cva, type VariantProps } from "class-variance-authority";
import { cn } from "../../lib/utils";

const alertVariants = cva(
    "relative flex items-start gap-3 rounded-sm border px-4 py-3 text-sm",
    {
        variants: {
            tone: {
                error:
                    "bg-banner-error text-banner-error-ink border-banner-error-edge",
                info:
                    "bg-surface-cool text-ink border-stroke",
                success:
                    "bg-[color-mix(in_oklab,var(--color-brand)_25%,var(--color-paper))] text-ink border-stroke",
            },
        },
        defaultVariants: { tone: "error" },
    },
);

export type AlertProps =
    & React.HTMLAttributes<HTMLDivElement>
    & VariantProps<typeof alertVariants>;

export const Alert = forwardRef<HTMLDivElement, AlertProps>(
    ({ className, tone, role = "alert", ...props }, ref) => (
        <div
            ref={ref}
            role={role}
            className={cn(alertVariants({ tone }), className)}
            {...props}
        />
    ),
);
Alert.displayName = "Alert";
