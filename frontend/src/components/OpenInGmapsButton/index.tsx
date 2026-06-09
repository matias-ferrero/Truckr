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

type Coords = { lat: number; lng: number };

/**
 * Build the Google Maps directions deep-link with both origin and destination.
 * Coordinates are rounded to 6 decimals to mirror the DB's `DECIMAL(9,6)`
 * precision (AC8).
 */
export function buildGmapsUrl(origin: Coords, destination: Coords): string {
    const fmt = (n: number) => Number(n.toFixed(6));
    return (
        `https://www.google.com/maps/dir/?api=1` +
        `&origin=${fmt(origin.lat)},${fmt(origin.lng)}` +
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
    origin: Coords;
    destination: Coords;
    /** Visible, already-localised label. */
    label: string;
    /** Optional richer screen-reader label; falls back to `label`. */
    ariaLabel?: string;
}

export function OpenInGmapsButton({ origin, destination, label, ariaLabel }: OpenInGmapsButtonProps) {
    return (
        <a
            href={buildGmapsUrl(origin, destination)}
            target="_blank"
            rel="noopener noreferrer"
            aria-label={ariaLabel ?? label}
            // Default size keeps the tap target at ≥44px (min-h-11) for mobile a11y.
            className={buttonVariants({ variant: "outline" })}
        >
            <GmapsPinIcon />
            {label}
        </a>
    );
}

export default OpenInGmapsButton;
