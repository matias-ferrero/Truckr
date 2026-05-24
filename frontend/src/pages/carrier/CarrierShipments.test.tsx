import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter } from "react-router-dom";
import CarrierShipments from "./CarrierShipments";
import * as shipmentsApi from "../../api/shipments";

vi.mock("../../api/shipments");

const mockedApi = vi.mocked(shipmentsApi);

function renderPage() {
    return render(
        <MemoryRouter>
            <CarrierShipments />
        </MemoryRouter>,
    );
}

beforeEach(() => {
    vi.resetAllMocks();
    mockedApi.listCarrierShipments.mockResolvedValue({
        items: [
            {
                id: 31,
                cargo_offer_id: 11,
                status: "pending_payment",
                accepted_at: "2026-06-11T10:00:00Z",
                picked_up_at: null,
                delivered_at: null,
                created_at: "2026-06-11T10:00:00Z",
                updated_at: "2026-06-11T10:00:00Z",
            },
        ],
        meta: { total: 1, page: 1, perPage: 20, totalPages: 1 },
    });
});

describe("CarrierShipments", () => {
    it("renders shipments list", async () => {
        renderPage();
        await waitFor(() => {
            expect(screen.getByRole("heading", { name: /mis viajes/i })).toBeInTheDocument();
            expect(screen.getByText(/Viaje #31/i)).toBeInTheDocument();
        });
    });

    it("changes filter and reloads", async () => {
        const user = userEvent.setup();
        renderPage();

        await waitFor(() => expect(mockedApi.listCarrierShipments).toHaveBeenCalled());
        await user.click(screen.getByRole("button", { name: /a recoger/i }));

        await waitFor(() => {
            expect(mockedApi.listCarrierShipments).toHaveBeenCalledWith("to_pick_up", 1);
        });
    });
});
