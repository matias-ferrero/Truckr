/** Presentation formatters for the Cargo Matches v2 screen. */

const arsFormatter = new Intl.NumberFormat("es-AR", {
    style: "currency",
    currency: "ARS",
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
});

/** Whole-peso total, e.g. `$ 4.180`. */
export function formatTotalArs(amount: number): string {
    return arsFormatter.format(amount);
}

/** Compact es-AR date, e.g. `05/06/26`. */
export function formatShortDate(iso: string): string {
    return new Date(iso).toLocaleDateString("es-AR", {
        day: "2-digit",
        month: "2-digit",
        year: "2-digit",
    });
}

/** Whole-peso per-km rate, e.g. `$1.240/km`. */
export function formatPerKm(raw: string): string {
    const n = Number(raw);
    return `$${n.toLocaleString("es-AR", { maximumFractionDigits: 0 })}/km`;
}

/** Decimal-string kilograms without the trailing `.0`, e.g. `3.000 kg`. */
export function formatKg(raw: string): string {
    return `${Number(raw).toLocaleString("es-AR", { maximumFractionDigits: 0 })} kg`;
}

/** One-decimal rating, es-AR comma, e.g. `4,7`. */
export function formatRating(avg: number): string {
    return avg.toLocaleString("es-AR", {
        minimumFractionDigits: 1,
        maximumFractionDigits: 1,
    });
}
