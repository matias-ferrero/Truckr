import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { http, HttpResponse } from "msw";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { server } from "../test/mocks/server";
import { AuthProvider, type Me } from "./AuthContext";
import RequireShipper from "./RequireShipper";

const API = "http://localhost:3000";

function meResponse(roles: Me["roles"]): Me {
    return {
        id: 1,
        email: "user@example.com",
        full_name: "Test User",
        phone: null,
        verified_at: null,
        roles,
        carrier: roles.includes("carrier") ? { id: 1 } : null,
        shipper: roles.includes("shipper") ? { id: 1 } : null,
    };
}

const mountAt = (path: string) =>
    render(
        <MemoryRouter initialEntries={[path]}>
            <AuthProvider>
                <Routes>
                    <Route
                        path="/carriers/:id/offers/new"
                        element={
                            <RequireShipper>
                                <div>wizard-content</div>
                            </RequireShipper>
                        }
                    />
                    <Route path="/login" element={<div>login-screen</div>} />
                    <Route path="/" element={<div>home-screen</div>} />
                </Routes>
            </AuthProvider>
        </MemoryRouter>,
    );

describe("RequireShipper", () => {
    it("redirects anonymous users to /login", async () => {
        mountAt("/carriers/1/offers/new");
        expect(await screen.findByText("login-screen")).toBeInTheDocument();
    });

    it("redirects carrier-only users to /", async () => {
        server.use(
            http.get(`${API}/api/auth/me`, () =>
                HttpResponse.json(meResponse(["carrier"])),
            ),
        );
        mountAt("/carriers/1/offers/new");
        expect(await screen.findByText("home-screen")).toBeInTheDocument();
    });

    it("renders children for users with the shipper role", async () => {
        server.use(
            http.get(`${API}/api/auth/me`, () =>
                HttpResponse.json(meResponse(["shipper"])),
            ),
        );
        mountAt("/carriers/1/offers/new");
        expect(await screen.findByText("wizard-content")).toBeInTheDocument();
    });
});
