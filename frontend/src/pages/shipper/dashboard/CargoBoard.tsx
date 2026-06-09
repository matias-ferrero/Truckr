import type { ColumnKey, DashboardModel } from "./buildDashboardModel";
import { shipperDashboardContent as t } from "./shipperDashboardContent";
import { BoardCard } from "./BoardCard";

const COLUMN_ORDER: ColumnKey[] = [
    "searching",
    "withOffers",
    "acceptedOffers",
    "inTransit",
    "delivered",
];

/** Per-stage modifier so each column reads as a distinct freight stage, not a
 *  generic kanban lane. Maps 1:1 to the column order above. */
const COLUMN_TONE: Record<ColumnKey, string> = {
    searching: "stage--searching",
    withOffers: "stage--offers",
    acceptedOffers: "stage--accepted",
    inTransit: "stage--transit",
    delivered: "stage--delivered",
};

export function CargoBoard({ model }: { model: DashboardModel }) {
    return (
        <section className="dashBoard" aria-labelledby="dash-board-title">
            <h2 className="dashSection__title" id="dash-board-title">
                {t.board.title}
            </h2>
            <ol className="dashBoard__track" aria-label={t.board.regionLabel}>
                {COLUMN_ORDER.map((key) => {
                    const cards = model.columns[key];
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
                            {cards.length === 0
                                ? <p className="dashColumn__empty">{t.board.columnEmpty}</p>
                                : (
                                    <ul className="dashColumn__cards">
                                        {cards.map((card) => <BoardCard key={card.key} card={card} />)}
                                    </ul>
                                )}
                        </li>
                    );
                })}
            </ol>
        </section>
    );
}
