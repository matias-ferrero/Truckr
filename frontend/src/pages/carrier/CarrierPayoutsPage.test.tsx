import { render, screen, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { describe, it, expect, vi, beforeEach } from "vitest";
import { CarrierPayoutsPage } from "./CarrierPayoutsPage";
import * as api from "../../api/payouts";

vi.mock("../../api/payouts", () => ({
    listCarrierPayouts: vi.fn(),
}));

describe("CarrierPayoutsPage", () => {
    beforeEach(() => {
        vi.resetAllMocks();
    });

    it("renders the empty state when there are no payouts", async () => {
        vi.mocked(api.listCarrierPayouts).mockResolvedValueOnce([]);

        render(
            <MemoryRouter>
                <CarrierPayoutsPage />
            </MemoryRouter>
        );

        expect(document.querySelector("[aria-busy='true']")).toBeInTheDocument();

        await waitFor(() => {
            expect(document.querySelector("[aria-busy='true']")).not.toBeInTheDocument();
        });

        expect(screen.getByText("Todavía no recibiste pagos. Aparecerán aquí cuando entregues un envío.")).toBeInTheDocument();
    });

    it("renders the table with payout rows when payouts exist", async () => {
        vi.mocked(api.listCarrierPayouts).mockResolvedValueOnce([
            {
                id: 1,
                shipment_id: 100,
                origin: "CABA",
                destination: "Rosario",
                shipper_name: "Acme Corp",
                gross_amount_cents: 1000_00,
                commission_rate: "0.15",
                commission_cents: 150_00,
                amount_cents: 850_00,
                currency: "ARS",
                state: "paid",
                paid_at: "2024-01-01T12:00:00Z",
                created_at: "2024-01-01T12:00:00Z",
            },
        ]);

        render(
            <MemoryRouter>
                <CarrierPayoutsPage />
            </MemoryRouter>
        );

        await waitFor(() => {
            expect(screen.queryByRole("main", { busy: true })).not.toBeInTheDocument();
        });

        expect(screen.getByRole("table")).toBeInTheDocument();
        expect(screen.getByText("CABA → Rosario")).toBeInTheDocument();
        expect(screen.getByText("Acme Corp")).toBeInTheDocument();
        expect(screen.getByText(/\$\s*1\.000/)).toBeInTheDocument();
        expect(screen.getByText(/-\s*\$\s*150/)).toBeInTheDocument();
        expect(screen.getByText(/\$\s*850/)).toBeInTheDocument();
        expect(screen.getByText("Pagado")).toBeInTheDocument();
        expect(screen.getByText("Ver envío")).toHaveAttribute("href", "/carrier/shipments/100");
    });

    it("renders an error message when the fetch fails", async () => {
        vi.mocked(api.listCarrierPayouts).mockRejectedValueOnce(new Error("Network error"));

        render(
            <MemoryRouter>
                <CarrierPayoutsPage />
            </MemoryRouter>
        );

        await waitFor(() => {
            expect(document.querySelector("[aria-busy='true']")).not.toBeInTheDocument();
        });

        expect(screen.getByRole("alert")).toBeInTheDocument();
        expect(screen.getByText("No pudimos cargar tus pagos. Intentá de nuevo.")).toBeInTheDocument();
        expect(screen.queryByRole("table")).not.toBeInTheDocument();
    });
});
