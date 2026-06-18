/* Pure projection from the raw compatible-windows array into the Cargo
 * Matches v2 view model (docs/features/cargo-matches-v2.prd.md). No React,
 * no I/O — the page renders straight off the returned `MatchesModel`.
 *
 * Every window in the input is already compatible (route, dates, capacity,
 * radius), so the model's job is *comparison*, not eligibility:
 *   - picks: up to three legible superlatives — cheapest / best-rated /
 *     soonest — each self-justifying, no blended score.
 *   - bestRated needs `reviews_count >= 1`; a lone unrated carrier never
 *     outranks an established one, and the slot disappears when nothing
 *     is rated yet.
 *   - picks are computed over the *filtered* set but ignore the active
 *     sort ("el más barato" can't change meaning when the grid reorders).
 *   - the strip is suppressed at <= MIN_MATCHES_FOR_PICKS matches — at that
 *     size the grid itself is the comparison.
 *   - filters and sort are US5's documented axes only; pagination is
 *     client-side slicing (US25).
 */

import type { CargoMatch } from "../../types/Cargo";
import { haversineKm } from "../../lib/geo";

export type MatchSort = "price-asc" | "price-desc" | "rating-desc" | "date-asc";

export type MatchFilters = {
    /** Max *total* price in ARS; null = no price ceiling. */
    maxPrice: number | null;
    /** ISO date (yyyy-mm-dd); window must still be available on/after it. */
    pickupFrom: string | null;
    /** ISO date (yyyy-mm-dd); window must start on/before it. */
    pickupTo: string | null;
};

export type PickKind = "cheapest" | "bestRated" | "soonest";

export type MatchRow = {
    match: CargoMatch;
    /** price_per_km × cargo haul distance; null when the cargo has no distance. */
    totalPrice: number | null;
    pricePerKm: number;
    ratingAvg: number;
    reviewsCount: number;
    /** True when the carrier has no reviews — render the "nuevo" chip, never 0★. */
    isUnrated: boolean;
    /** Haversine km from the cargo pickup to the window origin; null without coords. */
    distanceToPickupKm: number | null;
    /** Superlative badge this row earned, if any (also shown in the grid). */
    pick: PickKind | null;
};

export type MatchesModel = {
    /** Ordered, distinct picks (≤3). Empty when suppressed or no matches. */
    picks: { kind: PickKind; row: MatchRow }[];
    /** The current page of the filtered + sorted grid. */
    rows: MatchRow[];
    totalCount: number;
    filteredCount: number;
    page: number;
    pageCount: number;
};

export type BuildMatchesOptions = {
    sort: MatchSort;
    filters: MatchFilters;
    page: number;
    pageSize?: number;
};

export const DEFAULT_SORT: MatchSort = "price-asc";
export const EMPTY_FILTERS: MatchFilters = {
    maxPrice: null,
    pickupFrom: null,
    pickupTo: null,
};
export const PAGE_SIZE = 12;

/** Below this many (filtered) matches the picks strip adds nothing. */
const MIN_MATCHES_FOR_PICKS = 4;

type CargoContext = {
    /** The cargo's stored haul distance in km; null when not yet computed. */
    distanceKm: number | null;
    /** Cargo pickup point, for the displayed distance-to-pickup. */
    pickup: { lat: number; lng: number } | null;
};

function toRow(match: CargoMatch, cargo: CargoContext): MatchRow {
    const pricePerKm = Number(match.price_per_km);
    const reviewsCount = match.carrier.reviews_count;
    return {
        match,
        pricePerKm,
        totalPrice: cargo.distanceKm !== null && pricePerKm > 0
            ? cargo.distanceKm * pricePerKm
            : null,
        ratingAvg: Number(match.carrier.rating_avg),
        reviewsCount,
        isUnrated: reviewsCount === 0,
        distanceToPickupKm: cargo.pickup
            ? haversineKm(cargo.pickup, {
                lat: Number(match.origin_lat),
                lng: Number(match.origin_lng),
            })
            : null,
        pick: null,
    };
}

