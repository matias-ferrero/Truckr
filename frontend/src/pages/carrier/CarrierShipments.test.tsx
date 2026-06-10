import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import CarrierShipments from "./CarrierShipments";
import * as shipmentsApi from "../../api/shipments";
import type { Shipment } from "../../api/shipments";

vi.mock("../../api/shipments");

const api = vi.mocked(shipmentsApi);

function makeShipment(overrides: Partial<Shipment> = {}): Shipment {
    return {
        id: 31,
        state: "accepted",
        origin: "Av. Corrientes 1234, CABA",
        destination: "Av. Colón 500, Córdoba",
        created_at: "2026-06-11T10:00:00Z",
        amount_cents: 105_000_000,
        currency: "ARS",
        latest_activity_at: "2026-06-11T10:00:00Z",
        payment_escrowed: false,
        shipper_reviewed: false,
        carrier_reviewed: false,
        settled_at: null,
        ...overrides,
    };
}

function renderPage() {
    return render(
        <MemoryRouter initialEntries={["/carrier/shipments"]}>
            <Routes>
                <Route path="/carrier/shipments" element={<CarrierShipments />} />
                <Route path="/carrier/shipments/:id" element={<div>detail-screen</div>} />
            </Routes>
        </MemoryRouter>,
    );
}

beforeEach(() => {
    vi.resetAllMocks();
});

describe("CarrierShipments", () => {
    it("shows loading skeleton while fetching", () => {
        api.listCarrierShipments.mockReturnValue(new Promise(() => {}));
        renderPage();
        expect(screen.getByRole("status")).toBeInTheDocument();
        expect(screen.getByRole("status")).toHaveAttribute("aria-busy", "true");
    });

    it("shows the page heading", async () => {
        api.listCarrierShipments.mockResolvedValue([]);
        renderPage();
        expect(await screen.findByRole("heading", { name: "Mis Envíos" })).toBeInTheDocument();
    });

    it("shows empty state when there are no shipments", async () => {
        api.listCarrierShipments.mockResolvedValue([]);
        renderPage();
        expect(await screen.findByText("Aún no realizaste envíos")).toBeInTheDocument();
        expect(screen.getByText(/Aceptá una oferta/)).toBeInTheDocument();
    });

    it("renders a row for each shipment", async () => {
        api.listCarrierShipments.mockResolvedValue([
            makeShipment({ id: 31 }),
            makeShipment({ id: 32, state: "in_transit" }),
        ]);
        renderPage();
        await waitFor(() => {
            expect(screen.getByText("Aceptado")).toBeInTheDocument();
            expect(screen.getByText("En tránsito")).toBeInTheDocument();
        });
    });

    it("shows only state chip for cancelled shipment", async () => {
        api.listCarrierShipments.mockResolvedValue([makeShipment({ state: "cancelled" })]);
        renderPage();
        await waitFor(() => {
            expect(screen.getByText("Cancelado")).toBeInTheDocument();
        });
    });

    it("shows delivered chip", async () => {
        api.listCarrierShipments.mockResolvedValue([makeShipment({ state: "delivered" })]);
        renderPage();
        await waitFor(() => {
            expect(screen.getByText("Entregado")).toBeInTheDocument();
        });
    });

    it("navigates to detail when row link is clicked", async () => {
        const user = userEvent.setup();
        api.listCarrierShipments.mockResolvedValue([makeShipment({ id: 31 })]);
        renderPage();
        const link = await screen.findByRole("link", { name: /envío #31/i });
        await user.click(link);
        expect(await screen.findByText("detail-screen")).toBeInTheDocument();
    });

    it("does NOT render a Pagar button on the carrier side (payment is shipper-only)", async () => {
        api.listCarrierShipments.mockResolvedValue([
            makeShipment({ id: 31, state: "accepted", payment_escrowed: false }),
        ]);
        renderPage();
        await screen.findByText("Aceptado");
        expect(screen.queryByRole("button", { name: /^Pagar /i })).not.toBeInTheDocument();
    });

    it("shows error panel with retry button on fetch failure", async () => {
        api.listCarrierShipments.mockRejectedValue(new Error("Network error"));
        renderPage();
        expect(await screen.findByRole("alert")).toBeInTheDocument();
        expect(screen.getByText(/No pudimos cargar tus envíos/)).toBeInTheDocument();
        expect(screen.getByRole("button", { name: "Reintentar" })).toBeInTheDocument();
    });

    it("retries fetch when retry button is clicked", async () => {
        const user = userEvent.setup();
        api.listCarrierShipments
            .mockRejectedValueOnce(new Error("Network error"))
            .mockResolvedValue([]);
        renderPage();
        await screen.findByRole("alert");
        await user.click(screen.getByRole("button", { name: "Reintentar" }));
        expect(await screen.findByText("Aún no realizaste envíos")).toBeInTheDocument();
    });

    it("shows origin and destination in the row", async () => {
        api.listCarrierShipments.mockResolvedValue([
            makeShipment({ origin: "CABA", destination: "Mendoza" }),
        ]);
        renderPage();
        await waitFor(() => {
            expect(screen.getByText(/CABA/)).toBeInTheDocument();
            expect(screen.getByText(/Mendoza/)).toBeInTheDocument();
        });
    });
});
