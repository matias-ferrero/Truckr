import { beforeEach, describe, expect, it, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import CargoForm from "./CargoForm";
import * as cargoApi from "./api";
import { ApiError } from "../../api";
import type { Cargo } from "../../types/Cargo";
import type { AddressPickerValue } from "../../components/AddressPicker";

vi.mock("./api", async (orig) => {
    const actual = await orig<typeof cargoApi>();
    return {
        ...actual,
        getCargo: vi.fn(),
        createCargo: vi.fn(),
        updateCargo: vi.fn(),
    };
});

// Replace the AddressPicker with a thin testing harness — same pattern as the
// carrier transport-window form test. Each input exposes a "confirm" button
// that emits a fixed { text, lat, lng } payload so we can drive the form
// without spinning up the Google Maps JS API.
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
            pickup_address:   { text: "Av. Corrientes 1234, CABA", lat: -34.603722, lng: -58.381592, locality: "CABA", admin_area: "CABA" },
            delivery_address: { text: "Av. Colón 500, Córdoba",    lat: -31.420083, lng: -64.188776, locality: "Córdoba", admin_area: "Córdoba" },
        };
        const safeId = id ?? "default";
        return (
            <div data-testid={`mock-address-picker-${safeId}`}>
                <input
                    id={id}
                    aria-label={safeId}
                    value={value?.text ?? ""}
                    onChange={(e) => {
                        if (e.target.value === "") onChange(null);
                        else onChange({ text: e.target.value, lat: -34, lng: -58 });
                    }}
                    disabled={disabled}
                />
                <button type="button" onClick={() => onChange(confirmedSamples[safeId] ?? confirmedSamples.pickup_address)}>
                    confirm-{safeId}
                </button>
                <button type="button" onClick={() => onChange(null)}>
                    clear-{safeId}
                </button>
            </div>
        );
    },
}));

// CargoMapPreview pulls in the Google Maps loader at module scope. Stub it out
// in unit tests — the map preview itself is exercised in its own spec.
vi.mock("./CargoMapPreview", () => ({
    __esModule: true,
    default: ({ pickup, delivery }: { pickup: AddressPickerValue | null; delivery: AddressPickerValue | null }) => (
        <div
            data-testid="cargo-map-preview"
            data-pickup-lat={pickup?.lat ?? ""}
            data-pickup-lng={pickup?.lng ?? ""}
            data-delivery-lat={delivery?.lat ?? ""}
            data-delivery-lng={delivery?.lng ?? ""}
        />
    ),
}));

const api = vi.mocked(cargoApi);

function makeCargo(over: Partial<Cargo> = {}): Cargo {
    return {
        id:                   4,
        shipper_id:           1,
        status:               "open",
        cargo_description:    "Muebles",
        pickup_address:       "Av. Siempreviva 742",
        pickup_lat:           "-34.603722",
        pickup_lng:           "-58.381592",
        pickup_locality:      "Mendoza",
        pickup_admin_area:    "Mendoza",
        delivery_address:     "Calle Falsa 123",
        delivery_lat:         "-31.420083",
        delivery_lng:         "-64.188776",
        delivery_locality:    "Salta",
        delivery_admin_area:  "Salta",
        pickup_window_start:  "2026-06-01T08:00:00Z",
        pickup_window_end:    "2026-06-03T18:00:00Z",
        weight_kg:            "900.0",
        volume_cm3:           1_000_000,
        declared_value_cents: 2_000_000,
        cancelled_at:         null,
        created_at:           "",
        updated_at:           "",
        editable:             true,
        pending_offers_count: 0,
        cargo_offers:         [],
        ...over,
    };
}

function renderNew() {
    return render(
        <MemoryRouter initialEntries={["/shipper/cargos/new"]}>
            <Routes>
                <Route path="/shipper/cargos/new" element={<CargoForm mode="new" />} />
                <Route path="/shipper/cargos/:id" element={<div>cargo-detail</div>} />
            </Routes>
        </MemoryRouter>,
    );
}

