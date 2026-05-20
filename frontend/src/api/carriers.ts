import { apiFetch } from "../api";
import type { Vehicle } from "./vehicles";

// Wire format mirrors CarrierDetailResource on the backend.
export type TransportWindow = {
    id: number;
    vehicle_id: number;
    origin_zone: string;
    destination_zone: string;
    price_per_km: string;
    max_km: number;
    available_from: string;
    available_to: string;
    active: boolean;
};

export type CarrierDetail = {
    id: number;
    legal_name: string | null;
    tax_id: string | null;
    base_city: string | null;
    province: string | null;
    description: string | null;
    rating_avg: string;
    reviews_count: number;
    completed_shipments: number;
    vehicles: Vehicle[];
    transport_windows: TransportWindow[];
    created_at: string;
    updated_at: string;
};

export async function getCarrier(
    id: number,
    opts: { signal?: AbortSignal } = {},
): Promise<CarrierDetail> {
    return apiFetch<CarrierDetail>(`/api/carriers/${id}`, { signal: opts.signal });
}

// Helper for the UI: format cents in ARS by default.
export function formatCurrency(cents: number, currency = "ARS", locale = "es-AR"): string {
    return new Intl.NumberFormat(locale, {
        style: "currency",
        currency,
        maximumFractionDigits: 0,
    }).format(cents / 100);
}
