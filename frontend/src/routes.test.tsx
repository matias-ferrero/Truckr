import { describe, expect, it } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import { AppRoutes } from "./routes";

/**
 * Smoke test that the BrowserRouter mounts and at least one route renders.
 * jsdom/happy-dom defaults the URL to "/" so we expect the landing.
 */
describe("AppRoutes", () => {
    it("renders the landing on /", async () => {
        render(<AppRoutes />);
        await waitFor(() =>
            expect(screen.getByRole("heading", { level: 1 })).toBeInTheDocument()
        );
    });
});
