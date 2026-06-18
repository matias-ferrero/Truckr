import { describe, expect, it } from "vitest";
import {
    buildMatchesModel,
    DEFAULT_SORT,
    EMPTY_FILTERS,
    type BuildMatchesOptions,
    type MatchFilters,
    type MatchSort,
} from "./buildMatchesModel";
import type { CargoMatch } from "../../types/Cargo";

let nextId = 1;

function makeMatch(overrides: {
    pricePerKm?: string;
    ratingAvg?: string;
    reviewsCount?: number;
    availableFrom?: string;
    availableTo?: string;
    originLat?: string;
    originLng?: string;
} = {}): CargoMatch {
    return {
        id: nextId++,
        origin_address: "Av. Corrientes 1000",
        origin_locality: "CABA",
        origin_admin_area: "Buenos Aires",
        origin_lat: overrides.originLat ?? "-34.603722",
        origin_lng: overrides.originLng ?? "-58.381592",
        destination_address: "Bv. San Juan 100",
        destination_locality: "Córdoba",
        destination_admin_area: "Córdoba",
        destination_lat: "-31.420083",
        destination_lng: "-64.188776",
        price_per_km: overrides.pricePerKm ?? "10.0",
        max_km: 1000,
        pickup_radius_km: 50,
        dropoff_radius_km: 50,
        available_from: overrides.availableFrom ?? "2026-06-15T00:00:00Z",
        available_to: overrides.availableTo ?? "2026-06-30T00:00:00Z",
        active: true,
        vehicle: {
            id: 1,
            make: "Volvo",
            model: "FH",
            plate: "AB123CD",
            max_load_kg: "8000.0",
        },
        carrier: {
            id: nextId,
            display_name: `Carrier ${nextId}`,
            rating_avg: overrides.ratingAvg ?? "0.0",
            reviews_count: overrides.reviewsCount ?? 0,
        },
    };
}

const CARGO = { distanceKm: 700, pickup: { lat: -34.6, lng: -58.38 } };

function options(over: {
    sort?: MatchSort;
    filters?: Partial<MatchFilters>;
    page?: number;
    pageSize?: number;
} = {}): BuildMatchesOptions {
    return {
        sort: over.sort ?? DEFAULT_SORT,
        filters: { ...EMPTY_FILTERS, ...over.filters },
        page: over.page ?? 1,
        pageSize: over.pageSize,
    };
}

describe("buildMatchesModel — rows", () => {
    it("computes the total price as per-km × cargo distance", () => {
        const model = buildMatchesModel(
            [makeMatch({ pricePerKm: "1.5" })],
            CARGO,
            options(),
        );
        expect(model.rows[0].totalPrice).toBe(1050);
        expect(model.rows[0].pricePerKm).toBe(1.5);
    });

    it("leaves totalPrice null when the cargo has no distance", () => {
        const model = buildMatchesModel(
            [makeMatch()],
            { distanceKm: null, pickup: null },
            options(),
        );
        expect(model.rows[0].totalPrice).toBeNull();
        expect(model.rows[0].distanceToPickupKm).toBeNull();
    });

    it("flags carriers without reviews as unrated", () => {
        const model = buildMatchesModel(
            [
                makeMatch({ reviewsCount: 0, ratingAvg: "0.0" }),
                makeMatch({ reviewsCount: 3, ratingAvg: "4.5" }),
            ],
            CARGO,
            options(),
        );
        expect(model.rows.map((r) => r.isUnrated)).toEqual([true, false]);
    });

    it("computes the Haversine distance to pickup when coords exist", () => {
        const model = buildMatchesModel([makeMatch()], CARGO, options());
        expect(model.rows[0].distanceToPickupKm).toBeGreaterThanOrEqual(0);
        expect(model.rows[0].distanceToPickupKm).toBeLessThan(5);
    });
});

