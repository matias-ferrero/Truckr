import { apiFetch, API_BASE_URL, ApiError, buildAuthHeaders } from "../api";

export type ReviewAuthor = "carrier" | "shipper";

export type Review = {
    id: number;
    rating: number;
    body: string | null;
    authored_by: ReviewAuthor;
    created_at: string;
};

export type CreateReviewInput = {
    rating: number;
    body?: string | null;
};

export type ReviewListMeta = {
    total: number;
    page: number;
    perPage: number;
    totalPages: number;
};

export type ReviewListResult = {
    items: Review[];
    meta: ReviewListMeta;
};

function metaFromHeaders(res: Response): ReviewListMeta {
    return {
        total: Number(res.headers.get("X-Total") ?? 0),
        page: Number(res.headers.get("X-Page") ?? 1),
        perPage: Number(res.headers.get("X-Per-Page") ?? 10),
        totalPages: Number(res.headers.get("X-Total-Pages") ?? 1),
    };
}

// GET /api/carriers/:id/reviews — US26 (authenticated, paginated).
export async function listCarrierReviews(
    carrierId: number,
    page = 1,
    opts: { signal?: AbortSignal } = {},
): Promise<ReviewListResult> {
    const res = await fetch(
        `${API_BASE_URL}/api/carriers/${carrierId}/reviews?page=${page}`,
        {
            headers: { Accept: "application/json", ...buildAuthHeaders() },
            signal: opts.signal,
        },
    );
    if (!res.ok) {
        let payload: { error?: { code?: string; message?: string } } = {};
        try {
            payload = await res.json();
        } catch {
            /* non-JSON body */
        }
        throw new ApiError(
            res.status,
            payload.error?.message ?? `HTTP ${res.status}`,
            payload.error?.code,
        );
    }
    const items = (await res.json()) as Review[];
    return { items, meta: metaFromHeaders(res) };
}

// POST /api/shipments/:id/reviews — direction inferred from the authenticated poster.
export async function createShipmentReview(
    shipmentId: number,
    input: CreateReviewInput,
): Promise<Review> {
    return apiFetch<Review>(`/api/shipments/${shipmentId}/reviews`, {
        method: "POST",
        body: { rating: input.rating, body: input.body ?? null },
    });
}
