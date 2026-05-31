import type { ShipmentState } from "../../api/shipments";

export const shipmentStateSortOrder: Record<ShipmentState, number> = {
    in_transit: 0,
    accepted:   1,
    delivered:  2,
    cancelled:  3,
};

export const shipmentsSharedContent = {
    state: {
        accepted:   "Aceptado",
        in_transit: "En tránsito",
        delivered:  "Entregado",
        cancelled:  "Cancelado",
    },
    paymentState: {
        pending: "Pendiente de pago",
        paid:    "Pagado",
    },
    routeArrow: "→",
    detailLinkAria: (id: number, origin: string, destination: string, stateLabel: string) =>
        `Envío #${id}: de ${origin} a ${destination}, ${stateLabel}`,
    row: {
        counterpartyLabel:  "Contraparte",
        counterpartyMasked: "Datos revelados al pagar",
        payCta:             (amount: string) => `Pagar ${amount}`,
        rowAria:            (id: number, origin: string, destination: string, stateLabel: string) =>
            `Envío #${id}: de ${origin} a ${destination}, ${stateLabel}`,
    },
    payConfirm: {
        title:   "¿Confirmás la acción?",
        lead:    "Pagar",
        text:    "Serás redirigido a la pantalla de pago para completar el proceso.",
        cancel:  "Cancelar",
        confirm: "Confirmar",
    },
} as const;
