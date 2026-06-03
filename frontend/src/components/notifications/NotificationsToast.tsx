import { useNotifications } from "./NotificationsProvider";
import { notificationsContent } from "./notificationsContent";

// Transient toast stack: shows the most recent unread notifications in a
// corner overlay. Copy comes from the registry (via the provider); the only
// chrome label (the close button) reads from notificationsContent — no
// hardcoded JSX strings. UX defaults (position, motion, auto-dismiss, stack
// depth) were settled during the /critique → /polish → /audit gate.
const MAX_VISIBLE = 3;

export function NotificationsToast() {
    const { notifications, dismiss } = useNotifications();
    const text = notificationsContent.toast;

    const visible = notifications.filter((n) => !n.read).slice(0, MAX_VISIBLE);
    if (visible.length === 0) return null;

    return (
        <div className="notifToastRegion" role="region" aria-label={text.region} aria-live="polite">
            {visible.map((n) => (
                <article key={n.id} className="notifToast" role="status">
                    <div className="notifToastBody">
                        <p className="notifToastTitle">{n.title}</p>
                        <p className="notifToastText">{n.body}</p>
                    </div>
                    <button
                        type="button"
                        className="notifToastClose"
                        aria-label={text.dismiss}
                        onClick={() => dismiss(n.id)}
                    >
                        <span aria-hidden="true">×</span>
                    </button>
                </article>
            ))}
        </div>
    );
}
