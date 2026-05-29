/* Geographic helpers — pure functions, no external dependencies.
 *
 * Mirrors `backend/lib/truckr/geo.rb`. SQLite-forever means the server already
 * runs Haversine in Ruby for filtering + ordering; the client runs the same
 * formula for the *displayed* distance against the cargo pickup point so the
 * Shipper can scan match cards by proximity (`MatchCard.tsx`). Keeping the
 * formula in two languages is fine — there is no third place this would live.
 */

const EARTH_RADIUS_KM = 6371.0;

const toRad = (deg: number) => (deg * Math.PI) / 180;

export type LatLng = { lat: number; lng: number };

/**
 * Great-circle distance in kilometres between two decimal-degree points
 * using the Haversine formula.
 */
export function haversineKm(a: LatLng, b: LatLng): number {
    const dLat = toRad(b.lat - a.lat);
    const dLng = toRad(b.lng - a.lng);
    const sinLat = Math.sin(dLat / 2);
    const sinLng = Math.sin(dLng / 2);
    const h = sinLat * sinLat +
        Math.cos(toRad(a.lat)) * Math.cos(toRad(b.lat)) * sinLng * sinLng;
    return EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
}
