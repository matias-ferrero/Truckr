import { describe, expect, it } from "vitest";
import { formatDistance } from "./format-distance";

describe("formatDistance", () => {
    it("formats sub-km distances in meters", () => {
        expect(formatDistance(0.5)).toBe("500 m");
        expect(formatDistance(0.123)).toBe("123 m");
        expect(formatDistance(0.999)).toBe("999 m");
    });

    it("formats 1–99 km with one decimal", () => {
        expect(formatDistance(1)).toBe("1.0 km");
        expect(formatDistance(12.34)).toBe("12.3 km");
        expect(formatDistance(99.9)).toBe("99.9 km");
    });

    it("formats ≥ 100 km as a whole number", () => {
        expect(formatDistance(100)).toBe("100 km");
        expect(formatDistance(712.45)).toBe("712 km");
        expect(formatDistance(1234.5)).toBe("1235 km");
    });
});
