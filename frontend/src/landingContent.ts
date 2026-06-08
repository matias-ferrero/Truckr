export interface LandingData {
    hero: {
        title: string;
        brand: string;
        kicker: string;
        subtitle: string;
        cta_primary: string;
        cta_secondary: string;
    };
    features: Array<{
        id: number;
        title: string;
        description: string;
        icon: string;
    }>;
    stats: Array<{
        label: string;
        value: string;
    }>;
    audiences: {
        shipper: {
            label: string;
            title: string;
            description: string;
            bullets: string[];
            cta: string;
        };
        carrier: {
            label: string;
            title: string;
            description: string;
            bullets: string[];
            cta: string;
        };
    };
    steps: Array<{
        n: string;
        title: string;
        shipper: string;
        carrier: string;
    }>;
    commitments: Array<{
        title: string;
        body: string;
    }>;
    finalCta: {
        kicker: string;
        title: string;
        subtitle: string;
        shipper: string;
        carrier: string;
        loginPrompt: string;
        loginLabel: string;
    };
    color_palette: {
        primary: string;
        secondary: string;
        tertiary: string;
        error: string;
        neutral: string;
    };
    // Realtime in-app notification copy (INF-FE-00005). Until a real i18n
    // library lands, this bundle is the prototype-stage i18n source (CLAUDE.md
    // carve-out). Each notification type the backend can emit gets a typed
    // entry here; the frontend registry reads from it. New types are added by
    // the feature PR that introduces them.
    notifications: {
        ping: { title: string; body: string };
        cargo_offer_received: { title: string; body: string };
        cargo_offer_accepted: { title: string; body: string };
        cargo_offer_rejected: { title: string; body: string };
        payout_approved: { title: string; body: string };
        payout_failed: { title: string; body: string };
    };
}

export const landingContent: LandingData = {
    hero: {
        title: "Llevamos lo tuyo, sin vueltas.",
        brand: "Truckr®",
        kicker: "Marketplace de transporte · Argentina",
        subtitle:
            "Un lugar donde transportistas independientes y expedidores se encuentran con información clara, tarifas honestas y trato humano.",
        cta_primary: "Tengo un envío",
        cta_secondary: "Tengo un camión",
    },
    features: [
        {
            id: 1,
            title: "Tarifas claras",
            description:
                "Precio acordado antes de salir. Sin recargos a último momento ni cargos por gestión escondidos.",
            icon: "tag",
        },
        {
            id: 2,
            title: "Trato directo",
            description:
                "Hablás directo con la otra parte. Cero call center, cero formularios infinitos para coordinar un viaje.",
            icon: "chat",
        },
        {
            id: 3,
            title: "Trazabilidad real",
            description:
                "Datos completos del envío y del transportista antes de aceptar. Historial guardado para revisar después.",
            icon: "route",
        },
    ],
    stats: [
        { label: "Transportistas Activos", value: "500+" },
        { label: "Expedidores Satisfechos", value: "1000+" },
        { label: "Envíos Completados", value: "5000+" },
    ],
    audiences: {
        shipper: {
            label: "Para expedidores",
            title: "Tenés algo para mover. Te conectamos con quien lo lleva.",
            description:
                "Publicás el envío con la información clave, recibís propuestas de transportistas verificados y elegís sin presión.",
            bullets: [
                "Cotización en pesos, sin letra chica.",
                "Verificación de licencia, seguro y patente.",
                "Historial y reseñas reales de cada transportista.",
            ],
            cta: "Quiero enviar algo",
        },
        carrier: {
            label: "Para transportistas",
            title: "Tenés un camión. Te conectamos con cargas que valen el viaje.",
            description:
                "Publicás tu disponibilidad y rutas frecuentes, recibís pedidos que encajan, y coordinás directo sin perder tiempo.",
            bullets: [
                "Cobrás por transferencia, sin intermediarios.",
                "Filtrás por ruta, peso y tipo de carga.",
                "Construís tu reputación con cada viaje.",
            ],
            cta: "Quiero recibir viajes",
        },
    },
    steps: [
        {
            n: "01",
            title: "Publicás",
            shipper: "Cargás los datos del envío: origen, destino, peso y fecha.",
            carrier: "Cargás tu camión, capacidad, ruta habitual y disponibilidad.",
        },
        {
            n: "02",
            title: "Cruzamos",
            shipper: "Te llegan propuestas de transportistas que pasan por tu ruta.",
            carrier: "Te llegan pedidos compatibles con tu camión y agenda.",
        },
        {
            n: "03",
            title: "Coordinan",
            shipper: "Hablan directo, acuerdan precio, y el envío queda en marcha.",
            carrier: "Cerrás el viaje, cobrás al entregar, y queda en tu historial.",
        },
    ],
    commitments: [
        {
            title: "Precio antes del viaje",
            body: "La cotización es vinculante. Lo que se acordó es lo que se paga, salvo cambios pactados por ambos lados.",
        },
        {
            title: "Soporte de personas",
            body: "Atendemos por WhatsApp en horario hábil. Hablás con alguien, no con un bot que te deriva en círculos.",
        },
        {
            title: "Datos a la vista",
            body: "Antes de cerrar, ves quién es la otra parte, qué llevó antes y qué dijeron sus clientes anteriores.",
        },
    ],
    finalCta: {
        kicker: "Empezar",
        title: "Listo para mover lo tuyo, o para llenar tu camión.",
        subtitle:
            "Crear cuenta es gratis. Te tomamos sólo lo necesario para conectarte con la otra parte.",
        shipper: "Crear cuenta como expedidor",
        carrier: "Crear cuenta como transportista",
        loginPrompt: "¿Ya tenés cuenta?",
        loginLabel: "Iniciar sesión",
    },
    color_palette: {
        primary: "#46aadc",
        secondary: "#e1be5a",
        tertiary: "#9ca0a8",
        error: "#e26464",
        neutral: "#ffffff",
    },
    notifications: {
        ping: {
            title: "Notificaciones activas",
            body: "Recibís avisos en tiempo real mientras tu sesión está abierta.",
        },
        cargo_offer_received: {
            title: "Nueva oferta recibida",
            body: "Un expedidor te envió una oferta de carga. Revisala en tu bandeja para aceptarla o rechazarla.",
        },
        cargo_offer_accepted: {
            title: "Tu oferta fue aceptada",
            body: "El transportista aceptó tu oferta de carga. Ya podés continuar con el pago.",
        },
        cargo_offer_rejected: {
            title: "Tu oferta fue rechazada",
            body: "El transportista no aceptó tu oferta de carga. Podés enviar una nueva oferta.",
        },
        payout_approved: {
            title: "Pago acreditado",
            body: "Se transfirió el pago por tu envío.",
        },
        payout_failed: {
            title: "Error en pago",
            body: "Hubo un problema al procesar el pago del envío.",
        },
    },
};