describe("buildMatchesModel — picks", () => {
    it("selects cheapest, best-rated, and soonest as three distinct picks", () => {
        const matches = [
            makeMatch({ pricePerKm: "1.0", ratingAvg: "3.0", reviewsCount: 1, availableFrom: "2026-06-20T00:00:00Z" }),
            makeMatch({ pricePerKm: "2.0", ratingAvg: "4.9", reviewsCount: 10, availableFrom: "2026-06-21T00:00:00Z" }),
            makeMatch({ pricePerKm: "3.0", ratingAvg: "4.0", reviewsCount: 2, availableFrom: "2026-06-10T00:00:00Z" }),
            makeMatch({ pricePerKm: "4.0", ratingAvg: "3.5", reviewsCount: 2, availableFrom: "2026-06-25T00:00:00Z" }),
        ];
        const model = buildMatchesModel(matches, CARGO, options());
        expect(model.picks.map((p) => p.kind)).toEqual(["cheapest", "bestRated", "soonest"]);
        expect(model.picks[0].row.match.id).toBe(matches[0].id);
        expect(model.picks[1].row.match.id).toBe(matches[1].id);
        expect(model.picks[2].row.match.id).toBe(matches[2].id);
        const ids = model.picks.map((p) => p.row.match.id);
        expect(new Set(ids).size).toBe(3);
    });

    it("requires at least one review to win bestRated", () => {
        const lone5star = makeMatch({ pricePerKm: "2.0", ratingAvg: "5.0", reviewsCount: 0 });
        const veteran = makeMatch({ pricePerKm: "3.0", ratingAvg: "4.7", reviewsCount: 40 });
        const model = buildMatchesModel(
            [lone5star, veteran, makeMatch({ pricePerKm: "1.0" }), makeMatch({ pricePerKm: "4.0" })],
            CARGO,
            options(),
        );
        const bestRated = model.picks.find((p) => p.kind === "bestRated");
        expect(bestRated?.row.match.id).toBe(veteran.id);
    });

    it("breaks rating ties by review count", () => {
        const shallow = makeMatch({ pricePerKm: "2.0", ratingAvg: "4.8", reviewsCount: 2 });
        const deep = makeMatch({ pricePerKm: "3.0", ratingAvg: "4.8", reviewsCount: 25 });
        const model = buildMatchesModel(
            [shallow, deep, makeMatch({ pricePerKm: "1.0" }), makeMatch({ pricePerKm: "4.0" })],
            CARGO,
            options(),
        );
        const bestRated = model.picks.find((p) => p.kind === "bestRated");
        expect(bestRated?.row.match.id).toBe(deep.id);
    });

    it("omits bestRated entirely when no carrier has reviews", () => {
        const matches = [
            makeMatch({ pricePerKm: "1.0", availableFrom: "2026-06-20T00:00:00Z" }),
            makeMatch({ pricePerKm: "2.0", availableFrom: "2026-06-10T00:00:00Z" }),
            makeMatch({ pricePerKm: "3.0", availableFrom: "2026-06-25T00:00:00Z" }),
            makeMatch({ pricePerKm: "4.0", availableFrom: "2026-06-28T00:00:00Z" }),
        ];
        const model = buildMatchesModel(matches, CARGO, options());
        expect(model.picks.map((p) => p.kind)).toEqual(["cheapest", "soonest"]);
    });

    it("promotes the next-best window when one would win two badges", () => {
        // matches[0] is both cheapest AND soonest; soonest slot must promote
        // the next-earliest distinct window.
        const doubleWinner = makeMatch({ pricePerKm: "1.0", availableFrom: "2026-06-05T00:00:00Z" });
        const runnerUp = makeMatch({ pricePerKm: "2.0", availableFrom: "2026-06-08T00:00:00Z" });
        const model = buildMatchesModel(
            [
                doubleWinner,
                runnerUp,
                makeMatch({ pricePerKm: "3.0", ratingAvg: "4.5", reviewsCount: 3, availableFrom: "2026-06-20T00:00:00Z" }),
                makeMatch({ pricePerKm: "4.0", availableFrom: "2026-06-25T00:00:00Z" }),
            ],
            CARGO,
            options(),
        );
        const soonest = model.picks.find((p) => p.kind === "soonest");
        expect(model.picks.find((p) => p.kind === "cheapest")?.row.match.id).toBe(doubleWinner.id);
        expect(soonest?.row.match.id).toBe(runnerUp.id);
    });

    it("suppresses the strip entirely at three or fewer matches", () => {
        const model = buildMatchesModel(
            [makeMatch(), makeMatch(), makeMatch()],
            CARGO,
            options(),
        );
        expect(model.picks).toEqual([]);
    });

    it("recomputes picks under an active filter (filter-aware)", () => {
        const cheapOutOfBudget = makeMatch({ pricePerKm: "1.0" }); // total 700
        const matches = [
            cheapOutOfBudget,
            makeMatch({ pricePerKm: "0.5" }), // total 350
            makeMatch({ pricePerKm: "0.6" }),
            makeMatch({ pricePerKm: "0.7" }),
            makeMatch({ pricePerKm: "0.8" }),
        ];
        const model = buildMatchesModel(matches, CARGO, options({ filters: { maxPrice: 600 } }));
        const cheapest = model.picks.find((p) => p.kind === "cheapest");
        expect(cheapest?.row.match.id).toBe(matches[1].id);
        expect(model.filteredCount).toBe(4);
    });

    it("keeps the same picks regardless of the active sort (sort-blind)", () => {
        const matches = [
            makeMatch({ pricePerKm: "1.0", ratingAvg: "4.0", reviewsCount: 1 }),
            makeMatch({ pricePerKm: "2.0", ratingAvg: "4.9", reviewsCount: 5 }),
            makeMatch({ pricePerKm: "3.0", availableFrom: "2026-06-01T00:00:00Z" }),
            makeMatch({ pricePerKm: "4.0" }),
        ];
        const asc = buildMatchesModel(matches, CARGO, options({ sort: "price-asc" }));
        const desc = buildMatchesModel(matches, CARGO, options({ sort: "price-desc" }));
        expect(asc.picks.map((p) => p.row.match.id)).toEqual(desc.picks.map((p) => p.row.match.id));
    });

    it("marks picked rows with their badge in the grid", () => {
        const matches = [
            makeMatch({ pricePerKm: "1.0" }),
            makeMatch({ pricePerKm: "2.0" }),
            makeMatch({ pricePerKm: "3.0" }),
            makeMatch({ pricePerKm: "4.0" }),
        ];
        const model = buildMatchesModel(matches, CARGO, options());
        const cheapestRow = model.rows.find((r) => r.match.id === matches[0].id);
        expect(cheapestRow?.pick).toBe("cheapest");
    });
});

