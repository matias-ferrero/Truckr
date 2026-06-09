import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import CargoMapPreview from "./CargoMapPreview";

// Capture constructor arguments so we can assert that pin positions and the
// fitBounds rectangle are derived from the picker coordinates.
const mapInstances: Array<{ fitBounds: ReturnType<typeof vi.fn>; getDiv: () => Element | null }> = [];
const markerArgs: Array<{ position: { lat: number; lng: number }; label?: string }> = [];
const rendererInstances: Array<{ setMap: ReturnType<typeof vi.fn>; setDirections: ReturnType<typeof vi.fn> }> = [];

type LoaderMode = "ready" | "error";
let loaderMode: LoaderMode = "ready";

type DirectionsMode = "ok" | "zero_results" | "pending";
let directionsMode: DirectionsMode = "ok";
let directionsCallback: ((result: unknown, status: string) => void) | null = null;

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
    loaderMode = "ready";
    directionsMode = "ok";
    directionsCallback = null;
    vi.stubEnv("VITE_GOOGLE_MAPS_API_KEY", "test-key");

    const boundsCtor = vi.fn(() => {
        const points: Array<{ lat: number; lng: number }> = [];
        return {
            extend: (p: { lat: number; lng: number }) => points.push(p),
            points,
        };
    });
    const fitBounds = vi.fn();
    (globalThis as unknown as { google: unknown }).google = {
        maps: {
            LatLngBounds: boundsCtor,
            Map: vi.fn().mockImplementation((el: Element) => {
                const inst = { fitBounds, getDiv: () => el };
                mapInstances.push(inst);
                return inst;
            }),
            Marker: vi.fn().mockImplementation((args: { position: { lat: number; lng: number }; label?: string }) => {
                markerArgs.push(args);
                return { setMap: vi.fn() };
            }),
            DirectionsService: vi.fn().mockImplementation(() => ({
                route: vi.fn().mockImplementation((_req, cb) => {
                    if (directionsMode === "pending") {
                        directionsCallback = cb;
                        return;
                    }
                    if (directionsMode === "ok") {
                        cb(
                            { routes: [{ legs: [{ distance: { value: 712_000 } }] }] },
                            "OK",
                        );
                    } else {
                        cb(null, "ZERO_RESULTS");
                    }
                }),
            })),
            DirectionsRenderer: vi.fn().mockImplementation(() => {
                const inst = { setMap: vi.fn(), setDirections: vi.fn() };
                rendererInstances.push(inst);
                return inst;
            }),
            TravelMode: { DRIVING: "DRIVING" },
        },
    };
});

afterEach(() => {
    delete (globalThis as unknown as { google?: unknown }).google;
    vi.unstubAllEnvs();
    vi.restoreAllMocks();
});

