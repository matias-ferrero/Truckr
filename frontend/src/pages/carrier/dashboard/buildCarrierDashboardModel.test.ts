import { describe, expect, it } from "vitest";
import {
    buildCarrierDashboardModel,
    type CarrierSupply,
    EXPIRING_SOON_MS,
} from "./buildCarrierDashboardModel";
import type { CarrierCargoOffer } from "../../../api/carrierCargoOffers";
import type { Shipment } from "../../../api/shipments";

const NOW = Date.parse("2026-06-10T12:00:00Z");

let offerSeq = 0;
let shipmentSeq = 0;

function makeOffer(overrides: Partial<CarrierCargoOffer> = {}): CarrierCargoOffer {
    offerSeq += 1;
    return {
        id: offerSeq,
        cargo_id: offerSeq,
        carrier_id: 1,
        transport_window_id: 1,
        status: "pending",
        expires_at: "2026-06-15T12:00:00Z",
        accepted_at: null,
        rejected_at: null,
        created_at: "2026-06-09T12:00:00Z",
        updated_at: "2026-06-09T12:00:00Z",
        price_amount_cents: 2_500_000,
        cargo: {
            id: offerSeq,
            pickup_address: "Av. Corrientes 1234, CABA",
            delivery_address: "Av. Colón 500, Córdoba",
            pickup_locality: "CABA",
            delivery_locality: "Córdoba",
            weight_kg: "1500",
            volume_cm3: null,
            declared_value_cents: 5_000_000,
            pickup_window_start: "2026-06-12T08:00:00Z",
            pickup_window_end: "2026-06-14T18:00:00Z",
            cargo_description: "Pallets",
            status: "open",
            distance_km: "700",
        },
        shipper: { id: 3, name: "Agro SA", rating_avg: "4.5", reviews_count: 12 },
        transport_window: {
            id: 1,
            origin_locality: "CABA",
            origin_admin_area: "CABA",
            destination_locality: "Córdoba",
            destination_admin_area: "Córdoba",
            available_from: "2026-06-12T00:00:00Z",
            available_to: "2026-06-16T00:00:00Z",
            price_per_km: "1000",
            max_km: 900,
            status: "pending_offer",
        },
        ...overrides,
    };
}

function makeShipment(overrides: Partial<Shipment> = {}): Shipment {
    shipmentSeq += 1;
    return {
        id: shipmentSeq,
        state: "accepted",
        origin: "Rosario",
        destination: "Mendoza",
        created_at: "2026-06-01T00:00:00Z",
        amount_cents: 9_000_000,
        currency: "ARS",
        latest_activity_at: "2026-06-02T00:00:00Z",
        payment_escrowed: false,
        shipper_reviewed: false,
        carrier_reviewed: false,
        settled_at: null,
        ...overrides,
    };
}

const SUPPLY: CarrierSupply = { vehiclesCount: 2, openWindowsCount: 1, ratingAvg: "4.8" };

function build(
    offers: CarrierCargoOffer[],
    shipments: Shipment[],
    supply: CarrierSupply = SUPPLY,
) {
    return buildCarrierDashboardModel(offers, shipments, supply, NOW);
}

