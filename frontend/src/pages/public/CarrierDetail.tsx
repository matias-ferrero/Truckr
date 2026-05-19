import { useContext, useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { CarrierDetail as CarrierDetailDto, getCarrier } from "../../api/carriers";
import { ApiError } from "../../api";
import { publicContent } from "./publicContent";
import { Button, buttonVariants } from "../../components/ui/button";
import { cn } from "../../lib/utils";
import { AuthContext } from "../../auth/AuthContext";
import { useCurrentUser } from "../../auth/useCurrentUser";

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
    const { me } = useCurrentUser();
    const navigate = useNavigate();

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
            <main className="page publicMain" id="main" aria-busy="true">
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
            <main className="page publicMain" id="main">
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
            <main className="page publicMain" id="main">
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
    const isShipper = me?.roles.includes("shipper") ?? false;
    const ratingNum = Number(carrier.rating_avg);
    const isOwner = myCarrierId === carrier.id;

    return (
        <main className="page publicMain" id="main">
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
                            <span className="carrierHeroRating">
                                {t.ratingLabel(carrier.rating_avg, carrier.reviews_count)}
                            </span>
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
                    isShipper={isShipper}
                    onOffer={(w) =>
                        navigate(`/carriers/${carrierId}/offers/new?window=${w.id}`, {
                            state: { carrier, window: w },
                        })
                    }
                />

                <VehiclesSection vehicles={carrier.vehicles} />

                <section className="carrierSection" aria-labelledby="carrier-reviews-title">
                    <h2 id="carrier-reviews-title" className="sectionSubtitle">
                        {t.reviewsTitle}
                    </h2>
                    <p className="carrierMutedBlock">{t.reviewsPlaceholder}</p>
                </section>
            </div>
        </main>
    );
}

/* --- helpers --- */

function Stars({ rating }: { rating: number }) {
    // Floor to whole stars; we don't render half stars to keep the SVG simple.
    const rounded = Math.max(0, Math.min(5, Math.round(rating)));
    const ariaLabel = t.starsLabel(rating.toFixed(2));
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
    isShipper,
    onOffer,
}: {
    windows: CarrierDetailDto["transport_windows"];
    carrier: CarrierDetailDto;
    carrierId: number;
    isShipper: boolean;
    onOffer: (w: CarrierDetailDto["transport_windows"][0]) => void;
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
                                    {t.zoneLine(w.origin_zone, w.destination_zone)}
                                </span>
                                <span className="zonePrice">
                                    {t.pricePerKmLabel(w.price_per_km)}
                                </span>
                                {isShipper && (
                                    <Button
                                        size="sm"
                                        data-testid="offer-cta-top"
                                        aria-label={t.offerCtaAriaLabel(
                                            t.zoneLine(w.origin_zone, w.destination_zone),
                                        )}
                                        onClick={() => onOffer(w)}
                                    >
                                        {t.offerCta}
                                    </Button>
                                )}
                            </li>
                        ))}
                    </ul>
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
