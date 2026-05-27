import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { useCurrentUser } from "../../auth/useCurrentUser";
import { listMyVehicles, Vehicle } from "../../api/vehicles";
import { listMyTransportWindows, TransportWindow } from "../../api/transport_windows";
import { listMyCargoOffers, CargoOffer } from "../../api/cargoOffers";
import { listCarrierShipments, listShipperShipments, Shipment } from "../../api/shipments";
import { ShipmentStateChip } from "../../components/shipments/ShipmentStateChip";
import { shipmentStateSortOrder } from "../../components/shipments/shipmentsSharedContent";
import { dashboardContent, CARGO_OFFER_STATUS_LABEL, CARGO_OFFER_STATUS_BADGE_CLASS } from "./dashboardContent";
import { MyCargosSection } from "./MyCargosSection";
import "../../styles/dashboard.css";
import "../../styles/shipments.css";

const arDateFormatter = new Intl.DateTimeFormat("es-AR", {
    day: "2-digit",
    month: "2-digit",
    year: "2-digit",
});

const arsFormatter = new Intl.NumberFormat("es-AR", {
    style: "currency",
    currency: "ARS",
    maximumFractionDigits: 0,
});

function formatDate(iso: string) {
    return arDateFormatter.format(new Date(iso));
}

// Shorten a full street address to the city+province part for compact cards.
function formatAddress(addr: string): string {
    const parts = addr.split(",");
    return parts.length >= 2 ? parts.slice(1).join(",").trim() : addr;
}

function formatARS(cents: number): string {
    return arsFormatter.format(cents / 100);
}

const dc = dashboardContent;

function sortDashboardShipments(items: Shipment[]): Shipment[] {
    return [...items].sort((a, b) => {
        const stateDiff = shipmentStateSortOrder[a.state] - shipmentStateSortOrder[b.state];
        if (stateDiff !== 0) return stateDiff;
        return new Date(b.latest_activity_at).getTime() - new Date(a.latest_activity_at).getTime();
    });
}

