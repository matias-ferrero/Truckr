import { useCallback, useEffect, useRef, useState } from "react";
import { Button } from "../../components/ui/button";
import {
    acceptCarrierCargoOffer,
    CarrierCargoOffer,
    CarrierCargoOfferStatus,
    listCarrierCargoOffers,
    rejectCarrierCargoOffer,
} from "../../api/carrierCargoOffers";
import { offersAndShipmentsContent } from "./offersAndShipmentsContent";

const t = offersAndShipmentsContent.inbox;

const arDateFormatter = new Intl.DateTimeFormat("es-AR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
});

const arDateTimeFormatter = new Intl.DateTimeFormat("es-AR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
});

const arsFormatter = new Intl.NumberFormat("es-AR", {
    style: "currency",
    currency: "ARS",
    maximumFractionDigits: 0,
});

type InboxState =
    | { status: "loading" }
    | {
        status: "ready";
        items: CarrierCargoOffer[];
        meta: { total: number; page: number; perPage: number; totalPages: number };
    }
    | { status: "error"; message: string };

type ConfirmAction = {
    kind: "accept" | "reject";
    offer: CarrierCargoOffer;
};

function formatDate(iso: string): string {
    return arDateFormatter.format(new Date(iso));
}

function formatDateTime(iso: string): string {
    return arDateTimeFormatter.format(new Date(iso));
}

function formatARS(cents: number): string {
    return arsFormatter.format(cents / 100);
}

function summaryRoute(offer: CarrierCargoOffer): string {
    const from = offer.cargo.pickup_address.split(",")[0]?.trim() ?? "";
    const to = offer.cargo.delivery_address.split(",")[0]?.trim() ?? "";
    if (!from || !to) return t.cargoRouteFallback(offer.cargo_id);
    return `${from} → ${to}`;
}

