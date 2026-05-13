import { FormEvent, useEffect, useMemo, useRef, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { ApiError } from "../../api";
import {
    CarrierSearchParams,
    CarrierSearchResult,
    SearchTransportWindow,
    searchCarriers,
} from "../../api/carriers";
import { carrierSearchContent as t } from "./carrierSearchContent";
import { Button, buttonVariants } from "../../components/ui/button";
import { Input } from "../../components/ui/input";
import { FormField } from "../../components/ui/form-field";
import { Alert } from "../../components/ui/alert";
import { cn } from "../../lib/utils";
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

function readFiltersFromParams(params: URLSearchParams): CarrierSearchParams {
    return {
        originZone: params.get("origin_zone") ?? "",
        destinationZone: params.get("destination_zone") ?? "",
        dateFrom: params.get("date_from") ?? "",
        dateTo: params.get("date_to") ?? "",
    };
}

function hasAllFilters(filters: CarrierSearchParams): boolean {
    return (
        filters.originZone.trim().length > 0 &&
        filters.destinationZone.trim().length > 0 &&
        filters.dateFrom.length > 0 &&
        filters.dateTo.length > 0
    );
}

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
    const [searchParams] = useSearchParams();
    const [filters, setFilters] = useState<CarrierSearchParams>(() =>
        readFiltersFromParams(searchParams)
    );
    const [state, setState] = useState<SearchState>({ status: "idle" });
    const [rangeError, setRangeError] = useState<string | null>(null);
    const autoRanRef = useRef(false);

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

    useEffect(() => {
        if (autoRanRef.current) return;
        const initial = readFiltersFromParams(searchParams);
        if (!hasAllFilters(initial)) return;
        if (initial.dateFrom > initial.dateTo) {
            setRangeError(t.form.rangeError);
            autoRanRef.current = true;
            return;
        }
        autoRanRef.current = true;
        void runSearch(initial);
        // searchParams is read once on mount via ref guard; do not re-run on every URL tick.
        // eslint-disable-next-line react-hooks/exhaustive-deps
    }, []);

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

                <form
                    className="grid gap-4 bg-paper p-6 rounded-md shadow-[0_6px_24px_color-mix(in_oklab,var(--color-ink)_6%,transparent)]"
                    onSubmit={onSubmit}
                >
                    <fieldset className="grid gap-4 grid-cols-[repeat(auto-fit,minmax(200px,1fr))] border-0 p-0 m-0 min-w-0">
                        <legend className="sr-only">
                            {t.form.filterLegend || "Criterios de búsqueda"}
                        </legend>
                        <FormField id="search-origin" label={t.form.origin}>
                            <Input
                                id="search-origin"
                                type="text"
                                value={filters.originZone}
                                placeholder={t.form.originPlaceholder}
                                onChange={(event) =>
                                    setFilters((current) => ({ ...current, originZone: event.target.value }))}
                                required
                                aria-label={t.form.origin}
                            />
                        </FormField>
                        <FormField id="search-destination" label={t.form.destination}>
                            <Input
                                id="search-destination"
                                type="text"
                                value={filters.destinationZone}
                                placeholder={t.form.destinationPlaceholder}
                                onChange={(event) =>
                                    setFilters((current) => ({ ...current, destinationZone: event.target.value }))}
                                required
                                aria-label={t.form.destination}
                            />
                        </FormField>
                        <FormField id="search-date-from" label={t.form.dateFrom}>
                            <Input
                                id="search-date-from"
                                type="date"
                                value={filters.dateFrom}
                                onChange={(event) =>
                                    setFilters((current) => ({ ...current, dateFrom: event.target.value }))}
                                required
                                aria-label={t.form.dateFrom}
                            />
                        </FormField>
                        <FormField
                            id="search-date-to"
                            label={t.form.dateTo}
                            error={rangeError ?? undefined}
                        >
                            <Input
                                id="search-date-to"
                                type="date"
                                value={filters.dateTo}
                                onChange={(event) =>
                                    setFilters((current) => ({ ...current, dateTo: event.target.value }))}
                                required
                                aria-label={t.form.dateTo}
                            />
                        </FormField>
                    </fieldset>

                    <Button type="submit" disabled={!canSubmit || state.status === "loading"}>
                        {state.status === "loading" ? t.form.submitBusy : t.form.submit}
                    </Button>
                </form>

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
                    <Alert tone="error" aria-live="polite" className="mt-4">
                        <div className="flex flex-col gap-2 w-full">
                            <h2 className="font-semibold text-base">{t.states.errorTitle}</h2>
                            <p>{state.message}</p>
                            <Button
                                variant="ghost"
                                size="sm"
                                onClick={() => runSearch(filters)}
                                className="self-start"
                            >
                                {t.states.retry}
                            </Button>
                        </div>
                    </Alert>
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
                                        <Link
                                            className={cn(buttonVariants({ variant: "ghost", size: "sm" }))}
                                            to={`/carriers/${item.id}`}
                                        >
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
