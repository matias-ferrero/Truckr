import { useState, useEffect, useRef } from "react";
import { Button } from "../ui/button";
import type { PayLabel } from "../../hooks/useShipmentDetail";
import type { AvailableAction } from "../../api/shipments";
import { shipmentDetailContent as t } from "../../pages/shipments/shipmentDetailContent";

const CONFIRM_REQUIRED = new Set<AvailableAction>(["pay", "start_transit", "deliver", "cancel"]);

type Props = {
    available_actions: AvailableAction[];
    payLabel: PayLabel;
    isActing: boolean;
    actionError: string | null;
    onAction: (action: AvailableAction) => void;
    shipmentSummary?: string | null;
};

export function ShipmentActions({ available_actions, payLabel, isActing, actionError, onAction, shipmentSummary }: Props) {
    const [pendingAction, setPendingAction] = useState<AvailableAction | null>(null);
    const [successFlash, setSuccessFlash] = useState(false);
    const wasActing = useRef(false);
    const flashTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
    const dialogRef = useRef<HTMLDialogElement>(null);

    useEffect(() => {
        if (wasActing.current && !isActing && !actionError) {
            if (flashTimer.current) clearTimeout(flashTimer.current);
            setSuccessFlash(true);
            flashTimer.current = setTimeout(() => setSuccessFlash(false), 500);
        }
        wasActing.current = isActing;
    }, [isActing, actionError]);

    useEffect(() => () => {
        if (flashTimer.current) clearTimeout(flashTimer.current);
    }, []);

    // Open as modal on mount; focus the first (safe) button — WCAG 2.4.3.
    useEffect(() => {
        const el = dialogRef.current;
        if (!el) return;
        if (pendingAction) {
            el.showModal();
            const first = el.querySelector<HTMLElement>(
                'button:not([disabled]), [href], [tabindex]:not([tabindex="-1"])'
            );
            first?.focus();
        }
    }, [pendingAction]);

    if (available_actions.length === 0) return null;

    function labelFor(action: AvailableAction): string {
        if (action === "pay") return payLabel === "retry_payment" ? t.actions.retry_payment : t.actions.pay;
        return t.actions[action];
    }

    function handleClick(action: AvailableAction) {
        if (CONFIRM_REQUIRED.has(action)) {
            setPendingAction(action);
        } else {
            onAction(action);
        }
    }

    function handleConfirm() {
        if (pendingAction) {
            onAction(pendingAction);
            setPendingAction(null);
        }
    }

    function handleCancel() {
        setPendingAction(null);
    }

    const isPayAction = pendingAction === "pay" || pendingAction === "retry_payment";

    return (
        <section
            className="shipmentActionsSection"
            aria-label="Acciones del envío"
            data-success={successFlash ? "true" : undefined}
        >
            {actionError && (
                <div className="shipmentActionsError" role="alert">
                    <p>{actionError}</p>
                </div>
            )}

            <div className="shipmentActionsButtons">
                {available_actions.map((action) => (
                    <Button
                        key={action}
                        variant={action === "cancel" ? "danger" : "primary"}
                        disabled={isActing}
                        onClick={() => handleClick(action)}
                    >
                        {isActing ? <span className="shipmentActionsSpinner" aria-hidden="true" /> : null}
                        {labelFor(action)}
                    </Button>
                ))}
            </div>

            {pendingAction && (
                <dialog
                    className="confirmDialog"
                    aria-labelledby="confirmDialogTitle"
                    ref={dialogRef}
                    data-action={pendingAction}
                    onCancel={(e) => { e.preventDefault(); handleCancel(); }}
                >
                    <div className="confirmDialogBody">
                        {isPayAction && (
                            <div className="confirmDialogPaymark" aria-hidden="true">
                                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                                    <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
                                    <polyline points="9 12 11 14 15 10" />
                                </svg>
                            </div>
                        )}
                        <h2 className="confirmDialogTitle" id="confirmDialogTitle">
                            {t.confirm.title}
                        </h2>
                        {shipmentSummary && (
                            <p className="confirmDialogRoute">{shipmentSummary}</p>
                        )}
                        <p className="confirmDialogLead">
                            {labelFor(pendingAction)}
                        </p>
                        {(t.confirm.consequence as Record<string, string>)[pendingAction] && (
                            <p className="confirmDialogText">
                                {(t.confirm.consequence as Record<string, string>)[pendingAction]}
                            </p>
                        )}
                        <div className="confirmDialogActions">
                            <Button variant="ghost" onClick={handleCancel}>
                                Cancelar
                            </Button>
                            <Button variant="primary" className="confirmDialogConfirmBtn" onClick={handleConfirm}>
                                Confirmar
                            </Button>
                        </div>
                    </div>
                </dialog>
            )}
        </section>
    );
}
