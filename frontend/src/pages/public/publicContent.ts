/* Prototype-stage i18n bundle for public-facing pages (US6+).
   Mirrors the carve-out in landingContent.ts / carrierContent.ts:
   content is structured data here until a real i18n library lands. */

export const publicContent = {
    carrierDetail: {
        loadingLabel: "Cargando perfil del transportista",
        loadError: "No pudimos cargar el perfil",
        retry: "Reintentar",
        notFoundTitle: "Transportista no encontrado",
        notFoundLead: "El perfil que buscás no existe o ya no está disponible.",
        backToSearch: "Volver a la búsqueda",
        editProfile: "Editar mi perfil",
        ratingLabel: (avg: string | null, count: number) =>
            count === 0
                ? "Sin reseñas todavía"
                : `${avg ?? ""} · ${count} reseña${count === 1 ? "" : "s"}`,
        ratingValue: (avg: string) => `${avg.replace(".", ",")}/5`,
        ratingCount: (count: number) => `${count} reseña${count === 1 ? "" : "s"}`,
        starsLabel: (avg: string) => `Promedio de ${avg} sobre 5 estrellas`,
        completedShipments: (n: number) =>
            `${n} viaje${n === 1 ? "" : "s"} completado${n === 1 ? "" : "s"}`,
        baseCity: "Zona de origen",
        descriptionTitle: "Sobre este transportista",
        descriptionFallback:
            "Este transportista todavía no escribió una descripción.",
        zonesTitle: "Zonas que recorre",
        zonesEmpty: "Sin zonas publicadas en este momento.",
        openDestinationLabel: "Cualquier destino",
        pricePerKmLabel: (price: string) => `$${price} / km`,
        photoAlt: (label: string) => `Foto de ${label}`,
        vehiclesTitle: "Vehículos",
        vehicleHeading: (make: string, model: string) => `${make} ${model}`,
        vehiclePlate: "Patente",
        vehicleCapacity: "Capacidad",
        vehicleCapacityUnit: "kg",
        vehicleGps: "Trackeo GPS",
        vehicleGpsYes: "Sí",
        vehicleGpsNo: "No",
        offerCta: "Ofertar",
        offerCtaAriaLabel: (zone: string) => `Crear oferta para la ruta ${zone}`,
        reviewsTitle: "Reseñas",
        signInHint: "Iniciá sesión para leer las reseñas.",
        empty: "Todavía no hay reseñas de expedidores para este transportista.",
        reviewDate: (iso: string) =>
            new Date(iso).toLocaleDateString("es-AR", {
                year: "numeric",
                month: "long",
                day: "numeric",
            }),
        loadMore: "Ver más reseñas",
        loadingMore: "Cargando…",
    },
    shipperDetail: {
        loadingLabel: "Cargando perfil del expedidor",
        loadError: "No pudimos cargar el perfil",
        retry: "Reintentar",
        notFoundTitle: "Expedidor no encontrado",
        notFoundLead: "El perfil que buscás no existe o ya no está disponible.",
        back: "Volver",
        editProfile: "Editar mi perfil",
        title: (name: string) => name,
        taxIdLabel: "CUIT",
        // AC2 / AC5 — average + count shown alongside individual reviews.
        reviewsTitle: "Reseñas",
        averageRating: "Puntuación promedio",
        // Hero rating line — mirrors carrierDetail.ratingLabel so the empty
        // state reads "Sin reseñas todavía" next to empty stars (not a full
        // sentence). avg may be null when there are no reviews.
        ratingLabel: (avg: string | null, count: number) =>
            count === 0
                ? "Sin reseñas todavía"
                : `${(avg ?? "").replace(".", ",")}/5 · ${count} reseña${count === 1 ? "" : "s"}`,
        ratingSummary: (avg: string, count: number) =>
            `${avg.replace(".", ",")}/5 · ${count} reseña${count === 1 ? "" : "s"}`,
        // Split parts for the hero rating — value and count are styled independently.
        ratingValue: (avg: string) => `${avg.replace(".", ",")}/5`,
        ratingCount: (count: number) => `${count} reseña${count === 1 ? "" : "s"}`,
        starsLabel: (avg: string) => `Promedio de ${avg} sobre 5 estrellas`,
        // i18n key reviews.shipper.empty (AC5).
        empty: "Este expedidor todavía no tiene reseñas.",
        // Individual review card.
        reviewStarsLabel: (rating: number) => `${rating} de 5 estrellas`,
        reviewDate: (iso: string) =>
            new Date(iso).toLocaleDateString("es-AR", {
                year: "numeric",
                month: "long",
                day: "numeric",
            }),
        loadMore: "Ver más reseñas",
        loadingMore: "Cargando…",
    },
} as const;
