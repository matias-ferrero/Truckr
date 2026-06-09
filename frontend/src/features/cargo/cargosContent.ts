/* Prototype-stage i18n bundle for the Cargo publication funnel (US27).
 * Follows the carve-out in CLAUDE.md §Language policy: content data acting as
 * the i18n bundle until a real i18n library replaces it. Components must read
 * every string from here — never inline literals. */

import { formatDistance } from "../../lib/format-distance";

export const cargosContent = {
    statusLabel: {
        open: "Abierta",
        accepted: "Aceptada",
        cancelled: "Cancelada",
    } as Record<string, string>,
    /** Maps a CargoStatus to the `.statusBadge` CSS modifier. */
    statusBadgeClass: {
        open: "pendiente",
        accepted: "aceptado",
        cancelled: "pasado",
    } as Record<string, string>,

    list: {
        title: "Mis cargas",
        lead: "Publicá tus cargas y mirá qué transportistas pueden llevarlas.",
        publishCta: "Publicar carga",
        loadingLabel: "Cargando tus cargas",
        loadError: "No pudimos cargar tus cargas",
        retry: "Reintentar",
        gridLabel: "Cargas publicadas",
        emptyTitle: "Todavía no publicaste cargas",
        emptyLead: "Publicá tu primera carga para encontrar transportistas.",
        emptyCta: "Publicá tu primera carga",
        filterLabel: "Filtrar por estado",
        filterAll: "Todas",
        openDestinationLabel: "Cualquier destino",
        route: (from: string, to: string | null) => `${from} → ${to ?? "Cualquier destino"}`,
        pickupWindow: (from: string, to: string) =>
            from === to ? from : `${from} – ${to}`,
        offersCount: (n: number) =>
            n === 1 ? "1 oferta pendiente" : `${n} ofertas pendientes`,
        noOffers: "Sin ofertas todavía",
        viewDetail: "Ver detalle",
        pagination: {
            label: "Paginación de cargas",
            previous: "← Anterior",
            next: "Siguiente →",
            page: (page: number, total: number) => `Página ${page} de ${total}`,
            count: (total: number) =>
                `${total} carga${total === 1 ? "" : "s"}`,
        },
    },

    form: {
        newTitle: "Publicar una carga",
        editTitle: "Editar carga",
        newLead: "Contanos qué necesitás mover y entre qué fechas.",
        editLead: "Actualizá los datos de tu carga.",
        hydrating: "Cargando los datos de la carga",
        loadError: "No pudimos cargar la carga que querés editar.",
        allRequired: "Los campos marcados con * son obligatorios.",
        saveError: "No pudimos guardar la carga. Revisá los campos e intentá de nuevo.",
        sections: {
            what: "¿Qué querés mover?",
            where: "¿Desde y hasta dónde?",
            when: "¿En qué fechas?",
        },
        fields: {
            cargoDescription: "Descripción de la carga",
            cargoDescriptionHelp: "Hasta 200 caracteres.",
            pickupAddress: "Dirección de retiro",
            pickupAddressHelp:
                "Buscá una dirección y elegila del listado — capturamos sus coordenadas.",
            deliveryAddress: "Dirección de entrega",
            deliveryAddressHelp:
                "Buscá una dirección y elegila del listado — capturamos sus coordenadas.",
            pickupWindowStart: "Retiro desde",
            pickupWindowEnd: "Retiro hasta",
            weightKg: "Peso (kg)",
            weightKgHelp: "Hasta una decimal.",
            volumeCm3: "Volumen (cm³)",
            volumeOptional: "Opcional. Número entero.",
            declaredValue: "Valor declarado (ARS)",
            declaredValueHelp: "Ingresá pesos argentinos enteros, sin centavos.",
        },
        declaredValuePreview: (value: string) => `Se verá como ${value}.`,
        errors: {
            cargoDescriptionRequired: "Ingresá una descripción de la carga.",
            cargoDescriptionTooLong: "La descripción no puede superar los 200 caracteres.",
            pickupAddressRequired:
                "Confirmá una dirección de retiro desde el listado.",
            deliveryAddressRequired:
                "Confirmá una dirección de entrega desde el listado.",
            pickupWindowStartRequired: "Ingresá la fecha de inicio del retiro.",
            pickupWindowEndRequired: "Ingresá la fecha de fin del retiro.",
            pickupWindowEndBeforeStart:
                "El fin de la ventana debe ser posterior al inicio.",
            weightRequired: "Ingresá el peso de la carga.",
            weightPositive: "El peso debe ser mayor a cero.",
            volumePositive: "El volumen debe ser mayor a cero.",
            declaredValueRequired: "Ingresá el valor declarado.",
            declaredValueNonNegative: "El valor declarado no puede ser negativo.",
        },
        submit: {
            create: "Publicar carga",
            update: "Guardar cambios",
            saving: "Guardando…",
            cancel: "Cancelar",
        },
        saveErrorDialog: {
            title: "No se pudo guardar la carga",
            close: "Entendido",
        },
        mapPreview: {
            title: "Vista previa del recorrido",
            help:
                "Confirmá las dos direcciones para ver los pines de retiro y entrega.",
            pickupLabel: "Retiro",
            deliveryLabel: "Entrega",
            unavailable:
                "No pudimos cargar el mapa. Las coordenadas se guardan igual.",
            regionLabel: "Mapa con los pines de retiro y entrega",
            distanceLabel: "Distancia por ruta",
            distanceLoading: "Calculando distancia por ruta…",
            distanceUnavailable: "No se pudo calcular la distancia de la ruta.",
            distance: (km: number) => `Distancia por ruta: ${formatDistance(km)}`,
        },
    },

    detail: {
        loadingLabel: "Cargando la carga",
        loadError: "No pudimos cargar esta carga",
        retry: "Reintentar",
        backToList: "← Volver a mis cargas",
        editCta: "Editar",
        cancelCta: "Cancelar carga",
        searchCarriersCta: "Buscar transportistas",
        cancelledBadge: "Esta carga fue cancelada.",
        cancelledAt: (date: string) => `Cancelada el ${date}.`,
        sections: {
            summary: "Detalle de la carga",
            offers: "Mis ofertas",
        },
        summary: {
            openDestinationLabel: "Cualquier destino",
            route: (from: string, to: string | null) => `${from} → ${to ?? "Cualquier destino"}`,
            pickup: "Retiro",
            delivery: "Entrega",
            pickupWindow: "Ventana de retiro",
            weight: "Peso",
            weightUnit: "kg",
            volume: "Volumen",
            volumeUnit: "cm³",
            volumeNone: "Sin especificar",
            declaredValue: "Valor declarado",
            distance: "Distancia del viaje",
            distanceUnavailable: "No disponible",
        },
        offers: {
            empty: "Todavía no enviaste ofertas para esta carga.",
            emptyHint: "Buscá transportistas para enviar tu primera oferta.",
            window: (from: string, to: string) => `${from} → ${to}`,
            acceptedTitle: "Oferta aceptada",
            carrierFallback: "Transportista",
            acceptedAmountLabel: "Monto acordado",
            acceptedWindowLabel: "Ventana de disponibilidad",
            acceptedWindow: (from: string, to: string) => `${from} – ${to}`,
            expiresAt: (date: string) => `Vence el ${date}`,
        },
        cancelDialog: {
            title: "Cancelar esta carga",
            text:
                "Si cancelás la carga, las ofertas que enviaste a los transportistas van a vencer. Esta acción no se puede deshacer.",
            reasonLabel: "Motivo (opcional)",
            confirm: "Sí, cancelar carga",
            cancel: "No, volver",
            cancelling: "Cancelando…",
            error: "No pudimos cancelar la carga. Intentá de nuevo.",
        },
    },

    matchesScreen: {
        loadingLabel: "Cargando la carga",
        loadError: "No pudimos cargar esta carga",
        retry: "Reintentar",
        backToCargo: "← Volver a la carga",
        title: "Transportistas disponibles",
        lead: "Explorá los tramos compatibles y elegí el transportista para tu carga.",
        selectedCargoLabel: "Carga seleccionada",
        viewCargoDetail: "Ver detalle de la carga",
        notOpenTitle: "Esta carga ya no está abierta",
        notOpenLead: "Solo las cargas abiertas pueden recibir nuevas ofertas.",
        listLabel: "Transportistas compatibles",
        matchesLoading: "Buscando transportistas",
        matchesError: "No pudimos buscar transportistas",
        matchesEmpty:
            "Todavía no hay transportistas compatibles con esta carga.",
    },

    dashboardSection: {
        heading: "Mis cargas",
        countLabel: (n: number) => `${n} cargas`,
        viewAll: "Ver todas",
        publishCta: "Publicar carga",
        loadError: "No pudimos cargar tus cargas",
        retry: "Reintentar",
        emptyTitle: "Todavía no publicaste cargas",
        emptyHint: "Publicá tu primera carga para encontrar transportistas.",
        lanes: {
            open: "Abiertas",
            accepted: "Aceptadas",
            cancelled: "Canceladas",
        } as Record<string, string>,
        laneCount: (label: string, n: number) => `${label} · ${n}`,
        viewDetail: "Ver detalle",
        openCardAria: (route: string) =>
            `Buscar transportistas para la carga ${route}`,
        detailCardAria: (route: string) => `Ver el detalle de la carga ${route}`,
    },

    match: {
        carrier: (name: string) => name,
        carrierFallback: "Transportista",
        viewCarrierDetail: "Ver perfil",
        rating: (avg: string, count: number) => `${avg} ★ (${count})`,
        noRating: "Sin calificaciones",
        offerCta: "Enviar oferta →",
        vehicle: (make: string, model: string, plate: string) =>
            `${make} ${model} · ${plate}`,
        capacity: (kg: string) => `Capacidad: ${kg} kg`,
        availability: (from: string, to: string) => `Disponible ${from} – ${to}`,
        pricePerKm: (price: string) => `$${price} / km`,
        distanceKm: (km: number) =>
            km < 1 ? "Menos de 1 km del retiro" : `A ${formatDistance(km)} del retiro`,
        offerCtaAria: (route: string) => `Ofertar para el tramo ${route}`,
    },

    /** Maps a CargoOffer status to the `.statusBadge` modifier + label. */
    offerStatusLabel: {
        pending: "Pendiente",
        accepted: "Aceptada",
        paid: "Pagada",
        expired: "Vencida",
        cancelled: "Cancelada",
    } as Record<string, string>,
    offerStatusBadgeClass: {
        pending: "pendiente",
        accepted: "aceptado",
        paid: "pagado",
        expired: "pasado",
        cancelled: "pasado",
    } as Record<string, string>,
} as const;

export type CargosContent = typeof cargosContent;
