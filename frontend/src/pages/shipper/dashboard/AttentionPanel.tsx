import { Link } from "react-router-dom";
import type { DashboardModel } from "./buildDashboardModel";
import { shipperDashboardContent as t } from "./shipperDashboardContent";

type Attention = DashboardModel["attention"];

/** A single actionable alert row. Differentiated by tone + emphasis so the
 *  three rows never read as an identical-card grid (anti-slop). */
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

export function AttentionPanel({ attention }: { attention: Attention }) {
    const { toPay, withoutOffers, toReview } = attention;
    const allClear = toPay === 0 && withoutOffers === 0 && toReview === 0;

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
                        {toPay > 0 && (
                            <AlertRow
                                tone="dashAlert--pay"
                                urgent
                                count={toPay}
                                countText={t.attention.toPay.count(toPay)}
                                label={t.attention.toPay.label}
                                hint={t.attention.toPay.hint}
                                action={t.attention.toPay.action}
                                href="/shipper/shipments"
                            />
                        )}
                        {withoutOffers > 0 && (
                            <AlertRow
                                tone="dashAlert--offers"
                                count={withoutOffers}
                                countText={t.attention.withoutOffers.count(withoutOffers)}
                                label={t.attention.withoutOffers.label}
                                hint={t.attention.withoutOffers.hint}
                                action={t.attention.withoutOffers.action}
                                href="/shipper/cargos"
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
                                href="/shipper/shipments"
                            />
                        )}
                    </ul>
                )}
        </section>
    );
}
