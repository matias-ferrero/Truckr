export const shipperShipmentsContent = {
    title: "Mis Envíos",
    lead: "Seguí todos los envíos que contrataste.",
    loadingLabel: "Cargando envíos",
    loadError: "No pudimos cargar tus envíos",
    retry: "Reintentar",
    emptyTitle: "Aún no contrataste envíos",
    emptyLead: "Publicá una carga y esperá que un transportista envíe una oferta.",
    emptyCtaLabel: "Publicar una carga",
    listLabel: "Lista de envíos",
    shipmentCount: (n: number) => n === 1 ? "1 envío" : `${n} envíos`,
} as const;
