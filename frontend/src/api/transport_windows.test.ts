import { describe, it, expect, vi, beforeEach } from "vitest";
import {
    listMyTransportWindows,
    createTransportWindow,
    updateTransportWindow,
    deactivateTransportWindow,
} from "./transport_windows";

const BASE = "http://localhost:3000";

function makeWindow(overrides = {}) {
    return {
        id: 1,
        vehicle_id: 10,
        origin_province: "Buenos Aires",
        origin_locality: null,
        destination_province: "Córdoba",
        destination_locality: null,
        price_per_km: "1500.0",
        max_km: 1200,
        available_from: "2026-05-15T00:00:00.000Z",
        available_to: "2026-05-25T00:00:00.000Z",
        active: true,
        vehicle: { id: 10, make: "MB", model: "Sprinter", plate: "AA001XX", vehicle_type: "truck_small" },
        created_at: "2026-05-11T00:00:00.000Z",
        updated_at: "2026-05-11T00:00:00.000Z",
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

describe("listMyTransportWindows", () => {
    it("returns items + pagination meta from headers", async () => {
        mockFetch([makeWindow()], 200, {
            "X-Total": "1",
            "X-Page": "1",
            "X-Per-Page": "20",
            "X-Total-Pages": "1",
        });
        const result = await listMyTransportWindows();
        expect(result.items).toHaveLength(1);
        expect(result.meta.total).toBe(1);
        expect(result.meta.page).toBe(1);
    });
});

describe("createTransportWindow", () => {
    it("POSTs with transport_window wrapper and returns created window", async () => {
        mockFetch(makeWindow(), 201);
        const draft = {
            vehicle_id: 10,
            origin_province: "BsAs",
            origin_locality: null,
            destination_province: "Córdoba",
            destination_locality: null,
            price_per_km: "1500",
            max_km: "1200",
            available_from: "2026-05-15T00:00",
            available_to: "2026-05-25T00:00",
        };
        const result = await createTransportWindow(draft);
        expect(result.id).toBe(1);
        const call = vi.mocked(fetch).mock.calls[0]!;
        const body = JSON.parse(call[1]!.body as string);
        expect(body).toHaveProperty("transport_window.vehicle_id", 10);
    });
});

describe("updateTransportWindow", () => {
    it("PATCHes with transport_window wrapper", async () => {
        mockFetch(makeWindow({ active: false }), 200);
        await updateTransportWindow(1, { active: false });
        const call = vi.mocked(fetch).mock.calls[0]!;
        expect(call[0]).toContain("/transport_windows/1");
        expect((call[1] as RequestInit).method).toBe("PATCH");
    });
});

describe("deactivateTransportWindow", () => {
    it("sends PATCH with active=false and resolves with updated window", async () => {
        const window = { id: 1, active: false };
        vi.stubGlobal("fetch", vi.fn().mockResolvedValue(
            new Response(JSON.stringify(window), { status: 200, headers: { "Content-Type": "application/json" } })
        ));
        const result = await deactivateTransportWindow(1);
        expect(result).toMatchObject({ active: false });
        expect(vi.mocked(fetch)).toHaveBeenCalledWith(
            expect.stringContaining("/transport_windows/1"),
            expect.objectContaining({ method: "PATCH" })
        );
    });
});
