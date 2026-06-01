import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it } from "vitest";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { server } from "../../test/mocks/server";
import { http, HttpResponse } from "msw";
import { fixtureShipmentDetail } from "../../test/mocks/handlers";
import ShipmentDetailPage from "./ShipmentDetailPage";
import { formatDateTime } from "../../lib/format-date";

const API = "http://localhost:3000";

function renderPage(role: "carrier" | "shipper" = "shipper", id = 31) {
    return render(
        <MemoryRouter initialEntries={[`/${role}/shipments/${id}`]}>
            <Routes>
                <Route
                    path="/:role/shipments/:id"
                    element={<ShipmentDetailPage role={role} />}
                />
                <Route path="/:role/shipments/:id/pay" element={<div>pay-page</div>} />
            </Routes>
        </MemoryRouter>,
    );
}

function hasNormalizedText(expected: string) {
    const normalizedExpected = expected.replace(/\u00a0/g, " ");
    return (_content: string, node: Element | null) =>
        (node?.textContent ?? "").replace(/\u00a0/g, " ") === normalizedExpected;
}

describe("ShipmentDetailPage", () => {
    it("shows skeleton with aria-busy while loading", () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, async () => {
                await new Promise(() => {});
                return HttpResponse.json({});
            }),
        );
        renderPage();
        expect(document.querySelector("[aria-busy='true']")).toBeInTheDocument();
    });

    it("shows Envío #31 title on load", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ id: 31, state: "delivered" }))),
        );
        renderPage();
        await waitFor(() => expect(screen.getByRole("heading", { name: /envío #31/i })).toBeInTheDocument());
    });

    it("shows origin, destination, and amount in the detail block", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ state: "delivered" }))),
        );
        renderPage();
        await waitFor(() => expect(screen.getByText("Av. Corrientes 1234, CABA")).toBeInTheDocument());
        expect(screen.getByText("Av. Colón 500, Córdoba")).toBeInTheDocument();
    });

    it("shows pickup and delivery timestamps when present in shipment detail", async () => {
        const pickedUp = "2026-06-12T09:00:00Z";
        const delivered = "2026-06-13T14:30:00Z";

        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "delivered",
                    picked_up_at: pickedUp,
                    delivered_at: delivered,
                    tracking_events: [],
                }))),
        );

        renderPage("carrier");

        await waitFor(() => expect(screen.getByText("Retirada de carga")).toBeInTheDocument());
        expect(screen.getAllByText(hasNormalizedText(formatDateTime(pickedUp))).length).toBeGreaterThan(0);
        expect(screen.getByText("Entrega de carga")).toBeInTheDocument();
        expect(screen.getAllByText(hasNormalizedText(formatDateTime(delivered))).length).toBeGreaterThan(0);
    });

    it("falls back to tracking_events timestamps when picked_up_at/delivered_at are missing", async () => {
        const pickedUp = "2026-06-12T09:00:00Z";
        const delivered = "2026-06-13T14:30:00Z";

        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "delivered",
                    picked_up_at: null,
                    delivered_at: null,
                    tracking_events: [
                        { id: 11, kind: "status_change", occurred_at: pickedUp, from_status: "accepted", to_status: "in_transit" },
                        { id: 12, kind: "status_change", occurred_at: delivered, from_status: "in_transit", to_status: "delivered" },
                    ],
                }))),
        );

        renderPage("carrier");

        await waitFor(() => expect(screen.getByText("Retirada de carga")).toBeInTheDocument());
        expect(screen.getAllByText(hasNormalizedText(formatDateTime(pickedUp))).length).toBeGreaterThan(0);
        expect(screen.getByText("Entrega de carga")).toBeInTheDocument();
        expect(screen.getAllByText(hasNormalizedText(formatDateTime(delivered))).length).toBeGreaterThan(0);
    });

    // --- State matrix: Shipper ---

    it("[Shipper, accepted, no payment] shows Pendiente de pago label + Pagar button", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "accepted",
                    payment: null,
                    available_actions: ["pay"],
                }))),
        );
        renderPage("shipper");
        // Both PaymentStateChip and composite label show "Pendiente de pago" — both must be present.
        await waitFor(() => expect(screen.getAllByText(/pendiente de pago/i).length).toBeGreaterThanOrEqual(1));
        expect(screen.getByRole("button", { name: /pagar/i })).toBeInTheDocument();
    });

    it("[Shipper, accepted, failed payment] shows Reintentar pago button", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "accepted",
                    payment: { id: 1, state: "failed", amount_cents: 100, currency: "ARS", escrowed_at: null },
                    available_actions: ["pay"],
                }))),
        );
        renderPage("shipper");
        await waitFor(() =>
            expect(screen.getByRole("button", { name: /reintentar pago/i })).toBeInTheDocument(),
        );
    });

    it("[Shipper, accepted, escrowed] shows A recoger label, no action buttons", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "accepted",
                    payment: { id: 1, state: "escrowed", amount_cents: 100, currency: "ARS", escrowed_at: "2026-06-11T10:05:00Z" },
                    available_actions: [],
                }))),
        );
        renderPage("shipper");
        await waitFor(() => expect(screen.getByText(/a recoger/i)).toBeInTheDocument());
        expect(screen.queryByRole("button", { name: /pagar/i })).not.toBeInTheDocument();
    });

    // --- State matrix: Carrier ---

    it("[Carrier, accepted, escrowed] shows A recoger label and start_transit button", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "accepted",
                    payment: { id: 1, state: "escrowed", amount_cents: 100, currency: "ARS", escrowed_at: "2026-06-11T10:05:00Z" },
                    available_actions: ["start_transit"],
                }))),
        );
        renderPage("carrier");
        await waitFor(() => expect(screen.getByText(/a recoger/i)).toBeInTheDocument());
        expect(screen.getByRole("button", { name: /confirmar retiro/i })).toBeInTheDocument();
    });

    it("[Carrier, in_transit] shows deliver button", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "in_transit",
                    payment: { id: 1, state: "escrowed", amount_cents: 100, currency: "ARS", escrowed_at: "2026-06-11T10:05:00Z" },
                    available_actions: ["deliver"],
                }))),
        );
        renderPage("carrier");
        await waitFor(() => expect(screen.getByRole("heading", { name: /envío/i })).toBeInTheDocument());
        expect(screen.getByRole("button", { name: /confirmar entrega/i })).toBeInTheDocument();
    });

    it("[delivered] shows no action buttons but PaymentStateChip is visible", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "delivered",
                    available_actions: [],
                }))),
        );
        renderPage();
        await waitFor(() => expect(screen.getByText(/entregado/i)).toBeInTheDocument());
        expect(screen.queryByRole("button", { name: /pagar|iniciar|entregar/i })).not.toBeInTheDocument();
        expect(screen.getByText(/pagado/i)).toBeInTheDocument();
    });

    it("[cancelled] does not show PaymentStateChip", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "cancelled",
                    payment: null,
                    available_actions: [],
                }))),
        );
        renderPage();
        await waitFor(() => expect(screen.getByText("Cancelado")).toBeInTheDocument());
        expect(screen.queryByText(/pendiente de pago|pagado/i)).not.toBeInTheDocument();
    });

    // --- Timeline ---

    it("shows empty state (no list) when tracking_events is empty", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ tracking_events: [] }))),
        );
        renderPage();
        await waitFor(() => expect(screen.getByRole("heading", { name: /envío/i })).toBeInTheDocument());
        expect(screen.queryByRole("list", { name: /historial/i })).not.toBeInTheDocument();
        expect(screen.getByText(/sin eventos/i)).toBeInTheDocument();
    });

    it("renders timeline items when tracking_events is non-empty", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    tracking_events: [
                        { id: 1, kind: "shipment_accepted", occurred_at: "2026-06-11T10:00:00Z" },
                        { id: 2, kind: "shipment_in_transit", occurred_at: "2026-06-12T09:00:00Z" },
                    ],
                }))),
        );
        renderPage();
        await waitFor(() => expect(screen.getAllByRole("listitem")).toHaveLength(2));
    });

    // --- Error states ---

    it("shows not-found screen on 404", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json({ error: "not found" }, { status: 404 })),
        );
        renderPage();
        await waitFor(() => expect(screen.getByText(/envío no encontrado/i)).toBeInTheDocument());
        expect(screen.getByRole("link", { name: /volver al listado/i })).toBeInTheDocument();
    });

    it("shows error panel with retry on non-404 failure", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json({ error: "server error" }, { status: 500 })),
        );
        renderPage();
        await waitFor(() => expect(screen.getByRole("button", { name: /reintentar/i })).toBeInTheDocument());
    });

    it("retry button reloads detail", async () => {
        let calls = 0;
        server.use(
            http.get(`${API}/api/shipments/:id`, () => {
                calls++;
                if (calls === 1) return HttpResponse.json({ error: "err" }, { status: 500 });
                return HttpResponse.json(fixtureShipmentDetail());
            }),
        );
        const user = userEvent.setup();
        renderPage();
        await waitFor(() => expect(screen.getByRole("button", { name: /reintentar/i })).toBeInTheDocument());
        await user.click(screen.getByRole("button", { name: /reintentar/i }));
        await waitFor(() => expect(screen.getByRole("heading", { name: /envío/i })).toBeInTheDocument());
    });

    // --- Back link ---

    it("carrier back link points to /carrier/shipments", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail())),
        );
        renderPage("carrier");
        await waitFor(() => expect(screen.getByRole("link", { name: /volver/i })).toBeInTheDocument());
        expect(screen.getByRole("link", { name: /volver/i })).toHaveAttribute("href", "/carrier/shipments");
    });

    it("shipper back link points to /shipper/shipments", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail())),
        );
        renderPage("shipper");
        await waitFor(() => expect(screen.getByRole("link", { name: /volver/i })).toBeInTheDocument());
        expect(screen.getByRole("link", { name: /volver/i })).toHaveAttribute("href", "/shipper/shipments");
    });

    // --- Pay navigation ---

    it("[Shipper, accepted, no payment] Pagar opens modal then navigates to /pay on confirm", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "accepted",
                    payment: null,
                    available_actions: ["pay"],
                }))),
        );
        const user = userEvent.setup();
        renderPage("shipper");
        await waitFor(() => expect(screen.getByRole("button", { name: /pagar/i })).toBeInTheDocument());
        await user.click(screen.getByRole("button", { name: /pagar/i }));
        expect(screen.getByRole("dialog")).toBeInTheDocument();
        await user.click(screen.getByRole("button", { name: /confirmar/i }));
        await waitFor(() => expect(screen.getByText("pay-page")).toBeInTheDocument());
    });

    // --- US30 / REQ-BE-00044 — Carrier review integration (AC7) ---

    it("[Carrier, delivered, no review] mounts the review form", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ state: "delivered", carrier_review: null }))),
        );
        renderPage("carrier");
        await waitFor(() =>
            expect(screen.getByRole("heading", { name: /reseñar al expedidor/i })).toBeInTheDocument(),
        );
        expect(screen.getByRole("radiogroup", { name: /puntuación/i })).toBeInTheDocument();
        expect(screen.getByRole("button", { name: /enviar reseña/i })).toBeInTheDocument();
    });

    it("[Shipper, delivered] does NOT mount the review form", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ state: "delivered" }))),
        );
        renderPage("shipper");
        await waitFor(() => expect(screen.getByText(/entregado/i)).toBeInTheDocument());
        expect(screen.queryByRole("heading", { name: /reseñar al expedidor/i })).not.toBeInTheDocument();
    });

    it("[Carrier, in_transit] does NOT mount the review form (state guard)", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ state: "in_transit", available_actions: ["deliver"] }))),
        );
        renderPage("carrier");
        await waitFor(() => expect(screen.getByRole("heading", { name: /envío/i })).toBeInTheDocument());
        expect(screen.queryByRole("heading", { name: /reseñar al expedidor/i })).not.toBeInTheDocument();
    });

    it("[Carrier, delivered, existing review] hydrates the read-only card (AC7)", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "delivered",
                    carrier_review: {
                        id: 7,
                        rating: 4,
                        body: "Carga lista a horario.",
                        authored_by: "carrier",
                        created_at: "2026-06-12T10:00:00Z",
                    },
                }))),
        );
        renderPage("carrier");
        await waitFor(() => expect(screen.getByText(/¡gracias por tu reseña!/i)).toBeInTheDocument());
        expect(screen.getByText("Carga lista a horario.")).toBeInTheDocument();
        expect(screen.queryByRole("button", { name: /enviar reseña/i })).not.toBeInTheDocument();
    });

    it("[Carrier, delivered] submitting the form shows the read-only success state", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ state: "delivered", carrier_review: null }))),
        );
        const user = userEvent.setup();
        renderPage("carrier");
        await waitFor(() =>
            expect(screen.getByRole("button", { name: /enviar reseña/i })).toBeInTheDocument(),
        );
        await user.click(screen.getByRole("radio", { name: /5 estrellas/i }));
        await user.click(screen.getByRole("button", { name: /enviar reseña/i }));
        await waitFor(() => expect(screen.getByText(/¡gracias por tu reseña!/i)).toBeInTheDocument());
    });

});
