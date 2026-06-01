import { useCallback, useContext, useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import {
    getShipper,
    listShipperReviews,
    type ReviewListMeta,
    type ShipperDetail as ShipperDetailDto,
} from "../../api/shippers";
import type { Review } from "../../api/reviews";
import { ApiError } from "../../api";
import { publicContent } from "./publicContent";
import { Button, buttonVariants } from "../../components/ui/button";
import { cn } from "../../lib/utils";
import { AuthContext } from "../../auth/AuthContext";

const t = publicContent.shipperDetail;

type ShipperState =
    | { status: "loading" }
    | { status: "ready"; shipper: ShipperDetailDto }
    | { status: "notFound" }
    | { status: "error"; message: string };

/**
 * Public shipper profile page (US54 — REQ-BE-00045). Visible to authenticated
 * users. Shows identity, the average rating with stars + review count (AC2),
 * and a paginated list of individual review cards (AC5). Empty state uses the
 * reviews.shipper.empty copy.
 */
export default function ShipperDetail() {
    const params = useParams<{ id: string }>();
    const shipperId = Number(params.id);
    // Read context directly (not via the throwing hook) so the page works
    // when rendered without an AuthProvider — e.g. unit tests.
    const auth = useContext(AuthContext);
    const myShipperId = (auth?.me?.shipper as { id?: number } | null | undefined)?.id;

    const [state, setState] = useState<ShipperState>({ status: "loading" });
    const [reloadKey, setReloadKey] = useState(0);

    useEffect(() => {
        if (!Number.isFinite(shipperId) || shipperId <= 0) {
            setState({ status: "notFound" });
            return;
        }
        const ctrl = new AbortController();
        setState({ status: "loading" });
        getShipper(shipperId, { signal: ctrl.signal })
            .then((shipper) => setState({ status: "ready", shipper }))
            .catch((err: unknown) => {
                if ((err as { name?: string }).name === "AbortError") return;
                if (err instanceof ApiError && err.status === 404) {
                    setState({ status: "notFound" });
                } else {
                    setState({
                        status: "error",
                        message: err instanceof Error ? err.message : String(err),
                    });
                }
            });
        return () => ctrl.abort();
    }, [shipperId, reloadKey]);

    if (state.status === "loading") {
        return (
            <main className="page publicMain" id="main" aria-busy="true">
                <div className="container">
                    <div className="carrierDetailSkeleton" aria-label={t.loadingLabel}>
                        <div className="skeletonBlock skeletonHero" />
                        <div className="skeletonBlock skeletonBody" />
                    </div>
                </div>
            </main>
        );
    }

    if (state.status === "notFound") {
        return (
            <main className="page publicMain" id="main">
                <div className="container">
                    <div className="emptyState" role="status">
                        <h1 className="sectionTitle">{t.notFoundTitle}</h1>
                        <p>{t.notFoundLead}</p>
                        <Link to="/" className={cn(buttonVariants({ variant: "ghost", size: "sm" }))}>
                            {t.back}
                        </Link>
                    </div>
                </div>
            </main>
        );
    }

    if (state.status === "error") {
        return (
            <main className="page publicMain" id="main">
                <div className="container">
                    <div className="errorPanel" role="alert">
                        <p>{t.loadError}: {state.message}</p>
                        <Button variant="ghost" size="sm" onClick={() => setReloadKey((k) => k + 1)}>
                            {t.retry}
                        </Button>
                    </div>
                </div>
            </main>
        );
    }

    const { shipper } = state;
    const name = shipper.company_name ?? `#${shipper.id}`;
    const isOwner = myShipperId === shipper.id;

    return (
        <main className="page publicMain" id="main">
            <div className="container">
                <header className="carrierHero" aria-labelledby="shipper-name">
                    <div className="carrierHeroBody">
                        <h1 id="shipper-name" className="sectionTitle">{t.title(name)}</h1>
                        {isOwner && (
                            <Link
                                to="/profile"
                                className={cn(buttonVariants({ variant: "ghost", size: "sm" }), "w-fit")}
                            >
                                {t.editProfile}
                            </Link>
                        )}
                        <div className="carrierHeroMeta">
                            <Stars rating={Number(shipper.rating_avg)} />
                            {shipper.reviews_count > 0 && shipper.rating_avg != null ? (
                                <span className="carrierHeroRating">
                                    <span className="carrierHeroRatingValue">{t.ratingValue(shipper.rating_avg)}</span>
                                    <span className="carrierHeroRatingCount">{t.ratingCount(shipper.reviews_count)}</span>
                                </span>
                            ) : (
                                <span className="carrierHeroRating carrierHeroRatingEmpty">
                                    {t.ratingLabel(shipper.rating_avg, shipper.reviews_count)}
                                </span>
                            )}
                            {shipper.tax_id && (
                                <>
                                    <span aria-hidden="true">·</span>
                                    <span>{t.taxIdLabel}: <strong>{shipper.tax_id}</strong></span>
                                </>
                            )}
                        </div>
                    </div>
                </header>

                <ReviewsSection
                    shipperId={shipper.id}
                    ratingAvg={shipper.rating_avg}
                    reviewsCount={shipper.reviews_count}
                />
            </div>
        </main>
    );
}

/* --- helpers --- */

function Stars({ rating }: { rating: number }) {
    const rounded = Math.max(0, Math.min(5, Math.round(rating)));
    return (
        <span className="starRow" role="img" aria-label={t.starsLabel(rating.toFixed(1))}>
            {[0, 1, 2, 3, 4].map((i) => (
                <span key={i} className={`star${i < rounded ? " starFilled" : ""}`} aria-hidden="true">
                    ★
                </span>
            ))}
        </span>
    );
}

type ReviewsState =
    | { status: "loading" }
    | { status: "ready"; reviews: Review[]; meta: ReviewListMeta }
    | { status: "error"; message: string };

function ReviewsSection({
    shipperId,
    ratingAvg,
    reviewsCount,
}: {
    shipperId: number;
    ratingAvg: string | null;
    reviewsCount: number;
}) {
    const [state, setState] = useState<ReviewsState>({ status: "loading" });
    const [loadingMore, setLoadingMore] = useState(false);

    useEffect(() => {
        const ctrl = new AbortController();
        setState({ status: "loading" });
        listShipperReviews(shipperId, 1, { signal: ctrl.signal })
            .then(({ reviews, meta }) => setState({ status: "ready", reviews, meta }))
            .catch((err: unknown) => {
                if ((err as { name?: string }).name === "AbortError") return;
                setState({
                    status: "error",
                    message: err instanceof Error ? err.message : String(err),
                });
            });
        return () => ctrl.abort();
    }, [shipperId]);

    const loadMore = useCallback(async () => {
        if (state.status !== "ready" || loadingMore) return;
        setLoadingMore(true);
        try {
            const next = state.meta.page + 1;
            const { reviews, meta } = await listShipperReviews(shipperId, next);
            setState({ status: "ready", reviews: [...state.reviews, ...reviews], meta });
        } catch (err) {
            setState({
                status: "error",
                message: err instanceof Error ? err.message : String(err),
            });
        } finally {
            setLoadingMore(false);
        }
    }, [shipperId, state, loadingMore]);

    return (
        <section className="carrierSection shipperReviews" aria-labelledby="shipper-reviews-title">
            <h2 id="shipper-reviews-title" className="sectionSubtitle">{t.reviewsTitle}</h2>

            {state.status === "loading" && (
                <p className="carrierMutedBlock" aria-busy="true">{t.loadingMore}</p>
            )}

            {state.status === "error" && (
                <p className="errorPanel" role="alert">{t.loadError}: {state.message}</p>
            )}

            {state.status === "ready" && state.reviews.length === 0 && (
                <p className="carrierMutedBlock" role="status">{t.empty}</p>
            )}

            {state.status === "ready" && state.reviews.length > 0 && (
                <>
                    <ul className="shipperReviewList">
                        {state.reviews.map((r) => (
                            <li key={r.id} className="shipperReviewCard">
                                <div className="shipperReviewCardHead">
                                    <Stars rating={r.rating} />
                                    <span className="shipperReviewRating" aria-hidden="true">
                                        {r.rating}/5
                                    </span>
                                    <time className="shipperReviewDate" dateTime={r.created_at}>
                                        {t.reviewDate(r.created_at)}
                                    </time>
                                </div>
                                {r.body && <p className="shipperReviewBody">{r.body}</p>}
                            </li>
                        ))}
                    </ul>
                    {state.meta.page < state.meta.totalPages && (
                        <div className="shipperReviewsLoadMore">
                            <Button
                                variant="ghost"
                                size="sm"
                                onClick={loadMore}
                                disabled={loadingMore}
                            >
                                {loadingMore ? t.loadingMore : t.loadMore}
                            </Button>
                        </div>
                    )}
                </>
            )}
        </section>
    );
}
