import { FormEvent, useMemo, useState } from "react";
import { Link } from "react-router-dom";
import { ApiError } from "../../api";
import {
    CarrierSearchParams,
    CarrierSearchResult,
    SearchTransportWindow,
    searchCarriers,
} from "../../api/carriers";
import { transportWindowSearchContent as t } from "./transportWindowSearchContent";
import { Button, buttonVariants } from "../../components/ui/button";
import { Input } from "../../components/ui/input";
import { FormField } from "../../components/ui/form-field";
import { cn } from "../../lib/utils";

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

const RESULT_PREVIEW_LIMIT = 6;

const moneyFmt = new Intl.NumberFormat("es-AR", {
    style: "currency",
    currency: "ARS",
    maximumFractionDigits: 0,
});

function formatMoney(pricePerKm: string): string {
    const value = Number(pricePerKm);
    return Number.isFinite(value) ? moneyFmt.format(value) : pricePerKm;
}

function firstWindow(item: CarrierSearchResult): SearchTransportWindow | null {
    return item.transport_windows[0] ?? null;
}

function buildSearchUrl(filters: CarrierSearchParams): string {
    const q = new URLSearchParams({
        origin_zone: filters.originZone,
        destination_zone: filters.destinationZone,
        date_from: filters.dateFrom,
        date_to: filters.dateTo,
    });
    return `/transport_windows/search?${q.toString()}`;
}

export function TransportWindowSearchSection() {
    const [filters, setFilters] = useState<CarrierSearchParams>(initialFilters);
    const [state, setState] = useState<SearchState>({ status: "idle" });
    const [rangeError, setRangeError] = useState<string | null>(null);

    const canSubmit = useMemo(
        () =>
            filters.originZone.trim().length > 0 &&
            filters.destinationZone.trim().length > 0 &&
            filters.dateFrom.length > 0 &&
            filters.dateTo.length > 0,
        [filters],
    );

    const runSearch = async (criteria: CarrierSearchParams) => {
        setState({ status: "loading" });
        setRangeError(null);
        try {
            const items = await searchCarriers(criteria);
            setState({ status: "ready", items });
        } catch (error) {
            const message =
                error instanceof ApiError ? error.message : "No pudimos completar la búsqueda";
            setState({ status: "error", message });
        }
    };

    const onSubmit = async (event: FormEvent<HTMLFormElement>) => {
        event.preventDefault();
        if (filters.dateFrom && filters.dateTo && filters.dateFrom > filters.dateTo) {
            setRangeError(t.form.rangeError);
            return;
        }
        await runSearch(filters);
    };

    const resultCount = state.status === "ready" ? state.items.length : 0;
    const visibleItems =
        state.status === "ready" ? state.items.slice(0, RESULT_PREVIEW_LIMIT) : [];

    return (
        <section className="dashboardSection" aria-labelledby="section-search">
            <div className="dashboardSectionHeader">
                <div className="dashboardSectionHeading">
                    <span className="dashboardSectionIcon" aria-hidden="true">
                        <IconSearch />
                    </span>
                    <h2 id="section-search">{t.section.title}</h2>
                    {state.status === "ready" && (
                        <span
                            className="dashboardSectionCount"
                            aria-label={t.results.countLabel(resultCount)}
                        >
                            {resultCount}
                        </span>
                    )}
                </div>
                <span className="text-sm text-ink-soft">{t.section.lead}</span>
            </div>

            <form
                className="grid gap-3 mt-3"
                onSubmit={onSubmit}
            >
                <fieldset className="grid gap-3 grid-cols-[repeat(auto-fit,minmax(180px,1fr))] border-0 p-0 m-0 min-w-0">
                    <legend className="sr-only">{t.form.legend}</legend>

                    <FormField id="tw-search-origin" label={t.form.origin}>
                        <Input
                            id="tw-search-origin"
                            type="text"
                            value={filters.originZone}
                            placeholder={t.form.originPlaceholder}
                            onChange={(e) =>
                                setFilters((prev) => ({ ...prev, originZone: e.target.value }))}
                            required
                            aria-label={t.form.origin}
                        />
                    </FormField>

                    <FormField id="tw-search-destination" label={t.form.destination}>
                        <Input
                            id="tw-search-destination"
                            type="text"
                            value={filters.destinationZone}
                            placeholder={t.form.destinationPlaceholder}
                            onChange={(e) =>
                                setFilters((prev) => ({ ...prev, destinationZone: e.target.value }))}
                            required
                            aria-label={t.form.destination}
                        />
                    </FormField>

                    <FormField id="tw-search-date-from" label={t.form.dateFrom}>
                        <Input
                            id="tw-search-date-from"
                            type="date"
                            value={filters.dateFrom}
                            onChange={(e) =>
                                setFilters((prev) => ({ ...prev, dateFrom: e.target.value }))}
                            required
                            aria-label={t.form.dateFrom}
                        />
                    </FormField>

                    <FormField
                        id="tw-search-date-to"
                        label={t.form.dateTo}
                        error={rangeError ?? undefined}
                    >
                        <Input
                            id="tw-search-date-to"
                            type="date"
                            value={filters.dateTo}
                            onChange={(e) =>
                                setFilters((prev) => ({ ...prev, dateTo: e.target.value }))}
                            required
                            aria-label={t.form.dateTo}
                        />
                    </FormField>
                </fieldset>

                <div className="flex justify-end">
                    <Button
                        type="submit"
                        size="sm"
                        disabled={!canSubmit || state.status === "loading"}
                    >
                        {state.status === "loading" ? t.form.submitBusy : t.form.submit}
                    </Button>
                </div>
            </form>

            {state.status === "idle" && (
                <div className="dashboardEmpty" role="status">
                    <span className="dashboardEmptyIcon" aria-hidden="true">
                        <IconCompass />
                    </span>
                    <div>
                        <span className="dashboardEmptyTitle">{t.states.idleTitle}</span>
                        <span className="dashboardEmptyHint">{t.states.idleText}</span>
                    </div>
                </div>
            )}

            {state.status === "loading" && (
                <div
                    className="dashboardCardList"
                    aria-busy="true"
                    aria-label={t.states.loadingLabel}
                >
                    {[0, 1, 2].map((i) => (
                        <div key={i} className="dashboardSkeleton dashboardSkeletonCard" />
                    ))}
                </div>
            )}

            {state.status === "error" && (
                <div className="dashboardEmpty" role="alert">
                    <span className="dashboardEmptyIcon" aria-hidden="true">
                        <IconAlert />
                    </span>
                    <div className="flex flex-col items-start gap-2">
                        <span className="dashboardEmptyTitle">{t.states.errorTitle}</span>
                        <span className="dashboardEmptyHint">{state.message}</span>
                        <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => runSearch(filters)}
                        >
                            {t.states.retry}
                        </Button>
                    </div>
                </div>
            )}

            {state.status === "ready" && state.items.length === 0 && (
                <div className="dashboardEmpty" role="status">
                    <span className="dashboardEmptyIcon" aria-hidden="true">
                        <IconCompass />
                    </span>
                    <div>
                        <span className="dashboardEmptyTitle">{t.states.emptyTitle}</span>
                        <span className="dashboardEmptyHint">{t.states.emptyText}</span>
                    </div>
                </div>
            )}

            {state.status === "ready" && state.items.length > 0 && (
                <>
                    <ul
                        className="dashboardCardList dashboardSearchResults"
                        role="region"
                        aria-label={t.results.regionLabel}
                        aria-live="polite"
                    >
                        {visibleItems.map((item) => {
                            const window = firstWindow(item);
                            const base = [item.base_city, item.province]
                                .filter(Boolean)
                                .join(t.results.baseSeparator);
                            return (
                                <li key={item.id}>
                                    <Link
                                        to={`/carriers/${item.id}`}
                                        className="dashboardCard dashboardSearchCard"
                                    >
                                        <div className="dashboardCardHead">
                                            <span className="dashboardCardEyebrow">
                                                {t.results.cardEyebrow}
                                            </span>
                                            {window && (
                                                <span className="dashboardCardPrice">
                                                    {formatMoney(window.price_per_km)}
                                                    <span className="text-xs font-medium text-ink-faint ml-1">
                                                        {t.results.priceUnit}
                                                    </span>
                                                </span>
                                            )}
                                        </div>
                                        <h3 className="dashboardCardTitle">
                                            {item.display_name ||
                                                item.legal_name ||
                                                t.results.nameFallback}
                                            <IconArrowRight className="arrow" />
                                        </h3>
                                        {window && (
                                            <div className="dashboardCardMeta">
                                                <IconRoute />
                                                <span>
                                                    {window.origin_zone} → {window.destination_zone}
                                                </span>
                                            </div>
                                        )}
                                        <div className="dashboardCardMeta">
                                            <IconStar />
                                            <span>
                                                {item.rating_avg} · {item.completed_shipments}{" "}
                                                {t.results.shipments}
                                                {base ? ` · ${base}` : ""}
                                            </span>
                                        </div>
                                    </Link>
                                </li>
                            );
                        })}
                    </ul>
                    {state.items.length > RESULT_PREVIEW_LIMIT && (
                        <Link
                            to={buildSearchUrl(filters)}
                            className={cn(
                                buttonVariants({ variant: "ghost", size: "sm" }),
                                "self-start mt-3",
                            )}
                        >
                            {t.results.viewAll}
                            <IconArrowRight />
                        </Link>
                    )}
                </>
            )}
        </section>
    );
}

