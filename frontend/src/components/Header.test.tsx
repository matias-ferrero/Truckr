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
        await waitFor(() => expect(screen.getByText("logged@example.com")).toBeInTheDocument());
        expect(screen.getByRole("button", { name: /salir/i })).toBeInTheDocument();
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

        await waitFor(() => expect(screen.getByText("logged@example.com")).toBeInTheDocument());
        await user.click(screen.getByRole("button", { name: /salir/i }));

        await waitFor(() =>
            expect(screen.queryByText("logged@example.com")).not.toBeInTheDocument()
        );
    });
});
