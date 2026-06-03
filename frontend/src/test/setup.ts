import * as matchers from "@testing-library/jest-dom/matchers";
import { cleanup } from "@testing-library/react";
import { afterAll, afterEach, beforeAll, expect, vi } from "vitest";
import { server } from "./mocks/server";

// happy-dom has no WebSocket constructor, so the real Action Cable consumer
// blows up the moment a logged-in test mounts NotificationsProvider. Globally
// stub @rails/actioncable to an inert consumer — the notification specs inject
// their own fake consumerFactory and never touch this mock.
vi.mock("@rails/actioncable", () => ({
    createConsumer: () => ({
        subscriptions: {
            create: () => ({ unsubscribe() {}, perform() {}, send() {} }),
        },
        connect() {},
        disconnect() {},
        url: "",
    }),
    createWebSocketURL: (url: unknown) => String(url),
    getConfig: () => undefined,
}));

expect.extend(matchers);

beforeAll(() => server.listen({ onUnhandledRequest: "error" }));
beforeEach(() => {
    // Reset to base handlers before each test so a server.use() override
    // from a concurrent worker (Vitest threads share the MSW interceptor)
    // cannot bleed into the next test's anonymous/unauthenticated scenario.
    server.resetHandlers();
    window.localStorage.clear();
});
afterEach(() => {
    cleanup();
    server.resetHandlers();
    window.localStorage.clear();
});
afterAll(() => server.close());
