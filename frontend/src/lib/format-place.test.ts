import { describe, expect, it } from "vitest";
import { formatPlace, formatRoute } from "./format-place";

const OPEN = "Cualquier destino";

describe("formatPlace", () => {
    it("joins locality and admin_area with a comma", () => {
        expect(formatPlace({ locality: "Palermo", admin_area: "CABA" })).toBe("Palermo, CABA");
    });

    it("returns the locality only when admin_area is missing", () => {
        expect(formatPlace({ locality: "Palermo", admin_area: "" })).toBe("Palermo");
    });

    it("returns the admin_area only when locality is missing", () => {
        expect(formatPlace({ locality: "", admin_area: "CABA" })).toBe("CABA");
    });

    it("returns an empty string for a null place", () => {
        expect(formatPlace(null)).toBe("");
    });

    it("trims leading/trailing whitespace", () => {
        expect(formatPlace({ locality: "  Córdoba  ", admin_area: " Córdoba " }))
            .toBe("Córdoba, Córdoba");
    });
});

describe("formatRoute", () => {
    it("renders origin → destination when both have place data", () => {
        const route = formatRoute(
            { locality: "CABA", admin_area: "CABA" },
            { locality: "Córdoba", admin_area: "Córdoba" },
            OPEN,
        );
        expect(route).toBe("CABA, CABA → Córdoba, Córdoba");
    });

    it("renders the open-destination label when the destination is null", () => {
        const route = formatRoute(
            { locality: "CABA", admin_area: "CABA" },
            null,
            OPEN,
        );
        expect(route).toBe(`CABA, CABA → ${OPEN}`);
    });

    it("treats an all-empty destination as open", () => {
        const route = formatRoute(
            { locality: "CABA", admin_area: "CABA" },
            { locality: "", admin_area: null },
            OPEN,
        );
        expect(route).toBe(`CABA, CABA → ${OPEN}`);
    });
});
