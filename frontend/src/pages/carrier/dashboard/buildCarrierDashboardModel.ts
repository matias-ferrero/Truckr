/* Pure projection from the Carrier's raw data sources (pending offer inbox +
 * shipments + supply posture) into the Carrier Dashboard v2 board model.
 * No React, no I/O — the UI renders straight off the returned model.
 *
 * Job-funnel mapping (offer inbox → shipment FSM → settlement):
 *   pending CargoOffer                     → "newOffers"
 *   shipment accepted                      → "toStart"
 *   shipment in_transit                    → "inTransit"
 *   shipment delivered, settled_at null    → "delivered"  (por cobrar)
 *   shipment settled_at present            → "paid"
 * Cancelled shipments are excluded everywhere.
 *
 * Attention is strictly actionable (PRD governing rule): a row exists only
 * when the carrier holds the next move. An accepted-but-unpaid shipment is
 * the *shipper's* move (escrow gates start_transit), so it never alerts.
 */

import type { CarrierCargoOffer } from "../../../api/carrierCargoOffers";
import type { Shipment } from "../../../api/shipments";

export type ColumnKey = "newOffers" | "toStart" | "inTransit" | "delivered" | "paid";

export type JobBadge =
    | "expiring"
    | "new_offer"
    | "awaiting_payment"
    | "ready_to_start"
    | "in_transit"
    | "to_collect"
    | "to_review"
    | "paid";

/** Offers within this window of `expires_at` get the urgent (coral) tone —
 *  the carrier's structural equivalent of the shipper's "por pagar". */
export const EXPIRING_SOON_MS = 24 * 60 * 60 * 1000;

export interface OfferCard {
    key: string;
    offerId: number;
    origin: string;
    destination: string;
    priceCents: number | null;
    currency: string;
    weightKg: string | null;
    distanceKm: string | null;
    shipperName: string | null;
    /** "4.5" (1 dp) or null when the shipper has no reviews yet */
    shipperRating: string | null;
    shipperReviewsCount: number;
    expiresAt: string;
    expiringSoon: boolean;
    badge: JobBadge;
}

export interface ShipmentCard {
    key: string;
    shipmentId: number;
    origin: string;
    destination: string;
    priceCents: number | null;
    currency: string;
    column: Exclude<ColumnKey, "newOffers">;
    badge: JobBadge;
    href: string;
}

export type OnboardingStep = "no-vehicle" | "no-window" | "steady";

export interface CarrierSupply {
    vehiclesCount: number;
    openWindowsCount: number;
    /** carrier's own rating headline, e.g. "4.8"; null when unrated */
    ratingAvg: string | null;
}

export interface CarrierDashboardModel {
    columns: {
        newOffers: OfferCard[];
        toStart: ShipmentCard[];
        inTransit: ShipmentCard[];
        delivered: ShipmentCard[];
        paid: ShipmentCard[];
    };
    counts: Record<ColumnKey, number>;
    attention: {
        offersToAnswer: number;
        expiringOffers: number;
        toStart: number;
        toDeliver: number;
        toReview: number;
    };
    stats: CarrierSupply;
    onboardingStep: OnboardingStep;
    /** total cards across all columns — 0 means a board with no jobs yet */
    totalJobs: number;
}

const COLUMN_KEYS: ColumnKey[] = ["newOffers", "toStart", "inTransit", "delivered", "paid"];

/**
 * Coerce a `*_cents` wire value to a number. Cents may arrive as a decimal
 * string (Rails `DECIMAL` → JSON string) or a plain number. Returns null only
 * when the value is truly absent (null/undefined) or not parseable.
 */
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

const DEFAULT_CURRENCY = "ARS";

export function isExpiringSoon(expiresAt: string, now: number): boolean {
    const expiry = Date.parse(expiresAt);
    if (Number.isNaN(expiry)) return false;
    return expiry - now <= EXPIRING_SOON_MS;
}

