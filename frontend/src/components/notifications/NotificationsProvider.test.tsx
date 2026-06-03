import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { act, cleanup, render, screen } from "@testing-library/react";
import type { Consumer, SubscriptionMixin } from "@rails/actioncable";
import type { Me } from "../../auth/AuthContext";

// Controllable auth state — the provider only reads `me`.
let mockMe: Me | null = null;
vi.mock("../../auth/useCurrentUser", () => ({
    useCurrentUser: () => ({ me: mockMe }),
}));

import { NotificationsProvider, useNotifications, type ConsumerFactory } from "./NotificationsProvider";

const USER: Me = { id: 7, email: "u@truckr.test", roles: ["shipper"] };

// A fake Action Cable consumer that records lifecycle calls and lets the test
// drive the subscription callbacks (connected / rejected / received).
function makeFakeCable() {
    const handlers: SubscriptionMixin = {};
    const subscription = { unsubscribe: vi.fn(), perform: vi.fn(), send: vi.fn() };
    const consumer = {
        subscriptions: {
            create: vi.fn((_channel: unknown, mixin: SubscriptionMixin) => {
                Object.assign(handlers, mixin);
                return subscription;
            }),
        },
        disconnect: vi.fn(),
        connect: vi.fn(),
        url: "ws://test/cable",
    };
    const factory: ConsumerFactory = vi.fn(() => consumer as unknown as Consumer);
    return { handlers, subscription, consumer, factory };
}

// Surfaces the context for assertions and exposes the hook contract.
function Probe() {
    const ctx = useNotifications();
    return (
        <div>
            <span data-testid="contract">
                {["notifications", "dismiss", "clear"].every((k) => k in ctx) ? "ok" : "missing"}
            </span>
            <span data-testid="count">{ctx.notifications.length}</span>
            <span data-testid="connected">{String(ctx.connected)}</span>
        </div>
    );
}

beforeEach(() => {
    mockMe = null;
});

afterEach(() => {
    cleanup();
    vi.clearAllMocks();
});

describe("NotificationsProvider", () => {
    it("does not open a subscription while logged out", () => {
        const cable = makeFakeCable();
        render(
            <NotificationsProvider consumerFactory={cable.factory}>
                <Probe />
            </NotificationsProvider>,
        );
        expect(cable.factory).not.toHaveBeenCalled();
    });

    it("opens the personal-channel subscription once authenticated", () => {
        mockMe = USER;
        const cable = makeFakeCable();
        render(
            <NotificationsProvider consumerFactory={cable.factory}>
                <Probe />
            </NotificationsProvider>,
        );
        expect(cable.factory).toHaveBeenCalledTimes(1);
        expect(cable.consumer.subscriptions.create).toHaveBeenCalledWith(
            "NotificationsChannel",
            expect.any(Object),
        );
    });

    it("exposes the { notifications, dismiss, clear } contract", () => {
        mockMe = USER;
        const cable = makeFakeCable();
        render(
            <NotificationsProvider consumerFactory={cable.factory}>
                <Probe />
            </NotificationsProvider>,
        );
        expect(screen.getByTestId("contract")).toHaveTextContent("ok");
    });

    it("adds an incoming known notification to the history and tracks connection", () => {
        mockMe = USER;
        const cable = makeFakeCable();
        render(
            <NotificationsProvider consumerFactory={cable.factory}>
                <Probe />
            </NotificationsProvider>,
        );

        act(() => cable.handlers.connected?.());
        expect(screen.getByTestId("connected")).toHaveTextContent("true");

        act(() => cable.handlers.received?.({ type: "ping", payload: { message: "hi" } }));
        expect(screen.getByTestId("count")).toHaveTextContent("1");
    });

    it("ignores messages with an unknown type", () => {
        mockMe = USER;
        const cable = makeFakeCable();
        render(
            <NotificationsProvider consumerFactory={cable.factory}>
                <Probe />
            </NotificationsProvider>,
        );
        act(() => cable.handlers.received?.({ type: "not_a_type", payload: {} }));
        expect(screen.getByTestId("count")).toHaveTextContent("0");
    });

    it("tears down the subscription and clears history on logout", () => {
        mockMe = USER;
        const cable = makeFakeCable();
        const { rerender } = render(
            <NotificationsProvider consumerFactory={cable.factory}>
                <Probe />
            </NotificationsProvider>,
        );
        act(() => cable.handlers.received?.({ type: "ping", payload: {} }));
        expect(screen.getByTestId("count")).toHaveTextContent("1");

        // Log out and re-render: the effect tears down, history clears.
        mockMe = null;
        rerender(
            <NotificationsProvider consumerFactory={cable.factory}>
                <Probe />
            </NotificationsProvider>,
        );
        expect(cable.subscription.unsubscribe).toHaveBeenCalled();
        expect(cable.consumer.disconnect).toHaveBeenCalled();
        expect(screen.getByTestId("count")).toHaveTextContent("0");
    });

    it("retries exactly once on a rejected upgrade, then degrades to disconnected", () => {
        mockMe = USER;
        const cable = makeFakeCable();
        render(
            <NotificationsProvider consumerFactory={cable.factory}>
                <Probe />
            </NotificationsProvider>,
        );
        expect(cable.factory).toHaveBeenCalledTimes(1);

        // First rejection → one reconnect (re-reads the JWT via the URL fn).
        act(() => cable.handlers.rejected?.());
        expect(cable.factory).toHaveBeenCalledTimes(2);

        // Second rejection → give up silently, no further reconnects (no loop).
        act(() => cable.handlers.rejected?.());
        expect(cable.factory).toHaveBeenCalledTimes(2);
        expect(screen.getByTestId("connected")).toHaveTextContent("false");
    });
});
