import { beforeEach, describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import CarrierDetail from "./CarrierDetail";
import { ApiError } from "../../api";
import * as carriersApi from "../../api/carriers";
import type { CarrierDetail as CarrierDetailDto } from "../../api/carriers";
import * as reviewsApi from "../../api/reviews";
import type { Review } from "../../api/reviews";
import { AuthContext, type AuthState } from "../../auth/AuthContext";

vi.mock("../../api/carriers", async (orig) => {
    const actual = await orig<typeof carriersApi>();
    return {
        ...actual,
        getCarrier: vi.fn(),
    };
});

vi.mock("../../api/reviews", async (orig) => {
    const actual = await orig<typeof reviewsApi>();
    return {
        ...actual,
        listCarrierReviews: vi.fn(),
    };
});

const authStub: AuthState = {
    me: { id: 1, email: "shipper@test.com", roles: ["shipper"] },
    loading: false,
    register: vi.fn(),
    login: vi.fn(),
    logout: vi.fn(),
    updateMe: vi.fn(),
};

const guestAuth: AuthState = {
    me: null,
    loading: false,
    register: vi.fn(),
    login: vi.fn(),
    logout: vi.fn(),
    updateMe: vi.fn(),
};

function renderAt(url: string, auth: AuthState = guestAuth) {
    return render(
        <MemoryRouter initialEntries={[url]}>
            <AuthContext.Provider value={auth}>
                <Routes>
                    <Route path="/carriers/:id" element={<CarrierDetail />} />
                </Routes>
            </AuthContext.Provider>
        </MemoryRouter>,
    );
}

function fakeCarrier(over: Partial<CarrierDetailDto> = {}): CarrierDetailDto {
    return {
        id: 42,
        legal_name: "Transportes Andinos SRL",
        tax_id: "30700000001",
        base_city: "Mendoza",
        province: "Mendoza",
        description: "Flota especializada en cargas frágiles.",
        rating_avg: "4.50",
        reviews_count: 12,
        completed_shipments: 24,
        vehicles: [
            {
                id: 1,
                carrier_id: 42,
                make: "Mercedes-Benz",
                model: "Sprinter",
                year: 2021,
                plate: "AB123CD",
                vehicle_type: "truck_small",
                max_load_kg: "3500.00",
                length_cm: 500,
                width_cm: 200,
                height_cm: 220,
                volume_cm3: 22_000_000,
                gps_enabled: true,
                description: "Camión con cámara frigorífica",
                photos: [
                    { id: 9, thumbnail: "t.jpg", card: "c.jpg", full: "f.jpg" },
                ],
                created_at: "",
                updated_at: "",
            },
        ],
        transport_windows: [
            {
                id:                     7,
                vehicle_id:             1,
                origin_address:         "Av. Corrientes 1234, CABA",
                origin_locality:        "CABA",
                origin_admin_area:      "Buenos Aires",
                origin_lat:             "-34.603722",
                origin_lng:             "-58.381592",
                destination_address:    "Rosario",
                destination_locality:   "Rosario",
                destination_admin_area: "Santa Fe",
                destination_lat:        "-32.946820",
                destination_lng:        "-60.639317",
                pickup_radius_km:       10,
                dropoff_radius_km:      10,
                price_per_km:           "1500.50",
                max_km:                 1200,
                available_from:         "2026-06-01T00:00:00Z",
                available_to:           "2026-06-30T00:00:00Z",
                active:                 true,
            },
        ],
        created_at: "",
        updated_at: "",
        ...over,
    };
}

const sampleReviews: Review[] = [
    {
        id: 10,
        rating: 5,
        body: "Muy puntual y cuidadoso con la carga.",
        authored_by: "shipper",
        created_at: "2026-05-20T15:00:00Z",
    },
];

describe("CarrierDetail", () => {
    beforeEach(() => {
        vi.resetAllMocks();
        vi.mocked(reviewsApi.listCarrierReviews).mockResolvedValue({
            items: [],
            meta: { total: 0, page: 1, perPage: 10, totalPages: 1 },
        });
    });

    it("renders the hero with rating and reviews count", async () => {
        vi.mocked(carriersApi.getCarrier).mockResolvedValueOnce(fakeCarrier());
        renderAt("/carriers/42");

        expect(
            await screen.findByRole("heading", { name: /transportes andinos srl/i }),
        ).toBeInTheDocument();
        expect(screen.getByText(/4,50\/5/i)).toBeInTheDocument();
        expect(screen.getByText(/12 reseñas/i)).toBeInTheDocument();
        expect(screen.getByText(/24 viajes completados/i)).toBeInTheDocument();
    });

    it("renders the vehicle cards (photo + plate + capacity)", async () => {
        vi.mocked(carriersApi.getCarrier).mockResolvedValueOnce(fakeCarrier());
        renderAt("/carriers/42");

        expect(
            await screen.findByRole("img", { name: /foto de mercedes-benz sprinter/i }),
        ).toBeInTheDocument();
        expect(screen.getByText(/AB123CD/)).toBeInTheDocument();
        expect(screen.getByText(/3500\.00/)).toBeInTheDocument();
        // The duplicate "Galería de la flota" section was removed in favour of
        // a single Vehicles section — guard the regression.
        expect(screen.queryByText(/galería de la flota/i)).toBeNull();
    });

    it("renders transport windows with price per km", async () => {
        vi.mocked(carriersApi.getCarrier).mockResolvedValueOnce(fakeCarrier());
        renderAt("/carriers/42");

        expect(await screen.findByText(/CABA, Buenos Aires → Rosario, Santa Fe/i)).toBeInTheDocument();
        expect(screen.getByText(/\$1500\.50 \/ km/)).toBeInTheDocument();
    });

    it("renders locality, admin_area on both sides of the route", async () => {
        vi.mocked(carriersApi.getCarrier).mockResolvedValueOnce(
            fakeCarrier({
                transport_windows: [
                    {
                        id:                     7,
                        vehicle_id:             1,
                        origin_address:         "Av. Corrientes 1234, CABA",
                        origin_locality:        "CABA",
                        origin_admin_area:      "Buenos Aires",
                        origin_lat:             "-34.603722",
                        origin_lng:             "-58.381592",
                        destination_address:    "Córdoba Capital",
                        destination_locality:   "Córdoba Capital",
                        destination_admin_area: "Córdoba",
                        destination_lat:        "-31.420083",
                        destination_lng:        "-64.188776",
                        pickup_radius_km:       10,
                        dropoff_radius_km:      10,
                        price_per_km:           "1500.50",
                        max_km:                 1200,
                        available_from:         "2026-06-01T00:00:00Z",
                        available_to:           "2026-06-30T00:00:00Z",
                        active:                 true,
                    },
                ],
            }),
        );
        renderAt("/carriers/42");

        expect(
            await screen.findByText(/CABA, Buenos Aires → Córdoba Capital, Córdoba/i),
        ).toBeInTheDocument();
    });

    it("shows a not-found state when the API returns 404", async () => {
        vi.mocked(carriersApi.getCarrier).mockRejectedValueOnce(
            new ApiError(404, "Recurso no encontrado", "not_found"),
        );
        renderAt("/carriers/999");

        expect(await screen.findByText(/transportista no encontrado/i)).toBeInTheDocument();
    });

    it("renders a vehicle card without a photo by falling back to the truck glyph", async () => {
        const carrier = fakeCarrier({
            vehicles: [
                {
                    ...fakeCarrier().vehicles[0],
                    photos: [],
                },
            ],
        });
        vi.mocked(carriersApi.getCarrier).mockResolvedValueOnce(carrier);
        renderAt("/carriers/42");

        expect(
            await screen.findByRole("heading", { name: /mercedes-benz sprinter/i }),
        ).toBeInTheDocument();
        // No <img> rendered without photos; the placeholder is aria-hidden.
        expect(screen.queryByRole("img", { name: /foto de mercedes-benz/i })).toBeNull();
    });

    it("renders the open-destination label for open-destination transport windows", async () => {
        vi.mocked(carriersApi.getCarrier).mockResolvedValueOnce(
            fakeCarrier({
                transport_windows: [
                    {
                        id:                     8,
                        vehicle_id:             1,
                        origin_address:         "Av. Corrientes 1234, CABA",
                        origin_locality:        "CABA",
                        origin_admin_area:      "Buenos Aires",
                        origin_lat:             "-34.603722",
                        origin_lng:             "-58.381592",
                        destination_address:    null,
                        destination_locality:   null,
                        destination_admin_area: null,
                        destination_lat:        null,
                        destination_lng:        null,
                        pickup_radius_km:       10,
                        dropoff_radius_km:      null,
                        price_per_km:           "1200.00",
                        max_km:                 800,
                        available_from:         "2026-06-01T00:00:00Z",
                        available_to:           "2026-06-30T00:00:00Z",
                        active:                 true,
                    },
                ],
            }),
        );
        renderAt("/carriers/42");

        expect(await screen.findByText(/CABA, Buenos Aires → Cualquier destino/i)).toBeInTheDocument();
    });

    it("shows review cards when the viewer is authenticated", async () => {
        vi.mocked(carriersApi.getCarrier).mockResolvedValueOnce(fakeCarrier());
        vi.mocked(reviewsApi.listCarrierReviews).mockResolvedValue({
            items: sampleReviews,
            meta: { total: 1, page: 1, perPage: 10, totalPages: 1 },
        });
        renderAt("/carriers/42", authStub);

        expect(await screen.findByText(/muy puntual y cuidadoso/i)).toBeInTheDocument();
        expect(screen.getByText(/5\/5/i)).toBeInTheDocument();
        expect(reviewsApi.listCarrierReviews).toHaveBeenCalledWith(42, 1, expect.any(Object));
    });

    it("shows the empty reviews message when authenticated and there are none", async () => {
        vi.mocked(carriersApi.getCarrier).mockResolvedValueOnce(
            fakeCarrier({ rating_avg: null, reviews_count: 0 }),
        );
        renderAt("/carriers/42", authStub);

        expect(
            await screen.findByText(/todavía no hay reseñas de expedidores/i),
        ).toBeInTheDocument();
    });

    it("prompts sign-in for reviews when the visitor is not authenticated", async () => {
        vi.mocked(carriersApi.getCarrier).mockResolvedValueOnce(fakeCarrier());
        renderAt("/carriers/42");

        expect(
            await screen.findByText(/iniciá sesión para leer las reseñas/i),
        ).toBeInTheDocument();
        expect(reviewsApi.listCarrierReviews).not.toHaveBeenCalled();
    });

    it("falls back to descriptionFallback when the carrier has no description", async () => {
        vi.mocked(carriersApi.getCarrier).mockResolvedValueOnce(
            fakeCarrier({ description: null }),
        );
        renderAt("/carriers/42");

        expect(
            await screen.findByText(/todavía no escribió una descripción/i),
        ).toBeInTheDocument();
    });
});
