import { describe, expect, it, vi, beforeEach } from "vitest";
import { useState } from "react";
import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import {
    RadiusControl,
    RADIUS_DEFAULT_KM,
    RADIUS_MAX_KM,
    RADIUS_MIN_KM,
} from "./index";
import { radiusContent } from "./radiusContent";

// Stateful wrapper — mirrors what a real form does so the controlled `value`
// actually advances when the component emits `onChange`. Without it, typing
// into a controlled number input fights the test against React's value snap-back.
function Harness({
    initial,
    pin,
    onChange,
    error,
    role,
}: {
    initial: number;
    pin: { lat: number; lng: number } | null;
    onChange?: (v: number) => void;
    error?: string;
    role?: "pickup" | "dropoff";
}) {
    const [v, setV] = useState(initial);
    return (
        <RadiusControl
            role={role}
            pin={pin}
            value={v}
            onChange={(n) => { setV(n); onChange?.(n); }}
            error={error}
        />
    );
}

// State knobs the @googlemaps/js-api-loader mock reads at call time.
type LoaderMode = "ready" | "error" | "hang";
let loaderMode: LoaderMode = "ready";

// Captured Circle/Map instances per test so we can simulate "user drags the
// circle edge" by invoking the registered listeners directly.
type ListenerMap = Record<string, Array<() => void>>;
type MockCircle = {
    setRadius: (m: number) => void;
    getRadius: () => number;
    setCenter: (c: { lat: number; lng: number }) => void;
    getCenter: () => { lat: () => number; lng: () => number };
    getBounds: () => unknown;
    setMap: (m: unknown) => void;
    addListener: (event: string, cb: () => void) => { remove: () => void };
    __radiusM: number;
    __center: { lat: number; lng: number };
    __listeners: ListenerMap;
    __setMapCalls: unknown[];
    __opts: Record<string, unknown>;
};
let lastCircle: MockCircle | null = null;
const mapInstances: unknown[] = [];

function createMockCircle(opts: { center: { lat: number; lng: number }; radius: number } & Record<string, unknown>): MockCircle {
    const listeners: ListenerMap = {};
    const inst: MockCircle = {
        __radiusM:     opts.radius,
        __center:      opts.center,
        __listeners:   listeners,
        __setMapCalls: [],
        __opts:        opts,
        setRadius(m: number) {
            inst.__radiusM = m;
            (listeners["radius_changed"] ?? []).forEach((cb) => cb());
        },
        getRadius() { return inst.__radiusM; },
        setCenter(c) { inst.__center = c; },
        getCenter() { return { lat: () => inst.__center.lat, lng: () => inst.__center.lng }; },
        getBounds() { return null; },
        setMap(m) { inst.__setMapCalls.push(m); },
        addListener(event: string, cb: () => void) {
            (listeners[event] ??= []).push(cb);
            return { remove: () => {} };
        },
    };
    lastCircle = inst;
    return inst;
}

vi.mock("@googlemaps/js-api-loader", () => {
    class Loader {
        constructor(_opts: unknown) {}
        load() {
            if (loaderMode === "hang") return new Promise<void>(() => {});
            if (loaderMode === "error") return Promise.reject(new Error("load-error"));
            const mapsLib = {
                Map: function (this: unknown, _el: HTMLElement, _opts: unknown) {
                    const inst = { setCenter: vi.fn(), fitBounds: vi.fn() };
                    mapInstances.push(inst);
                    return inst;
                },
                Circle: function (this: unknown, opts: { center: { lat: number; lng: number }; radius: number } & Record<string, unknown>) {
                    return createMockCircle(opts);
                },
            };
            (globalThis as unknown as { google: { maps: Record<string, unknown> & { importLibrary: (n: string) => Promise<unknown> } } }).google = {
                maps: {
                    ...mapsLib,
                    importLibrary: (_n: string) => Promise.resolve(mapsLib),
                },
            };
            return Promise.resolve();
        }
    }
    return { Loader };
});

beforeEach(() => {
    loaderMode = "ready";
    lastCircle = null;
    mapInstances.length = 0;
    (globalThis as unknown as { google?: unknown }).google = undefined;
    vi.stubEnv("VITE_GOOGLE_MAPS_API_KEY", "test-key");
});

const ORIGIN = { lat: -34.603722, lng: -58.381592 };
const DESTINATION = { lat: -31.420083, lng: -64.188776 };

