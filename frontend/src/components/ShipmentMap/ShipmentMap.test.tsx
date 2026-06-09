import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import { ShipmentMap, toLatLng } from "./index";

// Capture constructor args so we can assert pin positions and route rendering.
const mapInstances: Array<{ fitBounds: ReturnType<typeof vi.fn>; getDiv: () => Element | null }> = [];
const markerArgs: Array<{ position: { lat: number; lng: number }; icon?: string; title?: string }> = [];
const rendererInstances: Array<{ setMap: ReturnType<typeof vi.fn>; setDirections: ReturnType<typeof vi.fn> }> = [];
let directionsCb: ((result: unknown, status: string) => void) | null = null;

type LoaderMode = "ready" | "error";
let loaderMode: LoaderMode = "ready";

vi.mock("@googlemaps/js-api-loader", () => {
    class Loader {
        constructor(_opts: unknown) {}
        load() {
            if (loaderMode === "error") return Promise.reject(new Error("load-error"));
            return Promise.resolve();
        }
    }
    return { Loader };
});

beforeEach(() => {
    mapInstances.length = 0;
    markerArgs.length = 0;
    rendererInstances.length = 0;
    directionsCb = null;
    loaderMode = "ready";
    vi.stubEnv("VITE_GOOGLE_MAPS_API_KEY", "test-key");

    const fitBounds = vi.fn();
    (globalThis as unknown as { google: unknown }).google = {
        maps: {
            TravelMode: { DRIVING: "DRIVING" },
            LatLngBounds: vi.fn(() => {
                const points: Array<{ lat: number; lng: number }> = [];
                return { extend: (p: { lat: number; lng: number }) => points.push(p), points };
            }),
            Map: vi.fn().mockImplementation((el: Element) => {
                const inst = { fitBounds, getDiv: () => el };
                mapInstances.push(inst);
                return inst;
            }),
            Marker: vi.fn().mockImplementation((args: { position: { lat: number; lng: number }; icon?: string; title?: string }) => {
                markerArgs.push(args);
                return { setMap: vi.fn() };
            }),
            DirectionsService: vi.fn().mockImplementation(() => ({
                route: vi.fn().mockImplementation((_req: unknown, cb: (result: unknown, status: string) => void) => {
                    directionsCb = cb;
                }),
            })),
            DirectionsRenderer: vi.fn().mockImplementation(() => {
                const inst = { setMap: vi.fn(), setDirections: vi.fn() };
                rendererInstances.push(inst);
                return inst;
            }),
        },
    };
});

afterEach(() => {
    delete (globalThis as unknown as { google?: unknown }).google;
    vi.unstubAllEnvs();
    vi.restoreAllMocks();
});

const ORIGIN = { lat: -34.6, lng: -58.4, label: "Origen X" };
const DESTINATION = { lat: -31.4, lng: -64.2, label: "Destino Y" };

describe("toLatLng", () => {
    it("parses DECIMAL string coordinates into numbers", () => {
        expect(toLatLng("-34.603722", "-58.381592", "addr")).toEqual({
            lat: -34.603722,
            lng: -58.381592,
            label: "addr",
        });
    });

    it("returns null when either coordinate is missing", () => {
        expect(toLatLng(null, "-58.4")).toBeNull();
        expect(toLatLng("-34.6", undefined)).toBeNull();
    });

    it("returns null for non-finite input", () => {
        expect(toLatLng("not-a-number", "-58.4")).toBeNull();
    });
});

describe("ShipmentMap", () => {
    it("renders two markers (green origin, red destination) and fits bounds", async () => {
        render(<ShipmentMap origin={ORIGIN} destination={DESTINATION} />);
        await waitFor(() => expect(markerArgs).toHaveLength(2));

        expect(markerArgs[0].position).toEqual({ lat: -34.6, lng: -58.4 });
        expect(markerArgs[0].icon).toContain("green-dot");
        expect(markerArgs[1].position).toEqual({ lat: -31.4, lng: -64.2 });
        expect(markerArgs[1].icon).toContain("red-dot");
        expect(mapInstances[0].fitBounds).toHaveBeenCalled();
    });

    it("draws the driving route polyline after the markers are placed", async () => {
        render(<ShipmentMap origin={ORIGIN} destination={DESTINATION} />);
        await waitFor(() => expect(markerArgs).toHaveLength(2));

        // DirectionsService callback was captured — simulate a successful response.
        expect(directionsCb).not.toBeNull();
        const fakeResult = { routes: [{ legs: [{ distance: { value: 712_000 } }] }] };
        directionsCb!(fakeResult, "OK");

        expect(rendererInstances).toHaveLength(1);
        expect(rendererInstances[0].setDirections).toHaveBeenCalledWith(fakeResult);
        expect(rendererInstances[0].setMap).toHaveBeenCalledWith(mapInstances[0]);
    });

    it("shows pins without a route when DirectionsService returns an error", async () => {
        render(<ShipmentMap origin={ORIGIN} destination={DESTINATION} />);
        await waitFor(() => expect(markerArgs).toHaveLength(2));

        directionsCb!(null, "ZERO_RESULTS");

        // No renderer created — the map stays at the two-pin state.
        expect(rendererInstances).toHaveLength(0);
        expect(screen.getByTestId("shipment-map-canvas")).toBeInTheDocument();
    });

    it("does not rebuild markers or re-fit bounds on a re-render with unchanged coords", async () => {
        const { rerender } = render(<ShipmentMap origin={ORIGIN} destination={DESTINATION} />);
        await waitFor(() => expect(markerArgs).toHaveLength(2));
        expect(mapInstances[0].fitBounds).toHaveBeenCalledTimes(1);

        // Fresh object refs, identical coordinates — mimics the detail page
        // recomputing the pins via toLatLng() on every parent re-render.
        rerender(
            <ShipmentMap
                origin={{ lat: -34.6, lng: -58.4, label: "Origen X" }}
                destination={{ lat: -31.4, lng: -64.2, label: "Destino Y" }}
            />,
        );
        // Still two markers, fitBounds not called again — no map snap-back.
        expect(markerArgs).toHaveLength(2);
        expect(mapInstances[0].fitBounds).toHaveBeenCalledTimes(1);
    });

    it("shows the unavailable message when origin is null (AC3)", () => {
        render(<ShipmentMap origin={null} destination={DESTINATION} />);
        expect(screen.getByText(/mapa no disponible/i)).toBeInTheDocument();
        expect(screen.queryByTestId("shipment-map-canvas")).not.toBeInTheDocument();
    });

    it("shows the unavailable message when destination is null (AC3)", () => {
        render(<ShipmentMap origin={ORIGIN} destination={null} />);
        expect(screen.getByText(/mapa no disponible/i)).toBeInTheDocument();
    });

    it("falls back to service-unavailable when the loader rejects (AC9)", async () => {
        loaderMode = "error";
        render(<ShipmentMap origin={ORIGIN} destination={DESTINATION} />);
        await waitFor(() =>
            expect(screen.getByText(/no pudimos cargar el mapa/i)).toBeInTheDocument(),
        );
        expect(screen.queryByTestId("shipment-map-canvas")).not.toBeInTheDocument();
    });

    it("falls back to service-unavailable when the API key is missing (AC9)", () => {
        vi.stubEnv("VITE_GOOGLE_MAPS_API_KEY", "");
        render(<ShipmentMap origin={ORIGIN} destination={DESTINATION} />);
        expect(screen.getByText(/no pudimos cargar el mapa/i)).toBeInTheDocument();
    });
});
