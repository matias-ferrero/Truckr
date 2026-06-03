import { useCallback, useContext, useEffect, useState } from "react";
import { Link, useParams } from "react-router-dom";
import { CarrierDetail as CarrierDetailDto, getCarrier } from "../../api/carriers";
import { listCarrierReviews, type Review, type ReviewListMeta } from "../../api/reviews";
import { ApiError } from "../../api";
import { publicContent } from "./publicContent";
import { formatRoute } from "../../lib/format-place";
import { Button, buttonVariants } from "../../components/ui/button";
import { cn } from "../../lib/utils";
import { AuthContext } from "../../auth/AuthContext";

const t = publicContent.carrierDetail;

type CarrierState =
    | { status: "loading" }
    | { status: "ready"; carrier: CarrierDetailDto }
    | { status: "notFound" }
    | { status: "error"; message: string };

/**
 * Public carrier profile page — entry point from the search results list (US4).
 *
 * Layout:
 *  - Hero: legal name, average rating with stars, completed shipments.
 *  - Description / base city.
 *  - Transport windows (zones + price per km).
 *  - Gallery of vehicle photos.
 *  - Vehicle cards.
 *  - Reviews placeholder.
 */
export default function CarrierDetail() {
    const params = useParams<{ id: string }>();
    const carrierId = Number(params.id);
    // Read context directly (not via the throwing hook) so the page
    // works when rendered without an AuthProvider — e.g. unit tests
    // and public visitors who haven't logged in yet.
    const auth = useContext(AuthContext);
    const myCarrierId = (auth?.me?.carrier as { id?: number } | null | undefined)?.id;

    const [state, setState] = useState<CarrierState>({ status: "loading" });
    const [reloadKey, setReloadKey] = useState(0);

    useEffect(() => {
        if (!Number.isFinite(carrierId) || carrierId <= 0) {
            setState({ status: "notFound" });
            return;
        }
        const ctrl = new AbortController();
        setState({ status: "loading" });
        getCarrier(carrierId, { signal: ctrl.signal })
            .then((carrier) => setState({ status: "ready", carrier }))
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
    }, [carrierId, reloadKey]);

    if (state.status === "loading") {
        return (
            <main className="page publicMain carrierDetailMain" id="main" aria-busy="true">
                <div className="container">
                    <div className="carrierDetailSkeleton" aria-label={t.loadingLabel}>
                        <div className="skeletonBlock skeletonHero" />
                        <div className="skeletonBlock skeletonBody" />
                        <div className="skeletonBlock skeletonBody" />
                    </div>
                </div>
            </main>
        );
    }

    if (state.status === "notFound") {
        return (
            <main className="page publicMain carrierDetailMain" id="main">
                <div className="container">
                    <div className="emptyState" role="status">
                        <h1 className="sectionTitle">{t.notFoundTitle}</h1>
                        <p>{t.notFoundLead}</p>
                        <Link
                            to="/"
                            className={cn(buttonVariants({ variant: "ghost", size: "sm" }))}
                        >
                            {t.backToSearch}
                        </Link>
                    </div>
                </div>
            </main>
        );
    }

    if (state.status === "error") {
        return (
            <main className="page publicMain carrierDetailMain" id="main">
                <div className="container">
                    <div className="errorPanel" role="alert">
                        <p>{t.loadError}: {state.message}</p>
                        <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => setReloadKey((k) => k + 1)}
                        >
                            {t.retry}
                        </Button>
                    </div>
                </div>
            </main>
        );
    }

    const { carrier } = state;
    const ratingNum = carrier.rating_avg !== null ? Number(carrier.rating_avg) : 0;
    const isOwner = myCarrierId === carrier.id;
    const isAuthenticated = Boolean(auth?.me);

    return (
        <main className="page publicMain carrierDetailMain" id="main">
            <div className="container">
                <header className="carrierHero" aria-labelledby="carrier-name">
                    <div className="carrierHeroBody">
                        <h1 id="carrier-name" className="sectionTitle">
                            {carrier.legal_name ?? `#${carrier.id}`}
                        </h1>
                        {isOwner && (
                            <Link
                                to="/profile"
                                className={cn(buttonVariants({ variant: "ghost", size: "sm" }), "w-fit")}
                            >
                                {t.editProfile}
                            </Link>
                        )}
                        <div className="carrierHeroMeta">
                            <Stars rating={ratingNum} />
                            {carrier.reviews_count > 0 && carrier.rating_avg != null ? (
                                <span className="carrierHeroRating">
                                    <span className="carrierHeroRatingValue">{t.ratingValue(carrier.rating_avg)}</span>
                                    <span className="carrierHeroRatingCount">{t.ratingCount(carrier.reviews_count)}</span>
                                </span>
                            ) : (
                                <span className="carrierHeroRating carrierHeroRatingEmpty">
                                    {t.ratingLabel(carrier.rating_avg, carrier.reviews_count)}
                                </span>
                            )}
                            <span aria-hidden="true">·</span>
                            <span>{t.completedShipments(carrier.completed_shipments)}</span>
                            {carrier.base_city && (
                                <>
                                    <span aria-hidden="true">·</span>
                                    <span>
                                        {t.baseCity}: <strong>{carrier.base_city}</strong>
                                    </span>
                                </>
                            )}
                        </div>
                    </div>
                </header>

                <section className="carrierSection" aria-labelledby="carrier-description-title">
                    <h2 id="carrier-description-title" className="sectionSubtitle">
                        {t.descriptionTitle}
                    </h2>
                    <p className="carrierDescription">
                        {carrier.description?.trim() || t.descriptionFallback}
                    </p>
                </section>

                <ZonesSection
                    windows={carrier.transport_windows}
                    carrier={carrier}
                    carrierId={carrierId}
                />

                <VehiclesSection vehicles={carrier.vehicles} />

                <CarrierReviewsSection
                    carrierId={carrierId}
                    isAuthenticated={isAuthenticated}
                />
            </div>
        </main>
    );
}

