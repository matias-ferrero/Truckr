import { apiFetch, API_BASE_URL, buildAuthHeaders, ApiError } from "../api";

/* Typed client for `/api/cargo_offers`.
 *
 * Post-REQ-FE-00015 remediation: a `CargoOffer` always bids against an
 * *already-published* `Cargo`. `createCargoOffer` takes the cargo id plus an
 * offer draft and posts `{ cargo_offer: { cargo_id, transport_window_id,
 * estimated_km } }` to the flat `POST /api/cargo_offers` route — no inline
 * cargo creation, no address / cargo-field payload. */

/** The offer-specific fields the caller supplies; `cargo_id` is added here. */
export type CargoOfferDraft = {
    transport_window_id: number;
    /** User-entered km; backend uses it to derive `amount_cents`. */
    estimated_km: string;
};

// Embedded cargo summary returned by the index endpoint.
export type CargoSummary = {
    pickup_address: string;
    delivery_address: string;
    pickup_window_start: string;
    pickup_window_end: string;
    cargo_description: string;
};

// Wire format for the CargoOffer resource returned by the backend.
export type CargoOffer = {
    id: number;
    cargo_id: number;
    carrier_id: number;
    transport_window_id: number;
    amount_cents: number;
    currency: string;
    status: "pending" | "accepted" | "paid" | "rejected" | "expired" | "cancelled";
    expires_at: string;
    accepted_at?: string | null;
    rejected_at?: string | null;
    created_at: string;
    updated_at: string;
    // The index resource embeds a cargo summary; optional for defensive
    // deserialization against future serializer variants.
    cargo?: CargoSummary;
};

export type CargoOfferListMeta = {
    total: number;
    page: number;
    perPage: number;
    totalPages: number;
};

export type CargoOfferListResult = {
    items: CargoOffer[];
    meta: CargoOfferListMeta;
};

function metaFromHeaders(res: Response): CargoOfferListMeta {
    return {
        total: Number(res.headers.get("X-Total") ?? 0),
        page: Number(res.headers.get("X-Page") ?? 1),
        perPage: Number(res.headers.get("X-Per-Page") ?? 20),
        totalPages: Number(res.headers.get("X-Total-Pages") ?? 1),
    };
}

export async function listMyCargoOffers(page = 1): Promise<CargoOfferListResult> {
    const res = await fetch(`${API_BASE_URL}/api/cargo_offers?page=${page}`, {
        headers: { Accept: "application/json", ...buildAuthHeaders() },
    });
    if (!res.ok) {
        let payload: { error?: { code?: string; message?: string; details?: unknown } } = {};
        try {
            payload = await res.json();
        } catch {
            /* body wasn't JSON */
        }
        throw new ApiError(
            res.status,
            payload.error?.message ?? `HTTP ${res.status}`,
            payload.error?.code,
            payload.error?.details,
        );
    }
    const items = (await res.json()) as CargoOffer[];
    return { items, meta: metaFromHeaders(res) };
}

/**
 * POST /api/cargo_offers — bid against an existing Cargo.
 * `cargoId` rides in the body as `cargo_id`, alongside the offer draft.
 */
export async function createCargoOffer(
    cargoId: number,
    draft: CargoOfferDraft,
): Promise<CargoOffer> {
    return apiFetch<CargoOffer>("/api/cargo_offers", {
        method: "POST",
        body: { cargo_offer: { cargo_id: cargoId, ...draft } },
    });
}
