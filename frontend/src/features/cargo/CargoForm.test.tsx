import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import CargoForm from "./CargoForm";
import * as cargoApi from "./api";
import { ApiError } from "../../api";
import type { Cargo } from "../../types/Cargo";

vi.mock("./api", async (orig) => {
    const actual = await orig<typeof cargoApi>();
    return {
        ...actual,
        getCargo: vi.fn(),
        createCargo: vi.fn(),
        updateCargo: vi.fn(),
    };
});

const api = vi.mocked(cargoApi);

function makeCargo(over: Partial<Cargo> = {}): Cargo {
    return {
        id: 4,
        shipper_id: 1,
        status: "open",
        cargo_description: "Muebles",
        pickup_address: "Av. Siempreviva 742",
        delivery_address: "Calle Falsa 123",
        pickup_zone: "Mendoza",
        delivery_zone: "Salta",
        pickup_window_start: "2026-06-01T08:00:00Z",
        pickup_window_end: "2026-06-03T18:00:00Z",
        weight_kg: "900.0",
        volume_cm3: 1_000_000,
        declared_value_cents: 2_000_000,
        cancelled_at: null,
        created_at: "",
        updated_at: "",
        editable: true,
        pending_offers_count: 0,
        cargo_offers: [],
        ...over,
    };
}

function renderNew() {
    return render(
        <MemoryRouter initialEntries={["/shipper/cargos/new"]}>
            <Routes>
                <Route
                    path="/shipper/cargos/new"
                    element={<CargoForm mode="new" />}
                />
                <Route
                    path="/shipper/cargos/:id"
                    element={<div>cargo-detail</div>}
                />
            </Routes>
        </MemoryRouter>,
    );
}

function renderEdit(id = 4) {
    return render(
        <MemoryRouter initialEntries={[`/shipper/cargos/${id}/edit`]}>
            <Routes>
                <Route
                    path="/shipper/cargos/:id/edit"
                    element={<CargoForm mode="edit" />}
                />
                <Route
                    path="/shipper/cargos/:id"
                    element={<div>cargo-detail</div>}
                />
            </Routes>
        </MemoryRouter>,
    );
}

async function fillValid(user: ReturnType<typeof userEvent.setup>) {
    await user.type(
        screen.getByLabelText(/Descripción de la carga/),
        "Pallets",
    );
    await user.type(screen.getByLabelText(/Peso \(kg\)/), "1500");
    await user.type(screen.getByLabelText(/Valor declarado/), "5000000");
    await user.type(
        screen.getByLabelText(/Dirección de retiro/),
        "Calle 1",
    );
    await user.type(
        screen.getByLabelText(/Dirección de entrega/),
        "Calle 2",
    );
    await user.selectOptions(
        screen.getByLabelText(/Zona de retiro/),
        "Buenos Aires",
    );
    await user.selectOptions(
        screen.getByLabelText(/Zona de entrega/),
        "Córdoba",
    );
    const start = screen.getByLabelText(/Retiro desde/);
    const end = screen.getByLabelText(/Retiro hasta/);
    await user.type(start, "2026-06-01T08:00");
    await user.type(end, "2026-06-03T18:00");
}

beforeEach(() => {
    vi.resetAllMocks();
});

describe("CargoForm — new", () => {
    it("renders the publish heading", () => {
        renderNew();
        expect(
            screen.getByRole("heading", { name: "Publicar una carga" }),
        ).toBeInTheDocument();
    });

    it("blocks submit and shows required-field errors", async () => {
        const user = userEvent.setup();
        renderNew();
        await user.click(
            screen.getByRole("button", { name: "Publicar carga" }),
        );
        expect(
            screen.getByText("Ingresá una descripción de la carga."),
        ).toBeInTheDocument();
        expect(
            screen.getByText("Ingresá el peso de la carga."),
        ).toBeInTheDocument();
        expect(api.createCargo).not.toHaveBeenCalled();
    });

    it("rejects a non-positive weight", async () => {
        const user = userEvent.setup();
        renderNew();
        await fillValid(user);
        await user.clear(screen.getByLabelText(/Peso \(kg\)/));
        await user.type(screen.getByLabelText(/Peso \(kg\)/), "0");
        await user.click(
            screen.getByRole("button", { name: "Publicar carga" }),
        );
        expect(
            screen.getByText("El peso debe ser mayor a cero."),
        ).toBeInTheDocument();
        expect(api.createCargo).not.toHaveBeenCalled();
    });

    it("rejects an end window not after the start", async () => {
        const user = userEvent.setup();
        renderNew();
        await fillValid(user);
        await user.clear(screen.getByLabelText(/Retiro hasta/));
        await user.type(
            screen.getByLabelText(/Retiro hasta/),
            "2026-06-01T08:00",
        );
        await user.click(
            screen.getByRole("button", { name: "Publicar carga" }),
        );
        expect(
            screen.getByText(
                "El fin de la ventana debe ser posterior al inicio.",
            ),
        ).toBeInTheDocument();
    });

    it("submits a valid draft and redirects to the detail", async () => {
        api.createCargo.mockResolvedValue(makeCargo({ id: 88 }));
        const user = userEvent.setup();
        renderNew();
        await fillValid(user);
        await user.click(
            screen.getByRole("button", { name: "Publicar carga" }),
        );
        await waitFor(() =>
            expect(screen.getByText("cargo-detail")).toBeInTheDocument()
        );
        expect(api.createCargo).toHaveBeenCalledOnce();
    });

    it("maps server-side field errors onto the inputs", async () => {
        api.createCargo.mockRejectedValue(
            new ApiError(422, "x", "x", {
                cargo_description: ["ya existe"],
            }),
        );
        const user = userEvent.setup();
        renderNew();
        await fillValid(user);
        await user.click(
            screen.getByRole("button", { name: "Publicar carga" }),
        );
        expect(await screen.findByText("ya existe")).toBeInTheDocument();
        expect(
            screen.getByText(/No pudimos guardar la carga/),
        ).toBeInTheDocument();
    });
});

describe("CargoForm — edit", () => {
    it("hydrates the form from the loaded cargo", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        renderEdit();
        expect(
            await screen.findByDisplayValue("Muebles"),
        ).toBeInTheDocument();
        expect(
            screen.getByRole("heading", { name: "Editar carga" }),
        ).toBeInTheDocument();
    });

    it("shows a load error when the cargo cannot be fetched", async () => {
        api.getCargo.mockRejectedValue(new Error("404"));
        renderEdit();
        expect(
            await screen.findByText(
                "No pudimos cargar la carga que querés editar.",
            ),
        ).toBeInTheDocument();
    });

    it("PATCHes on submit and redirects to the detail", async () => {
        api.getCargo.mockResolvedValue(makeCargo());
        api.updateCargo.mockResolvedValue(makeCargo());
        const user = userEvent.setup();
        renderEdit();
        await screen.findByDisplayValue("Muebles");
        await user.click(
            screen.getByRole("button", { name: "Guardar cambios" }),
        );
        await waitFor(() =>
            expect(screen.getByText("cargo-detail")).toBeInTheDocument()
        );
        expect(api.updateCargo).toHaveBeenCalledWith(4, expect.any(Object));
    });
});
