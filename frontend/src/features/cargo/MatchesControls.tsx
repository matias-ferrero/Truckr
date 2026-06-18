import type { MatchFilters, MatchSort } from "./buildMatchesModel";
import { cargoMatchesContent } from "./cargoMatchesContent";

const t = cargoMatchesContent.controls;

type Props = {
    sort: MatchSort;
    filters: MatchFilters;
    shownCount: number;
    totalCount: number;
    onSortChange: (sort: MatchSort) => void;
    onFiltersChange: (filters: MatchFilters) => void;
};

const SORT_OPTIONS: MatchSort[] = [
    "price-asc",
    "price-desc",
    "rating-desc",
    "date-asc",
];

/**
 * Sort + filter bar for the matches grid — US5's documented axes only:
 * sort by price / rating / pickup date, filter by max price and pickup
 * date range. Native controls (select, number, date) keep the affordances
 * standard for occasional users.
 */
export default function MatchesControls({
    sort,
    filters,
    shownCount,
    totalCount,
    onSortChange,
    onFiltersChange,
}: Props) {
    const hasFilters = filters.maxPrice !== null ||
        filters.pickupFrom !== null || filters.pickupTo !== null;

    return (
        <div className="matchesControls" role="group" aria-label={t.heading}>
            <p className="matchesCount" aria-live="polite">
                {t.resultCount(shownCount, totalCount)}
            </p>
            <div className="matchesControlFields">
                <label className="matchesControl">
                    <span className="matchesControlLabel">{t.sortLabel}</span>
                    <select
                        className="matchesControlInput"
                        value={sort}
                        onChange={(e) =>
                            onSortChange(e.target.value as MatchSort)}
                    >
                        {SORT_OPTIONS.map((option) => (
                            <option key={option} value={option}>
                                {t.sortOptions[option]}
                            </option>
                        ))}
                    </select>
                </label>
                <label className="matchesControl">
                    <span className="matchesControlLabel">
                        {t.maxPriceLabel}
                    </span>
                    <input
                        className="matchesControlInput"
                        type="number"
                        min="0"
                        inputMode="numeric"
                        placeholder={t.maxPricePlaceholder}
                        value={filters.maxPrice ?? ""}
                        onChange={(e) =>
                            onFiltersChange({
                                ...filters,
                                maxPrice: e.target.value === ""
                                    ? null
                                    : Number(e.target.value),
                            })}
                    />
                </label>
                <label className="matchesControl">
                    <span className="matchesControlLabel">
                        {t.pickupFromLabel}
                    </span>
                    <input
                        className="matchesControlInput"
                        type="date"
                        value={filters.pickupFrom ?? ""}
                        onChange={(e) =>
                            onFiltersChange({
                                ...filters,
                                pickupFrom: e.target.value || null,
                            })}
                    />
                </label>
                <label className="matchesControl">
                    <span className="matchesControlLabel">
                        {t.pickupToLabel}
                    </span>
                    <input
                        className="matchesControlInput"
                        type="date"
                        value={filters.pickupTo ?? ""}
                        onChange={(e) =>
                            onFiltersChange({
                                ...filters,
                                pickupTo: e.target.value || null,
                            })}
                    />
                </label>
                {hasFilters && (
                    <button
                        type="button"
                        className="button buttonGhost matchesClearFilters"
                        onClick={() =>
                            onFiltersChange({
                                maxPrice: null,
                                pickupFrom: null,
                                pickupTo: null,
                            })}
                    >
                        {t.clearFilters}
                    </button>
                )}
            </div>
        </div>
    );
}
