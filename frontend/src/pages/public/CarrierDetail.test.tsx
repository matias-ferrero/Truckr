import { beforeEach, describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import CarrierDetail from "./CarrierDetail";
import { ApiError } from "../../api";
import * as carriersApi from "../../api/carriers";
import type { CarrierDetail as CarrierDetailDto } from "../../api/carriers";
import { AuthProvider } from "../../auth/AuthContext";

vi.mock("../../api/carriers", async (orig) => {
    const actual = await orig<typeof carriersApi>();
    return {
        ...actual,
        getCarrier: vi.fn(),
    };
});

function renderAt(url: string) {
    return render(
        <MemoryRouter initialEntries={[url]}>
            <AuthProvider>
                <Routes>
                    <Route path="/carriers/:id" element={<CarrierDetail />} />
                </Routes>
            </AuthProvider>
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
                id: 7,
                vehicle_id: 1,
                origin_province: "Buenos Aires",
                origin_locality: null,
                destination_province: "Rosario",
                destination_locality: null,
                price_per_km: "1500.50",
                max_km: 1200,
                available_from: "2026-06-01T00:00:00Z",
                available_to: "2026-06-30T00:00:00Z",
                active: true,
            },
        ],
        created_at: "",
        updated_at: "",
        ...over,
    };
}

describe("CarrierDetail", () => {
    beforeEach(() => {
        vi.resetAllMocks();
    });

    it("renders the hero with rating and reviews count", async () => {
        vi.mocked(carriersApi.getCarrier).mockResolvedValueOnce(fakeCarrier());
        renderAt("/carriers/42");

        expect(
            await screen.findByRole("heading", { name: /transportes andinos srl/i }),
        ).toBeInTheDocument();
        expect(screen.getByText(/4\.50 sobre 5 · 12 reseñas/i)).toBeInTheDocument();
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

        expect(await screen.findByText(/buenos aires → rosario/i)).toBeInTheDocument();
        expect(screen.getByText(/\$1500\.50 \/ km/)).toBeInTheDocument();
    });

    it("renders province and locality in route when locality is present", async () => {
        vi.mocked(carriersApi.getCarrier).mockResolvedValueOnce(
            fakeCarrier({
                transport_windows: [
                    {
                        id: 7,
                        vehicle_id: 1,
                        origin_province: "Buenos Aires",
                        origin_locality: "CABA",
                        destination_province: "Córdoba",
                        destination_locality: "Córdoba Capital",
                        price_per_km: "1500.50",
                        max_km: 1200,
                        available_from: "2026-06-01T00:00:00Z",
                        available_to: "2026-06-30T00:00:00Z",
                        active: true,
                    },
                ],
            }),
        );
        renderAt("/carriers/42");

        expect(
            await screen.findByText(/Buenos Aires, CABA → Córdoba, Córdoba Capital/i),
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

    it("renders 'Destino abierto' for open-destination transport windows", async () => {
        vi.mocked(carriersApi.getCarrier).mockResolvedValueOnce(
            fakeCarrier({
                transport_windows: [
                    {
                        id: 8,
                        vehicle_id: 1,
                        origin_province: "Buenos Aires",
                        origin_locality: null,
                        destination_province: null,
                        destination_locality: null,
                        price_per_km: "1200.00",
                        max_km: 800,
                        available_from: "2026-06-01T00:00:00Z",
                        available_to: "2026-06-30T00:00:00Z",
                        active: true,
                    },
                ],
            }),
        );
        renderAt("/carriers/42");

        expect(await screen.findByText(/Buenos Aires → Destino abierto/i)).toBeInTheDocument();
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
