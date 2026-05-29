import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import CreateOfferPage from "./CreateOfferPage";
import * as cargoOffersApi from "../../api/cargoOffers";
import * as cargoApi from "../../features/cargo/api";
import type { Cargo, CargoMatch } from "../../types/Cargo";

vi.mock("../../api/cargoOffers");
vi.mock("../../features/cargo/api");

const offers = vi.mocked(cargoOffersApi);
const cargo = vi.mocked(cargoApi);

function fakeCargo(over: Partial<Cargo> = {}): Cargo {
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

function fakeWindow(over: Partial<CargoMatch> = {}): CargoMatch {
    return {
        id:                     5,
        origin_address:         "Av. Corrientes 1234, CABA",
        origin_locality:        "CABA",
        origin_admin_area:      "Buenos Aires",
        origin_lat:             "-34.603722",
        origin_lng:             "-58.381592",
        destination_address:    "Av. Colón 500, Córdoba",
        destination_locality:   "Córdoba",
        destination_admin_area: "Córdoba",
        destination_lat:        "-31.420083",
        destination_lng:        "-64.188776",
        pickup_radius_km:       10,
        dropoff_radius_km:      10,
        price_per_km:           "1500",
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
        carrier: { id: 1, display_name: "Transportes del Sur", rating_avg: "4.7" },
        ...over,
    };
}

type MountOpts = { state?: object | null };

function mount({ state = { window: fakeWindow() } }: MountOpts = {}) {
    return render(
        <MemoryRouter
            initialEntries={[
                {
                    pathname: "/shipper/cargos/7/offers/new",
                    search: "?window=5",
                    state,
                },
            ]}
        >
            <Routes>
                <Route
                    path="/shipper/cargos/:id/offers/new"
                    element={<CreateOfferPage />}
                />
                <Route
                    path="/shipper/cargos/:id"
                    element={<div>cargo-detail</div>}
                />
            </Routes>
        </MemoryRouter>,
    );
}

beforeEach(() => {
    vi.resetAllMocks();
});

describe("CreateOfferPage — cargo-scoped confirm step", () => {
    it("renders read-only cargo and window summaries", async () => {
        cargo.getCargo.mockResolvedValue(fakeCargo());
        mount();
        expect(
            await screen.findByText("Confirmar oferta"),
        ).toBeInTheDocument();
        expect(screen.getByText("Tu carga")).toBeInTheDocument();
        expect(
            screen.getByText("Ventana de transporte"),
        ).toBeInTheDocument();
        expect(
            screen.getByText("Transportista: Transportes del Sur"),
        ).toBeInTheDocument();
    });

    it("refetches the window from matches when router state is missing", async () => {
        cargo.getCargo.mockResolvedValue(fakeCargo());
        cargo.getMatches.mockResolvedValue({
            items: [fakeWindow()],
            meta: { total: 1, page: 1, perPage: 20, totalPages: 1 },
        });
        mount({ state: null });
        expect(
            await screen.findByText("Confirmar oferta"),
        ).toBeInTheDocument();
        expect(cargo.getMatches).toHaveBeenCalledWith(7);
    });

    it("shows the load error when the window cannot be resolved", async () => {
        cargo.getCargo.mockResolvedValue(fakeCargo());
        cargo.getMatches.mockResolvedValue({
            items: [],
            meta: { total: 0, page: 1, perPage: 20, totalPages: 1 },
        });
        mount({ state: null });
        expect(
            await screen.findByText(/No pudimos cargar la carga/),
        ).toBeInTheDocument();
    });

    it("validates a positive estimated_km", async () => {
        cargo.getCargo.mockResolvedValue(fakeCargo());
        const user = userEvent.setup();
        mount();
        await screen.findByText("Confirmar oferta");
        await user.click(
            screen.getByRole("button", { name: "Enviar oferta" }),
        );
        expect(
            screen.getByText(/Ingresá una cantidad de kilómetros/),
        ).toBeInTheDocument();
        expect(offers.createCargoOffer).not.toHaveBeenCalled();
    });

    it("shows the cost estimate once km are entered", async () => {
        cargo.getCargo.mockResolvedValue(fakeCargo());
        const user = userEvent.setup();
        mount();
        await screen.findByText("Confirmar oferta");
        await user.type(
            screen.getByLabelText("Kilómetros estimados del viaje"),
            "700",
        );
        // 700 km × $1500/km = $1.050.000
        expect(screen.getByTestId("cost-estimate")).toHaveTextContent(
            "1.050.000",
        );
    });

    it("posts cargo_id + offer fields and redirects to the cargo detail", async () => {
        cargo.getCargo.mockResolvedValue(fakeCargo());
        offers.createCargoOffer.mockResolvedValue({
            id: 1,
            cargo_id: 7,
            carrier_id: 1,
            transport_window_id: 5,
            amount_cents: 105_000_000,
            currency: "ARS",
            status: "pending",
            expires_at: "2026-05-27T10:00:00Z",
            created_at: "",
            updated_at: "",
        });
        const user = userEvent.setup();
        mount();
        await screen.findByText("Confirmar oferta");
        await user.type(
            screen.getByLabelText("Kilómetros estimados del viaje"),
            "700",
        );
        await user.click(
            screen.getByRole("button", { name: "Enviar oferta" }),
        );
        await waitFor(() =>
            expect(screen.getByText("cargo-detail")).toBeInTheDocument()
        );
        expect(offers.createCargoOffer).toHaveBeenCalledWith(7, {
            transport_window_id: 5,
            estimated_km: "700",
        });
    });

    it("shows an error alert when the offer submit fails", async () => {
        cargo.getCargo.mockResolvedValue(fakeCargo());
        const { ApiError } = await import("../../api");
        offers.createCargoOffer.mockRejectedValue(
            new ApiError(422, "unprocessable", "unprocessable", {}),
        );
        const user = userEvent.setup();
        mount();
        await screen.findByText("Confirmar oferta");
        await user.type(
            screen.getByLabelText("Kilómetros estimados del viaje"),
            "700",
        );
        await user.click(
            screen.getByRole("button", { name: "Enviar oferta" }),
        );
        expect(
            await screen.findByText(/No se pudo enviar la oferta/),
        ).toBeInTheDocument();
    });
});
