import { describe, it, expect, vi, beforeEach } from "vitest";
import { listMyQuotes } from "./quotes";

const BASE = "http://localhost:3000";

function makeQuote(overrides: Record<string, unknown> = {}) {
    return {
        id: 1,
        cargo_offer_id: 1,
        carrier_id: 1,
        transport_window_id: 1,
        amount_cents: 105_000_000,
        currency: "ARS",
        status: "pending",
        expires_at: "2026-06-01T00:00:00Z",
        created_at: "2026-05-20T10:00:00Z",
        updated_at: "2026-05-20T10:00:00Z",
        cargo_offer: {
            pickup_address: "Av. Corrientes 1234, C1043 CABA, Ciudad Autónoma de Buenos Aires",
            delivery_address: "Av. Colón 500, X5000 Córdoba, Córdoba",
            pickup_date: "2026-05-25",
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
    vi.stubGlobal("API_BASE_URL", BASE);
});

describe("listMyQuotes", () => {
    it("returns items and pagination meta from response headers", async () => {
        mockFetch([makeQuote()], 200, {
            "X-Total": "5",
            "X-Page": "1",
            "X-Per-Page": "20",
            "X-Total-Pages": "1",
        });
        const result = await listMyQuotes();
        expect(result.items).toHaveLength(1);
        expect(result.items[0].status).toBe("pending");
        expect(result.items[0].cargo_offer?.pickup_date).toBe("2026-05-25");
        expect(result.meta.total).toBe(5);
        expect(result.meta.page).toBe(1);
        expect(result.meta.perPage).toBe(20);
    });

    it("defaults meta to safe values when pagination headers are absent", async () => {
        mockFetch([makeQuote()], 200);
        const result = await listMyQuotes();
        expect(result.meta.total).toBe(0);
        expect(result.meta.page).toBe(1);
        expect(result.meta.perPage).toBe(20);
        expect(result.meta.totalPages).toBe(1);
    });

    it("passes the page param in the query string", async () => {
        mockFetch([], 200);
        await listMyQuotes(3);
        const url = (vi.mocked(fetch).mock.calls[0][0] as string);
        expect(url).toContain("page=3");
    });

    it("attaches Authorization header when a JWT is stored", async () => {
        vi.stubGlobal("localStorage", {
            getItem: vi.fn().mockReturnValue("test.jwt.token"),
            setItem: vi.fn(),
            removeItem: vi.fn(),
            clear: vi.fn(),
        });
        mockFetch([], 200);
        await listMyQuotes();
        const init = vi.mocked(fetch).mock.calls[0][1] as RequestInit;
        expect((init.headers as Record<string, string>)["Authorization"]).toBe(
            "Bearer test.jwt.token",
        );
    });

    it("throws with status on a non-ok response", async () => {
        mockFetch({ error: { message: "Unauthorized" } }, 401);
        await expect(listMyQuotes()).rejects.toMatchObject({
            message: "Unauthorized",
            status: 401,
        });
    });

    it("throws a generic HTTP error when response body is not JSON", async () => {
        vi.stubGlobal(
            "fetch",
            vi.fn().mockResolvedValue(new Response("not json", { status: 500 })),
        );
        await expect(listMyQuotes()).rejects.toMatchObject({ status: 500 });
    });
});