export default function CarrierCargoOfferInbox() {
    const [statusFilter, setStatusFilter] = useState<CarrierCargoOfferStatus>("pending");
    const [page, setPage] = useState(1);
    const [state, setState] = useState<InboxState>({ status: "loading" });
    const [actionInFlight, setActionInFlight] = useState<number | null>(null);
    const [confirmAction, setConfirmAction] = useState<ConfirmAction | null>(null);
    const [feedback, setFeedback] = useState<string | null>(null);
    const [expanded, setExpanded] = useState<Record<number, boolean>>({});

    const dialogRef = useRef<HTMLDialogElement>(null);
    const triggerButtonRef = useRef<HTMLButtonElement | null>(null);

    const reload = useCallback(async (nextPage = page, nextStatus = statusFilter) => {
        setState({ status: "loading" });
        try {
            const res = await listCarrierCargoOffers(nextStatus, nextPage);
            setState({ status: "ready", items: res.items, meta: res.meta });
        } catch (error) {
            setState({ status: "error", message: (error as Error).message });
        }
    }, [page, statusFilter]);

    useEffect(() => {
        reload(page, statusFilter);
    }, [reload, page, statusFilter]);

    useEffect(() => {
        const dialog = dialogRef.current;
        if (!dialog) return;
        if (confirmAction !== null) {
            dialog.showModal();
        } else if (dialog.open) {
            dialog.close();
        }
    }, [confirmAction]);

    async function confirmAndRun(): Promise<void> {
        if (!confirmAction) return;

        const offer = confirmAction.offer;
        setConfirmAction(null);
        setActionInFlight(offer.id);
        setFeedback(null);

        try {
            if (confirmAction.kind === "accept") {
                await acceptCarrierCargoOffer(offer.id);
                setFeedback(t.successAccepted);
            } else {
                await rejectCarrierCargoOffer(offer.id);
                setFeedback(t.successRejected);
            }
            await reload(page, statusFilter);
        } catch (error) {
            setFeedback((error as Error).message);
        } finally {
            setActionInFlight(null);
        }
    }

    const confirmationId = confirmAction?.offer.id ?? null;

    return (
        <main className="page carrierMain" id="main">
            <div className="container">
                {feedback && (
                    <div className="savedBanner" role="status" aria-live="polite">
                        <span>{feedback}</span>
                        <button
                            className="savedBannerClose"
                            aria-label={t.confirm.cancel}
                            onClick={() => setFeedback(null)}
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
                    <label className="inboxFilterLabel">
                        <span>{t.filterLabel}</span>
                        <select
                            value={statusFilter}
                            onChange={(event) => {
                                setPage(1);
                                setStatusFilter(event.target.value as CarrierCargoOfferStatus);
                            }}
                            className="inboxFilterSelect"
                        >
                            <option value="pending">{t.statusOptions.pending}</option>
                            <option value="accepted">{t.statusOptions.accepted}</option>
                            <option value="paid">{t.statusOptions.paid}</option>
                            <option value="rejected">{t.statusOptions.rejected}</option>
                            <option value="expired">{t.statusOptions.expired}</option>
                            <option value="cancelled">{t.statusOptions.cancelled}</option>
                        </select>
                    </label>
                </header>

                {state.status === "loading" && (
                    <ul className="offerInboxGrid skeleton" aria-busy="true" aria-label={t.loadingLabel}>
                        {[0, 1, 2].map((i) => (
                            <li key={i} className="offerInboxCard skeletonCard" aria-hidden="true" />
                        ))}
                    </ul>
                )}

                {state.status === "error" && (
                    <div className="errorPanel" role="alert">
                        <p>{t.loadError}: {state.message}</p>
                        <Button variant="ghost" onClick={() => reload(page, statusFilter)}>
                            {t.retry}
                        </Button>
                    </div>
                )}

                {state.status === "ready" && state.items.length === 0 && (
                    <div className="emptyState">
                        <h2 className="emptyStateTitle">{t.emptyTitle}</h2>
                        <p className="sectionLead">{t.emptyLead}</p>
                    </div>
                )}

                {state.status === "ready" && state.items.length > 0 && (
                    <>
                        <ul className="offerInboxGrid" aria-label={t.title}>
                            {state.items.map((offer) => {
                                const route = summaryRoute(offer);
                                const isPending = offer.status === "pending";
                                return (
                                    <li key={offer.id} className="offerInboxCard">
                                        <div className="offerInboxHead">
                                            <h2 className="offerInboxRoute">{route}</h2>
                                            <span className={`statusBadge ${offerStatusClass(offer.status)}`}>
                                                {t.statusOptions[offer.status]}
                                            </span>
                                        </div>
                                        <div className="offerInboxMeta">
                                            <p><strong>{t.amount}:</strong> {formatARS(offer.price_amount_cents)}</p>
                                            <p><strong>{t.expiresAt}:</strong> {formatDateTime(offer.expires_at)}</p>
                                            <p><strong>{t.shipper}:</strong> {offer.shipper.name ?? "—"}</p>
                                        </div>

                                        <details
                                            className="offerInboxDetails"
                                            onToggle={(e) => {
                                                const open = (e.currentTarget as HTMLDetailsElement).open;
                                                setExpanded((prev) => ({ ...prev, [offer.id]: open }));
                                            }}
                                        >
                                            <summary
                                                id={`offer-summary-${offer.id}`}
                                                aria-controls={`offer-details-${offer.id}`}
                                                aria-expanded={!!expanded[offer.id]}
                                            >
                                                {t.detailsOpen}
                                            </summary>
                                            <div
                                                id={`offer-details-${offer.id}`}
                                                className="offerInboxDetailBody"
                                                role="region"
                                                aria-labelledby={`offer-summary-${offer.id}`}
                                            >
                                                <h3>{t.detailTitle}</h3>
                                                <p><strong>{t.pickupAddress}:</strong> {offer.cargo.pickup_address}</p>
                                                <p><strong>{t.deliveryAddress}:</strong> {offer.cargo.delivery_address}</p>
                                                <p>
                                                    <strong>{t.pickupWindow}:</strong>{" "}
                                                    {formatDate(offer.cargo.pickup_window_start)} - {formatDate(offer.cargo.pickup_window_end)}
                                                </p>
                                                <p><strong>{t.weight}:</strong> {offer.cargo.weight_kg} kg</p>
                                                <p><strong>{t.volume}:</strong> {offer.cargo.volume_cm3 ?? "—"}</p>
                                                <p><strong>{t.declaredValue}:</strong> {formatARS(offer.cargo.declared_value_cents)}</p>
                                                <p><strong>{t.description}:</strong> {offer.cargo.cargo_description}</p>

                                                <h3>{t.windowTitle}</h3>
                                                <p>
                                                    <strong>{t.windowDate}:</strong>{" "}
                                                    {formatDate(offer.transport_window.available_from)} - {formatDate(offer.transport_window.available_to)}
                                                </p>
                                                <p><strong>{t.windowRate}:</strong> {offer.transport_window.price_per_km}</p>
                                                <p><strong>{t.windowMaxKm}:</strong> {offer.transport_window.max_km}</p>
                                            </div>
                                        </details>

                                        <div className="offerInboxActions">
                                            <Button
                                                variant="primary"
                                                size="sm"
                                                disabled={!isPending || actionInFlight === offer.id}
                                                onClick={(event) => {
                                                    triggerButtonRef.current = event.currentTarget as HTMLButtonElement;
                                                    setConfirmAction({ kind: "accept", offer });
                                                }}
                                            >
                                                {actionInFlight === offer.id ? t.processing : t.accept}
                                            </Button>
                                            <Button
                                                variant="ghost"
                                                size="sm"
                                                disabled={!isPending || actionInFlight === offer.id}
                                                onClick={(event) => {
                                                    triggerButtonRef.current = event.currentTarget as HTMLButtonElement;
                                                    setConfirmAction({ kind: "reject", offer });
                                                }}
                                            >
                                                {actionInFlight === offer.id ? t.processing : t.reject}
                                            </Button>
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
                                    onClick={() => setPage((current) => Math.max(1, current - 1))}
                                >
                                    {t.pagination.previous}
                                </Button>
                                <p>
                                    {t.pagination.page(state.meta.page, state.meta.totalPages)} · {t.pagination.count(state.meta.total)}
                                </p>
                                <Button
                                    variant="ghost"
                                    size="sm"
                                    disabled={page >= state.meta.totalPages}
                                    onClick={() => setPage((current) => current + 1)}
                                >
                                    {t.pagination.next}
                                </Button>
                            </nav>
                        )}
                    </>
                )}
            </div>

            <dialog
                ref={dialogRef}
                className="confirmDialog"
                role="dialog"
                aria-modal="true"
                onClose={() => {
                    setConfirmAction(null);
                    triggerButtonRef.current?.focus();
                }}
                aria-labelledby="confirm-offer-action"
                aria-describedby="confirm-offer-desc"
            >
                <div className="confirmDialogBody">
                    <h2 id="confirm-offer-action" className="confirmDialogTitle">
                        {t.confirm.title}
                    </h2>
                    <p id="confirm-offer-desc" className="confirmDialogText">
                        {confirmAction?.kind === "accept" ? t.confirm.acceptText : t.confirm.rejectText}
                    </p>
                    <div className="confirmDialogActions">
                        <Button variant="ghost" onClick={() => setConfirmAction(null)}>
                            {t.confirm.cancel}
                        </Button>
                        <Button
                            variant={confirmAction?.kind === "accept" ? "primary" : "danger"}
                            onClick={() => {
                                if (confirmationId !== null) void confirmAndRun();
                            }}
                        >
                            {confirmAction?.kind === "accept" ? t.confirm.accept : t.confirm.reject}
                        </Button>
                    </div>
                </div>
            </dialog>
        </main>
    );
}

function offerStatusClass(status: CarrierCargoOfferStatus): string {
    switch (status) {
        case "pending":
            return "pendiente";
        case "accepted":
            return "aceptado";
        case "paid":
            return "pagado";
        case "rejected":
        case "expired":
        case "cancelled":
            return "pasado";
        default:
            return "pendiente";
    }
}
