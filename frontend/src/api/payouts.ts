import { apiFetch } from "../api";

export type PayoutState = "paid" | "failed";

export type Payout = {
    id: number;
    shipment_id: number;
    gross_amount_cents: number;
    commission_rate: string;
    commission_cents: number;
    amount_cents: number;
    currency: string;
    state: PayoutState;
    paid_at: string | null;
    created_at: string;
    origin: string;
    destination: string;
    shipper_name: string;
};

export async function listCarrierPayouts(): Promise<Payout[]> {
    return apiFetch<Payout[]>("/api/carriers/me/payouts");
}
