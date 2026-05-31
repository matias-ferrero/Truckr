import { useCallback, useEffect, useState } from "react";
import {
    getShipmentDetail,
    createShipmentPayment,
    performShipmentTransition,
    type ShipmentDetail,
    type AvailableAction,
} from "../api/shipments";

export type PaymentState = "pending" | "paid";
export type CompositeLabel = "to_pick_up" | "awaiting_payment" | null;
export type PayLabel = "pay" | "retry_payment";

export type DerivedState = {
    paymentState: PaymentState;
    compositeLabel: CompositeLabel;
    payLabel: PayLabel;
    isActing: boolean;
    actionError: string | null;
};

export type DetailPageState =
    | { status: "loading" }
    | { status: "ready"; detail: ShipmentDetail; derived: DerivedState }
    | { status: "not_found" }
    | { status: "error"; message: string };

function derivePaymentState(detail: ShipmentDetail): PaymentState {
    return detail.payment?.state === "escrowed" ? "paid" : "pending";
}

function deriveCompositeLabel(detail: ShipmentDetail, paymentState: PaymentState): CompositeLabel {
    if (detail.state !== "accepted") return null;
    return paymentState === "paid" ? "to_pick_up" : "awaiting_payment";
}

function derivePayLabel(detail: ShipmentDetail): PayLabel {
    return detail.payment?.state === "failed" ? "retry_payment" : "pay";
}

export function useShipmentDetail(id: number): {
    state: DetailPageState;
    reload: () => void;
    // Wired for US18/US19 action buttons (start_transit, deliver) and future
    // cancel flow. Not yet consumed by ShipmentDetailPage — action buttons
    // were removed from the detail view in US39 and will return in a follow-up.
    handleAction: (action: AvailableAction) => Promise<void>;
} {
    const [pageState, setPageState] = useState<DetailPageState>({ status: "loading" });

    const buildReady = useCallback((detail: ShipmentDetail, isActing = false, actionError: string | null = null): DetailPageState => {
        const paymentState = derivePaymentState(detail);
        return {
            status: "ready",
            detail,
            derived: {
                paymentState,
                compositeLabel: deriveCompositeLabel(detail, paymentState),
                payLabel: derivePayLabel(detail),
                isActing,
                actionError,
            },
        };
    }, []);

    const load = useCallback(async () => {
        setPageState({ status: "loading" });
        try {
            const detail = await getShipmentDetail(id);
            setPageState(buildReady(detail));
        } catch (err) {
            const status = (err as { status?: number }).status;
            if (status === 404) {
                setPageState({ status: "not_found" });
            } else {
                setPageState({ status: "error", message: (err as Error).message ?? "Error" });
            }
        }
    }, [id, buildReady]);

    useEffect(() => {
        load();
    }, [load]);

    const handleAction = useCallback(async (action: AvailableAction) => {
        setPageState((prev) => {
            if (prev.status !== "ready") return prev;
            return buildReady(prev.detail, true, null);
        });

        try {
            if (action === "pay") {
                await createShipmentPayment(id);
            } else if (action === "start_transit" || action === "deliver") {
                await performShipmentTransition(id, action);
            } else if (action === "cancel") {
                // cancel endpoint not yet implemented (Sprint 4+); backend will
                // not emit "cancel" in available_actions until it is. If it ever
                // does without a matching FE endpoint this throws visibly.
                throw new Error("cancel action not yet supported on the frontend");
            } else {
                const _exhaustive: never = action;
                throw new Error(`Unknown available_action: ${_exhaustive}`);
            }
            const refreshed = await getShipmentDetail(id);
            setPageState(buildReady(refreshed));
            window.dispatchEvent(new Event("truckr:shipment-updated"));
        } catch (err) {
            setPageState((prev) => {
                if (prev.status !== "ready") return prev;
                return buildReady(prev.detail, false, (err as Error).message ?? "Error");
            });
        }
    }, [id, buildReady]);

    return { state: pageState, reload: load, handleAction };
}
