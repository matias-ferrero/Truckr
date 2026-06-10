import { describe, expect, it } from "vitest";
import { buildDashboardModel } from "./buildDashboardModel";
import type { Cargo, CargoOffer } from "../../../types/Cargo";
import type { Shipment } from "../../../api/shipments";

let cargoSeq = 0;
let offerSeq = 0;
let shipmentSeq = 0;

function makeOffer(overrides: Partial<CargoOffer> = {}): CargoOffer {
    offerSeq += 1;
    return {
        id: offerSeq,
        cargo_id: 0,
        carrier_id: 1,
        transport_window_id: 1,
        amount_cents: 10_000,
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

function makeShipment(overrides: Partial<Shipment> = {}): Shipment {
    shipmentSeq += 1;
    return {
        id: shipmentSeq,
        state: "accepted",
        origin: "Origin City",
        destination: "Dest City",
        created_at: "2026-06-01T00:00:00Z",
        amount_cents: 30_000,
        currency: "ARS",
        latest_activity_at: "2026-06-02T00:00:00Z",
        payment_escrowed: true,
        counterparty_display_name: "Carrier SA",
        shipper_reviewed: false,
        carrier_reviewed: false,
        settled_at: null,
        ...overrides,
    };
}

describe("buildDashboardModel", () => {
    it("returns empty columns + zero counts for empty inputs", () => {
        const model = buildDashboardModel([], []);
        expect(model.columns).toEqual({
            searching: [],
            withOffers: [],
            acceptedOffers: [],
            inTransit: [],
            delivered: [],
        });
        expect(model.counts).toEqual({
            searching: 0,
            withOffers: 0,
            acceptedOffers: 0,
            inTransit: 0,
            delivered: 0,
        });
        expect(model.attention).toEqual({ toPay: 0, withoutOffers: 0, toReview: 0 });
        expect(model.totalCargos).toBe(0);
    });

    it("buckets an open cargo with no pending offers into searching", () => {
        const cargo = makeCargo({ id: 12, cargo_offers: [] });
        const model = buildDashboardModel([cargo], []);
        expect(model.columns.searching).toHaveLength(1);
        const card = model.columns.searching[0];
        expect(card).toMatchObject({
            key: "cargo-12",
            source: "cargo",
            refId: 12,
            column: "searching",
            badge: "no_offers",
            href: "/shipper/cargos/12",
            offersCount: 0,
            priceCents: 250_000,
        });
    });

    it("treats expired/rejected/accepted offers as non-pending (still searching)", () => {
        const cargo = makeCargo({
            cargo_offers: [
                makeOffer({ status: "expired" }),
                makeOffer({ status: "accepted" }),
            ],
        });
        const model = buildDashboardModel([cargo], []);
        expect(model.columns.searching).toHaveLength(1);
        expect(model.columns.withOffers).toHaveLength(0);
        expect(model.columns.searching[0].offersCount).toBe(0);
        expect(model.attention.withoutOffers).toBe(1);
    });

    it("buckets an open cargo with >=1 pending offer into withOffers with lowest price", () => {
        const cargo = makeCargo({
            id: 5,
            cargo_offers: [
                makeOffer({ amount_cents: 90_000 }),
                makeOffer({ amount_cents: 40_000 }),
                makeOffer({ amount_cents: 70_000 }),
                makeOffer({ status: "expired", amount_cents: 1_000 }),
            ],
        });
        const model = buildDashboardModel([cargo], []);
        expect(model.columns.withOffers).toHaveLength(1);
        const card = model.columns.withOffers[0];
        expect(card).toMatchObject({
            column: "withOffers",
            badge: "has_offers",
            offersCount: 3,
            priceCents: 40_000,
            href: "/shipper/cargos/5",
        });
    });

    it("excludes cancelled cargos and cancelled shipments everywhere", () => {
        const model = buildDashboardModel(
            [makeCargo({ status: "cancelled" })],
            [makeShipment({ state: "cancelled" })],
        );
        expect(model.totalCargos).toBe(0);
        expect(model.attention).toEqual({ toPay: 0, withoutOffers: 0, toReview: 0 });
    });

    it("excludes accepted (promoted) cargos from the cargo columns", () => {
        const model = buildDashboardModel([makeCargo({ status: "accepted" })], []);
        expect(model.totalCargos).toBe(0);
        expect(model.columns.searching).toHaveLength(0);
        expect(model.columns.withOffers).toHaveLength(0);
    });

    it("buckets accepted shipments with payment_pending badge when not escrowed", () => {
        const shipment = makeShipment({ id: 7, state: "accepted", payment_escrowed: false });
        const model = buildDashboardModel([], [shipment]);
        expect(model.columns.acceptedOffers).toHaveLength(1);
        expect(model.columns.acceptedOffers[0]).toMatchObject({
            key: "shipment-7",
            source: "shipment",
            badge: "payment_pending",
            priceCents: 30_000,
            href: "/shipper/shipments/7",
            offersCount: 0,
        });
    });

    it("buckets accepted shipments with null badge when escrowed", () => {
        const model = buildDashboardModel([], [makeShipment({ state: "accepted", payment_escrowed: true })]);
        expect(model.columns.acceptedOffers[0].badge).toBeNull();
    });

    it("buckets in_transit shipments with in_transit badge", () => {
        const model = buildDashboardModel([], [makeShipment({ state: "in_transit" })]);
        expect(model.columns.inTransit).toHaveLength(1);
        expect(model.columns.inTransit[0].badge).toBe("in_transit");
    });

    it("buckets delivered shipments with to_review when not reviewed", () => {
        const model = buildDashboardModel([], [makeShipment({ state: "delivered", shipper_reviewed: false })]);
        expect(model.columns.delivered[0].badge).toBe("to_review");
    });

    it("buckets delivered shipments with delivered badge once reviewed", () => {
        const model = buildDashboardModel([], [makeShipment({ state: "delivered", shipper_reviewed: true })]);
        expect(model.columns.delivered[0].badge).toBe("delivered");
    });

    it("computes all three attention counts", () => {
        const cargos = [
            makeCargo({ cargo_offers: [] }), // withoutOffers
            makeCargo({ cargo_offers: [makeOffer()] }), // has offers
        ];
        const shipments = [
            makeShipment({ state: "accepted", payment_escrowed: false }), // toPay
            makeShipment({ state: "accepted", payment_escrowed: true }),
            makeShipment({ state: "delivered", shipper_reviewed: false }), // toReview
            makeShipment({ state: "delivered", shipper_reviewed: true }),
            makeShipment({ state: "cancelled", payment_escrowed: false }), // excluded
        ];
        const model = buildDashboardModel(cargos, shipments);
        expect(model.attention).toEqual({ toPay: 1, withoutOffers: 1, toReview: 1 });
    });

    it("coerces string cents to numbers (cargo declared_value and offer amount)", () => {
        const searchingCargo = makeCargo({
            declared_value_cents: "123456" as unknown as number,
            cargo_offers: [],
        });
        const offerCargo = makeCargo({
            cargo_offers: [makeOffer({ amount_cents: "55000" as unknown as number })],
        });
        const shipment = makeShipment({ amount_cents: "99999" as unknown as number });
        const model = buildDashboardModel([searchingCargo, offerCargo], [shipment]);
        expect(model.columns.searching[0].priceCents).toBe(123456);
        expect(model.columns.withOffers[0].priceCents).toBe(55000);
        expect(model.columns.acceptedOffers[0].priceCents).toBe(99999);
    });

    it("yields null priceCents when the value is truly absent or unparseable", () => {
        const cargo = makeCargo({ declared_value_cents: null as unknown as number, cargo_offers: [] });
        const offerCargo = makeCargo({
            cargo_offers: [makeOffer({ amount_cents: "" as unknown as number })],
        });
        const model = buildDashboardModel([cargo, offerCargo], []);
        expect(model.columns.searching[0].priceCents).toBeNull();
        expect(model.columns.withOffers[0].priceCents).toBeNull();
    });

    it("falls back to pickup_address / delivery_address when localities are empty", () => {
        const cargo = makeCargo({
            pickup_locality: "",
            delivery_locality: "",
            pickup_address: "Calle A",
            delivery_address: "Calle B",
        });
        const card = buildDashboardModel([cargo], []).columns.searching[0];
        expect(card.origin).toBe("Calle A");
        expect(card.destination).toBe("Calle B");
    });

    it("sorts cargos by created_at desc and shipments by latest_activity_at desc", () => {
        const older = makeCargo({ id: 1, created_at: "2026-06-01T00:00:00Z", cargo_offers: [] });
        const newer = makeCargo({ id: 2, created_at: "2026-06-05T00:00:00Z", cargo_offers: [] });
        const olderShip = makeShipment({
            id: 10,
            state: "in_transit",
            latest_activity_at: "2026-06-02T00:00:00Z",
        });
        const newerShip = makeShipment({
            id: 11,
            state: "in_transit",
            latest_activity_at: "2026-06-09T00:00:00Z",
        });
        const model = buildDashboardModel([older, newer], [olderShip, newerShip]);
        expect(model.columns.searching.map((c) => c.refId)).toEqual([2, 1]);
        expect(model.columns.inTransit.map((c) => c.refId)).toEqual([11, 10]);
    });

    it("falls back to created_at when latest_activity_at is unparseable for sorting", () => {
        const a = makeShipment({
            id: 20,
            state: "delivered",
            shipper_reviewed: true,
            latest_activity_at: "not-a-date",
            created_at: "2026-06-01T00:00:00Z",
        });
        const b = makeShipment({
            id: 21,
            state: "delivered",
            shipper_reviewed: true,
            latest_activity_at: "not-a-date",
            created_at: "2026-06-08T00:00:00Z",
        });
        const model = buildDashboardModel([], [a, b]);
        expect(model.columns.delivered.map((c) => c.refId)).toEqual([21, 20]);
    });

    it("sums totalCargos across all non-cancelled columns", () => {
        const model = buildDashboardModel(
            [makeCargo({ cargo_offers: [] }), makeCargo({ cargo_offers: [makeOffer()] })],
            [
                makeShipment({ state: "accepted" }),
                makeShipment({ state: "in_transit" }),
                makeShipment({ state: "delivered", shipper_reviewed: true }),
                makeShipment({ state: "cancelled" }),
            ],
        );
        expect(model.totalCargos).toBe(5);
    });
});
