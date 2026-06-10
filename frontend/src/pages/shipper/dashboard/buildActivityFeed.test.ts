import { describe, expect, it } from "vitest";
import { buildActivityFeed } from "./buildActivityFeed";
import type { Cargo, CargoOffer } from "../../../types/Cargo";
import type { Shipment, ShipperActivityEvent } from "../../../api/shipments";

let cargoSeq = 0;
let offerSeq = 0;
let eventSeq = 0;

function makeShipment(overrides: Partial<Shipment> = {}): Shipment {
    return {
        id: 100,
        state: "in_transit",
        origin: "Rosario",
        destination: "Mendoza",
        created_at: "2026-06-01T00:00:00Z",
        amount_cents: 9_000_000,
        currency: "ARS",
        latest_activity_at: "2026-06-01T00:00:00Z",
        payment_escrowed: false,
        shipper_reviewed: false,
        carrier_reviewed: false,
        settled_at: null,
        ...overrides,
    };
}

function makeOffer(overrides: Partial<CargoOffer> = {}): CargoOffer {
    offerSeq += 1;
    return {
        id: offerSeq,
        cargo_id: 0,
        carrier_id: 1,
        transport_window_id: 1,
        amount_cents: 12_000,
        currency: "ARS",
        status: "pending",
        expires_at: "2026-07-01T00:00:00Z",
        created_at: "2026-06-01T00:00:00Z",
        updated_at: "2026-06-01T00:00:00Z",
        ...overrides,
    };
}

function makeCargo(overrides: Partial<Cargo> = {}): Cargo {
    cargoSeq += 1;
    return {
        id: cargoSeq,
        shipper_id: 1,
        status: "open",
        cargo_description: "Pallets",
        pickup_address: "Av. Pickup 100",
        pickup_lat: "-34.6",
        pickup_lng: "-58.4",
        pickup_locality: "Pickup City",
        pickup_admin_area: "BA",
        delivery_address: "Av. Delivery 200",
        delivery_lat: "-31.4",
        delivery_lng: "-64.2",
        delivery_locality: "Delivery City",
        delivery_admin_area: "CB",
        pickup_window_start: "2026-06-10T08:00:00Z",
        pickup_window_end: "2026-06-10T12:00:00Z",
        weight_kg: "500",
        volume_cm3: null,
        declared_value_cents: 250_000,
        cancelled_at: null,
        created_at: "2026-06-01T00:00:00Z",
        updated_at: "2026-06-01T00:00:00Z",
        editable: true,
        pending_offers_count: 0,
        cargo_offers: [],
        ...overrides,
    } as Cargo;
}

function makeEvent(overrides: Partial<ShipperActivityEvent> = {}): ShipperActivityEvent {
    eventSeq += 1;
    return {
        id: eventSeq,
        shipment_id: 100,
        kind: "status_change",
        occurred_at: "2026-06-01T00:00:00Z",
        from_status: null,
        to_status: null,
        ...overrides,
    };
}

