import { apiFetch } from "../api";

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
