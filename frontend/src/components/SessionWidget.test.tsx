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

        // Carrier display name shown as a link to their public profile
        const profileLink = await screen.findByRole("link", { name: /perfil público de wanda/i });
        expect(profileLink).toHaveAttribute("href", "/carriers/me");
        expect(profileLink).toHaveTextContent("Wanda");

        // Account settings link is shown for any authenticated user.
        const accountLink = screen.getByRole("link", { name: /mi perfil/i });
        expect(accountLink).toHaveAttribute("href", "/profile");

        await user.click(screen.getByRole("button", { name: /salir/i }));
        await waitFor(() =>
            expect(screen.queryByText("Wanda")).not.toBeInTheDocument()
        );
    });

    it("renders a non-link chip for shippers (no public profile)", async () => {
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

        await waitFor(() => expect(screen.getByText("Sam")).toBeInTheDocument());
        expect(screen.queryByRole("link", { name: /perfil público de sam/i })).toBeNull();
        expect(screen.getByLabelText(/sesión como sam/i)).toBeInTheDocument();

        // Shippers also get a Mi perfil link to /profile.
        const accountLink = screen.getByRole("link", { name: /mi perfil/i });
        expect(accountLink).toHaveAttribute("href", "/profile");
    });
});
