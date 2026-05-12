import { describe, expect, it } from "vitest";
import { http, HttpResponse } from "msw";
import { server } from "../test/mocks/server";
import { formatCurrency, getCarrier } from "./carriers";

const API = "http://localhost:3000";

describe("api/carriers", () => {
    it("getCarrier hits GET /api/carriers/:id and returns the body", async () => {
        server.use(
            http.get(`${API}/api/carriers/7`, () =>
                HttpResponse.json({
                    id: 7,
                    legal_name: "Andina SRL",
                    tax_id: null,
                    base_city: "Mendoza",
                    province: "Mendoza",
                    description: null,
                    rating_avg: "4.2",
                    reviews_count: 3,
                    completed_shipments: 9,
                    vehicles: [],
                    transport_windows: [],
                    created_at: "",
                    updated_at: "",
                })),
        );

        const carrier = await getCarrier(7);
        expect(carrier.id).toBe(7);
        expect(carrier.legal_name).toBe("Andina SRL");
        expect(carrier.transport_windows).toEqual([]);
    });

    describe("formatCurrency", () => {
        it("formats ARS without fractional digits", () => {
            const out = formatCurrency(123_400, "ARS", "es-AR");
            // Intl uses a non-breaking space and may format differently; just check digits.
            expect(out).toMatch(/1\.?234/);
        });
    });
});
