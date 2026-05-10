import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import VehicleSelect from "./VehicleSelect";
import * as vehiclesApi from "../api/vehicles";

vi.mock("../api/vehicles");

const fake = (id: number, plate: string): vehiclesApi.Vehicle => ({
    id,
    carrier_id: 1,
    make: "MB",
    model: "Sprinter",
    year: 2022,
    plate,
    vehicle_type: "truck_small",
    max_load_kg: "3500",
    length_cm: null,
    width_cm: null,
    height_cm: null,
    volume_cm3: null,
    gps_enabled: false,
    description: "",
    photos: [],
    created_at: "",
    updated_at: "",
});

describe("VehicleSelect", () => {
    beforeEach(() => {
        vi.resetAllMocks();
    });

    it("auto-selects when there's exactly one vehicle", async () => {
        vi.mocked(vehiclesApi.listMyVehicles).mockResolvedValueOnce({
            items: [fake(7, "AAA111")],
            meta: { total: 1, page: 1, perPage: 20, totalPages: 1 },
        });
        const onChange = vi.fn();
        render(<VehicleSelect value={null} onChange={onChange} />);
        await waitFor(() => expect(onChange).toHaveBeenCalledWith(7));
    });

    it("does not auto-select when N > 1", async () => {
        vi.mocked(vehiclesApi.listMyVehicles).mockResolvedValueOnce({
            items: [fake(1, "AAA111"), fake(2, "BBB222")],
            meta: { total: 2, page: 1, perPage: 20, totalPages: 1 },
        });
        const onChange = vi.fn();
        render(<VehicleSelect value={null} onChange={onChange} />);
        const select = await screen.findByRole("combobox");
        expect(onChange).not.toHaveBeenCalled();
        const user = userEvent.setup();
        await user.selectOptions(select, "2");
        expect(onChange).toHaveBeenCalledWith(2);
    });

    it("shows the empty placeholder when the carrier has no vehicles", async () => {
        vi.mocked(vehiclesApi.listMyVehicles).mockResolvedValueOnce({
            items: [],
            meta: { total: 0, page: 1, perPage: 20, totalPages: 1 },
        });
        render(<VehicleSelect value={null} onChange={() => {}} />);
        expect(await screen.findByText(/todavía no tenés vehículos/i)).toBeInTheDocument();
    });
});
