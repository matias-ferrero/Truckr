import { useEffect, useRef, useState } from "react";
import { Button } from "./ui/button";

export type WizardStep = {
    label: string;
    content: React.ReactNode;
    /** When false, the Next / Submit button is disabled for this step. */
    canAdvance: boolean;
};

type WizardProps = {
    steps: WizardStep[];
    onSubmit: () => void;
    isSubmitting: boolean;
    nextLabel: string;
    backLabel: string;
    submitLabel: string;
    submittingLabel: string;
    /** Called when back is pressed on step 0. Omit to keep the button disabled. */
    onCancel?: () => void;
    /** Produces the live-region announcement when the step changes. Receives the 1-based step number and the step label. */
    stepAnnouncementTemplate?: (step: number, label: string) => string;
};

/**
 * Generic multi-step wizard shell. Step state lives here; form state stays in
 * the parent. Each step's `content` is a React node (not a component), so the
 * parent owns the draft and passes controlled inputs as children.
 */
export default function Wizard({
    steps,
    onSubmit,
    isSubmitting,
    nextLabel,
    backLabel,
    submitLabel,
    submittingLabel,
    onCancel,
    stepAnnouncementTemplate,
}: WizardProps) {
    const [current, setCurrent] = useState(0);
    const [announcement, setAnnouncement] = useState("");
    const bodyRef = useRef<HTMLDivElement>(null);
    const isInitialMount = useRef(true);
    const isLast = current === steps.length - 1;
    const step = steps[current];
    const stepLabel = step?.label ?? "";

    useEffect(() => {
        if (isInitialMount.current) {
            isInitialMount.current = false;
            return;
        }
        bodyRef.current?.focus();
        setAnnouncement(
            stepAnnouncementTemplate
                ? stepAnnouncementTemplate(current + 1, stepLabel)
                : `Step ${current + 1}: ${stepLabel}`,
        );
    }, [current, stepLabel, stepAnnouncementTemplate]);

    return (
        <div className="wizard">
            <span
                role="status"
                aria-live="polite"
                aria-atomic="true"
                className="sr-only"
            >
                {announcement}
            </span>
            <nav aria-label="Pasos del formulario">
                <ol
                    className="wizardSteps"
                    style={{ "--step-count": steps.length } as React.CSSProperties}
                >
                    {steps.map((s, i) => (
                        <li
                            key={s.label}
                            className={[
                                "wizardStep",
                                i === current ? "wizardStepCurrent" : "",
                                i < current ? "wizardStepDone" : "",
                            ]
                                .filter(Boolean)
                                .join(" ")}
                            aria-current={i === current ? "step" : undefined}
                        >
                            <span className="wizardStepNumber" aria-hidden="true">
                                {i + 1}
                            </span>
                            <span className="wizardStepLabel">{s.label}</span>
                        </li>
                    ))}
                </ol>
            </nav>

            <div className="wizardBody" key={current} ref={bodyRef} tabIndex={-1}>{step.content}</div>

            <div className="wizardNav">
                <Button
                    type="button"
                    variant="ghost"
                    onClick={current === 0 ? onCancel : () => setCurrent((c) => c - 1)}
                    disabled={current === 0 && !onCancel}
                >
                    {backLabel}
                </Button>

                {isLast ? (
                    <Button
                        type="button"
                        onClick={onSubmit}
                        disabled={!step.canAdvance || isSubmitting}
                    >
                        {isSubmitting ? submittingLabel : submitLabel}
                    </Button>
                ) : (
                    <Button
                        type="button"
                        onClick={() => setCurrent((c) => c + 1)}
                        disabled={!step.canAdvance}
                    >
                        {nextLabel}
                    </Button>
                )}
            </div>
        </div>
    );
}
