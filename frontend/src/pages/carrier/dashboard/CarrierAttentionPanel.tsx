import { Link } from "react-router-dom";
import type { CarrierDashboardModel } from "./buildCarrierDashboardModel";
import { carrierDashboardContent as t } from "./carrierDashboardContent";

type Attention = CarrierDashboardModel["attention"];

/** A single actionable alert row. Differentiated by tone + emphasis so the
 *  rows never read as an identical-card grid (anti-slop). */
function AlertRow(
    { tone, count, countText, label, hint, action, href, urgent }: {
        tone: string;
        count: number;
        countText: string;
        label: string;
        hint: string;
        action: string;
        href: string;
        urgent?: boolean;
    },
) {
    return (
        <li className={`dashAlert ${tone}${urgent ? " is-urgent" : ""}`}>
            <Link to={href} className="dashAlert__link">
                <span className="dashAlert__count" aria-hidden="true">{count}</span>
                <span className="dashAlert__body">
                    <span className="dashAlert__label">
                        {label}
                        <span className="dashAlert__sr"> ({countText})</span>
                    </span>
                    <span className="dashAlert__hint">{hint}</span>
                </span>
                <span className="dashAlert__action">{action}</span>
            </Link>
        </li>
    );
}

export function CarrierAttentionPanel({ attention }: { attention: Attention }) {
    const { offersToAnswer, expiringOffers, toStart, toDeliver, toReview } = attention;
    // Expiring offers escalate out of the plain "por responder" row so the
    // two never double-count the same offer.
    const calmOffers = offersToAnswer - expiringOffers;
    const allClear = offersToAnswer === 0 && toStart === 0 && toDeliver === 0 && toReview === 0;

    return (
        <section className="dashAttention" aria-labelledby="dash-attention-title">
            <h2 className="dashSection__title" id="dash-attention-title">
                {t.attention.title}
            </h2>

            {allClear
                ? (
                    <div className="dashAllClear">
                        <span className="dashAllClear__mark" aria-hidden="true">✓</span>
                        <div>
                            <p className="dashAllClear__title">{t.attention.allClearTitle}</p>
                            <p className="dashAllClear__lead">{t.attention.allClearLead}</p>
                        </div>
                    </div>
                )
                : (
                    <ul className="dashAlerts">
                        {expiringOffers > 0 && (
                            <AlertRow
                                tone="dashAlert--expiring"
                                urgent
                                count={expiringOffers}
                                countText={t.attention.expiring.count(expiringOffers)}
                                label={t.attention.expiring.label}
                                hint={t.attention.expiring.hint}
                                action={t.attention.expiring.action}
                                href="/carrier/cargo-offers"
                            />
                        )}
                        {calmOffers > 0 && (
                            <AlertRow
                                tone="dashAlert--offers"
                                count={calmOffers}
                                countText={t.attention.offersToAnswer.count(calmOffers)}
                                label={t.attention.offersToAnswer.label}
                                hint={t.attention.offersToAnswer.hint}
                                action={t.attention.offersToAnswer.action}
                                href="/carrier/cargo-offers"
                            />
                        )}
                        {toStart > 0 && (
                            <AlertRow
                                tone="dashAlert--start"
                                count={toStart}
                                countText={t.attention.toStart.count(toStart)}
                                label={t.attention.toStart.label}
                                hint={t.attention.toStart.hint}
                                action={t.attention.toStart.action}
                                href="/carrier/shipments"
                            />
                        )}
                        {toDeliver > 0 && (
                            <AlertRow
                                tone="dashAlert--deliver"
                                count={toDeliver}
                                countText={t.attention.toDeliver.count(toDeliver)}
                                label={t.attention.toDeliver.label}
                                hint={t.attention.toDeliver.hint}
                                action={t.attention.toDeliver.action}
                                href="/carrier/shipments"
                            />
                        )}
                        {toReview > 0 && (
                            <AlertRow
                                tone="dashAlert--review"
                                count={toReview}
                                countText={t.attention.toReview.count(toReview)}
                                label={t.attention.toReview.label}
                                hint={t.attention.toReview.hint}
                                action={t.attention.toReview.action}
                                href="/carrier/shipments"
                            />
                        )}
                    </ul>
                )}
        </section>
    );
}
