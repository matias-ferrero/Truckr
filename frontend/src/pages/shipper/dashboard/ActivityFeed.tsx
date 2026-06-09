import { useState } from "react";
import { Link } from "react-router-dom";
import { Button } from "../../../components/ui/button";
import type { ActivityItem } from "./buildActivityFeed";
import { shipperDashboardContent as t } from "./shipperDashboardContent";
import { formatArs, relativeTime } from "./format";

export const FEED_PAGE_SIZE = 6;

/** Stroke icon per activity type. Decorative (aria-hidden) — the text
 *  description carries the meaning. 24px viewBox, drawn at 20px inside a
 *  40px semantic-tinted tile so each kind is recognizable at a glance. */
function GlyphIcon({ type }: { type: ActivityItem["type"] }) {
    const paths: Record<ActivityItem["type"], React.ReactNode> = {
        offer_received: (
            <>
                <rect x="3" y="5" width="18" height="14" rx="2" />
                <path d="m3 7 9 6 9-6" />
            </>
        ),
        shipment_accepted: (
            <>
                <circle cx="12" cy="12" r="9" />
                <path d="m8.5 12.5 2.5 2.5 4.5-5.5" />
            </>
        ),
        shipment_in_transit: (
            <>
                <path d="M2 7h12v9H2z" />
                <path d="M14 10h4l3 3.5V16h-7" />
                <circle cx="6" cy="18" r="1.8" />
                <circle cx="17.5" cy="18" r="1.8" />
            </>
        ),
        shipment_delivered: (
            <>
                <path d="m12 3 8.5 4.7v8.6L12 21l-8.5-4.7V7.7L12 3z" />
                <path d="M3.5 7.7 12 12.4l8.5-4.7" />
                <path d="M12 12.4V21" />
            </>
        ),
        payment_escrowed: (
            <>
                <rect x="5" y="11" width="14" height="9" rx="2" />
                <path d="M8 11V8a4 4 0 0 1 8 0v3" />
            </>
        ),
        payment_failed: (
            <>
                <path d="M12 3.5 2.5 19.5h19L12 3.5z" />
                <path d="M12 10v4" />
                <path d="M12 16.8v.2" />
            </>
        ),
        status_change: (
            <>
                <path d="M20.5 12a8.5 8.5 0 1 1-2.6-6.1" />
                <path d="M20.5 3.5v4.4h-4.4" />
            </>
        ),
        note: <path d="m16.8 3.5 3.7 3.7L8 19.7l-4.8 1.1L4.3 16 16.8 3.5z" />,
        gps_update: (
            <>
                <path d="M12 21.5s-7-5.6-7-11.3a7 7 0 0 1 14 0c0 5.7-7 11.3-7 11.3z" />
                <circle cx="12" cy="10" r="2.5" />
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
            {paths[type]}
        </svg>
    );
}

function FeedRow({ item }: { item: ActivityItem }) {
    const description = t.feed.descriptions[item.type];
    const amount = item.amountCents !== null ? formatArs(item.amountCents) : null;
    const when = relativeTime(item.at);
    const hasRoute = item.origin !== null && item.destination !== null;
    return (
        <li className="dashFeed__item">
            <Link to={item.href} className="dashFeed__link">
                <span className={`dashFeed__glyph kind--${item.type}`} aria-hidden="true">
                    <GlyphIcon type={item.type} />
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
                {amount && <span className="dashFeed__amount">{amount}</span>}
            </Link>
        </li>
    );
}

export function ActivityFeed({ items }: { items: ActivityItem[] }) {
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
