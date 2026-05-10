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

    it("shows email + Salir when authenticated and logs out on click", async () => {
        server.use(
            http.get(`${API}/api/auth/me`, () =>
                HttpResponse.json({
                    id: 5,
                    email: "widget@example.com",
                    full_name: "W",
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

        await waitFor(() => expect(screen.getByText("widget@example.com")).toBeInTheDocument());
        await user.click(screen.getByRole("button", { name: /salir/i }));
        await waitFor(() =>
            expect(screen.queryByText("widget@example.com")).not.toBeInTheDocument()
        );
    });
});
