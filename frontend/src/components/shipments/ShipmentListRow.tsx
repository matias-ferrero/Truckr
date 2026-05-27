import { Link } from "react-router-dom";
import type { Shipment } from "../../api/shipments";
import { ShipmentStateChip } from "./ShipmentStateChip";
import { shipmentsSharedContent } from "./shipmentsSharedContent";

interface Props {
    shipment: Shipment;
    detailPath: string;
}

const dateFormatter = new Intl.DateTimeFormat("es-AR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
});

function formatAmount(cents: number, currency: string): string {
    return new Intl.NumberFormat("es-AR", { style: "currency", currency }).format(cents / 100);
}

export function ShipmentListRow({ shipment, detailPath }: Props) {
    const stateLabel = shipmentsSharedContent.state[shipment.state];
    return (
        <li className="shipmentRow">
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
                        <span className="shipmentRowAmount">
                            {formatAmount(shipment.amount_cents, shipment.currency)}
                        </span>
                    </div>
                    <div className="shipmentRowSubline">
                        <div className="shipmentRowChips">
                            <ShipmentStateChip state={shipment.state} />
                        </div>
                        <span className="shipmentRowDate">
                            {dateFormatter.format(new Date(shipment.latest_activity_at))}
                        </span>
                    </div>
                </div>
                <span className="shipmentRowChevron" aria-hidden="true">›</span>
            </Link>
        </li>
    );
}
