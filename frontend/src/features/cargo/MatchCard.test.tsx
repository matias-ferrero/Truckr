import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes, useLocation } from "react-router-dom";
import MatchCard from "./MatchCard";
import type { CargoMatch } from "../../types/Cargo";

function makeMatch(over: Partial<CargoMatch> = {}): CargoMatch {
    return {
        id: 5,
        origin_province: "Buenos Aires",
        origin_locality: null,
        destination_province: "Córdoba",
        destination_locality: null,
        price_per_km: "1500.0",
        max_km: 1000,
        available_from: "2026-05-25T00:00:00Z",
        available_to: "2026-06-10T00:00:00Z",
        vehicle: {
            id: 10,
            make: "Volvo",
            model: "FH",
            plate: "AB123CD",
            max_load_kg: "8000.0",
        },
        carrier: { id: 1, display_name: "Transportes del Sur", rating_avg: "4.7" },
        ...over,
    };
}

function LocationProbe() {
    const loc = useLocation();
    return <div data-testid="loc">{loc.pathname + loc.search}</div>;
}

function renderCard(match: CargoMatch, cargoId = 7) {
    return render(
        <MemoryRouter initialEntries={["/start"]}>
            <Routes>
                <Route
                    path="/start"
                    element={
                        <ul>
                            <MatchCard cargoId={cargoId} match={match} />
                        </ul>
                    }
                />
                <Route
                    path="/shipper/cargos/:id/offers/new"
                    element={<LocationProbe />}
                />
                <Route path="/carriers/:id" element={<LocationProbe />} />
            </Routes>
        </MemoryRouter>,
    );
}

describe("MatchCard", () => {
    it("renders the window route, carrier and capacity", () => {
        renderCard(makeMatch());
        expect(screen.getByText("Buenos Aires → Córdoba")).toBeInTheDocument();
        expect(
            screen.getByText("Transportista: Transportes del Sur"),
        ).toBeInTheDocument();
        expect(
            screen.getByText("Volvo FH · AB123CD"),
        ).toBeInTheDocument();
        expect(
            screen.getByText("Capacidad: 8000.0 kg"),
        ).toBeInTheDocument();
    });

    it("renders province and locality when locality is present", () => {
        renderCard(makeMatch({ origin_locality: "CABA", destination_locality: "Córdoba Capital" }));
        expect(screen.getByText("Buenos Aires, CABA → Córdoba, Córdoba Capital")).toBeInTheDocument();
    });

    it("falls back to a generic carrier label when display_name is null", () => {
        renderCard(
            makeMatch({
                carrier: { id: 1, display_name: null, rating_avg: "4.0" },
            }),
        );
        expect(screen.getByText("Transportista: Transportista")).toBeInTheDocument();
    });

    it("the whole card is a link into the cargo-scoped offer route", async () => {
        const user = userEvent.setup();
        renderCard(makeMatch(), 7);
        await user.click(
            screen.getByRole("link", { name: /Ofertar para el tramo/ }),
        );
        expect(screen.getByTestId("loc")).toHaveTextContent(
            "/shipper/cargos/7/offers/new?window=5",
        );
    });

    it("shows 'Destino abierto' when destination_province is null", () => {
        renderCard(makeMatch({ destination_province: null, destination_locality: null }));
        expect(screen.getByText("Buenos Aires → Destino abierto")).toBeInTheDocument();
    });

    it("includes a button to open the carrier public profile", async () => {
        const user = userEvent.setup();
        renderCard(makeMatch(), 7);
        await user.click(screen.getByRole("link", { name: /Ver perfil/i }));
        expect(screen.getByTestId("loc")).toHaveTextContent("/carriers/1");
    });
});
