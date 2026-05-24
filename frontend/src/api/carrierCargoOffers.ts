import { API_BASE_URL, ApiError, buildAuthHeaders, apiFetch } from "../api";

export type CarrierCargoOfferStatus =
    | "pending"
    | "accepted"
    | "paid"
    | "rejected"
    | "expired"
    | "cancelled";

export type CarrierCargoOfferCargo = {
    id: number;
    pickup_address: string;
    delivery_address: string;
    weight_kg: string;
    volume_cm3: number | null;
    declared_value_cents: number;
    pickup_window_start: string;
    pickup_window_end: string;
    cargo_description: string;
    status: string;
};

export type CarrierCargoOfferShipper = {
    id: number;
    name: string | null;
};

export type CarrierCargoOfferTransportWindow = {
    id: number;
    origin_zone: string;
    destination_zone: string;
    available_from: string;
    available_to: string;
    price_per_km: string;
    max_km: number;
    status: "open" | "pending_offer" | "reserved";
};

export type CarrierCargoOffer = {
    id: number;
    cargo_id: number;
    carrier_id: number;
    transport_window_id: number;
    status: CarrierCargoOfferStatus;
    expires_at: string;
    accepted_at: string | null;
    rejected_at: string | null;
    created_at: string;
    updated_at: string;
    price_amount_cents: number;
    cargo: CarrierCargoOfferCargo;
    shipper: CarrierCargoOfferShipper;
    transport_window: CarrierCargoOfferTransportWindow;
};

export type CarrierCargoOfferListMeta = {
    total: number;
    page: number;
    perPage: number;
    totalPages: number;
};

export type CarrierCargoOfferListResult = {
    items: CarrierCargoOffer[];
    meta: CarrierCargoOfferListMeta;
};

export type CarrierShipment = {
    id: number;
    cargo_offer_id: number;
    status: string;
    accepted_at: string | null;
    picked_up_at: string | null;
    delivered_at: string | null;
    settled_at: string | null;
    cancelled_at: string | null;
    cancellation_reason: string | null;
    created_at: string;
    updated_at: string;
};

export type AcceptCarrierCargoOfferResult = {
    cargo_offer: CarrierCargoOffer;
    shipment: CarrierShipment;
};

function metaFromHeaders(res: Response): CarrierCargoOfferListMeta {
    return {
        total: Number(res.headers.get("X-Total") ?? 0),
        page: Number(res.headers.get("X-Page") ?? 1),
        perPage: Number(res.headers.get("X-Per-Page") ?? 20),
        totalPages: Number(res.headers.get("X-Total-Pages") ?? 1),
    };
}

async function ensureOk(res: Response): Promise<void> {
    if (res.ok) return;

    let payload: { error?: { code?: string; message?: string; details?: unknown } } = {};
    try {
        payload = await res.json();
    } catch {
        // ignore non-json responses
    }

    throw new ApiError(
        res.status,
        payload.error?.message ?? `HTTP ${res.status}`,
        payload.error?.code,
        payload.error?.details,
    );
}

export async function listCarrierCargoOffers(
    status: CarrierCargoOfferStatus = "pending",
    page = 1,
): Promise<CarrierCargoOfferListResult> {
    const query = new URLSearchParams({ status, page: String(page) });
    const res = await fetch(`${API_BASE_URL}/api/carriers/me/cargo-offers?${query.toString()}`, {
        headers: { Accept: "application/json", ...buildAuthHeaders() },
    });

    await ensureOk(res);
    const items = (await res.json()) as CarrierCargoOffer[];
    return { items, meta: metaFromHeaders(res) };
}

export async function acceptCarrierCargoOffer(
    offerId: number,
): Promise<AcceptCarrierCargoOfferResult> {
    return apiFetch<AcceptCarrierCargoOfferResult>(`/api/carriers/me/cargo-offers/${offerId}/accept`, {
        method: "POST",
    });
}

export async function rejectCarrierCargoOffer(offerId: number): Promise<CarrierCargoOffer> {
    return apiFetch<CarrierCargoOffer>(`/api/carriers/me/cargo-offers/${offerId}/reject`, {
        method: "POST",
    });
}