export function DashboardPage() {
    const { me, loading } = useCurrentUser();
    const [vehicles, setVehicles] = useState<Vehicle[]>([]);

    const [windows, setWindows]           = useState<TransportWindow[]>([]);
    const [windowsTotal, setWindowsTotal] = useState(0);

    const [cargoOffers, setCargoOffers]           = useState<CargoOffer[]>([]);
    const [cargoOffersTotal, setCargoOffersTotal] = useState(0);

    const [shipments, setShipments] = useState<Shipment[]>([]);

    const isCarrier = me?.roles.includes("carrier");

    useEffect(() => {
        const fetchShipments = isCarrier ? listCarrierShipments : listShipperShipments;
        fetchShipments()
            .then(items => setShipments(sortDashboardShipments(items)))
            .catch(console.error);

        if (isCarrier) {
            listMyVehicles().then(res => setVehicles(res.items)).catch(console.error);
            listMyTransportWindows(1)
                .then(res => { setWindows(res.items); setWindowsTotal(res.meta.total); })
                .catch(console.error);
        } else {
            listMyCargoOffers(1)
                .then(res => { setCargoOffers(res.items); setCargoOffersTotal(res.meta.total); })
                .catch(console.error);
        }
    }, [isCarrier]);

    if (loading) {
        return (
            <main className="dashboardLoading" id="main" aria-busy="true" aria-live="polite">
                <span className="sr-only">Cargando panel</span>
                <div className="dashboardSkeleton dashboardSkeletonTitle" />
                <div className="dashboardSkeletonRow">
                    <div className="dashboardSkeleton dashboardSkeletonCard" />
                    <div className="dashboardSkeleton dashboardSkeletonCard" />
                    <div className="dashboardSkeleton dashboardSkeletonCard" />
                </div>
            </main>
        );
    }
    if (!me) return null;

    const firstName = (me.full_name || me.email).split(/[\s@]/)[0];

    return (
        <main className="dashboardMain" id="main">
            <div className="dashboardContainer">
                <header className="dashboardHero">
                    <span className={`dashboardHeroEyebrow${isCarrier ? " dashboardHeroEyebrow--carrier" : ""}`}>
                        {isCarrier ? dc.hero.eyebrow.carrier : dc.hero.eyebrow.shipper}
                    </span>
                    <h1 className="dashboardHeroTitle">{dc.hero.greeting(firstName)}</h1>
                    <p className="dashboardHeroLead">
                        {isCarrier ? dc.hero.lead.carrier : dc.hero.lead.shipper}
                    </p>
                </header>

                <section className="dashboardSection" aria-labelledby="section-trips">
                    <div className="dashboardSectionHeader">
                        <div className="dashboardSectionHeading">
                            <span className="dashboardSectionIcon" aria-hidden="true"><IconTruck /></span>
                            <h2 id="section-trips">{dc.trips.heading}</h2>
                            {shipments.length > 0 && (
                                <span className="dashboardSectionCount" aria-label={`${shipments.length} envíos`}>
                                    {shipments.length}
                                </span>
                            )}
                        </div>
                        <Link
                            to={isCarrier ? "/carrier/shipments" : "/shipper/shipments"}
                            className="button buttonGhost"
                        >
                            {dc.trips.viewAll}
                        </Link>
                    </div>
                    <div className="dashboardCardList">
                        {shipments.length === 0 ? (
                            <div className="dashboardEmpty" role="status">
                                <span className="dashboardEmptyIcon" aria-hidden="true"><IconRoute /></span>
                                <div>
                                    <span className="dashboardEmptyTitle">{dc.trips.emptyTitle}</span>
                                    <span className="dashboardEmptyHint">{dc.trips.emptyHint}</span>
                                </div>
                            </div>
                        ) : (
                            shipments.slice(0, 3).map(s => (
                                <Link
                                    key={s.id}
                                    to={isCarrier ? `/carrier/shipments/${s.id}` : `/shipper/shipments/${s.id}`}
                                    className={`dashboardCard${isCarrier ? " dashboardCard--sky" : " dashboardCard--cream"}`}
                                >
                                    <div className="dashboardCardHead">
                                        <ShipmentStateChip state={s.state} />
                                    </div>
                                    <h3
                                        className="dashboardCardTitle"
                                        aria-label={`${formatAddress(s.origin)} a ${formatAddress(s.destination)}`}
                                    >
                                        {formatAddress(s.origin)}
                                        <span aria-hidden="true"> → </span>
                                        {formatAddress(s.destination)}
                                        <IconArrowRight className="arrow" />
                                    </h3>
                                    <div className="dashboardCardMeta">
                                        <IconMoney />
                                        <span>{formatARS(s.amount_cents)}</span>
                                    </div>
                                    <div className="dashboardCardMeta">
                                        <IconCalendar />
                                        <span>{formatDate(s.latest_activity_at)}</span>
                                    </div>
                                </Link>
                            ))
                        )}
                    </div>
                </section>

                {!isCarrier && <MyCargosSection />}

                {!isCarrier && (
                    <section className="dashboardSection" aria-labelledby="section-offers">
                        <div className="dashboardSectionHeader">
                            <div className="dashboardSectionHeading">
                                <span className="dashboardSectionIcon" aria-hidden="true"><IconOffer /></span>
                                <h2 id="section-offers">{dc.shipper.offers.heading}</h2>
                                <span className="dashboardSectionCount" aria-label={`${cargoOffersTotal} ofertas`}>
                                    {cargoOffersTotal}
                                </span>
                            </div>
                        </div>
                        <div className="dashboardCardList">
                            {cargoOffers.length === 0 ? (
                                <div className="dashboardEmpty" role="status">
                                    <span className="dashboardEmptyIcon" aria-hidden="true"><IconOffer /></span>
                                    <div>
                                        <span className="dashboardEmptyTitle">{dc.shipper.offers.emptyTitle}</span>
                                        <span className="dashboardEmptyHint">
                                            {dc.shipper.offers.emptyHint}
                                        </span>
                                    </div>
                                </div>
                            ) : (
                                cargoOffers.map(co => (
                                    <div key={co.id} className="dashboardCard">
                                        <div className="dashboardCardHead">
                                            <span className={`statusBadge ${CARGO_OFFER_STATUS_BADGE_CLASS[co.status] ?? "pasado"}`}>
                                                {CARGO_OFFER_STATUS_LABEL[co.status] ?? co.status}
                                            </span>
                                        </div>
                                        <h3
                                            className="dashboardCardTitle"
                                            aria-label={co.cargo
                                                ? `${formatAddress(co.cargo.pickup_address)} a ${formatAddress(co.cargo.delivery_address)}`
                                                : dc.shipper.offers.fallbackCard(co.id)}
                                        >
                                            {co.cargo ? (
                                                <>
                                                    {formatAddress(co.cargo.pickup_address)}
                                                    <span aria-hidden="true"> → </span>
                                                    {formatAddress(co.cargo.delivery_address)}
                                                </>
                                            ) : dc.shipper.offers.fallbackCard(co.id)}
                                        </h3>
                                        <div className="dashboardCardMeta">
                                            <IconCalendar />
                                            <span>
                                                {co.cargo
                                                    ? formatDate(co.cargo.pickup_window_start)
                                                    : formatDate(co.created_at)}
                                            </span>
                                        </div>
                                        <div className="dashboardCardMeta">
                                            <IconMoney />
                                            <span>{formatARS(co.amount_cents)}</span>
                                        </div>
                                    </div>
                                ))
                            )}
                        </div>
                    </section>
                )}

                {isCarrier && (
                    <>
                        <section className="dashboardSection" aria-labelledby="section-availability">
                            <div className="dashboardSectionHeader">
                                <div className="dashboardSectionHeading">
                                    <span className="dashboardSectionIcon dashboardSectionIcon--sky" aria-hidden="true"><IconCalendar /></span>
                                    <h2 id="section-availability">{dc.carrier.availability.heading}</h2>
                                    <span className="dashboardSectionCount" aria-label={`${windowsTotal} ventanas`}>
                                        {windowsTotal}
                                    </span>
                                </div>
                                <Link to="/carrier/availability" className="button buttonGhost">
                                    {dc.carrier.availability.viewAll}
                                </Link>
                            </div>
                            <div className="dashboardCardList">
                                {windows.length === 0 ? (
                                    <div className="dashboardEmpty" role="status">
                                        <span className="dashboardEmptyIcon" aria-hidden="true"><IconCalendar /></span>
                                        <div>
                                            <span className="dashboardEmptyTitle">{dc.carrier.availability.emptyTitle}</span>
                                            <span className="dashboardEmptyHint">{dc.carrier.availability.emptyHint}</span>
                                        </div>
                                    </div>
                                ) : (
                                    windows.map(w => (
                                        <Link
                                            key={w.id}
                                            to={`/carrier/availability/${w.id}`}
                                            className="dashboardCard dashboardCard--sky"
                                        >
                                            <div className="dashboardCardHead">
                                                <span className="dashboardCardEyebrow">
                                                    {w.active ? dc.carrier.availability.statusActive : dc.carrier.availability.statusInactive}
                                                </span>
                                            </div>
                                            <h3
                                                className="dashboardCardTitle"
                                                aria-label={`${w.origin_province} a ${w.destination_province ?? "Destino abierto"}`}
                                            >
                                                {w.origin_locality ? `${w.origin_province}, ${w.origin_locality}` : w.origin_province}
                                                <span aria-hidden="true"> → </span>
                                                {w.destination_province
                                                    ? (w.destination_locality ? `${w.destination_province}, ${w.destination_locality}` : w.destination_province)
                                                    : "Destino abierto"}
                                                <IconArrowRight className="arrow" />
                                            </h3>
                                            <div className="dashboardCardMeta">
                                                <IconCalendar />
                                                <span>{formatDate(w.available_from)} – {formatDate(w.available_to)}</span>
                                            </div>
                                        </Link>
                                    ))
                                )}
                                <Link to="/carrier/availability/new" className="dashboardCard dashboardCard--sky dashboardCardNew dashboardCardNew--sky" aria-label={dc.carrier.availability.newLabel}>
                                    <span className="dashboardCardNewIcon dashboardCardNewIcon--sky" aria-hidden="true"><IconPlus /></span>
                                    <span className="dashboardCardNewLabel">{dc.carrier.availability.newLabel}</span>
                                </Link>
                            </div>
                        </section>

                        <section className="dashboardSection" aria-labelledby="section-vehicles">
                            <div className="dashboardSectionHeader">
                                <div className="dashboardSectionHeading">
                                    <span className="dashboardSectionIcon dashboardSectionIcon--sky" aria-hidden="true"><IconVehicle /></span>
                                    <h2 id="section-vehicles">{dc.carrier.fleet.heading}</h2>
                                    <span className="dashboardSectionCount" aria-label={`${vehicles.length} vehículos`}>
                                        {vehicles.length}
                                    </span>
                                </div>
                                <Link to="/carrier/vehicles" className="button buttonGhost">
                                    {dc.carrier.fleet.viewAll}
                                </Link>
                            </div>
                            <div className="dashboardCardList">
                                {vehicles.length === 0 ? (
                                    <div className="dashboardEmpty" role="status">
                                        <span className="dashboardEmptyIcon" aria-hidden="true"><IconVehicle /></span>
                                        <div>
                                            <span className="dashboardEmptyTitle">{dc.carrier.fleet.emptyTitle}</span>
                                            <span className="dashboardEmptyHint">{dc.carrier.fleet.emptyHint}</span>
                                        </div>
                                    </div>
                                ) : (
                                    vehicles.map(v => (
                                        <Link
                                            key={v.id}
                                            to={`/carrier/vehicle/${v.id}`}
                                            className="dashboardCard dashboardCard--sky"
                                        >
                                            <div className="dashboardCardHead">
                                                <span className="dashboardCardEyebrow">{dc.carrier.fleet.plateLabel}</span>
                                            </div>
                                            <h3 className="dashboardCardTitle">
                                                {v.plate}
                                                <IconArrowRight className="arrow" />
                                            </h3>
                                            <div className="dashboardCardMeta">
                                                <IconVehicleSmall />
                                                <span>{v.make} {v.model}</span>
                                            </div>
                                        </Link>
                                    ))
                                )}
                                <Link to="/carrier/vehicle/new" className="dashboardCard dashboardCard--sky dashboardCardNew dashboardCardNew--sky" aria-label={dc.carrier.fleet.addLabel}>
                                    <span className="dashboardCardNewIcon" aria-hidden="true"><IconPlus /></span>
                                    <span className="dashboardCardNewLabel">{dc.carrier.fleet.addLabel}</span>
                                </Link>
                            </div>
                        </section>
                    </>
                )}
            </div>
        </main>
    );
}

