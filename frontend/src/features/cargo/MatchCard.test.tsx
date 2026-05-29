import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes, useLocation } from "react-router-dom";
import MatchCard from "./MatchCard";
import type { CargoMatch } from "../../types/Cargo";

function makeMatch(over: Partial<CargoMatch> = {}): CargoMatch {
    return {
        id:                     5,
        origin_address:         "Av. Corrientes 1234, CABA",
        origin_locality:        "CABA",
        origin_admin_area:      "Buenos Aires",
        origin_lat:             "-34.603722",
        origin_lng:             "-58.381592",
        destination_address:    "Av. Colón 500, Córdoba",
        destination_locality:   "Córdoba",
        destination_admin_area: "Córdoba",
        destination_lat:        "-31.420083",
        destination_lng:        "-64.188776",
        pickup_radius_km:       10,
        dropoff_radius_km:      10,
        price_per_km:           "1500.0",
        max_km:                 1000,
        available_from:         "2026-05-25T00:00:00Z",
        available_to:           "2026-06-10T00:00:00Z",
        active:                 true,
        vehicle: {
            id:          10,
            make:        "Volvo",
            model:       "FH",
            plate:       "AB123CD",
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

function renderCard(
    match: CargoMatch,
    cargoId = 7,
    pickup?: { lat: number; lng: number },
) {
    return render(
        <MemoryRouter initialEntries={["/start"]}>
            <Routes>
                <Route
                    path="/start"
                    element={
                        <ul>
                            <MatchCard
                                cargoId={cargoId}
                                match={match}
                                pickup={pickup}
                            />
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
        expect(screen.getByText("CABA, Buenos Aires → Córdoba, Córdoba")).toBeInTheDocument();
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

    it("renders locality only when admin_area is empty", () => {
        renderCard(makeMatch({ origin_admin_area: "", destination_admin_area: "" }));
        expect(screen.getByText("CABA → Córdoba")).toBeInTheDocument();
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

    it("shows the open-destination label when destination_lat is null", () => {
        renderCard(makeMatch({
            destination_address:    null,
            destination_locality:   null,
            destination_admin_area: null,
            destination_lat:        null,
            destination_lng:        null,
            dropoff_radius_km:      null,
        }));
        expect(screen.getByText("CABA, Buenos Aires → Cualquier destino")).toBeInTheDocument();
    });

    it("renders Haversine distance from cargo pickup when pickup coords are supplied", () => {
        // CABA pickup vs La Plata origin (~50–60 km) — same fixture pair the
        // backend Geo spec uses. Tolerate the exact rounded km because the
        // user-visible copy is what we care about, not the integer.
        renderCard(
            makeMatch({ origin_lat: "-34.921450", origin_lng: "-57.954529" }),
            7,
            { lat: -34.603722, lng: -58.381592 },
        );
        expect(screen.getByText(/^A \d+ km del retiro$/)).toBeInTheDocument();
    });

    it("hides the distance line when no pickup coords are supplied", () => {
        renderCard(makeMatch());
        expect(screen.queryByText(/del retiro/)).not.toBeInTheDocument();
    });

    it("includes a button to open the carrier public profile", async () => {
        const user = userEvent.setup();
        renderCard(makeMatch(), 7);
        await user.click(screen.getByRole("link", { name: /Ver perfil/i }));
        expect(screen.getByTestId("loc")).toHaveTextContent("/carriers/1");
    });
});
