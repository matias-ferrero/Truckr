/* Prototype-stage i18n bundle for the cargo-scoped offer confirm step
   (US7 / REQ-FE-00015 remediation). Follows the carve-out in CLAUDE.md:
   content data acting as the i18n bundle until a real i18n library lands.

   Post-remediation the offer flow is a single confirm step: it bids an
   already-published Cargo against a chosen TransportWindow. The old 3-step
   wizard copy (addresses, cargo fields) is gone — that data lives on the
   published Cargo. */

export const offerContent = {
    title: "Confirmar oferta",
    lead: "Revisá la carga y la ventana de transporte antes de enviar tu oferta.",
    loadingLabel: "Cargando los datos de la oferta",
    loadError: "No pudimos cargar la carga o la ventana de transporte.",
    backToCargo: "← Volver a la carga",
    cargoSection: {
        heading: "Tu carga",
        route: (from: string, to: string) => `${from} → ${to}`,
        pickup: "Retiro",
        delivery: "Entrega",
        pickupWindow: "Ventana de retiro",
        weight: "Peso",
        weightUnit: "kg",
    },
    windowSection: {
        heading: "Ventana de transporte",
        route: (from: string, to: string) => `${from} → ${to}`,
        carrier: (name: string) => `Transportista: ${name}`,
        carrierFallback: "Transportista",
        vehicle: (make: string, model: string, plate: string) =>
            `${make} ${model} · ${plate}`,
        rate: (rate: string) => `$${rate} / km`,
        availability: (from: string, to: string) => `Disponible ${from} – ${to}`,
    },
    estimatedKm: "Kilómetros estimados del viaje",
    estimatedKmError: "Ingresá una cantidad de kilómetros mayor a cero.",
    estimatedCost: "Costo estimado",
    noEstimate: "Ingresá los km para ver el costo",
    submit: "Enviar oferta",
    submitting: "Enviando…",
    cancel: "Cancelar",
    errors: {
        saveError: "No se pudo enviar la oferta. Revisá los campos e intentá de nuevo.",
    },
} as const;
