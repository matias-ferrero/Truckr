import { apiFetch, API_BASE_URL, buildAuthHeaders, ApiError } from "../api";

// Wire format for the POST /api/quotes request body.
export type QuoteDraft = {
    transport_window_id: number;
    pickup_address: string;
    delivery_address: string;
    pickup_date: string;       // ISO date "YYYY-MM-DD"
    cargo_description: string;
    weight_kg: string;         // string for form binding; backend coerces to decimal
    volume_cm3: string;        // string for form binding; backend coerces to integer
    declared_value_cents: string; // converted from pesos × 100 before send
    estimated_km: string;      // user-entered km; backend uses it to compute amount_cents
};

// Embedded cargo offer summary returned by the index endpoint.
export type CargoOfferSummary = {
    pickup_address: string;
    delivery_address: string;
    pickup_date: string;
    cargo_description: string;
};

// Wire format for the Quote resource returned by the backend.
export type Quote = {
    id: number;
    cargo_offer_id: number;
    carrier_id: number;
    transport_window_id: number;
    amount_cents: number;
    currency: string;
    status: "pending" | "accepted" | "paid" | "expired" | "cancelled";
    expires_at: string;
    created_at: string;
    updated_at: string;
    // Always present: the resource always embeds cargo_offer. Optional type kept
    // for defensive deserialization against future serializer variants.
    cargo_offer?: CargoOfferSummary;
};

export type QuoteListMeta = {
    total: number;
    page: number;
    perPage: number;
    totalPages: number;
};

export type QuoteListResult = {
    items: Quote[];
    meta: QuoteListMeta;
};

function metaFromHeaders(res: Response): QuoteListMeta {
    return {
        total:      Number(res.headers.get("X-Total")       ?? 0),
        page:       Number(res.headers.get("X-Page")        ?? 1),
        perPage:    Number(res.headers.get("X-Per-Page")    ?? 20),
        totalPages: Number(res.headers.get("X-Total-Pages") ?? 1),
    };
}

export async function listMyQuotes(page = 1): Promise<QuoteListResult> {
    const res = await fetch(`${API_BASE_URL}/api/quotes?page=${page}`, {
        headers: { Accept: "application/json", ...buildAuthHeaders() },
    });
    if (!res.ok) {
        let payload: { error?: { code?: string; message?: string; details?: unknown } } = {};
        try { payload = await res.json(); } catch { /* body wasn't JSON */ }
        throw new ApiError(
            res.status,
            payload.error?.message ?? `HTTP ${res.status}`,
            payload.error?.code,
            payload.error?.details,
        );
    }
    const items = (await res.json()) as Quote[];
    return { items, meta: metaFromHeaders(res) };
}

export async function createQuote(draft: QuoteDraft): Promise<Quote> {
    return apiFetch<Quote>("/api/quotes", {
        method: "POST",
        body: { quote: draft },
    });
}
