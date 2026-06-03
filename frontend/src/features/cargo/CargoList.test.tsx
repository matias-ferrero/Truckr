import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter } from "react-router-dom";
import CargoList from "./CargoList";
import * as cargoApi from "./api";
import type { Cargo } from "../../types/Cargo";

vi.mock("./api");

const api = vi.mocked(cargoApi);

function makeCargo(over: Partial<Cargo> = {}): Cargo {
    return {
        id:                   1,
        shipper_id:           1,
        status:               "open",
        cargo_description:    "Pallets de electrodomésticos",
        pickup_address:       "Calle 1",
        pickup_lat:           "-34.603722",
        pickup_lng:           "-58.381592",
        pickup_locality:      "CABA",
        pickup_admin_area:    "Buenos Aires",
        delivery_address:     "Calle 2",
        delivery_lat:         "-31.420083",
        delivery_lng:         "-64.188776",
        delivery_locality:    "Córdoba",
        delivery_admin_area:  "Córdoba",
        pickup_window_start:  "2026-06-01T08:00:00Z",
        pickup_window_end:    "2026-06-03T18:00:00Z",
        weight_kg:            "1500.0",
        volume_cm3:           3_000_000,
        declared_value_cents: 5_000_000,
        cancelled_at:         null,
        created_at:           "2026-05-20T10:00:00Z",
        updated_at:           "2026-05-20T10:00:00Z",
        editable:             true,
        pending_offers_count: 0,
        cargo_offers:         [],
        ...over,
    };
}

function result(items: Cargo[], totalPages = 1) {
    return {
        items,
        meta: { total: items.length, page: 1, perPage: 20, totalPages },
    };
}

function renderList() {
    return render(
        <MemoryRouter>
            <CargoList />
        </MemoryRouter>,
    );
}

beforeEach(() => {
    vi.resetAllMocks();
});

describe("CargoList", () => {
    it("renders the heading and publish CTA", async () => {
        api.listCargos.mockResolvedValue(result([]));
        renderList();
        expect(
            await screen.findByRole("heading", { name: "Mis cargas" }),
        ).toBeInTheDocument();
        expect(
            screen.getByRole("link", { name: "Publicar carga" }),
        ).toBeInTheDocument();
    });

    it("shows the empty state with a first-cargo CTA", async () => {
        api.listCargos.mockResolvedValue(result([]));
        renderList();
        expect(
            await screen.findByText("Todavía no publicaste cargas"),
        ).toBeInTheDocument();
        expect(
            screen.getByRole("link", { name: "Publicá tu primera carga" }),
        ).toBeInTheDocument();
    });

    it("renders a cargo card with route, status and pending offers", async () => {
        api.listCargos.mockResolvedValue(
            result([makeCargo({ pending_offers_count: 2 })]),
        );
        renderList();
        const route = await screen.findByText("CABA, Buenos Aires → Córdoba");
        expect(route).toBeInTheDocument();
        // "Abierta" also appears as a filter option — scope to the card badge.
        const card = route.closest("li") as HTMLElement;
        expect(within(card).getByText("Abierta")).toBeInTheDocument();
        expect(screen.getByText("2 ofertas pendientes")).toBeInTheDocument();
    });

    it("shows the no-offers label when there are no pending offers", async () => {
        api.listCargos.mockResolvedValue(result([makeCargo()]));
        renderList();
        expect(
            await screen.findByText("Sin ofertas todavía"),
        ).toBeInTheDocument();
    });

    it("refetches with the status filter when changed", async () => {
        api.listCargos.mockResolvedValue(result([makeCargo()]));
        const user = userEvent.setup();
        renderList();
        await screen.findByText("CABA, Buenos Aires → Córdoba");

        await user.selectOptions(
            screen.getByLabelText("Filtrar por estado"),
            "Cancelada",
        );
        await waitFor(() =>
            expect(api.listCargos).toHaveBeenLastCalledWith("cancelled", 1)
        );
    });

    it("renders an error panel and retries on click", async () => {
        api.listCargos.mockRejectedValueOnce(new Error("network down"));
        const user = userEvent.setup();
        renderList();
        expect(
            await screen.findByText(/No pudimos cargar tus cargas/),
        ).toBeInTheDocument();

        api.listCargos.mockResolvedValueOnce(result([makeCargo()]));
        await user.click(screen.getByRole("button", { name: "Reintentar" }));
        expect(
            await screen.findByText("CABA, Buenos Aires → Córdoba"),
        ).toBeInTheDocument();
    });

    it("paginates when there is more than one page", async () => {
        api.listCargos.mockResolvedValue(result([makeCargo()], 3));
        const user = userEvent.setup();
        renderList();
        await screen.findByText("CABA, Buenos Aires → Córdoba");

        await user.click(screen.getByRole("button", { name: /Siguiente/ }));
        await waitFor(() =>
            expect(api.listCargos).toHaveBeenLastCalledWith(undefined, 2)
        );
    });
});
