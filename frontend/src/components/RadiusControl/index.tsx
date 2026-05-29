import { useEffect, useId, useRef, useState } from "react";
import { getGoogleMapsLoader } from "../../lib/gmaps";
import { Input } from "../ui/input";
import { radiusContent, type RadiusRole } from "./radiusContent";

export interface RadiusPin {
    lat: number;
    lng: number;
}

export interface RadiusControlProps {
    id?: string;
    name?: string;
    /** "pickup" centres on the origin pin, "dropoff" centres on the destination pin. */
    role?: RadiusRole;
    /** Coordinate the circle is anchored to. Null → input disabled, map torn down. */
    pin: RadiusPin | null;
    value: number;
    onChange: (next: number) => void;
    error?: string;
    disabled?: boolean;
    required?: boolean;
    label?: string;
    help?: string;
    placeholder?: string;
    placeholderWhenNoPin?: string;
    "aria-label"?: string;
    "aria-labelledby"?: string;
}

type LoadState = "loading" | "ready" | "error";

export const RADIUS_MIN_KM = 1;
export const RADIUS_MAX_KM = 200;
export const RADIUS_DEFAULT_KM = 10;

// Circle stroke per role — pickup uses the brand teal, dropoff a warmer coral
// so the two circles read as distinct when both are on screen.
const STROKE_COLOR: Record<RadiusRole, string> = {
    pickup:  "#4ECDC4",
    dropoff: "#FF6B6B",
};

function clampInteger(n: number, min: number, max: number): number {
    if (!Number.isFinite(n)) return min;
    return Math.min(max, Math.max(min, Math.round(n)));
}

