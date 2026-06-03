import {
    createContext,
    useCallback,
    useContext,
    useEffect,
    useMemo,
    useRef,
    useState,
    type ReactNode,
} from "react";
import { createConsumer, type Consumer } from "@rails/actioncable";
import { API_BASE_URL, getJwt } from "../../api";
import { useCurrentUser } from "../../auth/useCurrentUser";
import { isKnownNotificationType, notificationsRegistry, type NotificationType } from "./notificationsRegistry";
import { NotificationsToast } from "./NotificationsToast";

// Session-only history cap. Notifications are best-effort live delivery
// (ADR-013) — nothing is persisted, so we just keep the most recent N in
// memory for the badge panel.
const MAX_HISTORY = 50;

export interface AppNotification {
    id: string;
    type: NotificationType;
    title: string;
    body: string;
    receivedAt: number;
    read: boolean;
}

export interface NotificationsContextValue {
    notifications: AppNotification[];
    unreadCount: number;
    connected: boolean;
    dismiss: (id: string) => void;
    clear: () => void;
    markAllRead: () => void;
}

// Inert default so consumers (e.g. the header bell) render harmlessly when no
// provider is mounted — in the app the provider always wraps the router
// (routes.tsx), but isolated component tests render the header without it.
const INERT_VALUE: NotificationsContextValue = {
    notifications: [],
    unreadCount: 0,
    connected: false,
    dismiss: () => {},
    clear: () => {},
    markAllRead: () => {},
};

const NotificationsContext = createContext<NotificationsContextValue>(INERT_VALUE);

// A consumer factory lets tests inject a fake cable. The default builds a real
// Action Cable consumer whose URL is a *function* — re-evaluated on every
// (re)connect, so reconnection always carries the current JWT, not one cached
// at session start (INF-FE-00005 acceptance criteria).
export type ConsumerFactory = (urlFn: () => string) => Consumer;

const defaultConsumerFactory: ConsumerFactory = (urlFn) => createConsumer(urlFn);

function cableUrl(): string {
    // http(s)://host:3000  →  ws(s)://host:3000/cable?token=<jwt>
    const wsBase = API_BASE_URL.replace(/^http/i, "ws");
    const token = getJwt();
    const query = token ? `?token=${encodeURIComponent(token)}` : "";
    return `${wsBase}/cable${query}`;
}

let idCounter = 0;
function nextId(): string {
    idCounter += 1;
    return `n${idCounter}`;
}

function toNotification(data: unknown): AppNotification | null {
    if (typeof data !== "object" || data === null) return null;
    const { type, payload } = data as { type?: unknown; payload?: unknown };
    if (!isKnownNotificationType(type)) return null;

    const view = notificationsRegistry[type](payload);
    return {
        id: nextId(),
        type,
        title: view.title,
        body: view.body,
        receivedAt: Date.now(),
        read: false,
    };
}

export function NotificationsProvider({
    children,
    consumerFactory = defaultConsumerFactory,
}: {
    children: ReactNode;
    consumerFactory?: ConsumerFactory;
}) {
    const { me } = useCurrentUser();
    const [notifications, setNotifications] = useState<AppNotification[]>([]);
    const [connected, setConnected] = useState(false);
    // Bumped to force a single reconnect attempt after a rejected upgrade.
    const [reconnectNonce, setReconnectNonce] = useState(0);
    const rejectionsRef = useRef(0);

    const dismiss = useCallback((id: string) => {
        setNotifications((prev) => prev.filter((n) => n.id !== id));
    }, []);

    const clear = useCallback(() => setNotifications([]), []);

    const markAllRead = useCallback(() => {
        setNotifications((prev) => prev.map((n) => (n.read ? n : { ...n, read: true })));
    }, []);

    // Clear the session history when the user logs out.
    useEffect(() => {
        if (!me) {
            setNotifications([]);
            rejectionsRef.current = 0;
        }
    }, [me]);

    // Open the personal-channel subscription while authenticated; tear it down
    // on logout or unmount. Keyed on the user id so a re-login reconnects.
    useEffect(() => {
        if (!me) return;

        const consumer = consumerFactory(cableUrl);
        const subscription = consumer.subscriptions.create("NotificationsChannel", {
            connected: () => {
                rejectionsRef.current = 0; // a clean connect resets the retry budget
                setConnected(true);
            },
            disconnected: () => setConnected(false),
            rejected: () => {
                setConnected(false);
                // Auth rejected at the upgrade (e.g. expired JWT). Retry exactly
                // once — the URL function re-reads the (possibly refreshed)
                // token. A second rejection degrades to disconnected silently
                // rather than looping forever.
                if (rejectionsRef.current < 1) {
                    rejectionsRef.current += 1;
                    setReconnectNonce((n) => n + 1);
                }
            },
            received: (data: unknown) => {
                const notification = toNotification(data);
                if (!notification) return;
                setNotifications((prev) => [notification, ...prev].slice(0, MAX_HISTORY));
            },
        });

        return () => {
            subscription.unsubscribe();
            consumer.disconnect();
            setConnected(false);
        };
    }, [me?.id, reconnectNonce, consumerFactory]);

    const value = useMemo<NotificationsContextValue>(
        () => ({
            notifications,
            unreadCount: notifications.reduce((acc, n) => (n.read ? acc : acc + 1), 0),
            connected,
            dismiss,
            clear,
            markAllRead,
        }),
        [notifications, connected, dismiss, clear, markAllRead],
    );

    return (
        <NotificationsContext.Provider value={value}>
            {children}
            <NotificationsToast />
        </NotificationsContext.Provider>
    );
}

export function useNotifications(): NotificationsContextValue {
    return useContext(NotificationsContext);
}
