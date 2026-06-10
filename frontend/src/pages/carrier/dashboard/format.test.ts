import { describe, expect, it } from "vitest";
import { formatQuantity, timeUntil } from "./format";

const NOW = Date.parse("2026-06-10T12:00:00Z");

describe("timeUntil", () => {
    it("returns 'ahora' for the immediate future and the past", () => {
        expect(timeUntil("2026-06-10T12:00:30Z", NOW)).toBe("ahora");
        expect(timeUntil("2026-06-10T11:00:00Z", NOW)).toBe("ahora");
    });

    it("formats minutes, hours and days", () => {
        expect(timeUntil("2026-06-10T12:45:00Z", NOW)).toBe("en 45 min");
        expect(timeUntil("2026-06-10T17:00:00Z", NOW)).toBe("en 5 h");
        expect(timeUntil("2026-06-13T12:00:00Z", NOW)).toBe("en 3 d");
    });

    it("returns empty string for an unparseable timestamp", () => {
        expect(timeUntil("not-a-date", NOW)).toBe("");
    });
});

describe("formatQuantity", () => {
    it("localizes decimal wire strings, dropping trailing zeros", () => {
        expect(formatQuantity("3000.0")).toBe("3.000");
        expect(formatQuantity("840.0")).toBe("840");
        expect(formatQuantity("12.5")).toBe("12,5");
    });

    it("returns unparseable input verbatim", () => {
        expect(formatQuantity("n/a")).toBe("n/a");
    });
});