describe("RadiusControl — pickup role (default)", () => {
    it("renders the pickup label and the default input value", () => {
        const onChange = vi.fn();
        render(
            <RadiusControl
                pin={null}
                value={RADIUS_DEFAULT_KM}
                onChange={onChange}
            />,
        );
        expect(screen.getByText(radiusContent.pickup.label)).toBeInTheDocument();
        expect(screen.getByRole("spinbutton")).toHaveValue(RADIUS_DEFAULT_KM);
    });

    it("renders the no-pin placeholder and disables the input when pin is null", () => {
        render(
            <RadiusControl
                pin={null}
                value={RADIUS_DEFAULT_KM}
                onChange={vi.fn()}
            />,
        );
        expect(screen.getByTestId("pickup-radius-placeholder")).toHaveTextContent(
            radiusContent.pickup.placeholderWhenNoPin,
        );
        expect(screen.getByRole("spinbutton")).toBeDisabled();
        expect(screen.queryByTestId("pickup-radius-map")).not.toBeInTheDocument();
    });

    it("mounts the map container once a pin is provided", async () => {
        render(
            <RadiusControl
                pin={ORIGIN}
                value={RADIUS_DEFAULT_KM}
                onChange={vi.fn()}
            />,
        );
        await waitFor(() => expect(screen.queryByTestId("pickup-radius-map")).toBeInTheDocument());
        expect(screen.queryByTestId("pickup-radius-placeholder")).not.toBeInTheDocument();
        await waitFor(() => expect(lastCircle).not.toBeNull());
        expect(lastCircle!.__radiusM).toBe(RADIUS_DEFAULT_KM * 1000);
    });

    it("emits the integer km value when the user changes the input", () => {
        const onChange = vi.fn();
        render(<Harness initial={RADIUS_DEFAULT_KM} pin={ORIGIN} onChange={onChange} />);
        const input = screen.getByRole("spinbutton");
        fireEvent.change(input, { target: { value: "25" } });
        expect(onChange).toHaveBeenCalledWith(25);
    });

    it("clamps values below the min and above the max", () => {
        const onChange = vi.fn();
        render(<Harness initial={50} pin={ORIGIN} onChange={onChange} />);
        const input = screen.getByRole("spinbutton");
        fireEvent.change(input, { target: { value: "0" } });
        expect(onChange).toHaveBeenLastCalledWith(RADIUS_MIN_KM);

        onChange.mockClear();
        fireEvent.change(input, { target: { value: "999" } });
        expect(onChange).toHaveBeenLastCalledWith(RADIUS_MAX_KM);
    });

    it("rounds decimal input to the nearest integer", () => {
        const onChange = vi.fn();
        render(<Harness initial={10} pin={ORIGIN} onChange={onChange} />);
        const input = screen.getByRole("spinbutton");
        fireEvent.change(input, { target: { value: "12.6" } });
        expect(onChange).toHaveBeenLastCalledWith(13);
    });

    it("synchronises the circle to the input — typing 50 sets the circle radius to 50000m", async () => {
        const onChange = vi.fn();
        render(<Harness initial={10} pin={ORIGIN} onChange={onChange} />);
        await waitFor(() => expect(lastCircle).not.toBeNull());
        const input = screen.getByRole("spinbutton");
        fireEvent.change(input, { target: { value: "50" } });
        await waitFor(() => expect(lastCircle!.__radiusM).toBe(50_000));
    });

    it("synchronises the input to the circle — dragging the circle to 25km emits onChange(25)", async () => {
        const onChange = vi.fn();
        render(
            <RadiusControl
                pin={ORIGIN}
                value={10}
                onChange={onChange}
            />,
        );
        await waitFor(() => expect(lastCircle).not.toBeNull());
        // Simulate the user dragging the circle edge: Google fires `radius_changed`
        // after mutating the internal radius. We mimic by patching __radiusM
        // directly and invoking the registered listener.
        lastCircle!.__radiusM = 25_000;
        lastCircle!.__listeners["radius_changed"]?.forEach((cb) => cb());
        expect(onChange).toHaveBeenCalledWith(25);
    });

    it("does not loop — input change must not echo back through onChange a second time", async () => {
        const onChange = vi.fn();
        render(<Harness initial={10} pin={ORIGIN} onChange={onChange} />);
        await waitFor(() => expect(lastCircle).not.toBeNull());
        const input = screen.getByRole("spinbutton");
        fireEvent.change(input, { target: { value: "5" } });
        // Exactly one emission. The `radius_changed` listener fired by our
        // mocked setRadius() must be swallowed by the anti-loop flag.
        const calls = onChange.mock.calls.filter(([n]) => n === 5);
        expect(calls.length).toBe(1);
    });

    it("snaps the circle centre back to the pin if it drifts", async () => {
        render(
            <RadiusControl
                pin={ORIGIN}
                value={10}
                onChange={vi.fn()}
            />,
        );
        await waitFor(() => expect(lastCircle).not.toBeNull());
        lastCircle!.__center = { lat: ORIGIN.lat + 1, lng: ORIGIN.lng + 1 };
        lastCircle!.__listeners["center_changed"]?.forEach((cb) => cb());
        expect(lastCircle!.__center).toEqual(ORIGIN);
    });

    it("pushes external value changes (edit-mode hydration) into the circle radius", async () => {
        const onChange = vi.fn();
        const { rerender } = render(
            <RadiusControl
                pin={ORIGIN}
                value={10}
                onChange={onChange}
            />,
        );
        await waitFor(() => expect(lastCircle).not.toBeNull());
        rerender(
            <RadiusControl
                pin={ORIGIN}
                value={42}
                onChange={onChange}
            />,
        );
        await waitFor(() => expect(lastCircle!.__radiusM).toBe(42_000));
    });

    it("tears down the circle when pin is cleared and remounts it when pin returns", async () => {
        const onChange = vi.fn();
        const { rerender } = render(
            <RadiusControl
                pin={ORIGIN}
                value={10}
                onChange={onChange}
            />,
        );
        await waitFor(() => expect(lastCircle).not.toBeNull());
        const firstCircle = lastCircle!;
        rerender(
            <RadiusControl
                pin={null}
                value={10}
                onChange={onChange}
            />,
        );
        await waitFor(() => expect(firstCircle.__setMapCalls).toContain(null));
        rerender(
            <RadiusControl
                pin={ORIGIN}
                value={10}
                onChange={onChange}
            />,
        );
        await waitFor(() => expect(lastCircle).not.toBe(firstCircle));
    });

    it("shows the inline error and marks the input as invalid", () => {
        render(
            <RadiusControl
                pin={ORIGIN}
                value={10}
                onChange={vi.fn()}
                error={radiusContent.error.out_of_range}
            />,
        );
        expect(screen.getByRole("alert")).toHaveTextContent(radiusContent.error.out_of_range);
        expect(screen.getByRole("spinbutton")).toHaveAttribute("aria-invalid", "true");
    });

    it("falls back gracefully when the maps API key is missing — no map, placeholder copy when no pin", () => {
        vi.stubEnv("VITE_GOOGLE_MAPS_API_KEY", "");
        render(
            <RadiusControl
                pin={null}
                value={10}
                onChange={vi.fn()}
            />,
        );
        expect(screen.queryByTestId("pickup-radius-map")).not.toBeInTheDocument();
        expect(screen.getByTestId("pickup-radius-placeholder")).toBeInTheDocument();
    });

    it("survives a loader error — does not throw and never mounts a circle", async () => {
        loaderMode = "error";
        render(
            <RadiusControl
                pin={ORIGIN}
                value={10}
                onChange={vi.fn()}
            />,
        );
        // Give the rejected promise a tick to settle.
        await new Promise((r) => setTimeout(r, 0));
        expect(lastCircle).toBeNull();
    });
});

