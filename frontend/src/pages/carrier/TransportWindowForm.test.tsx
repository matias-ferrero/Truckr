import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, waitFor, within } from "@testing-library/react";
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
        origin_province: "Buenos Aires",
        origin_locality: null,
        destination_province: "Córdoba",
        destination_locality: null,
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

    it("shows all fields including province and optional locality", () => {
        renderNewForm();
        const originGroup = screen.getByRole("group", { name: /origen/i });
        const destGroup   = screen.getByRole("group", { name: /destino/i });
        expect(within(originGroup).getByLabelText(/provincia/i)).toBeInTheDocument();
        expect(within(originGroup).getByLabelText(/localidad/i)).toBeInTheDocument();
        expect(within(destGroup).getByLabelText(/provincia/i)).toBeInTheDocument();
        expect(within(destGroup).getByLabelText(/localidad/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/precio por km/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/kilómetros máximos/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/disponible desde/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/disponible hasta/i)).toBeInTheDocument();
    });

    it("calls createTransportWindow on submit and navigates to list", async () => {
        mockTwApi.createTransportWindow.mockResolvedValue(makeWindow());
        renderNewForm();

        await userEvent.selectOptions(screen.getByRole("combobox", { name: /vehículo/i }), "10");
        await userEvent.selectOptions(within(screen.getByRole("group", { name: /origen/i })).getByLabelText(/provincia/i), "Buenos Aires");
        await userEvent.selectOptions(within(screen.getByRole("group", { name: /destino/i })).getByLabelText(/provincia/i), "Córdoba");
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

    it("submits with destination_province null when destination fields are left blank", async () => {
        mockTwApi.createTransportWindow.mockResolvedValue(makeWindow({ destination_province: null }));
        renderNewForm();

        await userEvent.selectOptions(screen.getByRole("combobox", { name: /vehículo/i }), "10");
        await userEvent.selectOptions(within(screen.getByRole("group", { name: /origen/i })).getByLabelText(/provincia/i), "Buenos Aires");
        // leave destination fields at the empty placeholder option (open destination)
        await userEvent.type(screen.getByLabelText(/precio por km/i), "1500");
        await userEvent.type(screen.getByLabelText(/kilómetros máximos/i), "1200");
        await userEvent.type(screen.getByLabelText(/disponible desde/i), "2026-06-01");
        await userEvent.type(screen.getByLabelText(/disponible hasta/i), "2026-06-30");

        await userEvent.click(screen.getByRole("button", { name: /publicar disponibilidad/i }));

        await waitFor(() => {
            expect(mockTwApi.createTransportWindow).toHaveBeenCalledWith(
                expect.objectContaining({
                    destination_province: null,
                    destination_locality: null,
                })
            );
        });
    });

    it("submits with locality fields when filled", async () => {
        mockTwApi.createTransportWindow.mockResolvedValue(
            makeWindow({ origin_locality: "CABA", destination_locality: "Córdoba Capital" })
        );
        renderNewForm();

        await userEvent.selectOptions(screen.getByRole("combobox", { name: /vehículo/i }), "10");
        await userEvent.selectOptions(within(screen.getByRole("group", { name: /origen/i })).getByLabelText(/provincia/i), "Buenos Aires");
        await userEvent.type(within(screen.getByRole("group", { name: /origen/i })).getByLabelText(/localidad/i), "CABA");
        await userEvent.selectOptions(within(screen.getByRole("group", { name: /destino/i })).getByLabelText(/provincia/i), "Córdoba");
        await userEvent.type(within(screen.getByRole("group", { name: /destino/i })).getByLabelText(/localidad/i), "Córdoba Capital");
        await userEvent.type(screen.getByLabelText(/precio por km/i), "1500");
        await userEvent.type(screen.getByLabelText(/kilómetros máximos/i), "1200");
        await userEvent.type(screen.getByLabelText(/disponible desde/i), "2026-06-01");
        await userEvent.type(screen.getByLabelText(/disponible hasta/i), "2026-06-30");

        await userEvent.click(screen.getByRole("button", { name: /publicar disponibilidad/i }));

        await waitFor(() => {
            expect(mockTwApi.createTransportWindow).toHaveBeenCalledWith(
                expect.objectContaining({
                    origin_province: "Buenos Aires",
                    origin_locality: "CABA",
                    destination_province: "Córdoba",
                    destination_locality: "Córdoba Capital",
                })
            );
        });
    });

    it("shows helper text on the destination province field", () => {
        renderNewForm();
        expect(screen.getByText(/dejá vacío si aceptás cargas/i)).toBeInTheDocument();
    });

    it("shows error when dates are empty on submit", async () => {
        renderNewForm();
        await userEvent.selectOptions(screen.getByRole("combobox", { name: /vehículo/i }), "10");
        await userEvent.selectOptions(within(screen.getByRole("group", { name: /origen/i })).getByLabelText(/provincia/i), "Buenos Aires");
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
        await userEvent.selectOptions(within(screen.getByRole("group", { name: /origen/i })).getByLabelText(/provincia/i), "Buenos Aires");
        await userEvent.selectOptions(within(screen.getByRole("group", { name: /destino/i })).getByLabelText(/provincia/i), "Córdoba");
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
            expect(within(screen.getByRole("group", { name: /origen/i })).getByLabelText(/provincia/i)).toHaveValue("Buenos Aires");
        });
        expect(within(screen.getByRole("group", { name: /destino/i })).getByLabelText(/provincia/i)).toHaveValue("Córdoba");
    });

    it("hydrates destination fields as empty string for open-destination windows", async () => {
        mockTwApi.getMyTransportWindow.mockResolvedValue(
            makeWindow({ destination_province: null, destination_locality: null })
        );
        renderEditForm(1);

        await waitFor(() => {
            expect(within(screen.getByRole("group", { name: /destino/i })).getByLabelText(/provincia/i)).toHaveValue("");
        });
        expect(within(screen.getByRole("group", { name: /destino/i })).getByLabelText(/localidad/i)).toHaveValue("");
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
        mockTwApi.updateTransportWindow.mockResolvedValue(makeWindow({ origin_province: "Mendoza" }));
        renderEditForm(1);

        await waitFor(() => within(screen.getByRole("group", { name: /origen/i })).getByLabelText(/provincia/i));
        await userEvent.selectOptions(within(screen.getByRole("group", { name: /origen/i })).getByLabelText(/provincia/i), "Mendoza");
        await userEvent.click(screen.getByRole("button", { name: /guardar cambios/i }));

        await waitFor(() => {
            expect(mockTwApi.updateTransportWindow).toHaveBeenCalledWith(
                1,
                expect.objectContaining({
                    origin_province: "Mendoza",
                    available_from: "2026-05-15T00:00",
                    available_to: "2026-05-25T23:59",
                })
            );
        });
    });
});
