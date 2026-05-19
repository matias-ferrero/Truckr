/* Prototype-stage i18n bundle for the offer creation wizard (US7 / REQ-FE-00015).
   Follows the carve-out in CLAUDE.md: content data acting as the i18n bundle
   until a real i18n library replaces it. */

export const offerContent = {
    title: "Crear oferta de carga",
    stepLabels: ["Direcciones", "Carga", "Fecha y presupuesto"] as const,
    steps: {
        addresses: {
            heading: "¿Dónde retiramos y entregamos?",
            pickupGroup: "Origen",
            deliveryGroup: "Destino",
            street: "Calle",
            streetNumber: "Número",
            floor: "Piso / depto",
            floorPlaceholder: "3° A (opcional)",
            postalCode: "Código postal",
            city: "Localidad",
            province: "Provincia",
            provinceDefault: "Seleccioná una provincia",
            provinces: [
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
            ] as const,
        },
        cargo: {
            heading: "Detalle de la carga",
            cargoDescription: "Descripción de la carga",
            weightKg: "Peso (kg)",
            weightHint: (max: string) => `Capacidad máxima del vehículo: ${max} kg`,
            weightExceeded: (max: string) =>
                `El peso supera la capacidad del vehículo (${max} kg).`,
            volumeCm3: "Volumen (cm³)",
            volumeHint: (max: number) =>
                `Capacidad máxima del vehículo: ${max.toLocaleString("es-AR")} cm³`,
            volumeNoLimit: "Este vehículo no tiene volumen máximo registrado.",
            volumeExceeded: (max: number) =>
                `El volumen supera la capacidad del vehículo (${max.toLocaleString("es-AR")} cm³).`,
            declaredValue: "Valor declarado (ARS)",
        },
        review: {
            heading: "Fecha y resumen del presupuesto",
            windowInfo: "Ventana de transporte seleccionada",
            windowZone: (origin: string, dest: string) => `${origin} → ${dest}`,
            windowRate: (rate: string) => `$${rate} / km`,
            pickupDate: "Fecha de retiro",
            pickupDateHint: (from: string, to: string) =>
                `Disponible entre ${from} y ${to}`,
            estimatedKm: "Kilómetros estimados del viaje",
            estimatedCost: "Costo estimado",
            noEstimate: "Ingresá los km para ver el costo",
        },
    },
    nav: {
        next: "Siguiente",
        back: "Atrás",
        submit: "Enviar oferta",
        submitting: "Enviando…",
    },
    confirmation: {
        title: "Oferta enviada",
        lead: "Tu oferta fue enviada al transportista. Te avisaremos cuando responda.",
        quoteRef: (id: number) => `Referencia de oferta: #${id}`,
        status: "Estado: pendiente de respuesta",
        backToHome: "Volver al panel",
    },
    errors: {
        noState: "No se pudo cargar la ventana de transporte. Volvé al perfil del transportista.",
        saveError: "No se pudo enviar la oferta. Revisá los campos e intentá de nuevo.",
    },
    stepAnnouncement: (step: number, label: string) => `Paso ${step}: ${label}`,
} as const;