// REQ-BE-00039 AC12 — same component shell, different role copy + stroke colour.
// Visibility is driven by the parent: when the destination pin is null the form
// passes `pin={null}` and the dropoff variant collapses to the placeholder state.
describe("RadiusControl — dropoff role", () => {
    it("renders the dropoff label and placeholder copy", () => {
        render(
            <RadiusControl
                role="dropoff"
                pin={null}
                value={RADIUS_DEFAULT_KM}
                onChange={vi.fn()}
            />,
        );
        expect(screen.getByText(radiusContent.dropoff.label)).toBeInTheDocument();
        expect(screen.getByTestId("dropoff-radius-placeholder")).toHaveTextContent(
            radiusContent.dropoff.placeholderWhenNoPin,
        );
    });

    it("mounts the dropoff map when a destination pin is supplied", async () => {
        render(
            <RadiusControl
                role="dropoff"
                pin={DESTINATION}
                value={RADIUS_DEFAULT_KM}
                onChange={vi.fn()}
            />,
        );
        await waitFor(() => expect(screen.queryByTestId("dropoff-radius-map")).toBeInTheDocument());
        expect(screen.queryByTestId("dropoff-radius-placeholder")).not.toBeInTheDocument();
        await waitFor(() => expect(lastCircle).not.toBeNull());
        expect(lastCircle!.__center).toEqual(DESTINATION);
    });

    it("uses a distinct stroke colour from the pickup variant", async () => {
        render(
            <RadiusControl
                role="dropoff"
                pin={DESTINATION}
                value={RADIUS_DEFAULT_KM}
                onChange={vi.fn()}
            />,
        );
        await waitFor(() => expect(lastCircle).not.toBeNull());
        const dropoffStroke = lastCircle!.__opts.strokeColor as string;

        lastCircle = null;
        render(
            <RadiusControl
                role="pickup"
                pin={ORIGIN}
                value={RADIUS_DEFAULT_KM}
                onChange={vi.fn()}
            />,
        );
        await waitFor(() => expect(lastCircle).not.toBeNull());
        const pickupStroke = lastCircle!.__opts.strokeColor as string;

        expect(dropoffStroke).not.toBe(pickupStroke);
        expect(typeof dropoffStroke).toBe("string");
        expect(dropoffStroke.length).toBeGreaterThan(0);
    });

    it("hides the dropoff map entirely when the destination pin is cleared", async () => {
        const { rerender } = render(
            <RadiusControl
                role="dropoff"
                pin={DESTINATION}
                value={RADIUS_DEFAULT_KM}
                onChange={vi.fn()}
            />,
        );
        await waitFor(() => expect(screen.queryByTestId("dropoff-radius-map")).toBeInTheDocument());
        rerender(
            <RadiusControl
                role="dropoff"
                pin={null}
                value={RADIUS_DEFAULT_KM}
                onChange={vi.fn()}
            />,
        );
        await waitFor(() => expect(screen.queryByTestId("dropoff-radius-map")).not.toBeInTheDocument());
        expect(screen.getByTestId("dropoff-radius-placeholder")).toBeInTheDocument();
    });
});
