import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import VehicleForm from "./VehicleForm";
import * as vehiclesApi from "../../api/vehicles";

vi.mock("../../api/vehicles");

describe("VehicleForm", () => {
    beforeEach(() => {
        vi.resetAllMocks();
    });

    function renderForm() {
        return render(
            <MemoryRouter initialEntries={["/carrier/vehicle/new"]}>
                <Routes>
                    <Route
                        path="/carrier/vehicle/new"
                        element={<VehicleForm mode="new" />}
                    />
                    <Route path="/carrier/vehicles" element={<div>Lista</div>} />
                </Routes>
            </MemoryRouter>,
        );
    }

    function renderEditForm(vehicleId = 7) {
        return render(
            <MemoryRouter initialEntries={[`/carrier/vehicle/${vehicleId}`]}>
                <Routes>
                    <Route
                        path="/carrier/vehicle/:id"
                        element={<VehicleForm mode="edit" />}
                    />
                    <Route path="/carrier/vehicles" element={<div>Lista</div>} />
                </Routes>
            </MemoryRouter>,
        );
    }

    it("submits a new vehicle with the captured fields", async () => {
        vi.mocked(vehiclesApi.createVehicle).mockResolvedValueOnce({
            id: 1,
            carrier_id: 1,
            make: "MB",
            model: "Sprinter",
            year: 2022,
            plate: "AB123CD",
            vehicle_type: "truck_small",
            max_load_kg: "3500",
            length_cm: 500,
            width_cm: 200,
            height_cm: 220,
            volume_cm3: 22_000_000,
            gps_enabled: false,
            description: "",
            photos: [],
            created_at: "",
            updated_at: "",
        });

        renderForm();
        const user = userEvent.setup();

        await user.type(screen.getByLabelText(/marca/i), "MB");
        await user.type(screen.getByLabelText(/modelo/i), "Sprinter");
        await user.type(screen.getByLabelText(/patente/i), "ab123cd");
        await user.type(screen.getByLabelText(/capacidad de carga/i), "3500");

        await user.click(screen.getByRole("button", { name: /agregar vehículo/i }));

        await waitFor(() => expect(vehiclesApi.createVehicle).toHaveBeenCalled());
        const [fd] = vi.mocked(vehiclesApi.createVehicle).mock.calls[0]!;
        expect(fd.get("vehicle[plate]")).toBe("AB123CD");
        expect(fd.get("vehicle[max_load_kg]")).toBe("3500");
    });

    it("displays the live volume preview when dimensions are set", async () => {
        renderForm();
        const user = userEvent.setup();
        await user.type(screen.getByLabelText(/largo/i), "100");
        await user.type(screen.getByLabelText(/ancho/i), "200");
        await user.type(screen.getByLabelText(/alto/i), "300");
        expect(await screen.findByText(/Volumen estimado/i)).toBeInTheDocument();
    });

    it("warns about plate format when input doesn't match", async () => {
        renderForm();
        const user = userEvent.setup();
        await user.type(screen.getByLabelText(/patente/i), "$$$");
        expect(await screen.findByText(/Patente esperada/i)).toBeInTheDocument();
    });

    it("locks the plate field in edit mode", async () => {
        vi.mocked(vehiclesApi.getMyVehicle).mockResolvedValueOnce({
            id: 7,
            carrier_id: 1,
            make: "Ford",
            model: "F-100",
            year: 2018,
            plate: "AB123CD",
            vehicle_type: "truck",
            max_load_kg: "1500",
            length_cm: 500,
            width_cm: 200,
            height_cm: 220,
            volume_cm3: 22_000_000,
            gps_enabled: true,
            description: null,
            photos: [],
            created_at: "",
            updated_at: "",
        });
        vi.mocked(vehiclesApi.updateVehicle).mockResolvedValueOnce({
            id: 7,
            carrier_id: 1,
            make: "Ford",
            model: "F-100",
            year: 2018,
            plate: "AB123CD",
            vehicle_type: "truck",
            max_load_kg: "1500",
            length_cm: 500,
            width_cm: 200,
            height_cm: 220,
            volume_cm3: 22_000_000,
            gps_enabled: true,
            description: null,
            photos: [],
            created_at: "",
            updated_at: "",
        });

        renderEditForm();
        expect(await screen.findByLabelText(/patente/i)).toBeDisabled();
        expect(screen.getByText(/no se puede modificar/i)).toBeInTheDocument();
    });
});
