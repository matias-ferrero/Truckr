import { useEffect, useId, useRef, useState } from "react";
import { getGoogleMapsLoader } from "../../lib/gmaps";
import { parsePlace, type PlaceAddressComponent } from "../../lib/places";
import { Input } from "../ui/input";
import { addressPickerContent } from "./addressPickerContent";

export interface AddressPickerValue {
    text: string;
    lat: number;
    lng: number;
    // REQ-BE-00039 / ADR-014: locality + admin_area parsed from the place's
    // addressComponents via the shared `parsePlace` cascade. Optional because
    // upstream callers from the US48 era may still pass a value without them.
    locality?: string;
    admin_area?: string;
}

export interface AddressPickerProps {
    id?: string;
    name?: string;
    value: AddressPickerValue | null;
    onChange: (next: AddressPickerValue | null) => void;
    error?: string;
    disabled?: boolean;
    required?: boolean;
    placeholder?: string;
    "aria-label"?: string;
    "aria-labelledby"?: string;
}

type LoadState = "loading" | "ready" | "error";

type PlacesLib = {
    AutocompleteSuggestion:   typeof google.maps.places.AutocompleteSuggestion;
    AutocompleteSessionToken: typeof google.maps.places.AutocompleteSessionToken;
};

function truncate6(n: number): number {
    return Number(n.toFixed(6));
}

// Debounce window for keystrokes → fetchAutocompleteSuggestions. Short enough
// that typing feels live, long enough to avoid one request per character.
const DEBOUNCE_MS = 200;

// Region restriction. CLDR two-letter codes. AR = Argentina (US48 AC).
const INCLUDED_REGION_CODES = ["ar"];

