import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createCargoOffer, listMyCargoOffers } from "./cargoOffers";

const BASE = "http://localhost:3000";

function makeCargoOffer(overrides: Record<string, unknown> = {}) {
    return {
        id: 1,
        cargo_id: 7,
        carrier_id: 1,
        transport_window_id: 5,
        amount_cents: 105_000_000,
        currency: "ARS",
        status: "pending",
        expires_at: "2026-05-27T10:00:00Z",
        created_at: "2026-05-20T10:00:00Z",
        updated_at: "2026-05-20T10:00:00Z",
        cargo: {
            pickup_address: "Av. Corrientes 1234, CABA",
            delivery_address: "Av. Colón 500, Córdoba",
            pickup_window_start: "2026-05-25T08:00:00Z",
            pickup_window_end: "2026-05-26T18:00:00Z",
            cargo_description: "Pallets",
        },
        ...overrides,
    };
}

function mockFetch(body: unknown, status = 200, headers: Record<string, string> = {}) {
    const res = new Response(JSON.stringify(body), {
        status,
        headers: { "Content-Type": "application/json", ...headers },
    });
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(res));
}

beforeEach(() => {
    vi.unstubAllGlobals();
});

// Restore globals so the trailing `fetch` stub doesn't leak into other suites.
afterEach(() => {
    vi.unstubAllGlobals();
});

describe("listMyCargoOffers", () => {
    it("returns items and pagination meta from response headers", async () => {
        mockFetch([makeCargoOffer()], 200, {
            "X-Total": "5",
            "X-Page": "1",
            "X-Per-Page": "20",
            "X-Total-Pages": "1",
        });
        const result = await listMyCargoOffers();
        expect(result.items).toHaveLength(1);
        expect(result.items[0].status).toBe("pending");
        expect(result.items[0].cargo?.pickup_window_start).toBe(
            "2026-05-25T08:00:00Z",
        );
        expect(result.meta.total).toBe(5);
    });

    it("defaults meta to safe values when pagination headers are absent", async () => {
        mockFetch([makeCargoOffer()], 200);
        const result = await listMyCargoOffers();
        expect(result.meta.total).toBe(0);
        expect(result.meta.page).toBe(1);
        expect(result.meta.totalPages).toBe(1);
    });

    it("passes the page param in the query string", async () => {
        mockFetch([], 200);
        await listMyCargoOffers(3);
        const url = vi.mocked(fetch).mock.calls[0][0] as string;
        expect(url).toContain("page=3");
    });

    it("throws with status on a non-ok response", async () => {
        mockFetch({ error: { message: "Unauthorized" } }, 401);
        await expect(listMyCargoOffers()).rejects.toMatchObject({
            message: "Unauthorized",
            status: 401,
        });
    });

    it("throws a generic HTTP error when response body is not JSON", async () => {
        vi.stubGlobal(
            "fetch",
            vi.fn().mockResolvedValue(new Response("not json", { status: 500 })),
        );
        await expect(listMyCargoOffers()).rejects.toMatchObject({ status: 500 });
    });
});

describe("createCargoOffer", () => {
    it("posts cargo_id in the body alongside the offer draft", async () => {
        mockFetch(makeCargoOffer(), 201);
        const offer = await createCargoOffer(7, {
            transport_window_id: 5,
            estimated_km: "700",
        });
        expect(offer.cargo_id).toBe(7);

        const init = vi.mocked(fetch).mock.calls[0][1] as RequestInit;
        const body = JSON.parse(init.body as string);
        expect(body).toEqual({
            cargo_offer: {
                cargo_id: 7,
                transport_window_id: 5,
                estimated_km: "700",
            },
        });
        expect(init.method).toBe("POST");
        const url = vi.mocked(fetch).mock.calls[0][0] as string;
        expect(url).toBe(`${BASE}/api/cargo_offers`);
    });

    it("surfaces the ApiError envelope on a 422 response", async () => {
        mockFetch(
            {
                error: {
                    code: "unprocessable",
                    message: "Validación fallida",
                    details: { transport_window: ["ya tiene una oferta"] },
                },
            },
            422,
        );
        await expect(
            createCargoOffer(7, { transport_window_id: 5, estimated_km: "700" }),
        ).rejects.toMatchObject({ status: 422, code: "unprocessable" });
    });
});