export function RadiusControl({
    id,
    name,
    role = "pickup",
    pin,
    value,
    onChange,
    error,
    disabled,
    required,
    label,
    help,
    placeholder,
    placeholderWhenNoPin,
    "aria-label": ariaLabel,
    "aria-labelledby": ariaLabelledBy,
}: RadiusControlProps) {
    const autoId = useId();
    const inputId = id ?? autoId;
    const errorId = `${inputId}-error`;
    const helpId = `${inputId}-help`;
    const mapId = `${inputId}-map`;
    const apiKey = (import.meta.env.VITE_GOOGLE_MAPS_API_KEY as string | undefined) ?? "";
    const roleCopy = radiusContent[role];

    const [loadState, setLoadState] = useState<LoadState>(apiKey ? "loading" : "error");

    const mapContainerRef = useRef<HTMLDivElement | null>(null);
    const mapRef = useRef<google.maps.Map | null>(null);
    const circleRef = useRef<google.maps.Circle | null>(null);
    // True while we're propagating an input change down to the circle. Stops the
    // circle's `radius_changed` listener from echoing back through `onChange`,
    // which would create an update loop (input → circle → input → …).
    const isApplyingInputRef = useRef(false);
    // Latest onChange + value pinned via ref so the persistent listeners attached
    // once on mount always see the freshest props without re-binding the map.
    const onChangeRef = useRef(onChange);
    const valueRef = useRef(value);

    useEffect(() => { onChangeRef.current = onChange; }, [onChange]);
    useEffect(() => { valueRef.current = value; }, [value]);

    useEffect(() => {
        if (!apiKey) return;
        let cancelled = false;
        const loader = getGoogleMapsLoader(apiKey);
        loader
            .load()
            .then(async () => {
                await google.maps.importLibrary("maps");
                if (cancelled) return;
                setLoadState("ready");
            })
            .catch(() => {
                if (!cancelled) setLoadState("error");
            });
        return () => { cancelled = true; };
    }, [apiKey]);

    // Build the map + circle once the API is ready AND a pin exists.
    // Tearing them down when pin clears avoids a stale map sitting under the
    // placeholder copy.
    useEffect(() => {
        if (loadState !== "ready" || !pin || !mapContainerRef.current) return;
        if (!mapRef.current) {
            mapRef.current = new google.maps.Map(mapContainerRef.current, {
                center:            pin,
                zoom:              11,
                disableDefaultUI:  true,
                gestureHandling:   "cooperative",
                clickableIcons:    false,
                keyboardShortcuts: false,
            });
        } else {
            mapRef.current.setCenter(pin);
        }

        if (!circleRef.current) {
            circleRef.current = new google.maps.Circle({
                map:          mapRef.current,
                center:       pin,
                radius:       valueRef.current * 1000,
                editable:     true,
                draggable:    false,
                fillOpacity:  0.15,
                strokeWeight: 2,
                strokeColor:  STROKE_COLOR[role],
                fillColor:    STROKE_COLOR[role],
                clickable:    false,
            });

            circleRef.current.addListener("radius_changed", () => {
                if (isApplyingInputRef.current) return;
                const meters = circleRef.current?.getRadius() ?? valueRef.current * 1000;
                const km = clampInteger(meters / 1000, RADIUS_MIN_KM, RADIUS_MAX_KM);
                if (km !== valueRef.current) {
                    onChangeRef.current(km);
                }
            });

            // Centre stays locked to the pin (US50 decision, extended in
            // REQ-BE-00039 to dropoff). If anything moves the centre, snap back.
            circleRef.current.addListener("center_changed", () => {
                const c = circleRef.current?.getCenter();
                if (!c) return;
                if (c.lat() !== pin.lat || c.lng() !== pin.lng) {
                    circleRef.current?.setCenter(pin);
                }
            });
        } else {
            circleRef.current.setCenter(pin);
        }

        // Fit roughly to the circle so the user sees the whole shape.
        const bounds = circleRef.current.getBounds();
        if (bounds) mapRef.current.fitBounds(bounds);
    }, [loadState, pin?.lat, pin?.lng, pin, role]);

    // External value updates (edit-mode hydration, parent reset) push to circle.
    useEffect(() => {
        if (!circleRef.current) return;
        const meters = value * 1000;
        if (circleRef.current.getRadius() === meters) return;
        isApplyingInputRef.current = true;
        circleRef.current.setRadius(meters);
        queueMicrotask(() => { isApplyingInputRef.current = false; });
    }, [value]);

    // Tear down map artefacts if the pin gets cleared. We re-create them
    // the next time the user picks a pin.
    useEffect(() => {
        if (pin) return;
        if (circleRef.current) {
            circleRef.current.setMap(null);
            circleRef.current = null;
        }
        mapRef.current = null;
    }, [pin]);

    function handleInputChange(e: React.ChangeEvent<HTMLInputElement>) {
        const raw = e.target.value;
        if (raw === "") {
            // Allow transient empty state while the user is editing — the form's
            // submit guard catches an actually-missing value.
            onChange(RADIUS_MIN_KM);
            return;
        }
        const km = clampInteger(Number(raw), RADIUS_MIN_KM, RADIUS_MAX_KM);
        if (circleRef.current) {
            isApplyingInputRef.current = true;
            circleRef.current.setRadius(km * 1000);
            queueMicrotask(() => { isApplyingInputRef.current = false; });
        }
        if (km !== value) onChange(km);
    }

    const resolvedLabel = label ?? roleCopy.label;
    const resolvedHelp = help ?? roleCopy.help;
    const resolvedPlaceholder = placeholder ?? roleCopy.placeholder;
    const resolvedNoPinCopy = placeholderWhenNoPin ?? roleCopy.placeholderWhenNoPin;
    const inputDisabled = disabled || !pin;
    const visibleError = error;

    return (
        <div className="radiusControl" data-state={pin ? "ready" : "idle"} data-role={role}>
            <label htmlFor={inputId} className="radiusLabel">
                {resolvedLabel}
                {required && <span aria-hidden="true" className="requiredStar"> *</span>}
            </label>
            <Input
                id={inputId}
                name={name}
                type="number"
                inputMode="numeric"
                min={RADIUS_MIN_KM}
                max={RADIUS_MAX_KM}
                step={1}
                value={value}
                onChange={handleInputChange}
                placeholder={resolvedPlaceholder}
                disabled={inputDisabled}
                required={required}
                aria-label={ariaLabel}
                aria-labelledby={ariaLabelledBy}
                aria-describedby={
                    [visibleError ? errorId : null, resolvedHelp ? helpId : null]
                        .filter(Boolean)
                        .join(" ") || undefined
                }
                aria-invalid={visibleError ? "true" : undefined}
                aria-required={required ? "true" : undefined}
            />
            {resolvedHelp && (
                <p id={helpId} className="radiusHelp">
                    {resolvedHelp}
                </p>
            )}
            {visibleError && (
                <p id={errorId} role="alert" className="radiusError">
                    {visibleError}
                </p>
            )}
            {!pin && (
                <p className="radiusPlaceholder" data-testid={`${role}-radius-placeholder`}>
                    {resolvedNoPinCopy}
                </p>
            )}
            {pin && loadState !== "error" && (
                <div
                    id={mapId}
                    ref={mapContainerRef}
                    className="radiusMap"
                    role="application"
                    aria-label={roleCopy.mapAriaLabel}
                    aria-busy={loadState === "loading" ? "true" : undefined}
                    data-testid={`${role}-radius-map`}
                />
            )}
        </div>
    );
}

export default RadiusControl;
