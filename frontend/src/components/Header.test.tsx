import { describe, expect, it } from "vitest";
import { http, HttpResponse } from "msw";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { server } from "../test/mocks/server";
import { AuthProvider } from "../auth/AuthContext";
import { Header } from "./Header";

const API = "http://localhost:3000";

const renderHeader = (initial = "/login") =>
    render(
        <MemoryRouter initialEntries={[initial]}>
            <AuthProvider>
                <Routes>
                    <Route path="*" element={<Header />} />
                </Routes>
            </AuthProvider>
        </MemoryRouter>,
    );

describe("Header", () => {
    it("shows login + register links when anonymous", async () => {
        // Explicitly force 401 regardless of any JWT in storage from concurrent tests.
        server.use(http.get(`${API}/api/auth/me`, () =>
            HttpResponse.json({ error: "unauthorized" }, { status: 401 }),
        ));
        renderHeader("/");
        await waitFor(() =>
            expect(screen.getByRole("link", { name: /iniciar sesión/i })).toBeInTheDocument()
        );
        expect(screen.getByRole("link", { name: /crear cuenta/i })).toBeInTheDocument();
    });

    it("hides the redundant link on the page you are on", async () => {
        renderHeader("/login");
        await waitFor(() =>
            expect(screen.getByRole("link", { name: /crear cuenta/i })).toBeInTheDocument()
        );
        expect(screen.queryByRole("link", { name: /iniciar sesión/i })).toBeNull();
    });

    it("shows email + Salir button when authenticated", async () => {
        server.use(
            http.get(`${API}/api/auth/me`, () =>
                HttpResponse.json({
                    id: 9,
                    email: "logged@example.com",
                    full_name: "Logged",
                    phone: null,
                    verified_at: null,
                    roles: ["shipper"],
                    carrier: null,
                    shipper: { id: 1 },
                })
            ),
        );

        renderHeader("/");
        await waitFor(() => expect(screen.getByText("Logged")).toBeInTheDocument());
        expect(screen.getByRole("button", { name: /salir/i })).toBeInTheDocument();
        // Shippers' name button is the single profile entry point → /shippers/me.
        expect(screen.getByRole("link", { name: /perfil público de logged/i }))
            .toHaveAttribute("href", "/shippers/me");
        // No standalone "Mi perfil" link; the name button replaces it.
        expect(screen.queryByRole("link", { name: /^mi perfil$/i })).toBeNull();
    });

    it("points the profile chip at /carriers/me for carriers", async () => {
        server.use(
            http.get(`${API}/api/auth/me`, () =>
                HttpResponse.json({
                    id: 9,
                    email: "carrier@example.com",
                    full_name: "Carrier User",
                    phone: null,
                    verified_at: null,
                    roles: ["carrier"],
                    carrier: { id: 7 },
                    shipper: null,
                })
            ),
            http.get(`${API}/api/carriers/me/cargo-offers`, () =>
                HttpResponse.json([], {
                    headers: {
                        "X-Total": "3",
                        "X-Page": "1",
                        "X-Per-Page": "20",
                        "X-Total-Pages": "1",
                    },
                })
            ),
        );

        renderHeader("/");
        await waitFor(() => expect(screen.getByText("Carrier User")).toBeInTheDocument());
        expect(screen.getByRole("link", { name: /perfil público de carrier user/i }))
            .toHaveAttribute("href", "/carriers/me");
        // Carrier section links + the pending-offers badge moved to the Sidebar.
        expect(screen.queryByRole("link", { name: /bandeja/i })).toBeNull();
        expect(screen.queryByRole("link", { name: /mis pagos/i })).toBeNull();
        expect(screen.queryByRole("link", { name: /mis viajes/i })).toBeNull();
        expect(screen.queryByRole("link", { name: /envíos/i })).toBeNull();
        // Even with pending offers, the header shows no badge now.
        expect(screen.queryByText(/pendientes/i)).toBeNull();
    });

    it("logs out when Salir is clicked", async () => {
        server.use(
            http.get(`${API}/api/auth/me`, () =>
                HttpResponse.json({
                    id: 9,
                    email: "logged@example.com",
                    full_name: "Logged",
                    phone: null,
                    verified_at: null,
                    roles: ["shipper"],
                    carrier: null,
                    shipper: { id: 1 },
                })
            ),
        );

        const user = userEvent.setup();
        renderHeader("/");

        await waitFor(() => expect(screen.getByText("Logged")).toBeInTheDocument());
        await user.click(screen.getByRole("button", { name: /salir/i }));

        await waitFor(() =>
            expect(screen.queryByText("Logged")).not.toBeInTheDocument()
        );
    });
});
