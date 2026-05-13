import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
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
    it("renders the editorial headline as the h1", () => {
        renderLanding();
        const h1 = screen.getByRole("heading", { level: 1 });
        expect(h1).toHaveTextContent(landingContent.hero.title);
    });

    it("renders supporting hero copy", () => {
        renderLanding();
        expect(screen.getByText(landingContent.hero.subtitle)).toBeInTheDocument();
        expect(screen.getByText(landingContent.hero.kicker)).toBeInTheDocument();
    });

    it("hero CTAs route to signup pre-tagged with the user's role", () => {
        renderLanding();
        const primary = screen.getByRole("link", {
            name: new RegExp(landingContent.hero.cta_primary, "i"),
        });
        const secondary = screen.getByRole("link", {
            name: new RegExp(landingContent.hero.cta_secondary, "i"),
        });
        expect(primary).toHaveAttribute("href", "/signup?role=shipper");
        expect(secondary).toHaveAttribute("href", "/signup?role=carrier");
    });

    it("audience card CTAs route to signup with the matching role", () => {
        renderLanding();
        const shipperCta = screen.getByRole("link", {
            name: new RegExp(landingContent.audiences.shipper.cta, "i"),
        });
        const carrierCta = screen.getByRole("link", {
            name: new RegExp(landingContent.audiences.carrier.cta, "i"),
        });
        expect(shipperCta).toHaveAttribute("href", "/signup?role=shipper");
        expect(carrierCta).toHaveAttribute("href", "/signup?role=carrier");
    });

    it("renders a final CTA band linking to signup and login", () => {
        renderLanding();
        const finalShipper = screen.getByRole("link", {
            name: new RegExp(landingContent.finalCta.shipper, "i"),
        });
        const finalCarrier = screen.getByRole("link", {
            name: new RegExp(landingContent.finalCta.carrier, "i"),
        });
        expect(finalShipper).toHaveAttribute("href", "/signup?role=shipper");
        expect(finalCarrier).toHaveAttribute("href", "/signup?role=carrier");
        const login = screen.getByRole("link", {
            name: new RegExp(landingContent.finalCta.loginLabel, "i"),
        });
        expect(login).toHaveAttribute("href", "/login");
    });

    it("renders every feature heading", () => {
        renderLanding();
        for (const feature of landingContent.features) {
            expect(
                screen.getByRole("heading", { name: feature.title }),
            ).toBeInTheDocument();
        }
    });

    it("renders both audience cards with their bullet lists", () => {
        renderLanding();
        expect(
            screen.getByRole("heading", { name: landingContent.audiences.shipper.title }),
        ).toBeInTheDocument();
        expect(
            screen.getByRole("heading", { name: landingContent.audiences.carrier.title }),
        ).toBeInTheDocument();
        for (const bullet of landingContent.audiences.shipper.bullets) {
            expect(screen.getByText(bullet)).toBeInTheDocument();
        }
        for (const bullet of landingContent.audiences.carrier.bullets) {
            expect(screen.getByText(bullet)).toBeInTheDocument();
        }
    });

    it("renders all three steps with both perspectives", () => {
        renderLanding();
        for (const step of landingContent.steps) {
            expect(
                screen.getByRole("heading", { name: step.title }),
            ).toBeInTheDocument();
            expect(screen.getByText(step.shipper)).toBeInTheDocument();
            expect(screen.getByText(step.carrier)).toBeInTheDocument();
        }
    });

    it("renders the three honest commitments", () => {
        renderLanding();
        for (const c of landingContent.commitments) {
            expect(
                screen.getByRole("heading", { name: c.title }),
            ).toBeInTheDocument();
            expect(screen.getByText(c.body)).toBeInTheDocument();
        }
    });

    it("does not render the removed quote widget", () => {
        renderLanding();
        expect(
            screen.queryByRole("heading", { name: /pedí una cotización/i }),
        ).not.toBeInTheDocument();
        expect(
            screen.queryByRole("button", { name: /enviar solicitud/i }),
        ).not.toBeInTheDocument();
    });

    it("exposes a 'cómo funciona' anchor linking to the steps section", () => {
        renderLanding();
        const link = screen.getAllByRole("link", { name: /cómo funciona/i })[0];
        expect(link).toHaveAttribute("href", "#como-funciona");
    });
});
