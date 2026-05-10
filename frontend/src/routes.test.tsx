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
        );

        window.history.pushState({}, "", "/carrier/vehicles");
        render(<AppRoutes />);

        const skipLinks = await screen.findAllByText(/saltar al contenido/i);
        expect(skipLinks.length).toBeGreaterThan(0);
    });

    it("falls through unknown paths to the landing", async () => {
        window.history.pushState({}, "", "/no-such-route");
        render(<AppRoutes />);
        await waitFor(() =>
            expect(screen.getByRole("heading", { level: 1 })).toBeInTheDocument()
        );
    });
});
