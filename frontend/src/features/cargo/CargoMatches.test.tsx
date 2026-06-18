import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, within } from "@testing-library/react";
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
        distance_km:          "700.0",
        cancelled_at:         null,
        created_at:           "",
        updated_at:           "",
        editable:             true,
        pending_offers_count: 0,
        cargo_offers:         [],
        ...over,
    };
}

let nextMatchId = 1;

function makeMatch(over: Partial<CargoMatch> = {}): CargoMatch {
    const id = nextMatchId++;
    return {
        id,
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
        carrier: {
            id:            id,
            display_name:  `Transportes ${id} SRL`,
            rating_avg:    "4.7",
            reviews_count: 5,
        },
        ...over,
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
                <Route
                    path="/carriers/:id"
                    element={<div>carrier-profile</div>}
                />
            </Routes>
        </MemoryRouter>,
    );
}

beforeEach(() => {
    vi.resetAllMocks();
    nextMatchId = 1;
});

describe("CargoMatches — open cargo", () => {
    it("pins the cargo context bar and lists matches", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        api.getMatches.mockResolvedValue([makeMatch()]);
        renderScreen();
        expect(await screen.findByText("Tu carga")).toBeInTheDocument();
        expect(
            await screen.findByText("Transportes 1 SRL"),
        ).toBeInTheDocument();
    });

    it("shows the empty state with an edit nudge when there are no matches", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        api.getMatches.mockResolvedValue([]);
        renderScreen();
        expect(
            await screen.findByText(
                "Todavía no hay transportistas compatibles",
            ),
        ).toBeInTheDocument();
        expect(
            screen.getByRole("link", { name: "Editar la carga" }),
        ).toBeInTheDocument();
    });

    it("each match card links into the cargo-scoped offer flow", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        api.getMatches.mockResolvedValue([makeMatch()]);
        const user = userEvent.setup();
        renderScreen();
        await user.click(
            await screen.findByRole("link", { name: /Enviar oferta a/ }),
        );
        expect(await screen.findByText("offer-screen")).toBeInTheDocument();
    });
});

describe("CargoMatches — Recomendados strip", () => {
    it("suppresses the strip at three or fewer matches", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        api.getMatches.mockResolvedValue([
            makeMatch(),
            makeMatch(),
            makeMatch(),
        ]);
        renderScreen();
        await screen.findByText("Transportes 1 SRL");
        expect(screen.queryByText("Recomendados")).not.toBeInTheDocument();
    });

    it("shows distinct cheapest / best-rated / soonest picks above the grid", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        api.getMatches.mockResolvedValue([
            makeMatch({ price_per_km: "1.0", available_from: "2026-05-28T00:00:00Z" }),
            makeMatch({
                price_per_km: "2.0",
                carrier: { id: 90, display_name: "Premium SRL", rating_avg: "4.9", reviews_count: 12 },
            }),
            makeMatch({ price_per_km: "3.0", available_from: "2026-05-20T00:00:00Z" }),
            makeMatch({ price_per_km: "4.0" }),
        ]);
        renderScreen();
        const strip = (await screen.findByText("Recomendados"))
            .closest("section") as HTMLElement;
        expect(within(strip).getByText("Más barato")).toBeInTheDocument();
        expect(within(strip).getByText("Mejor calificado")).toBeInTheDocument();
        expect(within(strip).getByText("Más próximo")).toBeInTheDocument();
        expect(within(strip).getByText("Premium SRL")).toBeInTheDocument();
    });

    it("omits the best-rated pick when no carrier has reviews", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        const unrated = { rating_avg: "0.0", reviews_count: 0 };
        api.getMatches.mockResolvedValue([
            makeMatch({ price_per_km: "1.0", carrier: { id: 1, display_name: "A", ...unrated } }),
            makeMatch({ price_per_km: "2.0", carrier: { id: 2, display_name: "B", ...unrated } }),
            makeMatch({ price_per_km: "3.0", carrier: { id: 3, display_name: "C", ...unrated } }),
            makeMatch({ price_per_km: "4.0", carrier: { id: 4, display_name: "D", ...unrated } }),
        ]);
        renderScreen();
        await screen.findByText("Recomendados");
        expect(screen.queryByText("Mejor calificado")).not.toBeInTheDocument();
        // The badge legitimately appears twice: in the strip and on the
        // matching grid card (picked rows stay visible in the grid).
        expect(screen.getAllByText("Más barato").length).toBeGreaterThan(0);
    });
});