function renderEdit(id = 4) {
    return render(
        <MemoryRouter initialEntries={[`/shipper/cargos/${id}/edit`]}>
            <Routes>
                <Route path="/shipper/cargos/:id/edit" element={<CargoForm mode="edit" />} />
                <Route path="/shipper/cargos/:id" element={<div>cargo-detail</div>} />
            </Routes>
        </MemoryRouter>,
    );
}

async function fillAddresses(user: ReturnType<typeof userEvent.setup>) {
    await user.click(screen.getByRole("button", { name: /confirm-pickup_address/i }));
    await user.click(screen.getByRole("button", { name: /confirm-delivery_address/i }));
}

async function fillCommonFields(user: ReturnType<typeof userEvent.setup>) {
    await user.type(screen.getByLabelText(/Descripción de la carga/), "Pallets");
    await user.type(screen.getByLabelText(/Peso \(kg\)/), "1500");
    await user.type(screen.getByLabelText(/Valor declarado/), "5000000");
    await user.type(screen.getByLabelText(/Retiro desde/), "2026-06-01T08:00");
    await user.type(screen.getByLabelText(/Retiro hasta/), "2026-06-03T18:00");
}

beforeEach(() => {
    vi.resetAllMocks();
});

describe("CargoForm — new", () => {
    it("renders the publish heading", () => {
        renderNew();
        expect(screen.getByRole("heading", { name: "Publicar una carga" })).toBeInTheDocument();
    });

    it("renders two AddressPickers and the map preview", () => {
        renderNew();
        expect(screen.getByTestId("mock-address-picker-pickup_address")).toBeInTheDocument();
        expect(screen.getByTestId("mock-address-picker-delivery_address")).toBeInTheDocument();
        expect(screen.getByTestId("cargo-map-preview")).toBeInTheDocument();
    });

    it("blocks submit and surfaces a missing-coordinates error per picker", async () => {
        const user = userEvent.setup();
        renderNew();
        await user.click(screen.getByRole("button", { name: "Publicar carga" }));
        expect(
            screen.getByText("Confirmá una dirección de retiro desde el listado."),
        ).toBeInTheDocument();
        expect(
            screen.getByText("Confirmá una dirección de entrega desde el listado."),
        ).toBeInTheDocument();
        expect(api.createCargo).not.toHaveBeenCalled();
    });

    it("submits a valid draft with the four coordinates and redirects to the detail", async () => {
        api.createCargo.mockResolvedValue(makeCargo({ id: 88 }));
        const user = userEvent.setup();
        renderNew();
        await fillAddresses(user);
        await fillCommonFields(user);
        expect(screen.getByText("Se verá como ARS 5.000.000.")).toBeInTheDocument();
        await user.click(screen.getByRole("button", { name: "Publicar carga" }));

        await waitFor(() => expect(screen.getByText("cargo-detail")).toBeInTheDocument());
        expect(api.createCargo).toHaveBeenCalledWith(
            expect.objectContaining({
                pickup_address: "Av. Corrientes 1234, CABA",
                pickup_lat:     -34.603722,
                pickup_lng:     -58.381592,
                delivery_address: "Av. Colón 500, Córdoba",
                delivery_lat:     -31.420083,
                delivery_lng:     -64.188776,
            }),
        );
    });

    it("blocks submit when only the pickup picker is confirmed", async () => {
        const user = userEvent.setup();
        renderNew();
        await user.click(screen.getByRole("button", { name: /confirm-pickup_address/i }));
        await fillCommonFields(user);
        await user.click(screen.getByRole("button", { name: "Publicar carga" }));
        expect(
            screen.getByText("Confirmá una dirección de entrega desde el listado."),
        ).toBeInTheDocument();
        expect(api.createCargo).not.toHaveBeenCalled();
    });

    it("forwards the picker coordinates to the map preview", async () => {
        const user = userEvent.setup();
        renderNew();
        await user.click(screen.getByRole("button", { name: /confirm-pickup_address/i }));
        await user.click(screen.getByRole("button", { name: /confirm-delivery_address/i }));
        const preview = screen.getByTestId("cargo-map-preview");
        expect(preview).toHaveAttribute("data-pickup-lat",   "-34.603722");
        expect(preview).toHaveAttribute("data-pickup-lng",   "-58.381592");
        expect(preview).toHaveAttribute("data-delivery-lat", "-31.420083");
        expect(preview).toHaveAttribute("data-delivery-lng", "-64.188776");
    });

    it("maps server-side field errors onto the inputs", async () => {
        api.createCargo.mockRejectedValue(
            new ApiError(422, "x", "x", { cargo_description: ["ya existe"] }),
        );
        const user = userEvent.setup();
        renderNew();
        await fillAddresses(user);
        await fillCommonFields(user);
        await user.click(screen.getByRole("button", { name: "Publicar carga" }));
        expect(await screen.findByText("ya existe")).toBeInTheDocument();
        expect(screen.getByText(/No pudimos guardar la carga/)).toBeInTheDocument();
    });

    it("explains that the declared value is entered in ARS and stored as cents", async () => {
        renderNew();
        const user = userEvent.setup();
        await user.type(screen.getByLabelText(/Valor declarado/), "5000000");
        expect(screen.getByText(/Ingresá pesos argentinos enteros, sin centavos\./)).toBeInTheDocument();
        expect(screen.getByText("Se verá como ARS 5.000.000.")).toBeInTheDocument();
    });
});

