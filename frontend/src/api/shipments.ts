import { apiFetch } from "../api";
import type { Review } from "./reviews";
import type { Payout } from "./payouts";

export type ShipmentState =
    | "accepted"
    | "in_transit"
    | "delivered"
    | "cancelled";

// UI-level payment chip state (derived from shipment FSM, not a backend field).
export type PaymentState = "pending" | "paid";

// Backend Payment row state (mirrors the `payments.state` column).
export type PaymentRowState = "escrowed" | "failed";

export type Shipment = {
    id: number;
    state: ShipmentState;
    origin: string;
    destination: string;
    created_at: string;
    amount_cents: number;
    currency: string;
    latest_activity_at: string;
    payment_escrowed: boolean;
    counterparty_display_name?: string | null;
    // US-Shipper-Dashboard — true once the Shipper has left their review for a
    // delivered shipment. Drives the "pendiente de reseña" attention surface.
    shipper_reviewed: boolean;
    // Carrier-Dashboard-v2 — mirror flag for the Carrier viewer (US30), and
    // the settlement timestamp that splits Entregadas (por cobrar) / Pagadas.
    carrier_reviewed: boolean;
    settled_at: string | null;
};

export type CounterpartyContact = {
    full_name: string;
    email: string;
    phone: string | null;
} | null;

export type ShipmentPayment = {
    id: number;
    state: PaymentRowState;
    amount_cents: number;
    currency: string;
    escrowed_at: string | null;
};

export type TrackingEvent = {
    id: number;
    kind: string;
    occurred_at: string;
    from_status?: string | null;
    to_status?: string | null;
};

// US-Shipper-Dashboard — the activity-feed event kinds emitted by
// GET /api/shippers/me/shipments-scoped activity. `status_change`, `gps_update`
// and `note` mirror the TrackingEvent vocabulary; the `shipment_*` / `payment_*`
// kinds are coarse lifecycle markers the feed surfaces directly.
export type ShipperActivityKind =
    | "status_change"
    | "gps_update"
    | "note"
    | "shipment_accepted"
    | "shipment_in_transit"
    | "shipment_delivered"
    | "shipment_cancelled"
    | "payment_escrowed"
    | "payment_failed";

// A single row from GET /api/shippers/me/activity. Newest-first, capped at 20
// by the backend. `from_status` / `to_status` are only meaningful for
// `status_change`; null otherwise.
export type ShipperActivityEvent = {
    id: number;
    shipment_id: number;
    kind: ShipperActivityKind;
    occurred_at: string;
    from_status?: string | null;
    to_status?: string | null;
};

export type ShipmentCargo = {
    origin: string;
    destination: string;
    description: string;
    weight_kg: string;
    // Cargo pickup/delivery coordinates, emitted by ShipmentDetailResource as
    // DECIMAL(9,6) strings (US48/US49 — REQ-BE-00036). Feed the US51 map and the
    // Google Maps deep-links (REQ-FE-00028). May be absent on legacy rows; the
    // map degrades to a neutral "unavailable" state in that case.
    pickup_lat?: string | null;
    pickup_lng?: string | null;
    delivery_lat?: string | null;
    delivery_lng?: string | null;
};

export type ShipmentVehicle = {
    plate: string;
    kind: string;
};

export type ShipmentDetail = {
    id: number;
    state: ShipmentState;
    created_at: string;
    picked_up_at?: string | null;
    delivered_at?: string | null;
    amount_cents: number;
    currency: string;
    cargo: ShipmentCargo;
    vehicle: ShipmentVehicle;
    counterparty?: { kind: "carrier" | "shipper"; id: number; display_name: string } | null;
    counterparty_contact: CounterpartyContact;
    payment?: ShipmentPayment | null;
    payout?: Pick<Payout, "id" | "state" | "gross_amount_cents" | "commission_rate" | "commission_cents" | "amount_cents" | "currency" | "paid_at"> | null;
    tracking_events: TrackingEvent[];
    available_actions: AvailableAction[];
    // US30 / REQ-BE-00044 — the Carrier→Shipper review for this shipment, when
    // one already exists. Only surfaced to the Carrier viewer (the author) and
    // only on a `delivered` shipment; null otherwise. Lets the detail page
    // hydrate CarrierReviewForm straight into its read-only state (AC7) across
    // reloads, without a separate listing endpoint (US26 / US54).
    carrier_review?: Review | null;
    shipper_review?: Review | null;
};

// Canonical enum owned by REQ-BE-00035 §4.4. The FE never invents entries.
export type AvailableAction = "start_transit" | "deliver" | "pay" | "cancel";

export type PaymentResult = {
    payment_id: number;
    state: "escrowed";
};

export async function listCarrierShipments(): Promise<Shipment[]> {
    return apiFetch<Shipment[]>("/api/carriers/me/shipments");
}

export async function listShipperShipments(): Promise<Shipment[]> {
    return apiFetch<Shipment[]>("/api/shippers/me/shipments");
}

export async function getShipmentDetail(id: number): Promise<ShipmentDetail> {
    return apiFetch<ShipmentDetail>(`/api/shipments/${id}`);
}

export async function listShipperActivity(): Promise<ShipperActivityEvent[]> {
    return apiFetch<ShipperActivityEvent[]>("/api/shippers/me/activity");
}

// Carrier-Dashboard-v2 — the heterogeneous news feed from
// GET /api/carriers/me/activity: payouts settled, reviews received from
// shippers, and inbound offer events. Self-triggered shipment milestones are
// deliberately absent (they're a log, not news).
export type CarrierActivityKind =
    | "payout_paid"
    | "review_received"
    | "offer_received"
    | "offer_accepted"
    | "offer_rejected";

export type CarrierActivityEvent = {
    /** composite key, e.g. "payout-3" / "offer-9-accepted" */
    id: string;
    kind: CarrierActivityKind;
    occurred_at: string;
    shipment_id: number | null;
    cargo_offer_id: number | null;
    origin: string;
    destination: string;
    amount_cents: number | null;
    currency: string | null;
    rating: number | null;
};

export async function listCarrierActivity(): Promise<CarrierActivityEvent[]> {
    return apiFetch<CarrierActivityEvent[]>("/api/carriers/me/activity");
}

export async function createShipmentPayment(id: number): Promise<PaymentResult> {
    return apiFetch<PaymentResult>(`/api/shipments/${id}/payments`, { method: "POST" });
}

export async function performShipmentTransition(
    id: number,
    action: "start_transit" | "deliver",
): Promise<void> {
    await apiFetch<void>(`/api/shipments/${id}/${action}`, { method: "POST" });
}
