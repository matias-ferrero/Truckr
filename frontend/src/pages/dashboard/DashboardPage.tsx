import { useEffect, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { useCurrentUser } from "../../auth/useCurrentUser";
import { listMyVehicles, Vehicle } from "../../api/vehicles";
import "../../styles/dashboard.css";

type TripStatus = "PENDIENTE" | "ACEPTADO" | "PASADO";
type TripFilter = "TODOS" | TripStatus;

const TRIP_FILTERS: { value: TripFilter; label: string }[] = [
    { value: "TODOS", label: "Todos" },
    { value: "ACEPTADO", label: "Aceptados" },
    { value: "PENDIENTE", label: "Pendientes" },
    { value: "PASADO", label: "Pasados" },
];

export function DashboardPage() {
    const { me, loading } = useCurrentUser();
    const [vehicles, setVehicles] = useState<Vehicle[]>([]);
    const [activeFilter, setActiveFilter] = useState<TripFilter>("TODOS");

    const [availabilities] = useState([
        { id: 1, date: "Hoy", time: "14:00 - 18:00", route: "Centro → Pilar" },
        { id: 2, date: "Mañana", time: "09:00 - 13:00", route: "San Isidro → CABA" },
    ]);
    const [trips] = useState<{
        id: number;
        date: string;
        status: TripStatus;
        route: string;
        price: string;
    }[]>([
        { id: 1, date: "20/05", status: "PENDIENTE", route: "Tigre → Belgrano", price: "$ 50.000" },
    ]);

    const isCarrier = me?.roles.includes("carrier");

    useEffect(() => {
        if (isCarrier) {
            listMyVehicles().then(res => setVehicles(res.items)).catch(console.error);
        }
    }, [isCarrier]);

    const visibleTrips = useMemo(
        () => (activeFilter === "TODOS" ? trips : trips.filter(t => t.status === activeFilter)),
        [trips, activeFilter],
    );

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

                <section className="dashboardSection" aria-labelledby="section-trips">
                    <div className="dashboardSectionHeader">
                        <div className="dashboardSectionHeading">
                            <span className="dashboardSectionIcon" aria-hidden="true"><IconTruck /></span>
                            <h2 id="section-trips">Mis viajes</h2>
                            <span className="dashboardSectionCount" aria-label={`${visibleTrips.length} viajes`}>
                                {visibleTrips.length}
                            </span>
                        </div>
                        <div className="dashboardFilters" role="group" aria-label="Filtrar viajes">
                            {TRIP_FILTERS.map(f => (
                                <button
                                    key={f.value}
                                    type="button"
                                    aria-pressed={activeFilter === f.value}
                                    onClick={() => setActiveFilter(f.value)}
                                >
                                    {f.label}
                                </button>
                            ))}
                        </div>
                    </div>
                    <div className="dashboardCardList">
                        {visibleTrips.length === 0 ? (
                            <div className="dashboardEmpty" role="status">
                                <span className="dashboardEmptyIcon" aria-hidden="true"><IconRoute /></span>
                                <div>
                                    <span className="dashboardEmptyTitle">Sin viajes para mostrar</span>
                                    <span className="dashboardEmptyHint">
                                        Probá con otro filtro o publicá tu primer viaje.
                                    </span>
                                </div>
                            </div>
                        ) : (
                            visibleTrips.map(t => (
                                <article key={t.id} className="dashboardCard">
                                    <div className="dashboardCardHead">
                                        <span className="dashboardCardEyebrow">Viaje #{t.id}</span>
                                        <span className="dashboardCardPrice">{t.price}</span>
                                    </div>
                                    <h3 className="dashboardCardTitle">{t.route}</h3>
                                    <div className="dashboardCardMeta">
                                        <IconCalendar />
                                        <span>{t.date}</span>
                                    </div>
                                    <div className="dashboardCardFoot">
                                        <StatusBadge status={t.status} />
                                    </div>
                                </article>
                            ))
                        )}
                        <Link to="/trips/new" className="dashboardCard dashboardCardNew" aria-label="Nuevo viaje">
                            <span className="dashboardCardNewIcon" aria-hidden="true"><IconPlus /></span>
                            <span className="dashboardCardNewLabel">Nuevo viaje</span>
                        </Link>
                    </div>
                </section>

                {isCarrier && (
                    <>
                        <section className="dashboardSection" aria-labelledby="section-availability">
                            <div className="dashboardSectionHeader">
                                <div className="dashboardSectionHeading">
                                    <span className="dashboardSectionIcon" aria-hidden="true"><IconCalendar /></span>
                                    <h2 id="section-availability">Mi disponibilidad</h2>
                                    <span className="dashboardSectionCount" aria-label={`${availabilities.length} ventanas`}>
                                        {availabilities.length}
                                    </span>
                                </div>
                            </div>
                            <div className="dashboardCardList">
                                {availabilities.length === 0 ? (
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
                                    availabilities.map(a => (
                                        <article key={a.id} className="dashboardCard">
                                            <div className="dashboardCardHead">
                                                <span className="dashboardCardEyebrow">{a.date}</span>
                                            </div>
                                            <h3 className="dashboardCardTitle">
                                                <IconClock />
                                                {a.time}
                                            </h3>
                                            <div className="dashboardCardMeta">
                                                <IconMapPin />
                                                <span>{a.route}</span>
                                            </div>
                                        </article>
                                    ))
                                )}
                                <Link to="/availability/new" className="dashboardCard dashboardCardNew" aria-label="Nueva disponibilidad">
                                    <span className="dashboardCardNewIcon" aria-hidden="true"><IconPlus /></span>
                                    <span className="dashboardCardNewLabel">Nueva disponibilidad</span>
                                </Link>
                            </div>
                        </section>

                        <section className="dashboardSection" aria-labelledby="section-vehicles">
                            <div className="dashboardSectionHeader">
                                <div className="dashboardSectionHeading">
                                    <span className="dashboardSectionIcon" aria-hidden="true"><IconVehicle /></span>
                                    <h2 id="section-vehicles">Mis vehículos</h2>
                                    <span className="dashboardSectionCount" aria-label={`${vehicles.length} vehículos`}>
                                        {vehicles.length}
                                    </span>
                                </div>
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
                                <Link to="/carrier/vehicle/new" className="dashboardCard dashboardCardNew" aria-label="Nuevo vehículo">
                                    <span className="dashboardCardNewIcon" aria-hidden="true"><IconPlus /></span>
                                    <span className="dashboardCardNewLabel">Nuevo vehículo</span>
                                </Link>
                            </div>
                        </section>
                    </>
                )}
            </div>
        </main>
    );
}

/* ---- Status badge --------------------------------------------------- */

function StatusBadge({ status }: { status: TripStatus }) {
    const className = `statusBadge ${status.toLowerCase()}`;
    const label = status.charAt(0) + status.slice(1).toLowerCase();
    const icon = status === "ACEPTADO"
        ? <IconCheck />
        : status === "PENDIENTE"
            ? <IconClock />
            : <IconCheck />;
    return (
        <span className={className}>
            {icon}
            {label}
        </span>
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

function IconClock() {
    return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <circle cx="12" cy="12" r="9" />
            <path d="M12 7v5l3 2" />
        </svg>
    );
}

function IconCheck() {
    return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="M5 12l4.5 4.5L19 7" />
        </svg>
    );
}

function IconMapPin() {
    return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="M12 22s7-7.5 7-13a7 7 0 1 0-14 0c0 5.5 7 13 7 13z" />
            <circle cx="12" cy="9" r="2.25" />
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
