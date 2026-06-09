/**
 * Formats a driving distance following Google Maps display conventions:
 * - < 1 km   → meters, e.g. "500 m"
 * - 1–99 km  → 1 decimal, e.g. "12.3 km"
 * - ≥ 100 km → whole number, e.g. "712 km"
 */
export function formatDistance(km: number): string {
    if (km < 1) return `${Math.round(km * 1000)} m`;
    if (km < 100) return `${km.toFixed(1)} km`;
    return `${Math.round(km)} km`;
}
