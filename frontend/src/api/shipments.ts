import { apiFetch } from "../api";

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

export type ShipmentCargo = {
    origin: string;
    destination: string;
    description: string;
    weight_kg: string;
};

export type ShipmentVehicle = {
    plate: string;
    kind: string;
};

export type ShipmentDetail = {
    id: number;
    state: ShipmentState;
    created_at: string;
    amount_cents: number;
    currency: string;
    cargo: ShipmentCargo;
    vehicle: ShipmentVehicle;
    counterparty?: { kind: "carrier" | "shipper"; id: number; display_name: string } | null;
    counterparty_contact: CounterpartyContact;
    payment?: ShipmentPayment | null;
    tracking_events: TrackingEvent[];
    available_actions: AvailableAction[];
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

export async function createShipmentPayment(id: number): Promise<PaymentResult> {
    return apiFetch<PaymentResult>(`/api/shipments/${id}/payments`, { method: "POST" });
}

export async function performShipmentTransition(
    id: number,
    action: "start_transit" | "deliver",
): Promise<void> {
    await apiFetch<void>(`/api/shipments/${id}/${action}`, { method: "POST" });
}
