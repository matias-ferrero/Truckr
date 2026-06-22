import { describe, expect, it } from "vitest";
import { http, HttpResponse } from "msw";
import { render, screen, waitFor, within } from "@testing-library/react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { server } from "../test/mocks/server";
import { AuthProvider } from "../auth/AuthContext";
import { Sidebar } from "./Sidebar";

const API = "http://localhost:3000";

type Roles = Array<"carrier" | "shipper">;

const mockMe = (roles: Roles) =>
    server.use(
        http.get(`${API}/api/auth/me`, () =>
            HttpResponse.json({
                id: 9,
                email: "user@example.com",
                full_name: "Test User",
                phone: null,
                verified_at: null,
                roles,
                carrier: roles.includes("carrier") ? { id: 1 } : null,
                shipper: roles.includes("shipper") ? { id: 1 } : null,
            })
        ),
    );

const renderSidebar = (initial = "/") =>
    render(
        <MemoryRouter initialEntries={[initial]}>
            <AuthProvider>
                <Routes>
                    <Route path="*" element={<Sidebar />} />
                </Routes>
            </AuthProvider>
        </MemoryRouter>,
    );

describe("Sidebar", () => {
    it("renders nothing for anonymous visitors", async () => {
        server.use(http.get(`${API}/api/auth/me`, () =>
            HttpResponse.json({ error: "unauthorized" }, { status: 401 }),
        ));
        const { container } = renderSidebar("/");
        // Give the auth fetch a tick to resolve, then assert no nav rendered.
        await waitFor(() => expect(screen.queryByRole("navigation")).toBeNull());
        expect(container).toBeEmptyDOMElement();
    });

    it("shows the carrier group — including the moved 'Mis Pagos' — for carriers", async () => {
        mockMe(["carrier"]);
        renderSidebar("/carrier/vehicles");

        await waitFor(() =>
            expect(screen.getByRole("link", { name: "Vehículos" })).toBeInTheDocument()
        );
        expect(screen.getByRole("link", { name: "Inicio" })).toHaveAttribute(
            "href",
            "/carrier/dashboard",
        );
        expect(screen.getByRole("link", { name: "Disponibilidad" })).toHaveAttribute(
            "href",
            "/carrier/availability",
        );
        expect(screen.getByRole("link", { name: "Mis Pagos" })).toHaveAttribute(
            "href",
            "/carrier/payouts",
        );
        // No shipper-only items for a carrier-only user.
        expect(screen.queryByRole("link", { name: "Mis Cargas" })).toBeNull();
    });

    it("shows the live pending-offers badge on the Ofertas item", async () => {
        mockMe(["carrier"]);
        server.use(
            http.get(`${API}/api/carriers/me/cargo-offers`, () =>
                HttpResponse.json([], {
                    headers: { "X-Total": "3", "X-Page": "1", "X-Per-Page": "20", "X-Total-Pages": "1" },
                })
            ),
        );
        renderSidebar("/carrier/cargo-offers");

        // The dot shows just the number, inside the Ofertas link (row clickable),
        // while the full phrase rides on the link's accessible name for SR users.
        const offersLink = await screen.findByRole("link", { name: /3 ofertas pendientes/i });
        expect(within(offersLink).getByText("3")).toBeInTheDocument();
    });

    it("renders no badge when there are no pending offers", async () => {
        mockMe(["carrier"]);
        server.use(
            http.get(`${API}/api/carriers/me/cargo-offers`, () =>
                HttpResponse.json([], {
                    headers: { "X-Total": "0", "X-Page": "1", "X-Per-Page": "20", "X-Total-Pages": "1" },
                })
            ),
        );
        renderSidebar("/carrier/vehicles");

        await waitFor(() =>
            expect(screen.getByRole("link", { name: "Vehículos" })).toBeInTheDocument()
        );
        // No badge → the Ofertas link's accessible name is exactly "Ofertas".
        expect(screen.getByRole("link", { name: "Ofertas" })).toBeInTheDocument();
        expect(screen.queryByText(/pendientes/i)).toBeNull();
    });

    it("shows only the shipper group for shippers", async () => {
        mockMe(["shipper"]);
        renderSidebar("/shipper/dashboard");

        await waitFor(() =>
            expect(screen.getByRole("link", { name: "Mis Cargas" })).toBeInTheDocument()
        );
        expect(screen.getByRole("link", { name: "Inicio" })).toHaveAttribute(
            "href",
            "/shipper/dashboard",
        );
        expect(screen.queryByRole("link", { name: "Vehículos" })).toBeNull();
        expect(screen.queryByRole("link", { name: "Mis Pagos" })).toBeNull();
    });

    it("shows both groups for dual-role users", async () => {
        mockMe(["carrier", "shipper"]);
        renderSidebar("/");

        await waitFor(() =>
            expect(screen.getByRole("link", { name: "Vehículos" })).toBeInTheDocument()
        );
        expect(screen.getByRole("link", { name: "Mis Cargas" })).toBeInTheDocument();
        // "Inicio" and "Mis Envíos" exist in both groups → two links each.
        expect(screen.getAllByRole("link", { name: "Inicio" })).toHaveLength(2);
        expect(screen.getAllByRole("link", { name: "Mis Envíos" })).toHaveLength(2);
        // Each list is named via aria-labelledby so SR users can tell them apart.
        expect(screen.getByRole("list", { name: "Transportista" })).toBeInTheDocument();
        expect(screen.getByRole("list", { name: "Expedidor" })).toBeInTheDocument();
    });

    it("marks the active route with aria-current", async () => {
        mockMe(["carrier"]);
        renderSidebar("/carrier/payouts");

        await waitFor(() =>
            expect(screen.getByRole("link", { name: "Mis Pagos" })).toHaveAttribute(
                "aria-current",
                "page",
            )
        );
        expect(screen.getByRole("link", { name: "Vehículos" })).not.toHaveAttribute(
            "aria-current",
        );
    });
});
