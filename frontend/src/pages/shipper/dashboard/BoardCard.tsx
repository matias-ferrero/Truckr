import { Link } from "react-router-dom";
import type { BoardCard as BoardCardModel } from "./buildDashboardModel";
import { badgeLabel, shipperDashboardContent as t } from "./shipperDashboardContent";
import { formatArs } from "./format";

/** Maps a badge to a visual tone class. Color is never the only signal —
 *  every badge also carries its text label. */
function badgeTone(badge: BoardCardModel["badge"]): string {
    switch (badge) {
        case "payment_pending":
            return "is-urgent";
        case "has_offers":
        case "in_transit":
            return "is-sky";
        case "delivered":
            return "is-done";
        case "to_review":
            return "is-review";
        case "no_offers":
        default:
            return "is-neutral";
    }
}

export function BoardCard({ card }: { card: BoardCardModel }) {
    const label = badgeLabel(card.badge, card.offersCount);
    const accessibleName = t.board.cardAccessibleName(
        card.origin,
        card.destination,
        label ?? t.board.noStatus,
    );

    return (
        <li className="dashCard">
            <Link to={card.href} className="dashCard__link" aria-label={accessibleName}>
                <p className="dashCard__route">
                    <span className="dashCard__place">{card.origin}</span>
                    <span className="dashCard__arrow" aria-hidden="true">{"→"}</span>
                    <span className="dashCard__place">{card.destination}</span>
                </p>
                <div className="dashCard__meta">
                    {card.priceCents !== null && (
                        <span className="dashCard__price">{formatArs(card.priceCents)}</span>
                    )}
                    {label && (
                        <span className={`dashBadge ${badgeTone(card.badge)}`}>{label}</span>
                    )}
                </div>
            </Link>
        </li>
    );
}