/* --- helpers --- */

function Stars({ rating }: { rating: number }) {
    // Floor to whole stars; we don't render half stars to keep the SVG simple.
    const rounded = Math.max(0, Math.min(5, Math.round(rating)));
    const ariaLabel = t.starsLabel(rating.toFixed(1));
    return (
        <span className="starRow" role="img" aria-label={ariaLabel}>
            {[0, 1, 2, 3, 4].map((i) => (
                <span
                    key={i}
                    className={`star${i < rounded ? " starFilled" : ""}`}
                    aria-hidden="true"
                >
                    ★
                </span>
            ))}
        </span>
    );
}

function ZonesSection({
    windows,
    carrier,
    carrierId,
}: {
    windows: CarrierDetailDto["transport_windows"];
    carrier: CarrierDetailDto;
    carrierId: number;
}) {
    // Suppress unused-variable lint on carrierId — kept for future deep-link use.
    void carrierId;
    void carrier;
    return (
        <section className="carrierSection" aria-labelledby="carrier-zones-title">
            <h2 id="carrier-zones-title" className="sectionSubtitle">
                {t.zonesTitle}
            </h2>
            {windows.length === 0
                ? <p className="carrierMutedBlock">{t.zonesEmpty}</p>
                : (
                    <ul className="zoneList">
                        {windows.map((w) => (
                            <li key={w.id} className="zoneItem">
                                <span className="zoneRoute">
                                    {formatRoute(
                                        { locality: w.origin_locality, admin_area: w.origin_admin_area },
                                        w.destination_lat !== null
                                            ? { locality: w.destination_locality, admin_area: w.destination_admin_area }
                                            : null,
                                        t.openDestinationLabel,
                                    )}
                                </span>
                                <span className="zonePrice">
                                    {t.pricePerKmLabel(w.price_per_km)}
                                </span>
                            </li>
                        ))}
                    </ul>
                )}
        </section>
    );
}

