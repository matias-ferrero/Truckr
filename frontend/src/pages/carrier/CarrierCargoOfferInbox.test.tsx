import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter } from "react-router-dom";
import CarrierCargoOfferInbox from "./CarrierCargoOfferInbox";
import * as carrierOffersApi from "../../api/carrierCargoOffers";

vi.mock("../../api/carrierCargoOffers");

const mockedApi = vi.mocked(carrierOffersApi);

function makeOffer(overrides: Partial<carrierOffersApi.CarrierCargoOffer> = {}): carrierOffersApi.CarrierCargoOffer {
    return {
        id: 11,
        cargo_id: 7,
        carrier_id: 1,
        transport_window_id: 5,
        status: "pending",
        expires_at: "2026-06-15T12:00:00Z",
        accepted_at: null,
        rejected_at: null,
        created_at: "2026-06-10T10:00:00Z",
        updated_at: "2026-06-10T10:00:00Z",
        price_amount_cents: 105_000_000,
        cargo: {
            id: 7,
            pickup_address: "Av. Corrientes 1234, CABA",
            delivery_address: "Av. Colón 500, Córdoba",
            weight_kg: "1500.0",
            volume_cm3: 3_000_000,
            declared_value_cents: 5_000_000,
            pickup_window_start: "2026-06-12T08:00:00Z",
            pickup_window_end: "2026-06-13T18:00:00Z",
            cargo_description: "Pallets",
            status: "open",
        },
        shipper: { id: 1, name: "Test User" },
        transport_window: {
            id: 5,
            origin_locality: "CABA",
            origin_admin_area: "Buenos Aires",
            destination_locality: "Córdoba",
            destination_admin_area: "Córdoba",
            available_from: "2026-06-11T08:00:00Z",
            available_to: "2026-06-16T18:00:00Z",
            price_per_km: "1500.0",
            max_km: 1000,
            status: "pending_offer",
        },
        ...overrides,
    };
}

function renderPage() {
    return render(
        <MemoryRouter>
            <CarrierCargoOfferInbox />
        </MemoryRouter>,
    );
}

beforeEach(() => {
    vi.resetAllMocks();
    mockedApi.listCarrierCargoOffers.mockResolvedValue({
        items: [makeOffer()],
        meta: { total: 1, page: 1, perPage: 20, totalPages: 1 },
    });
});

describe("CarrierCargoOfferInbox", () => {
    it("renders pending offers", async () => {
        renderPage();

        await waitFor(() => {
            expect(screen.getByRole("heading", { name: /ofertas recibidas/i })).toBeInTheDocument();
            expect(screen.getByRole("heading", { name: /Av\. Corrientes 1234/i })).toBeInTheDocument();
        });
    });

    it("accepts an offer after confirmation", async () => {
        const user = userEvent.setup();
        mockedApi.acceptCarrierCargoOffer.mockResolvedValue({
            cargo_offer: makeOffer({ status: "accepted", accepted_at: "2026-06-11T10:00:00Z" }),
            shipment: {
                id: 31,
                cargo_offer_id: 11,
                status: "accepted",
                accepted_at: "2026-06-11T10:00:00Z",
                picked_up_at: null,
                delivered_at: null,
                created_at: "2026-06-11T10:00:00Z",
                updated_at: "2026-06-11T10:00:00Z",
            },
        });

        renderPage();

        await waitFor(() => expect(screen.getByRole("button", { name: /aceptar/i })).toBeInTheDocument());
        await user.click(screen.getByRole("button", { name: /aceptar/i }));
        await user.click(screen.getByRole("button", { name: /confirmar aceptación/i }));

        await waitFor(() => {
            expect(mockedApi.acceptCarrierCargoOffer).toHaveBeenCalledWith(11);
            expect(screen.getByText(/oferta aceptada/i)).toBeInTheDocument();
        });
    });

    it("rejects an offer after confirmation", async () => {
        const user = userEvent.setup();
        mockedApi.rejectCarrierCargoOffer.mockResolvedValue(
            makeOffer({ status: "rejected", rejected_at: "2026-06-11T10:00:00Z" }),
        );

        renderPage();

        await waitFor(() => expect(screen.getByRole("button", { name: /rechazar/i })).toBeInTheDocument());
        await user.click(screen.getByRole("button", { name: /rechazar/i }));
        await user.click(screen.getByRole("button", { name: /confirmar rechazo/i }));

        await waitFor(() => {
            expect(mockedApi.rejectCarrierCargoOffer).toHaveBeenCalledWith(11);
            expect(screen.getByText(/oferta rechazada/i)).toBeInTheDocument();
        });
    });
});
