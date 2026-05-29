// REQ-BE-00039 / ADR-014: address-driven label helpers.
//
// Every TransportWindow + Cargo now carries `*_locality` and `*_admin_area`
// (parsed at AddressPicker time via `parsePlace`). Wherever a route label is
// rendered — match cards, cargo lists, window lists, carrier profile, dashboard
// — these helpers produce the canonical "Locality, AdminArea" string and the
// arrow-joined route, so we don't repeat the formatting logic at every call
// site.
//
// The "open destination" copy is injected by the caller (its i18n key lives
// in the relevant `*Content.ts` bundle, e.g.
// `cargosContent.list.openDestinationLabel`) — the helper never owns user copy.

export interface Place {
    locality: string | null | undefined;
    admin_area: string | null | undefined;
}

export function formatPlace(place: Place | null | undefined): string {
    if (!place) return "";
    const loc = (place.locality ?? "").trim();
    const adm = (place.admin_area ?? "").trim();
    if (loc && adm) return `${loc}, ${adm}`;
    return loc || adm;
}

export function formatRoute(
    origin: Place,
    destination: Place | null | undefined,
    openDestinationLabel: string,
): string {
    const originStr = formatPlace(origin);
    const destStr = destination && (destination.locality || destination.admin_area)
        ? formatPlace(destination)
        : openDestinationLabel;
    return `${originStr} → ${destStr}`;
}
