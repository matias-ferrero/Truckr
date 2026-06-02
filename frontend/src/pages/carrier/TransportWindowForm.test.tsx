import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import TransportWindowForm from "./TransportWindowForm";
import * as twApi from "../../api/transport_windows";
import * as vehiclesApi from "../../api/vehicles";
import type { AddressPickerValue } from "../../components/AddressPicker";

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

// Replace the RadiusControl with a plain number input so the form test can
// drive value changes without dragging in the Google Maps JS API. The
// component is exercised end-to-end in its own spec.
vi.mock("../../components/RadiusControl", () => ({
    RadiusControl: ({
        id,
        value,
        onChange,
        label,
        role,
    }: {
        id?: string;
        value: number;
        onChange: (v: number) => void;
        label?: string;
        role?: "pickup" | "dropoff";
    }) => (
        <div data-testid={`mock-radius-${role ?? "pickup"}-${id ?? "default"}`}>
            <label htmlFor={id}>{label ?? "Radio (km)"}</label>
            <input
                id={id}
                type="number"
                value={value}
                onChange={(e) => onChange(Number(e.target.value))}
            />
        </div>
    ),
    RADIUS_DEFAULT_KM: 10,
    RADIUS_MIN_KM:     1,
    RADIUS_MAX_KM:     200,
}));

// Replace the AddressPicker with a thin testing harness so the form test
// can drive value changes without dragging in the Google Maps JS API. Each
// input renders the current `text` as its value and exposes a button to
// "confirm" a fixed { text, lat, lng, locality, admin_area } payload.
vi.mock("../../components/AddressPicker", () => ({
    AddressPicker: ({
        id,
        value,
        onChange,
        disabled,
    }: {
        id?: string;
        value: AddressPickerValue | null;
        onChange: (v: AddressPickerValue | null) => void;
        disabled?: boolean;
    }) => {
        const confirmedSamples: Record<string, AddressPickerValue> = {
            origin_address:      {
                text:       "Av. Corrientes 1234, CABA, Argentina",
                lat:        -34.603722,
                lng:        -58.381592,
                locality:   "CABA",
                admin_area: "Buenos Aires",
            },
            destination_address: {
                text:       "Av. Colón 500, Córdoba, Argentina",
                lat:        -31.420083,
                lng:        -64.188776,
                locality:   "Córdoba",
                admin_area: "Córdoba",
            },
        };
        return (
            <div data-testid={`mock-address-picker-${id ?? "default"}`}>
                <input
                    id={id}
                    aria-label={id ?? "address"}
                    value={value?.text ?? ""}
                    onChange={(e) => {
                        if (e.target.value === "") onChange(null);
                        else onChange({ text: e.target.value, lat: -34, lng: -58, locality: "", admin_area: "" });
                    }}
                    disabled={disabled}
                />
                <button
                    type="button"
                    onClick={() => onChange(confirmedSamples[id ?? ""] ?? confirmedSamples.origin_address)}
                >
                    confirm-{id ?? "default"}
                </button>
                <button
                    type="button"
                    onClick={() => onChange(null)}
                >
                    clear-{id ?? "default"}
                </button>
            </div>
        );
    },
}));

const mockTwApi  = vi.mocked(twApi);
const mockVehApi = vi.mocked(vehiclesApi);

function makeWindow(overrides: Partial<twApi.TransportWindow> = {}): twApi.TransportWindow {
    return {
        id:                     1,
        vehicle_id:             10,
        origin_address:         "Av. Corrientes 1234, CABA, Argentina",
        origin_locality:        "CABA",
        origin_admin_area:      "Buenos Aires",
        origin_lat:             "-34.603722",
        origin_lng:             "-58.381592",
        destination_address:    "Av. Colón 500, Córdoba, Argentina",
        destination_locality:   "Córdoba",
        destination_admin_area: "Córdoba",
        destination_lat:        "-31.420083",
        destination_lng:        "-64.188776",
        pickup_radius_km:       10,
        dropoff_radius_km:      10,
        price_per_km:           "1500.0",
        max_km:                 1200,
        available_from:         "2026-05-15T09:00:00.000Z",
        available_to:           "2026-05-25T18:00:00.000Z",
        active:                 true,
        cargo_offers_count:     0,
        vehicle:                { id: 10, make: "MB", model: "Sprinter", plate: "AA001XX", vehicle_type: "truck_small" },
        created_at:             "2026-05-11T00:00:00.000Z",
        updated_at:             "2026-05-11T00:00:00.000Z",
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
        </MemoryRouter>,
    );
}

