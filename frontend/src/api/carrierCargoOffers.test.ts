import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
    acceptCarrierCargoOffer,
    listCarrierCargoOffers,
    rejectCarrierCargoOffer,
} from "./carrierCargoOffers";

const BASE = "http://localhost:3000";

function pendingOffer() {
    return {
        id: 11,
        cargo_id: 7,
        carrier_id: 1,
        transport_window_id: 5,
        status: "pending",
        expires_at: "2026-06-15T12:00:00Z",
        accepted_at: null,
        rejected_at: null,
        created_at: "2026-06-10T10:00:00Z",
        updated_at: "2026-06-10T10:00:00Z",
        price_amount_cents: 105_000_000,
        cargo: {
            id: 7,
            pickup_address: "Av. Corrientes 1234, CABA",
            delivery_address: "Av. Colón 500, Córdoba",
            weight_kg: "1500.0",
            volume_cm3: 3_000_000,
            declared_value_cents: 5_000_000,
            pickup_window_start: "2026-06-12T08:00:00Z",
            pickup_window_end: "2026-06-13T18:00:00Z",
            cargo_description: "Pallets",
            status: "open",
        },
        shipper: { id: 1, name: "Test User" },
        transport_window: {
            id: 5,
            origin_locality: "CABA",
            origin_admin_area: "Buenos Aires",
            destination_locality: "Córdoba",
            destination_admin_area: "Córdoba",
            available_from: "2026-06-11T08:00:00Z",
            available_to: "2026-06-16T18:00:00Z",
            price_per_km: "1500.0",
            max_km: 1000,
            status: "pending_offer",
        },
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

afterEach(() => {
    vi.unstubAllGlobals();
});

describe("listCarrierCargoOffers", () => {
    it("returns inbox items with pagination meta", async () => {
        mockFetch([pendingOffer()], 200, {
            "X-Total": "4",
            "X-Page": "1",
            "X-Per-Page": "20",
            "X-Total-Pages": "1",
        });

        const result = await listCarrierCargoOffers("pending", 1);
        expect(result.items).toHaveLength(1);
        expect(result.items[0].price_amount_cents).toBe(105_000_000);
        expect(result.meta.total).toBe(4);

        const url = vi.mocked(fetch).mock.calls[0][0] as string;
        expect(url).toBe(`${BASE}/api/carriers/me/cargo-offers?status=pending&page=1`);
    });
});

describe("acceptCarrierCargoOffer", () => {
    it("posts to accept endpoint", async () => {
        mockFetch({ cargo_offer: pendingOffer(), shipment: { id: 1 } }, 200);
        await acceptCarrierCargoOffer(11);

        const [url, init] = vi.mocked(fetch).mock.calls[0] as [string, RequestInit];
        expect(url).toBe(`${BASE}/api/carriers/me/cargo-offers/11/accept`);
        expect(init.method).toBe("POST");
    });
});

describe("rejectCarrierCargoOffer", () => {
    it("posts to reject endpoint", async () => {
        mockFetch({ ...pendingOffer(), status: "rejected", rejected_at: "2026-06-11T10:00:00Z" }, 200);
        await rejectCarrierCargoOffer(11);

        const [url, init] = vi.mocked(fetch).mock.calls[0] as [string, RequestInit];
        expect(url).toBe(`${BASE}/api/carriers/me/cargo-offers/11/reject`);
        expect(init.method).toBe("POST");
    });
});
