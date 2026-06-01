import * as matchers from "@testing-library/jest-dom/matchers";
import { cleanup } from "@testing-library/react";
import { afterAll, afterEach, beforeAll, expect } from "vitest";
import { server } from "./mocks/server";

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