describe("CargoMapPreview", () => {
    it("renders the idle placeholder when either side is missing", () => {
        render(<CargoMapPreview pickup={null} delivery={null} />);
        expect(screen.getByText("Vista previa del recorrido")).toBeInTheDocument();
        expect(
            screen.getByText(/Confirmá las dos direcciones/i),
        ).toBeInTheDocument();
    });

    it("creates two markers from the picker coordinates when both are confirmed", async () => {
        render(
            <CargoMapPreview
                pickup={{ text: "P", lat: -34.6, lng: -58.4 }}
                delivery={{ text: "D", lat: -31.4, lng: -64.2 }}
            />,
        );
        await waitFor(() => expect(markerArgs).toHaveLength(2));
        expect(markerArgs[0].position).toEqual({ lat: -34.6, lng: -58.4 });
        expect(markerArgs[1].position).toEqual({ lat: -31.4, lng: -64.2 });
        expect(mapInstances[0].fitBounds).toHaveBeenCalled();
    });

    it("falls back to a 'map unavailable' message when the loader rejects", async () => {
        loaderMode = "error";
        render(
            <CargoMapPreview
                pickup={{ text: "P", lat: -34.6, lng: -58.4 }}
                delivery={{ text: "D", lat: -31.4, lng: -64.2 }}
            />,
        );
        await waitFor(() => {
            expect(
                screen.getByText("No pudimos cargar el mapa. Las coordenadas se guardan igual."),
            ).toBeInTheDocument();
        });
    });

    it("shows a loading indicator while the Directions route call is pending", async () => {
        directionsMode = "pending";
        render(
            <CargoMapPreview
                pickup={{ text: "P", lat: -34.6, lng: -58.4 }}
                delivery={{ text: "D", lat: -31.4, lng: -64.2 }}
            />,
        );
        await waitFor(() => expect(markerArgs).toHaveLength(2));
        expect(screen.getByTestId("cargo-map-preview-distance-loading")).toBeInTheDocument();
        expect(screen.queryByTestId("cargo-map-preview-distance")).not.toBeInTheDocument();
    });

    it("displays the road distance when DirectionsService returns OK", async () => {
        render(
            <CargoMapPreview
                pickup={{ text: "P", lat: -34.6, lng: -58.4 }}
                delivery={{ text: "D", lat: -31.4, lng: -64.2 }}
            />,
        );
        await waitFor(() =>
            expect(screen.getByTestId("cargo-map-preview-distance")).toBeInTheDocument()
        );
        expect(screen.getByTestId("cargo-map-preview-distance")).toHaveTextContent(
            "Distancia por ruta: 712 km",
        );
    });

    it("draws the route polyline via DirectionsRenderer when DirectionsService returns OK", async () => {
        render(
            <CargoMapPreview
                pickup={{ text: "P", lat: -34.6, lng: -58.4 }}
                delivery={{ text: "D", lat: -31.4, lng: -64.2 }}
            />,
        );
        await waitFor(() => expect(rendererInstances).toHaveLength(1));
        expect(rendererInstances[0].setMap).toHaveBeenCalled();
        expect(rendererInstances[0].setDirections).toHaveBeenCalledWith(
            expect.objectContaining({ routes: expect.any(Array) }),
        );
    });

    it("shows the stored distanceKm and draws the route without using the leg distance", async () => {
        render(
            <CargoMapPreview
                pickup={{ text: "P", lat: -34.6, lng: -58.4 }}
                delivery={{ text: "D", lat: -31.4, lng: -64.2 }}
                distanceKm={712.45}
            />,
        );
        await waitFor(() =>
            expect(screen.getByTestId("cargo-map-preview-distance")).toBeInTheDocument()
        );
        // 712.45 km ≥ 100 → whole number
        expect(screen.getByTestId("cargo-map-preview-distance")).toHaveTextContent(
            "Distancia por ruta: 712 km",
        );
        // DirectionsService must still be called for the route geometry
        const { DirectionsService, DirectionsRenderer } = (
            globalThis as unknown as { google: { maps: typeof google.maps } }
        ).google.maps;
        expect(DirectionsService).toHaveBeenCalled();
        expect(DirectionsRenderer).toHaveBeenCalled();
    });

    it("shows the unavailable message when DirectionsService returns ZERO_RESULTS", async () => {
        directionsMode = "zero_results";
        render(
            <CargoMapPreview
                pickup={{ text: "P", lat: -34.6, lng: -58.4 }}
                delivery={{ text: "D", lat: -31.4, lng: -64.2 }}
            />,
        );
        await waitFor(() =>
            expect(screen.getByTestId("cargo-map-preview-distance-error")).toBeInTheDocument()
        );
        expect(screen.getByTestId("cargo-map-preview-distance-error")).toHaveTextContent(
            "No se pudo calcular la distancia de la ruta.",
        );
    });

    it("reinitialises the map when the canvas div remounts after an address is cleared", async () => {
        const pickup   = { text: "P", lat: -34.6, lng: -58.4 };
        const delivery = { text: "D", lat: -31.4, lng: -64.2 };

        const { rerender } = render(
            <CargoMapPreview pickup={pickup} delivery={delivery} />,
        );
        await waitFor(() => expect(mapInstances).toHaveLength(1));

        // Clearing pickup renders the idle placeholder — canvas div unmounts.
        rerender(<CargoMapPreview pickup={null} delivery={delivery} />);
        expect(mapInstances).toHaveLength(1);

        // Re-entering pickup remounts the canvas as a NEW DOM element.
        // Without the getDiv() guard the old Map instance would be reused on the
        // detached element; with it a fresh Map is created on the new div.
        rerender(<CargoMapPreview pickup={pickup} delivery={delivery} />);
        await waitFor(() => expect(mapInstances).toHaveLength(2));
        expect(mapInstances[1].fitBounds).toHaveBeenCalled();
    });
});
