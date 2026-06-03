import { beforeEach, describe, expect, it, vi } from "vitest";
import { listCarrierReviews } from "./reviews";

const BASE = "http://localhost:3000";

describe("listCarrierReviews", () => {
    beforeEach(() => {
        vi.stubGlobal("fetch", vi.fn());
    });

    it("GETs /api/carriers/:id/reviews and returns items + Pagy meta", async () => {
        window.localStorage.setItem("truckr.jwt", "test-jwt");

        const items = [
            {
                id: 1,
                rating: 5,
                body: "Excelente",
                authored_by: "shipper" as const,
                created_at: "2026-06-01T12:00:00Z",
            },
        ];
        vi.mocked(fetch).mockResolvedValueOnce(
            new Response(JSON.stringify(items), {
                status: 200,
                headers: {
                    "X-Total": "1",
                    "X-Page": "1",
                    "X-Per-Page": "10",
                    "X-Total-Pages": "1",
                },
            }),
        );

        const result = await listCarrierReviews(42, 2);

        const [url, init] = vi.mocked(fetch).mock.calls[0] as [string, RequestInit];
        expect(url).toBe(`${BASE}/api/carriers/42/reviews?page=2`);
        const headers = new Headers(init.headers as HeadersInit);
        expect(headers.get("Authorization")).toBe("Bearer test-jwt");
        expect(result.items).toEqual(items);
        expect(result.meta).toEqual({
            total: 1,
            page: 1,
            perPage: 10,
            totalPages: 1,
        });
    });
});
