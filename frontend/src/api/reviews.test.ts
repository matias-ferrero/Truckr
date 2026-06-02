import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createShipmentReview } from "./reviews";
import { ApiError } from "../api";

const BASE = "http://localhost:3000";

function mockFetch(body: unknown, status = 200) {
    const res = new Response(JSON.stringify(body), {
        status,
        headers: { "Content-Type": "application/json" },
    });
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue(res));
}

beforeEach(() => {
    vi.unstubAllGlobals();
});

afterEach(() => {
    vi.unstubAllGlobals();
});

describe("createShipmentReview", () => {
    it("POSTs to /api/shipments/:id/reviews with rating + body", async () => {
        mockFetch({ id: 1, rating: 5, body: "Genial", authored_by: "shipper", created_at: "2026-05-29T10:00:00Z" }, 201);

        await createShipmentReview(31, { rating: 5, body: "Genial" });

        const [url, init] = vi.mocked(fetch).mock.calls[0];
        expect(url).toBe(`${BASE}/api/shipments/31/reviews`);
        expect(init?.method).toBe("POST");
        expect(JSON.parse(init?.body as string)).toEqual({ rating: 5, body: "Genial" });
    });

    it("sends body: null when no comment is provided", async () => {
        mockFetch({ id: 2, rating: 4, body: null, authored_by: "carrier", created_at: "2026-05-29T10:00:00Z" }, 201);

        await createShipmentReview(31, { rating: 4 });

        const [, init] = vi.mocked(fetch).mock.calls[0];
        expect(JSON.parse(init?.body as string)).toEqual({ rating: 4, body: null });
    });

    it("returns the parsed Review on success", async () => {
        mockFetch({ id: 9, rating: 5, body: "Genial", authored_by: "shipper", created_at: "2026-05-29T10:00:00Z" }, 201);

        const review = await createShipmentReview(31, { rating: 5, body: "Genial" });
        expect(review.id).toBe(9);
        expect(review.authored_by).toBe("shipper");
    });

    it("throws ApiError with the status on a 409 conflict", async () => {
        mockFetch({ error: { code: "conflict", message: "Ya dejaste una reseña" } }, 409);

        await expect(createShipmentReview(31, { rating: 5 })).rejects.toMatchObject({
            name: "ApiError",
            status: 409,
        });
    });

    it("propagates ApiError instances (instanceof check)", async () => {
        mockFetch({ error: { code: "forbidden", message: "No autorizado" } }, 403);

        const err = await createShipmentReview(31, { rating: 5 }).catch((e) => e);
        expect(err).toBeInstanceOf(ApiError);
        expect(err.status).toBe(403);
    });
});
