import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { useCurrentUser } from "../../auth/useCurrentUser";
import { listMyVehicles, Vehicle } from "../../api/vehicles";
import { listMyTransportWindows, TransportWindow } from "../../api/transport_windows";
import { TransportWindowSearchSection } from "./TransportWindowSearchSection";
import "../../styles/dashboard.css";

function formatDate(iso: string) {
    return new Date(iso).toLocaleDateString("es-AR", {
        day: "2-digit",
        month: "2-digit",
        year: "2-digit",
    });
}

export function DashboardPage() {
    const { me, loading } = useCurrentUser();
    const [vehicles, setVehicles] = useState<Vehicle[]>([]);

    const [windows, setWindows]           = useState<TransportWindow[]>([]);
    const [windowsTotal, setWindowsTotal] = useState(0);

    const isCarrier = me?.roles.includes("carrier");

    useEffect(() => {
        if (isCarrier) {
            listMyVehicles().then(res => setVehicles(res.items)).catch(console.error);
            listMyTransportWindows(1)
                .then(res => { setWindows(res.items); setWindowsTotal(res.meta.total); })
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
    const roleLabel = isCarrier ? "Transportista" : "Expedidor";

    return (
        <main className="dashboardMain" id="main">
            <div className="dashboardContainer">
                <header className="dashboardHero">
                    <span className="dashboardHeroEyebrow">Panel · {roleLabel}</span>
                    <h1 className="dashboardHeroTitle">Hola, {firstName}</h1>
                    <p className="dashboardHeroLead">
                        {isCarrier
                            ? "Acá vas a ver tus viajes, tu disponibilidad y los vehículos que tenés cargados."
                            : "Acá vas a ver tus viajes y solicitudes de cotización."}
                    </p>
                    <span className="dashboardHeroAccount" aria-label={`Sesión iniciada como ${me.email}`}>
                        <IconUser /> {me.email}
                    </span>
                    {isCarrier && (
                        <Link to="/carriers/me" className="dashboardHeroLink">
                            Ver mi perfil público
                            <IconArrowRight />
                        </Link>
                    )}
                </header>

                {!isCarrier && <TransportWindowSearchSection />}

                <section className="dashboardSection" aria-labelledby="section-trips">
                    <div className="dashboardSectionHeader">
                        <div className="dashboardSectionHeading">
                            <span className="dashboardSectionIcon" aria-hidden="true"><IconTruck /></span>
                            <h2 id="section-trips">Mis viajes</h2>
                        </div>
                    </div>
                    <div className="dashboardCardList">
                        <div className="dashboardEmpty" role="status">
                            <span className="dashboardEmptyIcon" aria-hidden="true"><IconRoute /></span>
                            <div>
                                <span className="dashboardEmptyTitle">Todavía no tenés viajes</span>
                                <span className="dashboardEmptyHint">
                                    Cuando se confirme tu primer viaje vas a verlo acá.
                                </span>
                            </div>
                        </div>
                    </div>
                </section>

                {isCarrier && (
                    <>
                        <section className="dashboardSection" aria-labelledby="section-availability">
                            <div className="dashboardSectionHeader">
                                <div className="dashboardSectionHeading">
                                    <span className="dashboardSectionIcon" aria-hidden="true"><IconCalendar /></span>
                                    <h2 id="section-availability">Mi disponibilidad</h2>
                                    <span className="dashboardSectionCount" aria-label={`${windowsTotal} ventanas`}>
                                        {windowsTotal}
                                    </span>
                                </div>
                                <Link to="/carrier/availability" className="button buttonGhost">
                                    Ver todas
                                </Link>
                            </div>
                            <div className="dashboardCardList">
                                {windows.length === 0 ? (
                                    <div className="dashboardEmpty" role="status">
                                        <span className="dashboardEmptyIcon" aria-hidden="true"><IconCalendar /></span>
                                        <div>
                                            <span className="dashboardEmptyTitle">Todavía no publicaste disponibilidad</span>
                                            <span className="dashboardEmptyHint">
                                                Sumá ventanas para que los expedidores te encuentren.
                                            </span>
                                        </div>
                                    </div>
                                ) : (
                                    windows.map(w => (
                                        <Link
                                            key={w.id}
                                            to={`/carrier/availability/${w.id}`}
                                            className="dashboardCard"
                                        >
                                            <div className="dashboardCardHead">
                                                <span className="dashboardCardEyebrow">{w.active ? "Publicada" : "Sin publicar"}</span>
                                            </div>
                                            <h3 className="dashboardCardTitle">
                                                {w.origin_zone} → {w.destination_zone}
                                                <IconArrowRight className="arrow" />
                                            </h3>
                                            <div className="dashboardCardMeta">
                                                <IconCalendar />
                                                <span>{formatDate(w.available_from)} – {formatDate(w.available_to)}</span>
                                            </div>
                                        </Link>
                                    ))
                                )}
                                <Link to="/carrier/availability/new" className="dashboardCard dashboardCardNew" aria-label="Nueva disponibilidad">
                                    <span className="dashboardCardNewIcon" aria-hidden="true"><IconPlus /></span>
                                    <span className="dashboardCardNewLabel">Nueva disponibilidad</span>
                                </Link>
                            </div>
                        </section>

                        <section className="dashboardSection" aria-labelledby="section-vehicles">
                            <div className="dashboardSectionHeader">
                                <div className="dashboardSectionHeading">
                                    <span className="dashboardSectionIcon" aria-hidden="true"><IconVehicle /></span>
                                    <h2 id="section-vehicles">Mi flota</h2>
                                    <span className="dashboardSectionCount" aria-label={`${vehicles.length} vehículos`}>
                                        {vehicles.length}
                                    </span>
                                </div>
                                <Link to="/carrier/vehicles" className="button buttonGhost">
                                    Ver todos
                                </Link>
                            </div>
                            <div className="dashboardCardList">
                                {vehicles.length === 0 ? (
                                    <div className="dashboardEmpty" role="status">
                                        <span className="dashboardEmptyIcon" aria-hidden="true"><IconVehicle /></span>
                                        <div>
                                            <span className="dashboardEmptyTitle">Aún no cargaste un vehículo</span>
                                            <span className="dashboardEmptyHint">
                                                Agregá tu primer vehículo para poder publicar viajes.
                                            </span>
                                        </div>
                                    </div>
                                ) : (
                                    vehicles.map(v => (
                                        <Link
                                            key={v.id}
                                            to={`/carrier/vehicle/${v.id}`}
                                            className="dashboardCard"
                                        >
                                            <div className="dashboardCardHead">
                                                <span className="dashboardCardEyebrow">Patente</span>
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
                                <Link to="/carrier/vehicle/new" className="dashboardCard dashboardCardNew" aria-label="Agregar vehículo">
                                    <span className="dashboardCardNewIcon" aria-hidden="true"><IconPlus /></span>
                                    <span className="dashboardCardNewLabel">Agregar vehículo</span>
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

function IconUser() {
    return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <circle cx="12" cy="8" r="3.5" />
            <path d="M5 20c1.5-3.5 4-5 7-5s5.5 1.5 7 5" />
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
