/* Pure merge of two activity sources into one chronologically-sorted feed:
 *   1. offer-received events derived from each non-cancelled cargo's nested
 *      `cargo_offers[]` (the backend activity endpoint is shipment-scoped, so
 *      offers on still-open cargos are only visible on the cargo records).
 *   2. shipment lifecycle / tracking events from GET /api/shippers/me/activity.
 * Each item is enriched with the route (origin → destination) of its cargo /
 * shipment so the feed rows carry real context. The full sorted list is
 * returned; the ActivityFeed component owns pagination.
 * No React, no I/O.
 */

import type { Cargo } from "../../../types/Cargo";
import type { Shipment, ShipperActivityEvent } from "../../../api/shipments";

export interface ActivityItem {
    key: string;
    /** ISO timestamp */
    at: string;
    type:
        | "offer_received"
        | "shipment_accepted"
        | "shipment_in_transit"
        | "shipment_delivered"
        | "payment_escrowed"
        | "payment_failed"
        | "status_change"
        | "note"
        | "gps_update";
    /** cargo id for offer_received, else shipment id */
    refId: number;
    href: string;
    /** Route endpoints of the related cargo / shipment; null when unresolvable. */
    origin: string | null;
    destination: string | null;
    amountCents: number | null;
    currency: string | null;
}

function toCents(value: unknown): number | null {
    if (value === null || value === undefined) return null;
    if (typeof value === "number") return Number.isNaN(value) ? null : value;
    if (typeof value === "string") {
        const trimmed = value.trim();
        if (trimmed === "") return null;
        const parsed = Number(trimmed);
        return Number.isNaN(parsed) ? null : parsed;
    }
    return null;
}

/** `shipment_cancelled` has no ActivityItem type — it is dropped from the feed. */
function eventType(kind: ShipperActivityEvent["kind"]): ActivityItem["type"] | null {
    switch (kind) {
        case "shipment_accepted":
        case "shipment_in_transit":
        case "shipment_delivered":
        case "payment_escrowed":
        case "payment_failed":
        case "status_change":
        case "note":
        case "gps_update":
            return kind;
        case "shipment_cancelled":
        default:
            return null;
    }
}

export function buildActivityFeed(
    cargos: Cargo[],
    events: ShipperActivityEvent[],
    shipments: Shipment[] = [],
): ActivityItem[] {
    const items: ActivityItem[] = [];
    const shipmentById = new Map<number, Shipment>(
        (shipments ?? []).map((s) => [s.id, s]),
    );

    for (const cargo of cargos ?? []) {
        if (cargo.status === "cancelled") continue;
        for (const offer of cargo.cargo_offers ?? []) {
            items.push({
                key: `offer-${offer.id}`,
                at: offer.created_at,
                type: "offer_received",
                refId: cargo.id,
                href: `/shipper/cargos/${cargo.id}`,
                origin: cargo.pickup_locality || null,
                destination: cargo.delivery_locality || null,
                amountCents: toCents(offer.amount_cents),
                currency: offer.currency ?? null,
            });
        }
    }

    for (const event of events ?? []) {
        const type = eventType(event.kind);
        if (type === null) continue;
        const shipment = shipmentById.get(event.shipment_id) ?? null;
        // Escrow is the one money moment in the lifecycle: surface the amount.
        const showAmount = type === "payment_escrowed" && shipment !== null;
        items.push({
            key: `event-${event.id}`,
            at: event.occurred_at,
            type,
            refId: event.shipment_id,
            href: `/shipper/shipments/${event.shipment_id}`,
            origin: shipment?.origin || null,
            destination: shipment?.destination || null,
            amountCents: showAmount ? toCents(shipment.amount_cents) : null,
            currency: showAmount ? shipment.currency ?? null : null,
        });
    }

    items.sort((a, b) => (Date.parse(b.at) || 0) - (Date.parse(a.at) || 0));

    return items;
}
