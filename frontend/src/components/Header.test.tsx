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
        // Shipper falls back to /profile
        expect(screen.getByRole("link", { name: /perfil de logged/i }))
            .toHaveAttribute("href", "/profile");
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
        );

        renderHeader("/");
        await waitFor(() => expect(screen.getByText("Carrier User")).toBeInTheDocument());
        expect(screen.getByRole("link", { name: /perfil de carrier user/i }))
            .toHaveAttribute("href", "/carriers/me");
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
