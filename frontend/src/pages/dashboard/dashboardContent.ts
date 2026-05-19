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
            carrier: "Acá vas a ver tus viajes, tu disponibilidad y los vehículos que tenés cargados.",
            shipper:  "Acá vas a ver tus viajes y solicitudes de cotización.",
        },
    },
    trips: {
        heading:    "Mis viajes",
        emptyTitle: "Todavía no tenés viajes",
        emptyHint:  "Cuando se confirme tu primer viaje vas a verlo acá.",
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

export const QUOTE_STATUS_LABEL: Record<string, string> = {
    pending:   "Pendiente",
    accepted:  "Aceptada",
    paid:      "Pagada",
    expired:   "Vencida",
    cancelled: "Cancelada",
};

/** Maps quote status values to the CSS modifier class on `.statusBadge`. */
export const QUOTE_STATUS_BADGE_CLASS: Record<string, string> = {
    pending:   "pendiente",
    accepted:  "aceptado",
    paid:      "pagado",
    expired:   "pasado",
    cancelled: "pasado",
};
