/* Prototype-stage content bundle (es-AR) for the Shipper Dashboard v2.
 * Mirrors the `shipperShipmentsContent` pattern: ALL Spanish copy lives here,
 * never as inline JSX literals (language policy). Functions allowed for
 * count-driven strings.
 */

import type { BoardBadge, ColumnKey } from "./buildDashboardModel";
import type { ActivityItem } from "./buildActivityFeed";

export const shipperDashboardContent = {
    loadingLabel: "Cargando tu panel",
    loadError: "No pudimos cargar tu panel",
    retry: "Reintentar",

    greeting: (name: string) => `Hola, ${name} 👋`,
    greetingFallback: "Hola 👋",
    greetingLead: "Este es el estado de tus cargas hoy.",
    publishCta: "Publicar carga",

    attention: {
        regionLabel: "Atención requerida",
        title: "Atención requerida",
        allClearTitle: "Todo al día",
        allClearLead: "No hay nada pendiente por ahora. Buen momento para publicar una nueva carga.",
        toPay: {
            label: "Envíos por pagar",
            hint: "Asegurá tu pago en garantía para que el transporte arranque.",
            action: "Pagar ahora",
            count: (n: number) => (n === 1 ? "1 envío" : `${n} envíos`),
        },
        withoutOffers: {
            label: "Cargas sin ofertas",
            hint: "Revisá los datos o ampliá la ventana para atraer transportistas.",
            action: "Ver cargas",
            count: (n: number) => (n === 1 ? "1 carga" : `${n} cargas`),
        },
        toReview: {
            label: "Transportistas por calificar",
            hint: "Tu calificación ayuda a otros expedidores a elegir bien.",
            action: "Calificar",
            count: (n: number) => (n === 1 ? "1 entrega" : `${n} entregas`),
        },
    },

    board: {
        regionLabel: "Mis cargas",
        title: "Mis cargas",
        columnEmpty: "Sin cargas aquí",
        columnNames: {
            searching: "Buscando transporte",
            withOffers: "Con ofertas",
            acceptedOffers: "Ofertas aceptadas",
            inTransit: "En tránsito",
            delivered: "Entregadas",
        } satisfies Record<ColumnKey, string>,
        /** Accessible name for a column, e.g. "Con ofertas, 3 cargas". */
        columnAccessibleName: (name: string, count: number) =>
            `${name}, ${count === 1 ? "1 carga" : `${count} cargas`}`,
        /** Accessible name for a card link: route + status. */
        cardAccessibleName: (origin: string, destination: string, status: string) =>
            `Carga de ${origin} a ${destination}. Estado: ${status}.`,
        noStatus: "Sin estado",
        priceLabel: "Precio",
    },

    badges: {
        no_offers: "Sin ofertas",
        has_offers: (n: number) => (n === 1 ? "1 oferta" : `${n} ofertas`),
        payment_pending: "Pago pendiente",
        in_transit: "En camino",
        delivered: "Entregado",
        to_review: "Calificar",
    },

    feed: {
        regionLabel: "Actividad reciente",
        title: "Actividad reciente",
        empty: "Sin actividad reciente",
        descriptions: {
            offer_received: "Nueva oferta recibida",
            shipment_accepted: "Aceptaste una oferta",
            shipment_in_transit: "Tu envío salió en camino",
            shipment_delivered: "Envío entregado",
            payment_escrowed: "Pago retenido en garantía",
            payment_failed: "Falló el pago",
            status_change: "Cambio de estado del envío",
            note: "Nueva nota en el envío",
            gps_update: "Ubicación del envío actualizada",
        } satisfies Record<ActivityItem["type"], string>,
        pager: {
            navLabel: "Paginación de actividad",
            prev: "Anterior",
            next: "Siguiente",
            /** Visible range, e.g. "1–6 de 23". */
            range: (from: number, to: number, total: number) => `${from}–${to} de ${total}`,
        },
    },

    onboarding: {
        title: "Publicá tu primera carga",
        lead:
            "Contanos qué necesitás transportar y recibí ofertas de transportistas verificados en minutos.",
    },
} as const;

/** Resolve a board badge to its Spanish label (text always present a11y-wise). */
export function badgeLabel(badge: BoardBadge, offersCount: number): string | null {
    if (badge === null) return null;
    if (badge === "has_offers") return shipperDashboardContent.badges.has_offers(offersCount);
    return shipperDashboardContent.badges[badge];
}
