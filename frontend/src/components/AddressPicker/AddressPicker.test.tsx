import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AddressPicker, type AddressPickerValue } from "./index";
import { addressPickerContent } from "./addressPickerContent";

// State knobs that the @googlemaps/js-api-loader mock reads at call time.
// Each test resets these in beforeEach, then optionally tweaks them before
// rendering to simulate loading / load-error / a particular suggestion list.
type LoaderMode = "ready" | "error" | "hang";
let loaderMode: LoaderMode = "ready";
type SuggestionFactory = () => google.maps.places.AutocompleteSuggestion[];
let nextSuggestions: SuggestionFactory = () => [];
const sessionTokenCtor = vi.fn();

vi.mock("@googlemaps/js-api-loader", () => {
    class Loader {
        constructor(_opts: unknown) {}
        load() {
            if (loaderMode === "hang") return new Promise<void>(() => {});
            if (loaderMode === "error") return Promise.reject(new Error("load-error"));
            // Install just enough of `google.maps.places` for the component to call.
            const placesLib = {
                AutocompleteSuggestion:   { fetchAutocompleteSuggestions: vi.fn(() => Promise.resolve({ suggestions: nextSuggestions() })) },
                AutocompleteSessionToken: sessionTokenCtor,
            };
            (globalThis as unknown as { google: { maps: { importLibrary: (n: string) => Promise<unknown> } } }).google = {
                maps: {
                    importLibrary: (_name: string) => Promise.resolve(placesLib),
                },
            };
            return Promise.resolve();
        }
    }
    return { Loader };
});

beforeEach(() => {
    loaderMode = "ready";
    nextSuggestions = () => [];
    sessionTokenCtor.mockReset();
    sessionTokenCtor.mockImplementation(() => ({}));
    // Clear any stamped `google` so each test starts cold.
    (globalThis as unknown as { google?: unknown }).google = undefined;
    vi.stubEnv("VITE_GOOGLE_MAPS_API_KEY", "test-key");
});

type SuggestionOpts = {
    lat?: number;
    lng?: number;
    address?: string;
    mainText?: string;
    secondaryText?: string;
    locationNull?: boolean;
};

function makeSuggestion(opts: SuggestionOpts = {}): google.maps.places.AutocompleteSuggestion {
    const address = opts.address ?? "Av. Corrientes 1234, CABA, Argentina";
    const lat = opts.lat ?? -34.6;
    const lng = opts.lng ?? -58.4;
    const pred = {
        placeId:       `pid:${address}:${lat},${lng}`,
        text:          { text: address },
        mainText:      { text: opts.mainText ?? address },
        secondaryText: opts.secondaryText ? { text: opts.secondaryText } : null,
        toPlace() {
            const place: Record<string, unknown> = {
                formattedAddress: address,
                location:         opts.locationNull
                    ? null
                    : ({
                        lat: () => lat,
                        lng: () => lng,
                    } as unknown as google.maps.LatLng),
            };
            place.fetchFields = vi.fn(() => Promise.resolve({ place }));
            return place as unknown as google.maps.places.Place;
        },
    } as unknown as google.maps.places.PlacePrediction;
    return { placePrediction: pred } as google.maps.places.AutocompleteSuggestion;
}

async function waitForReady() {
    // Once the loader resolves, the component flips out of the "loading" state
    // and exposes the combobox. We key off that to know the picker is interactive.
    return await screen.findByRole("combobox", {}, { timeout: 2000 });
}

