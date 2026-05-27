/* Prototype-stage i18n bundle for dashboard sections. Follows the same
   carve-out pattern as offerContent.ts (CLAUDE.md §Language policy). */

export const dashboardContent = {
    hero: {
        greeting: (firstName: string) => `Hola, ${firstName}`,
        eyebrow: {
            carrier: "Panel · Transportista",
            shipper:  "Panel · Expedidor",
        },
        lead: {
            carrier: "Acá vas a ver tus envíos, tu disponibilidad y los vehículos que tenés cargados.",
            shipper:  "Acá vas a ver tus envíos y solicitudes de cotización.",
        },
    },
    trips: {
        heading:    "Mis envíos",
        viewAll:    "Ver mis envíos",
        emptyTitle: "Todavía no tenés envíos",
        emptyHint:  "Cuando se confirme tu primer envío vas a verlo acá.",
    },
    carrier: {
        availability: {
            heading:        "Mi disponibilidad",
            viewAll:        "Ver todas",
            emptyTitle:     "Todavía no publicaste disponibilidad",
            emptyHint:      "Sumá ventanas para que los expedidores te encuentren.",
            newLabel:       "Nueva disponibilidad",
            statusActive:   "Publicada",
            statusInactive: "Sin publicar",
        },
        fleet: {
            heading:    "Mi flota",
            viewAll:    "Ver todos",
            emptyTitle: "Aún no cargaste un vehículo",
            emptyHint:  "Agregá tu primer vehículo para poder publicar viajes.",
            addLabel:   "Agregar vehículo",
            plateLabel: "Patente",
        },
    },
    shipper: {
        offers: {
            heading:      "Mis ofertas",
            emptyTitle:   "Todavía no enviaste ofertas",
            emptyHint:    "Buscá un transportista y enviá tu primera oferta de carga.",
            fallbackCard: (id: number) => `Oferta #${id}`,
        },
    },
} as const;

export const CARGO_OFFER_STATUS_LABEL: Record<string, string> = {
    pending:   "Pendiente",
    accepted:  "Aceptada",
    paid:      "Pagada",
    rejected:  "Rechazada",
    expired:   "Vencida",
    cancelled: "Cancelada",
};

/** Maps cargo offer status values to the CSS modifier class on `.statusBadge`. */
export const CARGO_OFFER_STATUS_BADGE_CLASS: Record<string, string> = {
    pending:   "pendiente",
    accepted:  "aceptado",
    paid:      "pagado",
    rejected:  "pasado",
    expired:   "pasado",
    cancelled: "pasado",
};
