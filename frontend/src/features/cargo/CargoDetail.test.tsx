import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import CargoDetail from "./CargoDetail";
import * as cargoApi from "./api";
import type { Cargo, CargoOffer } from "../../types/Cargo";

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
        cancelled_at:         null,
        created_at:           "",
        updated_at:           "",
        editable:             true,
        pending_offers_count: 0,
        cargo_offers:         [],
        ...over,
    };
}

function makeOffer(over: Partial<CargoOffer> = {}): CargoOffer {
    return {
        id:                  11,
        cargo_id:            7,
        carrier_id:          1,
        transport_window_id: 5,
        amount_cents:        105_000_000,
        currency:            "ARS",
        status:              "pending",
        expires_at:          "2026-05-27T10:00:00Z",
        created_at:          "",
        updated_at:          "",
        transport_window: {
            id:                     5,
            origin_locality:        "CABA",
            origin_admin_area:      "Buenos Aires",
            destination_locality:   "Córdoba",
            destination_admin_area: "Córdoba",
            available_from:         "2026-05-25T00:00:00Z",
            available_to:           "2026-06-10T00:00:00Z",
        },
        ...over,
    };
}

function renderDetail(id = 7) {
    return render(
        <MemoryRouter initialEntries={[`/shipper/cargos/${id}`]}>
            <Routes>
                <Route path="/shipper/cargos/:id" element={<CargoDetail />} />
                <Route path="/shipper/cargos" element={<div>cargo-list</div>} />
            </Routes>
        </MemoryRouter>,
    );
}

beforeEach(() => {
    vi.resetAllMocks();
});

describe("CargoDetail — open cargo", () => {
    it("renders the summary and shows search/edit/cancel actions", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        renderDetail();
        expect(
            await screen.findByRole("heading", {
                name: "CABA, Buenos Aires → Córdoba, Córdoba",
            }),
        ).toBeInTheDocument();
        expect(
            screen.getByRole("link", { name: "Buscar transportistas" }),
        ).toBeInTheDocument();
        expect(
            screen.getByRole("link", { name: "Editar" }),
        ).toBeInTheDocument();
        expect(
            screen.getByRole("button", { name: "Cancelar carga" }),
        ).toBeInTheDocument();
    });

    it("the search-carriers shortcut targets the cargo-scoped matches route", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        renderDetail();
        const link = await screen.findByRole("link", {
            name: "Buscar transportistas",
        });
        expect(link).toHaveAttribute("href", "/shipper/cargos/7/matches");
    });

    it("shows the offers empty state when there are no offers", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        renderDetail();
        expect(
            await screen.findByText(
                "Todavía no enviaste ofertas para esta carga.",
            ),
        ).toBeInTheDocument();
    });

    it("lists nested offers with status and route", async () => {
        api.getCargo.mockResolvedValue(
            makeCargo({ cargo_offers: [makeOffer()] }),
        );
        renderDetail();
        const offersSection = await screen.findByRole("region", {
            name: "Mis ofertas",
        });
        expect(within(offersSection).getByText("Pendiente"))
            .toBeInTheDocument();
        expect(
            within(offersSection).getByText("CABA, Buenos Aires → Córdoba, Córdoba"),
        ).toBeInTheDocument();
    });
});

describe("CargoDetail — accepted cargo", () => {
    it("shows the winning-carrier block and no edit actions", async () => {
        api.getCargo.mockResolvedValue(
            makeCargo({
                status: "accepted",
                editable: false,
                cargo_offers: [makeOffer({ status: "accepted" })],
            }),
        );
        renderDetail();
        expect(
            await screen.findByText("Oferta aceptada"),
        ).toBeInTheDocument();
        expect(
            screen.queryByRole("button", { name: "Cancelar carga" }),
        ).not.toBeInTheDocument();
        expect(
            screen.queryByRole("link", { name: "Buscar transportistas" }),
        ).not.toBeInTheDocument();
    });
});

describe("CargoDetail — cancelled cargo", () => {
    it("shows the cancelled badge and no actions", async () => {
        api.getCargo.mockResolvedValue(
            makeCargo({
                status: "cancelled",
                editable: false,
                cancelled_at: "2026-05-21T10:00:00Z",
            }),
        );
        renderDetail();
        expect(await screen.findByText("Cancelada")).toBeInTheDocument();
        expect(screen.getByText(/Cancelada el/)).toBeInTheDocument();
        expect(
            screen.queryByRole("link", { name: "Editar" }),
        ).not.toBeInTheDocument();
    });
});

describe("CargoDetail — cancel modal", () => {
    it("opens the confirm dialog and cancels the cargo", async () => {
        api.getCargo
            .mockResolvedValueOnce(makeCargo())
            .mockResolvedValueOnce(makeCargo({ status: "cancelled" }));
        api.cancelCargo.mockResolvedValue(undefined);
        const user = userEvent.setup();
        renderDetail();

        await user.click(
            await screen.findByRole("button", { name: "Cancelar carga" }),
        );
        const dialog = await screen.findByRole("dialog");
        expect(dialog).toHaveTextContent("Cancelar esta carga");

        await user.click(
            screen.getByRole("button", { name: "Sí, cancelar carga" }),
        );
        await waitFor(() =>
            expect(api.cancelCargo).toHaveBeenCalledWith(7, undefined)
        );
    });

    it("passes the typed reason to cancelCargo", async () => {
        api.getCargo
            .mockResolvedValueOnce(makeCargo())
            .mockResolvedValueOnce(makeCargo({ status: "cancelled" }));
        api.cancelCargo.mockResolvedValue(undefined);
        const user = userEvent.setup();
        renderDetail();

        await user.click(
            await screen.findByRole("button", { name: "Cancelar carga" }),
        );
        await user.type(
            screen.getByLabelText("Motivo (opcional)"),
            "ya no la necesito",
        );
        await user.click(
            screen.getByRole("button", { name: "Sí, cancelar carga" }),
        );
        await waitFor(() =>
            expect(api.cancelCargo).toHaveBeenCalledWith(
                7,
                "ya no la necesito",
            )
        );
    });

    it("shows an error inside the dialog when cancel fails", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        api.cancelCargo.mockRejectedValue(new Error("boom"));
        const user = userEvent.setup();
        renderDetail();

        await user.click(
            await screen.findByRole("button", { name: "Cancelar carga" }),
        );
        await user.click(
            screen.getByRole("button", { name: "Sí, cancelar carga" }),
        );
        expect(
            await screen.findByText(/No pudimos cancelar la carga/),
        ).toBeInTheDocument();
    });
});

describe("CargoDetail — error state", () => {
    it("renders an error panel and retries", async () => {
        api.getCargo.mockRejectedValueOnce(new Error("down"));
        const user = userEvent.setup();
        renderDetail();
        expect(
            await screen.findByText(/No pudimos cargar esta carga/),
        ).toBeInTheDocument();

        api.getCargo.mockResolvedValueOnce(makeCargo());
        await user.click(screen.getByRole("button", { name: "Reintentar" }));
        expect(
            await screen.findByRole("heading", {
                name: "CABA, Buenos Aires → Córdoba, Córdoba",
            }),
        ).toBeInTheDocument();
    });
});