describe("buildActivityFeed", () => {
    it("returns an empty feed for empty inputs", () => {
        expect(buildActivityFeed([], [])).toEqual([]);
    });

    it("derives offer_received items from every non-cancelled cargo's offers", () => {
        const cargo = makeCargo({
            id: 9,
            cargo_offers: [makeOffer({ id: 3, amount_cents: 45_000, currency: "ARS" })],
        });
        const [item] = buildActivityFeed([cargo], []);
        expect(item).toMatchObject({
            key: "offer-3",
            type: "offer_received",
            refId: 9,
            href: "/shipper/cargos/9",
            origin: "Pickup City",
            destination: "Delivery City",
            amountCents: 45_000,
            currency: "ARS",
            at: "2026-06-01T00:00:00Z",
        });
    });

    it("skips offers from cancelled cargos", () => {
        const cargo = makeCargo({ status: "cancelled", cargo_offers: [makeOffer()] });
        expect(buildActivityFeed([cargo], [])).toEqual([]);
    });

    it("coerces string offer amounts and tolerates missing currency", () => {
        const cargo = makeCargo({
            cargo_offers: [
                makeOffer({ id: 50, amount_cents: "33000" as unknown as number, currency: undefined as unknown as string }),
            ],
        });
        const [item] = buildActivityFeed([cargo], []);
        expect(item.amountCents).toBe(33000);
        expect(item.currency).toBeNull();
    });

    it("maps shipment_* and payment_* kinds directly with shipment href and null amount", () => {
        const events = [
            makeEvent({ id: 1, kind: "shipment_accepted", shipment_id: 7 }),
            makeEvent({ id: 2, kind: "shipment_in_transit", shipment_id: 7 }),
            makeEvent({ id: 3, kind: "shipment_delivered", shipment_id: 7 }),
            makeEvent({ id: 4, kind: "payment_failed", shipment_id: 7 }),
        ];
        const feed = buildActivityFeed([], events);
        expect(feed).toHaveLength(4);
        for (const item of feed) {
            expect(item.refId).toBe(7);
            expect(item.href).toBe("/shipper/shipments/7");
            expect(item.amountCents).toBeNull();
            expect(item.currency).toBeNull();
        }
        expect(feed.map((i) => i.type).sort()).toEqual(
            ["payment_failed", "shipment_accepted", "shipment_delivered", "shipment_in_transit"],
        );
    });

    it("enriches shipment events with the route of the matching shipment", () => {
        const shipment = makeShipment({ id: 7, origin: "Córdoba", destination: "Salta" });
        const feed = buildActivityFeed(
            [],
            [makeEvent({ id: 1, kind: "shipment_in_transit", shipment_id: 7 })],
            [shipment],
        );
        expect(feed[0]).toMatchObject({ origin: "Córdoba", destination: "Salta" });
    });

    it("leaves the route null when the shipment is unknown", () => {
        const feed = buildActivityFeed(
            [],
            [makeEvent({ id: 1, kind: "shipment_in_transit", shipment_id: 999 })],
            [makeShipment({ id: 7 })],
        );
        expect(feed[0]).toMatchObject({ origin: null, destination: null });
    });

    it("surfaces the shipment amount on payment_escrowed events only", () => {
        const shipment = makeShipment({ id: 7, amount_cents: 5_500_000, currency: "ARS" });
        const events = [
            makeEvent({ id: 1, kind: "payment_escrowed", shipment_id: 7 }),
            makeEvent({ id: 2, kind: "shipment_delivered", shipment_id: 7 }),
        ];
        const feed = buildActivityFeed([], events, [shipment]);
        const escrowed = feed.find((i) => i.type === "payment_escrowed")!;
        const delivered = feed.find((i) => i.type === "shipment_delivered")!;
        expect(escrowed.amountCents).toBe(5_500_000);
        expect(escrowed.currency).toBe("ARS");
        expect(delivered.amountCents).toBeNull();
    });

    it("keeps status_change / note / gps_update kinds as their own type", () => {
        const events = [
            makeEvent({ id: 10, kind: "status_change" }),
            makeEvent({ id: 11, kind: "note" }),
            makeEvent({ id: 12, kind: "gps_update" }),
        ];
        const feed = buildActivityFeed([], events);
        expect(feed.map((i) => i.type).sort()).toEqual(["gps_update", "note", "status_change"]);
    });

    it("drops shipment_cancelled events (no ActivityItem type for them)", () => {
        const feed = buildActivityFeed([], [makeEvent({ kind: "shipment_cancelled" })]);
        expect(feed).toEqual([]);
    });

    it("merges both sources and sorts by `at` descending", () => {
        const cargo = makeCargo({
            id: 1,
            cargo_offers: [makeOffer({ id: 100, created_at: "2026-06-03T00:00:00Z" })],
        });
        const events = [
            makeEvent({ id: 200, kind: "shipment_delivered", occurred_at: "2026-06-05T00:00:00Z" }),
            makeEvent({ id: 201, kind: "note", occurred_at: "2026-06-01T00:00:00Z" }),
        ];
        const feed = buildActivityFeed([cargo], events);
        expect(feed.map((i) => i.key)).toEqual(["event-200", "offer-100", "event-201"]);
    });

    it("returns the full sorted list — pagination belongs to the component", () => {
        const events = Array.from({ length: 20 }, (_, i) =>
            makeEvent({
                id: 1000 + i,
                kind: "note",
                occurred_at: `2026-06-${String(i + 1).padStart(2, "0")}T00:00:00Z`,
            }),
        );
        const feed = buildActivityFeed([], events);
        expect(feed).toHaveLength(20);
        // Newest first: the last-day event leads.
        expect(feed[0].key).toBe("event-1019");
    });
});