function renderEditForm(id = 1) {
    return render(
        <MemoryRouter initialEntries={[`/carrier/availability/${id}`]}>
            <Routes>
                <Route path="/carrier/availability/:id" element={<TransportWindowForm mode="edit" />} />
                <Route path="/carrier/availability" element={<div>list</div>} />
            </Routes>
        </MemoryRouter>,
    );
}

async function fillCommonFields() {
    await userEvent.selectOptions(screen.getByRole("combobox", { name: /vehículo/i }), "10");
    await userEvent.type(screen.getByLabelText(/precio por km/i), "1500");
    await userEvent.type(screen.getByLabelText(/kilómetros máximos/i), "1200");
    await userEvent.type(screen.getByLabelText(/disponible desde/i), "2099-01-01");
    await userEvent.type(screen.getByLabelText(/disponible hasta/i), "2099-01-31");
}

beforeEach(() => {
    vi.resetAllMocks();
    mockVehApi.listMyVehicles?.mockResolvedValue?.({ items: [], meta: { total: 0, page: 1, perPage: 20, totalPages: 1 } });
});

describe("TransportWindowForm — new mode (REQ-BE-00039)", () => {
    it("renders the create heading", () => {
        renderNewForm();
        expect(screen.getByRole("heading", { name: /nueva disponibilidad/i })).toBeInTheDocument();
    });

    it("renders an AddressPicker for origin and another for destination — no province dropdowns", () => {
        renderNewForm();
        expect(screen.getByTestId("mock-address-picker-origin_address")).toBeInTheDocument();
        expect(screen.getByTestId("mock-address-picker-destination_address")).toBeInTheDocument();
        // ProvinceSelect was removed from the transport-window form in REQ-BE-00039 —
        // any "Provincia" copy would be a regression.
        expect(screen.queryByLabelText(/^provincia$/i)).toBeNull();
    });

    it("renders the pickup radius control by default and hides the dropoff radius until destination is confirmed", () => {
        renderNewForm();
        expect(screen.getByTestId("mock-radius-pickup-pickup_radius_km")).toBeInTheDocument();
        expect(screen.queryByTestId("mock-radius-dropoff-dropoff_radius_km")).toBeNull();
    });

    it("reveals the dropoff radius control once the destination address is confirmed", async () => {
        renderNewForm();
        await userEvent.click(screen.getByRole("button", { name: /confirm-destination_address/i }));
        expect(screen.getByTestId("mock-radius-dropoff-dropoff_radius_km")).toBeInTheDocument();
    });

    it("hides the dropoff radius control again when the destination is cleared", async () => {
        renderNewForm();
        await userEvent.click(screen.getByRole("button", { name: /confirm-destination_address/i }));
        await userEvent.click(screen.getByRole("button", { name: /clear-destination_address/i }));
        expect(screen.queryByTestId("mock-radius-dropoff-dropoff_radius_km")).toBeNull();
    });

    it("submits the full address payload (origin + destination + both radii)", async () => {
        mockTwApi.createTransportWindow.mockResolvedValue(makeWindow());
        renderNewForm();
        await userEvent.click(screen.getByRole("button", { name: /confirm-origin_address/i }));
        await userEvent.click(screen.getByRole("button", { name: /confirm-destination_address/i }));
        await fillCommonFields();
        await userEvent.click(screen.getByRole("button", { name: /publicar disponibilidad/i }));

        await waitFor(() => {
            expect(mockTwApi.createTransportWindow).toHaveBeenCalledWith(
                expect.objectContaining({
                    origin_address:         "Av. Corrientes 1234, CABA, Argentina",
                    origin_locality:        "CABA",
                    origin_admin_area:      "Buenos Aires",
                    origin_lat:             -34.603722,
                    origin_lng:             -58.381592,
                    destination_address:    "Av. Colón 500, Córdoba, Argentina",
                    destination_locality:   "Córdoba",
                    destination_admin_area: "Córdoba",
                    destination_lat:        -31.420083,
                    destination_lng:        -64.188776,
                    pickup_radius_km:       10,
                    dropoff_radius_km:      10,
                }),
            );
        });
        expect(screen.getByText("list")).toBeInTheDocument();
    });

    it("submits the open-destination shape (null destination fields, null dropoff_radius)", async () => {
        mockTwApi.createTransportWindow.mockResolvedValue(makeWindow({
            destination_address:    null,
            destination_locality:   null,
            destination_admin_area: null,
            destination_lat:        null,
            destination_lng:        null,
            dropoff_radius_km:      null,
        }));
        renderNewForm();
        await userEvent.click(screen.getByRole("button", { name: /confirm-origin_address/i }));
        // destination intentionally left blank
        await fillCommonFields();
        await userEvent.click(screen.getByRole("button", { name: /publicar disponibilidad/i }));

        await waitFor(() => {
            expect(mockTwApi.createTransportWindow).toHaveBeenCalledWith(
                expect.objectContaining({
                    destination_address:    null,
                    destination_locality:   null,
                    destination_admin_area: null,
                    destination_lat:        null,
                    destination_lng:        null,
                    dropoff_radius_km:      null,
                }),
            );
        });
    });

    it("includes a custom pickup_radius_km in the create payload when the user changes it", async () => {
        mockTwApi.createTransportWindow.mockResolvedValue(makeWindow({ pickup_radius_km: 25 }));
        renderNewForm();
        await userEvent.click(screen.getByRole("button", { name: /confirm-origin_address/i }));
        await fillCommonFields();
        const radius = screen.getByLabelText(/radio de recogida/i);
        await userEvent.clear(radius);
        await userEvent.type(radius, "25");
        await userEvent.click(screen.getByRole("button", { name: /publicar disponibilidad/i }));
        await waitFor(() => {
            expect(mockTwApi.createTransportWindow).toHaveBeenCalledWith(
                expect.objectContaining({ pickup_radius_km: 25 }),
            );
        });
    });

    it("blocks submit when origin pin is missing", async () => {
        renderNewForm();
        await userEvent.selectOptions(screen.getByRole("combobox", { name: /vehículo/i }), "10");
        // intentionally skip the origin picker
        await userEvent.click(screen.getByRole("button", { name: /publicar disponibilidad/i }));
        await waitFor(() => {
            expect(screen.getByRole("alert")).toHaveTextContent(/confirmá una dirección de origen/i);
        });
        expect(mockTwApi.createTransportWindow).not.toHaveBeenCalled();
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
        await userEvent.click(screen.getByRole("button", { name: /confirm-origin_address/i }));
        await userEvent.type(screen.getByLabelText(/precio por km/i), "1500");
        await userEvent.type(screen.getByLabelText(/kilómetros máximos/i), "1200");
        // leave dates empty
        await userEvent.click(screen.getByRole("button", { name: /publicar disponibilidad/i }));
        await waitFor(() => {
            expect(screen.getByRole("alert")).toBeInTheDocument();
        });
        expect(mockTwApi.createTransportWindow).not.toHaveBeenCalled();
    });
});

