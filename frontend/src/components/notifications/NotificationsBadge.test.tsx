import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { act, cleanup, render, screen, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { Consumer, SubscriptionMixin } from "@rails/actioncable";
import type { Me } from "../../auth/AuthContext";

let mockMe: Me | null = null;
vi.mock("../../auth/useCurrentUser", () => ({
    useCurrentUser: () => ({ me: mockMe }),
}));

import { NotificationsProvider, type ConsumerFactory } from "./NotificationsProvider";
import NotificationsBadge from "./NotificationsBadge";
import { landingContent } from "../../landingContent";
import { notificationsContent } from "./notificationsContent";

const USER: Me = { id: 1, email: "u@truckr.test", roles: ["shipper"] };

function makeFakeCable() {
    const handlers: SubscriptionMixin = {};
    const subscription = { unsubscribe: vi.fn(), perform: vi.fn(), send: vi.fn() };
    const consumer = {
        subscriptions: { create: vi.fn((_c: unknown, m: SubscriptionMixin) => (Object.assign(handlers, m), subscription)) },
        disconnect: vi.fn(),
        connect: vi.fn(),
        url: "ws://test/cable",
    };
    const factory: ConsumerFactory = vi.fn(() => consumer as unknown as Consumer);
    return { handlers, factory };
}

function renderBadge() {
    const cable = makeFakeCable();
    render(
        <NotificationsProvider consumerFactory={cable.factory}>
            <NotificationsBadge />
        </NotificationsProvider>,
    );
    return cable;
}

beforeEach(() => {
    mockMe = USER;
});
afterEach(() => {
    cleanup();
    vi.clearAllMocks();
});

describe("NotificationsBadge", () => {
    it("shows no count when there are no unread notifications", () => {
        renderBadge();
        // The accessible name falls back to the generic 'open' label.
        expect(screen.getByRole("button", { name: notificationsContent.badge.open })).toBeInTheDocument();
        expect(screen.queryByText("1")).toBeNull();
    });

    it("reflects the unread count from incoming notifications", () => {
        const cable = renderBadge();
        act(() => cable.handlers.received?.({ type: "ping", payload: {} }));
        act(() => cable.handlers.received?.({ type: "ping", payload: {} }));

        expect(
            screen.getByRole("button", { name: notificationsContent.badge.unreadAria(2) }),
        ).toBeInTheDocument();
    });

    it("opens the history panel on click, marks all read, and lists the session history", async () => {
        const user = userEvent.setup();
        const cable = renderBadge();
        act(() => cable.handlers.received?.({ type: "ping", payload: {} }));

        await user.click(screen.getByRole("button", { name: notificationsContent.badge.unreadAria(1) }));

        const panel = screen.getByRole("dialog", { name: notificationsContent.badge.panelTitle });
        expect(within(panel).getByText(landingContent.notifications.ping.title)).toBeInTheDocument();

        // Opening marks everything read → the count is gone from the trigger label.
        expect(
            screen.getByRole("button", { name: notificationsContent.badge.open }),
        ).toBeInTheDocument();
    });

    it("shows an empty state and supports clearing the history", async () => {
        const user = userEvent.setup();
        const cable = renderBadge();
        act(() => cable.handlers.received?.({ type: "ping", payload: {} }));

        await user.click(screen.getByRole("button", { name: notificationsContent.badge.unreadAria(1) }));
        await user.click(screen.getByRole("button", { name: notificationsContent.badge.clear }));

        const panel = screen.getByRole("dialog", { name: notificationsContent.badge.panelTitle });
        expect(within(panel).getByText(notificationsContent.badge.empty)).toBeInTheDocument();
    });
});
