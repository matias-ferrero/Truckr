import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { http, HttpResponse } from "msw";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { server } from "../../test/mocks/server";
import { AuthProvider, type Me } from "../../auth/AuthContext";
import CarrierMeRedirect from "./CarrierMeRedirect";

const API = "http://localhost:3000";

function meResponse(roles: Me["roles"], carrierId: number | null = 1): Me {
    return {
        id: 1,
        email: "user@example.com",
        full_name: "Test User",
        phone: null,
        verified_at: null,
        roles,
        carrier: roles.includes("carrier") && carrierId != null ? { id: carrierId } : null,
        shipper: roles.includes("shipper") ? { id: 1 } : null,
    };
}

const mountAt = (path: string) =>
    render(
        <MemoryRouter initialEntries={[path]}>
            <AuthProvider>
                <Routes>
                    <Route path="/carriers/me" element={<CarrierMeRedirect />} />
                    <Route path="/carriers/:id" element={<div>carrier-profile-{":id"}</div>} />
                    <Route path="/login" element={<div>login-screen</div>} />
                    <Route path="/" element={<div>home-screen</div>} />
                </Routes>
            </AuthProvider>
        </MemoryRouter>,
    );

describe("CarrierMeRedirect", () => {
    it("redirects anonymous users to /login", async () => {
        // Default handler: /me → 401
        mountAt("/carriers/me");
        expect(await screen.findByText("login-screen")).toBeInTheDocument();
    });

    it("redirects authenticated carriers to /carriers/:id", async () => {
        server.use(http.get(`${API}/api/auth/me`, () => HttpResponse.json(meResponse(["carrier"], 42))));
        render(
            <MemoryRouter initialEntries={["/carriers/me"]}>
                <AuthProvider>
                    <Routes>
                        <Route path="/carriers/me" element={<CarrierMeRedirect />} />
                        <Route path="/carriers/:id" element={<div data-testid="carrier-profile">profile</div>} />
                    </Routes>
                </AuthProvider>
            </MemoryRouter>,
        );
        expect(await screen.findByTestId("carrier-profile")).toBeInTheDocument();
    });

    it("redirects authenticated non-carriers to /", async () => {
        server.use(http.get(`${API}/api/auth/me`, () => HttpResponse.json(meResponse(["shipper"]))));
        mountAt("/carriers/me");
        expect(await screen.findByText("home-screen")).toBeInTheDocument();
    });
});