type ReviewsState =
    | { status: "loading" }
    | { status: "ready"; reviews: Review[]; meta: ReviewListMeta }
    | { status: "error"; message: string };

function CarrierReviewsSection({
    carrierId,
    isAuthenticated,
}: {
    carrierId: number;
    isAuthenticated: boolean;
}) {
    const [state, setState] = useState<ReviewsState>({ status: "loading" });
    const [loadingMore, setLoadingMore] = useState(false);

    useEffect(() => {
        if (!isAuthenticated) return;
        const ctrl = new AbortController();
        setState({ status: "loading" });
        listCarrierReviews(carrierId, 1, { signal: ctrl.signal })
            .then(({ items, meta }) => setState({ status: "ready", reviews: items, meta }))
            .catch((err: unknown) => {
                if ((err as { name?: string }).name === "AbortError") return;
                setState({
                    status: "error",
                    message: err instanceof Error ? err.message : String(err),
                });
            });
        return () => ctrl.abort();
    }, [carrierId, isAuthenticated]);

    const loadMore = useCallback(async () => {
        if (state.status !== "ready" || loadingMore) return;
        setLoadingMore(true);
        try {
            const next = state.meta.page + 1;
            const { items, meta } = await listCarrierReviews(carrierId, next);
            setState({ status: "ready", reviews: [...state.reviews, ...items], meta });
        } catch (err) {
            setState({
                status: "error",
                message: err instanceof Error ? err.message : String(err),
            });
        } finally {
            setLoadingMore(false);
        }
    }, [carrierId, state, loadingMore]);

    return (
        <section className="carrierSection" aria-labelledby="carrier-reviews-title">
            <h2 id="carrier-reviews-title" className="sectionSubtitle">
                {t.reviewsTitle}
            </h2>

            {!isAuthenticated && (
                <p className="carrierMutedBlock">{t.signInHint}</p>
            )}

            {isAuthenticated && state.status === "loading" && (
                <p className="carrierMutedBlock" aria-busy="true">{t.loadingMore}</p>
            )}

            {isAuthenticated && state.status === "error" && (
                <p className="errorPanel" role="alert">{t.loadError}: {state.message}</p>
            )}

            {isAuthenticated && state.status === "ready" && state.reviews.length === 0 && (
                <p className="carrierMutedBlock" role="status">{t.empty}</p>
            )}

            {isAuthenticated && state.status === "ready" && state.reviews.length > 0 && (
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

function VehiclesSection({ vehicles }: { vehicles: CarrierDetailDto["vehicles"] }) {
    if (vehicles.length === 0) return null;
    return (
        <section className="carrierSection" aria-labelledby="carrier-vehicles-title">
            <h2 id="carrier-vehicles-title" className="sectionSubtitle">
                {t.vehiclesTitle}
            </h2>
            <ul className="vehicleGrid">
                {vehicles.map((v) => (
                    <li key={v.id} className="vehicleCard">
                        <div className="cardImage">
                            {v.photos[0]
                                ? (
                                    <img
                                        src={v.photos[0].card}
                                        alt={t.photoAlt(`${v.make} ${v.model}`)}
                                        loading="lazy"
                                        decoding="async"
                                    />
                                )
                                : <div className="cardPlaceholder" aria-hidden="true">🚚</div>}
                        </div>
                        <div className="cardBody">
                            <h3>{t.vehicleHeading(v.make, v.model)}</h3>
                            <p className="cardMeta">
                                {t.vehiclePlate}: <strong>{v.plate}</strong>
                            </p>
                            <p className="cardMeta">
                                {t.vehicleCapacity}: {v.max_load_kg} {t.vehicleCapacityUnit}
                            </p>
                            <p className="cardMeta">
                                {t.vehicleGps}:{" "}
                                {v.gps_enabled ? t.vehicleGpsYes : t.vehicleGpsNo}
                            </p>
                            {v.description && (
                                <p className="cardMeta cardDescription">{v.description}</p>
                            )}
                        </div>
                    </li>
                ))}
            </ul>
        </section>
    );
}
