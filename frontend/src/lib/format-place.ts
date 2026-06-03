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

import { normalizeAdminArea } from "./places";

export interface Place {
    locality: string | null | undefined;
    admin_area: string | null | undefined;
}

export function formatPlace(place: Place | null | undefined): string {
    if (!place) return "";
    // Guard against data anomalies (string "null") and apply alias normalisation
    // so existing DB records with the full province name display the short form.
    const loc = (place.locality ?? "").replace(/^null$/i, "").trim();
    const adm = normalizeAdminArea((place.admin_area ?? "").replace(/^null$/i, "").trim());
    // Avoid "CABA, CABA" when locality and admin_area collapse to the same value
    // after normalisation (e.g. locality="CABA" + admin_area="Ciudad Autónoma…").
    if (loc && adm && loc !== adm) return `${loc}, ${adm}`;
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
