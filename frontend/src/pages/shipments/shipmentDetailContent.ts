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
    // Shipment-detail v2 — sticky rail primary-action card. One entry per
    // state×role×payment cell of the matrix in
    // docs/features/shipment-detail-v2.prd.md §3. The card is never a dead
    // button: when the viewer can't act it shows reassuring status copy.
    rail: {
        regionLabel: "Estado y acciones del envío",
        // Eyebrows carry the *implication* (whose move is it), not the raw
        // state name — the state chips in the header already own that, so
        // repeating it verbatim 100px away would be dead redundancy.
        eyebrow: {
            next_step:        "Tu próximo paso",
            waiting_carrier:  "Esperando al transportista",
            waiting_shipper:  "Esperando al expedidor",
            in_progress:      "En curso",
            last_step:        "Último paso",
            cancelled:        "Sin acciones pendientes",
        },
        shipper: {
            pay: {
                headline: "Reservá tu envío",
                lead: "Pagá ahora para confirmar la reserva y que el transportista pueda retirar la carga.",
            },
            retry: {
                headline: "El pago no se procesó",
                lead: "Reintentá el pago para confirmar la reserva del envío.",
            },
            waiting_pickup: {
                headline: "Pago confirmado",
                lead: "Estamos esperando que el transportista retire la carga. Te avisaremos cuando esté en camino.",
            },
            in_transit: {
                headline: "Tu carga está en camino",
                lead: "Te avisaremos cuando el transportista confirme la entrega.",
            },
        },
        carrier: {
            waiting_payment: {
                headline: "Esperando el pago del expedidor",
                lead: "Vas a poder confirmar el retiro cuando el pago quede acreditado.",
            },
            ready_to_pick_up: {
                headline: "Listo para retirar",
                lead: "Confirmá el retiro cuando tengas la carga a bordo.",
            },
            in_transit: {
                headline: "Carga en tránsito",
                lead: "Confirmá la entrega cuando llegues a destino.",
            },
        },
        review: {
            headline: "¿Cómo fue tu experiencia?",
            lead: "Tu reseña ayuda a que la comunidad elija mejor.",
            cta: "Dejá tu reseña",
            dialogClose: "Cerrar",
        },
        cancelled: {
            headline: "Envío cancelado",
            lead: "Este envío fue cancelado y no requiere más acciones.",
        },
    },
    // Link-only counterparty reputation (shipment-detail v2 §6) — deep-links to
    // the public profile, keyed by the counterparty's kind.
    reputation: {
        carrier: "Ver reputación del transportista",
        shipper: "Ver reputación del expedidor",
    },
    confirm: {
        title: "¿Confirmás la acción?",
        // Pay confirmation — the single highest-anxiety click in the product.
        // Restate the amount, name the escrow protection, and make the button
        // concrete instead of generic ("¿Confirmás la acción?" → the money).
        payTitle: "Confirmá tu pago",
        payReassurance: "Tu pago queda protegido y solo se libera al transportista cuando confirmás la entrega.",
        payCta: (amount: string) => `Ir a pagar ${amount}`,
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
    payout: {
        sectionTitle: "Liquidación del envío",
        gross: "Monto bruto",
        commission: "Comisión plataforma",
        net: "Monto acreditado",
        paid_at: "Fecha de acreditación",
        states: {
            paid: "Acreditado",
            failed: "Fallido",
        },
        // delivered, but the payout row hasn't landed yet — answer "¿cuándo
        // cobro?" with a real status instead of an empty rail.
        pending: {
            eyebrow: "Liquidación",
            headline: "Liquidación en proceso",
            lead: "Estamos procesando el pago de tu envío. Vas a ver el detalle acá cuando se acredite.",
        },
    },
    review: {
        carrierSectionLabel: "Reseña del expedidor",
        shipperSectionLabel: "Reseña del transportista",
    },
    // US51 / REQ-FE-00028 — map section + Google Maps deep-links. v2 adds the
    // state-aware navigation emphasis for the carrier (prd §4): pickup while
    // `accepted`+paid, delivery while `in_transit`, demoted route otherwise.
    map: {
        sectionTitle: "Mapa del recorrido",
        openRoute: "Ver ruta en Google Maps",
        openRouteAria: (origin: string, destination: string) =>
            origin && destination
                ? `Ver ruta de ${origin} a ${destination} en Google Maps, se abre en una pestaña nueva`
                : "Ver ruta en Google Maps, se abre en una pestaña nueva",
        navToPickup: "Navegar al retiro",
        navToPickupAria: (origin: string) =>
            origin
                ? `Navegar al punto de retiro en ${origin} con Google Maps, se abre en una pestaña nueva`
                : "Navegar al punto de retiro con Google Maps, se abre en una pestaña nueva",
        navToDelivery: "Navegar a la entrega",
        navToDeliveryAria: (destination: string) =>
            destination
                ? `Navegar al punto de entrega en ${destination} con Google Maps, se abre en una pestaña nueva`
                : "Navegar al punto de entrega con Google Maps, se abre en una pestaña nueva",
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
        cancel_dialog:  "Cancelar",
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
