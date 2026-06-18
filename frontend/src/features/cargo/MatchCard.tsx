import { Link } from "react-router-dom";
import type { MatchRow } from "./buildMatchesModel";
import { cargoMatchesContent } from "./cargoMatchesContent";
import { cargosContent } from "./cargosContent";
import { formatRoute } from "../../lib/format-place";
import { formatPerKm, formatRating, formatShortDate, formatTotalArs } from "./matchesFormat";

const t = cargoMatchesContent;

type Props = {
    cargoId: number;
    row: MatchRow;
};

/**
 * One compatible TransportWindow in the matches grid
 * (docs/features/cargo-matches-v2.prd.md). Every card in the grid is already
 * compatible, so the hierarchy leads with the two real differentiators:
 * the estimated total price (headline) and the carrier's reputation (trust
 * chip). Route, pickup date and distance are demoted to one quiet meta strip;
 * vehicle detail lives behind "Ver perfil".
 */
export default function MatchCard({ cargoId, row }: Props) {
    const { match } = row;
    const hasDestination = match.destination_lat !== null;
    const route = formatRoute(
        { locality: match.origin_locality, admin_area: match.origin_admin_area },
        hasDestination
            ? { locality: match.destination_locality, admin_area: match.destination_admin_area }
            : null,
        cargosContent.list.openDestinationLabel,
    );
    const carrierName = match.carrier.display_name ?? t.card.carrierFallback;

    return (
        <li>
            <article
                className="matchCard"
                data-pick={row.pick ?? undefined}
            >
                {row.pick !== null && (
                    <span className="matchPickBadge">
                        {t.picks.label[row.pick]}
                    </span>
                )}
                <header className="matchCardTop">
                    <div className="matchPrice">
                        {row.totalPrice !== null
                            ? (
                                <>
                                    <span
                                        className="matchPriceTotal"
                                        aria-label={t.card.totalPriceAria(
                                            formatTotalArs(row.totalPrice),
                                        )}
                                    >
                                        {formatTotalArs(row.totalPrice)}
                                    </span>
                                    <span className="matchPriceRate">
                                        {formatPerKm(match.price_per_km)}
                                    </span>
                                </>
                            )
                            : (
                                <span className="matchPriceTotal">
                                    {formatPerKm(match.price_per_km)}
                                </span>
                            )}
                    </div>
                    {row.isUnrated
                        ? (
                            <span className="matchTrust matchTrust--new">
                                <span className="matchTrustHead">
                                    {t.card.newCarrier}
                                </span>
                                <span className="matchTrustSub">
                                    {t.card.newCarrierDetail}
                                </span>
                            </span>
                        )
                        : (
                            <span className="matchTrust">
                                <span className="matchTrustHead">
                                    {formatRating(row.ratingAvg)}{" "}
                                    <span aria-hidden="true">★</span>
                                </span>
                                <span className="matchTrustSub">
                                    {t.card.reviews(row.reviewsCount)}
                                </span>
                            </span>
                        )}
                </header>
                <p className="matchCarrier">{carrierName}</p>
                <p className="matchMetaStrip">
                    <span>{t.card.availableFrom(formatShortDate(match.available_from))}</span>
                    {row.distanceToPickupKm !== null && (
                        <span>{t.card.distanceKm(row.distanceToPickupKm)}</span>
                    )}
                    <span className="matchMetaRoute" title={route}>{route}</span>
                </p>
                <footer className="matchCardActions">
                    <Link
                        className="button buttonGhost"
                        to={`/carriers/${match.carrier.id}`}
                        state={{ backToMatches: `/shipper/cargos/${cargoId}/matches` }}
                    >
                        {t.card.viewProfile}
                    </Link>
                    <Link
                        className="button buttonPrimary"
                        to={`/shipper/cargos/${cargoId}/offers/new?window=${match.id}`}
                        state={{ window: match }}
                        aria-label={t.card.offerCtaAria(carrierName, route)}
                    >
                        {t.card.offerCta}
                    </Link>
                </footer>
            </article>
        </li>
    );
}
