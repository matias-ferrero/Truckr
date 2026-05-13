import { cloneElement, isValidElement } from "react";
import { cn } from "../../lib/utils";
import { Label } from "./label";

export type FormFieldProps = {
    id: string;
    label: React.ReactNode;
    error?: string;
    help?: React.ReactNode;
    children: React.ReactNode;
    className?: string;
    /** Render the label as a <legend> instead — for radio/checkbox groupings. */
    asFieldset?: boolean;
};

// Field shell for label + control + error/help. Forwards aria-invalid and
// aria-describedby onto the child control so callers don't have to wire it.
export function FormField(
    { id, label, error, help, children, className, asFieldset }: FormFieldProps,
) {
    const errorId = `${id}-error`;
    const helpId = `${id}-help`;
    const describedBy = error ? errorId : help ? helpId : undefined;

    let control: React.ReactNode = children;
    if (!asFieldset && isValidElement(children)) {
        control = cloneElement(
            children as React.ReactElement<Record<string, unknown>>,
            {
                "aria-invalid": error ? "true" : undefined,
                "aria-describedby": describedBy,
            } as Record<string, unknown>,
        );
    }

    if (asFieldset) {
        return (
            <fieldset
                className={cn("flex flex-col gap-2 min-w-0 border-0 p-0 m-0", className)}
                aria-describedby={describedBy}
            >
                <legend className="text-sm font-semibold text-ink mb-2">{label}</legend>
                {control}
                <FieldFootnote error={error} errorId={errorId} help={help} helpId={helpId} />
            </fieldset>
        );
    }

    return (
        <div className={cn("flex flex-col gap-2 min-w-0", className)}>
            <Label htmlFor={id}>{label}</Label>
            {control}
            <FieldFootnote error={error} errorId={errorId} help={help} helpId={helpId} />
        </div>
    );
}

function FieldFootnote(
    { error, errorId, help, helpId }: {
        error?: string;
        errorId: string;
        help?: React.ReactNode;
        helpId: string;
    },
) {
    if (error) {
        return (
            <div
                id={errorId}
                role="alert"
                className="text-xs font-semibold text-[color-mix(in_oklab,var(--color-brand-error)_50%,var(--color-ink))]"
            >
                {error}
            </div>
        );
    }
    if (help) {
        return (
            <div id={helpId} className="text-xs text-ink-faint leading-snug">
                {help}
            </div>
        );
    }
    return null;
}
