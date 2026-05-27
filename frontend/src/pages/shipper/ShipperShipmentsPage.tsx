import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Button, buttonVariants } from "../../components/ui/button";
import { listShipperShipments } from "../../api/shipments";
import type { Shipment } from "../../api/shipments";
import { ShipmentListRow } from "../../components/shipments/ShipmentListRow";
import { SkeletonRows } from "../../components/shipments/SkeletonRows";
import { shipmentStateSortOrder } from "../../components/shipments/shipmentsSharedContent";
import { shipperShipmentsContent as t } from "./shipperShipmentsContent";
import "../../styles/shipments.css";

type PageState =
    | { status: "loading" }
    | { status: "ready"; items: Shipment[] }
    | { status: "error"; message: string };

function sortShipments(items: Shipment[]): Shipment[] {
    return [...items].sort(
        (a, b) => shipmentStateSortOrder[a.state] - shipmentStateSortOrder[b.state],
    );
}

export default function ShipperShipmentsPage() {
    const [state, setState] = useState<PageState>({ status: "loading" });

    const load = useCallback(async () => {
        setState({ status: "loading" });
        try {
            const items = await listShipperShipments();
            setState({ status: "ready", items: sortShipments(items) });
        } catch (error) {
            setState({ status: "error", message: (error as Error).message });
        }
    }, []);

    useEffect(() => {
        load();
    }, [load]);

    return (
        <main className="page shipperMain" id="main">
            <div className="container">
                <header className="listHeader">
                    <div className="shipmentListHeader">
                        <div>
                            <h1 className="sectionTitle">{t.title}</h1>
                            <p className="sectionLead">{t.lead}</p>
                        </div>
                        {state.status === "ready" && (
                            <span className="shipmentListCount">
                                {t.shipmentCount(state.items.length)}
                            </span>
                        )}
                    </div>
                </header>

                {state.status === "loading" && (
                    <ul
                        className="shipmentList shipmentList--shipper"
                        aria-busy="true"
                        aria-label={t.loadingLabel}
                        role="status"
                    >
                        <SkeletonRows />
                    </ul>
                )}

                {state.status === "error" && (
                    <div className="shipmentErrorPanel" role="alert">
                        <p>{t.loadError}.</p>
                        <Button variant="primary" onClick={load}>
                            {t.retry}
                        </Button>
                    </div>
                )}

                {state.status === "ready" && state.items.length === 0 && (
                    <div className="shipmentEmptyState shipmentEmptyState--shipper">
                        <div className="shipmentEmptyContent">
                            <h2 className="shipmentEmptyTitle">
                                {t.emptyTitle}
                            </h2>
                            <p className="shipmentEmptyLead">{t.emptyLead}</p>
                        </div>
                        <Link to="/shipper/cargos/new" className={buttonVariants({ variant: "primary", size: "sm" })}>
                            {t.emptyCtaLabel}
                        </Link>
                    </div>
                )}

                {state.status === "ready" && state.items.length > 0 && (
                    <ul className="shipmentList shipmentList--shipper" aria-label={t.listLabel}>
                        {state.items.map((shipment) => (
                            <ShipmentListRow
                                key={shipment.id}
                                shipment={shipment}
                                detailPath={`/shipper/shipments/${shipment.id}`}
                                payHref={(s) => `/shipper/shipments/${s.id}/pay`}
                            />
                        ))}
                    </ul>
                )}
            </div>
        </main>
    );
}
