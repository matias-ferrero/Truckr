import { describe, expect, it } from "vitest";
import { haversineKm } from "./geo";

const CABA = { lat: -34.603722, lng: -58.381592 };
const LA_PLATA = { lat: -34.921450, lng: -57.954529 };
const SALTA = { lat: -24.7821, lng: -65.4232 };

describe("haversineKm", () => {
    it("is zero for identical points", () => {
        expect(haversineKm(CABA, CABA)).toBeCloseTo(0, 6);
    });

    it("is symmetric", () => {
        expect(haversineKm(CABA, LA_PLATA)).toBeCloseTo(
            haversineKm(LA_PLATA, CABA),
            6,
        );
    });

    it("matches the backend reference for CABA ↔ La Plata (~56 km)", () => {
        // Same fixture and tolerance the Ruby Geo spec uses for US5 AC8.
        expect(haversineKm(CABA, LA_PLATA)).toBeGreaterThan(50);
        expect(haversineKm(CABA, LA_PLATA)).toBeLessThan(60);
    });

    it("returns ~1300 km from CABA to Salta", () => {
        const d = haversineKm(CABA, SALTA);
        expect(d).toBeGreaterThan(1250);
        expect(d).toBeLessThan(1400);
    });
});
