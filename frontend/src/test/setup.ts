import * as matchers from "@testing-library/jest-dom/matchers";
import { cleanup } from "@testing-library/react";
import { afterAll, afterEach, beforeAll, expect } from "vitest";
import { server } from "./mocks/server";

expect.extend(matchers);

beforeAll(() => server.listen({ onUnhandledRequest: "error" }));
afterEach(() => {
    cleanup();
    server.resetHandlers();
    // Stateless JWT lives in localStorage — clear between tests so an
    // authenticated case doesn't leak into the next anonymous one.
    window.localStorage.clear();
});
afterAll(() => server.close());