describe("TransportWindowForm — edit mode (REQ-BE-00039)", () => {
    it("hydrates the address fields and both radii from the existing window", async () => {
        mockTwApi.getMyTransportWindow.mockResolvedValue(makeWindow());
        renderEditForm(1);
        await waitFor(() => {
            expect(screen.getByLabelText("origin_address")).toHaveValue("Av. Corrientes 1234, CABA, Argentina");
        });
        expect(screen.getByLabelText("destination_address")).toHaveValue("Av. Colón 500, Córdoba, Argentina");
        expect(screen.getByLabelText(/radio de recogida/i)).toHaveValue(10);
        expect(screen.getByLabelText(/radio de entrega/i)).toHaveValue(10);
    });

    it("hydrates destination as empty for open-destination windows and hides the dropoff radius", async () => {
        mockTwApi.getMyTransportWindow.mockResolvedValue(makeWindow({
            destination_address:    null,
            destination_locality:   null,
            destination_admin_area: null,
            destination_lat:        null,
            destination_lng:        null,
            dropoff_radius_km:      null,
        }));
        renderEditForm(1);
        await waitFor(() => {
            expect(screen.getByLabelText("destination_address")).toHaveValue("");
        });
        expect(screen.queryByTestId("mock-radius-dropoff-dropoff_radius_km")).toBeNull();
    });

    it("renders the edit heading", async () => {
        mockTwApi.getMyTransportWindow.mockResolvedValue(makeWindow());
        renderEditForm(1);
        await waitFor(() => {
            expect(screen.getByRole("heading", { name: /editar disponibilidad/i })).toBeInTheDocument();
        });
    });

    it("PATCHes the new dropoff_radius_km after the user edits it", async () => {
        mockTwApi.getMyTransportWindow.mockResolvedValue(makeWindow({ dropoff_radius_km: 25 }));
        mockTwApi.updateTransportWindow.mockResolvedValue(makeWindow({ dropoff_radius_km: 50 }));
        renderEditForm(1);

        await waitFor(() => expect(screen.getByLabelText(/radio de entrega/i)).toHaveValue(25));
        const radius = screen.getByLabelText(/radio de entrega/i);
        await userEvent.clear(radius);
        await userEvent.type(radius, "50");
        await userEvent.click(screen.getByRole("button", { name: /guardar cambios/i }));

        await waitFor(() => {
            expect(mockTwApi.updateTransportWindow).toHaveBeenCalledWith(
                1,
                expect.objectContaining({ dropoff_radius_km: 50 }),
            );
        });
    });
});