describe("CargoMatches — sort and filter", () => {
    it("re-orders the grid when the sort changes", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        api.getMatches.mockResolvedValue([
            makeMatch({ price_per_km: "1.0", carrier: { id: 1, display_name: "Barato SRL", rating_avg: "3.0", reviews_count: 1 } }),
            makeMatch({ price_per_km: "9.0", carrier: { id: 2, display_name: "Caro SRL", rating_avg: "5.0", reviews_count: 9 } }),
        ]);
        const user = userEvent.setup();
        renderScreen();
        await screen.findByText("Barato SRL");

        let names = screen.getAllByRole("listitem")
            .map((li) => li.textContent ?? "");
        expect(names.findIndex((s) => s.includes("Barato SRL")))
            .toBeLessThan(names.findIndex((s) => s.includes("Caro SRL")));

        await user.selectOptions(
            screen.getByLabelText("Ordenar por"),
            "rating-desc",
        );
        names = screen.getAllByRole("listitem")
            .map((li) => li.textContent ?? "");
        expect(names.findIndex((s) => s.includes("Caro SRL")))
            .toBeLessThan(names.findIndex((s) => s.includes("Barato SRL")));
    });

    it("filters by max price and shows the filtered count", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        api.getMatches.mockResolvedValue([
            makeMatch({ price_per_km: "1.0" }), // total 700
            makeMatch({ price_per_km: "9.0" }), // total 6300
        ]);
        const user = userEvent.setup();
        renderScreen();
        await screen.findByText("Transportes 1 SRL");

        await user.type(screen.getByLabelText("Precio máximo"), "1000");
        expect(screen.getByText("1 de 2 compatibles")).toBeInTheDocument();
        expect(screen.queryByText("Transportes 2 SRL")).not.toBeInTheDocument();

        await user.click(
            screen.getByRole("button", { name: "Limpiar filtros" }),
        );
        expect(await screen.findByText("Transportes 2 SRL")).toBeInTheDocument();
    });

    it("shows the no-results hint when filters exclude everything", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        api.getMatches.mockResolvedValue([makeMatch({ price_per_km: "9.0" })]);
        const user = userEvent.setup();
        renderScreen();
        await screen.findByText("Transportes 1 SRL");

        await user.type(screen.getByLabelText("Precio máximo"), "1");
        expect(
            screen.getByText(/Ningún transportista entra en esos filtros/),
        ).toBeInTheDocument();
    });
});

describe("CargoMatches — pagination", () => {
    it("paginates the grid client-side", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        api.getMatches.mockResolvedValue(
            Array.from({ length: 15 }, (_, i) =>
                makeMatch({ price_per_km: String(i + 1) })),
        );
        const user = userEvent.setup();
        renderScreen();
        // The cheapest match shows twice (pick + grid card) — wait on either.
        await screen.findAllByText("Transportes 1 SRL");
        expect(screen.getByText("Página 1 de 2")).toBeInTheDocument();
        expect(screen.queryByText("Transportes 15 SRL")).not.toBeInTheDocument();

        await user.click(screen.getByRole("button", { name: "Siguiente →" }));
        expect(await screen.findByText("Transportes 15 SRL")).toBeInTheDocument();
        expect(screen.getByText("Página 2 de 2")).toBeInTheDocument();
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
        api.getMatches.mockResolvedValue([]);
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
