/* Pure mapping from GET /api/carriers/me/activity rows into renderable feed
 * items. The backend already merges + caps the heterogeneous sources
 * (payouts, reviews received, offer events) newest-first; this module only
 * resolves hrefs and re-sorts defensively. No React, no I/O.
 */

import type { CarrierActivityEvent } from "../../../api/shipments";

export interface CarrierActivityItem {
    key: string;
    /** ISO timestamp */
    at: string;
    kind: CarrierActivityEvent["kind"];
    href: string;
    origin: string | null;
    destination: string | null;
    amountCents: number | null;
    currency: string | null;
    rating: number | null;
}

export function buildCarrierActivityFeed(
    events: CarrierActivityEvent[],
): CarrierActivityItem[] {
    const items = (events ?? []).map((event): CarrierActivityItem => ({
        key: event.id,
        at: event.occurred_at,
        kind: event.kind,
        // Shipment-anchored news deep-links to the shipment; offer news lands
        // on the inbox (offers have no per-row detail page).
        href: event.shipment_id !== null
            ? `/carrier/shipments/${event.shipment_id}`
            : "/carrier/cargo-offers",
        origin: event.origin || null,
        destination: event.destination || null,
        amountCents: event.amount_cents,
        currency: event.currency,
        rating: event.rating,
    }));

    items.sort((a, b) => (Date.parse(b.at) || 0) - (Date.parse(a.at) || 0));
    return items;
}
