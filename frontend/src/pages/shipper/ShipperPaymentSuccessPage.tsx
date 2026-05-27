import { useEffect, useState } from "react";
import { Link, useNavigate, useParams } from "react-router-dom";
import { ApiError } from "../../api";
import { getShipmentDetail } from "../../api/shipments";
import type { ShipmentDetail } from "../../api/shipments";
import { buttonVariants } from "../../components/ui/button";
import { paymentContent as t } from "./paymentContent";
import "../../styles/shipments.css";

function formatAmount(cents: number, currency: string): string {
    return new Intl.NumberFormat("es-AR", { style: "currency", currency }).format(cents / 100);
}

export default function ShipperPaymentSuccessPage() {
    const { id } = useParams<{ id: string }>();
    const navigate = useNavigate();
    const shipmentId = Number(id);
    const [shipment, setShipment] = useState<ShipmentDetail | null>(null);

    useEffect(() => {
        const previousTitle = document.title;
        document.title = t.success.documentTitle;
        return () => {
            document.title = previousTitle;
        };
    }, []);

    useEffect(() => {
        if (!Number.isFinite(shipmentId)) {
            navigate("/shipper/shipments", { replace: true });
            return;
        }
        getShipmentDetail(shipmentId)
            .then((detail) => {
                if (!detail.counterparty_contact) {
                    navigate("/shipper/shipments", { replace: true });
                    return;
                }
                setShipment(detail);
            })
            .catch((e: unknown) => {
                if (e instanceof ApiError) {
                    navigate("/shipper/shipments", { replace: true });
                    return;
                }
                navigate("/shipper/shipments", { replace: true });
            });
    }, [shipmentId, navigate]);

    if (!shipment || !shipment.counterparty_contact) {
        return (
            <main className="page shipperMain shipperPaymentSuccessPage" id="main" aria-busy="true">
                <div className="container" />
            </main>
        );
    }

    const contact = shipment.counterparty_contact;

    return (
        <main className="page shipperMain shipperPaymentSuccessPage" id="main">
            <div className="container shipperPaymentSuccessContainer">
                <header className="shipperPaymentSuccessHeader">
                    <span className="shipperPaymentSuccessIcon" aria-hidden="true">
                        ✓
                    </span>
                    <h1 className="sectionTitle">{t.success.heading}</h1>
                    <p className="sectionLead">{t.success.subheading}</p>
                </header>

                <section className="shipperPaymentSuccessSummary" aria-label={t.success.amountLabel}>
                    <span className="shipperPaymentSummaryLabel">{t.success.amountLabel}</span>
                    <span className="shipperPaymentSummaryAmount">
                        {formatAmount(shipment.amount_cents, shipment.currency)}
                    </span>
                </section>

                <section className="shipperPaymentContactPanel" aria-label={t.success.contactTitle}>
                    <h2 className="shipperPaymentContactTitle">{t.success.contactTitle}</h2>
                    <dl className="shipperPaymentContactList">
                        <div className="shipperPaymentContactRow">
                            <dt>{t.success.contactName}</dt>
                            <dd>{contact.full_name}</dd>
                        </div>
                        <div className="shipperPaymentContactRow">
                            <dt>{t.success.contactEmail}</dt>
                            <dd>
                                <a href={`mailto:${contact.email}`}>{contact.email}</a>
                            </dd>
                        </div>
                        <div className="shipperPaymentContactRow">
                            <dt>{t.success.contactPhone}</dt>
                            <dd>
                                {contact.phone
                                    ? <a href={`tel:${contact.phone}`}>{contact.phone}</a>
                                    : t.success.contactPhoneFallback}
                            </dd>
                        </div>
                    </dl>
                </section>

                <div className="shipperPaymentActions">
                    <Link
                        to="/shipper/shipments"
                        className={buttonVariants({ variant: "primary", size: "default" })}
                    >
                        {t.success.backCta}
                    </Link>
                </div>
            </div>
        </main>
    );
}
