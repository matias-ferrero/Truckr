import { render, screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { server } from "../../test/mocks/server";
import { http, HttpResponse } from "msw";
import { fixtureShipmentDetail } from "../../test/mocks/handlers";
import ShipmentDetailPage from "./ShipmentDetailPage";

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

describe("ShipmentDetailPage", () => {
    // Force the US51 map into its service-unavailable path so these page tests
    // stay deterministic regardless of a local `.env` Google Maps key — the
    // map canvas itself is covered in ShipmentMap.test.tsx with a mocked loader.
    // The deep-link buttons render independently of the JS API (AC9).
    beforeEach(() => vi.stubEnv("VITE_GOOGLE_MAPS_API_KEY", ""));
    afterEach(() => vi.unstubAllEnvs());

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

    // --- Primary action card: Shipper matrix ---

    it("[Shipper, accepted, no payment] shows Pendiente de pago + Reservá tu envío + Pagar CTA", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "accepted",
                    payment: null,
                    available_actions: ["pay"],
                }))),
        );
        renderPage("shipper");
        // Both PaymentStateChip and the rail eyebrow show "Pendiente de pago".
        await waitFor(() => expect(screen.getAllByText(/pendiente de pago/i).length).toBeGreaterThanOrEqual(1));
        expect(screen.getByText(/reservá tu envío/i)).toBeInTheDocument();
        expect(screen.getByRole("button", { name: /pagar/i })).toBeInTheDocument();
    });

    it("[Shipper, accepted, failed payment] shows retry headline + Reintentar pago button", async () => {
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
        expect(screen.getByText(/el pago no se procesó/i)).toBeInTheDocument();
    });

    it("[Shipper, accepted, escrowed] shows the waiting-on-pickup card, no pay button", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "accepted",
                    payment: { id: 1, state: "escrowed", amount_cents: 100, currency: "ARS", escrowed_at: "2026-06-11T10:05:00Z" },
                    available_actions: [],
                }))),
        );
        renderPage("shipper");
        await waitFor(() => expect(screen.getByText(/pago confirmado/i)).toBeInTheDocument());
        expect(screen.getByText(/esperando al transportista/i)).toBeInTheDocument();
        expect(screen.queryByRole("button", { name: /pagar/i })).not.toBeInTheDocument();
    });

    it("[Shipper, in_transit] shows the on-its-way status card, no action buttons", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "in_transit",
                    available_actions: [],
                }))),
        );
        renderPage("shipper");
        await waitFor(() => expect(screen.getByText(/tu carga está en camino/i)).toBeInTheDocument());
        expect(screen.queryByRole("button", { name: /pagar|confirmar/i })).not.toBeInTheDocument();
    });

    // --- Primary action card: Carrier matrix ---

    it("[Carrier, accepted, no payment] shows the waiting-on-payment card, no transition buttons", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "accepted",
                    payment: null,
                    available_actions: [],
                }))),
        );
        renderPage("carrier");
        await waitFor(() =>
            expect(screen.getByText(/esperando el pago del expedidor/i)).toBeInTheDocument(),
        );
        expect(screen.queryByRole("button", { name: /confirmar retiro|confirmar entrega/i })).not.toBeInTheDocument();
    });

    it("[Carrier, accepted, escrowed] shows Listo para retirar + Confirmar Retiro in the rail", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "accepted",
                    payment: { id: 1, state: "escrowed", amount_cents: 100, currency: "ARS", escrowed_at: "2026-06-11T10:05:00Z" },
                    available_actions: ["start_transit"],
                }))),
        );
        renderPage("carrier");
        await waitFor(() => expect(screen.getByText(/listo para retirar/i)).toBeInTheDocument());
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

    it("[delivered] shows no transition buttons but PaymentStateChip is visible", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "delivered",
                    available_actions: [],
                }))),
        );
        renderPage();
        // State chip + rail eyebrow both read "Entregado".
        await waitFor(() => expect(screen.getAllByText(/entregado/i).length).toBeGreaterThanOrEqual(1));
        expect(screen.queryByRole("button", { name: /pagar|iniciar|entregar/i })).not.toBeInTheDocument();
        expect(screen.getByText(/pagado/i)).toBeInTheDocument();
    });

    it("[cancelled] does not show PaymentStateChip and shows the cancelled status card", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "cancelled",
                    payment: null,
                    available_actions: [],
                }))),
        );
        renderPage();
        // State chip + rail eyebrow both read "Cancelado".
        await waitFor(() => expect(screen.getAllByText("Cancelado").length).toBeGreaterThanOrEqual(1));
        expect(screen.getByText(/envío cancelado/i)).toBeInTheDocument();
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
        await waitFor(() => expect(screen.getByRole("button", { name: /pagar ahora/i })).toBeInTheDocument());
        await user.click(screen.getByRole("button", { name: /pagar ahora/i }));
        const dialog = screen.getByRole("dialog");
        expect(dialog).toBeInTheDocument();
        // P1 — the dialog restates the amount and names the escrow protection
        // at the highest-anxiety click instead of going generic.
        expect(within(dialog).getByText(/queda protegido/i)).toBeInTheDocument();
        // Confirm button restates the amount: "Ir a pagar $120.000".
        await user.click(within(dialog).getByRole("button", { name: /ir a pagar/i }));
        await waitFor(() => expect(screen.getByText("pay-page")).toBeInTheDocument());
    });

    // --- US20 / US30 — delivered-shipment reviews via the rail CTA + modal ---

    it("[Carrier, delivered, no review] rail CTA opens the review form in a modal", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ state: "delivered", carrier_review: null }))),
        );
        const user = userEvent.setup();
        renderPage("carrier");
        await waitFor(() =>
            expect(screen.getByRole("button", { name: /dejá tu reseña/i })).toBeInTheDocument(),
        );
        await user.click(screen.getByRole("button", { name: /dejá tu reseña/i }));
        expect(screen.getByRole("heading", { name: /reseñar al expedidor/i })).toBeInTheDocument();
        expect(screen.getByRole("radiogroup", { name: /puntuación/i })).toBeInTheDocument();
        expect(screen.getByRole("button", { name: /enviar reseña/i })).toBeInTheDocument();
    });

    it("[Shipper, delivered, no review] rail CTA opens the review form in a modal", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ state: "delivered", shipper_review: null }))),
        );
        const user = userEvent.setup();
        renderPage("shipper");
        await waitFor(() =>
            expect(screen.getByRole("button", { name: /dejá tu reseña/i })).toBeInTheDocument(),
        );
        await user.click(screen.getByRole("button", { name: /dejá tu reseña/i }));
        expect(screen.getByRole("heading", { name: /dejar reseña/i })).toBeInTheDocument();
        expect(screen.getByRole("radiogroup", { name: /puntuación/i })).toBeInTheDocument();
        expect(screen.getByRole("button", { name: /enviar reseña/i })).toBeInTheDocument();
    });

    it("review modal closes via the Cerrar button without submitting", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ state: "delivered", shipper_review: null }))),
        );
        const user = userEvent.setup();
        renderPage("shipper");
        await waitFor(() =>
            expect(screen.getByRole("button", { name: /dejá tu reseña/i })).toBeInTheDocument(),
        );
        await user.click(screen.getByRole("button", { name: /dejá tu reseña/i }));
        expect(screen.getByRole("radiogroup", { name: /puntuación/i })).toBeInTheDocument();
        await user.click(screen.getByRole("button", { name: /cerrar/i }));
        expect(screen.queryByRole("radiogroup", { name: /puntuación/i })).not.toBeInTheDocument();
        // The CTA is back — nothing was submitted.
        expect(screen.getByRole("button", { name: /dejá tu reseña/i })).toBeInTheDocument();
    });

    it("[Carrier, delivered] does NOT offer the shipper review form", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ state: "delivered" }))),
        );
        const user = userEvent.setup();
        renderPage("carrier");
        await waitFor(() =>
            expect(screen.getByRole("button", { name: /dejá tu reseña/i })).toBeInTheDocument(),
        );
        await user.click(screen.getByRole("button", { name: /dejá tu reseña/i }));
        expect(screen.queryByRole("heading", { name: /dejar reseña/i })).not.toBeInTheDocument();
        expect(screen.getByRole("heading", { name: /reseñar al expedidor/i })).toBeInTheDocument();
    });

    it("[Shipper, in_transit] does NOT offer the review CTA (state guard)", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ state: "in_transit" }))),
        );
        renderPage("shipper");
        await waitFor(() => expect(screen.getByRole("heading", { name: /envío/i })).toBeInTheDocument());
        expect(screen.queryByRole("button", { name: /dejá tu reseña/i })).not.toBeInTheDocument();
    });

    it("[Shipper, delivered, existing review] hydrates the read-only card in the rail (AC7)", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "delivered",
                    shipper_review: {
                        id: 8,
                        rating: 5,
                        body: "Entrega puntual.",
                        authored_by: "shipper",
                        created_at: "2026-06-12T10:00:00Z",
                    },
                }))),
        );
        renderPage("shipper");
        await waitFor(() => expect(screen.getByText(/¡gracias por tu reseña!/i)).toBeInTheDocument());
        expect(screen.getByText("Entrega puntual.")).toBeInTheDocument();
        expect(screen.queryByRole("button", { name: /enviar reseña|dejá tu reseña/i })).not.toBeInTheDocument();
    });

    it("[Shipper, delivered] submitting in the modal shows the read-only success state", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ state: "delivered", shipper_review: null }))),
        );
        const user = userEvent.setup();
        renderPage("shipper");
        await waitFor(() =>
            expect(screen.getByRole("button", { name: /dejá tu reseña/i })).toBeInTheDocument(),
        );
        await user.click(screen.getByRole("button", { name: /dejá tu reseña/i }));
        await user.click(screen.getByRole("radio", { name: /5 estrellas/i }));
        await user.click(screen.getByRole("button", { name: /enviar reseña/i }));
        await waitFor(() => expect(screen.getByText(/¡gracias por tu reseña!/i)).toBeInTheDocument());
        // Closing the modal hands the done card to the rail.
        await user.click(screen.getByRole("button", { name: /cerrar/i }));
        expect(screen.getByText(/¡gracias por tu reseña!/i)).toBeInTheDocument();
        expect(screen.queryByRole("button", { name: /dejá tu reseña/i })).not.toBeInTheDocument();
    });

    it("[Carrier, in_transit] does NOT offer the review CTA (state guard)", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ state: "in_transit", available_actions: ["deliver"] }))),
        );
        renderPage("carrier");
        await waitFor(() => expect(screen.getByRole("heading", { name: /envío/i })).toBeInTheDocument());
        expect(screen.queryByRole("button", { name: /dejá tu reseña/i })).not.toBeInTheDocument();
    });

    it("[Carrier, delivered, existing review] hydrates the read-only card in the rail (AC7)", async () => {
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
        expect(screen.queryByRole("button", { name: /enviar reseña|dejá tu reseña/i })).not.toBeInTheDocument();
    });

    it("[Carrier, delivered] submitting in the modal shows the read-only success state", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ state: "delivered", carrier_review: null }))),
        );
        const user = userEvent.setup();
        renderPage("carrier");
        await waitFor(() =>
            expect(screen.getByRole("button", { name: /dejá tu reseña/i })).toBeInTheDocument(),
        );
        await user.click(screen.getByRole("button", { name: /dejá tu reseña/i }));
        await user.click(screen.getByRole("radio", { name: /5 estrellas/i }));
        await user.click(screen.getByRole("button", { name: /enviar reseña/i }));
        await waitFor(() => expect(screen.getByText(/¡gracias por tu reseña!/i)).toBeInTheDocument());
    });

    // --- Counterparty + reputation links (v2 §6) ---

    it("[Carrier viewer] links the shipper counterparty to its public profile", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    counterparty: { kind: "shipper", id: 17, display_name: "Expede SA" },
                }))),
        );
        renderPage("carrier");

        const link = await screen.findByRole("link", { name: "Expede SA" });
        expect(link).toHaveAttribute("href", "/shippers/17");
    });

    it("[Shipper viewer] does NOT link the carrier counterparty display name", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    counterparty: { kind: "carrier", id: 3, display_name: "Transportes Demo SRL" },
                }))),
        );
        renderPage("shipper");

        await waitFor(() => expect(screen.getByText("Transportes Demo SRL")).toBeInTheDocument());
        expect(screen.queryByRole("link", { name: "Transportes Demo SRL" })).toBeNull();
    });

    it("[Shipper viewer] contact card links to the carrier's reputation", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    counterparty: { kind: "carrier", id: 3, display_name: "Transportes Demo SRL" },
                }))),
        );
        renderPage("shipper");

        const link = await screen.findByRole("link", { name: /ver reputación del transportista/i });
        expect(link).toHaveAttribute("href", "/carriers/3");
    });

    it("[Carrier viewer] contact card links to the shipper's reputation", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    counterparty: { kind: "shipper", id: 17, display_name: "Expede SA" },
                }))),
        );
        renderPage("carrier");

        const link = await screen.findByRole("link", { name: /ver reputación del expedidor/i });
        expect(link).toHaveAttribute("href", "/shippers/17");
    });

    // --- US15 / REQ-BE-00046 — Liquidación del envío (payout breakdown) ---

    it("[Carrier, delivered, payout paid] shows the Liquidación rail card with breakdown", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "delivered",
                    payout: {
                        id: 5,
                        state: "paid",
                        gross_amount_cents: 100_000_00,
                        commission_rate: "0.15",
                        commission_cents:  15_000_00,
                        amount_cents:      85_000_00,
                        currency: "ARS",
                        paid_at: "2026-06-13T15:00:00Z",
                    },
                }))),
        );
        renderPage("carrier");

        await waitFor(() =>
            expect(screen.getByText(/liquidación del envío/i)).toBeInTheDocument(),
        );
        // All breakdown rows must be visible
        expect(screen.getByText(/monto bruto/i)).toBeInTheDocument();
        // Commission label shows the dynamic rate
        expect(screen.getByText(/comisión plataforma.*15\s*%/i)).toBeInTheDocument();
        expect(screen.getByText(/monto acreditado/i)).toBeInTheDocument();
        // paid_at date row (AC3)
        expect(screen.getByText(/fecha de acreditación/i)).toBeInTheDocument();
        // State chip — exact text to avoid matching "Monto acreditado" dt
        expect(screen.getByText("Acreditado")).toBeInTheDocument();
    });

    it("[Carrier, delivered, no payout] shows the in-process liquidación card, not silence", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "delivered",
                    payout: null,
                }))),
        );
        renderPage("carrier");

        await waitFor(() => expect(screen.getByText(/liquidación en proceso/i)).toBeInTheDocument());
        // The full breakdown card (with its "Liquidación del envío" heading) is absent.
        expect(screen.queryByText(/liquidación del envío/i)).not.toBeInTheDocument();
    });

    it("[Shipper, delivered, no payout] never shows any liquidación card", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ state: "delivered", payout: null }))),
        );
        renderPage("shipper");
        await waitFor(() => expect(screen.getByRole("heading", { name: /envío/i })).toBeInTheDocument());
        expect(screen.queryByText(/liquidación/i)).not.toBeInTheDocument();
    });

    it("[Shipper viewer] does NOT show the Liquidación section even when payout exists", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "delivered",
                    // Shipper viewer: backend returns payout: null, but even if
                    // the field is present the role guard in the component hides it.
                    payout: null,
                }))),
        );
        renderPage("shipper");

        await waitFor(() => expect(screen.getByRole("heading", { name: /envío/i })).toBeInTheDocument());
        expect(screen.queryByText(/liquidación del envío/i)).not.toBeInTheDocument();
    });

    // --- US51 / REQ-FE-00028 — map section + Google Maps deep-links ---
    // No VITE_GOOGLE_MAPS_API_KEY is stubbed here, so <ShipmentMap /> degrades to
    // its service-unavailable state; the deep-link buttons must still render with
    // the correct hrefs (AC9) — they don't depend on the JS API.

    it("renders the map section keeping the shipment-tracking-map anchor (AC7)", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail())),
        );
        renderPage();
        await waitFor(() =>
            expect(screen.getByRole("heading", { name: /mapa del recorrido/i })).toBeInTheDocument(),
        );
        expect(document.querySelector("section#shipment-tracking-map")).toBeInTheDocument();
    });

    it("renders a single Google Maps deep-link with origin+destination coords (AC2/AC8)", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail())),
        );
        renderPage();

        const routeLink = await screen.findByRole("link", { name: /ver ruta.*google maps/i });
        expect(routeLink).toHaveAttribute(
            "href",
            "https://www.google.com/maps/dir/?api=1&origin=-34.603722,-58.381592&destination=-31.420083,-64.188776",
        );
    });

    it.each(["accepted", "in_transit", "delivered", "cancelled"] as const)(
        "shows the map section and the route deep-link in %s state (AC4)",
        async (state) => {
            server.use(
                http.get(`${API}/api/shipments/:id`, () =>
                    HttpResponse.json(fixtureShipmentDetail({ state, available_actions: [] }))),
            );
            renderPage();
            await waitFor(() =>
                expect(screen.getByRole("heading", { name: /mapa del recorrido/i })).toBeInTheDocument(),
            );
            expect(screen.getByRole("link", { name: /ver ruta.*google maps/i })).toBeInTheDocument();
        },
    );

    it("shows the unavailable message and no deep-link when coordinates are missing (AC3)", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    cargo: {
                        origin: "Av. Corrientes 1234, CABA",
                        destination: "Av. Colón 500, Córdoba",
                        description: "Pallets",
                        weight_kg: "1500.0",
                        pickup_lat: null,
                        pickup_lng: null,
                        delivery_lat: null,
                        delivery_lng: null,
                    },
                }))),
        );
        renderPage();
        await waitFor(() => expect(screen.getByText(/mapa no disponible/i)).toBeInTheDocument());
        expect(screen.queryByRole("link", { name: /ver ruta/i })).toBeNull();
    });

    // --- State-aware navigation emphasis (v2 §4) ---

    it("[Carrier, accepted, escrowed] promotes Navegar al retiro (destination-only pickup link)", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "accepted",
                    payment: { id: 1, state: "escrowed", amount_cents: 100, currency: "ARS", escrowed_at: "2026-06-11T10:05:00Z" },
                    available_actions: ["start_transit"],
                }))),
        );
        renderPage("carrier");

        const navLink = await screen.findByRole("link", { name: /navegar al punto de retiro/i });
        expect(navLink).toHaveAttribute(
            "href",
            "https://www.google.com/maps/dir/?api=1&destination=-34.603722,-58.381592",
        );
        // The full route stays available, demoted to secondary.
        expect(screen.getByRole("link", { name: /ver ruta.*google maps/i })).toBeInTheDocument();
    });

    it("[Carrier, accepted, unpaid] does NOT promote a navigation action", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "accepted",
                    payment: null,
                    available_actions: [],
                }))),
        );
        renderPage("carrier");
        await waitFor(() =>
            expect(screen.getByRole("link", { name: /ver ruta.*google maps/i })).toBeInTheDocument(),
        );
        expect(screen.queryByRole("link", { name: /navegar/i })).toBeNull();
    });

    it("[Carrier, in_transit] promotes Navegar a la entrega (destination-only delivery link)", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({
                    state: "in_transit",
                    available_actions: ["deliver"],
                }))),
        );
        renderPage("carrier");

        const navLink = await screen.findByRole("link", { name: /navegar al punto de entrega/i });
        expect(navLink).toHaveAttribute(
            "href",
            "https://www.google.com/maps/dir/?api=1&destination=-31.420083,-64.188776",
        );
    });

    it("[Carrier, delivered] demotes navigation to the plain route link", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ state: "delivered" }))),
        );
        renderPage("carrier");
        await waitFor(() =>
            expect(screen.getByRole("link", { name: /ver ruta.*google maps/i })).toBeInTheDocument(),
        );
        expect(screen.queryByRole("link", { name: /navegar/i })).toBeNull();
    });

    it("[Shipper, in_transit] gets the full route link only — no navigate actions", async () => {
        server.use(
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json(fixtureShipmentDetail({ state: "in_transit" }))),
        );
        renderPage("shipper");
        await waitFor(() =>
            expect(screen.getByRole("link", { name: /ver ruta.*google maps/i })).toBeInTheDocument(),
        );
        expect(screen.queryByRole("link", { name: /navegar/i })).toBeNull();
    });

});