/* ---- Icons (Lucide-style, currentColor) ----------------------------- */

type IconProps = { className?: string };

function IconSearch() {
    return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <circle cx="11" cy="11" r="6.5" />
            <path d="m20 20-3.6-3.6" />
        </svg>
    );
}

function IconCompass() {
    return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <circle cx="12" cy="12" r="9" />
            <path d="m15 9-2 5-5 2 2-5 5-2z" />
        </svg>
    );
}

function IconAlert() {
    return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="M10.3 4.1 2.6 17.4A2 2 0 0 0 4.3 20.5h15.4a2 2 0 0 0 1.7-3.1L13.7 4.1a2 2 0 0 0-3.4 0Z" />
            <path d="M12 10v4" />
            <path d="M12 17.5h.01" />
        </svg>
    );
}

function IconRoute() {
    return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <circle cx="6" cy="6" r="2.25" />
            <circle cx="18" cy="18" r="2.25" />
            <path d="M8 6h6a4 4 0 0 1 0 8h-4a4 4 0 0 0 0 8h6" />
        </svg>
    );
}

function IconStar() {
    return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="m12 3.5 2.6 5.4 5.9.6-4.4 4 1.3 5.9L12 16.5l-5.4 2.9 1.3-5.9-4.4-4 5.9-.6L12 3.5z" />
        </svg>
    );
}

function IconArrowRight({ className }: IconProps) {
    return (
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" className={className}>
            <path d="M5 12h14M13 6l6 6-6 6" />
        </svg>
    );
}