describe("buildMatchesModel — sort", () => {
    const matches = [
        makeMatch({ pricePerKm: "3.0", ratingAvg: "4.0", reviewsCount: 2, availableFrom: "2026-06-20T00:00:00Z" }),
        makeMatch({ pricePerKm: "1.0", ratingAvg: "4.9", reviewsCount: 9, availableFrom: "2026-06-25T00:00:00Z" }),
        makeMatch({ pricePerKm: "2.0", reviewsCount: 0, availableFrom: "2026-06-10T00:00:00Z" }),
    ];

    it("sorts by price ascending and descending", () => {
        const asc = buildMatchesModel(matches, CARGO, options({ sort: "price-asc" }));
        expect(asc.rows.map((r) => r.pricePerKm)).toEqual([1, 2, 3]);
        const desc = buildMatchesModel(matches, CARGO, options({ sort: "price-desc" }));
        expect(desc.rows.map((r) => r.pricePerKm)).toEqual([3, 2, 1]);
    });

    it("sorts by rating with unrated carriers last", () => {
        const model = buildMatchesModel(matches, CARGO, options({ sort: "rating-desc" }));
        expect(model.rows.map((r) => r.ratingAvg)).toEqual([4.9, 4, 0]);
        expect(model.rows[2].isUnrated).toBe(true);
    });

    it("sorts by earliest availability", () => {
        const model = buildMatchesModel(matches, CARGO, options({ sort: "date-asc" }));
        expect(model.rows[0].match.available_from).toBe("2026-06-10T00:00:00Z");
    });
});

describe("buildMatchesModel — filters", () => {
    it("filters by max total price", () => {
        const matches = [
            makeMatch({ pricePerKm: "1.0" }), // total 700
            makeMatch({ pricePerKm: "2.0" }), // total 1400
        ];
        const model = buildMatchesModel(matches, CARGO, options({ filters: { maxPrice: 1000 } }));
        expect(model.filteredCount).toBe(1);
        expect(model.rows[0].match.id).toBe(matches[0].id);
        expect(model.totalCount).toBe(2);
    });

    it("filters by pickup date range against window availability", () => {
        const early = makeMatch({ availableFrom: "2026-06-01T00:00:00Z", availableTo: "2026-06-05T00:00:00Z" });
        const late = makeMatch({ availableFrom: "2026-06-20T00:00:00Z", availableTo: "2026-06-28T00:00:00Z" });
        const model = buildMatchesModel(
            [early, late],
            CARGO,
            options({ filters: { pickupFrom: "2026-06-10", pickupTo: "2026-06-22" } }),
        );
        expect(model.filteredCount).toBe(1);
        expect(model.rows[0].match.id).toBe(late.id);
    });

    it("combines price and date filters", () => {
        const matches = [
            makeMatch({ pricePerKm: "1.0", availableFrom: "2026-06-01T00:00:00Z", availableTo: "2026-06-05T00:00:00Z" }),
            makeMatch({ pricePerKm: "1.0", availableFrom: "2026-06-20T00:00:00Z" }),
            makeMatch({ pricePerKm: "9.0", availableFrom: "2026-06-20T00:00:00Z" }),
        ];
        const model = buildMatchesModel(
            matches,
            CARGO,
            options({ filters: { maxPrice: 1000, pickupFrom: "2026-06-10" } }),
        );
        expect(model.filteredCount).toBe(1);
        expect(model.rows[0].match.id).toBe(matches[1].id);
    });
});

describe("buildMatchesModel — pagination", () => {
    it("slices the sorted rows into pages", () => {
        const matches = Array.from({ length: 30 }, (_, i) =>
            makeMatch({ pricePerKm: String(i + 1) }));
        const p1 = buildMatchesModel(matches, CARGO, options({ pageSize: 12 }));
        expect(p1.rows).toHaveLength(12);
        expect(p1.pageCount).toBe(3);
        expect(p1.rows[0].pricePerKm).toBe(1);

        const p3 = buildMatchesModel(matches, CARGO, options({ page: 3, pageSize: 12 }));
        expect(p3.rows).toHaveLength(6);
        expect(p3.rows[0].pricePerKm).toBe(25);
    });

    it("clamps an out-of-range page into bounds", () => {
        const matches = Array.from({ length: 5 }, () => makeMatch());
        const model = buildMatchesModel(matches, CARGO, options({ page: 99, pageSize: 12 }));
        expect(model.page).toBe(1);
        expect(model.rows).toHaveLength(5);
    });

    it("handles the empty input", () => {
        const model = buildMatchesModel([], CARGO, options());
        expect(model).toMatchObject({
            picks: [],
            rows: [],
            totalCount: 0,
            filteredCount: 0,
            page: 1,
            pageCount: 1,
        });
    });
});
