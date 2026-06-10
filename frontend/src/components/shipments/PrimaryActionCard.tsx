import { Button } from "../ui/button";
import { ShipmentActions } from "./ShipmentActions";
import { shipmentDetailContent as t } from "../../pages/shipments/shipmentDetailContent";
import type { AvailableAction, ShipmentState } from "../../api/shipments";
import type { PaymentState, PayLabel } from "../../hooks/useShipmentDetail";

// <PrimaryActionCard /> — shipment-detail v2 / ADR-015.
//
// Top of the sticky rail. The single place where the state×role×payment matrix
// (docs/features/shipment-detail-v2.prd.md §3) becomes UI: it always answers
// "what's my situation and what can I do right now". Never a dead button —
// when the viewer can't act it renders reassuring status copy instead.
//
// Action buttons render strictly off the backend's `available_actions` (safe
// by delegation, via <ShipmentActions /> for carrier transitions and the
// onPay callback for the shipper's escrow flow). Only the waiting/status copy
// is derived client-side from state + payment.

type Role = "carrier" | "shipper";

type Mode = "action" | "waiting" | "status";

type Eyebrow = keyof typeof t.rail.eyebrow;

type CardCopy = { headline: string; lead: string };

type Props = {
    role: Role;
    state: ShipmentState;
    paymentState: PaymentState;
    payLabel: PayLabel;
    amountLabel: string;
    /** A review by the viewer already exists (rail shows the done card instead). */
    hasReview: boolean;
    available_actions: AvailableAction[];
    isActing: boolean;
    actionError: string | null;
    onAction: (action: AvailableAction) => void;
    onPay: () => void;
    onOpenReview: () => void;
    shipmentSummary?: string | null;
};

function resolveCard(role: Role, state: ShipmentState, paymentState: PaymentState, payLabel: PayLabel): { mode: Mode; eyebrow: Eyebrow; copy: CardCopy } {
    if (state === "cancelled") {
        return { mode: "status", eyebrow: "cancelled", copy: t.rail.cancelled };
    }
    if (state === "delivered") {
        return { mode: "action", eyebrow: "last_step", copy: t.rail.review };
    }
    if (role === "shipper") {
        if (state === "in_transit") return { mode: "status", eyebrow: "in_progress", copy: t.rail.shipper.in_transit };
        if (paymentState === "paid") return { mode: "waiting", eyebrow: "waiting_carrier", copy: t.rail.shipper.waiting_pickup };
        return {
            mode: "action",
            eyebrow: "next_step",
            copy: payLabel === "retry_payment" ? t.rail.shipper.retry : t.rail.shipper.pay,
        };
    }
    // carrier
    if (state === "in_transit") return { mode: "action", eyebrow: "next_step", copy: t.rail.carrier.in_transit };
    if (paymentState === "paid") return { mode: "action", eyebrow: "next_step", copy: t.rail.carrier.ready_to_pick_up };
    return { mode: "waiting", eyebrow: "waiting_shipper", copy: t.rail.carrier.waiting_payment };
}

export function PrimaryActionCard({
    role,
    state,
    paymentState,
    payLabel,
    amountLabel,
    hasReview,
    available_actions,
    isActing,
    actionError,
    onAction,
    onPay,
    onOpenReview,
    shipmentSummary,
}: Props) {
    // delivered + reviewed → the read-only review card (rendered by the page)
    // takes the rail slot; this card disappears entirely.
    if (state === "delivered" && hasReview) return null;

    const { mode, eyebrow, copy } = resolveCard(role, state, paymentState, payLabel);
    const showPayCta = role === "shipper" && state === "accepted" && paymentState === "pending";
    const showAmount = state === "accepted" && paymentState === "pending";
    const showCarrierActions = role === "carrier" && state !== "delivered" && available_actions.length > 0;
    const showReviewCta = state === "delivered" && !hasReview;

    return (
        <section
            className={`primaryActionCard primaryActionCard--${mode}`}
            aria-label={t.rail.regionLabel}
        >
            <div aria-live="polite" aria-atomic="true">
                <p className="primaryActionCard__eyebrow">{t.rail.eyebrow[eyebrow]}</p>
                <h2 className="primaryActionCard__headline">{copy.headline}</h2>
                <p className="primaryActionCard__lead">{copy.lead}</p>
            </div>

            {showAmount && (
                <p className="primaryActionCard__amount">{amountLabel}</p>
            )}

            {showPayCta && (
                <Button
                    variant="primary"
                    className="primaryActionCard__cta"
                    onClick={onPay}
                >
                    {payLabel === "retry_payment" ? t.actions.retry_payment : t.composite.awaiting_payment_cta}
                </Button>
            )}

            {showCarrierActions && (
                <ShipmentActions
                    available_actions={available_actions}
                    payLabel={payLabel}
                    isActing={isActing}
                    actionError={actionError}
                    onAction={onAction}
                    shipmentSummary={shipmentSummary}
                />
            )}

            {showReviewCta && (
                <Button
                    variant="primary"
                    className="primaryActionCard__cta"
                    onClick={onOpenReview}
                >
                    {t.rail.review.cta}
                </Button>
            )}
        </section>
    );
}
