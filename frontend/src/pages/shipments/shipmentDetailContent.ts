export const shipmentDetailContent = {
    title: (id: number) => `Envío #${id}`,
    back: "Volver a Mis Envíos",
    counterparty: {
        carrier: "Transportista",
        shipper:  "Expedidor",
    },
    composite: {
        to_pick_up:            "A recoger",
        awaiting_payment:      "Pendiente de pago",
        awaiting_payment_cta:  "Pagar ahora",
    },
    confirm: {
        title: "¿Confirmás la acción?",
        consequence: {
            start_transit: "El envío quedará registrado como en tránsito y el expedidor será notificado.",
            deliver:       "Se marcará el envío como entregado y se iniciará la liberación del pago al transportista.",
            pay:           "Serás redirigido a la pantalla de pago para completar el proceso.",
            cancel:        "El envío será cancelado. Esta acción es irreversible.",
        },
    },
    contact: {
        sectionTitle: "Datos de contacto",
    },
    review: {
        carrierSectionLabel: "Reseña del expedidor",
        shipperSectionLabel: "Reseña del transportista",
    },
    tracking: {
        sectionTitle: "Historial de eventos",
        placeholder:  "Se mostrará el recorrido cuando esté disponible",
        events: {
            shipment_accepted:   "Envío aceptado",
            shipment_in_transit: "En tránsito",
            shipment_delivered:  "Entregado",
            shipment_cancelled:  "Cancelado",
            payment_escrowed:    "Pago confirmado",
            payment_failed:      "Pago fallido",
        } as Record<string, string>,
        // Transitional labels for kind="status_change" events (REQ-BE-00038 will
        // replace these with dedicated event kinds emitted by the FSM directly).
        statusChangeLabel: {
            in_transit: "En tránsito",
            delivered:  "Entregado",
            cancelled:  "Cancelado",
        } as Record<string, string>,
        emptyDefault: "Sin eventos registrados aún.",
        emptyByState: {
            accepted:   "Los eventos de seguimiento se registrarán al iniciar el transporte.",
            in_transit: "Los eventos se están registrando.",
            delivered:  "Entrega completada.",
            cancelled:  "El envío fue cancelado antes de iniciar el transporte.",
        } as Record<string, string>,
    },
    actions: {
        start_transit:  "Confirmar Retiro",
        deliver:        "Confirmar entrega",
        pay:            "Pagar",
        retry_payment:  "Reintentar pago",
        cancel:         "Cancelar envío",
        error: {
            generic: "No pudimos completar la acción. Intentá de nuevo.",
        },
    },
    fields: {
        origin:      "Origen",
        destination: "Destino",
        description: "Descripción",
        weight:      "Peso",
        vehicle:     "Vehículo",
        created_at:  "Fecha de creación",
        picked_up_at: "Retirada de carga",
        delivered_at: "Entrega de carga",
        amount:      "Monto acordado",
        contact_name:  "Nombre de contacto",
        contact_email: "Correo de contacto",
        contact_phone: "Teléfono de contacto",
    },
    notfound: {
        title: "Envío no encontrado",
        lead:  "Este envío no existe o no tenés acceso a él.",
        cta:   "Volver al listado",
    },
    error: {
        title: "No se pudo cargar el envío",
        retry: "Reintentar",
    },
    skeleton: {
        label: "Cargando envío",
    },
} as const;
