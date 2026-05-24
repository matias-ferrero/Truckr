import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { listCarrierShipments } from "./shipments";

const BASE = "http://localhost:3000";

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

afterEach(() => {
    vi.unstubAllGlobals();
});

describe("listCarrierShipments", () => {
    it("requests in-progress shipments by default", async () => {
        mockFetch([], 200, {
            "X-Total": "0",
            "X-Page": "1",
            "X-Per-Page": "20",
            "X-Total-Pages": "1",
        });

        await listCarrierShipments(undefined, 1);
        const url = vi.mocked(fetch).mock.calls[0][0] as string;
        expect(url).toBe(`${BASE}/api/carriers/me/shipments?page=1`);
    });

    it("passes explicit status filter", async () => {
        mockFetch([], 200);
        await listCarrierShipments("delivered", 2);
        const url = vi.mocked(fetch).mock.calls[0][0] as string;
        expect(url).toBe(`${BASE}/api/carriers/me/shipments?page=2&status=delivered`);
    });
});