/** Effective price for ordering: total when known, per-km otherwise.
 *  Haul distance is fixed per cargo, so the two orderings are identical. */
function priceKey(row: MatchRow): number {
    return row.totalPrice ?? row.pricePerKm;
}

function dateKey(row: MatchRow): number {
    return new Date(row.match.available_from).getTime();
}

function applyFilters(rows: MatchRow[], filters: MatchFilters): MatchRow[] {
    return rows.filter((row) => {
        if (filters.maxPrice !== null && priceKey(row) > filters.maxPrice) {
            return false;
        }
        if (
            filters.pickupFrom !== null &&
            row.match.available_to < `${filters.pickupFrom}T00:00:00`
        ) {
            return false;
        }
        if (
            filters.pickupTo !== null &&
            row.match.available_from > `${filters.pickupTo}T23:59:59`
        ) {
            return false;
        }
        return true;
    });
}

const comparators: Record<MatchSort, (a: MatchRow, b: MatchRow) => number> = {
    "price-asc": (a, b) => priceKey(a) - priceKey(b),
    "price-desc": (a, b) => priceKey(b) - priceKey(a),
    // Rated carriers first (by rating, ties by review depth); unrated sink.
    "rating-desc": (a, b) => {
        if (a.isUnrated !== b.isUnrated) return a.isUnrated ? 1 : -1;
        return b.ratingAvg - a.ratingAvg || b.reviewsCount - a.reviewsCount;
    },
    "date-asc": (a, b) => dateKey(a) - dateKey(b),
};

/** Best candidate per superlative among rows not already used by an earlier
 *  slot. Returns null when no eligible candidate remains. */
const pickSelectors: Record<PickKind, (rows: MatchRow[]) => MatchRow | null> = {
    cheapest: (rows) =>
        rows.reduce<MatchRow | null>(
            (best, row) => (best === null || priceKey(row) < priceKey(best) ? row : best),
            null,
        ),
    bestRated: (rows) =>
        rows.reduce<MatchRow | null>((best, row) => {
            if (row.isUnrated) return best;
            if (best === null) return row;
            if (row.ratingAvg !== best.ratingAvg) {
                return row.ratingAvg > best.ratingAvg ? row : best;
            }
            return row.reviewsCount > best.reviewsCount ? row : best;
        }, null),
    soonest: (rows) =>
        rows.reduce<MatchRow | null>(
            (best, row) => (best === null || dateKey(row) < dateKey(best) ? row : best),
            null,
        ),
};

const PICK_ORDER: PickKind[] = ["cheapest", "bestRated", "soonest"];

function selectPicks(filtered: MatchRow[]): { kind: PickKind; row: MatchRow }[] {
    if (filtered.length < MIN_MATCHES_FOR_PICKS) return [];
    const used = new Set<number>();
    const picks: { kind: PickKind; row: MatchRow }[] = [];
    for (const kind of PICK_ORDER) {
        const candidates = filtered.filter((row) => !used.has(row.match.id));
        const winner = pickSelectors[kind](candidates);
        if (winner === null) continue;
        used.add(winner.match.id);
        winner.pick = kind;
        picks.push({ kind, row: winner });
    }
    return picks;
}

export function buildMatchesModel(
    matches: CargoMatch[],
    cargo: CargoContext,
    options: BuildMatchesOptions,
): MatchesModel {
    const pageSize = options.pageSize ?? PAGE_SIZE;
    const all = matches.map((match) => toRow(match, cargo));

    const filtered = applyFilters(all, options.filters);
    const picks = selectPicks(filtered);

    const sorted = [...filtered].sort(comparators[options.sort]);

    const pageCount = Math.max(1, Math.ceil(sorted.length / pageSize));
    const page = Math.min(Math.max(1, options.page), pageCount);
    const rows = sorted.slice((page - 1) * pageSize, page * pageSize);

    return {
        picks,
        rows,
        totalCount: all.length,
        filteredCount: filtered.length,
        page,
        pageCount,
    };
}
