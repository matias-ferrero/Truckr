import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { listCargos, type CargoListMeta } from "./api";
import type { Cargo, CargoStatus } from "../../types/Cargo";
import { cargosContent } from "./cargosContent";
import { formatRoute } from "../../lib/format-place";

const t = cargosContent.list;

const STATUS_FILTERS: { value: "" | CargoStatus; label: string }[] = [
    { value: "", label: t.filterAll },
    { value: "open", label: cargosContent.statusLabel.open },
    { value: "accepted", label: cargosContent.statusLabel.accepted },
    { value: "cancelled", label: cargosContent.statusLabel.cancelled },
];

function formatDate(iso: string): string {
    return new Date(iso).toLocaleDateString("es-AR", {
        day: "2-digit",
        month: "2-digit",
        year: "2-digit",
    });
}

type LoadState =
    | { status: "loading" }
    | { status: "ready"; items: Cargo[]; meta: CargoListMeta }
    | { status: "error"; message: string };

export default function CargoList() {
    const [filter, setFilter] = useState<"" | CargoStatus>("");
    const [page, setPage] = useState(1);
    const [state, setState] = useState<LoadState>({ status: "loading" });

    const reload = useCallback(async () => {
        setState({ status: "loading" });
        try {
            const res = await listCargos(filter || undefined, page);
            setState({ status: "ready", items: res.items, meta: res.meta });
        } catch (e) {
            setState({ status: "error", message: (e as Error).message });
        }
    }, [filter, page]);

    useEffect(() => {
        reload();
    }, [reload]);

    return (
        <main className="page" id="main">
            <div className="container">
                <header className="listHeader">
                    <div>
                        <h1 className="sectionTitle">{t.title}</h1>
                        <p className="sectionLead">{t.lead}</p>
                    </div>
                    <Link to="/shipper/cargos/new" className="button buttonPrimary">
                        {t.publishCta}
                    </Link>
                </header>

                <div className="filterBar">
                    <label className="filterLabel" htmlFor="cargo-status-filter">
                        {t.filterLabel}
                    </label>
                    <select
                        id="cargo-status-filter"
                        className="filterSelect"
                        value={filter}
                        onChange={(e) => {
                            setFilter(e.target.value as "" | CargoStatus);
                            setPage(1);
                        }}
                    >
                        {STATUS_FILTERS.map((f) => (
                            <option key={f.value || "all"} value={f.value}>
                                {f.label}
                            </option>
                        ))}
                    </select>
                </div>

                {state.status === "loading" && (
                    <ul
                        className="cargoGrid skeleton"
                        aria-busy="true"
                        aria-label={t.loadingLabel}
                    >
                        {[0, 1, 2].map((i) => (
                            <li key={i} className="cargoCard skeletonCard" />
                        ))}
                    </ul>
                )}

                {state.status === "error" && (
                    <div className="errorPanel" role="alert">
                        <p>
                            {t.loadError}: {state.message}
                        </p>
                        <button
                            className="button buttonGhost"
                            type="button"
                            onClick={reload}
                        >
                            {t.retry}
                        </button>
                    </div>
                )}

                {state.status === "ready" && state.items.length === 0 && (
                    <div className="emptyState">
                        <h2 className="emptyStateTitle">{t.emptyTitle}</h2>
                        <p className="sectionLead">{t.emptyLead}</p>
                        <Link
                            to="/shipper/cargos/new"
                            className="button buttonPrimary"
                        >
                            {t.emptyCta}
                        </Link>
                    </div>
                )}

                {state.status === "ready" && state.items.length > 0 && (
                    <>
                        <ul className="cargoGrid" aria-label={t.gridLabel}>
                            {state.items.map((c) => (
                                <li key={c.id} className="cargoCard">
                                    <div className="cargoCardHeader">
                                        <span
                                            className="cargoRoute"
                                            title={formatRoute(
                                                { locality: c.pickup_locality, admin_area: c.pickup_admin_area },
                                                { locality: c.delivery_locality, admin_area: c.delivery_admin_area },
                                                t.openDestinationLabel,
                                            )}
                                        >
                                            {formatRoute(
                                                { locality: c.pickup_locality, admin_area: c.pickup_admin_area },
                                                { locality: c.delivery_locality, admin_area: c.delivery_admin_area },
                                                t.openDestinationLabel,
                                            )}
                                        </span>
                                        <span
                                            className={`statusBadge ${
                                                cargosContent.statusBadgeClass[
                                                    c.status
                                                ] ?? "pendiente"
                                            }`}
                                        >
                                            {cargosContent.statusLabel[c.status] ??
                                                c.status}
                                        </span>
                                    </div>
                                    <p className="cargoCardDescription">
                                        {c.cargo_description}
                                    </p>
                                    <p className="cargoCardMeta">
                                        {t.pickupWindow(
                                            formatDate(c.pickup_window_start),
                                            formatDate(c.pickup_window_end),
                                        )}
                                    </p>
                                    <p className="cargoCardOffers">
                                        {c.pending_offers_count > 0
                                            ? t.offersCount(c.pending_offers_count)
                                            : t.noOffers}
                                    </p>
                                    <div className="cardActions">
                                        <Link
                                            to={`/shipper/cargos/${c.id}`}
                                            className="button buttonGhost"
                                        >
                                            {t.viewDetail}
                                        </Link>
                                    </div>
                                </li>
                            ))}
                        </ul>
                        {state.meta.totalPages > 1 && (
                            <nav
                                className="paginator"
                                aria-label={t.pagination.label}
                            >
                                <button
                                    type="button"
                                    className="button buttonGhost"
                                    disabled={page <= 1}
                                    onClick={() =>
                                        setPage((p) => Math.max(1, p - 1))}
                                >
                                    {t.pagination.previous}
                                </button>
                                <p>
                                    {t.pagination.page(
                                        state.meta.page,
                                        state.meta.totalPages,
                                    )}
                                    {" · "}
                                    {t.pagination.count(state.meta.total)}
                                </p>
                                <button
                                    type="button"
                                    className="button buttonGhost"
                                    disabled={page >= state.meta.totalPages}
                                    onClick={() => setPage((p) => p + 1)}
                                >
                                    {t.pagination.next}
                                </button>
                            </nav>
                        )}
                    </>
                )}
            </div>
        </main>
    );
}
