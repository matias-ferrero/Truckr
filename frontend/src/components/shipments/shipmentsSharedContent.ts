import type { ShipmentState } from "../../api/shipments";

export const shipmentStateSortOrder: Record<ShipmentState, number> = {
    in_transit:      0,
    pending_payment: 1,
    accepted:        2,
    delivered:       3,
    cancelled:       4,
};

export const shipmentsSharedContent = {
    state: {
        accepted:        "Aceptado",
        pending_payment: "Pendiente de pago",
        in_transit:      "En tránsito",
        delivered:       "Entregado",
        cancelled:       "Cancelado",
    },
    routeArrow: "→",
    detailLinkAria: (id: number, origin: string, destination: string, stateLabel: string) =>
        `Envío #${id}: de ${origin} a ${destination}, ${stateLabel}`,
} as const;
