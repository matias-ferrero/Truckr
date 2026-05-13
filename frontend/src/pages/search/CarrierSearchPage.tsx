import { FormEvent, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { ApiError } from "../../api";
import {
    CarrierSearchParams,
    CarrierSearchResult,
    SearchTransportWindow,
    searchCarriers,
} from "../../api/carriers";
import { carrierSearchContent as t } from "./carrierSearchContent";
import "./carrier.css";

type SearchState =
    | { status: "idle" }
    | { status: "loading" }
    | { status: "error"; message: string }
    | { status: "ready"; items: CarrierSearchResult[] };

const initialFilters: CarrierSearchParams = {
    originZone: "",
    destinationZone: "",
    dateFrom: "",
    dateTo: "",
};

function formatMoney(pricePerKm: string): string {
    const value = Number(pricePerKm);
    if (Number.isNaN(value)) return pricePerKm;
    return new Intl.NumberFormat("es-AR", {
        style: "currency",
        currency: "ARS",
        maximumFractionDigits: 0,
    }).format(value);
}

function firstWindow(item: CarrierSearchResult): SearchTransportWindow | null {
    return item.transport_windows[0] ?? null;
}

export default function CarrierSearchPage() {
    const [filters, setFilters] = useState(initialFilters);
    const [state, setState] = useState<SearchState>({ status: "idle" });
    const [rangeError, setRangeError] = useState<string | null>(null);

    const canSubmit = useMemo(
        () =>
            !!filters.originZone.trim() &&
            !!filters.destinationZone.trim() &&
            !!filters.dateFrom &&
            !!filters.dateTo,
        [filters],
    );

    const runSearch = async (criteria: CarrierSearchParams) => {
        setState({ status: "loading" });
        setRangeError(null);
        try {
            const items = await searchCarriers(criteria);
            setState({ status: "ready", items });
        } catch (error) {
            const message = error instanceof ApiError
                ? error.message
                : "No pudimos completar la búsqueda";
            setState({ status: "error", message });
        }
    };

    const onSubmit = async (event: FormEvent<HTMLFormElement>) => {
        event.preventDefault();

        if (filters.dateFrom > filters.dateTo) {
            setRangeError(t.form.rangeError);
            return;
        }

        await runSearch(filters);
    };

    return (
        <main className="page carrierMain" id="main">
            <div className="container searchShell">
                <header className="searchHeader">
                    <h1 className="sectionTitle">{t.title}</h1>
                    <p className="sectionLead">{t.lead}</p>
                </header>

                <form className="searchForm" onSubmit={onSubmit}>
                    <fieldset>
                        <legend className="visuallyHidden">{t.form.filterLegend || "Criterios de búsqueda"}</legend>
                        <label className="searchField">
                            <span>{t.form.origin}</span>
                            <input
                                className="input"
                                type="text"
                                value={filters.originZone}
                                placeholder={t.form.originPlaceholder}
                                onChange={(event) =>
                                    setFilters((current) => ({ ...current, originZone: event.target.value }))}
                                required
                                aria-label={t.form.origin}
                            />
                        </label>

                        <label className="searchField">
                            <span>{t.form.destination}</span>
                            <input
                                className="input"
                                type="text"
                                value={filters.destinationZone}
                                placeholder={t.form.destinationPlaceholder}
                                onChange={(event) =>
                                    setFilters((current) => ({ ...current, destinationZone: event.target.value }))}
                                required
                                aria-label={t.form.destination}
                            />
                        </label>

                        <label className="searchField">
                            <span>{t.form.dateFrom}</span>
                            <input
                                className="input"
                                type="date"
                                value={filters.dateFrom}
                                onChange={(event) =>
                                    setFilters((current) => ({ ...current, dateFrom: event.target.value }))}
                                required
                                aria-label={t.form.dateFrom}
                            />
                        </label>

                        <label className="searchField">
                            <span>{t.form.dateTo}</span>
                            <input
                                className="input"
                                type="date"
                                value={filters.dateTo}
                                onChange={(event) =>
                                    setFilters((current) => ({ ...current, dateTo: event.target.value }))}
                                required
                                aria-label={t.form.dateTo}
                                aria-invalid={rangeError ? "true" : "false"}
                                aria-describedby={rangeError ? "range-error-msg" : undefined}
                            />
                        </label>
                    </fieldset>

                    <button className="button buttonPrimary" type="submit" disabled={!canSubmit || state.status === "loading"}>
                        {state.status === "loading" ? t.form.submitBusy : t.form.submit}
                    </button>
                </form>

                {rangeError && (
                    <div className="errorPanel" role="alert" id="range-error-msg">
                        <p>{rangeError}</p>
                    </div>
                )}

                {state.status === "idle" && (
                    <section className="searchStatePanel" aria-live="polite">
                        <h2>{t.states.idleTitle}</h2>
                        <p>{t.states.idleText}</p>
                    </section>
                )}

                {state.status === "loading" && (
                    <section className="searchStatePanel" aria-live="polite" aria-busy="true" role="status">
                        <p>{t.states.loading}</p>
                        <ul
                            className="searchResults skeleton"
                            aria-label={t.states.loadingLabel || "Cargando transportistas"}
                        >
                            {[0, 1, 2].map((i) => (
                                <li key={i} className="searchCard skeletonCard" />
                            ))}
                        </ul>
                    </section>
                )}

                {state.status === "error" && (
                    <section className="searchStatePanel" aria-live="polite" role="alert">
                        <h2>{t.states.errorTitle}</h2>
                        <p>{state.message}</p>
                        <button className="button buttonGhost" type="button" onClick={() => runSearch(filters)}>
                            {t.states.retry}
                        </button>
                    </section>
                )}

                {state.status === "ready" && state.items.length === 0 && (
                    <section className="searchStatePanel" aria-live="polite">
                        <h2>{t.states.emptyTitle}</h2>
                        <p>{t.states.emptyText}</p>
                        <p className="searchCriteria">
                            Búsqueda: <strong>{filters.originZone}</strong> → <strong>{filters.destinationZone}</strong>
                            {" "}({filters.dateFrom} a {filters.dateTo})
                        </p>
                    </section>
                )}

                {state.status === "ready" && state.items.length > 0 && (
                    <ul className="searchResults" aria-label={t.resultsLabel} role="region" aria-live="polite">
                        {state.items.map((item) => {
                            const window = firstWindow(item);
                            return (
                                <li className="searchCard" key={item.id}>
                                    <div className="searchCardBody">
                                        <h2>{item.display_name || t.card.nameFallback}</h2>
                                        <p>
                                            <strong>{t.card.rating}:</strong>
                                            {" "}
                                            ⭐ {item.rating_avg} · {item.completed_shipments} {t.card.shipments}
                                        </p>
                                        {window && (
                                            <>
                                                <p>
                                                    <strong>{t.card.zones}:</strong>
                                                    {" "}
                                                    {window.origin_zone} → {window.destination_zone}
                                                </p>
                                                <p>
                                                    <strong>{t.card.price}:</strong>
                                                    {" "}
                                                    {formatMoney(window.price_per_km)} {t.card.priceUnit}
                                                </p>
                                                <p>
                                                    <strong>{t.card.available}:</strong>
                                                    {" "}
                                                    {window.available_from.slice(0, 10)} - {window.available_to.slice(0, 10)}
                                                </p>
                                            </>
                                        )}
                                        <p>
                                            <strong>{t.card.base}:</strong>
                                            {" "}
                                            {[item.base_city, item.province].filter(Boolean).join(", ") || "-"}
                                        </p>
                                    </div>
                                    <div className="searchCardActions">
                                        <Link className="button buttonGhost" to={`/carriers/${item.id}`}>
                                            {t.card.details}
                                        </Link>
                                    </div>
                                </li>
                            );
                        })}
                    </ul>
                )}
            </div>
        </main>
    );
}
