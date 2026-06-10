import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import CargoMatches from "./CargoMatches";
import * as cargoApi from "./api";
import type { Cargo, CargoMatch } from "../../types/Cargo";

vi.mock("./api");

const api = vi.mocked(cargoApi);

function makeCargo(over: Partial<Cargo> = {}): Cargo {
    return {
        id:                   7,
        shipper_id:           1,
        status:               "open",
        cargo_description:    "Pallets de electrodomésticos",
        pickup_address:       "Av. Corrientes 1234",
        pickup_lat:           "-34.603722",
        pickup_lng:           "-58.381592",
        pickup_locality:      "CABA",
        pickup_admin_area:    "Buenos Aires",
        delivery_address:     "Av. Colón 500",
        delivery_lat:         "-31.420083",
        delivery_lng:         "-64.188776",
        delivery_locality:    "Córdoba",
        delivery_admin_area:  "Córdoba",
        pickup_window_start:  "2026-06-01T08:00:00Z",
        pickup_window_end:    "2026-06-03T18:00:00Z",
        weight_kg:            "1500.0",
        volume_cm3:           3_000_000,
        declared_value_cents: 5_000_000,
        distance_km:          null,
        cancelled_at:         null,
        created_at:           "",
        updated_at:           "",
        editable:             true,
        pending_offers_count: 0,
        cargo_offers:         [],
        ...over,
    };
}

function makeMatch(over: Partial<CargoMatch> = {}): CargoMatch {
    return {
        id:                     5,
        origin_address:         "La Plata",
        origin_locality:        "La Plata",
        origin_admin_area:      "Buenos Aires",
        origin_lat:             "-34.921450",
        origin_lng:             "-57.954529",
        destination_address:    "Córdoba",
        destination_locality:   "Córdoba",
        destination_admin_area: "Córdoba",
        destination_lat:        "-31.420083",
        destination_lng:        "-64.188776",
        pickup_radius_km:       10,
        dropoff_radius_km:      10,
        price_per_km:           "1500.0",
        max_km:                 1000,
        available_from:         "2026-05-25T00:00:00Z",
        available_to:           "2026-06-10T00:00:00Z",
        active:                 true,
        vehicle: {
            id:          10,
            make:        "Volvo",
            model:       "FH",
            plate:       "AB123CD",
            max_load_kg: "8000.0",
        },
        carrier: { id: 1, display_name: "Transportes del Sur", rating_avg: "4.7", reviews_count: 5 },
        ...over,
    };
}

function matchResult(items: CargoMatch[]) {
    return {
        items,
        meta: { total: items.length, page: 1, perPage: 20, totalPages: 1 },
    };
}

function renderScreen(id = 7) {
    return render(
        <MemoryRouter initialEntries={[`/shipper/cargos/${id}/matches`]}>
            <Routes>
                <Route
                    path="/shipper/cargos/:id/matches"
                    element={<CargoMatches />}
                />
                <Route
                    path="/shipper/cargos/:id"
                    element={<div>cargo-detail</div>}
                />
                <Route
                    path="/shipper/cargos/:id/offers/new"
                    element={<div>offer-screen</div>}
                />
            </Routes>
        </MemoryRouter>,
    );
}

beforeEach(() => {
    vi.resetAllMocks();
});

describe("CargoMatches — open cargo", () => {
    it("pins the selected-cargo card and lists matches", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        api.getMatches.mockResolvedValue(matchResult([makeMatch()]));
        renderScreen();
        expect(
            await screen.findByText("Carga seleccionada"),
        ).toBeInTheDocument();
        expect(
            screen.getByText("Pallets de electrodomésticos"),
        ).toBeInTheDocument();
        expect(
            await screen.findByText("Transportes del Sur"),
        ).toBeInTheDocument();
    });

    it("shows the empty state when there are no matches", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        api.getMatches.mockResolvedValue(matchResult([]));
        renderScreen();
        expect(
            await screen.findByText(
                "Todavía no hay transportistas compatibles con esta carga.",
            ),
        ).toBeInTheDocument();
    });

    it("each match card links into the cargo-scoped offer flow", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        api.getMatches.mockResolvedValue(matchResult([makeMatch()]));
        const user = userEvent.setup();
        renderScreen();
        await user.click(
            await screen.findByRole("link", {
                name: /Ofertar para el tramo/,
            }),
        );
        expect(await screen.findByText("offer-screen")).toBeInTheDocument();
    });
});