function offerCard(offer: CarrierCargoOffer, now: number): OfferCard {
    const expiring = isExpiringSoon(offer.expires_at, now);
    return {
        key: `offer-${offer.id}`,
        offerId: offer.id,
        origin: offer.cargo.pickup_locality || offer.cargo.pickup_address,
        destination: offer.cargo.delivery_locality || offer.cargo.delivery_address,
        priceCents: toCents(offer.price_amount_cents),
        currency: DEFAULT_CURRENCY,
        weightKg: offer.cargo.weight_kg || null,
        distanceKm: offer.cargo.distance_km,
        shipperName: offer.shipper.name,
        shipperRating: offer.shipper.rating_avg,
        shipperReviewsCount: offer.shipper.reviews_count,
        expiresAt: offer.expires_at,
        expiringSoon: expiring,
        badge: expiring ? "expiring" : "new_offer",
    };
}

function shipmentColumn(shipment: Shipment): ShipmentCard["column"] | null {
    if (shipment.settled_at) return "paid";
    switch (shipment.state) {
        case "accepted":
            return "toStart";
        case "in_transit":
            return "inTransit";
        case "delivered":
            return "delivered";
        default:
            return null;
    }
}

function shipmentBadge(shipment: Shipment, column: ShipmentCard["column"]): JobBadge {
    switch (column) {
        case "toStart":
            return shipment.payment_escrowed ? "ready_to_start" : "awaiting_payment";
        case "inTransit":
            return "in_transit";
        case "delivered":
            return "to_collect";
        case "paid":
            return shipment.carrier_reviewed ? "paid" : "to_review";
    }
}

function shipmentCard(shipment: Shipment, column: ShipmentCard["column"]): ShipmentCard {
    return {
        key: `shipment-${shipment.id}`,
        shipmentId: shipment.id,
        origin: shipment.origin,
        destination: shipment.destination,
        priceCents: toCents(shipment.amount_cents),
        currency: shipment.currency || DEFAULT_CURRENCY,
        column,
        badge: shipmentBadge(shipment, column),
        href: `/carrier/shipments/${shipment.id}`,
    };
}

function shipmentSortKey(shipment: Shipment): number {
    return (
        Date.parse(shipment.latest_activity_at) ||
        Date.parse(shipment.created_at) ||
        0
    );
}

export function buildCarrierDashboardModel(
    offers: CarrierCargoOffer[],
    shipments: Shipment[],
    supply: CarrierSupply,
    now: number = Date.now(),
): CarrierDashboardModel {
    // Only pending offers are jobs awaiting a response. The inbox endpoint
    // already filters, but stay defensive against a wider payload.
    const pending = (offers ?? []).filter((o) => o.status === "pending");

    // Response queue order: the offer closest to expiry comes first.
    const newOffers = pending
        .map((o) => offerCard(o, now))
        .sort((a, b) => (Date.parse(a.expiresAt) || 0) - (Date.parse(b.expiresAt) || 0));

    const columns: CarrierDashboardModel["columns"] = {
        newOffers,
        toStart: [],
        inTransit: [],
        delivered: [],
        paid: [],
    };

    const sortKeys = new Map<string, number>();
    const liveShipments = (shipments ?? []).filter((s) => s.state !== "cancelled");
    for (const shipment of liveShipments) {
        const column = shipmentColumn(shipment);
        if (column === null) continue;
        const card = shipmentCard(shipment, column);
        columns[column].push(card);
        sortKeys.set(card.key, shipmentSortKey(shipment));
    }

    const counts = {} as Record<ColumnKey, number>;
    let totalJobs = 0;
    for (const key of COLUMN_KEYS) {
        if (key !== "newOffers") {
            columns[key].sort((a, b) => (sortKeys.get(b.key) ?? 0) - (sortKeys.get(a.key) ?? 0));
        }
        counts[key] = columns[key].length;
        totalJobs += columns[key].length;
    }

    const attention = {
        offersToAnswer: newOffers.length,
        expiringOffers: newOffers.filter((o) => o.expiringSoon).length,
        // Escrow gates start_transit: unpaid accepted shipments are the
        // shipper's move, not the carrier's — never an alert.
        toStart: liveShipments.filter(
            (s) => s.state === "accepted" && s.payment_escrowed === true,
        ).length,
        toDeliver: liveShipments.filter((s) => s.state === "in_transit").length,
        toReview: liveShipments.filter(
            (s) => s.state === "delivered" && s.carrier_reviewed === false,
        ).length,
    };

    const onboardingStep: OnboardingStep = supply.vehiclesCount === 0
        ? "no-vehicle"
        : supply.openWindowsCount === 0
        ? "no-window"
        : "steady";

    return { columns, counts, attention, stats: supply, onboardingStep, totalJobs };
}
