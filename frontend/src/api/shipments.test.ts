import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
    listCarrierShipments,
    listShipperShipments,
    getShipmentDetail,
    performShipmentTransition,
} from "./shipments";

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

describe("getShipmentDetail", () => {
    it("calls GET /api/shipments/:id", async () => {
        mockFetch({ id: 5, state: "accepted", amount_cents: 100, currency: "ARS",
            created_at: "2026-06-11T10:00:00Z",
            cargo: { origin: "CABA", destination: "Córdoba", description: "Pallets", weight_kg: "1500.0" },
            vehicle: { plate: "AAA111", kind: "truck_small" },
            counterparty: null, counterparty_contact: null, payment: null,
            tracking_events: [], available_actions: [] });
        await getShipmentDetail(5);
        const url = vi.mocked(fetch).mock.calls[0][0] as string;
        expect(url).toBe(`${BASE}/api/shipments/5`);
    });

    it("returns parsed ShipmentDetail including available_actions and tracking_events", async () => {
        const fixture = {
            id: 5, state: "in_transit", amount_cents: 100, currency: "ARS",
            created_at: "2026-06-11T10:00:00Z",
            cargo: { origin: "CABA", destination: "Córdoba", description: "Pallets", weight_kg: "1500.0" },
            vehicle: { plate: "AAA111", kind: "truck_small" },
            counterparty: { kind: "shipper", id: 1, display_name: "Empresa Demo" },
            counterparty_contact: null,
            payment: { id: 1, state: "escrowed", amount_cents: 100, currency: "ARS", escrowed_at: "2026-06-11T10:05:00Z" },
            tracking_events: [{ id: 1, kind: "shipment_accepted", occurred_at: "2026-06-11T10:00:00Z" }],
            available_actions: ["deliver"],
        };
        mockFetch(fixture);
        const result = await getShipmentDetail(5);
        expect(result.available_actions).toEqual(["deliver"]);
        expect(result.tracking_events).toHaveLength(1);
        expect(result.cargo.origin).toBe("CABA");
        expect(result.vehicle.plate).toBe("AAA111");
    });
});

describe("performShipmentTransition", () => {
    it("calls POST /api/shipments/:id/start_transit", async () => {
        mockFetch({});
        await performShipmentTransition(7, "start_transit");
        const [url, init] = vi.mocked(fetch).mock.calls[0] as [string, RequestInit];
        expect(url).toBe(`${BASE}/api/shipments/7/start_transit`);
        expect(init.method).toBe("POST");
    });

    it("calls POST /api/shipments/:id/deliver", async () => {
        mockFetch({});
        await performShipmentTransition(7, "deliver");
        const [url] = vi.mocked(fetch).mock.calls[0] as [string, RequestInit];
        expect(url).toBe(`${BASE}/api/shipments/7/deliver`);
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
