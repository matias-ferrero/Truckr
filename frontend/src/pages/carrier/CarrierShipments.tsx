import { useCallback, useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { Button } from "../../components/ui/button";
import { listCarrierShipments, ShipmentStatusFilter } from "../../api/shipments";
import type { CarrierShipment } from "../../api/shipments";
import { offersAndShipmentsContent } from "./offersAndShipmentsContent";

const t = offersAndShipmentsContent.shipments;

const arDateFormatter = new Intl.DateTimeFormat("es-AR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
});

type ShipmentState =
    | { status: "loading" }
    | {
        status: "ready";
        items: CarrierShipment[];
        meta: { total: number; page: number; perPage: number; totalPages: number };
    }
    | { status: "error"; message: string };

const STATUS_FILTERS: Array<{ value: "all" | ShipmentStatusFilter; label: string }> = [
    { value: "all", label: t.statuses.all },
    { value: "pending_payment", label: t.statuses.pending_payment },
    { value: "to_pick_up", label: t.statuses.to_pick_up },
    { value: "in_transit", label: t.statuses.in_transit },
    { value: "delivered", label: t.statuses.delivered },
];

function formatDateTime(iso: string | null): string {
    if (!iso) return "—";
    return arDateFormatter.format(new Date(iso));
}

export default function CarrierShipments() {
    const [searchParams, setSearchParams] = useSearchParams();
    const [page, setPage] = useState(1);
    const [state, setState] = useState<ShipmentState>({ status: "loading" });

    const selected = (searchParams.get("status") ?? "all") as "all" | ShipmentStatusFilter;

    const reload = useCallback(async (nextPage = page, filter = selected) => {
        setState({ status: "loading" });
        try {
            const status = filter === "all" ? undefined : filter;
            const res = await listCarrierShipments(status, nextPage);
            setState({ status: "ready", items: res.items, meta: res.meta });
        } catch (error) {
            setState({ status: "error", message: (error as Error).message });
        }
    }, [page, selected]);

    useEffect(() => {
        reload(page, selected);
    }, [reload, page, selected]);

    return (
        <main className="page carrierMain" id="main">
            <div className="container">
                <header className="listHeader">
                    <div>
                        <h1 className="sectionTitle">{t.title}</h1>
                        <p className="sectionLead">{t.lead}</p>
                    </div>
                    <div className="shipmentsFilter" role="group" aria-label={t.statusLabel}>
                        {STATUS_FILTERS.map((option) => (
                            <Button
                                key={option.value}
                                variant={selected === option.value ? "primary" : "ghost"}
                                size="sm"
                                aria-pressed={selected === option.value}
                                onClick={() => {
                                    setPage(1);
                                    if (option.value === "all") {
                                        setSearchParams({});
                                    } else {
                                        setSearchParams({ status: option.value });
                                    }
                                }}
                            >
                                {option.label}
                            </Button>
                        ))}
                    </div>
                </header>

                {state.status === "loading" && (
                    <ul className="shipmentGrid skeleton" aria-busy="true" aria-label={t.loadingLabel}>
                        {[0, 1, 2].map((i) => (
                            <li key={i} className="shipmentCard skeletonCard" aria-hidden="true" />
                        ))}
                    </ul>
                )}

                {state.status === "error" && (
                    <div className="errorPanel" role="alert">
                        <p>{t.loadError}: {state.message}</p>
                        <Button variant="ghost" onClick={() => reload(page, selected)}>
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
                        <ul className="shipmentGrid" aria-label={t.title}>
                            {state.items.map((shipment) => (
                                <li key={shipment.id} className="shipmentCard">
                                    <div className="shipmentHead">
                                        <h2>{t.shipmentId(shipment.id)}</h2>
                                        <span className={`statusBadge ${shipmentStatusClass(shipment.status)}`}>
                                            {t.statusBadge[shipment.status] ?? shipment.status}
                                        </span>
                                    </div>
                                    <p className="shipmentMeta"><strong>{t.cargoOfferId(shipment.cargo_offer_id)}</strong></p>
                                    <p className="shipmentMeta"><strong>{t.acceptedAt}:</strong> {formatDateTime(shipment.accepted_at)}</p>
                                    <p className="shipmentMeta"><strong>{t.pickedUpAt}:</strong> {formatDateTime(shipment.picked_up_at)}</p>
                                    <p className="shipmentMeta"><strong>{t.deliveredAt}:</strong> {formatDateTime(shipment.delivered_at)}</p>
                                </li>
                            ))}
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
        </main>
    );
}

function shipmentStatusClass(status: string): string {
    return status === "delivered" ? "statusInactive" : "statusActive";
}
