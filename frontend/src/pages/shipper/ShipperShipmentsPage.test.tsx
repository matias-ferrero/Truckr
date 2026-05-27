import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import ShipperShipmentsPage from "./ShipperShipmentsPage";
import * as shipmentsApi from "../../api/shipments";
import type { Shipment } from "../../api/shipments";

vi.mock("../../api/shipments");

const api = vi.mocked(shipmentsApi);

function makeShipment(overrides: Partial<Shipment> = {}): Shipment {
    return {
        id: 42,
        state: "delivered",
        origin: "Av. Corrientes 1234, CABA",
        destination: "Av. Colón 500, Córdoba",
        created_at: "2026-06-11T10:00:00Z",
        amount_cents: 105_000_000,
        currency: "ARS",
        latest_activity_at: "2026-06-11T10:00:00Z",
        ...overrides,
    };
}

function renderPage() {
    return render(
        <MemoryRouter initialEntries={["/shipper/shipments"]}>
            <Routes>
                <Route path="/shipper/shipments" element={<ShipperShipmentsPage />} />
                <Route path="/shipper/shipments/:id" element={<div>detail-screen</div>} />
                <Route path="/shipper/shipments/:id/pay" element={<div>pay-screen</div>} />
            </Routes>
        </MemoryRouter>,
    );
}

beforeEach(() => {
    vi.resetAllMocks();
});

describe("ShipperShipmentsPage", () => {
    it("shows loading skeleton while fetching", () => {
        api.listShipperShipments.mockReturnValue(new Promise(() => {}));
        renderPage();
        expect(screen.getByRole("status")).toBeInTheDocument();
        expect(screen.getByRole("status")).toHaveAttribute("aria-busy", "true");
    });

    it("shows the page heading", async () => {
        api.listShipperShipments.mockResolvedValue([]);
        renderPage();
        expect(await screen.findByRole("heading", { name: "Mis Envíos" })).toBeInTheDocument();
    });

    it("shows shipper-specific empty state copy", async () => {
        api.listShipperShipments.mockResolvedValue([]);
        renderPage();
        expect(await screen.findByText("Aún no contrataste envíos")).toBeInTheDocument();
        expect(screen.getByText(/Publicá una carga/)).toBeInTheDocument();
    });

    it("renders a row for each shipment", async () => {
        api.listShipperShipments.mockResolvedValue([
            makeShipment({ id: 42, state: "delivered" }),
            makeShipment({ id: 43, state: "in_transit" }),
        ]);
        renderPage();
        await waitFor(() => {
            expect(screen.getByText("Entregado")).toBeInTheDocument();
            expect(screen.getByText("En tránsito")).toBeInTheDocument();
        });
    });

    it("shows pending_payment state chip", async () => {
        api.listShipperShipments.mockResolvedValue([makeShipment({ state: "pending_payment" })]);
        renderPage();
        await waitFor(() => {
            expect(screen.getByText("Pendiente de pago")).toBeInTheDocument();
        });
    });

    it("shows only state chip for cancelled shipment", async () => {
        api.listShipperShipments.mockResolvedValue([makeShipment({ state: "cancelled" })]);
        renderPage();
        await waitFor(() => {
            expect(screen.getByText("Cancelado")).toBeInTheDocument();
        });
        expect(screen.queryByText("Pendiente de pago")).not.toBeInTheDocument();
    });

    it("navigates to detail when row link is clicked", async () => {
        const user = userEvent.setup();
        api.listShipperShipments.mockResolvedValue([makeShipment({ id: 42 })]);
        renderPage();
        const link = await screen.findByRole("link", { name: /envío #42/i });
        await user.click(link);
        expect(await screen.findByText("detail-screen")).toBeInTheDocument();
    });

    it("row links point to /shipper/shipments/:id", async () => {
        api.listShipperShipments.mockResolvedValue([makeShipment({ id: 42 })]);
        renderPage();
        const link = await screen.findByRole("link", { name: /envío #42/i });
        expect(link).toHaveAttribute("href", "/shipper/shipments/42");
    });

    it("shows error panel with retry button on fetch failure", async () => {
        api.listShipperShipments.mockRejectedValue(new Error("Network error"));
        renderPage();
        expect(await screen.findByRole("alert")).toBeInTheDocument();
        expect(screen.getByText(/No pudimos cargar tus envíos/)).toBeInTheDocument();
        expect(screen.getByRole("button", { name: "Reintentar" })).toBeInTheDocument();
    });

    it("retries fetch when retry button is clicked", async () => {
        const user = userEvent.setup();
        api.listShipperShipments
            .mockRejectedValueOnce(new Error("Network error"))
            .mockResolvedValue([]);
        renderPage();
        await screen.findByRole("alert");
        await user.click(screen.getByRole("button", { name: "Reintentar" }));
        expect(await screen.findByText("Aún no contrataste envíos")).toBeInTheDocument();
    });

    it("renders a Pagar button on accepted shipments and navigates to /pay", async () => {
        const user = userEvent.setup();
        api.listShipperShipments.mockResolvedValue([
            makeShipment({ id: 42, state: "accepted", amount_cents: 12_345_67 }),
        ]);
        renderPage();
        const payButton = await screen.findByRole("button", { name: /^Pagar /i });
        await user.click(payButton);
        expect(await screen.findByText("pay-screen")).toBeInTheDocument();
    });

    it("does NOT render a Pagar button once payment has been escrowed", async () => {
        api.listShipperShipments.mockResolvedValue([
            makeShipment({ id: 42, state: "pending_payment" }),
            makeShipment({ id: 43, state: "in_transit" }),
        ]);
        renderPage();
        await screen.findByText("En tránsito");
        expect(screen.queryByRole("button", { name: /^Pagar /i })).not.toBeInTheDocument();
    });

    it("shows the counterparty name unmasked once payment has landed", async () => {
        api.listShipperShipments.mockResolvedValue([
            makeShipment({
                id: 42,
                state: "delivered",
                counterparty_display_name: "Transportes Demo SRL",
            }),
        ]);
        renderPage();
        expect(await screen.findByText("Transportes Demo SRL")).toBeInTheDocument();
    });

    it("masks the counterparty name while the shipment is awaiting payment", async () => {
        api.listShipperShipments.mockResolvedValue([
            makeShipment({
                id: 42,
                state: "accepted",
                counterparty_display_name: "Transportes Demo SRL",
            }),
        ]);
        renderPage();
        await screen.findByText("Aceptado");
        expect(screen.queryByText("Transportes Demo SRL")).not.toBeInTheDocument();
        expect(screen.getByText("Datos revelados al pagar")).toBeInTheDocument();
    });
});