export function AddressPicker({
    id,
    name,
    value,
    onChange,
    error,
    disabled,
    required,
    placeholder,
    "aria-label": ariaLabel,
    "aria-labelledby": ariaLabelledBy,
}: AddressPickerProps) {
    const autoId = useId();
    const inputId = id ?? autoId;
    const listboxId = `${inputId}-listbox`;
    const errorId = `${inputId}-error`;
    const apiKey = (import.meta.env.VITE_GOOGLE_MAPS_API_KEY as string | undefined) ?? "";

    const [loadState, setLoadState] = useState<LoadState>(apiKey ? "loading" : "error");
    const libRef = useRef<PlacesLib | null>(null);
    const sessionTokenRef = useRef<google.maps.places.AutocompleteSessionToken | null>(null);

    const [text, setText] = useState<string>(value?.text ?? "");
    const [touched, setTouched] = useState(false);
    const [suggestions, setSuggestions] = useState<google.maps.places.AutocompleteSuggestion[]>([]);
    const [activeIndex, setActiveIndex] = useState(-1);
    const [open, setOpen] = useState(false);

    const containerRef = useRef<HTMLDivElement | null>(null);
    const seqRef = useRef(0);

    useEffect(() => {
        if (!apiKey) return;
        let cancelled = false;
        const loader = getGoogleMapsLoader(apiKey);
        loader
            .load()
            .then(async () => {
                const lib = (await google.maps.importLibrary("places")) as unknown as PlacesLib;
                if (cancelled) return;
                libRef.current = lib;
                sessionTokenRef.current = new lib.AutocompleteSessionToken();
                setLoadState("ready");
            })
            .catch(() => {
                if (!cancelled) setLoadState("error");
            });
        return () => {
            cancelled = true;
        };
    }, [apiKey]);

    // Keep internal text in sync when the parent swaps `value` (edit-mode hydration).
    useEffect(() => {
        setText(value?.text ?? "");
    }, [value?.text]);

    const serviceUnavailable = loadState === "error";
    const isConfirmed = value !== null;
    const isUnconfirmed = !isConfirmed && touched && text.trim().length > 0;
    const internalError = isUnconfirmed ? addressPickerContent.error.unconfirmed : undefined;
    const visibleError = error ?? internalError ?? (serviceUnavailable ? addressPickerContent.error.serviceUnavailable : undefined);

    // Fetch suggestions when the user types. Skipped while the value is confirmed
    // (the input mirrors the confirmed text — no need to re-query until edited).
    useEffect(() => {
        if (loadState !== "ready" || !libRef.current) return;
        if (isConfirmed || text.trim().length === 0) {
            setSuggestions([]);
            setOpen(false);
            return;
        }
        const mySeq = ++seqRef.current;
        const handle = setTimeout(async () => {
            try {
                const { suggestions: sugs } = await libRef
                    .current!.AutocompleteSuggestion.fetchAutocompleteSuggestions({
                        input:               text,
                        includedRegionCodes: INCLUDED_REGION_CODES,
                        sessionToken:        sessionTokenRef.current ?? undefined,
                    });
                if (mySeq !== seqRef.current) return;
                setSuggestions(sugs);
                setActiveIndex(-1);
                setOpen(sugs.length > 0);
            } catch {
                if (mySeq === seqRef.current) {
                    setSuggestions([]);
                    setOpen(false);
                }
            }
        }, DEBOUNCE_MS);
        return () => clearTimeout(handle);
    }, [text, loadState, isConfirmed]);

    async function selectSuggestion(sug: google.maps.places.AutocompleteSuggestion) {
        const pred = sug.placePrediction;
        if (!pred) return;
        try {
            const place = pred.toPlace();
            await place.fetchFields({ fields: ["formattedAddress", "location", "addressComponents"] });
            const loc = place.location ?? null;
            if (!loc) {
                onChange(null);
                setTouched(true);
                return;
            }
            const components = (place.addressComponents ?? null) as
                | ReadonlyArray<PlaceAddressComponent>
                | null;
            const parsed = parsePlace({
                formattedAddress:  place.formattedAddress ?? pred.text.text,
                location:          loc,
                addressComponents: components,
            });
            const next: AddressPickerValue = {
                text:       parsed.address || pred.text.text,
                lat:        truncate6(loc.lat()),
                lng:        truncate6(loc.lng()),
                locality:   parsed.locality,
                admin_area: parsed.admin_area,
            };
            setText(next.text);
            setSuggestions([]);
            setOpen(false);
            // A confirmed selection ends the billing session — rotate the token.
            if (libRef.current) {
                sessionTokenRef.current = new libRef.current.AutocompleteSessionToken();
            }
            onChange(next);
        } catch {
            onChange(null);
            setTouched(true);
        }
    }

    function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
        const next = e.target.value;
        setText(next);
        // Editing after a confirmed selection invalidates it — the parent must
        // wait for a new confirmation before treating the field as valid.
        if (isConfirmed) onChange(null);
    }

    function handleBlur() {
        // Defer so an in-flight mousedown on a suggestion is honored before
        // we close the listbox / mark the field touched.
        setTimeout(() => {
            const root = containerRef.current;
            if (root && document.activeElement && root.contains(document.activeElement)) {
                return;
            }
            setTouched(true);
            setOpen(false);
        }, 150);
    }

    function handleKeyDown(e: React.KeyboardEvent<HTMLInputElement>) {
        if (e.key === "Escape") {
            setOpen(false);
            return;
        }
        if (!open || suggestions.length === 0) return;
        if (e.key === "ArrowDown") {
            e.preventDefault();
            setActiveIndex((i) => Math.min(suggestions.length - 1, i + 1));
        } else if (e.key === "ArrowUp") {
            e.preventDefault();
            setActiveIndex((i) => Math.max(0, i - 1));
        } else if (e.key === "Enter" && activeIndex >= 0) {
            e.preventDefault();
            void selectSuggestion(suggestions[activeIndex]);
        }
    }

    if (serviceUnavailable) {
        return (
            <div data-state="service_unavailable">
                <Input
                    id={inputId}
                    name={name}
                    type="text"
                    value={text}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    disabled
                    placeholder={placeholder ?? addressPickerContent.placeholder}
                    aria-label={ariaLabel}
                    aria-labelledby={ariaLabelledBy}
                    aria-invalid="true"
                    aria-describedby={errorId}
                    aria-required={required ? "true" : undefined}
                />
                <p id={errorId} role="alert" className="text-xs font-semibold text-[color-mix(in_oklab,var(--color-brand-error)_50%,var(--color-ink))] mt-2">
                    {visibleError ?? addressPickerContent.error.serviceUnavailable}
                </p>
            </div>
        );
    }

    if (loadState === "loading") {
        return (
            <div data-state="loading">
                <Input
                    id={inputId}
                    name={name}
                    type="text"
                    value={text}
                    onChange={handleChange}
                    onBlur={handleBlur}
                    disabled
                    placeholder={addressPickerContent.statusLoading}
                    aria-label={ariaLabel}
                    aria-labelledby={ariaLabelledBy}
                    aria-required={required ? "true" : undefined}
                    aria-busy="true"
                />
            </div>
        );
    }

    const state = isConfirmed
        ? "confirmed"
        : isUnconfirmed
        ? "unconfirmed"
        : text.length > 0
        ? "suggesting"
        : "idle";
    const listboxOpen = open && suggestions.length > 0 && !disabled;

    return (
        <div data-state={state} ref={containerRef} className="relative">
            <Input
                id={inputId}
                name={name}
                type="text"
                role="combobox"
                aria-autocomplete="list"
                aria-controls={listboxId}
                aria-expanded={listboxOpen}
                aria-activedescendant={
                    listboxOpen && activeIndex >= 0 ? `${inputId}-option-${activeIndex}` : undefined
                }
                value={text}
                onChange={handleChange}
                onBlur={handleBlur}
                onKeyDown={handleKeyDown}
                disabled={disabled}
                placeholder={placeholder ?? addressPickerContent.placeholder}
                aria-label={ariaLabel}
                aria-labelledby={ariaLabelledBy}
                aria-invalid={visibleError ? "true" : undefined}
                aria-describedby={visibleError ? errorId : undefined}
                aria-required={required ? "true" : undefined}
                autoComplete="off"
            />
            {listboxOpen && (
                <ul
                    id={listboxId}
                    role="listbox"
                    className="absolute z-10 mt-1 max-h-64 w-full overflow-auto rounded-sm border border-stroke bg-paper shadow-lg"
                >
                    {suggestions.map((sug, idx) => {
                        const pred = sug.placePrediction;
                        if (!pred) return null;
                        const mainText = pred.mainText?.text ?? pred.text.text;
                        const secondaryText = pred.secondaryText?.text;
                        const active = idx === activeIndex;
                        return (
                            <li
                                id={`${inputId}-option-${idx}`}
                                key={pred.placeId}
                                role="option"
                                aria-selected={active}
                                className={
                                    "cursor-pointer px-3.5 py-2 text-sm text-ink " +
                                    (active
                                        ? "bg-[color-mix(in_oklab,var(--color-brand)_15%,var(--color-paper))]"
                                        : "hover:bg-[color-mix(in_oklab,var(--color-brand)_8%,var(--color-paper))]")
                                }
                                onMouseDown={(e) => {
                                    // Keep focus on the input so blur doesn't close the listbox before click fires.
                                    e.preventDefault();
                                }}
                                onClick={() => void selectSuggestion(sug)}
                            >
                                <span className="block font-medium">{mainText}</span>
                                {secondaryText && (
                                    <span className="block text-xs text-ink-faint">{secondaryText}</span>
                                )}
                            </li>
                        );
                    })}
                </ul>
            )}
            {visibleError && (
                <p id={errorId} role="alert" className="text-xs font-semibold text-[color-mix(in_oklab,var(--color-brand-error)_50%,var(--color-ink))] mt-2">
                    {visibleError}
                </p>
            )}
        </div>
    );
}

export default AddressPicker;
