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

// ---- Public carrier search (transport_windows) ----------------------------
//
// Mirrors the wire format of CarrierSearchResource: lists matching carriers
// with the transport windows that overlap the requested zone+date filters.
// Endpoint is public (no auth required) — apiFetch still attaches a Bearer
// token if the user is signed in, which the backend ignores for this route.

export type SearchTransportWindow = {
    id: number;
    origin_zone: string;
    destination_zone: string;
    price_per_km: string;
    max_km: number;
    available_from: string;
    available_to: string;
    active: boolean;
};

export type CarrierSearchResult = {
    id: number;
    legal_name: string | null;
    display_name: string | null;
    base_city: string | null;
    province: string | null;
    rating_avg: string;
    completed_shipments: number;
    transport_windows: SearchTransportWindow[];
};

export type CarrierSearchParams = {
    originZone: string;
    destinationZone: string;
    dateFrom: string;
    dateTo: string;
};

function toQuery(params: CarrierSearchParams): string {
    return new URLSearchParams({
        origin_zone: params.originZone,
        destination_zone: params.destinationZone,
        date_from: params.dateFrom,
        date_to: params.dateTo,
    }).toString();
}

export async function searchCarriers(
    params: CarrierSearchParams,
    opts: { signal?: AbortSignal } = {},
): Promise<CarrierSearchResult[]> {
    return apiFetch<CarrierSearchResult[]>(
        `/api/transport_windows?${toQuery(params)}`,
        { signal: opts.signal },
    );
}
