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
import { formatRoute } from "../../lib/format-place";

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

function fmtPrice(p: string): string {
    return Number(p).toLocaleString("es-AR", { minimumFractionDigits: 0, maximumFractionDigits: 2 });
}

function fmtRoute(tw: {
    origin_locality: string;
    origin_admin_area: string;
    destination_locality: string | null;
    destination_admin_area: string | null;
    destination_lat: string | number | null;
}): string {
    const hasDestination = tw.destination_lat !== null;
    return formatRoute(
        { locality: tw.origin_locality, admin_area: tw.origin_admin_area },
        hasDestination
            ? { locality: tw.destination_locality, admin_area: tw.destination_admin_area }
            : null,
        t.destinationAny,
    );
}

export default function TransportWindowList() {
    const location = useLocation();
    const navigate = useNavigate();

    const [page, setPage]         = useState(1);
    const [state, setState]       = useState<LoadState>({ status: "loading" });
    const [toggling, setToggling] = useState<number | null>(null);
    const [toggleMsg, setToggleMsg] = useState<string | null>(null);
    const [recentlyDeactivatedId, setRecentlyDeactivatedId] = useState<number | null>(null);
    const toggleTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
    const [confirmDelete, setConfirmDelete] = useState<TransportWindow | null>(null);
    const [blockedDelete, setBlockedDelete] = useState<TransportWindow | null>(null);
    const blockDialogRef = useRef<HTMLDialogElement>(null);
    const [pendingDeleteItem, setPendingDeleteItem] = useState<TransportWindow | null>(null);
    const pendingDeleteTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
    const [deleteError, setDeleteError] = useState<string | null>(null);
    const deleteErrorTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
    const dialogRef = useRef<HTMLDialogElement>(null);

    const locationState  = location.state as { justSaved?: boolean; isNew?: boolean } | null;
    const justSaved      = !!locationState?.justSaved;
    const justSavedIsNew = !!locationState?.isNew;
    const [showSaved, setShowSaved] = useState(false);
    const [savedIsNew, setSavedIsNew] = useState(false);

    useEffect(() => {
        if (!justSaved) return;
        setShowSaved(true);
        setSavedIsNew(justSavedIsNew);
        navigate(location.pathname, { replace: true, state: null });
        const id = setTimeout(() => setShowSaved(false), 4000);
        return () => clearTimeout(id);
    // eslint-disable-next-line react-hooks/exhaustive-deps
    }, [justSaved]);

    useEffect(() => () => {
        if (toggleTimerRef.current) clearTimeout(toggleTimerRef.current);
        if (pendingDeleteTimerRef.current) clearTimeout(pendingDeleteTimerRef.current);
        if (deleteErrorTimerRef.current) clearTimeout(deleteErrorTimerRef.current);
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

    useEffect(() => {
        const dialog = blockDialogRef.current;
        if (!dialog) return;
        if (blockedDelete !== null) {
            dialog.showModal();
        } else if (dialog.open) {
            dialog.close();
        }
    }, [blockedDelete]);

    // Keyboard shortcut: n → new window (when no input is focused)
    useEffect(() => {
        function onKeyDown(e: KeyboardEvent) {
            if (e.key !== "n" || e.ctrlKey || e.metaKey || e.altKey) return;
            const tag = (document.activeElement as HTMLElement | null)?.tagName ?? "";
            if (tag === "INPUT" || tag === "TEXTAREA" || tag === "SELECT") return;
            navigate("/carrier/availability/new");
        }
        document.addEventListener("keydown", onKeyDown);
        return () => document.removeEventListener("keydown", onKeyDown);
    }, [navigate]);

    const reload = useCallback(async (nextPage = page) => {
        setState({ status: "loading" });
        try {
            const res = await listMyTransportWindows(nextPage);
            setState({ status: "ready", items: res.items, meta: res.meta });
        } catch (e) {
            const msg = (e as Error).message;
            console.error("TransportWindowList load error:", msg);
            setState({ status: "error", message: msg });
        }
    }, [page]);

    useEffect(() => {
        reload(page);
    }, [reload, page]);

    async function handleToggleActive(tw: TransportWindow) {
        setToggling(tw.id);
        try {
            let updated: TransportWindow;
            if (tw.active) {
                updated = await deactivateTransportWindow(tw.id);
                setRecentlyDeactivatedId(tw.id);
                setToggleMsg(t.toggledHidden);
            } else {
                setRecentlyDeactivatedId(null);
                updated = await updateTransportWindow(tw.id, { active: true });
                setToggleMsg(t.toggledVisible);
            }
            setState(prev =>
                prev.status === "ready"
                    ? { ...prev, items: prev.items.map(i => i.id === tw.id ? updated : i) }
                    : prev
            );
            if (toggleTimerRef.current) clearTimeout(toggleTimerRef.current);
            toggleTimerRef.current = setTimeout(() => {
                setToggleMsg(null);
                setRecentlyDeactivatedId(null);
            }, 5000);
        } finally {
            setToggling(null);
        }
    }

    async function handleUndoDeactivate() {
        const id = recentlyDeactivatedId;
        if (id === null) return;
        if (toggleTimerRef.current) clearTimeout(toggleTimerRef.current);
        setRecentlyDeactivatedId(null);
        setToggleMsg(null);
        setToggling(id);
        try {
            const updated = await updateTransportWindow(id, { active: true });
            setState(prev =>
                prev.status === "ready"
                    ? { ...prev, items: prev.items.map(i => i.id === id ? updated : i) }
                    : prev
            );
            setToggleMsg(t.toggledVisible);
            toggleTimerRef.current = setTimeout(() => setToggleMsg(null), 5000);
        } finally {
            setToggling(null);
        }
    }

    function handleDeleteOptimistic(tw: TransportWindow) {
        setConfirmDelete(null);
        setState(prev =>
            prev.status === "ready"
                ? { ...prev, items: prev.items.filter(i => i.id !== tw.id) }
                : prev
        );
        setPendingDeleteItem(tw);
        if (pendingDeleteTimerRef.current) clearTimeout(pendingDeleteTimerRef.current);
        pendingDeleteTimerRef.current = setTimeout(async () => {
            try {
                await deleteTransportWindow(tw.id);
            } catch (e: unknown) {
                const err = e as { body?: { error?: { details?: { base?: string[] } } }; status?: number };
                const isConstraint = err?.status === 422 && !!err?.body?.error?.details?.base?.length;
                setDeleteError(isConstraint ? t.deleteBlocked : t.deleteFailed);
                if (deleteErrorTimerRef.current) clearTimeout(deleteErrorTimerRef.current);
                deleteErrorTimerRef.current = setTimeout(() => setDeleteError(null), 7000);
                await reload(page);
            } finally {
                setPendingDeleteItem(null);
            }
        }, 5000);
    }

    async function handleUndoDelete() {
        if (pendingDeleteTimerRef.current) clearTimeout(pendingDeleteTimerRef.current);
        pendingDeleteTimerRef.current = null;
        setPendingDeleteItem(null);
        await reload(page);
    }

    const deleteTriggerRef = useRef<HTMLButtonElement | null>(null);

    return (
        <main className="page carrierMain" id="main">
            <div className="container">
                {showSaved && (
                    <div className="savedBanner" role="status" aria-live="polite">
                        <span>{savedIsNew ? t.savedBannerNew : t.savedBanner}</span>
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
                        {toggleMsg === t.toggledHidden && recentlyDeactivatedId !== null && (
                            <button
                                className="savedBannerUndo"
                                aria-label={t.undoDeactivateAria}
                                onClick={handleUndoDeactivate}
                            >
                                {t.undoCta}
                            </button>
                        )}
                        <button
                            className="savedBannerClose"
                            aria-label={t.savedBannerDismiss}
                            onClick={() => {
                                setToggleMsg(null);
                                setRecentlyDeactivatedId(null);
                            }}
                        >
                            ×
                        </button>
                    </div>
                )}
                {deleteError && (
                    <div className="errorBanner" role="alert" aria-live="assertive">
                        <span>{deleteError}</span>
                        <button
                            className="savedBannerClose"
                            aria-label={t.savedBannerDismiss}
                            onClick={() => setDeleteError(null)}
                        >
                            ×
                        </button>
                    </div>
                )}
                {pendingDeleteItem && (
                    <div className="savedBanner" role="status" aria-live="polite">
                        <span>{t.deletedBanner}</span>
                        <button
                            className="savedBannerUndo"
                            aria-label={t.undoDeleteAria}
                            onClick={handleUndoDelete}
                        >
                            {t.undoCta}
                        </button>
                        <button
                            className="savedBannerClose"
                            aria-label={t.savedBannerDismiss}
                            onClick={() => setPendingDeleteItem(null)}
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
                        <Link
                            to="/carrier/availability/new"
                            className={buttonVariants()}
                        >
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
                        <p>{t.loadError}</p>
                        <Button variant="outline" onClick={() => reload(page)}>
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
                            {state.items.map((tw) => {
                                const route = fmtRoute(tw);
                                return (
                                <li key={tw.id} className={`windowCard${tw.active ? "" : " isInactive"}`}>
                                    <div className="windowCardHeader">
                                        <h2 className="windowRoute" title={route}>
                                            {route}
                                        </h2>
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
                                            <span>{t.pricePerKm}: <strong>${fmtPrice(tw.price_per_km)}</strong></span>
                                            <span aria-hidden="true"> · </span>
                                            <span>{t.maxKm}: <strong>{tw.max_km}</strong></span>
                                        </p>
                                        <p className="windowMeta">
                                            {t.from} {formatDate(tw.available_from)} — {t.to} {formatDate(tw.available_to)}
                                        </p>
                                    </div>
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
                                                className="cardSecondaryBtn"
                                                aria-label={toggling === tw.id ? t.toggling : `${tw.active ? t.deactivate : t.reactivate}: ${route}`}
                                                onClick={() => handleToggleActive(tw)}
                                                disabled={toggling === tw.id}
                                            >
                                                {toggling === tw.id ? (
                                                    <span className="cardActionLabel">{t.toggling}</span>
                                                ) : (
                                                    <>
                                                        {tw.active ? (
                                                            <svg aria-hidden="true" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
                                                                <path d="M1 7s2.333-4 6-4 6 4 6 4-2.333 4-6 4-6-4-6-4z" />
                                                                <circle cx="7" cy="7" r="2" />
                                                                <line x1="2" y1="2" x2="12" y2="12" />
                                                            </svg>
                                                        ) : (
                                                            <svg aria-hidden="true" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
                                                                <path d="M1 7s2.333-4 6-4 6 4 6 4-2.333 4-6 4-6-4-6-4z" />
                                                                <circle cx="7" cy="7" r="2" />
                                                            </svg>
                                                        )}
                                                        <span className="cardActionLabel" aria-hidden="true">
                                                            {tw.active ? t.deactivate : t.reactivate}
                                                        </span>
                                                    </>
                                                )}
                                            </Button>
                                            <Button
                                                variant="ghost"
                                                size="sm"
                                                className="cardSecondaryBtn cardDeleteBtn"
                                                aria-label={`${t.delete}: ${route}`}
                                                onClick={(e) => {
                                                    deleteTriggerRef.current = e.currentTarget as HTMLButtonElement;
                                                    if (tw.cargo_offers_count > 0) {
                                                        setBlockedDelete(tw);
                                                    } else {
                                                        setConfirmDelete(tw);
                                                    }
                                                }}
                                            >
                                                <svg aria-hidden="true" viewBox="0 0 14 14" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
                                                    <polyline points="1 3.5 2.5 3.5 13 3.5" />
                                                    <path d="M4.5 3.5V2a.5.5 0 0 1 .5-.5h4a.5.5 0 0 1 .5.5v1.5" />
                                                    <path d="M11.5 3.5l-.7 8a1 1 0 0 1-1 .9H4.2a1 1 0 0 1-1-.9l-.7-8" />
                                                    <line x1="5.5" y1="6.5" x2="5.5" y2="10" />
                                                    <line x1="8.5" y1="6.5" x2="8.5" y2="10" />
                                                </svg>
                                                <span className="cardActionLabel" aria-hidden="true">
                                                    {t.delete}
                                                </span>
                                            </Button>
                                        </div>
                                    </div>
                                </li>
                                );
                            })}
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
                            {fmtRoute(confirmDelete)}
                        </p>
                    )}
                    <p className="confirmDialogText">{t.deleteConfirm}</p>
                    <div className="confirmDialogActions">
                        <Button variant="ghost" onClick={() => setConfirmDelete(null)}>
                            {t.deleteCancel}
                        </Button>
                        <Button
                            variant="danger"
                            onClick={() => { if (confirmDelete !== null) handleDeleteOptimistic(confirmDelete); }}
                        >
                            {t.delete}
                        </Button>
                    </div>
                </div>
            </dialog>

            <dialog
                ref={blockDialogRef}
                className="confirmDialog"
                aria-modal="true"
                onClose={() => {
                    setBlockedDelete(null);
                    deleteTriggerRef.current?.focus();
                }}
                aria-labelledby="blocked-delete-title"
            >
                <div className="confirmDialogBody">
                    <h2 id="blocked-delete-title" className="confirmDialogTitle">
                        {t.deleteBlockedTitle}
                    </h2>
                    {blockedDelete && (
                        <p className="confirmDialogRoute">
                            {fmtRoute(blockedDelete)}
                        </p>
                    )}
                    <p className="confirmDialogText">{t.deleteBlockedBody}</p>
                    <div className="confirmDialogActions">
                        <Button onClick={() => setBlockedDelete(null)}>
                            {t.deleteBlockedClose}
                        </Button>
                    </div>
                </div>
            </dialog>
        </main>
    );
}
