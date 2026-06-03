// UI chrome copy for the notifications primitives (INF-FE-00005). Mirrors the
// existing content-module pattern (e.g. offersAndShipmentsContent) — labels
// live here, not hardcoded in JSX, per the language policy. The per-type
// title/body copy lives in landingContent.notifications and is resolved
// through notificationsRegistry; this module only covers the surrounding
// controls (toast close button, badge, history panel).
export const notificationsContent = {
    toast: {
        region: "Notificaciones recientes",
        dismiss: "Descartar notificación",
    },
    badge: {
        open: "Abrir notificaciones",
        unreadAria: (count: number) =>
            `${count} notificación${count === 1 ? "" : "es"} sin leer`,
        panelTitle: "Notificaciones",
        empty: "No tenés notificaciones en esta sesión.",
        clear: "Limpiar todo",
    },
};
