// @vitest-environment happy-dom
import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { http, HttpResponse } from "msw";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { server } from "../../test/mocks/server";
import { AuthProvider, type Me } from "../../auth/AuthContext";
import ShipperMeRedirect from "./ShipperMeRedirect";

const API = "http://localhost:3000";

function meResponse(roles: Me["roles"], shipperId: number | null = 1): Me {
    return {
        id: 1,
        email: "user@example.com",
        full_name: "Test User",
        phone: null,
        verified_at: null,
        roles,
        carrier: roles.includes("carrier") ? { id: 1 } : null,
        shipper: roles.includes("shipper") && shipperId != null ? { id: shipperId } : null,
    };
}

const mountAt = (path: string) =>
    render(
        <MemoryRouter initialEntries={[path]}>
            <AuthProvider>
                <Routes>
                    <Route path="/shippers/me" element={<ShipperMeRedirect />} />
                    <Route path="/shippers/:id" element={<div>shipper-profile</div>} />
                    <Route path="/login" element={<div>login-screen</div>} />
                    <Route path="/" element={<div>home-screen</div>} />
                </Routes>
            </AuthProvider>
        </MemoryRouter>,
    );

describe("ShipperMeRedirect", () => {
    it("redirects anonymous users to /login", async () => {
        mountAt("/shippers/me");
        expect(await screen.findByText("login-screen")).toBeInTheDocument();
    });

    it("redirects authenticated shippers to /shippers/:id", async () => {
        server.use(http.get(`${API}/api/auth/me`, () => HttpResponse.json(meResponse(["shipper"], 42))));
        mountAt("/shippers/me");
        expect(await screen.findByText("shipper-profile")).toBeInTheDocument();
    });

    it("redirects authenticated non-shippers to /", async () => {
        server.use(http.get(`${API}/api/auth/me`, () => HttpResponse.json(meResponse(["carrier"]))));
        mountAt("/shippers/me");
        expect(await screen.findByText("home-screen")).toBeInTheDocument();
    });
});
