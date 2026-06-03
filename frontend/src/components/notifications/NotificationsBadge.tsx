import { useCallback, useEffect, useRef, useState } from "react";
import { useNotifications } from "./NotificationsProvider";
import { notificationsContent } from "./notificationsContent";

// Header bell: shows the unread count and, on click, opens a panel listing the
// current session's notification history. Opening the panel marks everything
// read (clearing the count). Visual language matches the header pill/badge
// pattern from the carrier offers inbox (PR #194). Copy lives in
// notificationsContent — no hardcoded JSX strings.
export default function NotificationsBadge() {
    const { notifications, unreadCount, dismiss, clear, markAllRead } = useNotifications();
    const [open, setOpen] = useState(false);
    const containerRef = useRef<HTMLDivElement>(null);
    const text = notificationsContent.badge;

    const close = useCallback(() => setOpen(false), []);

    const toggle = useCallback(() => setOpen((wasOpen) => !wasOpen), []);

    // Opening the panel acknowledges everything, clearing the unread count.
    // Done in an effect (not inside the setOpen updater) to avoid triggering a
    // provider state update during this component's render.
    useEffect(() => {
        if (open) markAllRead();
    }, [open, markAllRead]);

    // Dismiss the panel on outside click / Escape for keyboard + pointer parity.
    useEffect(() => {
        if (!open) return;
        function onPointerDown(event: MouseEvent) {
            if (!containerRef.current?.contains(event.target as Node)) close();
        }
        function onKeyDown(event: KeyboardEvent) {
            if (event.key === "Escape") close();
        }
        document.addEventListener("mousedown", onPointerDown);
        document.addEventListener("keydown", onKeyDown);
        return () => {
            document.removeEventListener("mousedown", onPointerDown);
            document.removeEventListener("keydown", onKeyDown);
        };
    }, [open, close]);

    return (
        <div className="notifBadge" ref={containerRef}>
            <button
                type="button"
                className="notifBadgeButton"
                aria-label={unreadCount > 0 ? text.unreadAria(unreadCount) : text.open}
                aria-haspopup="dialog"
                aria-expanded={open}
                onClick={toggle}
            >
                <svg className="notifBadgeIcon" viewBox="0 0 24 24" aria-hidden="true" focusable="false">
                    <path
                        fill="none"
                        stroke="currentColor"
                        strokeWidth="1.7"
                        strokeLinecap="round"
                        strokeLinejoin="round"
                        d="M18 8a6 6 0 1 0-12 0c0 7-3 9-3 9h18s-3-2-3-9M13.7 21a2 2 0 0 1-3.4 0"
                    />
                </svg>
                {unreadCount > 0 && (
                    <span className="notifBadgeCount" aria-hidden="true">
                        {unreadCount}
                    </span>
                )}
            </button>

            {open && (
                <div className="notifPanel" role="dialog" aria-label={text.panelTitle}>
                    <div className="notifPanelHead">
                        <p className="notifPanelTitle">{text.panelTitle}</p>
                        {notifications.length > 0 && (
                            <button type="button" className="notifPanelClear" onClick={clear}>
                                {text.clear}
                            </button>
                        )}
                    </div>

                    {notifications.length === 0 ? (
                        <p className="notifPanelEmpty">{text.empty}</p>
                    ) : (
                        <ul className="notifPanelList">
                            {notifications.map((n) => (
                                <li key={n.id} className="notifPanelItem">
                                    <div className="notifPanelItemBody">
                                        <p className="notifPanelItemTitle">{n.title}</p>
                                        <p className="notifPanelItemText">{n.body}</p>
                                    </div>
                                    <button
                                        type="button"
                                        className="notifPanelItemClose"
                                        aria-label={notificationsContent.toast.dismiss}
                                        onClick={() => dismiss(n.id)}
                                    >
                                        <span aria-hidden="true">×</span>
                                    </button>
                                </li>
                            ))}
                        </ul>
                    )}
                </div>
            )}
        </div>
    );
}
