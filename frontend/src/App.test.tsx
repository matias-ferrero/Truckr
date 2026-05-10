import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter } from "react-router-dom";
import LandingPage from "./App";
import { AuthProvider } from "./auth/AuthContext";
import { landingContent } from "./landingContent";

const renderLanding = () =>
    render(
        <MemoryRouter>
            <AuthProvider>
                <LandingPage />
            </AuthProvider>
        </MemoryRouter>,
    );

describe("LandingPage", () => {
    it("renders hero copy from landingContent", () => {
        renderLanding();
        expect(
            screen.getByRole("heading", { name: landingContent.hero.title }),
        ).toBeInTheDocument();
        expect(
            screen.getByText(new RegExp(landingContent.hero.subtitle, "i")),
        ).toBeInTheDocument();
    });

    it("renders every feature", () => {
        renderLanding();
        for (const feature of landingContent.features) {
            expect(
                screen.getByRole("heading", { name: feature.title }),
            ).toBeInTheDocument();
        }
    });

    it("shows validation errors when the quote form is submitted empty", async () => {
        const user = userEvent.setup();
        renderLanding();

        const submit = screen.getByRole("button", { name: /enviar solicitud/i });
        await user.click(submit);

        expect(
            screen.getByText(/Decinos desde dónde sale el envío/i),
        ).toBeInTheDocument();
        expect(
            screen.getByText(/Decinos a dónde llega el envío/i),
        ).toBeInTheDocument();
    });

    it("submits the quote happy path and shows the confirmation block", async () => {
        const user = userEvent.setup();
        renderLanding();

        await user.type(screen.getByLabelText(/origen/i), "CABA");
        await user.type(screen.getByLabelText(/destino/i), "Rosario");
        await user.type(screen.getByLabelText(/qué transportás|carga/i), "5 cajas");
        await user.type(screen.getByLabelText(/contacto|email|whatsapp/i), "ana@example.com");

        await user.click(screen.getByRole("button", { name: /enviar solicitud/i }));

        expect(await screen.findByText(/recibido\./i)).toBeInTheDocument();
        expect(screen.getByText(/CABA → Rosario/i)).toBeInTheDocument();
    });

    it("'Pedir otra' resets the quote confirmation back to the form", async () => {
        const user = userEvent.setup();
        renderLanding();

        await user.type(screen.getByLabelText(/origen/i), "CABA");
        await user.type(screen.getByLabelText(/destino/i), "Rosario");
        await user.type(screen.getByLabelText(/qué transportás|carga/i), "muebles");
        await user.type(screen.getByLabelText(/contacto|email|whatsapp/i), "ana@example.com");
        await user.click(screen.getByRole("button", { name: /enviar solicitud/i }));

        await user.click(await screen.findByRole("button", { name: /pedir otra/i }));

        expect(
            screen.getByRole("button", { name: /enviar solicitud/i }),
        ).toBeInTheDocument();
    });
});
