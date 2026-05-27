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
    const formattedAmount = formatAmount(shipment.amount_cents, shipment.currency);

    // Pre-payment state masks the counterparty until escrow lands (US8 / AC9).
    // Backend FSM: shippers can only pay an `accepted` shipment (Payments::Create
    // guards on `status_accepted?`); once paid, the shipment leaves `accepted`.
    const masked = shipment.state === "accepted";

    const showPayCta = payHref !== undefined && shipment.state === "accepted";

    const counterpartyText = shipment.counterparty_display_name
        ? masked
            ? t.counterpartyMasked
            : shipment.counterparty_display_name
        : null;

    return (
        <li className="shipmentRow shipmentRow--card">
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
                <div className="shipmentRowActions">
                    <Button
                        variant="primary"
                        size="sm"
                        onClick={(e) => {
                            e.preventDefault();
                            e.stopPropagation();
                            navigate(payHref!(shipment));
                        }}
                    >
                        {t.payCta(formattedAmount)}
                    </Button>
                </div>
            )}
        </li>
    );
}