/* ---- Icons (Lucide-style strokes, currentColor) --------------------- */

type IconProps = { className?: string };

function IconTruck() {
    return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="M3 7h11v9H3z" />
            <path d="M14 10h4l3 3v3h-7" />
            <circle cx="7.5" cy="17.5" r="1.75" />
            <circle cx="17.5" cy="17.5" r="1.75" />
        </svg>
    );
}

function IconVehicle() {
    return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="M5 13l1.5-4.5A2 2 0 0 1 8.4 7h7.2a2 2 0 0 1 1.9 1.5L19 13" />
            <path d="M4 13h16v4a1 1 0 0 1-1 1h-2v-2H7v2H5a1 1 0 0 1-1-1z" />
            <circle cx="7.5" cy="16" r="1.25" />
            <circle cx="16.5" cy="16" r="1.25" />
        </svg>
    );
}

function IconVehicleSmall() {
    return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="M5 13l1.5-4.5A2 2 0 0 1 8.4 7h7.2a2 2 0 0 1 1.9 1.5L19 13" />
            <path d="M4 13h16v4H4z" />
        </svg>
    );
}

function IconCalendar() {
    return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <rect x="3.5" y="5" width="17" height="15" rx="2" />
            <path d="M3.5 10h17" />
            <path d="M8 3v4M16 3v4" />
        </svg>
    );
}

function IconRoute() {
    return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <circle cx="6" cy="6" r="2.25" />
            <circle cx="18" cy="18" r="2.25" />
            <path d="M8 6h6a4 4 0 0 1 0 8h-4a4 4 0 0 0 0 8h6" />
        </svg>
    );
}

function IconPlus() {
    return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="M12 5v14M5 12h14" />
        </svg>
    );
}

function IconArrowRight({ className }: IconProps) {
    return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" className={className}>
            <path d="M5 12h14M13 6l6 6-6 6" />
        </svg>
    );
}

function IconOffer() {
    return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <rect x="3" y="5" width="18" height="14" rx="2" />
            <path d="M3 9h18" />
            <path d="M8 13h2M14 13h2" />
        </svg>
    );
}

function IconMoney() {
    return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <circle cx="12" cy="12" r="9" />
            <path d="M12 7v10M9.5 9.5C9.5 8.4 10.6 8 12 8s2.5.4 2.5 1.5-1.1 2-2.5 2-2.5.9-2.5 2S10.6 16 12 16s2.5-.4 2.5-1.5" />
        </svg>
    );
}
