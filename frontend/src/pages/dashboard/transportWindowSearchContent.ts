/**
 * Content bundle for the dashboard's transport-window search section.
 * Mirrors the prototype-stage i18n pattern of `carrierSearchContent.ts` and
 * `landingContent.ts` — Spanish copy lives here, JSX consumes keys.
 */
export const transportWindowSearchContent = {
    section: {
        eyebrow: "Buscar transportistas",
        title: "Encontrá un transportista",
        lead: "Filtrá por zonas de retiro/entrega y rango de fechas. Mostramos ventanas activas que se solapan con tus fechas.",
    },
    form: {
        legend: "Criterios de búsqueda de transportistas",
        origin: "Origen",
        originPlaceholder: "Ej: CABA, Rosario, Mendoza",
        destination: "Destino",
        destinationPlaceholder: "Ej: Córdoba, Tucumán",
        dateFrom: "Retiro desde",
        dateTo: "Retiro hasta",
        submit: "Buscar",
        submitBusy: "Buscando…",
        rangeError: "La fecha hasta debe ser igual o posterior a la fecha desde.",
    },
    states: {
        idleTitle: "Empezá completando los filtros",
        idleText: "Usamos coincidencia flexible por zona y ventanas activas dentro del rango.",
        loadingLabel: "Cargando transportistas",
        errorTitle: "No pudimos completar la búsqueda",
        retry: "Reintentar",
        emptyTitle: "No encontramos resultados",
        emptyText: "Probá ampliar el rango de fechas o usar otra combinación de zonas.",
    },
    results: {
        countLabel: (n: number) => `${n} resultado${n === 1 ? "" : "s"}`,
        regionLabel: "Resultados de búsqueda",
        cardEyebrow: "Ventana activa",
        rating: "Rating",
        shipments: "viajes",
        priceUnit: "/ km",
        details: "Ver detalle",
        viewAll: "Ver todos los resultados",
        nameFallback: "Transportista sin nombre",
        baseSeparator: ", ",
    },
} as const;
