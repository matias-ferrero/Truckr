/* Pure formatting helpers for the Carrier Dashboard. `formatArs` and
 * `relativeTime` (past tense, "hace 2 h") are shared with the Shipper
 * dashboard; `timeUntil` is carrier-specific — offers expire in the future.
 */

export { formatArs, relativeTime } from "../../shipper/dashboard/format";

const MINUTE = 60_000;
const HOUR = 60 * MINUTE;
const DAY = 24 * HOUR;

/**
 * Coarse, human future distance in es-AR: "ahora", "en 45 min", "en 5 h",
 * "en 2 d". A past timestamp also returns "ahora" — a pending offer past its
 * expiry is about to be swept by the expiration job. `now` is injectable for
 * deterministic tests.
 */
export function timeUntil(iso: string, now: number = Date.now()): string {
    const then = new Date(iso).getTime();
    if (Number.isNaN(then)) return "";
    const diff = then - now;
    if (diff < MINUTE) return "ahora";
    if (diff < HOUR) return `en ${Math.floor(diff / MINUTE)} min`;
    if (diff < DAY) return `en ${Math.floor(diff / HOUR)} h`;
    return `en ${Math.floor(diff / DAY)} d`;
}

const quantityFormatter = new Intl.NumberFormat("es-AR", {
    maximumFractionDigits: 1,
});

/**
 * Format a decimal wire string ("3000.0") as a human es-AR quantity
 * ("3.000"). Unparseable input is returned verbatim.
 */
export function formatQuantity(value: string): string {
    const parsed = Number(value);
    if (Number.isNaN(parsed)) return value;
    return quantityFormatter.format(parsed);
}
