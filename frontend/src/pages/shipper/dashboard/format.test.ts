import { describe, expect, it } from "vitest";
import { formatArs, relativeTime } from "./format";

describe("formatArs", () => {
    it("formats cents as ARS with no decimals", () => {
        const out = formatArs(123_400);
        expect(out).toContain("1.234");
        expect(out).not.toContain(",00");
    });

    it("rounds to the nearest peso", () => {
        expect(formatArs(150)).toContain("2");
    });
});

describe("relativeTime", () => {
    const now = new Date("2026-06-07T12:00:00Z").getTime();

    it("returns 'ahora' under a minute", () => {
        expect(relativeTime("2026-06-07T11:59:30Z", now)).toBe("ahora");
    });

    it("returns minutes", () => {
        expect(relativeTime("2026-06-07T11:45:00Z", now)).toBe("hace 15 min");
    });

    it("returns hours", () => {
        expect(relativeTime("2026-06-07T10:00:00Z", now)).toBe("hace 2 h");
    });

    it("returns days", () => {
        expect(relativeTime("2026-06-04T12:00:00Z", now)).toBe("hace 3 d");
    });

    it("returns weeks", () => {
        expect(relativeTime("2026-05-24T12:00:00Z", now)).toBe("hace 2 sem");
    });

    it("returns empty string for invalid input", () => {
        expect(relativeTime("not-a-date", now)).toBe("");
    });
});
