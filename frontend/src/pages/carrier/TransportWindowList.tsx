import { useCallback, useEffect, useRef, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import {
    deactivateTransportWindow,
    deleteTransportWindow,
    listMyTransportWindows,
    TransportWindow,
    TransportWindowListMeta,
    updateTransportWindow,
} from "../../api/transport_windows";
import { Button, buttonVariants } from "../../components/ui/button";
import { cn } from "../../lib/utils";
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
        year: "numeric",
    });
}

export default function TransportWindowList() {
    const location = useLocation();
    const navigate = useNavigate();

    const [page, setPage]         = useState(1);
    const [state, setState]       = useState<LoadState>({ status: "loading" });
    const [toggling, setToggling] = useState<number | null>(null);
    const [toggleMsg, setToggleMsg] = useState<string | null>(null);
    const toggleTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
    const [confirmDelete, setConfirmDelete] = useState<TransportWindow | null>(null);
    const [deleting, setDeleting] = useState<number | null>(null);
    const dialogRef = useRef<HTMLDialogElement>(null);

    const justSaved = !!(location.state as { justSaved?: boolean } | null)?.justSaved;
    const [showSaved, setShowSaved] = useState(false);

    useEffect(() => {
        if (!justSaved) return;
        setShowSaved(true);
        navigate(location.pathname, { replace: true, state: null });
        const id = setTimeout(() => setShowSaved(false), 4000);
        return () => clearTimeout(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [justSaved]);

    useEffect(() => () => {
        if (toggleTimerRef.current) clearTimeout(toggleTimerRef.current);
    }, []);

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
                setToggleMsg(t.toggledHidden);
            } else {
                await updateTransportWindow(tw.id, { active: true });
                setToggleMsg(t.toggledVisible);
            }
            await reload(page);
            if (toggleTimerRef.current) clearTimeout(toggleTimerRef.current);
            toggleTimerRef.current = setTimeout(() => setToggleMsg(null), 3500);
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

    const confirmId = confirmDelete?.id ?? null;
    const deleteTriggerRef = useRef<HTMLButtonElement | null>(null);

    return (
        <main className="page carrierMain" id="main">
            <div className="container">
                {showSaved && (
                    <div className="savedBanner" role="status" aria-live="polite">
                        <span>{t.savedBanner}</span>
                        <button
                            className="savedBannerClose"
                            aria-label={t.savedBannerDismiss}
                            onClick={() => setShowSaved(false)}
                        >
                            ×
                        </button>
                    </div>
                )}
                {toggleMsg && (
                    <div className="savedBanner" role="status" aria-live="polite">
                        <span>{toggleMsg}</span>
                        <button
                            className="savedBannerClose"
                            aria-label={t.savedBannerDismiss}
                            onClick={() => setToggleMsg(null)}
                        >
                            ×
                        </button>
                    </div>
                )}
                <header className="listHeader">
                    <div>
                        <h1 className="sectionTitle">{t.title}</h1>
                        <p className="sectionLead">{t.lead}</p>
                    </div>
                    {!(state.status === "ready" && state.items.length === 0) && (
                        <Link to="/carrier/availability/new" className={buttonVariants()}>
                            {t.addCta}
                        </Link>
                    )}
                </header>

                {state.status === "loading" && (
                    <ul
                        className="windowGrid skeleton"
                        aria-busy="true"
                        aria-label={t.loadingLabel}
                    >
                        {[0, 1, 2].map((i) => (
                            <li key={i} className="windowCard skeletonCard" aria-hidden="true" />
                        ))}
                    </ul>
                )}

                {state.status === "error" && (
                    <div className="errorPanel" role="alert">
                        <p>{t.loadError}: {state.message}</p>
                        <Button variant="ghost" onClick={() => reload(page)}>
                            {t.retry}
                        </Button>
                    </div>
                )}

                {state.status === "ready" && state.items.length === 0 && (
                    <div className="emptyState">
                        <h2 className="emptyStateTitle">{t.emptyTitle}</h2>
                        <p className="sectionLead">{t.emptyLead}</p>
                        <Link to="/carrier/availability/new" className={buttonVariants()}>
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
                                        <span
                                            className={`statusBadge${tw.active ? " statusActive" : " statusInactive"}`}
                                            title={tw.active ? t.activeTitle : t.inactiveTitle}
                                            aria-label={tw.active ? t.activeTitle : t.inactiveTitle}
                                        >
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
                                    {/* Action hierarchy: Edit leads (outline, full width) →
                                        Toggle is secondary (ghost sm) →
                                        Delete is danger-colored ghost (weight reserved for confirm dialog) */}
                                    <div className="cardActions">
                                        <Link
                                            to={`/carrier/availability/${tw.id}`}
                                            className={cn(buttonVariants({ variant: "outline", size: "sm" }), "cardEditBtn")}
                                        >
                                            {t.edit}
                                        </Link>
                                        <div className="cardSecondaryActions">
                                            <Button
                                                variant="ghost"
                                                size="sm"
                                                aria-label={tw.active
                                                    ? `${t.deactivate}: ${tw.origin_zone} → ${tw.destination_zone}`
                                                    : `${t.reactivate}: ${tw.origin_zone} → ${tw.destination_zone}`}
                                                onClick={() => handleToggleActive(tw)}
                                                disabled={toggling === tw.id || deleting === tw.id}
                                            >
                                                {toggling === tw.id
                                                    ? t.toggling
                                                    : tw.active ? t.deactivate : t.reactivate}
                                            </Button>
                                            <Button
                                                variant="ghost"
                                                size="sm"
                                                className="cardDeleteBtn"
                                                onClick={(e) => {
                                                    deleteTriggerRef.current = e.currentTarget as HTMLButtonElement;
                                                    setConfirmDelete(tw);
                                                }}
                                                disabled={deleting === tw.id}
                                            >
                                                {deleting === tw.id ? t.deleting : t.delete}
                                            </Button>
                                        </div>
                                    </div>
                                </li>
                            ))}
                        </ul>
                        {state.meta.totalPages > 1 && (
                            <nav className="paginator" aria-label={t.pagination.label}>
                                <Button
                                    variant="ghost"
                                    size="sm"
                                    disabled={page <= 1}
                                    onClick={() => setPage((p) => Math.max(1, p - 1))}
                                >
                                    <span aria-hidden="true">← </span>{t.pagination.previous}
                                </Button>
                                <p>
                                    {t.pagination.page(state.meta.page, state.meta.totalPages)}
                                    {" · "}
                                    {t.pagination.count(state.meta.total)}
                                </p>
                                <Button
                                    variant="ghost"
                                    size="sm"
                                    disabled={page >= state.meta.totalPages}
                                    onClick={() => setPage((p) => p + 1)}
                                >
                                    {t.pagination.next}<span aria-hidden="true"> →</span>
                                </Button>
                            </nav>
                        )}
                    </>
                )}
            </div>

            <dialog
                ref={dialogRef}
                className="confirmDialog"
                aria-modal="true"
                onClose={() => {
                    setConfirmDelete(null);
                    deleteTriggerRef.current?.focus();
                }}
                aria-labelledby="confirm-delete-title"
            >
                <div className="confirmDialogBody">
                    <h2 id="confirm-delete-title" className="confirmDialogTitle">
                        {t.deleteTitle}
                    </h2>
                    {confirmDelete && (
                        <p className="confirmDialogRoute">
                            {confirmDelete.origin_zone} → {confirmDelete.destination_zone}
                        </p>
                    )}
                    <p className="confirmDialogText">{t.deleteConfirm}</p>
                    <div className="confirmDialogActions">
                        <Button variant="ghost" onClick={() => setConfirmDelete(null)}>
                            {t.deleteCancel}
                        </Button>
                        <Button
                            variant="danger"
                            onClick={() => { if (confirmId !== null) handleDelete(confirmId); }}
                            disabled={deleting === confirmId}
                        >
                            {deleting === confirmId ? t.deleting : t.delete}
                        </Button>
                    </div>
                </div>
            </dialog>
        </main>
    );
}
