export interface LandingData {
    hero: {
        title: string;
        subtitle: string;
        description: string;
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
    color_palette: {
        primary: string;
        secondary: string;
        tertiary: string;
        error: string;
        neutral: string;
    };
}

export const landingContent: LandingData = {
    hero: {
        title: "Truckr®",
        subtitle: "Conectando transportistas independientes con expedidores",
        description: "La plataforma de servicios de transporte que une oferta y demanda",
        cta_primary: "Comenzar",
        cta_secondary: "Más información",
    },
    features: [
        {
            id: 1,
            title: "Para Transportistas",
            description: "Expande tu negocio encontrando nuevos expedidores de forma sencilla",
            icon: "truck",
        },
        {
            id: 2,
            title: "Para Expedidores",
            description: "Solicita servicios de transporte confiables al mejor precio",
            icon: "package",
        },
        {
            id: 3,
            title: "Seguro y Confiable",
            description: "Todas las transacciones están protegidas y verificadas",
            icon: "shield",
        },
    ],
    stats: [
        { label: "Transportistas Activos", value: "500+" },
        { label: "Expedidores Satisfechos", value: "1000+" },
        { label: "Envíos Completados", value: "5000+" },
    ],
    color_palette: {
        primary: "#bee4fa",
        secondary: "#f1e3aa",
        tertiary: "#b4b4b4",
        error: "#ff9999",
        neutral: "#ffffff",
    },
};
