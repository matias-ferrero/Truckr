import { apiFetch } from "../api";

// US30 / REQ-BE-00044 — Carrier → Shipper review on a delivered Shipment.
export type ReviewAuthor = "carrier" | "shipper";

export type Review = {
    id: number;
    rating: number;
    body: string | null;
    authored_by: ReviewAuthor;
    created_at: string;
};

export type CreateCarrierReviewInput = {
    rating: number;
    body?: string | null;
};

// POST /api/shipments/:id/carrier_reviews — 201 with the created ReviewResource.
// Surfaces ApiError on 403 / 404 / 409 / 422 so callers can branch on status.
export async function createCarrierReview(
    shipmentId: number,
    input: CreateCarrierReviewInput,
): Promise<Review> {
    return apiFetch<Review>(`/api/shipments/${shipmentId}/carrier_reviews`, {
        method: "POST",
        body: { rating: input.rating, body: input.body ?? null },
    });
}
