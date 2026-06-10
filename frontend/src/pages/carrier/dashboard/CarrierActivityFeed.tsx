import { useState } from "react";
import { Link } from "react-router-dom";
import { Button } from "../../../components/ui/button";
import type { CarrierActivityItem } from "./buildCarrierActivityFeed";
import { carrierDashboardContent as t } from "./carrierDashboardContent";
import { formatArs, relativeTime } from "./format";

export const FEED_PAGE_SIZE = 6;

/** Stroke icon per activity kind. Decorative (aria-hidden) — the text
 *  description carries the meaning. 24px viewBox, drawn at 20px inside a
 *  40px semantic-tinted tile so each kind is recognizable at a glance. */
function GlyphIcon({ kind }: { kind: CarrierActivityItem["kind"] }) {
    const paths: Record<CarrierActivityItem["kind"], React.ReactNode> = {
        payout_paid: (
            <>
                <rect x="3" y="6" width="18" height="12" rx="2" />
                <circle cx="12" cy="12" r="2.6" />
                <path d="M6.5 9.5v.01M17.5 14.5v.01" />
            </>
        ),
        review_received: (
            <path d="m12 3.5 2.6 5.4 5.9.8-4.3 4.1 1 5.8-5.2-2.8-5.2 2.8 1-5.8L3.5 9.7l5.9-.8L12 3.5z" />
        ),
        offer_received: (
            <>
                <rect x="3" y="5" width="18" height="14" rx="2" />
                <path d="m3 7 9 6 9-6" />
            </>
        ),
        offer_accepted: (
            <>
                <circle cx="12" cy="12" r="9" />
                <path d="m8.5 12.5 2.5 2.5 4.5-5.5" />
            </>
        ),
        offer_rejected: (
            <>
                <circle cx="12" cy="12" r="9" />
                <path d="m9 9 6 6M15 9l-6 6" />
            </>
        ),
    };
    return (
        <svg
            viewBox="0 0 24 24"
            width="20"
            height="20"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.8"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
        >
            {paths[kind]}
        </svg>
    );
}

function FeedRow({ item }: { item: CarrierActivityItem }) {
    const description = t.feed.descriptions[item.kind];
    const amount = item.amountCents !== null ? formatArs(item.amountCents) : null;
    const when = relativeTime(item.at);
    const hasRoute = item.origin !== null && item.destination !== null;
    return (
        <li className="dashFeed__item">
            <Link to={item.href} className="dashFeed__link">
                <span className={`dashFeed__glyph kind--${item.kind}`} aria-hidden="true">
                    <GlyphIcon kind={item.kind} />
                </span>
                <span className="dashFeed__body">
                    <span className="dashFeed__desc">{description}</span>
                    <span className="dashFeed__detail">
                        {hasRoute && (
                            <span className="dashFeed__route">
                                {item.origin}
                                <span className="dashFeed__routeArrow" aria-hidden="true">
                                    →
                                </span>
                                {item.destination}
                            </span>
                        )}
                        {when && (
                            <time className="dashFeed__time" dateTime={item.at}>
                                {when}
                            </time>
                        )}
                    </span>
                </span>
                {item.kind === "review_received" && item.rating !== null
                    ? <span className="dashFeed__amount">{t.feed.ratingDetail(item.rating)}</span>
                    : amount && <span className="dashFeed__amount">{amount}</span>}
            </Link>
        </li>
    );
}

export function CarrierActivityFeed({ items }: { items: CarrierActivityItem[] }) {
    const [page, setPage] = useState(0);

    const totalPages = Math.max(1, Math.ceil(items.length / FEED_PAGE_SIZE));
    const safePage = Math.min(page, totalPages - 1);
    const from = safePage * FEED_PAGE_SIZE;
    const visible = items.slice(from, from + FEED_PAGE_SIZE);

    return (
        <section className="dashFeed" aria-labelledby="dash-feed-title">
            <h2 className="dashSection__title" id="dash-feed-title">
                {t.feed.title}
            </h2>
            {items.length === 0
                ? <p className="dashFeed__empty">{t.feed.empty}</p>
                : (
                    <>
                        <ol className="dashFeed__list" aria-label={t.feed.regionLabel}>
                            {visible.map((item) => <FeedRow key={item.key} item={item} />)}
                        </ol>
                        {totalPages > 1 && (
                            <nav className="dashFeed__pager" aria-label={t.feed.pager.navLabel}>
                                <Button
                                    variant="outline"
                                    size="sm"
                                    disabled={safePage === 0}
                                    onClick={() => setPage(safePage - 1)}
                                >
                                    {t.feed.pager.prev}
                                </Button>
                                <span className="dashFeed__pagerRange" aria-live="polite">
                                    {t.feed.pager.range(
                                        from + 1,
                                        from + visible.length,
                                        items.length,
                                    )}
                                </span>
                                <Button
                                    variant="outline"
                                    size="sm"
                                    disabled={safePage >= totalPages - 1}
                                    onClick={() => setPage(safePage + 1)}
                                >
                                    {t.feed.pager.next}
                                </Button>
                            </nav>
                        )}
                    </>
                )}
        </section>
    );
}
