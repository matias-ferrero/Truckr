import { describe, expect, it } from "vitest";
import { http, HttpResponse } from "msw";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter } from "react-router-dom";
import { server } from "../test/mocks/server";
import { AuthProvider } from "../auth/AuthContext";
import { SessionWidget } from "./SessionWidget";

const API = "http://localhost:3000";

const renderWidget = () =>
    render(
        <MemoryRouter>
            <AuthProvider>
                <SessionWidget />
            </AuthProvider>
        </MemoryRouter>,
    );

describe("SessionWidget", () => {
    it("shows login + register links when anonymous", async () => {
        // Explicitly force 401 regardless of any JWT in storage from concurrent tests.
        server.use(http.get(`${API}/api/auth/me`, () =>
            HttpResponse.json({ error: "unauthorized" }, { status: 401 }),
        ));
        renderWidget();
        await waitFor(() =>
            expect(screen.getByRole("link", { name: /iniciar sesión/i })).toBeInTheDocument()
        );
        expect(screen.getByRole("link", { name: /crear cuenta/i })).toBeInTheDocument();
    });

    it("shows the display name + Salir when authenticated and logs out on click", async () => {
        server.use(
            http.get(`${API}/api/auth/me`, () =>
                HttpResponse.json({
                    id: 5,
                    email: "widget@example.com",
                    full_name: "Wanda",
                    phone: null,
                    verified_at: null,
                    roles: ["carrier"],
                    carrier: { id: 1 },
                    shipper: null,
                })
            ),
        );

        const user = userEvent.setup();
        renderWidget();

        // Carrier display name is the single profile entry point and
        // points at the public profile (which links to /profile to edit).
        const profileLink = await screen.findByRole("link", { name: /perfil público de wanda/i });
        expect(profileLink).toHaveAttribute("href", "/carriers/me");
        expect(profileLink).toHaveTextContent("Wanda");

        // No redundant "Mi perfil" link — the name button is the entry point.
        expect(screen.queryByRole("link", { name: /^mi perfil$/i })).toBeNull();

        await user.click(screen.getByRole("button", { name: /salir/i }));
        await waitFor(() =>
            expect(screen.queryByText("Wanda")).not.toBeInTheDocument()
        );
    });

    it("points the shipper's name link at /shippers/me (public profile)", async () => {
        server.use(
            http.get(`${API}/api/auth/me`, () =>
                HttpResponse.json({
                    id: 6,
                    email: "ship@example.com",
                    full_name: "Sam",
                    phone: null,
                    verified_at: null,
                    roles: ["shipper"],
                    carrier: null,
                    shipper: { id: 1 },
                })
            ),
        );

        renderWidget();

        const nameLink = await screen.findByRole("link", { name: /perfil público de sam/i });
        expect(nameLink).toHaveAttribute("href", "/shippers/me");
        expect(nameLink).toHaveTextContent("Sam");
        // The name button is the single entry point — no redundant /profile link.
        expect(screen.queryByRole("link", { name: /^mi perfil$/i })).toBeNull();
    });
});
