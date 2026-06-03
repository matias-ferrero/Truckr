import { apiFetch } from "../api";
import type { Vehicle } from "./vehicles";

// Wire format mirrors CarrierDetailResource on the backend (REQ-BE-00039).
export type TransportWindow = {
    id: number;
    vehicle_id: number;
    origin_address: string;
    origin_locality: string;
    origin_admin_area: string;
    origin_lat: string | number;
    origin_lng: string | number;
    destination_address: string | null;
    destination_locality: string | null;
    destination_admin_area: string | null;
    destination_lat: string | number | null;
    destination_lng: string | number | null;
    pickup_radius_km: number;
    dropoff_radius_km: number | null;
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
    rating_avg: string | null;
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