describe("CargoForm — edit", () => {
    it("hydrates the pickers and the inputs from the loaded cargo", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        renderEdit();
        expect(await screen.findByDisplayValue("Muebles")).toBeInTheDocument();
        expect(screen.getByRole("heading", { name: "Editar carga" })).toBeInTheDocument();
        expect(screen.getByLabelText("pickup_address")).toHaveValue("Av. Siempreviva 742");
        expect(screen.getByLabelText("delivery_address")).toHaveValue("Calle Falsa 123");
    });

    it("shows a load error when the cargo cannot be fetched", async () => {
        api.getCargo.mockRejectedValue(new Error("404"));
        renderEdit();
        expect(
            await screen.findByText("No pudimos cargar la carga que querés editar."),
        ).toBeInTheDocument();
    });

    it("PATCHes with the existing coordinates when the pickers are untouched", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        api.updateCargo.mockResolvedValue(makeCargo());
        const user = userEvent.setup();
        renderEdit();
        await screen.findByDisplayValue("Muebles");
        await user.click(screen.getByRole("button", { name: "Guardar cambios" }));

        await waitFor(() => expect(screen.getByText("cargo-detail")).toBeInTheDocument());
        expect(api.updateCargo).toHaveBeenCalledWith(
            4,
            expect.objectContaining({
                pickup_address: "Av. Siempreviva 742",
                pickup_lat:     -34.603722,
                pickup_lng:     -58.381592,
                delivery_address: "Calle Falsa 123",
                delivery_lat:     -31.420083,
                delivery_lng:     -64.188776,
            }),
        );
    });

    it("PATCHes with new coordinates after the user re-confirms a picker", async () => {
        api.getCargo.mockResolvedValue(
            makeCargo({
                pickup_address: "Vieja dirección",
                pickup_lat:     "-30.000000",
                pickup_lng:     "-60.000000",
            }),
        );
        api.updateCargo.mockResolvedValue(makeCargo());
        const user = userEvent.setup();
        renderEdit();
        await screen.findByDisplayValue("Muebles");
        await user.click(screen.getByRole("button", { name: /confirm-pickup_address/i }));
        await user.click(screen.getByRole("button", { name: "Guardar cambios" }));

        await waitFor(() => expect(screen.getByText("cargo-detail")).toBeInTheDocument());
        expect(api.updateCargo).toHaveBeenCalledWith(
            4,
            expect.objectContaining({
                pickup_address: "Av. Corrientes 1234, CABA",
                pickup_lat:     -34.603722,
                pickup_lng:     -58.381592,
            }),
        );
    });
});
