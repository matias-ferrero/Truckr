import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { listCarrierShipments, listShipperShipments } from "./shipments";

const BASE = "http://localhost:3000";

function mockFetch(body: unknown, status = 200) {
    const res = new Response(JSON.stringify(body), {
        status,
        headers: { "Content-Type": "application/json" },
    });
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(res));
}

beforeEach(() => {
    vi.unstubAllGlobals();
});

afterEach(() => {
    vi.unstubAllGlobals();
});

describe("listCarrierShipments", () => {
    it("calls GET /api/carriers/me/shipments", async () => {
        mockFetch([]);
        await listCarrierShipments();
        const url = vi.mocked(fetch).mock.calls[0][0] as string;
        expect(url).toBe(`${BASE}/api/carriers/me/shipments`);
    });

    it("returns the parsed array from the response", async () => {
        const fixture = [
            {
                id: 31,
                state: "accepted",
                origin: "CABA",
                destination: "Córdoba",
                created_at: "2026-06-11T10:00:00Z",
                amount_cents: 105_000_000,
                currency: "ARS",
                latest_activity_at: "2026-06-11T10:00:00Z",
            },
        ];
        mockFetch(fixture);
        const result = await listCarrierShipments();
        expect(result).toHaveLength(1);
        expect(result[0].state).toBe("accepted");
    });
});

describe("listShipperShipments", () => {
    it("calls GET /api/shippers/me/shipments", async () => {
        mockFetch([]);
        await listShipperShipments();
        const url = vi.mocked(fetch).mock.calls[0][0] as string;
        expect(url).toBe(`${BASE}/api/shippers/me/shipments`);
    });

    it("returns the parsed array from the response", async () => {
        const fixture = [
            {
                id: 42,
                state: "delivered",
                origin: "CABA",
                destination: "Mendoza",
                created_at: "2026-06-11T10:00:00Z",
                amount_cents: 80_000_000,
                currency: "ARS",
                latest_activity_at: "2026-06-12T10:00:00Z",
            },
        ];
        mockFetch(fixture);
        const result = await listShipperShipments();
        expect(result).toHaveLength(1);
        expect(result[0].state).toBe("delivered");
    });
});
