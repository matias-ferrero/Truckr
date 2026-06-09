// Prototype-stage i18n bundle for <ShipmentMap /> (US51 / REQ-FE-00028).
// All copy lives here so no Spanish literal leaks into the JSX. Folds into the
// real i18n library when it lands (see CLAUDE.md language policy).
export const shipmentMapContent = {
    // AC3 — defensive: shown when origin or destination coordinates are missing.
    unavailable: "Mapa no disponible: falta la información de ubicación de este envío.",
    // AC9 — shown when the Google Maps JS API fails to load (no key, network,
    // quota). The deep-link button renders separately and keeps working.
    serviceUnavailable:
        "No pudimos cargar el mapa. Usá el botón para ver la ruta en Google Maps.",
    regionLabel: "Mapa del envío con el origen y el destino",
    originPinTitle: "Origen",
    destinationPinTitle: "Destino",
} as const;
