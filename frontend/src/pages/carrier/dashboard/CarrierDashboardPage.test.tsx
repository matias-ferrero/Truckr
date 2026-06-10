import { beforeEach, describe, expect, it, vi } from "vitest";
import { render, screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import CarrierDashboardPage from "./CarrierDashboardPage";
import * as offersApi from "../../../api/carrierCargoOffers";
import * as shipmentsApi from "../../../api/shipments";
import * as vehiclesApi from "../../../api/vehicles";
import * as windowsApi from "../../../api/transport_windows";
import * as currentUser from "../../../auth/useCurrentUser";
import type { CarrierCargoOffer } from "../../../api/carrierCargoOffers";
import type { CarrierActivityEvent, Shipment } from "../../../api/shipments";
import type { TransportWindow } from "../../../api/transport_windows";
import type { Me } from "../../../auth/AuthContext";

vi.mock("../../../api/carrierCargoOffers");
vi.mock("../../../api/shipments");
vi.mock("../../../api/vehicles");
vi.mock("../../../api/transport_windows");
vi.mock("../../../auth/useCurrentUser");

const offers = vi.mocked(offersApi);
const shipments = vi.mocked(shipmentsApi);
const vehicles = vi.mocked(vehiclesApi);
const windows = vi.mocked(windowsApi);
const auth = vi.mocked(currentUser);

// --- fixtures -------------------------------------------------------------

function makeMe(overrides: Partial<Me> = {}): Me {
    return {
        id: 1,
        email: "pedro@truckr.test",
        full_name: "Pedro Gómez",
        roles: ["carrier"],
        carrier: { id: 7, rating_avg: "4.8", reviews_count: 21 },
        ...overrides,
    };
}

function mockUser(me: Me | null = makeMe()) {
    auth.useCurrentUser.mockReturnValue({
        me,
        loading: false,
        register: vi.fn(),
        login: vi.fn(),
        logout: vi.fn(),
        updateMe: vi.fn(),
    });
}

const IN_A_WEEK = new Date(Date.now() + 7 * 24 * 3600_000).toISOString();
const IN_TWO_HOURS = new Date(Date.now() + 2 * 3600_000).toISOString();

function makeOffer(overrides: Partial<CarrierCargoOffer> = {}): CarrierCargoOffer {
    return {
        id: 901,
        cargo_id: 1,
        carrier_id: 7,
        transport_window_id: 1,
        status: "pending",
        expires_at: IN_A_WEEK,
        accepted_at: null,
        rejected_at: null,
        created_at: "2026-06-09T10:00:00Z",
        updated_at: "2026-06-09T10:00:00Z",
        price_amount_cents: 2_500_000,
        cargo: {
            id: 1,
            pickup_address: "Av. Corrientes 1234, CABA",
            delivery_address: "Av. Colón 500, Córdoba",
            pickup_locality: "CABA",
            delivery_locality: "Córdoba",
            weight_kg: "1500",
            volume_cm3: null,
            declared_value_cents: 5_000_000,
            pickup_window_start: "2026-06-12T08:00:00Z",
            pickup_window_end: "2026-06-14T18:00:00Z",
            cargo_description: "Pallets",
            status: "open",
            distance_km: "700",
        },
        shipper: { id: 3, name: "Agro SA", rating_avg: "4.5", reviews_count: 12 },
        transport_window: {
            id: 1,
            origin_locality: "CABA",
            origin_admin_area: "CABA",
            destination_locality: "Córdoba",
            destination_admin_area: "Córdoba",
            available_from: "2026-06-12T00:00:00Z",
            available_to: "2026-06-16T00:00:00Z",
            price_per_km: "1000",
            max_km: 900,
            status: "pending_offer",
        },
        ...overrides,
    };
}

function makeShipment(overrides: Partial<Shipment> = {}): Shipment {
    return {
        id: 42,
        state: "accepted",
        origin: "Rosario",
        destination: "Mendoza",
        created_at: "2026-06-09T10:00:00Z",
        amount_cents: 10_000_000,
        currency: "ARS",
        latest_activity_at: "2026-06-09T10:00:00Z",
        payment_escrowed: true,
        shipper_reviewed: false,
        carrier_reviewed: false,
        settled_at: null,
        ...overrides,
    };
}

function makeWindow(overrides: Partial<TransportWindow> = {}): TransportWindow {
    return {
        id: 1,
        vehicle_id: 1,
        origin_address: "Av. Corrientes 1234, CABA",
        origin_locality: "CABA",
        origin_admin_area: "CABA",
        origin_lat: "-34.6",
        origin_lng: "-58.4",
        destination_address: null,
        destination_locality: null,
        destination_admin_area: null,
        destination_lat: null,
        destination_lng: null,
        price_per_km: "1000",
        max_km: 900,
        pickup_radius_km: 50,
        dropoff_radius_km: null,
        available_from: "2026-06-12T00:00:00Z",
        available_to: "2026-06-16T00:00:00Z",
        active: true,
        status: "open",
        cargo_offers_count: 0,
        vehicle: { id: 1, make: "Iveco", model: "Daily", plate: "AAA111", vehicle_type: "truck_small" },
        created_at: "2026-06-01T00:00:00Z",
        updated_at: "2026-06-01T00:00:00Z",
        ...overrides,
    };
}

function makeActivity(
    overrides: Partial<CarrierActivityEvent> = {},
): CarrierActivityEvent {
    return {
        id: "payout-3",
        kind: "payout_paid",
        occurred_at: "2026-06-09T10:00:00Z",
        shipment_id: 42,
        cargo_offer_id: null,
        origin: "Rosario",
        destination: "Mendoza",
        amount_cents: 8_500_000,
        currency: "ARS",
        rating: null,
        ...overrides,
    };
}

const LIST_META = { total: 1, page: 1, perPage: 20, totalPages: 1 };

function mockData(
    {
        pendingOffers = [],
        shipmentRows = [],
        vehicleCount = 1,
        windowRows = [makeWindow()],
        activity = [],
    }: {
        pendingOffers?: CarrierCargoOffer[];
        shipmentRows?: Shipment[];
        vehicleCount?: number;
        windowRows?: TransportWindow[];
        activity?: CarrierActivityEvent[];
    } = {},
) {
    offers.listCarrierCargoOffers.mockResolvedValue({
        items: pendingOffers,
        meta: { ...LIST_META, total: pendingOffers.length },
    });
    shipments.listCarrierShipments.mockResolvedValue(shipmentRows);
    vehicles.listMyVehicles.mockResolvedValue({
        items: [],
        meta: { ...LIST_META, total: vehicleCount },
    });
    windows.listMyTransportWindows.mockResolvedValue({
        items: windowRows,
        meta: { ...LIST_META, total: windowRows.length },
    });
    shipments.listCarrierActivity.mockResolvedValue(activity);
}

function renderPage() {
    return render(
        <MemoryRouter initialEntries={["/carrier/dashboard"]}>
            <Routes>
                <Route path="/carrier/dashboard" element={<CarrierDashboardPage />} />
            </Routes>
        </MemoryRouter>,
    );
}

beforeEach(() => {
    vi.clearAllMocks();
    mockUser();
});

describe("CarrierDashboardPage", () => {
    it("shows a loading skeleton while data is fetched", () => {
        mockData();
        offers.listCarrierCargoOffers.mockReturnValue(new Promise(() => {}));
        renderPage();
        expect(screen.getByRole("status", { name: /cargando tu panel/i }))
            .toBeInTheDocument();
    });

    it("greets the carrier by first name with the steady CTA", async () => {
        mockData();
        renderPage();
        await screen.findByRole("heading", { name: /hola, pedro/i });
        expect(screen.getByRole("link", { name: /publicar ventana/i }))
            .toHaveAttribute("href", "/carrier/availability/new");
    });

    it("renders the board with cards in the right columns", async () => {
        mockData({
            pendingOffers: [makeOffer()],
            shipmentRows: [
                makeShipment({ id: 42, state: "accepted" }),
                makeShipment({ id: 43, state: "in_transit", origin: "Salta", destination: "Jujuy" }),
                makeShipment({ id: 44, state: "delivered", origin: "CABA", destination: "Rosario" }),
                makeShipment({
                    id: 45,
                    state: "delivered",
                    settled_at: "2026-06-08T00:00:00Z",
                    carrier_reviewed: true,
                    origin: "Mar del Plata",
                    destination: "CABA",
                }),
            ],
        });
        renderPage();

        const board = (await screen.findByRole("heading", { name: /mis viajes/i }))
            .closest("section") as HTMLElement;

        const column = (name: RegExp) =>
            within(board).getByRole("listitem", { name }) as HTMLElement;

        expect(within(column(/ofertas nuevas, 1 viaje/i)).getByText("Agro SA"))
            .toBeInTheDocument();
        expect(within(column(/por iniciar, 1 viaje/i)).getByText(/lista para iniciar/i))
            .toBeInTheDocument();
        expect(within(column(/en tránsito, 1 viaje/i)).getByText("Salta"))
            .toBeInTheDocument();
        expect(within(column(/entregadas, 1 viaje/i)).getByText(/por cobrar/i))
            .toBeInTheDocument();
        expect(within(column(/pagadas, 1 viaje/i)).getByText(/^pagada$/i))
            .toBeInTheDocument();
        // The Pagadas column carries the payouts-history drill-down (the
        // header link was consolidated away).
        expect(
            within(column(/pagadas, 1 viaje/i)).getByRole("link", {
                name: /historial de pagos/i,
            }),
        ).toHaveAttribute("href", "/carrier/payouts");
    });

    it("excludes cancelled shipments from the board", async () => {
        mockData({
            pendingOffers: [makeOffer()],
            shipmentRows: [makeShipment({ state: "cancelled" })],
        });
        renderPage();
        const board = (await screen.findByRole("heading", { name: /mis viajes/i }))
            .closest("section") as HTMLElement;
        expect(within(board).getByRole("listitem", { name: /por iniciar, 0 viajes/i }))
            .toBeInTheDocument();
    });

    it("shows the attention panel with actionable counts and links", async () => {
        mockData({
            pendingOffers: [makeOffer()],
            shipmentRows: [
                makeShipment({ id: 42, state: "accepted", payment_escrowed: true }),
                makeShipment({ id: 43, state: "in_transit" }),
                makeShipment({ id: 44, state: "delivered", carrier_reviewed: false }),
            ],
        });
        renderPage();

        await screen.findByRole("heading", { name: /atención requerida/i });
        expect(screen.getByRole("link", { name: /ofertas nuevas por responder/i }))
            .toHaveAttribute("href", "/carrier/cargo-offers");
        expect(screen.getByRole("link", { name: /envíos por iniciar/i }))
            .toHaveAttribute("href", "/carrier/shipments");
        expect(screen.getByRole("link", { name: /envíos por entregar/i }))
            .toHaveAttribute("href", "/carrier/shipments");
        expect(screen.getByRole("link", { name: /expedidores por calificar/i }))
            .toHaveAttribute("href", "/carrier/shipments");
    });

    it("escalates an expiring offer into the urgent coral row without double-counting", async () => {
        mockData({ pendingOffers: [makeOffer({ expires_at: IN_TWO_HOURS })] });
        renderPage();

        await screen.findByRole("heading", { name: /atención requerida/i });
        expect(screen.getByRole("link", { name: /ofertas por vencer/i }))
            .toBeInTheDocument();
        // The single offer escalated — the calm row must not repeat it.
        expect(screen.queryByRole("link", { name: /ofertas nuevas por responder/i }))
            .toBeNull();
        // The offer card carries the urgent badge + countdown.
        expect(screen.getByText(/vence pronto/i)).toBeInTheDocument();
        expect(screen.getByText(/vence en 1 h/i)).toBeInTheDocument();
    });

    it("does not alert on accepted shipments that are still unpaid", async () => {
        mockData({
            pendingOffers: [makeOffer()],
            shipmentRows: [makeShipment({ state: "accepted", payment_escrowed: false })],
        });
        renderPage();
        await screen.findByRole("heading", { name: /atención requerida/i });
        expect(screen.queryByRole("link", { name: /envíos por iniciar/i })).toBeNull();
        expect(screen.getByText(/esperando pago/i)).toBeInTheDocument();
    });

    it("shows the all-clear state when nothing needs action", async () => {
        mockData({
            shipmentRows: [
                makeShipment({
                    state: "delivered",
                    settled_at: "2026-06-08T00:00:00Z",
                    carrier_reviewed: true,
                }),
            ],
        });
        renderPage();
        expect(await screen.findByText(/todo al día/i)).toBeInTheDocument();
    });

    it("shows the quiet stats strip", async () => {
        mockData({ pendingOffers: [makeOffer()], vehicleCount: 2 });
        renderPage();
        await screen.findByRole("heading", { name: /mis viajes/i });
        expect(screen.getByRole("link", { name: /2 vehículos/i }))
            .toHaveAttribute("href", "/carrier/vehicles");
        expect(screen.getByRole("link", { name: /1 ventana abierta/i }))
            .toHaveAttribute("href", "/carrier/availability");
        expect(screen.getByText(/4\.8 de calificación/i)).toBeInTheDocument();
    });

    it("accepts an offer from its card after confirmation and reloads", async () => {
        mockData({ pendingOffers: [makeOffer()] });
        offers.acceptCarrierCargoOffer.mockResolvedValue(
            {} as offersApi.AcceptCarrierCargoOfferResult,
        );
        const user = userEvent.setup();
        renderPage();

        await user.click(
            await screen.findByRole("button", { name: /aceptar la oferta de caba a córdoba/i }),
        );
        await user.click(screen.getByRole("button", { name: /sí, aceptar/i }));

        await waitFor(() => expect(offers.acceptCarrierCargoOffer).toHaveBeenCalledWith(901));
        // One load on mount + one after the action.
        expect(offers.listCarrierCargoOffers).toHaveBeenCalledTimes(2);
        expect(await screen.findByText(/oferta aceptada/i)).toBeInTheDocument();
    });

    it("rejects an offer from its card after confirmation", async () => {
        mockData({ pendingOffers: [makeOffer()] });
        offers.rejectCarrierCargoOffer.mockResolvedValue(makeOffer({ status: "rejected" }));
        const user = userEvent.setup();
        renderPage();

        await user.click(
            await screen.findByRole("button", { name: /rechazar la oferta de caba a córdoba/i }),
        );
        await user.click(screen.getByRole("button", { name: /sí, rechazar/i }));

        await waitFor(() => expect(offers.rejectCarrierCargoOffer).toHaveBeenCalledWith(901));
        expect(await screen.findByText(/oferta rechazada/i)).toBeInTheDocument();
    });

    it("renders the activity feed with payout and review rows", async () => {
        mockData({
            pendingOffers: [makeOffer()],
            activity: [
                makeActivity(),
                makeActivity({
                    id: "review-1",
                    kind: "review_received",
                    rating: 4,
                    amount_cents: null,
                    currency: null,
                }),
            ],
        });
        renderPage();

        await screen.findByRole("heading", { name: /actividad reciente/i });
        expect(screen.getByText(/cobraste un viaje/i)).toBeInTheDocument();
        expect(screen.getByText(/recibiste una reseña/i)).toBeInTheDocument();
        expect(screen.getByText("★ 4 de 5")).toBeInTheDocument();
    });

    it("still renders the board when the activity feed fails", async () => {
        mockData({ pendingOffers: [makeOffer()] });
        shipments.listCarrierActivity.mockRejectedValue(new Error("boom"));
        renderPage();
        await screen.findByRole("heading", { name: /mis viajes/i });
        expect(screen.getByText(/sin actividad reciente/i)).toBeInTheDocument();
    });

    describe("onboarding ladder", () => {
        it("guides a brand-new carrier to add their first vehicle", async () => {
            mockData({ vehicleCount: 0, windowRows: [] });
            renderPage();
            await screen.findByRole("heading", { name: /sumá tu primer vehículo/i });
            expect(screen.getByRole("link", { name: /agregá tu primer vehículo/i }))
                .toHaveAttribute("href", "/carrier/vehicle/new");
        });

        it("guides a carrier with a vehicle but no window to publish one", async () => {
            mockData({ vehicleCount: 1, windowRows: [] });
            renderPage();
            await screen.findByRole("heading", { name: /publicá tu primera ventana/i });
            expect(screen.getByRole("link", { name: /publicá tu primera ventana/i }))
                .toHaveAttribute("href", "/carrier/availability/new");
        });

        it("shows the waiting hero for a ready carrier with no jobs yet", async () => {
            mockData();
            renderPage();
            await screen.findByRole("heading", { name: /tu flota está lista/i });
            expect(screen.getByText(/van a aparecer acá/i)).toBeInTheDocument();
        });
    });

    it("shows an error panel with retry when loading fails", async () => {
        mockData();
        offers.listCarrierCargoOffers.mockRejectedValueOnce(new Error("network down"));
        const user = userEvent.setup();
        renderPage();

        const alert = await screen.findByRole("alert");
        expect(within(alert).getByText(/network down/i)).toBeInTheDocument();

        await user.click(within(alert).getByRole("button", { name: /reintentar/i }));
        await screen.findByRole("heading", { name: /tu flota está lista/i });
    });
});
