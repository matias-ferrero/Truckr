// Pure helper: parses a Google Places `Place` (new Places API) into the shape
// the address-driven matcher needs. The cascade for `locality` mirrors the
// fallback chain in REQ-BE-00039 (ADR-014, AC11): try the strict locality
// component first, then sublocality, then department-level admin area, and
// finally the first comma-separated chunk of the formatted address as a
// last resort. `admin_area` is always sourced from `administrative_area_level_1`
// (provincia in es-AR), with the same final-chunk fallback.
//
// Admin-area aliases: some provinces / autonomous cities have canonical short
// forms that are used everywhere in the UI. Map the verbose Google name to the
// short form here so it is normalised at parse time (new addresses) and at
// display time via `format-place.ts`.
const ADMIN_AREA_ALIASES: Readonly<Record<string, string>> = {
    "ciudad autónoma de buenos aires": "CABA",
    "ciudad autonoma de buenos aires": "CABA",
};

export function normalizeAdminArea(s: string): string {
    const key = s.toLowerCase().trim();
    return ADMIN_AREA_ALIASES[key] ?? s;
}

export interface PlaceAddressComponent {
    types: ReadonlyArray<string>;
    longText?: string | null;
    shortText?: string | null;
}

export interface PlaceLike {
    formattedAddress?: string | null;
    location?: { lat(): number; lng(): number } | null;
    addressComponents?: ReadonlyArray<PlaceAddressComponent> | null;
}

export interface ParsedPlace {
    address: string;
    lat: number;
    lng: number;
    locality: string;
    admin_area: string;
}

const LOCALITY_FALLBACK_TYPES: ReadonlyArray<string> = [
    "locality",
    "sublocality_level_1",
    "administrative_area_level_2",
];

function findComponent(
    components: ReadonlyArray<PlaceAddressComponent> | null | undefined,
    type: string,
): PlaceAddressComponent | undefined {
    if (!components) return undefined;
    return components.find((c) => c.types.includes(type));
}

function componentText(c: PlaceAddressComponent | undefined): string {
    if (!c) return "";
    return (c.longText ?? c.shortText ?? "").trim();
}

function firstCommaChunk(formatted: string | null | undefined): string {
    if (!formatted) return "";
    const head = formatted.split(",")[0] ?? "";
    return head.trim();
}

function truncate6(n: number): number {
    return Number(n.toFixed(6));
}

export function parsePlace(place: PlaceLike): ParsedPlace {
    const address = (place.formattedAddress ?? "").trim();
    const loc = place.location ?? null;
    const lat = loc ? truncate6(loc.lat()) : NaN;
    const lng = loc ? truncate6(loc.lng()) : NaN;

    let locality = "";
    for (const t of LOCALITY_FALLBACK_TYPES) {
        const text = componentText(findComponent(place.addressComponents, t));
        if (text) {
            locality = text;
            break;
        }
    }
    if (!locality) locality = firstCommaChunk(address);

    const adminFromComponent = componentText(
        findComponent(place.addressComponents, "administrative_area_level_1"),
    );
    const admin_area = normalizeAdminArea(adminFromComponent || firstCommaChunk(address));

    return { address, lat, lng, locality, admin_area };
}
