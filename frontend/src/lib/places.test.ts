import { describe, expect, it } from "vitest";
import { parsePlace, normalizeAdminArea, type PlaceLike } from "./places";

function makePlace(args: {
    formattedAddress?: string;
    lat?: number;
    lng?: number;
    components?: Array<{ types: string[]; longText?: string; shortText?: string }>;
}): PlaceLike {
    return {
        formattedAddress: args.formattedAddress,
        location:
            args.lat !== undefined && args.lng !== undefined
                ? { lat: () => args.lat!, lng: () => args.lng! }
                : null,
        addressComponents: args.components,
    };
}

describe("parsePlace", () => {
    it("uses `locality` when present (primary cascade branch)", () => {
        const result = parsePlace(
            makePlace({
                formattedAddress: "Av. Corrientes 1234, CABA, Argentina",
                lat:              -34.603722,
                lng:              -58.381592,
                components:       [
                    { types: ["locality"], longText: "Buenos Aires" },
                    { types: ["administrative_area_level_1"], longText: "Ciudad Autónoma de Buenos Aires" },
                ],
            }),
        );
        expect(result.locality).toBe("Buenos Aires");
        expect(result.admin_area).toBe("CABA");
        expect(result.address).toBe("Av. Corrientes 1234, CABA, Argentina");
        expect(result.lat).toBe(-34.603722);
        expect(result.lng).toBe(-58.381592);
    });

    it("falls back to `sublocality_level_1` when locality is absent", () => {
        const result = parsePlace(
            makePlace({
                formattedAddress: "Palermo, CABA, Argentina",
                lat:              -34.5889,
                lng:              -58.4279,
                components:       [
                    { types: ["sublocality_level_1"], longText: "Palermo" },
                    { types: ["administrative_area_level_1"], longText: "Ciudad Autónoma de Buenos Aires" },
                ],
            }),
        );
        expect(result.locality).toBe("Palermo");
    });

    it("falls back to `administrative_area_level_2` when locality and sublocality are absent", () => {
        const result = parsePlace(
            makePlace({
                formattedAddress: "Tigre, Buenos Aires, Argentina",
                lat:              -34.4264,
                lng:              -58.5797,
                components:       [
                    { types: ["administrative_area_level_2"], longText: "Tigre" },
                    { types: ["administrative_area_level_1"], longText: "Buenos Aires" },
                ],
            }),
        );
        expect(result.locality).toBe("Tigre");
        expect(result.admin_area).toBe("Buenos Aires");
    });

    it("falls back to first comma-separated chunk of formatted address when no admin components are present", () => {
        const result = parsePlace(
            makePlace({
                formattedAddress: "Cabo Vírgenes, Santa Cruz, Argentina",
                lat:              -52.3375,
                lng:              -68.3625,
                components:       [],
            }),
        );
        expect(result.locality).toBe("Cabo Vírgenes");
        expect(result.admin_area).toBe("Cabo Vírgenes");
    });

    it("sources admin_area from administrative_area_level_1 (provincia)", () => {
        const result = parsePlace(
            makePlace({
                formattedAddress: "Av. Colón 500, Córdoba, Argentina",
                lat:              -31.4201,
                lng:              -64.1888,
                components:       [
                    { types: ["locality"], longText: "Córdoba" },
                    { types: ["administrative_area_level_1"], longText: "Córdoba" },
                ],
            }),
        );
        expect(result.admin_area).toBe("Córdoba");
    });

    it("truncates lat/lng to 6 decimal places to match DECIMAL(9,6)", () => {
        const result = parsePlace(
            makePlace({
                formattedAddress: "Test",
                lat:              -34.6037229999,
                lng:              -58.3815919999,
                components:       [{ types: ["locality"], longText: "Test" }],
            }),
        );
        expect(result.lat).toBe(-34.603723);
        expect(result.lng).toBe(-58.381592);
    });

    it("returns NaN coords when location is absent", () => {
        const result = parsePlace({
            formattedAddress: "Nowhere",
            location:         null,
            addressComponents: [],
        });
        expect(Number.isNaN(result.lat)).toBe(true);
        expect(Number.isNaN(result.lng)).toBe(true);
    });

    it("prefers longText over shortText", () => {
        const result = parsePlace(
            makePlace({
                formattedAddress: "Test",
                lat:              0,
                lng:              0,
                components:       [
                    {
                        types:     ["locality"],
                        longText:  "San Carlos de Bariloche",
                        shortText: "Bariloche",
                    },
                ],
            }),
        );
        expect(result.locality).toBe("San Carlos de Bariloche");
    });

    it("normalises Ciudad Autónoma de Buenos Aires → CABA at parse time", () => {
        const result = parsePlace(
            makePlace({
                formattedAddress: "Av. Corrientes 1234, Buenos Aires, Argentina",
                lat:              -34.603722,
                lng:              -58.381592,
                components:       [
                    { types: ["locality"], longText: "Buenos Aires" },
                    { types: ["administrative_area_level_1"], longText: "Ciudad Autónoma de Buenos Aires" },
                ],
            }),
        );
        expect(result.admin_area).toBe("CABA");
    });
});

describe("normalizeAdminArea", () => {
    it("maps the accented form to CABA", () => {
        expect(normalizeAdminArea("Ciudad Autónoma de Buenos Aires")).toBe("CABA");
    });

    it("maps the unaccented form to CABA", () => {
        expect(normalizeAdminArea("Ciudad Autonoma de Buenos Aires")).toBe("CABA");
    });

    it("is case-insensitive", () => {
        expect(normalizeAdminArea("CIUDAD AUTÓNOMA DE BUENOS AIRES")).toBe("CABA");
    });

    it("leaves other provinces unchanged", () => {
        expect(normalizeAdminArea("Buenos Aires")).toBe("Buenos Aires");
        expect(normalizeAdminArea("Córdoba")).toBe("Córdoba");
    });

    it("returns the input unchanged for empty string", () => {
        expect(normalizeAdminArea("")).toBe("");
    });
});
