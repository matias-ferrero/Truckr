import { apiFetch } from "../api";

export type ShipmentState = "accepted" | "pending_payment" | "in_transit" | "delivered" | "cancelled";

export type Shipment = {
    id: number;
    state: ShipmentState;
    origin: string;
    destination: string;
    created_at: string;
    amount_cents: number;
    currency: string;
    latest_activity_at: string;
};

export async function listCarrierShipments(): Promise<Shipment[]> {
    return apiFetch<Shipment[]>("/api/carriers/me/shipments");
}

export async function listShipperShipments(): Promise<Shipment[]> {
    return apiFetch<Shipment[]>("/api/shippers/me/shipments");
}
