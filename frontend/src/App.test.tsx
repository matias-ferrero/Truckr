import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import LandingPage from "./App";
import { landingContent } from "./landingContent";

describe("LandingPage", () => {
    it("renders hero copy from landingContent", () => {
        render(<LandingPage />);
        expect(
            screen.getByRole("heading", { name: landingContent.hero.title }),
        ).toBeInTheDocument();
        expect(
            screen.getByText(new RegExp(landingContent.hero.subtitle, "i")),
        ).toBeInTheDocument();
    });

    it("renders every feature", () => {
        render(<LandingPage />);
        for (const feature of landingContent.features) {
            expect(
                screen.getByRole("heading", { name: feature.title }),
            ).toBeInTheDocument();
        }
    });

    it("shows validation errors when the quote form is submitted empty", async () => {
        const user = userEvent.setup();
        render(<LandingPage />);

        const submit = screen.getByRole("button", { name: /enviar solicitud/i });
        await user.click(submit);

        expect(
            screen.getByText(/Decinos desde dónde sale el envío/i),
        ).toBeInTheDocument();
        expect(
            screen.getByText(/Decinos a dónde llega el envío/i),
        ).toBeInTheDocument();
    });
});
