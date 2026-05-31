import { useState, useEffect, useRef } from "react";
import { Link, useNavigate } from "react-router-dom";
import type { Shipment } from "../../api/shipments";
import { Button } from "../ui/button";
import { ShipmentStateChip } from "./ShipmentStateChip";
import { shipmentsSharedContent } from "./shipmentsSharedContent";

interface Props {
    shipment: Shipment;
    detailPath: string;
    payHref?: (shipment: Shipment) => string;
}

const dateFormatter = new Intl.DateTimeFormat("es-AR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
});

function formatAmount(cents: number, currency: string): string {
    return new Intl.NumberFormat("es-AR", { style: "currency", currency }).format(cents / 100);
}

export function ShipmentListRow({ shipment, detailPath, payHref }: Props) {
    const navigate = useNavigate();
    const stateLabel = shipmentsSharedContent.state[shipment.state];
    const t = shipmentsSharedContent.row;
    const c = shipmentsSharedContent.payConfirm;
    const formattedAmount = formatAmount(shipment.amount_cents, shipment.currency);

    const [payDialogOpen, setPayDialogOpen] = useState(false);
    const payDialogRef = useRef<HTMLDialogElement>(null);

    // Pre-payment mask: counterparty is hidden until payment is escrowed (US8 / AC9).
    // State stays `accepted` after payment; payment_escrowed is the authoritative signal.
    const masked = shipment.state === "accepted" && !shipment.payment_escrowed;

    const showPayCta = payHref !== undefined && shipment.state === "accepted" && !shipment.payment_escrowed;

    const counterpartyText = shipment.counterparty_display_name
        ? masked
            ? t.counterpartyMasked
            : shipment.counterparty_display_name
        : null;

    useEffect(() => {
        const el = payDialogRef.current;
        if (!el) return;
        if (payDialogOpen) {
            el.showModal();
            const first = el.querySelector<HTMLElement>(
                'button:not([disabled]), [href], [tabindex]:not([tabindex="-1"])'
            );
            first?.focus();
        }
    }, [payDialogOpen]);

    function handlePayConfirm() {
        if (!payHref) return;
        setPayDialogOpen(false);
        navigate(payHref(shipment));
    }

    return (
        <li className={`shipmentRow shipmentRow--card${showPayCta ? " shipmentRow--withPay" : ""}`}>
            <Link
                to={detailPath}
                className="shipmentRowLink"
                aria-label={shipmentsSharedContent.detailLinkAria(
                    shipment.id,
                    shipment.origin,
                    shipment.destination,
                    stateLabel,
                )}
            >
                <div className="shipmentRowMain">
                    <div className="shipmentRowHeadline">
                        <p className="shipmentRowRoute">
                            <span className="shipmentRowRouteText">{shipment.origin}</span>
                            <span className="shipmentRowArrow" aria-hidden="true">
                                {shipmentsSharedContent.routeArrow}
                            </span>
                            <span className="shipmentRowRouteText">{shipment.destination}</span>
                        </p>
                        <span className="shipmentRowAmount">{formattedAmount}</span>
                    </div>
                    <div className="shipmentRowSubline">
                        <div className="shipmentRowChips">
                            <ShipmentStateChip state={shipment.state} />
                        </div>
                        <span className="shipmentRowDate">
                            {dateFormatter.format(new Date(shipment.latest_activity_at))}
                        </span>
                    </div>
                    {counterpartyText && (
                        <p className="shipmentRowCounterparty">
                            <span className="shipmentRowCounterpartyLabel">
                                {t.counterpartyLabel}:
                            </span>{" "}
                            <span
                                className={`shipmentRowCounterpartyValue${masked ? " shipmentRowCounterpartyValue--masked" : ""}`}
                            >
                                {counterpartyText}
                            </span>
                        </p>
                    )}
                </div>
                <span className="shipmentRowChevron" aria-hidden="true">›</span>
            </Link>

            {showPayCta && (
                <div className="shipmentRowPayStrip">
                    <Button
                        variant="primary"
                        size="sm"
                        onClick={(e) => {
                            e.preventDefault();
                            e.stopPropagation();
                            setPayDialogOpen(true);
                        }}
                    >
                        {t.payCta(formattedAmount)}
                    </Button>
                </div>
            )}

            {payDialogOpen && (
                <dialog
                    className="confirmDialog"
                    ref={payDialogRef}
                    data-action="pay"
                    aria-labelledby={`payConfirmTitle-${shipment.id}`}
                    onCancel={(e) => { e.preventDefault(); setPayDialogOpen(false); }}
                >
                    <div className="confirmDialogBody">
                        <div className="confirmDialogPaymark" aria-hidden="true">
                            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
                                <path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z" />
                                <polyline points="9 12 11 14 15 10" />
                            </svg>
                        </div>
                        <h2 className="confirmDialogTitle" id={`payConfirmTitle-${shipment.id}`}>
                            {c.title}
                        </h2>
                        <p className="confirmDialogRoute">
                            {shipment.origin} → {shipment.destination}
                        </p>
                        <p className="confirmDialogLead">{c.lead}</p>
                        <p className="confirmDialogText">{c.text}</p>
                        <div className="confirmDialogActions">
                            <Button variant="ghost" onClick={() => setPayDialogOpen(false)}>
                                {c.cancel}
                            </Button>
                            <Button variant="primary" className="confirmDialogConfirmBtn" onClick={handlePayConfirm}>
                                {c.confirm}
                            </Button>
                        </div>
                    </div>
                </dialog>
            )}
        </li>
    );
}
