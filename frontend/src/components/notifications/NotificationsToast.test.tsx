import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { act, cleanup, render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import type { Consumer, SubscriptionMixin } from "@rails/actioncable";
import type { Me } from "../../auth/AuthContext";

let mockMe: Me | null = null;
vi.mock("../../auth/useCurrentUser", () => ({
    useCurrentUser: () => ({ me: mockMe }),
}));

import { NotificationsProvider, type ConsumerFactory } from "./NotificationsProvider";
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

beforeEach(() => {
    mockMe = USER;
});
afterEach(() => {
    cleanup();
    vi.clearAllMocks();
});

describe("NotificationsToast", () => {
    it("renders nothing when there are no notifications", () => {
        const cable = makeFakeCable();
        render(<NotificationsProvider consumerFactory={cable.factory} />);
        expect(screen.queryByRole("region", { name: notificationsContent.toast.region })).toBeNull();
    });

    it("renders an incoming notification's title and body from the registry copy", () => {
        const cable = makeFakeCable();
        render(<NotificationsProvider consumerFactory={cable.factory} />);

        act(() => cable.handlers.received?.({ type: "ping", payload: {} }));

        expect(screen.getByText(landingContent.notifications.ping.title)).toBeInTheDocument();
        expect(screen.getByText(landingContent.notifications.ping.body)).toBeInTheDocument();
    });

    it("dismisses a toast when its close button is clicked", async () => {
        const user = userEvent.setup();
        const cable = makeFakeCable();
        render(<NotificationsProvider consumerFactory={cable.factory} />);

        act(() => cable.handlers.received?.({ type: "ping", payload: {} }));
        expect(screen.getByText(landingContent.notifications.ping.title)).toBeInTheDocument();

        await user.click(screen.getByRole("button", { name: notificationsContent.toast.dismiss }));
        expect(screen.queryByText(landingContent.notifications.ping.title)).toBeNull();
    });
});
