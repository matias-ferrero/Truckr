import { describe, expect, it } from "vitest";
import { render, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { http, HttpResponse, delay } from "msw";
import { server } from "../test/mocks/server";
import { AuthProvider } from "./AuthContext";
import { setJwt, getJwt } from "../api";

const API = "http://localhost:3000";

function renderProvider() {
    return render(
        <MemoryRouter>
            <AuthProvider>
                <div data-testid="child" />
            </AuthProvider>
        </MemoryRouter>,
    );
}

describe("AuthProvider — bootstrap clearJwt guard", () => {
    it("does not wipe a token stored after mount when the bootstrap 401 arrives late", async () => {
        // Regression: ImpersonatePage calls setJwt(token) then window.location.replace("/").
        // The old-page AuthProvider started an anonymous /me fetch before ImpersonatePage
        // stored the token. If that 401 arrives after setJwt() runs, clearJwt() must be
        // skipped because the token in storage is newer than the one sent with the request.

        // Delay the 401 so we can store a token in-flight.
        server.use(
            http.get(`${API}/api/auth/me`, async () => {
                await delay(50);
                return HttpResponse.json(
                    { error: { code: "unauthorized", message: "Autenticación requerida" } },
                    { status: 401 },
                );
            }),
        );

        renderProvider();

        // Store a fresh token while the delayed /me request is still in-flight.
        setJwt("impersonation.token.value");

        // Wait for the 401 response to be processed.
        await waitFor(() => expect(getJwt()).toBe("impersonation.token.value"), { timeout: 500 });
    });

    it("still clears a stale token when the 401 arrives and no new token was stored", async () => {
        setJwt("stale.token.value");

        server.use(
            http.get(`${API}/api/auth/me`, () =>
                HttpResponse.json(
                    { error: { code: "unauthorized", message: "Autenticación requerida" } },
                    { status: 401 },
                ),
            ),
        );

        renderProvider();

        await waitFor(() => expect(getJwt()).toBeNull());
    });
});