describe("buildCarrierDashboardModel", () => {
    describe("column bucketing", () => {
        it("puts pending offers in newOffers", () => {
            const model = build([makeOffer()], []);
            expect(model.counts.newOffers).toBe(1);
            expect(model.columns.newOffers[0].origin).toBe("CABA");
            expect(model.columns.newOffers[0].destination).toBe("Córdoba");
        });

        it("ignores non-pending offers defensively", () => {
            const model = build([makeOffer({ status: "rejected" })], []);
            expect(model.counts.newOffers).toBe(0);
        });

        it("maps accepted → toStart, in_transit → inTransit", () => {
            const model = build([], [
                makeShipment({ state: "accepted" }),
                makeShipment({ state: "in_transit" }),
            ]);
            expect(model.counts.toStart).toBe(1);
            expect(model.counts.inTransit).toBe(1);
        });

        it("splits delivered by settled_at: null → delivered (por cobrar), present → paid", () => {
            const model = build([], [
                makeShipment({ state: "delivered", settled_at: null }),
                makeShipment({ state: "delivered", settled_at: "2026-06-09T00:00:00Z" }),
            ]);
            expect(model.counts.delivered).toBe(1);
            expect(model.counts.paid).toBe(1);
            expect(model.columns.delivered[0].badge).toBe("to_collect");
        });

        it("excludes cancelled shipments everywhere", () => {
            const model = build([], [makeShipment({ state: "cancelled" })]);
            expect(model.totalJobs).toBe(0);
            expect(
                Object.values(model.counts).reduce((a, b) => a + b, 0),
            ).toBe(0);
        });

        it("sorts newOffers by soonest expiry first", () => {
            const later = makeOffer({ expires_at: "2026-06-14T12:00:00Z" });
            const sooner = makeOffer({ expires_at: "2026-06-11T12:00:00Z" });
            const model = build([later, sooner], []);
            expect(model.columns.newOffers.map((o) => o.offerId)).toEqual([
                sooner.id,
                later.id,
            ]);
        });

        it("sorts shipment columns by latest activity, newest first", () => {
            const older = makeShipment({ latest_activity_at: "2026-06-01T00:00:00Z" });
            const newer = makeShipment({ latest_activity_at: "2026-06-09T00:00:00Z" });
            const model = build([], [older, newer]);
            expect(model.columns.toStart.map((s) => s.shipmentId)).toEqual([
                newer.id,
                older.id,
            ]);
        });
    });

    describe("expiry urgency", () => {
        it("flags offers within the 24h window as expiring", () => {
            const expiring = makeOffer({
                expires_at: new Date(NOW + EXPIRING_SOON_MS - 1).toISOString(),
            });
            const calm = makeOffer({
                expires_at: new Date(NOW + EXPIRING_SOON_MS + 60_000).toISOString(),
            });
            const model = build([expiring, calm], []);
            const byId = new Map(model.columns.newOffers.map((o) => [o.offerId, o]));
            expect(byId.get(expiring.id)?.expiringSoon).toBe(true);
            expect(byId.get(expiring.id)?.badge).toBe("expiring");
            expect(byId.get(calm.id)?.expiringSoon).toBe(false);
            expect(byId.get(calm.id)?.badge).toBe("new_offer");
            expect(model.attention.expiringOffers).toBe(1);
        });

        it("treats an already-past expiry as expiring (sweep job pending)", () => {
            const model = build(
                [makeOffer({ expires_at: new Date(NOW - 60_000).toISOString() })],
                [],
            );
            expect(model.attention.expiringOffers).toBe(1);
        });
    });

    describe("attention (strictly actionable)", () => {
        it("counts pending offers as offersToAnswer", () => {
            const model = build([makeOffer(), makeOffer()], []);
            expect(model.attention.offersToAnswer).toBe(2);
        });

        it("only counts escrowed accepted shipments as toStart (unpaid is the shipper's move)", () => {
            const model = build([], [
                makeShipment({ state: "accepted", payment_escrowed: true }),
                makeShipment({ state: "accepted", payment_escrowed: false }),
            ]);
            expect(model.attention.toStart).toBe(1);
        });

        it("counts in_transit shipments as toDeliver", () => {
            const model = build([], [makeShipment({ state: "in_transit" })]);
            expect(model.attention.toDeliver).toBe(1);
        });

        it("counts unreviewed delivered shipments as toReview, settled or not", () => {
            const model = build([], [
                makeShipment({ state: "delivered", carrier_reviewed: false }),
                makeShipment({
                    state: "delivered",
                    carrier_reviewed: false,
                    settled_at: "2026-06-09T00:00:00Z",
                }),
                makeShipment({ state: "delivered", carrier_reviewed: true }),
            ]);
            expect(model.attention.toReview).toBe(2);
        });

        it("never alerts on cancelled shipments", () => {
            const model = build([], [
                makeShipment({ state: "cancelled", payment_escrowed: true }),
            ]);
            expect(model.attention.toStart).toBe(0);
        });
    });

    describe("badges", () => {
        it("differentiates escrowed vs unpaid accepted shipments", () => {
            const paid = makeShipment({ state: "accepted", payment_escrowed: true });
            const unpaid = makeShipment({ state: "accepted", payment_escrowed: false });
            const model = build([], [paid, unpaid]);
            const byId = new Map(model.columns.toStart.map((s) => [s.shipmentId, s]));
            expect(byId.get(paid.id)?.badge).toBe("ready_to_start");
            expect(byId.get(unpaid.id)?.badge).toBe("awaiting_payment");
        });

        it("marks unreviewed paid shipments with to_review", () => {
            const model = build([], [
                makeShipment({
                    state: "delivered",
                    settled_at: "2026-06-09T00:00:00Z",
                    carrier_reviewed: false,
                }),
            ]);
            expect(model.columns.paid[0].badge).toBe("to_review");
        });
    });

    describe("cards", () => {
        it("carries shipper identity + rating onto the offer card", () => {
            const model = build([makeOffer()], []);
            const card = model.columns.newOffers[0];
            expect(card.shipperName).toBe("Agro SA");
            expect(card.shipperRating).toBe("4.5");
            expect(card.shipperReviewsCount).toBe(12);
        });

        it("coerces string cents and falls back to addresses when localities are blank", () => {
            const offer = makeOffer();
            offer.cargo.pickup_locality = "";
            offer.cargo.delivery_locality = "";
            const model = build([offer], []);
            const card = model.columns.newOffers[0];
            expect(card.origin).toBe("Av. Corrientes 1234, CABA");
            expect(card.destination).toBe("Av. Colón 500, Córdoba");
            expect(card.priceCents).toBe(2_500_000);
        });

        it("links shipment cards to their detail page", () => {
            const shipment = makeShipment({ state: "in_transit" });
            const model = build([], [shipment]);
            expect(model.columns.inTransit[0].href).toBe(
                `/carrier/shipments/${shipment.id}`,
            );
        });
    });

    describe("onboarding ladder", () => {
        it("derives no-vehicle, no-window and steady", () => {
            expect(
                build([], [], { vehiclesCount: 0, openWindowsCount: 0, ratingAvg: null })
                    .onboardingStep,
            ).toBe("no-vehicle");
            expect(
                build([], [], { vehiclesCount: 1, openWindowsCount: 0, ratingAvg: null })
                    .onboardingStep,
            ).toBe("no-window");
            expect(
                build([], [], { vehiclesCount: 1, openWindowsCount: 2, ratingAvg: null })
                    .onboardingStep,
            ).toBe("steady");
        });
    });

    describe("degenerate inputs", () => {
        it("handles empty everything", () => {
            const model = build([], [], { vehiclesCount: 0, openWindowsCount: 0, ratingAvg: null });
            expect(model.totalJobs).toBe(0);
            expect(model.attention).toEqual({
                offersToAnswer: 0,
                expiringOffers: 0,
                toStart: 0,
                toDeliver: 0,
                toReview: 0,
            });
        });

        it("tolerates null-ish lists", () => {
            const model = buildCarrierDashboardModel(
                undefined as unknown as CarrierCargoOffer[],
                undefined as unknown as Shipment[],
                SUPPLY,
                NOW,
            );
            expect(model.totalJobs).toBe(0);
        });
    });
});
