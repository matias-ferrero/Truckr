import { describe, expect, it } from "vitest";
import { buildCarrierActivityFeed } from "./buildCarrierActivityFeed";
import type { CarrierActivityEvent } from "../../../api/shipments";

function makeEvent(overrides: Partial<CarrierActivityEvent> = {}): CarrierActivityEvent {
    return {
        id: "offer-1-received",
        kind: "offer_received",
        occurred_at: "2026-06-09T10:00:00Z",
        shipment_id: null,
        cargo_offer_id: 1,
        origin: "CABA",
        destination: "Córdoba",
        amount_cents: 2_500_000,
        currency: "ARS",
        rating: null,
        ...overrides,
    };
}

describe("buildCarrierActivityFeed", () => {
    it("links shipment-anchored events to the shipment detail", () => {
        const [item] = buildCarrierActivityFeed([
            makeEvent({ id: "payout-2", kind: "payout_paid", shipment_id: 7, cargo_offer_id: null }),
        ]);
        expect(item.href).toBe("/carrier/shipments/7");
    });

    it("links offer events to the inbox", () => {
        const [item] = buildCarrierActivityFeed([makeEvent()]);
        expect(item.href).toBe("/carrier/cargo-offers");
    });

    it("sorts newest first regardless of input order", () => {
        const items = buildCarrierActivityFeed([
            makeEvent({ id: "a", occurred_at: "2026-06-01T00:00:00Z" }),
            makeEvent({ id: "b", occurred_at: "2026-06-09T00:00:00Z" }),
        ]);
        expect(items.map((i) => i.key)).toEqual(["b", "a"]);
    });

    it("carries amount and rating through", () => {
        const [review] = buildCarrierActivityFeed([
            makeEvent({
                id: "review-1",
                kind: "review_received",
                shipment_id: 3,
                amount_cents: null,
                currency: null,
                rating: 4,
            }),
        ]);
        expect(review.rating).toBe(4);
        expect(review.amountCents).toBeNull();
    });

    it("handles an empty / missing list", () => {
        expect(buildCarrierActivityFeed([])).toEqual([]);
        expect(
            buildCarrierActivityFeed(undefined as unknown as CarrierActivityEvent[]),
        ).toEqual([]);
    });
});
