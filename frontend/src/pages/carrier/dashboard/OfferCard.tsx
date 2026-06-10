import { Link } from "react-router-dom";
import { Button } from "../../../components/ui/button";
import type { OfferCard as OfferCardModel } from "./buildCarrierDashboardModel";
import { carrierDashboardContent as t, jobBadgeLabel } from "./carrierDashboardContent";
import { formatArs, formatQuantity, timeUntil } from "./format";

/** An inbound job awaiting response: route, cargo vitals, the shipper's
 *  identity + rating (the carrier vets who they commit to — asymmetric
 *  reveal), expiry countdown, and inline accept / reject. */
export function OfferCard(
    { card, busy, onAccept, onReject }: {
        card: OfferCardModel;
        busy: boolean;
        onAccept: (card: OfferCardModel) => void;
        onReject: (card: OfferCardModel) => void;
    },
) {
    const badge = jobBadgeLabel(card.badge);
    const origin = card.origin || t.board.openDestination;
    const destination = card.destination || t.board.openDestination;
    const vitals = [
        card.weightKg ? t.offerCard.weight(formatQuantity(card.weightKg)) : null,
        card.distanceKm ? t.offerCard.distance(formatQuantity(card.distanceKm)) : null,
    ].filter(Boolean) as string[];

    return (
        <li className={`dashCard dashCard--offer${card.expiringSoon ? " is-expiring" : ""}`}>
            <Link
                to="/carrier/cargo-offers"
                className="dashCard__link"
                aria-label={t.board.cardAccessibleName(origin, destination, badge)}
            >
                <p className="dashCard__route">
                    <span className="dashCard__place">{origin}</span>
                    <span className="dashCard__arrow" aria-hidden="true">{"→"}</span>
                    <span className="dashCard__place">{destination}</span>
                </p>
                <div className="dashCard__meta">
                    {card.priceCents !== null && (
                        <span className="dashCard__price">{formatArs(card.priceCents)}</span>
                    )}
                    <span className={`dashBadge ${card.expiringSoon ? "is-urgent" : "is-new"}`}>
                        {badge}
                    </span>
                </div>
                {vitals.length > 0 && (
                    <p className="dashCard__vitals">{vitals.join(" · ")}</p>
                )}
                <p className="dashCard__shipper">
                    <span className="dashCard__shipperName">{card.shipperName}</span>
                    {card.shipperRating
                        ? (
                            <span
                                className="dashCard__rating"
                                aria-label={t.offerCard.ratingAccessible(
                                    card.shipperRating,
                                    card.shipperReviewsCount,
                                )}
                            >
                                {t.offerCard.rating(card.shipperRating, card.shipperReviewsCount)}
                            </span>
                        )
                        : <span className="dashCard__ratingEmpty">{t.offerCard.ratingEmpty}</span>}
                </p>
                <p className={`dashCard__expiry${card.expiringSoon ? " is-urgent" : ""}`}>
                    {t.offerCard.expiresIn(timeUntil(card.expiresAt))}
                </p>
            </Link>
            <div className="dashCard__actions">
                <Button
                    size="sm"
                    variant="primary"
                    disabled={busy}
                    onClick={() => onAccept(card)}
                    aria-label={t.offerCard.acceptOffer(origin, destination)}
                >
                    {busy ? t.offerCard.processing : t.offerCard.accept}
                </Button>
                <Button
                    size="sm"
                    variant="outline"
                    disabled={busy}
                    onClick={() => onReject(card)}
                    aria-label={t.offerCard.rejectOffer(origin, destination)}
                >
                    {t.offerCard.reject}
                </Button>
            </div>
        </li>
    );
}
