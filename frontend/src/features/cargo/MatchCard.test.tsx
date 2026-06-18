import { describe, expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import MatchCard from "./MatchCard";
import type { MatchRow } from "./buildMatchesModel";
import type { CargoMatch } from "../../types/Cargo";

function makeMatch(over: Partial<CargoMatch> = {}): CargoMatch {
    return {
        id:                     5,
        origin_address:         "La Plata",
        origin_locality:        "La Plata",
        origin_admin_area:      "Buenos Aires",
        origin_lat:             "-34.921450",
        origin_lng:             "-57.954529",
        destination_address:    "Córdoba",
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
        carrier: {
            id:            1,
            display_name:  "Transportes del Sur",
            rating_avg:    "4.7",
            reviews_count: 5,
        },
        ...over,
    };
}

function makeRow(over: Partial<MatchRow> = {}): MatchRow {
    const match = over.match ?? makeMatch();
    return {
        match,
        totalPrice: 1_050_000,
        pricePerKm: Number(match.price_per_km),
        ratingAvg: Number(match.carrier.rating_avg),
        reviewsCount: match.carrier.reviews_count,
        isUnrated: match.carrier.reviews_count === 0,
        distanceToPickupKm: 52.3,
        pick: null,
        ...over,
    };
}

function renderCard(row: MatchRow) {
    return render(
        <MemoryRouter>
            <ul>
                <MatchCard cargoId={7} row={row} />
            </ul>
        </MemoryRouter>,
    );
}

describe("MatchCard", () => {
    it("leads with the total estimated price and the per-km rate", () => {
        renderCard(makeRow());
        expect(
            screen.getByLabelText(/Precio total estimado/),
        ).toHaveTextContent("1.050.000");
        expect(screen.getByText("$1.500/km")).toBeInTheDocument();
    });

    it("falls back to the per-km rate as headline without a total", () => {
        renderCard(makeRow({ totalPrice: null }));
        expect(screen.queryByLabelText(/Precio total estimado/)).toBeNull();
        expect(screen.getByText("$1.500/km")).toBeInTheDocument();
    });

    it("shows the trust chip with rating and review count", () => {
        renderCard(makeRow());
        expect(screen.getByText(/4,7/)).toBeInTheDocument();
        expect(screen.getByText("5 reseñas")).toBeInTheDocument();
    });

    it("renders the neutral nuevo chip for unrated carriers, never 0★", () => {
        const match = makeMatch({
            carrier: { id: 1, display_name: "Nuevo SRL", rating_avg: "0.0", reviews_count: 0 },
        });
        renderCard(makeRow({ match, isUnrated: true, ratingAvg: 0, reviewsCount: 0 }));
        expect(screen.getByText("Transportista nuevo")).toBeInTheDocument();
        expect(screen.getByText("Sin calificaciones todavía")).toBeInTheDocument();
        expect(screen.queryByText(/0,0/)).toBeNull();
    });

    it("demotes pickup date, distance and route to the meta strip", () => {
        renderCard(makeRow());
        // Regex, not a literal date: toLocaleDateString renders in the local
        // timezone, which differs between dev (UTC-3) and CI (UTC).
        expect(screen.getByText(/^Sale \d{2}\/\d{2}\/\d{2}$/)).toBeInTheDocument();
        expect(screen.getByText(/del retiro/)).toBeInTheDocument();
        expect(screen.getByText(/La Plata.*Córdoba/)).toBeInTheDocument();
    });

    it("omits the distance line when pickup coords are unavailable", () => {
        renderCard(makeRow({ distanceToPickupKm: null }));
        expect(screen.queryByText(/del retiro/)).toBeNull();
    });

    it("shows the pick badge when the row earned one", () => {
        renderCard(makeRow({ pick: "cheapest" }));
        expect(screen.getByText("Más barato")).toBeInTheDocument();
    });

    it("links to the carrier profile and the offer flow", () => {
        renderCard(makeRow());
        expect(
            screen.getByRole("link", { name: "Ver perfil" }),
        ).toHaveAttribute("href", "/carriers/1");
        expect(
            screen.getByRole("link", { name: /Enviar oferta a Transportes del Sur/ }),
        ).toHaveAttribute(
            "href",
            "/shipper/cargos/7/offers/new?window=5",
        );
    });
});
