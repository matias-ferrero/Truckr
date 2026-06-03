// Minimal type surface for @rails/actioncable (the package ships no .d.ts).
// Covers only what NotificationsProvider uses. The `url` accepted by
// createConsumer may be a function — it's re-evaluated on every (re)connect,
// which is how reconnection picks up the current JWT (INF-FE-00005).
declare module "@rails/actioncable" {
    export interface ChannelNameWithParams {
        channel: string;
        [key: string]: unknown;
    }

    export interface Subscription {
        unsubscribe(): void;
        perform(action: string, data?: object): void;
        send(data: object): boolean;
    }

    export interface SubscriptionMixin {
        initialized?(): void;
        connected?(): void;
        disconnected?(): void;
        rejected?(): void;
        received?(data: unknown): void;
    }

    export interface Subscriptions {
        create(
            channel: string | ChannelNameWithParams,
            mixin?: SubscriptionMixin,
        ): Subscription;
    }

    export interface Consumer {
        subscriptions: Subscriptions;
        connect(): void;
        disconnect(): void;
        readonly url: string;
    }

    export function createConsumer(url?: string | (() => string)): Consumer;
    export function createWebSocketURL(url: string | (() => string)): string;
    export function getConfig(name: string): string | undefined;
}
