import { describe, expect, it } from "vitest";
import { http, HttpResponse } from "msw";
import { server } from "../test/mocks/server";
import { getShipper, listShipperReviews } from "./shippers";
import type { Review } from "./reviews";

const API = "http://localhost:3000";

const sampleReview: Review = {
    id: 1,
    rating: 5,
    body: "Carga lista a horario.",
    authored_by: "carrier",
    created_at: "2026-06-01T10:00:00Z",
};

describe("api/shippers", () => {
    it("getShipper hits GET /api/shippers/:id and returns the body", async () => {
        server.use(
            http.get(`${API}/api/shippers/4`, () =>
                HttpResponse.json({
                    id: 4,
                    company_name: "Expede SA",
                    tax_id: "30-1234-5",
                    billing_address: "Av. Siempreviva 742",
                    rating_avg: "4.3",
                    reviews_count: 7,
                    created_at: "",
                    updated_at: "",
                })),
        );

        const shipper = await getShipper(4);
        expect(shipper.id).toBe(4);
        expect(shipper.company_name).toBe("Expede SA");
        expect(shipper.rating_avg).toBe("4.3");
        expect(shipper.reviews_count).toBe(7);
    });

    it("getShipper surfaces 404 as an error with status", async () => {
        server.use(
            http.get(`${API}/api/shippers/999`, () =>
                HttpResponse.json({ error: { code: "not_found" } }, { status: 404 })),
        );

        await expect(getShipper(999)).rejects.toMatchObject({ status: 404 });
    });

    it("listShipperReviews returns reviews + meta from response headers", async () => {
        server.use(
            http.get(`${API}/api/shippers/4/reviews`, () =>
                HttpResponse.json([sampleReview], {
                    headers: {
                        "X-Total": "12",
                        "X-Page": "1",
                        "X-Per-Page": "10",
                        "X-Total-Pages": "2",
                    },
                })),
        );

        const { reviews, meta } = await listShipperReviews(4);
        expect(reviews).toHaveLength(1);
        expect(reviews[0].authored_by).toBe("carrier");
        expect(meta).toEqual({ total: 12, page: 1, perPage: 10, totalPages: 2 });
    });

    it("listShipperReviews passes the page param through", async () => {
        let seenUrl = "";
        server.use(
            http.get(`${API}/api/shippers/4/reviews`, ({ request }) => {
                seenUrl = request.url;
                return HttpResponse.json([], {
                    headers: { "X-Total": "12", "X-Page": "2", "X-Per-Page": "10", "X-Total-Pages": "2" },
                });
            }),
        );

        await listShipperReviews(4, 2);
        expect(seenUrl).toContain("page=2");
    });

    it("listShipperReviews defaults missing meta headers", async () => {
        server.use(
            http.get(`${API}/api/shippers/4/reviews`, () => HttpResponse.json([])),
        );

        const { meta } = await listShipperReviews(4);
        expect(meta).toEqual({ total: 0, page: 1, perPage: 10, totalPages: 1 });
    });
});
