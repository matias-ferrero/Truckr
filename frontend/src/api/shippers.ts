import { API_BASE_URL, apiFetch, buildAuthHeaders } from "../api";
import type { Review } from "./reviews";

// Wire format mirrors ShipperDetailResource on the backend (US54 / REQ-BE-00045).
// rating_avg is a stringified decimal (e.g. "4.3") to match CarrierDetail, or
// null when the shipper has no reviews yet.
export type ShipperDetail = {
    id: number;
    company_name: string | null;
    tax_id: string | null;
    billing_address: string | null;
    rating_avg: string | null;
    reviews_count: number;
    created_at: string;
    updated_at: string;
};

export type ReviewListMeta = {
    total: number;
    page: number;
    perPage: number;
    totalPages: number;
};

export type ReviewListResult = {
    reviews: Review[];
    meta: ReviewListMeta;
};

// GET /api/shippers/:id — authenticated; 404 surfaces as ApiError.
export async function getShipper(
    id: number,
    opts: { signal?: AbortSignal } = {},
): Promise<ShipperDetail> {
    return apiFetch<ShipperDetail>(`/api/shippers/${id}`, { signal: opts.signal });
}

function metaFromHeaders(res: Response): ReviewListMeta {
    return {
        total: Number(res.headers.get("X-Total") ?? 0),
        page: Number(res.headers.get("X-Page") ?? 1),
        perPage: Number(res.headers.get("X-Per-Page") ?? 10),
        totalPages: Number(res.headers.get("X-Total-Pages") ?? 1),
    };
}

// GET /api/shippers/:id/reviews — paginated (10/page), newest first. Reads the
// X-Total* headers for pagination, same shape as listMyVehicles / cargo lists.
export async function listShipperReviews(
    shipperId: number,
    page = 1,
    opts: { signal?: AbortSignal } = {},
): Promise<ReviewListResult> {
    const res = await fetch(
        `${API_BASE_URL}/api/shippers/${shipperId}/reviews?page=${page}`,
        {
            headers: { "Content-Type": "application/json", ...buildAuthHeaders() },
            signal: opts.signal,
        },
    );
    if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        const envelope = (body as { error?: { code?: string; message?: string } }).error;
        const message = envelope?.message ?? envelope?.code ?? `HTTP ${res.status}`;
        throw Object.assign(new Error(message), { status: res.status, body });
    }
    const reviews = (await res.json()) as Review[];
    return { reviews, meta: metaFromHeaders(res) };
}
