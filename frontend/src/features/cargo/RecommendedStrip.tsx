import { Link } from "react-router-dom";
import type { MatchesModel } from "./buildMatchesModel";
import { cargoMatchesContent } from "./cargoMatchesContent";
import { formatPerKm, formatRating, formatShortDate, formatTotalArs } from "./matchesFormat";

const t = cargoMatchesContent;

type Props = {
    cargoId: number;
    picks: MatchesModel["picks"];
};

/**
 * The "Recomendados" strip — up to three curated picks, each a single
 * legible superlative (cheapest / best-rated / soonest). Every badge is
 * self-justifying via its `why` line; there is no blended score. The strip
 * is rendered only when `buildMatchesModel` produced picks (>3 filtered
 * matches), and each pick links straight into the offer flow.
 */
export default function RecommendedStrip({ cargoId, picks }: Props) {
    if (picks.length === 0) return null;

    return (
        <section className="picksStrip" aria-labelledby="matches-picks-title">
            <h2 id="matches-picks-title" className="picksHeading">
                {t.picks.heading}
            </h2>
            <ul className="picksList">
                {picks.map(({ kind, row }) => {
                    const carrierName = row.match.carrier.display_name ??
                        t.card.carrierFallback;
                    return (
                        <li key={kind}>
                            <article className={`pickCard pickCard--${kind}`}>
                                <span className="pickBadge">
                                    {t.picks.label[kind]}
                                </span>
                                <p className="pickWhy">{t.picks.why[kind]}</p>
                                <div className="pickFacts">
                                    <span className="pickPrice">
                                        {row.totalPrice !== null
                                            ? formatTotalArs(row.totalPrice)
                                            : formatPerKm(
                                                row.match.price_per_km,
                                            )}
                                    </span>
                                    {row.isUnrated
                                        ? (
                                            <span className="pickTrust pickTrust--new">
                                                {t.card.newCarrier}
                                            </span>
                                        )
                                        : (
                                            <span className="pickTrust">
                                                {formatRating(row.ratingAvg)}{" "}
                                                <span aria-hidden="true">★</span>
                                                {" · "}
                                                {t.card.reviews(row.reviewsCount)}
                                            </span>
                                        )}
                                </div>
                                <p className="pickMeta">
                                    <span>{carrierName}</span>
                                    <span>
                                        {t.card.availableFrom(
                                            formatShortDate(
                                                row.match.available_from,
                                            ),
                                        )}
                                    </span>
                                </p>
                                <Link
                                    className="button buttonPrimary pickCta"
                                    to={`/shipper/cargos/${cargoId}/offers/new?window=${row.match.id}`}
                                    state={{ window: row.match }}
                                    aria-label={t.card.offerCtaAria(
                                        carrierName,
                                        t.picks.label[kind],
                                    )}
                                >
                                    {t.card.offerCta}
                                </Link>
                            </article>
                        </li>
                    );
                })}
            </ul>
        </section>
    );
}
