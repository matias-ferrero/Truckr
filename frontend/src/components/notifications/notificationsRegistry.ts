import { landingContent } from "../../landingContent";

// Closed set of notification types — the frontend mirror of the backend's
// `Notifications::Type` whitelist (INF-FE-00005 / ADR-013). Each feature PR
// that introduces a new type extends both this union and the renderer map.
export type NotificationType =
    | "ping"
    | "cargo_offer_received"
    | "cargo_offer_accepted"
    | "cargo_offer_rejected"
    | "payout_approved"
    | "payout_failed";

export interface NotificationView {
    title: string;
    body: string;
}

// A renderer turns an incoming payload into displayable copy. Copy comes from
// `landingContent.notifications` (the prototype-stage i18n bundle) — never
// hardcoded here. Renderers may interpolate payload fields into the body.
type Renderer = (payload: unknown) => NotificationView;

export const notificationsRegistry: Record<NotificationType, Renderer> = {
    ping: () => ({
        title: landingContent.notifications.ping.title,
        body: landingContent.notifications.ping.body,
    }),
    cargo_offer_received: () => ({
        title: landingContent.notifications.cargo_offer_received.title,
        body: landingContent.notifications.cargo_offer_received.body,
    }),
    cargo_offer_accepted: () => ({
        title: landingContent.notifications.cargo_offer_accepted.title,
        body: landingContent.notifications.cargo_offer_accepted.body,
    }),
    cargo_offer_rejected: () => ({
        title: landingContent.notifications.cargo_offer_rejected.title,
        body: landingContent.notifications.cargo_offer_rejected.body,
    }),
    payout_approved: () => ({
        title: landingContent.notifications.payout_approved.title,
        body: landingContent.notifications.payout_approved.body,
    }),
    payout_failed: () => ({
        title: landingContent.notifications.payout_failed.title,
        body: landingContent.notifications.payout_failed.body,
    }),
};

// Type guard: is this incoming `type` one we know how to render?
export function isKnownNotificationType(type: unknown): type is NotificationType {
    return typeof type === "string" && Object.prototype.hasOwnProperty.call(notificationsRegistry, type);
}
