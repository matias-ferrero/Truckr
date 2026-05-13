import { useCallback, useEffect, useRef, useState } from "react";
import { Link, useLocation } from "react-router-dom";
import {
    deleteVehicle,
    listMyVehicles,
    Vehicle,
    VehicleListMeta,
} from "../../api/vehicles";
import { carrierContent, vehicleTypeLabel } from "./carrierContent";

const t = carrierContent.list;

type LoadState =
    | { status: "loading" }
    | { status: "ready"; items: Vehicle[]; meta: VehicleListMeta }
    | { status: "error"; message: string };

export default function VehicleList() {
    const location = useLocation();
    const highlightId = (location.state as { highlightId?: number } | null)?.highlightId;

    const [page, setPage] = useState(1);
    const [state, setState] = useState<LoadState>({ status: "loading" });
    const [pendingDelete, setPendingDelete] = useState<number | null>(null);
    const [confirmTarget, setConfirmTarget] = useState<number | null>(null);

    const reload = useCallback(async (nextPage = page) => {
        setState({ status: "loading" });
        try {
            const res = await listMyVehicles(nextPage);
            setState({ status: "ready", items: res.items, meta: res.meta });
        } catch (e) {
            setState({ status: "error", message: (e as Error).message });
        }
    }, [page]);

    useEffect(() => {
        reload(page);
    }, [reload, page]);

    async function performDelete(id: number) {
        setConfirmTarget(null);
        setPendingDelete(id);
        try {
            await deleteVehicle(id);
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
                    <Link to="/carrier/vehicle/new" className="button buttonPrimary">
                        {t.addCta}
                    </Link>
                </header>

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
                        <p>{t.emptyTitle}</p>
                        <Link to="/carrier/vehicle/new" className="button buttonPrimary">
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
                                            className="button buttonGhost"
                                        >
                                            {t.edit}
                                        </Link>
                                        <button
                                            className="button buttonDanger"
                                            type="button"
                                            onClick={() => setConfirmTarget(v.id)}
                                            disabled={pendingDelete === v.id}
                                        >
                                            {pendingDelete === v.id ? t.deleting : t.delete}
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
                    <button type="button" className="button buttonGhost" onClick={onCancel}>
                        {c.cancel}
                    </button>
                    <button type="button" className="button buttonDanger" onClick={onConfirm}>
                        {c.confirm}
                    </button>
                </div>
            </div>
        </dialog>
    );
}
