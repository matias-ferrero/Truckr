import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import ShipperPaymentPage from "./ShipperPaymentPage";
import * as shipmentsApi from "../../api/shipments";
import { ApiError } from "../../api";
import type { ShipmentDetail } from "../../api/shipments";

vi.mock("../../api/shipments");

const api = vi.mocked(shipmentsApi);

const detailFixture: ShipmentDetail = {
    id: 31,
    state: "accepted",
    payment_state: "pending",
    amount_cents: 12_500_000,
    currency: "ARS",
    counterparty: { kind: "carrier", id: 1, display_name: "Transportes Demo" },
    counterparty_contact: null,
};

function renderPage(path = "/shipper/shipments/31/pay") {
    return render(
        <MemoryRouter initialEntries={[path]}>
            <Routes>
                <Route path="/shipper/shipments/:id/pay" element={<ShipperPaymentPage />} />
                <Route path="/shipper/shipments/:id/pay/success" element={<div>success-screen</div>} />
                <Route path="/shipper/shipments" element={<div>list-screen</div>} />
            </Routes>
        </MemoryRouter>,
    );
}

async function fillValidForm(user: ReturnType<typeof userEvent.setup>) {
    await user.type(screen.getByLabelText(/número de tarjeta/i), "4242 4242 4242 4242");
    await user.type(screen.getByLabelText(/vencimiento/i), "12/30");
    await user.type(screen.getByLabelText(/^CVV$/i), "123");
    await user.type(screen.getByLabelText(/titular/i), "Demo Holder");
    await user.type(screen.getByLabelText(/calle y número/i), "Av. Demo 1234");
    await user.type(screen.getByLabelText(/^ciudad$/i), "Buenos Aires");
    await user.selectOptions(screen.getByLabelText(/provincia/i), "CABA");
    await user.type(screen.getByLabelText(/código postal/i), "1414");
}

beforeEach(() => {
    vi.resetAllMocks();
    api.getShipmentDetail.mockResolvedValue(detailFixture);
});

describe("ShipperPaymentPage", () => {
    it("renders heading + form sections", async () => {
        renderPage();
        await screen.findByRole("heading", { name: "Pagar envío" });
        expect(screen.getByText("Tarjeta de crédito")).toBeInTheDocument();
        expect(screen.getByText("Dirección de facturación")).toBeInTheDocument();
    });

    it("submit stays enabled but surfaces inline errors when the form is empty", async () => {
        const user = userEvent.setup();
        renderPage();
        await screen.findByRole("heading", { name: "Pagar envío" });

        const submit = screen.getByRole("button", { name: /^Realizar pago$/ });
        expect(submit).toBeEnabled();

        await user.click(submit);

        expect(await screen.findByText("Ingresá el número de tarjeta.")).toBeInTheDocument();
        expect(screen.getByText("Seleccioná una provincia.")).toBeInTheDocument();
        expect(api.createShipmentPayment).not.toHaveBeenCalled();
        expect(screen.getByLabelText(/número de tarjeta/i)).toHaveFocus();
    });

    it("auto-formats card number with 4-digit groups", async () => {
        const user = userEvent.setup();
        renderPage();
        await screen.findByRole("heading", { name: "Pagar envío" });

        const card = screen.getByLabelText(/número de tarjeta/i) as HTMLInputElement;
        await user.type(card, "4242424242424242");
        expect(card.value).toBe("4242 4242 4242 4242");
    });

    it("auto-formats expiry into MM/YY", async () => {
        const user = userEvent.setup();
        renderPage();
        await screen.findByRole("heading", { name: "Pagar envío" });

        const expiry = screen.getByLabelText(/vencimiento/i) as HTMLInputElement;
        await user.type(expiry, "1230");
        expect(expiry.value).toBe("12/30");
    });

    it("flags an expired card on blur", async () => {
        const user = userEvent.setup();
        renderPage();
        await screen.findByRole("heading", { name: "Pagar envío" });

        const expiry = screen.getByLabelText(/vencimiento/i);
        await user.type(expiry, "12/00");
        await user.tab();
        expect(await screen.findByText("La tarjeta está vencida.")).toBeInTheDocument();
    });

    it("renders CVV as a password field for shoulder-surfing safety", async () => {
        renderPage();
        await screen.findByRole("heading", { name: "Pagar envío" });
        expect(screen.getByLabelText(/^CVV$/i)).toHaveAttribute("type", "password");
    });

    it("navigates to success on a successful payment", async () => {
        const user = userEvent.setup();
        api.createShipmentPayment.mockResolvedValue({ payment_id: 1, state: "escrowed" });
        renderPage();
        await screen.findByRole("heading", { name: "Pagar envío" });
        await fillValidForm(user);

        const submit = screen.getByRole("button", { name: /^Realizar pago$/ });
        expect(submit).toBeEnabled();
        await user.click(submit);

        await waitFor(() => {
            expect(api.createShipmentPayment).toHaveBeenCalledWith(31);
        });
        expect(await screen.findByText("success-screen")).toBeInTheDocument();
    });

    it("shows a generic error on a 409 and re-enables submit", async () => {
        const user = userEvent.setup();
        api.createShipmentPayment.mockRejectedValue(new ApiError(409, "already paid", "conflict"));
        renderPage();
        await screen.findByRole("heading", { name: "Pagar envío" });
        await fillValidForm(user);
        await user.click(screen.getByRole("button", { name: /^Realizar pago$/ }));

        const alert = await screen.findByRole("alert");
        expect(alert).toBeInTheDocument();
        expect(screen.getByRole("button", { name: /^Realizar pago$/ })).toBeEnabled();
    });

    it("redirects to the list when the shipment detail returns 403/404", async () => {
        api.getShipmentDetail.mockRejectedValue(new ApiError(404, "not found"));
        renderPage();
        expect(await screen.findByText("list-screen")).toBeInTheDocument();
    });
});
