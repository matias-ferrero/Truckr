import { buttonVariants } from "../ui/button";

// <OpenInGmapsButton /> — US51 / REQ-FE-00028.
//
// A deep-link to Google Maps rendered as a design-system button. The URL is a
// static, parameterised string (no API key, no JS API) so it keeps working even
// when <ShipmentMap /> degrades to its service-unavailable state (AC9).
//
// Mobile: the canonical `https://www.google.com/maps/...` URL is opened by the
// native Google Maps app on Android/iOS when installed, otherwise the browser —
// more portable than `comgooglemaps://` UA sniffing (decision closed in triage).
//
// Shipment-detail v2 (§4): `origin` is optional. Without it the deep-link is a
// destination-only `dir` URL, which Google Maps resolves as "navigate from my
// current location" — the carrier's navigate-to-pickup / navigate-to-delivery
// actions. `variant` lets the state-aware emphasis promote one link to primary.

type Coords = { lat: number; lng: number };

/**
 * Build the Google Maps directions deep-link. With `origin`, a full
 * origin→destination route; without it, destination-only (navigation starts at
 * the device's current location). Coordinates are rounded to 6 decimals to
 * mirror the DB's `DECIMAL(9,6)` precision (AC8).
 */
export function buildGmapsUrl(origin: Coords | null | undefined, destination: Coords): string {
    const fmt = (n: number) => Number(n.toFixed(6));
    const originPart = origin ? `&origin=${fmt(origin.lat)},${fmt(origin.lng)}` : "";
    return (
        `https://www.google.com/maps/dir/?api=1` +
        originPart +
        `&destination=${fmt(destination.lat)},${fmt(destination.lng)}`
    );
}

function GmapsPinIcon() {
    return (
        <svg viewBox="0 0 16 16" fill="none" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
            <path d="M13 6.5c0 3.5-5 8-5 8s-5-4.5-5-8a5 5 0 0 1 10 0z" />
            <circle cx="8" cy="6.5" r="1.75" />
        </svg>
    );
}

export interface OpenInGmapsButtonProps {
    /** Route start. Omit for destination-only navigation from current location. */
    origin?: Coords | null;
    destination: Coords;
    /** Visible, already-localised label. */
    label: string;
    /** Optional richer screen-reader label; falls back to `label`. */
    ariaLabel?: string;
    /** Visual emphasis — `primary` for the state-promoted nav action. */
    variant?: "primary" | "outline";
}

export function OpenInGmapsButton({ origin, destination, label, ariaLabel, variant = "outline" }: OpenInGmapsButtonProps) {
    return (
        <a
            href={buildGmapsUrl(origin, destination)}
            target="_blank"
            rel="noopener noreferrer"
            aria-label={ariaLabel ?? label}
            // Default size keeps the tap target at ≥44px (min-h-11) for mobile a11y.
            className={buttonVariants({ variant })}
        >
            <GmapsPinIcon />
            {label}
        </a>
    );
}

export default OpenInGmapsButton;
