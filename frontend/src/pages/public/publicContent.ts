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
        ratingLabel: (avg: string, count: number) =>
            count === 0
                ? "Sin reseñas todavía"
                : `${avg} sobre 5 · ${count} reseña${count === 1 ? "" : "s"}`,
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
        reviewsTitle: "Reseñas",
        reviewsPlaceholder:
            "Próximamente vas a poder leer las reseñas de otros expedidores.",
        offerCta: "Ofertar",
        offerCtaAriaLabel: (zone: string) => `Crear oferta para la ruta ${zone}`,
    },
} as const;
