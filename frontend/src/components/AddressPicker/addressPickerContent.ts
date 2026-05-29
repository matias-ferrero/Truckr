// Prototype-stage i18n bundle for <AddressPicker /> (US48 / REQ-FE-00025).
// Keys are English; values are Spanish (es-AR). Migrate to a real i18n
// library when the repo adopts one — meanwhile keep the shape stable so
// US49 / US50 consumers can reuse without poking the file.

export const addressPickerContent = {
    placeholder:        "Ingresá una dirección argentina",
    statusLoading:      "Cargando servicio de direcciones…",
    error: {
        unconfirmed:        "Confirmá una sugerencia del listado para captar la ubicación.",
        serviceUnavailable: "Servicio de direcciones no disponible. Reintentá en un rato.",
    },
} as const;
