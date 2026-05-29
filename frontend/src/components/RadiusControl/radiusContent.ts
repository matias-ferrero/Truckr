// Prototype-stage i18n bundle for <RadiusControl /> (US50 + REQ-BE-00039 AC12).
// Keys are English; values are Spanish (es-AR). The `pickup` / `dropoff` split
// matches the role-parameterised component — when the repo adopts a real i18n
// library, port these to `transport_window.{role}_radius.*`.

export const radiusContent = {
    pickup: {
        label:                "Radio de recogida (km)",
        help:                 "Distancia máxima desde el origen en la que aceptás recoger cargas. Default 10 km.",
        placeholder:          "Ej. 10",
        placeholderWhenNoPin: "Seleccioná el origen para definir el radio.",
        mapAriaLabel:         "Mapa del radio de recogida",
    },
    dropoff: {
        label:                "Radio de entrega (km)",
        help:                 "Distancia máxima desde el destino en la que aceptás dejar cargas. Default 10 km.",
        placeholder:          "Ej. 10",
        placeholderWhenNoPin: "Seleccioná el destino para definir el radio.",
        mapAriaLabel:         "Mapa del radio de entrega",
    },
    error: {
        out_of_range: "El radio debe ser un entero entre 1 y 200 km.",
    },
} as const;

export type RadiusRole = "pickup" | "dropoff";
