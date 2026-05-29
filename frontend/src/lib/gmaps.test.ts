import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const constructorCalls: unknown[] = [];

vi.mock("@googlemaps/js-api-loader", () => {
    class Loader {
        constructor(opts: unknown) {
            constructorCalls.push(opts);
        }
        load() { return Promise.resolve(); }
    }
    return { Loader };
});

describe("getGoogleMapsLoader", () => {
    beforeEach(async () => {
        constructorCalls.length = 0;
        vi.resetModules();
    });

    afterEach(() => {
        constructorCalls.length = 0;
    });

    it("constructs exactly one Loader regardless of caller count", async () => {
        const { getGoogleMapsLoader } = await import("./gmaps");
        const a = getGoogleMapsLoader("key");
        const b = getGoogleMapsLoader("key");
        const c = getGoogleMapsLoader("key");
        expect(constructorCalls).toHaveLength(1);
        expect(a).toBe(b);
        expect(b).toBe(c);
    });

    it("requests the union of libraries that every map-bearing component needs", async () => {
        const { getGoogleMapsLoader } = await import("./gmaps");
        getGoogleMapsLoader("key");
        const opts = constructorCalls[0] as { libraries: string[] };
        // Sorted comparison so future additions don't depend on order.
        expect([...opts.libraries].sort()).toEqual(["maps", "places"]);
    });
});
