import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import ShipperPaymentSuccessPage from "./ShipperPaymentSuccessPage";
import * as shipmentsApi from "../../api/shipments";
import { ApiError } from "../../api";
import type { ShipmentDetail } from "../../api/shipments";

vi.mock("../../api/shipments");

const api = vi.mocked(shipmentsApi);

const paidDetail: ShipmentDetail = {
    id: 31,
    state: "accepted",
    payment_state: "paid",
    amount_cents: 12_500_000,
    currency: "ARS",
    counterparty: { kind: "carrier", id: 1, display_name: "Transportes Demo" },
    counterparty_contact: {
        full_name: "Carrier Demo",
        email: "carrier@demo.test",
        phone: "+54 11 5555-1111",
    },
};

function renderPage(path = "/shipper/shipments/31/pay/success") {
    return render(
        <MemoryRouter initialEntries={[path]}>
            <Routes>
                <Route path="/shipper/shipments/:id/pay/success" element={<ShipperPaymentSuccessPage />} />
                <Route path="/shipper/shipments" element={<div>list-screen</div>} />
            </Routes>
        </MemoryRouter>,
    );
}

beforeEach(() => {
    vi.resetAllMocks();
});

describe("ShipperPaymentSuccessPage", () => {
    it("renders the contact triple once detail is fetched", async () => {
        api.getShipmentDetail.mockResolvedValue(paidDetail);
        renderPage();
        await screen.findByRole("heading", { name: "Pago confirmado" });
        expect(screen.getByText("Carrier Demo")).toBeInTheDocument();
        expect(screen.getByRole("link", { name: "carrier@demo.test" })).toHaveAttribute(
            "href",
            "mailto:carrier@demo.test",
        );
        expect(screen.getByRole("link", { name: "+54 11 5555-1111" })).toHaveAttribute(
            "href",
            "tel:+54 11 5555-1111",
        );
    });

    it("falls back to placeholder when phone is null", async () => {
        api.getShipmentDetail.mockResolvedValue({ ...paidDetail, counterparty_contact: { ...paidDetail.counterparty_contact!, phone: null } });
        renderPage();
        await screen.findByRole("heading", { name: "Pago confirmado" });
        expect(screen.getByText("No disponible")).toBeInTheDocument();
    });

    it("renders a back link to /shipper/shipments", async () => {
        api.getShipmentDetail.mockResolvedValue(paidDetail);
        renderPage();
        const back = await screen.findByRole("link", { name: "Volver a Mis Envíos" });
        expect(back).toHaveAttribute("href", "/shipper/shipments");
    });

    it("redirects to /shipper/shipments when contact is not yet revealed", async () => {
        api.getShipmentDetail.mockResolvedValue({ ...paidDetail, counterparty_contact: null });
        renderPage();
        await waitFor(() => {
            expect(screen.getByText("list-screen")).toBeInTheDocument();
        });
    });

    it("redirects to /shipper/shipments on API error", async () => {
        api.getShipmentDetail.mockRejectedValue(new ApiError(404, "not found"));
        renderPage();
        await waitFor(() => {
            expect(screen.getByText("list-screen")).toBeInTheDocument();
        });
    });
});
