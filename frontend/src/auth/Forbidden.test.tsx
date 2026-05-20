import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import Forbidden from "./Forbidden";

describe("Forbidden", () => {
    it("renders the 403 view with a heading and a way back home", () => {
        render(
            <MemoryRouter>
                <Forbidden />
            </MemoryRouter>,
        );
        expect(
            screen.getByRole("heading", {
                name: "No tenés acceso a esta página",
            }),
        ).toBeInTheDocument();
        expect(screen.getByText("403")).toBeInTheDocument();
        const back = screen.getByRole("link", { name: "Volver al panel" });
        expect(back).toHaveAttribute("href", "/");
    });

    it("exposes the panel as an alert region", () => {
        render(
            <MemoryRouter>
                <Forbidden />
            </MemoryRouter>,
        );
        expect(screen.getByRole("alert")).toBeInTheDocument();
    });
});
