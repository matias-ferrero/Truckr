import { useCallback, useEffect, useRef, useState } from "react";
import { Link, useLocation } from "react-router-dom";
import {
    deleteVehicle,
    listMyVehicles,
    Vehicle,
    VehicleListMeta,
} from "../../api/vehicles";
import { carrierContent, vehicleTypeLabel } from "./carrierContent";
import { Button, buttonVariants } from "../../components/ui/button";
import { cn } from "../../lib/utils";

const t = carrierContent.list;

type LoadState =
    | { status: "loading" }
    | { status: "ready"; items: Vehicle[]; meta: VehicleListMeta }
    | { status: "error"; message: string };

type DiscardErrorKind = "windows" | "commitments" | "generic";

type DiscardError = {
    message: string;
    kind: DiscardErrorKind;
};

export default function VehicleList() {
    const location = useLocation();
    const highlightId = (location.state as { highlightId?: number } | null)?.highlightId;

    const [page, setPage] = useState(1);
    const [state, setState] = useState<LoadState>({ status: "loading" });
    const [pendingDelete, setPendingDelete] = useState<number | null>(null);
    const [confirmTarget, setConfirmTarget] = useState<number | null>(null);
    const [discardNotice, setDiscardNotice] = useState<string | null>(null);
    const [discardError, setDiscardError] = useState<DiscardError | null>(null);
    const discardNoticeTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

    const clearDiscardNoticeTimer = () => {
        if (discardNoticeTimerRef.current) {
            clearTimeout(discardNoticeTimerRef.current);
            discardNoticeTimerRef.current = null;
        }
    };

    const reload = useCallback(async (nextPage = page) => {
        setState({ status: "loading" });
        try {
            const res = await listMyVehicles(nextPage);
            setState({ status: "ready", items: res.items, meta: res.meta });
        } catch (e) {
            setState({ status: "error", message: (e as Error).message });
        }
    }, [page]);

    useEffect(() => () => {
        clearDiscardNoticeTimer();
    }, []);

    useEffect(() => {
        reload(page);
    }, [reload, page]);

    async function performDelete(id: number) {
        setConfirmTarget(null);
        setPendingDelete(id);
        setDiscardError(null);
        try {
            await deleteVehicle(id);
            setDiscardNotice(t.discardSuccess);
            clearDiscardNoticeTimer();
            discardNoticeTimerRef.current = setTimeout(() => setDiscardNotice(null), 5000);
            await reload(page);
        } catch (e) {
            const err = e as { status?: number; body?: { error?: { details?: { base?: string[] } } } };
            const base = err.body?.error?.details?.base?.[0] ?? null;
            const kind: DiscardErrorKind = base?.match(/ventan|window/i)
                ? "windows"
                : base?.match(/compromet|pendiente|ofert/i)
                    ? "commitments"
                    : "generic";
            setDiscardError({
                kind,
                message: base ?? t.discardFailed,
            });
            await reload(page);
        } finally {
            setPendingDelete(null);
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
                    <Link
                        to="/carrier/vehicle/new"
                        className={cn(buttonVariants({ variant: "primary" }))}
                    >
                        {t.addCta}
                    </Link>
                </header>

                {discardNotice && (
                    <div className="savedBanner" role="status" aria-live="polite">
                        <span>{discardNotice}</span>
                        <button
                            className="savedBannerClose"
                            aria-label={t.dismissBanner}
                            onClick={() => setDiscardNotice(null)}
                        >
                            ×
                        </button>
                    </div>
                )}

                {discardError && (
                    <div className="errorBanner" role="alert" aria-live="assertive">
                        <span>{discardError.message}</span>
                        {discardError.kind === "windows" ? (
                            <Link
                                to="/carrier/availability"
                                className="savedBannerUndo"
                            >
                                {t.discardBlockedWindowsCta}
                            </Link>
                        ) : discardError.kind === "commitments" ? (
                            <Link
                                to="/carrier/cargo-offers"
                                className="savedBannerUndo"
                            >
                                {t.discardBlockedCommitmentsCta}
                            </Link>
                        ) : null}
                        <button
                            className="savedBannerClose"
                            aria-label={t.dismissBanner}
                            onClick={() => setDiscardError(null)}
                        >
                            ×
                        </button>
                    </div>
                )}

                {state.status === "loading" && (
                    <ul
                        className="vehicleGrid skeleton"
                        aria-busy="true"
                        aria-label={t.loadingLabel}
                    >
                        {[0, 1, 2].map((i) => (
                            <li key={i} className="vehicleCard skeletonCard" />
                        ))}
                    </ul>
                )}

                {state.status === "error" && (
                    <div className="errorPanel" role="alert">
                        <p>{t.loadError}: {state.message}</p>
                        <Button variant="ghost" size="sm" onClick={() => reload(page)}>
                            {t.retry}
                        </Button>
                    </div>
                )}

                {state.status === "ready" && state.items.length === 0 && (
                    <div className="emptyState">
                        <p>{t.emptyTitle}</p>
                        <Link
                            to="/carrier/vehicle/new"
                            className={cn(buttonVariants({ variant: "primary" }))}
                        >
                            {t.emptyCta}
                        </Link>
                    </div>
                )}

                {state.status === "ready" && state.items.length > 0 && (
                    <>
                        <ul className="vehicleGrid" aria-label={t.gridLabel}>
                            {state.items.map((v) => (
                                <li
                                    key={v.id}
                                    className={`vehicleCard${highlightId === v.id ? " isHighlighted" : ""}`}
                                >
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
                                            : (
                                                <div className="cardPlaceholder" aria-hidden="true">
                                                    {t.placeholderEmoji}
                                                </div>
                                            )}
                                    </div>
                                    <div className="cardBody">
                                        <h2>{v.make} {v.model}</h2>
                                        <p className="cardMeta">
                                            <span>{t.plate}: <strong>{v.plate}</strong></span>
                                            {v.year && <span>· {v.year}</span>}
                                        </p>
                                        <p className="cardMeta">
                                            {t.capacity}: {v.max_load_kg} {t.capacityUnit} ·
                                            {" "}{vehicleTypeLabel(v.vehicle_type)}
                                        </p>
                                    </div>
                                    <div className="cardActions">
                                        <Link
                                            to={`/carrier/vehicle/${v.id}`}
                                            className={cn(
                                                buttonVariants({ variant: "ghost", size: "sm" }),
                                                "flex-1",
                                            )}
                                        >
                                            {t.edit}
                                        </Link>
                                        <Button
                                            variant="danger"
                                            size="sm"
                                            onClick={() => setConfirmTarget(v.id)}
                                            disabled={pendingDelete === v.id}
                                            className="flex-1"
                                        >
                                            {pendingDelete === v.id ? t.discarding : t.discard}
                                        </Button>
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
                                    {t.pagination.previous}
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
                                    {t.pagination.next}
                                </Button>
                            </nav>
                        )}
                    </>
                )}
            </div>

            <ConfirmDialog
                open={confirmTarget != null}
                onCancel={() => setConfirmTarget(null)}
                onConfirm={() => confirmTarget != null && performDelete(confirmTarget)}
            />
        </main>
    );
}

type ConfirmDialogProps = {
    open: boolean;
    onCancel: () => void;
    onConfirm: () => void;
};

function ConfirmDialog({ open, onCancel, onConfirm }: ConfirmDialogProps) {
    const ref = useRef<HTMLDialogElement | null>(null);
    const triggerRef = useRef<Element | null>(null);
    const c = carrierContent.list.confirmDelete;

    useEffect(() => {
        const el = ref.current;
        if (!el) return;
        if (open && !el.open) {
            triggerRef.current = document.activeElement;
            el.showModal();
        }
        if (!open && el.open) {
            el.close();
            if (triggerRef.current instanceof HTMLElement) {
                triggerRef.current.focus();
            }
        }
    }, [open]);

    return (
        <dialog
            ref={ref}
            className="confirmDialog"
            aria-labelledby="confirm-title"
            aria-describedby="confirm-text"
            onCancel={(e) => {
                e.preventDefault();
                onCancel();
            }}
        >
            <div className="confirmDialogBody">
                <h2 id="confirm-title" className="confirmDialogTitle">{c.title}</h2>
                <p id="confirm-text" className="confirmDialogText">{c.text}</p>
                <div className="confirmDialogActions">
                    <Button variant="ghost" size="sm" onClick={onCancel}>
                        {c.cancel}
                    </Button>
                    <Button variant="danger" size="sm" onClick={onConfirm}>
                        {c.confirm}
                    </Button>
                </div>
            </div>
        </dialog>
    );
}
