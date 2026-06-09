/* Tiny pure formatting helpers for the Shipper Dashboard.
 * Kept free of React / I/O so a sibling engineer can unit-test them directly.
 */

const arsFormatter = new Intl.NumberFormat("es-AR", {
    style: "currency",
    currency: "ARS",
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
});

/** Format integer cents as ARS with no decimals, es-AR grouping. */
export function formatArs(cents: number): string {
    return arsFormatter.format(Math.round(cents) / 100);
}

const MINUTE = 60_000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;
const WEEK = 7 * DAY;

/**
 * Coarse, human relative time in es-AR: "ahora", "hace 2 min", "hace 3 h",
 * "hace 5 d", "hace 2 sem". `now` is injectable for deterministic tests.
 */
export function relativeTime(iso: string, now: number = Date.now()): string {
    const then = new Date(iso).getTime();
    if (Number.isNaN(then)) return "";
    const diff = now - then;
    if (diff < MINUTE) return "ahora";
    if (diff < HOUR) return `hace ${Math.floor(diff / MINUTE)} min`;
    if (diff < DAY) return `hace ${Math.floor(diff / HOUR)} h`;
    if (diff < WEEK) return `hace ${Math.floor(diff / DAY)} d`;
    return `hace ${Math.floor(diff / WEEK)} sem`;
}
