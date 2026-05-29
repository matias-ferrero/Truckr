import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import CargoMapPreview from "./CargoMapPreview";

// Capture constructor arguments so we can assert that pin positions and the
// fitBounds rectangle are derived from the picker coordinates.
const mapInstances: Array<{ fitBounds: ReturnType<typeof vi.fn> }> = [];
const markerArgs: Array<{ position: { lat: number; lng: number }; label?: string }> = [];

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
    loaderMode = "ready";
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
            Map: vi.fn().mockImplementation(() => {
                const inst = { fitBounds };
                mapInstances.push(inst);
                return inst;
            }),
            Marker: vi.fn().mockImplementation((args: { position: { lat: number; lng: number }; label?: string }) => {
                markerArgs.push(args);
                return { setMap: vi.fn() };
            }),
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
});
