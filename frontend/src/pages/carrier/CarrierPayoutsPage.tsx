import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Payout, listCarrierPayouts } from "../../api/payouts";
import { carrierPayoutsContent as t } from "./carrierPayoutsContent";
import { formatDateTime } from "../../lib/format-date";
import { formatCurrency } from "../../lib/format-currency";
import "../../styles/carrier-payouts.css";

export function CarrierPayoutsPage() {
    const [payouts, setPayouts] = useState<Payout[]>([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState(false);

    useEffect(() => {
        listCarrierPayouts()
            .then(setPayouts)
            .catch(() => setError(true))
            .finally(() => setLoading(false));
    }, []);

    if (loading) {
        return (
            <main className="page carrierPayoutsPage" id="main" aria-busy="true">
                <div className="container" />
            </main>
        );
    }

    return (
        <main className="page carrierPayoutsPage" id="main">
            <div className="container">
                <h1 className="carrierPayoutsTitle">{t.title}</h1>

                {error ? (
                    <div className="carrierPayoutsEmpty" role="alert">{t.error}</div>
                ) : payouts.length === 0 ? (
                    <div className="carrierPayoutsEmpty">{t.empty}</div>
                ) : (
                    <div className="carrierPayoutsTableWrapper">
                        <table className="carrierPayoutsTable">
                            <caption className="visuallyHidden">{t.tableCaption}</caption>
                            <thead>
                                <tr>
                                    <th scope="col">{t.table.route}</th>
                                    <th scope="col">{t.table.shipper}</th>
                                    <th scope="col">{t.table.gross}</th>
                                    <th scope="col">{t.table.commission}</th>
                                    <th scope="col">{t.table.net}</th>
                                    <th scope="col">{t.table.state}</th>
                                    <th scope="col">{t.table.date}</th>
                                    <th scope="col">
                                        <span className="visuallyHidden">{t.table.actionsHeader}</span>
                                    </th>
                                </tr>
                            </thead>
                            <tbody>
                                {payouts.map((p) => (
                                    <tr key={p.id}>
                                        <td data-label={t.table.route}>{p.origin} → {p.destination}</td>
                                        <td data-label={t.table.shipper}>{p.shipper_name}</td>
                                        <td data-label={t.table.gross} className="carrierPayoutsGross">
                                            {formatCurrency(p.gross_amount_cents, p.currency)}
                                        </td>
                                        <td data-label={t.table.commission} className="carrierPayoutsCommission">
                                            - {formatCurrency(p.commission_cents, p.currency)}
                                        </td>
                                        <td data-label={t.table.net} className="carrierPayoutsNet">
                                            {formatCurrency(p.amount_cents, p.currency)}
                                        </td>
                                        <td data-label={t.table.state}>
                                            <span className={`carrierPayoutsState carrierPayoutsState--${p.state}`}>
                                                {t.states[p.state]}
                                            </span>
                                        </td>
                                        <td data-label={t.table.date}>{formatDateTime(p.paid_at ?? p.created_at)}</td>
                                        <td>
                                            <Link
                                                to={`/carrier/shipments/${p.shipment_id}`}
                                                className="carrierPayoutsLink"
                                                aria-label={t.table.linkAria(p.origin, p.destination)}
                                            >
                                                {t.table.link}
                                            </Link>
                                        </td>
                                    </tr>
                                ))}
                            </tbody>
                        </table>
                    </div>
                )}
            </div>
        </main>
    );
}
