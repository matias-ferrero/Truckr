import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { OpenInGmapsButton, buildGmapsUrl } from "./index";

const ORIGIN = { lat: -34.603722, lng: -58.381592 };
const DEST   = { lat: -31.420083, lng: -64.188776 };

describe("buildGmapsUrl", () => {
    it("builds the directions deep-link with origin and destination", () => {
        expect(buildGmapsUrl(ORIGIN, DEST)).toBe(
            "https://www.google.com/maps/dir/?api=1&origin=-34.603722,-58.381592&destination=-31.420083,-64.188776",
        );
    });

    it("rounds coordinates to 6 decimals (AC8)", () => {
        const url = buildGmapsUrl(
            { lat: -34.6037229876, lng: -58.3815921234 },
            { lat: -31.4200831234, lng: -64.1887769876 },
        );
        expect(url).toBe(
            "https://www.google.com/maps/dir/?api=1&origin=-34.603723,-58.381592&destination=-31.420083,-64.188777",
        );
        // No more than 6 fractional digits on any coordinate segment.
        for (const param of ["origin", "destination"]) {
            const val = new URL(url).searchParams.get(param)!;
            for (const part of val.split(",")) {
                expect((part.split(".")[1] ?? "").length).toBeLessThanOrEqual(6);
            }
        }
    });
});

describe("OpenInGmapsButton", () => {
    it("renders a link with the origin+destination deep-link href and the given label", () => {
        render(
            <OpenInGmapsButton
                origin={ORIGIN}
                destination={DEST}
                label="Ver ruta en Google Maps"
            />,
        );
        const link = screen.getByRole("link", { name: /ver ruta en google maps/i });
        expect(link).toHaveAttribute(
            "href",
            "https://www.google.com/maps/dir/?api=1&origin=-34.603722,-58.381592&destination=-31.420083,-64.188776",
        );
    });

    it("opens in a new tab with a safe rel (AC2)", () => {
        render(
            <OpenInGmapsButton
                origin={ORIGIN}
                destination={DEST}
                label="Ver ruta en Google Maps"
            />,
        );
        const link = screen.getByRole("link", { name: /ver ruta/i });
        expect(link).toHaveAttribute("target", "_blank");
        expect(link).toHaveAttribute("rel", "noopener noreferrer");
    });

    it("uses the explicit ariaLabel for screen readers when provided", () => {
        render(
            <OpenInGmapsButton
                origin={ORIGIN}
                destination={DEST}
                label="Ver ruta en Google Maps"
                ariaLabel="Ver ruta de Av. Corrientes 1234 a Av. Colón 500 en Google Maps, se abre en una pestaña nueva"
            />,
        );
        expect(
            screen.getByRole("link", { name: /ver ruta de av\. corrientes/i }),
        ).toBeInTheDocument();
    });
});
