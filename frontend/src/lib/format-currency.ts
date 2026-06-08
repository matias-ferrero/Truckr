/**
 * Memoised currency formatter. The `Intl.NumberFormat` constructor is
 * expensive — memoising by `${locale}::${currency}` avoids re-creating the
 * formatter on every render in list views (payouts table, shipment rows, etc.)
 */

const formatterCache = new Map<string, Intl.NumberFormat>();

function getFormatter(locale: string, currency: string): Intl.NumberFormat {
    const key = `${locale}::${currency}`;
    let fmt = formatterCache.get(key);
    if (!fmt) {
        fmt = new Intl.NumberFormat(locale, {
            style: "currency",
            currency,
            minimumFractionDigits: 0,
            maximumFractionDigits: 0,
        });
        formatterCache.set(key, fmt);
    }
    return fmt;
}

/**
 * Format an amount in cents as a localised currency string.
 *
 * @param cents    Integer amount in the minor unit (e.g. 1_250_000 = ARS 12.500)
 * @param currency ISO 4217 currency code (e.g. "ARS", "USD")
 * @param locale   BCP 47 locale string, defaults to "es-AR"
 */
export function formatCurrency(
    cents: number,
    currency: string,
    locale = "es-AR",
): string {
    return getFormatter(locale, currency).format(cents / 100);
}
