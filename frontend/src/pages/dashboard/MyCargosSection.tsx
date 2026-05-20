import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { listCargos } from "../../features/cargo/api";
import type { Cargo, CargoStatus } from "../../types/Cargo";
import { cargosContent } from "../../features/cargo/cargosContent";

const t = cargosContent.dashboardSection;

// Swimlane order + how many cards each lane previews on the dashboard.
const LANE_ORDER: CargoStatus[] = ["open", "accepted", "cancelled"];
const PER_LANE = 4;

function formatDate(iso: string): string {
    return new Date(iso).toLocaleDateString("es-AR", {
        day: "2-digit",
        month: "2-digit",
        year: "2-digit",
    });
}

// The "Abiertas" lane surfaces cargos with no pending offers first (plan §9
// D4). Array.prototype.sort is stable, so the backend's created_at-desc order
// is preserved within each group.
function laneItems(items: Cargo[], status: CargoStatus): Cargo[] {
    const lane = items.filter((c) => c.status === status);
    if (status !== "open") return lane;
    return [...lane].sort(
        (a, b) =>
            (a.pending_offers_count === 0 ? 0 : 1) -
            (b.pending_offers_count === 0 ? 0 : 1),
    );
}

type LoadState =
    | { status: "loading" }
    | { status: "ready"; items: Cargo[] }
    | { status: "error" };

/**
 * "Mis cargas" — the shipper dashboard's top section (plan §9 D4). Cargos are
 * grouped into labeled status swimlanes, each capped to a short preview with a
 * "Ver todas" link to the full `/shipper/cargos` list. Clicking an open cargo
 * opens its transport-window search; non-open cargos open their detail.
 */
export function MyCargosSection() {
    const [state, setState] = useState<LoadState>({ status: "loading" });

    const reload = useCallback(async () => {
        setState({ status: "loading" });
        try {
            const res = await listCargos();
            setState({ status: "ready", items: res.items });
        } catch {
            setState({ status: "error" });
        }
    }, []);

    useEffect(() => {
        reload();
    }, [reload]);

    const total = state.status === "ready" ? state.items.length : 0;

    return (
        <section className="dashboardSection" aria-labelledby="section-cargos">
            <div className="dashboardSectionHeader">
                <div className="dashboardSectionHeading">
                    <span className="dashboardSectionIcon" aria-hidden="true">
                        <IconBox />
                    </span>
                    <h2 id="section-cargos">{t.heading}</h2>
                    {state.status === "ready" && total > 0 && (
                        <span
                            className="dashboardSectionCount"
                            aria-label={t.countLabel(total)}
                        >
                            {total}
                        </span>
                    )}
                </div>
                <Link to="/shipper/cargos" className="button buttonGhost">
                    {t.viewAll}
                </Link>
            </div>

            {state.status === "loading" && (
                <div className="dashboardCardList" aria-busy="true">
                    {[0, 1, 2].map((i) => (
                        <div
                            key={i}
                            className="dashboardSkeleton dashboardSkeletonCard"
                        />
                    ))}
                </div>
            )}

            {state.status === "error" && (
                <div className="errorPanel" role="alert">
                    <p>{t.loadError}</p>
                    <button
                        type="button"
                        className="button buttonGhost"
                        onClick={reload}
                    >
                        {t.retry}
                    </button>
                </div>
            )}

            {state.status === "ready" && state.items.length === 0 && (
                <div className="dashboardEmpty" role="status">
                    <span className="dashboardEmptyIcon" aria-hidden="true">
                        <IconBox />
                    </span>
                    <div>
                        <span className="dashboardEmptyTitle">
                            {t.emptyTitle}
                        </span>
                        <span className="dashboardEmptyHint">{t.emptyHint}</span>
                    </div>
                    <Link
                        to="/shipper/cargos/new"
                        className="button buttonPrimary"
                    >
                        {t.publishCta}
                    </Link>
                </div>
            )}

            {state.status === "ready" && state.items.length > 0 && (
                <div className="cargoLanes">
                    {LANE_ORDER.map((status) => {
                        const lane = laneItems(state.items, status);
                        if (lane.length === 0) return null;
                        return (
                            <div className="cargoLane" key={status}>
                                <h3 className="cargoLaneTitle">
                                    {t.laneCount(t.lanes[status], lane.length)}
                                </h3>
                                <ul className="cargoMiniGrid">
                                    {lane.slice(0, PER_LANE).map((c) => (
                                        <CargoMiniCard key={c.id} cargo={c} />
                                    ))}
                                </ul>
                            </div>
                        );
                    })}
                </div>
            )}
        </section>
    );
}

function CargoMiniCard({ cargo }: { cargo: Cargo }) {
    const route = cargosContent.list.route(
        cargo.pickup_zone,
        cargo.delivery_zone,
    );
    const isOpen = cargo.status === "open";
    // Open cargo → transport-window search; non-open → detail (plan §9 D3).
    const primaryTo = isOpen
        ? `/shipper/cargos/${cargo.id}/matches`
        : `/shipper/cargos/${cargo.id}`;

    return (
        <li className="cargoMiniCard">
            <div className="cargoMiniCardHead">
                <span
                    className={`statusBadge ${
                        cargosContent.statusBadgeClass[cargo.status] ??
                        "pendiente"
                    }`}
                >
                    {cargosContent.statusLabel[cargo.status] ?? cargo.status}
                </span>
                <span className="cargoMiniCardOffers">
                    {cargo.pending_offers_count > 0
                        ? cargosContent.list.offersCount(
                            cargo.pending_offers_count,
                        )
                        : cargosContent.list.noOffers}
                </span>
            </div>
            <h4 className="cargoMiniCardTitle">
                <Link
                    className="cargoMiniCardLink"
                    to={primaryTo}
                    aria-label={
                        isOpen
                            ? t.openCardAria(route)
                            : t.detailCardAria(route)
                    }
                >
                    {route}
                </Link>
            </h4>
            <p className="cargoMiniCardDesc">{cargo.cargo_description}</p>
            <p className="cargoMiniCardMeta">
                {cargosContent.list.pickupWindow(
                    formatDate(cargo.pickup_window_start),
                    formatDate(cargo.pickup_window_end),
                )}
            </p>
            <Link
                to={`/shipper/cargos/${cargo.id}`}
                className="button buttonGhost cargoMiniCardDetail"
            >
                {t.viewDetail}
            </Link>
        </li>
    );
}

function IconBox() {
    return (
        <svg
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
        >
            <path d="M21 8l-9-5-9 5 9 5 9-5z" />
            <path d="M3 8v8l9 5 9-5V8" />
            <path d="M12 13v8" />
        </svg>
    );
}