describe("CargoMatches — pagination", () => {
    it("shows the total compatible-carrier count above the list", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        api.getMatches.mockResolvedValue({
            items: [makeMatch()],
            meta: { total: 23, page: 1, perPage: 20, totalPages: 2 },
        });
        renderScreen();
        expect(
            await screen.findByText("23 transportistas compatibles"),
        ).toBeInTheDocument();
    });

    it("singularises the count for a lone compatible carrier", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        api.getMatches.mockResolvedValue(matchResult([makeMatch()]));
        renderScreen();
        expect(
            await screen.findByText("1 transportista compatible"),
        ).toBeInTheDocument();
    });

    it("steps to the next page and requests it from the API", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        api.getMatches.mockImplementation((_id, page = 1) =>
            Promise.resolve({
                items: [
                    makeMatch({
                        id: page,
                        carrier: {
                            id: page,
                            display_name: page === 1 ? "Primera" : "Segunda",
                            rating_avg: "4.7",
                            reviews_count: 5,
                        },
                    }),
                ],
                meta: { total: 23, page, perPage: 20, totalPages: 2 },
            }),
        );
        const user = userEvent.setup();
        renderScreen();

        expect(await screen.findByText("Primera")).toBeInTheDocument();
        expect(screen.getByText("Página 1 de 2")).toBeInTheDocument();
        expect(
            screen.getByRole("button", { name: "← Anterior" }),
        ).toBeDisabled();

        await user.click(screen.getByRole("button", { name: "Siguiente →" }));

        expect(await screen.findByText("Segunda")).toBeInTheDocument();
        expect(screen.getByText("Página 2 de 2")).toBeInTheDocument();
        expect(api.getMatches).toHaveBeenLastCalledWith(7, 2);
    });

    it("omits the paginator when the results fit on one page", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        api.getMatches.mockResolvedValue(matchResult([makeMatch()]));
        renderScreen();
        await screen.findByText("Transportes del Sur");
        expect(
            screen.queryByRole("navigation", {
                name: "Paginación de transportistas",
            }),
        ).not.toBeInTheDocument();
    });
});

describe("CargoMatches — non-open cargo", () => {
    it("shows the not-open notice and skips the matches request", async () => {
        api.getCargo.mockResolvedValue(
            makeCargo({ status: "cancelled", editable: false }),
        );
        renderScreen();
        expect(
            await screen.findByText("Esta carga ya no está abierta"),
        ).toBeInTheDocument();
        expect(api.getMatches).not.toHaveBeenCalled();
    });
});

describe("CargoMatches — error states", () => {
    it("renders an error panel and retries the cargo load", async () => {
        api.getCargo.mockRejectedValueOnce(new Error("down"));
        const user = userEvent.setup();
        renderScreen();
        expect(
            await screen.findByText(/No pudimos cargar esta carga/),
        ).toBeInTheDocument();

        api.getCargo.mockResolvedValueOnce(makeCargo());
        api.getMatches.mockResolvedValue(matchResult([]));
        await user.click(screen.getByRole("button", { name: "Reintentar" }));
        expect(
            await screen.findByRole("heading", {
                name: "Transportistas disponibles",
            }),
        ).toBeInTheDocument();
    });

    it("shows a matches error when the matches request fails", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        api.getMatches.mockRejectedValue(new Error("boom"));
        renderScreen();
        expect(
            await screen.findByText("No pudimos buscar transportistas"),
        ).toBeInTheDocument();
    });
});
