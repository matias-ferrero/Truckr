/* Prototype-stage i18n bundle for the Cargo publication funnel (US27).
 * Follows the carve-out in CLAUDE.md §Language policy: content data acting as
 * the i18n bundle until a real i18n library replaces it. Components must read
 * every string from here — never inline literals. */

const PROVINCES = [
    "Buenos Aires",
    "Catamarca",
    "Chaco",
    "Chubut",
    "Ciudad Autónoma de Buenos Aires",
    "Córdoba",
    "Corrientes",
    "Entre Ríos",
    "Formosa",
    "Jujuy",
    "La Pampa",
    "La Rioja",
    "Mendoza",
    "Misiones",
    "Neuquén",
    "Río Negro",
    "Salta",
    "San Juan",
    "San Luis",
    "Santa Cruz",
    "Santa Fe",
    "Santiago del Estero",
    "Tierra del Fuego",
    "Tucumán",
] as const;

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
        route: (from: string, to: string) => `${from} → ${to}`,
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
            deliveryAddress: "Dirección de entrega",
            pickupZone: "Zona de retiro",
            deliveryZone: "Zona de entrega",
            zoneHelp: "Provincia o región — la usamos para buscar transportistas.",
            zoneDefault: "Seleccioná una zona",
            pickupWindowStart: "Retiro desde",
            pickupWindowEnd: "Retiro hasta",
            weightKg: "Peso (kg)",
            volumeCm3: "Volumen (cm³)",
            volumeOptional: "Opcional.",
            declaredValue: "Valor declarado (ARS)",
        },
        provinces: PROVINCES,
        errors: {
            cargoDescriptionRequired: "Ingresá una descripción de la carga.",
            cargoDescriptionTooLong: "La descripción no puede superar los 200 caracteres.",
            pickupAddressRequired: "Ingresá la dirección de retiro.",
            deliveryAddressRequired: "Ingresá la dirección de entrega.",
            pickupZoneRequired: "Elegí la zona de retiro.",
            deliveryZoneRequired: "Elegí la zona de entrega.",
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
            route: (from: string, to: string) => `${from} → ${to}`,
            pickup: "Retiro",
            delivery: "Entrega",
            pickupWindow: "Ventana de retiro",
            weight: "Peso",
            weightUnit: "kg",
            volume: "Volumen",
            volumeUnit: "cm³",
            volumeNone: "Sin especificar",
            declaredValue: "Valor declarado",
        },
        offers: {
            empty: "Todavía no enviaste ofertas para esta carga.",
            emptyHint: "Buscá transportistas para enviar tu primera oferta.",
            window: (from: string, to: string) => `${from} → ${to}`,
            acceptedTitle: "Oferta aceptada",
            acceptedLead: "Coordinaste el viaje con este transportista.",
        },
        cancelDialog: {
            title: "Cancelar esta carga",
            text:
                "Si cancelás la carga, las ofertas pendientes que recibiste van a vencer. Esta acción no se puede deshacer.",
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
        lead: "Tocá un transportista para enviarle una oferta por esta carga.",
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
        carrier: (name: string) => `Transportista: ${name}`,
        carrierFallback: "Transportista",
        rating: (avg: string) => `${avg} ★`,
        vehicle: (make: string, model: string, plate: string) =>
            `${make} ${model} · ${plate}`,
        capacity: (kg: string) => `Capacidad: ${kg} kg`,
        availability: (from: string, to: string) => `Disponible ${from} – ${to}`,
        pricePerKm: (price: string) => `$${price} / km`,
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
