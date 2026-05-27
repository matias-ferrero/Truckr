import { apiFetch } from "../api";

export type ShipmentState =
    | "accepted"
    | "pending_payment"
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

export type ShipmentDetail = {
    id: number;
    state: ShipmentState;
    amount_cents: number;
    currency: string;
    counterparty?: { kind: "carrier" | "shipper"; id: number; display_name: string } | null;
    counterparty_contact: CounterpartyContact;
    payment?: ShipmentPayment | null;
};

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
