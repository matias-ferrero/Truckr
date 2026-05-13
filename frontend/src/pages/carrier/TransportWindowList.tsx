import { useCallback, useEffect, useRef, useState } from "react";
import { Link } from "react-router-dom";
import {
    deactivateTransportWindow,
    deleteTransportWindow,
    listMyTransportWindows,
    TransportWindow,
    TransportWindowListMeta,
    updateTransportWindow,
} from "../../api/transport_windows";
import { carrierContent } from "./carrierContent";

const t = carrierContent.availability.list;

type LoadState =
    | { status: "loading" }
    | { status: "ready"; items: TransportWindow[]; meta: TransportWindowListMeta }
    | { status: "error"; message: string };

function formatDate(iso: string) {
    return new Date(iso).toLocaleDateString("es-AR", {
        day: "2-digit",
        month: "2-digit",
        year: "2-digit",
    });
}

export default function TransportWindowList() {
    const [page, setPage]         = useState(1);
    const [state, setState]       = useState<LoadState>({ status: "loading" });
    const [toggling, setToggling] = useState<number | null>(null);
    const [confirmDelete, setConfirmDelete] = useState<number | null>(null);
    const [deleting, setDeleting] = useState<number | null>(null);
    const dialogRef = useRef<HTMLDialogElement>(null);

    useEffect(() => {
        const dialog = dialogRef.current;
        if (!dialog) return;
        if (confirmDelete !== null) {
            dialog.showModal();
        } else if (dialog.open) {
            dialog.close();
        }
    }, [confirmDelete]);

    const reload = useCallback(async (nextPage = page) => {
        setState({ status: "loading" });
        try {
            const res = await listMyTransportWindows(nextPage);
            setState({ status: "ready", items: res.items, meta: res.meta });
        } catch (e) {
            setState({ status: "error", message: (e as Error).message });
        }
    }, [page]);

    useEffect(() => {
        reload(page);
    }, [reload, page]);

    async function handleToggleActive(tw: TransportWindow) {
        setToggling(tw.id);
        try {
            if (tw.active) {
                await deactivateTransportWindow(tw.id);
            } else {
                await updateTransportWindow(tw.id, { active: true });
            }
            await reload(page);
        } finally {
            setToggling(null);
        }
    }

    async function handleDelete(id: number) {
        setConfirmDelete(null);
        setDeleting(id);
        try {
            await deleteTransportWindow(id);
            await reload(page);
        } finally {
            setDeleting(null);
        }
    }

    return (
        <main className="page carrierMain" id="main">
            <div className="container">
                <header className="listHeader">
                    <div>
                        <h1 className="sectionTitle">{t.title}</h1>
                        <p className="sectionLead">{t.lead}</p>
                    </div>
                    <Link to="/carrier/availability/new" className="button buttonPrimary">
                        {t.addCta}
                    </Link>
                </header>

                {state.status === "loading" && (
                    <ul
                        className="windowGrid skeleton"
                        aria-busy="true"
                        aria-label={t.loadingLabel}
                    >
                        {[0, 1, 2].map((i) => (
                            <li key={i} className="windowCard skeletonCard" />
                        ))}
                    </ul>
                )}

                {state.status === "error" && (
                    <div className="errorPanel" role="alert">
                        <p>{t.loadError}: {state.message}</p>
                        <button
                            className="button buttonGhost"
                            onClick={() => reload(page)}
                            type="button"
                        >
                            {t.retry}
                        </button>
                    </div>
                )}

                {state.status === "ready" && state.items.length === 0 && (
                    <div className="emptyState">
                        <h2 className="emptyStateTitle">{t.emptyTitle}</h2>
                        <p className="sectionLead">{t.emptyLead}</p>
                        <Link to="/carrier/availability/new" className="button buttonPrimary">
                            {t.emptyCta}
                        </Link>
                    </div>
                )}

                {state.status === "ready" && state.items.length > 0 && (
                    <>
                        <ul className="windowGrid" aria-label={t.gridLabel}>
                            {state.items.map((tw) => (
                                <li key={tw.id} className={`windowCard${tw.active ? "" : " isInactive"}`}>
                                    <div className="windowCardHeader">
                                        <span
                                            className="windowRoute"
                                            title={`${tw.origin_zone} → ${tw.destination_zone}`}
                                        >
                                            {tw.origin_zone} → {tw.destination_zone}
                                        </span>
                                        <span className={`statusBadge${tw.active ? " statusActive" : " statusInactive"}`}>
                                            {tw.active ? t.active : t.inactive}
                                        </span>
                                    </div>
                                    <div className="windowCardBody">
                                        <p className="windowMeta">
                                            <span>{tw.vehicle.make} {tw.vehicle.model} · <strong>{tw.vehicle.plate}</strong></span>
                                        </p>
                                        <p className="windowMeta">
                                            <span>{t.pricePerKm}: <strong>${tw.price_per_km}</strong></span>
                                            {" · "}
                                            <span>{t.maxKm}: <strong>{tw.max_km}</strong></span>
                                        </p>
                                        <p className="windowMeta">
                                            {t.from} {formatDate(tw.available_from)} — {t.to} {formatDate(tw.available_to)}
                                        </p>
                                    </div>
                                    <div className="cardActions">
                                        <Link
                                            to={`/carrier/availability/${tw.id}`}
                                            className="button buttonGhost"
                                        >
                                            {t.edit}
                                        </Link>
                                        <button
                                            className={`button ${tw.active ? "buttonDanger" : "buttonGhost"}`}
                                            type="button"
                                            aria-label={tw.active
                                                ? `${t.deactivate}: ${tw.origin_zone} → ${tw.destination_zone}`
                                                : `${t.reactivate}: ${tw.origin_zone} → ${tw.destination_zone}`}
                                            onClick={() => handleToggleActive(tw)}
                                            disabled={toggling === tw.id || deleting === tw.id}
                                        >
                                            {toggling === tw.id
                                                ? t.toggling
                                                : tw.active ? t.deactivate : t.reactivate}
                                        </button>
                                        <button
                                            className="button buttonDanger"
                                            type="button"
                                            onClick={() => setConfirmDelete(tw.id)}
                                            disabled={deleting === tw.id}
                                        >
                                            {deleting === tw.id ? t.deleting : t.delete}
                                        </button>
                                    </div>
                                </li>
                            ))}
                        </ul>
                        {state.meta.totalPages > 1 && (
                            <nav className="paginator" aria-label={t.pagination.label}>
                                <button
                                    type="button"
                                    className="button buttonGhost"
                                    disabled={page <= 1}
                                    onClick={() => setPage((p) => Math.max(1, p - 1))}
                                >
                                    {t.pagination.previous}
                                </button>
                                <p>
                                    {t.pagination.page(state.meta.page, state.meta.totalPages)}
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

            <dialog
                ref={dialogRef}
                className="confirmDialog"
                onClose={() => setConfirmDelete(null)}
                aria-labelledby="confirm-delete-title"
            >
                <div className="confirmDialogBody">
                    <h2 id="confirm-delete-title" className="confirmDialogTitle">
                        {t.deleteTitle}
                    </h2>
                    <p className="confirmDialogText">{t.deleteConfirm}</p>
                    <div className="confirmDialogActions">
                        <button
                            className="button buttonGhost"
                            type="button"
                            onClick={() => setConfirmDelete(null)}
                        >
                            {t.deleteCancel}
                        </button>
                        <button
                            className="button buttonDanger"
                            type="button"
                            onClick={() => { if (confirmDelete !== null) handleDelete(confirmDelete); }}
                            disabled={deleting === confirmDelete}
                        >
                            {deleting === confirmDelete ? t.deleting : t.delete}
                        </button>
                    </div>
                </div>
            </dialog>
        </main>
    );
}
