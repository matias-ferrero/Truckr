import { Link } from "react-router-dom";
import type {
    CarrierDashboardModel,
    ColumnKey,
    OfferCard as OfferCardModel,
} from "./buildCarrierDashboardModel";
import { carrierDashboardContent as t } from "./carrierDashboardContent";
import { OfferCard } from "./OfferCard";
import { ShipmentCard } from "./ShipmentCard";

const COLUMN_ORDER: ColumnKey[] = ["newOffers", "toStart", "inTransit", "delivered", "paid"];

/** Per-stage modifier so each column reads as a distinct job stage, not a
 *  generic kanban lane. Maps 1:1 to the column order above. */
const COLUMN_TONE: Record<ColumnKey, string> = {
    newOffers: "stage--offers",
    toStart: "stage--start",
    inTransit: "stage--transit",
    delivered: "stage--collect",
    paid: "stage--paid",
};

export function JobBoard(
    { model, busyOfferId, onAccept, onReject }: {
        model: CarrierDashboardModel;
        busyOfferId: number | null;
        onAccept: (card: OfferCardModel) => void;
        onReject: (card: OfferCardModel) => void;
    },
) {
    return (
        <section className="dashBoard" aria-labelledby="dash-board-title">
            <h2 className="dashSection__title" id="dash-board-title">
                {t.board.title}
            </h2>
            <ol className="dashBoard__track" aria-label={t.board.regionLabel}>
                {COLUMN_ORDER.map((key) => {
                    const count = model.counts[key];
                    const name = t.board.columnNames[key];
                    return (
                        <li
                            key={key}
                            className={`dashColumn ${COLUMN_TONE[key]}`}
                            aria-label={t.board.columnAccessibleName(name, count)}
                        >
                            <div className="dashColumn__head">
                                <h3 className="dashColumn__title">{name}</h3>
                                <span className="dashColumn__count" aria-hidden="true">{count}</span>
                            </div>
                            {count === 0
                                ? <p className="dashColumn__empty">{t.board.columnEmpty}</p>
                                : (
                                    <ul className="dashColumn__cards">
                                        {key === "newOffers"
                                            ? model.columns.newOffers.map((card) => (
                                                <OfferCard
                                                    key={card.key}
                                                    card={card}
                                                    busy={busyOfferId === card.offerId}
                                                    onAccept={onAccept}
                                                    onReject={onReject}
                                                />
                                            ))
                                            : model.columns[key].map((card) => (
                                                <ShipmentCard key={card.key} card={card} />
                                            ))}
                                    </ul>
                                )}
                            {key === "paid" && (
                                <Link to={t.board.payoutsHref} className="dashColumn__drill">
                                    {t.board.payoutsLink}
                                </Link>
                            )}
                        </li>
                    );
                })}
            </ol>
        </section>
    );
}
