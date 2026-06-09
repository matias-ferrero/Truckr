/* Pure projection from the two raw Shipper data sources (cargos + shipments)
 * into the Shipper Dashboard v2 board model. No React, no I/O — the UI engineer
 * renders straight off the returned `DashboardModel`.
 *
 * Lifecycle mapping (cargo funnel → shipment FSM):
 *   open cargo, 0 pending offers   → "searching"
 *   open cargo, >=1 pending offer  → "withOffers"
 *   shipment accepted              → "acceptedOffers"
 *   shipment in_transit            → "inTransit"
 *   shipment delivered             → "delivered"
 * Cancelled cargos and cancelled shipments are excluded everywhere.
 */

import type { Cargo, CargoOffer } from "../../../types/Cargo";
import type { Shipment } from "../../../api/shipments";

export type ColumnKey =
    | "searching"
    | "withOffers"
    | "acceptedOffers"
    | "inTransit"
    | "delivered";

export type BoardBadge =
    | "no_offers"
    | "has_offers"
    | "payment_pending"
    | "in_transit"
    | "delivered"
    | "to_review"
    | null;

export interface BoardCard {
    /** stable unique key, e.g. `cargo-12` / `shipment-7` */
    key: string;
    source: "cargo" | "shipment";
    refId: number;
    /** for cargos: pickup_locality || pickup_address; for shipments: origin */
    origin: string;
    /** for cargos: delivery_locality || delivery_address; for shipments: destination */
    destination: string;
    priceCents: number | null;
    currency: string;
    column: ColumnKey;
    badge: BoardBadge;
    /** `/shipper/cargos/:id` for cargos, `/shipper/shipments/:id` for shipments */
    href: string;
    /** 0 for shipments */
    offersCount: number;
}

export interface DashboardModel {
    columns: Record<ColumnKey, BoardCard[]>;
    counts: Record<ColumnKey, number>;
    attention: { toPay: number; withoutOffers: number; toReview: number };
    /** total non-cancelled cards across all columns */
    totalCargos: number;
}

const COLUMN_KEYS: ColumnKey[] = [
    "searching",
    "withOffers",
    "acceptedOffers",
    "inTransit",
    "delivered",
];

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

/** A currency code is per-offer / per-shipment; cargos have no currency so default. */
const DEFAULT_CURRENCY = "ARS";

/** Only `pending` offers count toward the board; expired/rejected/etc. don't. */
function pendingOffers(cargo: Cargo): CargoOffer[] {
    const offers = cargo.cargo_offers ?? [];
    return offers.filter((o) => o.status === "pending");
}

function lowestPendingAmount(offers: CargoOffer[]): number | null {
    let lowest: number | null = null;
    for (const offer of offers) {
        const cents = toCents(offer.amount_cents);
        if (cents === null) continue;
        if (lowest === null || cents < lowest) lowest = cents;
    }
    return lowest;
}

function pendingCurrency(offers: CargoOffer[]): string {
    for (const offer of offers) {
        if (offer.currency) return offer.currency;
    }
    return DEFAULT_CURRENCY;
}

function cargoCard(cargo: Cargo): BoardCard {
    const pending = pendingOffers(cargo);
    const hasOffers = pending.length > 0;
    return {
        key: `cargo-${cargo.id}`,
        source: "cargo",
        refId: cargo.id,
        origin: cargo.pickup_locality || cargo.pickup_address,
        destination: cargo.delivery_locality || cargo.delivery_address,
        priceCents: hasOffers
            ? lowestPendingAmount(pending)
            : toCents(cargo.declared_value_cents),
        currency: hasOffers ? pendingCurrency(pending) : DEFAULT_CURRENCY,
        column: hasOffers ? "withOffers" : "searching",
        badge: hasOffers ? "has_offers" : "no_offers",
        href: `/shipper/cargos/${cargo.id}`,
        offersCount: pending.length,
    };
}

function shipmentBadge(shipment: Shipment): BoardBadge {
    switch (shipment.state) {
        case "accepted":
            return shipment.payment_escrowed ? null : "payment_pending";
        case "in_transit":
            return "in_transit";
        case "delivered":
            return shipment.shipper_reviewed ? "delivered" : "to_review";
        default:
            return null;
    }
}

function shipmentColumn(state: Shipment["state"]): ColumnKey | null {
    switch (state) {
        case "accepted":
            return "acceptedOffers";
        case "in_transit":
            return "inTransit";
        case "delivered":
            return "delivered";
        default:
            return null;
    }
}

function shipmentCard(shipment: Shipment, column: ColumnKey): BoardCard {
    return {
        key: `shipment-${shipment.id}`,
        source: "shipment",
        refId: shipment.id,
        origin: shipment.origin,
        destination: shipment.destination,
        priceCents: toCents(shipment.amount_cents),
        currency: shipment.currency || DEFAULT_CURRENCY,
        column,
        badge: shipmentBadge(shipment),
        href: `/shipper/shipments/${shipment.id}`,
        offersCount: 0,
    };
}

/** Most-recent-first sort key for a card's underlying record. */
function cargoSortKey(cargo: Cargo): number {
    return Date.parse(cargo.created_at) || 0;
}

function shipmentSortKey(shipment: Shipment): number {
    return (
        Date.parse(shipment.latest_activity_at) ||
        Date.parse(shipment.created_at) ||
        0
    );
}

export function buildDashboardModel(
    cargos: Cargo[],
    shipments: Shipment[],
): DashboardModel {
    const columns: Record<ColumnKey, BoardCard[]> = {
        searching: [],
        withOffers: [],
        acceptedOffers: [],
        inTransit: [],
        delivered: [],
    };

    // Cargos: only `open` ones feed the searching / withOffers columns. Accepted
    // cargos have been promoted to shipments (which carry the live state), and
    // cancelled cargos are excluded entirely.
    const liveCargos = (cargos ?? []).filter((c) => c.status === "open");
    const cargoSort = new Map<string, number>();
    for (const cargo of liveCargos) {
        const card = cargoCard(cargo);
        columns[card.column].push(card);
        cargoSort.set(card.key, cargoSortKey(cargo));
    }

    const shipmentSort = new Map<string, number>();
    for (const shipment of shipments ?? []) {
        if (shipment.state === "cancelled") continue;
        const column = shipmentColumn(shipment.state);
        if (column === null) continue;
        const card = shipmentCard(shipment, column);
        columns[column].push(card);
        shipmentSort.set(card.key, shipmentSortKey(shipment));
    }

    const sortKey = (card: BoardCard): number =>
        (card.source === "cargo" ? cargoSort.get(card.key) : shipmentSort.get(card.key)) ?? 0;

    const counts = {} as Record<ColumnKey, number>;
    let totalCargos = 0;
    for (const key of COLUMN_KEYS) {
        columns[key].sort((a, b) => sortKey(b) - sortKey(a));
        counts[key] = columns[key].length;
        totalCargos += columns[key].length;
    }

    const liveShipments = (shipments ?? []).filter((s) => s.state !== "cancelled");
    const attention = {
        toPay: liveShipments.filter(
            (s) => s.state === "accepted" && s.payment_escrowed === false,
        ).length,
        withoutOffers: liveCargos.filter((c) => pendingOffers(c).length === 0).length,
        toReview: liveShipments.filter(
            (s) => s.state === "delivered" && s.shipper_reviewed === false,
        ).length,
    };

    return { columns, counts, attention, totalCargos };
}
