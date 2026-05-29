import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter } from "react-router-dom";
import VehicleList from "./VehicleList";
import * as vehiclesApi from "../../api/vehicles";

vi.mock("../../api/vehicles");

// jsdom doesn't implement HTMLDialogElement showModal/close, so polyfill
// just enough to assert the open state without crashing.
beforeEach(() => {
    if (!HTMLDialogElement.prototype.showModal) {
        HTMLDialogElement.prototype.showModal = function () {
            this.setAttribute("open", "");
        };
        HTMLDialogElement.prototype.close = function () {
            this.removeAttribute("open");
        };
    }
});

const fakeVehicle = (over: Partial<vehiclesApi.Vehicle> = {}): vehiclesApi.Vehicle => ({
    id: 1,
    carrier_id: 1,
    make: "MB",
    model: "Sprinter",
    year: 2022,
    plate: "AAA111",
    vehicle_type: "truck_small",
    max_load_kg: "3500.00",
    length_cm: 500,
    width_cm: 200,
    height_cm: 220,
    volume_cm3: 22_000_000,
    gps_enabled: false,
    description: "",
    photos: [],
    created_at: "",
    updated_at: "",
    ...over,
});

describe("VehicleList", () => {
    beforeEach(() => {
        vi.resetAllMocks();
    });

    it("renders the empty state when there are no vehicles", async () => {
        vi.mocked(vehiclesApi.listMyVehicles).mockResolvedValueOnce({
            items: [],
            meta: { total: 0, page: 1, perPage: 20, totalPages: 1 },
        });
        render(<MemoryRouter><VehicleList /></MemoryRouter>);
        expect(await screen.findByText(/todavía no agregaste vehículos/i)).toBeInTheDocument();
    });

    it("renders cards for each vehicle", async () => {
        vi.mocked(vehiclesApi.listMyVehicles).mockResolvedValueOnce({
            items: [fakeVehicle({ id: 1, plate: "AAA111" }), fakeVehicle({ id: 2, plate: "BBB222" })],
            meta: { total: 2, page: 1, perPage: 20, totalPages: 1 },
        });
        render(<MemoryRouter><VehicleList /></MemoryRouter>);
        expect(await screen.findByText(/AAA111/)).toBeInTheDocument();
        expect(await screen.findByText(/BBB222/)).toBeInTheDocument();
    });

    it("calls deleteVehicle when the user confirms discard in the dialog", async () => {
        vi.mocked(vehiclesApi.listMyVehicles).mockResolvedValueOnce({
            items: [fakeVehicle({ id: 7 })],
            meta: { total: 1, page: 1, perPage: 20, totalPages: 1 },
        });
        vi.mocked(vehiclesApi.deleteVehicle).mockResolvedValueOnce(undefined);
        vi.mocked(vehiclesApi.listMyVehicles).mockResolvedValueOnce({
            items: [],
            meta: { total: 0, page: 1, perPage: 20, totalPages: 1 },
        });

        render(<MemoryRouter><VehicleList /></MemoryRouter>);
        const user = userEvent.setup();
        const deleteBtn = await screen.findByRole("button", { name: /^dar de baja$/i });
        await user.click(deleteBtn);

        const dialog = await screen.findByRole("dialog");
        const confirmBtn = within(dialog).getByRole("button", { name: /^dar de baja$/i });
        await user.click(confirmBtn);

        await waitFor(() => expect(vehiclesApi.deleteVehicle).toHaveBeenCalledWith(7));
        expect(await screen.findByText(/vehículo dado de baja/i)).toBeInTheDocument();
    });

    it("does not delete when the dialog is cancelled", async () => {
        vi.mocked(vehiclesApi.listMyVehicles).mockResolvedValue({
            items: [fakeVehicle({ id: 9 })],
            meta: { total: 1, page: 1, perPage: 20, totalPages: 1 },
        });
        vi.mocked(vehiclesApi.deleteVehicle).mockResolvedValue(undefined);

        render(<MemoryRouter><VehicleList /></MemoryRouter>);
        const user = userEvent.setup();
        const deleteBtn = await screen.findByRole("button", { name: /^dar de baja$/i });
        await user.click(deleteBtn);

        const dialog = await screen.findByRole("dialog");
        const cancelBtn = within(dialog).getByRole("button", { name: /cancelar/i });
        await user.click(cancelBtn);

        expect(vehiclesApi.deleteVehicle).not.toHaveBeenCalled();
    });

    it("shows a blocked banner with a Mis Ventanas link when active windows prevent discard", async () => {
        vi.mocked(vehiclesApi.listMyVehicles).mockResolvedValue({
            items: [fakeVehicle({ id: 11 })],
            meta: { total: 1, page: 1, perPage: 20, totalPages: 1 },
        });
        vi.mocked(vehiclesApi.deleteVehicle).mockRejectedValue({
            status: 422,
            body: {
                error: {
                    details: {
                        base: ["No podés dar de baja este vehículo porque todavía tiene ventanas activas."],
                    },
                },
            },
        });

        render(<MemoryRouter><VehicleList /></MemoryRouter>);
        const user = userEvent.setup();
        await user.click(await screen.findByRole("button", { name: /^dar de baja$/i }));
        await user.click(within(await screen.findByRole("dialog")).getByRole("button", { name: /^dar de baja$/i }));

        expect(await screen.findByRole("alert")).toHaveTextContent(/ventanas activas/i);
        expect(screen.getByRole("link", { name: /ir a mis ventanas/i })).toHaveAttribute("href", "/carrier/availability");
    });

    it("shows a blocked banner with a cargo-offers link when pending commitments prevent discard", async () => {
        vi.mocked(vehiclesApi.listMyVehicles).mockResolvedValue({
            items: [fakeVehicle({ id: 12 })],
            meta: { total: 1, page: 1, perPage: 20, totalPages: 1 },
        });
        vi.mocked(vehiclesApi.deleteVehicle).mockRejectedValue({
            status: 422,
            body: {
                error: {
                    details: {
                        base: ["No podés dar de baja este vehículo porque tiene ofertas o viajes pendientes."],
                    },
                },
            },
        });

        render(<MemoryRouter><VehicleList /></MemoryRouter>);
        const user = userEvent.setup();
        await user.click(await screen.findByRole("button", { name: /^dar de baja$/i }));
        await user.click(within(await screen.findByRole("dialog")).getByRole("button", { name: /^dar de baja$/i }));

        expect(await screen.findByRole("alert")).toHaveTextContent(/ofertas o viajes pendientes/i);
        expect(screen.getByRole("link", { name: /ir a la bandeja de ofertas/i })).toHaveAttribute("href", "/carrier/cargo-offers");
    });
});
