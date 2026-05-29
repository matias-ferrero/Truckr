import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { MyCargosSection } from "./MyCargosSection";
import * as cargoApi from "../../features/cargo/api";
import type { Cargo } from "../../types/Cargo";

vi.mock("../../features/cargo/api");

const api = vi.mocked(cargoApi);

function makeCargo(over: Partial<Cargo> = {}): Cargo {
    return {
        id:                   1,
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
        volume_cm3:           null,
        declared_value_cents: 5_000_000,
        cancelled_at:         null,
        created_at:           "",
        updated_at:           "",
        editable:             true,
        pending_offers_count: 0,
        cargo_offers:         [],
        ...over,
    };
}

function listResult(items: Cargo[]) {
    return {
        items,
        meta: { total: items.length, page: 1, perPage: 20, totalPages: 1 },
    };
}

const renderSection = () =>
    render(
        <MemoryRouter>
            <MyCargosSection />
        </MemoryRouter>,
    );

beforeEach(() => {
    vi.resetAllMocks();
});

describe("MyCargosSection", () => {
    it("renders the section heading", () => {
        api.listCargos.mockReturnValue(new Promise(() => {}));
        renderSection();
        expect(
            screen.getByRole("heading", { level: 2, name: "Mis cargas" }),
        ).toBeInTheDocument();
    });

    it("groups cargos into labeled status swimlanes", async () => {
        api.listCargos.mockResolvedValue(
            listResult([
                makeCargo({ id: 1, status: "open" }),
                makeCargo({ id: 2, status: "accepted", editable: false }),
                makeCargo({ id: 3, status: "cancelled", editable: false }),
            ]),
        );
        renderSection();
        expect(await screen.findByText(/Abiertas · 1/)).toBeInTheDocument();
        expect(screen.getByText(/Aceptadas · 1/)).toBeInTheDocument();
        expect(screen.getByText(/Canceladas · 1/)).toBeInTheDocument();
    });

    it("links an open cargo to its matches screen, with a separate detail link", async () => {
        api.listCargos.mockResolvedValue(
            listResult([makeCargo({ id: 9, status: "open" })]),
        );
        renderSection();
        const search = await screen.findByRole("link", {
            name: /Buscar transportistas para la carga/,
        });
        expect(search).toHaveAttribute("href", "/shipper/cargos/9/matches");
        expect(
            screen.getByRole("link", { name: "Ver detalle" }),
        ).toHaveAttribute("href", "/shipper/cargos/9");
    });

    it("links a non-open cargo straight to its detail screen", async () => {
        api.listCargos.mockResolvedValue(
            listResult([
                makeCargo({ id: 4, status: "cancelled", editable: false }),
            ]),
        );
        renderSection();
        const link = await screen.findByRole("link", {
            name: /Ver el detalle de la carga/,
        });
        expect(link).toHaveAttribute("href", "/shipper/cargos/4");
    });

    it("hoists open cargos with no pending offers above those with offers", async () => {
        api.listCargos.mockResolvedValue(
            listResult([
                makeCargo({ id: 1, status: "open", pending_offers_count: 2 }),
                makeCargo({ id: 2, status: "open", pending_offers_count: 0 }),
            ]),
        );
        renderSection();
        const cards = await screen.findAllByRole("link", {
            name: /Buscar transportistas para la carga/,
        });
        expect(cards[0]).toHaveAttribute("href", "/shipper/cargos/2/matches");
        expect(cards[1]).toHaveAttribute("href", "/shipper/cargos/1/matches");
    });

    it("shows the empty state with a publish CTA when there are no cargos", async () => {
        api.listCargos.mockResolvedValue(listResult([]));
        renderSection();
        expect(
            await screen.findByText("Todavía no publicaste cargas"),
        ).toBeInTheDocument();
        expect(
            screen.getByRole("link", { name: "Publicar carga" }),
        ).toHaveAttribute("href", "/shipper/cargos/new");
    });

    it("shows an error state with retry when the request fails", async () => {
        api.listCargos.mockRejectedValue(new Error("boom"));
        renderSection();
        expect(
            await screen.findByText("No pudimos cargar tus cargas"),
        ).toBeInTheDocument();
        expect(
            screen.getByRole("button", { name: "Reintentar" }),
        ).toBeInTheDocument();
    });
});
