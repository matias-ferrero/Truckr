import "@testing-library/jest-dom/vitest";
import { afterAll, afterEach, beforeAll } from "vitest";
import { cleanup } from "@testing-library/react";
import { server } from "./mocks/server";

beforeAll(() => server.listen({ onUnhandledRequest: "error" }));
afterEach(() => {
    cleanup();
    server.resetHandlers();
    // Stateless JWT lives in localStorage — clear between tests so an
    // authenticated case doesn't leak into the next anonymous one.
    window.localStorage.clear();
});
afterAll(() => server.close());
