/* Prototype-stage i18n bundle for the persistent app Sidebar.
   Mirrors the pattern of landingContent.ts / offersAndShipmentsContent.ts:
   copy lives here as data, never hardcoded in JSX. Migrates to the real
   i18n library when it lands (see CLAUDE.md language policy). es-AR. */
export const sidebarContent = {
    label: "Navegación principal",
    carrier: {
        heading: "Transportista",
        items: {
            dashboard: "Inicio",
            vehicles: "Vehículos",
            availability: "Disponibilidad",
            offers: "Ofertas",
            shipments: "Mis Envíos",
            payouts: "Mis Pagos",
        },
    },
    shipper: {
        heading: "Expedidor",
        items: {
            dashboard: "Inicio",
            cargos: "Mis Cargas",
            shipments: "Mis Envíos",
        },
    },
} as const;
