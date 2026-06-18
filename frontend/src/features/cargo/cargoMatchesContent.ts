/**
 * es-AR copy bundle for the Cargo Matches v2 screen
 * (`/shipper/cargos/:id/matches` — docs/features/cargo-matches-v2.prd.md).
 * Prototype-stage i18n: all user-visible strings live here, never in JSX.
 */

import type { PickKind } from "./buildMatchesModel";
import { formatDistance } from "../../lib/format-distance";

export const cargoMatchesContent = {
    loadingLabel: "Cargando la carga",
    loadError: "No pudimos cargar esta carga",
    retry: "Reintentar",
    backToCargo: "← Volver a la carga",
    title: "Transportistas disponibles",
    lead: "Compará precio y reputación entre los transportistas compatibles con tu carga.",

    contextBar: {
        eyebrow: "Tu carga",
        viewDetail: "Ver detalle",
        pickupWindow: (from: string, to: string) => `Retiro ${from} – ${to}`,
    },

    notOpen: {
        title: "Esta carga ya no está abierta",
        lead: "Solo las cargas abiertas pueden recibir nuevas ofertas.",
        cta: "Ver detalle de la carga",
    },

    picks: {
        heading: "Recomendados",
        label: {
            cheapest: "Más barato",
            bestRated: "Mejor calificado",
            soonest: "Más próximo",
        } satisfies Record<PickKind, string>,
        why: {
            cheapest: "El precio total más bajo",
            bestRated: "La mejor reputación entre los compatibles",
            soonest: "El que puede retirar antes",
        } satisfies Record<PickKind, string>,
    },

    controls: {
        heading: "Todos los transportistas",
        resultCount: (shown: number, total: number) =>
            shown === total
                ? `${total} compatibles`
                : `${shown} de ${total} compatibles`,
        sortLabel: "Ordenar por",
        sortOptions: {
            "price-asc": "Menor precio",
            "price-desc": "Mayor precio",
            "rating-desc": "Mejor calificación",
            "date-asc": "Retiro más próximo",
        },
        maxPriceLabel: "Precio máximo",
        maxPricePlaceholder: "Sin tope",
        pickupFromLabel: "Retiro desde",
        pickupToLabel: "Retiro hasta",
        clearFilters: "Limpiar filtros",
        noFilterResults:
            "Ningún transportista entra en esos filtros. Probá ampliar el precio máximo o las fechas.",
    },

    card: {
        carrierFallback: "Transportista",
        totalPriceAria: (total: string) => `Precio total estimado ${total}`,
        reviews: (count: number) =>
            count === 1 ? "1 reseña" : `${count} reseñas`,
        newCarrier: "Transportista nuevo",
        newCarrierDetail: "Sin calificaciones todavía",
        availableFrom: (date: string) => `Sale ${date}`,
        distanceKm: (km: number) =>
            km < 1 ? "A menos de 1 km del retiro" : `A ${formatDistance(km)} del retiro`,
        viewProfile: "Ver perfil",
        offerCta: "Enviar oferta",
        offerCtaAria: (carrier: string, route: string) =>
            `Enviar oferta a ${carrier} para el tramo ${route}`,
    },

    pagination: {
        navLabel: "Páginas de resultados",
        prev: "← Anterior",
        next: "Siguiente →",
        pageStatus: (page: number, pages: number) => `Página ${page} de ${pages}`,
    },

    states: {
        matchesLoading: "Buscando transportistas…",
        matchesError: "No pudimos buscar transportistas",
        matchesEmptyTitle: "Todavía no hay transportistas compatibles",
        matchesEmptyHint:
            "Podés ampliar la ventana de retiro de tu carga para alcanzar más ventanas de transporte.",
        matchesEmptyCta: "Editar la carga",
    },
} as const;

export type CargoMatchesContent = typeof cargoMatchesContent;