describe("AddressPicker", () => {
    it("renders in idle state with the default placeholder", async () => {
        const onChange = vi.fn();
        render(<AddressPicker value={null} onChange={onChange} aria-label="Origin" />);
        const input = await waitForReady();
        expect(input).toHaveAttribute("placeholder", addressPickerContent.placeholder);
        expect(input).toHaveValue("");
    });

    it("emits { text, lat, lng, locality, admin_area } truncated to 6 decimals when a suggestion is selected", async () => {
        nextSuggestions = () => [
            makeSuggestion({ lat: -34.6037229876, lng: -58.3815912345, address: "Av. Corrientes 1234, CABA, Argentina" }),
        ];
        const onChange = vi.fn();
        render(<AddressPicker value={null} onChange={onChange} aria-label="Origin" />);
        const input = await waitForReady();
        await userEvent.type(input, "Av");
        const option = await screen.findByRole("option");
        await userEvent.click(option);
        await waitFor(() => {
            expect(onChange).toHaveBeenLastCalledWith(expect.objectContaining({
                text: "Av. Corrientes 1234, CABA, Argentina",
                lat:  -34.603723,
                lng:  -58.381591,
            }));
        });
    });

    it("never emits onChange with non-finite lat/lng when a suggestion is selected", async () => {
        nextSuggestions = () => [makeSuggestion({ lat: -34.6, lng: -58.4 })];
        const onChange = vi.fn();
        render(<AddressPicker value={null} onChange={onChange} aria-label="Origin" />);
        const input = await waitForReady();
        await userEvent.type(input, "x");
        const option = await screen.findByRole("option");
        await userEvent.click(option);
        await waitFor(() => expect(onChange).toHaveBeenCalled());
        const confirmed = onChange.mock.calls
            .map((c) => c[0] as AddressPickerValue | null)
            .filter((v): v is AddressPickerValue => v !== null);
        expect(confirmed.length).toBeGreaterThan(0);
        for (const v of confirmed) {
            expect(typeof v.lat).toBe("number");
            expect(typeof v.lng).toBe("number");
            expect(Number.isFinite(v.lat)).toBe(true);
            expect(Number.isFinite(v.lng)).toBe(true);
        }
    });

    it("prefills the input from a non-null `value` (US33 edit-mode hydration)", async () => {
        const onChange = vi.fn();
        render(
            <AddressPicker
                value={{ text: "Mendoza Capital, Argentina", lat: -32.8895, lng: -68.8458 }}
                onChange={onChange}
                aria-label="Origin"
            />,
        );
        const input = await waitForReady();
        expect(input).toHaveValue("Mendoza Capital, Argentina");
    });

    it("invalidates the confirmed value when the user edits the input after picking", async () => {
        const onChange = vi.fn();
        render(
            <AddressPicker
                value={{ text: "Av. Corrientes 1234, CABA, Argentina", lat: -34.6, lng: -58.4 }}
                onChange={onChange}
                aria-label="Origin"
            />,
        );
        const input = await waitForReady();
        await userEvent.type(input, "x");
        expect(onChange).toHaveBeenCalledWith(null);
    });

    it("shows the unconfirmed error after blur with typed text and no selection", async () => {
        nextSuggestions = () => [];
        const onChange = vi.fn();
        render(<AddressPicker value={null} onChange={onChange} aria-label="Origin" />);
        const input = await waitForReady();
        await userEvent.type(input, "Buenos");
        await userEvent.tab();
        // The blur is debounced 150ms internally — wait it out.
        const alert = await screen.findByRole("alert", {}, { timeout: 1000 });
        expect(alert).toHaveTextContent(addressPickerContent.error.unconfirmed);
        expect(input).toHaveAttribute("aria-invalid", "true");
    });

    it("emits null when a selected place has no resolvable location", async () => {
        nextSuggestions = () => [makeSuggestion({ locationNull: true })];
        const onChange = vi.fn();
        render(<AddressPicker value={null} onChange={onChange} aria-label="Origin" />);
        const input = await waitForReady();
        await userEvent.type(input, "??");
        const option = await screen.findByRole("option");
        await userEvent.click(option);
        await waitFor(() => expect(onChange).toHaveBeenLastCalledWith(null));
    });

    it("renders the service_unavailable fallback when the JS API fails to load", async () => {
        loaderMode = "error";
        const onChange = vi.fn();
        const { container } = render(<AddressPicker value={null} onChange={onChange} aria-label="Origin" />);
        await waitFor(() => {
            expect(container.querySelector("[data-state='service_unavailable']")).not.toBeNull();
        });
        expect(screen.getByRole("alert")).toHaveTextContent(addressPickerContent.error.serviceUnavailable);
        expect(screen.getByRole("textbox", { name: /origin/i })).toBeDisabled();
    });

    it("renders the service_unavailable fallback when the api key is missing", () => {
        vi.stubEnv("VITE_GOOGLE_MAPS_API_KEY", "");
        const onChange = vi.fn();
        const { container } = render(<AddressPicker value={null} onChange={onChange} aria-label="Origin" />);
        expect(container.querySelector("[data-state='service_unavailable']")).not.toBeNull();
    });

    it("renders the loading state while the JS API loader is pending", () => {
        loaderMode = "hang";
        const onChange = vi.fn();
        const { container } = render(<AddressPicker value={null} onChange={onChange} aria-label="Origin" />);
        expect(container.querySelector("[data-state='loading']")).not.toBeNull();
        expect(screen.getByRole("textbox", { name: /origin/i })).toBeDisabled();
    });

    it("surfaces a parent-supplied error string and sets aria-invalid", async () => {
        const onChange = vi.fn();
        render(
            <AddressPicker value={null} onChange={onChange} error="campo requerido" aria-label="Origin" />,
        );
        await waitForReady();
        expect(screen.getByRole("alert")).toHaveTextContent("campo requerido");
        expect(screen.getByRole("combobox", { name: /origin/i })).toHaveAttribute("aria-invalid", "true");
    });

    it("respects the `disabled` prop", async () => {
        const onChange = vi.fn();
        render(<AddressPicker value={null} onChange={onChange} disabled aria-label="Origin" />);
        await waitForReady();
        expect(screen.getByRole("combobox", { name: /origin/i })).toBeDisabled();
    });

    it("waits to surface the unconfirmed error until blur", async () => {
        const onChange = vi.fn();
        render(<AddressPicker value={null} onChange={onChange} aria-label="Origin" />);
        const input = await waitForReady();
        await userEvent.type(input, "Bue");
        await waitFor(() => {
            expect(screen.queryByRole("alert")).toBeNull();
        });
    });

    it("opens the listbox with suggestions after typing and supports keyboard selection", async () => {
        nextSuggestions = () => [
            makeSuggestion({ lat: -34.6, lng: -58.4, address: "Av. Corrientes 1234, CABA, Argentina", mainText: "Av. Corrientes 1234", secondaryText: "CABA, Argentina" }),
            makeSuggestion({ lat: -34.61, lng: -58.41, address: "Av. Corrientes 2000, CABA, Argentina", mainText: "Av. Corrientes 2000", secondaryText: "CABA, Argentina" }),
        ];
        const onChange = vi.fn();
        render(<AddressPicker value={null} onChange={onChange} aria-label="Origin" />);
        const input = await waitForReady();
        await userEvent.type(input, "Av");
        const options = await screen.findAllByRole("option");
        expect(options).toHaveLength(2);
        // ArrowDown → first option becomes active; Enter confirms.
        await userEvent.keyboard("{ArrowDown}{Enter}");
        await waitFor(() => {
            expect(onChange).toHaveBeenLastCalledWith(expect.objectContaining({
                text: "Av. Corrientes 1234, CABA, Argentina",
                lat:  -34.6,
                lng:  -58.4,
            }));
        });
    });
});
