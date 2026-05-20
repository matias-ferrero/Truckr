import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import TransportWindowForm from "./TransportWindowForm";
import * as twApi from "../../api/transport_windows";
import * as vehiclesApi from "../../api/vehicles";

vi.mock("../../api/transport_windows");
vi.mock("../../api/vehicles");
vi.mock("../../components/VehicleSelect", () => ({
    default: ({ onChange }: { onChange: (id: number) => void }) => (
        <select
            aria-label="Vehículo"
            onChange={(e) => onChange(Number(e.target.value))}
            defaultValue=""
        >
            <option value="">—</option>
            <option value="10">MB Sprinter — AA001XX</option>
        </select>
    ),
}));

const mockTwApi  = vi.mocked(twApi);
const mockVehApi = vi.mocked(vehiclesApi);

function makeWindow(overrides: Partial<twApi.TransportWindow> = {}): twApi.TransportWindow {
    return {
        id: 1,
        vehicle_id: 10,
        origin_zone: "Buenos Aires",
        destination_zone: "Córdoba",
        price_per_km: "1500.0",
        max_km: 1200,
        available_from: "2026-05-15T09:00:00.000Z",
        available_to: "2026-05-25T18:00:00.000Z",
        active: true,
        vehicle: { id: 10, make: "MB", model: "Sprinter", plate: "AA001XX", vehicle_type: "truck_small" },
        created_at: "2026-05-11T00:00:00.000Z",
        updated_at: "2026-05-11T00:00:00.000Z",
        ...overrides,
    };
}

function renderNewForm() {
    return render(
        <MemoryRouter initialEntries={["/carrier/availability/new"]}>
            <Routes>
                <Route path="/carrier/availability/new" element={<TransportWindowForm mode="new" />} />
                <Route path="/carrier/availability" element={<div>list</div>} />
            </Routes>
        </MemoryRouter>
    );
}

function renderEditForm(id = 1) {
    return render(
        <MemoryRouter initialEntries={[`/carrier/availability/${id}`]}>
            <Routes>
                <Route path="/carrier/availability/:id" element={<TransportWindowForm mode="edit" />} />
                <Route path="/carrier/availability" element={<div>list</div>} />
            </Routes>
        </MemoryRouter>
    );
}

beforeEach(() => {
    vi.resetAllMocks();
    mockVehApi.listMyVehicles?.mockResolvedValue?.({ items: [], meta: { total: 0, page: 1, perPage: 20, totalPages: 1 } });
});

