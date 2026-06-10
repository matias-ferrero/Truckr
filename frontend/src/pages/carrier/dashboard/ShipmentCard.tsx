import { Link } from "react-router-dom";
import type { ShipmentCard as ShipmentCardModel } from "./buildCarrierDashboardModel";
import { carrierDashboardContent as t, jobBadgeLabel } from "./carrierDashboardContent";
import { formatArs } from "./format";

/** Maps a badge to a visual tone class. Color is never the only signal —
 *  every badge also carries its text label. */
function badgeTone(badge: ShipmentCardModel["badge"]): string {
    switch (badge) {
        case "ready_to_start":
        case "in_transit":
            return "is-active";
        case "to_collect":
            return "is-collect";
        case "paid":
            return "is-done";
        case "to_review":
            return "is-review";
        case "awaiting_payment":
        default:
            return "is-neutral";
    }
}

export function ShipmentCard({ card }: { card: ShipmentCardModel }) {
    const label = jobBadgeLabel(card.badge);
    return (
        <li className="dashCard">
            <Link
                to={card.href}
                className="dashCard__link"
                aria-label={t.board.cardAccessibleName(card.origin, card.destination, label)}
            >
                <p className="dashCard__route">
                    <span className="dashCard__place">{card.origin}</span>
                    <span className="dashCard__arrow" aria-hidden="true">{"→"}</span>
                    <span className="dashCard__place">{card.destination}</span>
                </p>
                <div className="dashCard__meta">
                    {card.priceCents !== null && (
                        <span className="dashCard__price">{formatArs(card.priceCents)}</span>
                    )}
                    <span className={`dashBadge ${badgeTone(card.badge)}`}>{label}</span>
                </div>
            </Link>
        </li>
    );
}
