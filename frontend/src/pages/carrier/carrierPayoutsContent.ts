export const carrierPayoutsContent = {
    title: "Mis Pagos",
    empty: "Todavía no recibiste pagos. Aparecerán aquí cuando entregues un envío.",
    error: "No pudimos cargar tus pagos. Intentá de nuevo.",
    tableCaption: "Historial de pagos acreditados",
    table: {
        route: "Ruta",
        shipper: "Expedidor",
        gross: "Bruto",
        commission: "Comisión",
        net: "Neto acreditado",
        state: "Estado",
        date: "Fecha",
        actionsHeader: "Acciones",
        link: "Ver envío",
        linkAria: (origin: string, destination: string) => `Ver envío ${origin} → ${destination}`,
    },
    states: {
        paid: "Pagado",
        failed: "Fallido",
    },
} as const;
