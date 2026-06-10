import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import { http, HttpResponse } from "msw";
import { server } from "./test/mocks/server";
import { AppRoutes } from "./routes";

const API = "http://localhost:3000";

const carrierMe = {
    id: 1,
    email: "ana@example.com",
    full_name: "Ana",
    phone: null,
    verified_at: null,
    roles: ["carrier"],
    carrier: { id: 1 },
    shipper: null,
};

describe("AppRoutes", () => {
    beforeEach(() => {
        window.history.pushState({}, "", "/");
    });

    afterEach(() => {
        window.history.pushState({}, "", "/");
    });

    it("renders the landing on /", async () => {
        render(<AppRoutes />);
        await waitFor(() =>
            expect(screen.getByRole("heading", { level: 1 })).toBeInTheDocument()
        );
    });

    it("mounts AuthShell on /login (skipLink + Header)", async () => {
        window.history.pushState({}, "", "/login");
        render(<AppRoutes />);
        const skipLinks = await screen.findAllByText(/saltar al contenido/i);
        expect(skipLinks.length).toBeGreaterThan(0);
    });

    it("mounts AuthShell on /signup", async () => {
        window.history.pushState({}, "", "/signup");
        render(<AppRoutes />);
        const skipLinks = await screen.findAllByText(/saltar al contenido/i);
        expect(skipLinks.length).toBeGreaterThan(0);
    });

    it("mounts CarrierLayout for an authenticated carrier", async () => {
        server.use(
            http.get(`${API}/api/auth/me`, () => HttpResponse.json(carrierMe)),
            http.get(`${API}/api/carriers/me/vehicles`, () => HttpResponse.json([])),
            http.get(`${API}/api/carriers/me/cargo-offers`, () =>
                HttpResponse.json([], {
                    headers: {
                        "X-Total": "0",
                        "X-Page": "1",
                        "X-Per-Page": "20",
                        "X-Total-Pages": "1",
                    },
                })
            ),
        );

        window.history.pushState({}, "", "/carrier/vehicles");
        render(<AppRoutes />);

        const skipLinks = await screen.findAllByText(/saltar al contenido/i);
        expect(skipLinks.length).toBeGreaterThan(0);
    });

    it("renders carrier inbox route", async () => {
        server.use(
            http.get(`${API}/api/auth/me`, () => HttpResponse.json(carrierMe)),
            http.get(`${API}/api/carriers/me/cargo-offers`, () =>
                HttpResponse.json([], {
                    headers: {
                        "X-Total": "0",
                        "X-Page": "1",
                        "X-Per-Page": "20",
                        "X-Total-Pages": "1",
                    },
                })
            ),
        );

        window.history.pushState({}, "", "/carrier/cargo-offers");
        render(<AppRoutes />);

        await screen.findByRole("heading", { name: /ofertas recibidas/i }, { timeout: 5000 });
    });

    it("renders carrier shipments route", async () => {
        server.use(
            http.get(`${API}/api/auth/me`, () => HttpResponse.json(carrierMe)),
            http.get(`${API}/api/carriers/me/cargo-offers`, () =>
                HttpResponse.json([], {
                    headers: {
                        "X-Total": "0",
                        "X-Page": "1",
                        "X-Per-Page": "20",
                        "X-Total-Pages": "1",
                    },
                })
            ),
            http.get(`${API}/api/carriers/me/shipments`, () => HttpResponse.json([])),
        );

        window.history.pushState({}, "", "/carrier/shipments");
        render(<AppRoutes />);

        await waitFor(() =>
            expect(screen.getByRole("heading", { name: /mis envíos/i })).toBeInTheDocument()
        );
    });

    it("renders carrier shipment detail route", async () => {
        server.use(
            http.get(`${API}/api/auth/me`, () => HttpResponse.json(carrierMe)),
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json({
                    id: 31, state: "delivered", created_at: "2026-06-11T10:00:00Z",
                    amount_cents: 105_000_000, currency: "ARS",
                    cargo: { origin: "CABA", destination: "Córdoba", description: "P", weight_kg: "1500" },
                    vehicle: { plate: "AAA111", kind: "truck_small" },
                    counterparty: null, counterparty_contact: null, payment: null,
                    tracking_events: [], available_actions: [],
                })),
        );
        window.history.pushState({}, "", "/carrier/shipments/31");
        render(<AppRoutes />);
        await waitFor(() =>
            expect(screen.getByRole("heading", { name: /envío #31/i })).toBeInTheDocument()
        );
    });

    it("renders shipper shipment detail route", async () => {
        const shipperMe = { ...carrierMe, roles: ["shipper"], carrier: null,
            shipper: { id: 1, company_name: null, tax_id: null, billing_address: null } };
        server.use(
            http.get(`${API}/api/auth/me`, () => HttpResponse.json(shipperMe)),
            http.get(`${API}/api/shipments/:id`, () =>
                HttpResponse.json({
                    id: 42, state: "accepted", created_at: "2026-06-11T10:00:00Z",
                    amount_cents: 80_000_000, currency: "ARS",
                    cargo: { origin: "Mendoza", destination: "CABA", description: "Vino", weight_kg: "800" },
                    vehicle: { plate: "BBB222", kind: "truck_medium" },
                    counterparty: null, counterparty_contact: null, payment: null,
                    tracking_events: [], available_actions: ["pay"],
                })),
        );
        window.history.pushState({}, "", "/shipper/shipments/42");
        render(<AppRoutes />);
        await waitFor(() =>
            expect(screen.getByRole("heading", { name: /envío #42/i })).toBeInTheDocument()
        );
    });

    it("redirects a logged-in carrier from / to the carrier v2 dashboard", async () => {
        const listHeaders = {
            "X-Total": "0",
            "X-Page": "1",
            "X-Per-Page": "20",
            "X-Total-Pages": "1",
        };
        server.use(
            http.get(`${API}/api/auth/me`, () => HttpResponse.json(carrierMe)),
            http.get(`${API}/api/carriers/me/cargo-offers`, () =>
                HttpResponse.json([], { headers: listHeaders })),
            http.get(`${API}/api/carriers/me/shipments`, () => HttpResponse.json([])),
            http.get(`${API}/api/carriers/me/vehicles`, () =>
                HttpResponse.json([], { headers: listHeaders })),
            http.get(`${API}/api/carriers/me/transport_windows`, () =>
                HttpResponse.json([], { headers: listHeaders })),
            http.get(`${API}/api/carriers/me/activity`, () => HttpResponse.json([])),
        );
        window.history.pushState({}, "", "/");
        render(<AppRoutes />);
        // The carrier greeting proves we landed on the job-funnel dashboard,
        // not the retired multi-section one.
        await waitFor(() =>
            expect(screen.getByRole("heading", { name: /Hola, Ana/ })).toBeInTheDocument()
        );
        expect(window.location.pathname).toBe("/carrier/dashboard");
    });

    it("redirects a logged-in shipper from / to the v2 dashboard", async () => {
        const shipperMe = { ...carrierMe, roles: ["shipper"], carrier: null,
            shipper: { id: 1, company_name: null, tax_id: null, billing_address: null } };
        server.use(
            http.get(`${API}/api/auth/me`, () => HttpResponse.json(shipperMe)),
            http.get(`${API}/api/shippers/me/activity`, () => HttpResponse.json([])),
        );
        window.history.pushState({}, "", "/");
        render(<AppRoutes />);
        // The v2 greeting heading proves we landed on the Cargo-centric
        // dashboard, not the legacy multi-section one.
        await waitFor(() =>
            expect(screen.getByRole("heading", { name: /Hola, Ana/ })).toBeInTheDocument()
        );
        expect(window.location.pathname).toBe("/shipper/dashboard");
    });

    it("falls through unknown paths to the landing", async () => {
        window.history.pushState({}, "", "/no-such-route");
        render(<AppRoutes />);
        await waitFor(() =>
            expect(screen.getByRole("heading", { level: 1 })).toBeInTheDocument()
        );
    });
});