describe("TransportWindowForm — new mode", () => {
    it("renders the create heading", () => {
        renderNewForm();
        expect(screen.getByRole("heading", { name: /nueva disponibilidad/i })).toBeInTheDocument();
    });

    it("shows all required fields", () => {
        renderNewForm();
        expect(screen.getByLabelText(/zona de origen/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/zona de destino/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/precio por km/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/kilómetros máximos/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/disponible desde/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/disponible hasta/i)).toBeInTheDocument();
    });

    it("calls createTransportWindow on submit and navigates to list", async () => {
        mockTwApi.createTransportWindow.mockResolvedValue(makeWindow());
        renderNewForm();

        await userEvent.selectOptions(screen.getByRole("combobox", { name: /vehículo/i }), "10");
        await userEvent.type(screen.getByLabelText(/zona de origen/i), "Buenos Aires");
        await userEvent.type(screen.getByLabelText(/zona de destino/i), "Córdoba");
        await userEvent.type(screen.getByLabelText(/precio por km/i), "1500");
        await userEvent.type(screen.getByLabelText(/kilómetros máximos/i), "1200");
        await userEvent.type(screen.getByLabelText(/disponible desde/i), "2026-06-01");
        await userEvent.type(screen.getByLabelText(/disponible hasta/i), "2026-06-30");

        await userEvent.click(screen.getByRole("button", { name: /publicar disponibilidad/i }));

        await waitFor(() => {
            expect(mockTwApi.createTransportWindow).toHaveBeenCalledOnce();
        });
        expect(screen.getByText("list")).toBeInTheDocument();
    });

    it("shows error panel when no vehicle is selected", async () => {
        renderNewForm();
        await userEvent.click(screen.getByRole("button", { name: /publicar disponibilidad/i }));
        await waitFor(() => {
            expect(screen.getByRole("alert")).toHaveTextContent(/vehículo/i);
        });
    });

    it("shows error when dates are empty on submit", async () => {
        renderNewForm();
        await userEvent.selectOptions(screen.getByRole("combobox", { name: /vehículo/i }), "10");
        await userEvent.type(screen.getByLabelText(/zona de origen/i), "Buenos Aires");
        await userEvent.type(screen.getByLabelText(/zona de destino/i), "Córdoba");
        await userEvent.type(screen.getByLabelText(/precio por km/i), "1500");
        await userEvent.type(screen.getByLabelText(/kilómetros máximos/i), "1200");
        // leave dates empty
        await userEvent.click(screen.getByRole("button", { name: /publicar disponibilidad/i }));
        await waitFor(() => {
            expect(screen.getByRole("alert")).toBeInTheDocument();
        });
        expect(mockTwApi.createTransportWindow).not.toHaveBeenCalled();
    });

    it("navigates with justSaved state after successful create", async () => {
        mockTwApi.createTransportWindow.mockResolvedValue(makeWindow());
        renderNewForm();

        await userEvent.selectOptions(screen.getByRole("combobox", { name: /vehículo/i }), "10");
        await userEvent.type(screen.getByLabelText(/zona de origen/i), "Buenos Aires");
        await userEvent.type(screen.getByLabelText(/zona de destino/i), "Córdoba");
        await userEvent.type(screen.getByLabelText(/precio por km/i), "1500");
        await userEvent.type(screen.getByLabelText(/kilómetros máximos/i), "1200");
        await userEvent.type(screen.getByLabelText(/disponible desde/i), "2026-06-01");
        await userEvent.type(screen.getByLabelText(/disponible hasta/i), "2026-06-30");

        await userEvent.click(screen.getByRole("button", { name: /publicar disponibilidad/i }));

        await waitFor(() => expect(screen.getByText("list")).toBeInTheDocument());
    });
});

describe("TransportWindowForm — edit mode", () => {
    it("hydrates form fields from the existing window", async () => {
        mockTwApi.getMyTransportWindow.mockResolvedValue(makeWindow());
        renderEditForm(1);

        await waitFor(() => {
            expect(screen.getByLabelText(/zona de origen/i)).toHaveValue("Buenos Aires");
        });
        expect(screen.getByLabelText(/zona de destino/i)).toHaveValue("Córdoba");
    });

    it("renders the edit heading", async () => {
        mockTwApi.getMyTransportWindow.mockResolvedValue(makeWindow());
        renderEditForm(1);
        await waitFor(() => {
            expect(screen.getByRole("heading", { name: /editar disponibilidad/i })).toBeInTheDocument();
        });
    });

    it("calls updateTransportWindow on submit with datetime suffix in payload", async () => {
        mockTwApi.getMyTransportWindow.mockResolvedValue(makeWindow());
        mockTwApi.updateTransportWindow.mockResolvedValue(makeWindow({ origin_zone: "Rosario" }));
        renderEditForm(1);

        await waitFor(() => screen.getByLabelText(/zona de origen/i));
        await userEvent.clear(screen.getByLabelText(/zona de origen/i));
        await userEvent.type(screen.getByLabelText(/zona de origen/i), "Rosario");
        await userEvent.click(screen.getByRole("button", { name: /guardar cambios/i }));

        await waitFor(() => {
            expect(mockTwApi.updateTransportWindow).toHaveBeenCalledWith(
                1,
                expect.objectContaining({
                    origin_zone: "Rosario",
                    available_from: "2026-05-15T00:00",
                    available_to: "2026-05-25T23:59",
                })
            );
        });
    });
});
