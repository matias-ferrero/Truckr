/* Prototype-stage content bundle (es-AR) for the Carrier Dashboard v2.
 * Mirrors `shipperDashboardContent`: ALL Spanish copy lives here, never as
 * inline JSX literals (language policy). Functions allowed for count-driven
 * strings.
 */

import type { CarrierActivityItem } from "./buildCarrierActivityFeed";
import type { ColumnKey, JobBadge, OnboardingStep } from "./buildCarrierDashboardModel";

export const carrierDashboardContent = {
    loadingLabel: "Cargando tu panel",
    loadError: "No pudimos cargar tu panel",
    retry: "Reintentar",

    greeting: (name: string) => `Hola, ${name} 👋`,
    greetingFallback: "Hola 👋",
    greetingLead: "Este es el estado de tus viajes hoy.",
    /** Progressive primary CTA — follows the carrier's setup ladder. */
    cta: {
        "no-vehicle": "Agregá tu primer vehículo",
        "no-window": "Publicá tu primera ventana",
        steady: "Publicar ventana",
    } satisfies Record<OnboardingStep, string>,
    ctaHref: {
        "no-vehicle": "/carrier/vehicle/new",
        "no-window": "/carrier/availability/new",
        steady: "/carrier/availability/new",
    } satisfies Record<OnboardingStep, string>,

    stats: {
        regionLabel: "Tu flota de un vistazo",
        vehicles: (n: number) => (n === 1 ? "1 vehículo" : `${n} vehículos`),
        openWindows: (n: number) => (n === 1 ? "1 ventana abierta" : `${n} ventanas abiertas`),
        rating: (avg: string) => `${avg} de calificación`,
        ratingEmpty: "Sin calificaciones aún",
        vehiclesHref: "/carrier/vehicles",
        windowsHref: "/carrier/availability",
    },

    attention: {
        title: "Atención requerida",
        allClearTitle: "Todo al día",
        allClearLead: "No hay nada pendiente por ahora. Buen momento para publicar otra ventana.",
        expiring: {
            label: "Ofertas por vencer",
            hint: "Respondé antes de que venzan o vas a perder el viaje.",
            action: "Responder ya",
            count: (n: number) => (n === 1 ? "1 oferta" : `${n} ofertas`),
        },
        offersToAnswer: {
            label: "Ofertas nuevas por responder",
            hint: "Aceptá o rechazá para no dejar pasar trabajos.",
            action: "Responder",
            count: (n: number) => (n === 1 ? "1 oferta" : `${n} ofertas`),
        },
        toStart: {
            label: "Envíos por iniciar",
            hint: "El pago ya está en garantía: podés salir a buscar la carga.",
            action: "Iniciar viaje",
            count: (n: number) => (n === 1 ? "1 envío" : `${n} envíos`),
        },
        toDeliver: {
            label: "Envíos por entregar",
            hint: "Marcá la entrega para liberar tu pago.",
            action: "Ver envíos",
            count: (n: number) => (n === 1 ? "1 envío" : `${n} envíos`),
        },
        toReview: {
            label: "Expedidores por calificar",
            hint: "Tu calificación ayuda a otros transportistas a elegir bien.",
            action: "Calificar",
            count: (n: number) => (n === 1 ? "1 entrega" : `${n} entregas`),
        },
    },

    board: {
        title: "Mis viajes",
        regionLabel: "Mis viajes",
        columnEmpty: "Sin viajes aquí",
        columnNames: {
            newOffers: "Ofertas nuevas",
            toStart: "Por iniciar",
            inTransit: "En tránsito",
            delivered: "Entregadas",
            paid: "Pagadas",
        } satisfies Record<ColumnKey, string>,
        columnAccessibleName: (name: string, count: number) =>
            `${name}, ${count === 1 ? "1 viaje" : `${count} viajes`}`,
        cardAccessibleName: (origin: string, destination: string, status: string) =>
            `Viaje de ${origin} a ${destination}. Estado: ${status}.`,
        noStatus: "Sin estado",
        openDestination: "Destino abierto",
        /** Drill-down under the Pagadas column — the payouts history's only
         *  navigation entry point now that the header link is gone. */
        payoutsLink: "Historial de pagos",
        payoutsHref: "/carrier/payouts",
    },

    offerCard: {
        accept: "Aceptar",
        reject: "Rechazar",
        acceptOffer: (origin: string, destination: string) =>
            `Aceptar la oferta de ${origin} a ${destination}`,
        rejectOffer: (origin: string, destination: string) =>
            `Rechazar la oferta de ${origin} a ${destination}`,
        weight: (kg: string) => `${kg} kg`,
        distance: (km: string) => `${km} km`,
        /** e.g. "★ 4.5 (12)" — visible text; the a11y name is ratingAccessible */
        rating: (avg: string, count: number) => `★ ${avg} (${count})`,
        ratingAccessible: (avg: string, count: number) =>
            `Calificación ${avg} de 5, ${count === 1 ? "1 reseña" : `${count} reseñas`}`,
        ratingEmpty: "Sin reseñas",
        expiresIn: (relative: string) => `Vence ${relative}`,
        accepted: "Oferta aceptada",
        rejected: "Oferta rechazada",
        actionError: "No pudimos procesar la oferta. Probá de nuevo.",
        processing: "Procesando…",
        confirm: {
            acceptTitle: "Aceptar oferta",
            rejectTitle: "Rechazar oferta",
            acceptText:
                "Al aceptar te comprometés a realizar el viaje y se rechazarán las demás ofertas de esa ventana.",
            rejectText: "La oferta se rechazará y tu ventana volverá a quedar abierta.",
            accept: "Sí, aceptar",
            reject: "Sí, rechazar",
            cancel: "Cancelar",
        },
        closeFeedback: "Cerrar aviso",
    },

    badges: {
        expiring: "Vence pronto",
        new_offer: "Nueva",
        awaiting_payment: "Esperando pago",
        ready_to_start: "Lista para iniciar",
        in_transit: "En camino",
        to_collect: "Por cobrar",
        to_review: "Calificar",
        paid: "Pagada",
    } satisfies Record<NonNullable<JobBadge>, string>,

    feed: {
        regionLabel: "Actividad reciente",
        title: "Actividad reciente",
        empty: "Sin actividad reciente",
        descriptions: {
            payout_paid: "Cobraste un viaje",
            review_received: "Recibiste una reseña",
            offer_received: "Nueva oferta recibida",
            offer_accepted: "Aceptaste una oferta",
            offer_rejected: "Rechazaste una oferta",
        } satisfies Record<CarrierActivityItem["kind"], string>,
        ratingDetail: (rating: number) => `★ ${rating} de 5`,
        pager: {
            navLabel: "Paginación de actividad",
            prev: "Anterior",
            next: "Siguiente",
            range: (from: number, to: number, total: number) => `${from}–${to} de ${total}`,
        },
    },

    onboarding: {
        "no-vehicle": {
            title: "Sumá tu primer vehículo",
            lead:
                "Cargá los datos de tu camión o utilitario para empezar a ofrecer viajes en Truckr.",
        },
        "no-window": {
            title: "Publicá tu primera ventana",
            lead:
                "Contale al mercado cuándo y por dónde viajás: los expedidores te van a encontrar y enviarte ofertas.",
        },
        steady: {
            title: "Tu flota está lista",
            lead:
                "Ya estás visible en el mercado. Las ofertas de los expedidores van a aparecer acá apenas lleguen.",
        },
    } satisfies Record<OnboardingStep, { title: string; lead: string }>,
} as const;

/** Resolve a board badge to its Spanish label (text always present a11y-wise). */
export function jobBadgeLabel(badge: JobBadge): string {
    return carrierDashboardContent.badges[badge];
}
