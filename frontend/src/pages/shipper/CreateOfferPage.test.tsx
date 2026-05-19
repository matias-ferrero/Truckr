import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import CreateOfferPage from "./CreateOfferPage";
import * as quotesApi from "../../api/quotes";
import type { CarrierDetail, TransportWindow } from "../../api/carriers";
import type { Vehicle } from "../../api/vehicles";

vi.mock("../../api/quotes");

// ── fixtures ──────────────────────────────────────────────────────────────────

const fakeVehicle = (over: Partial<Vehicle> = {}): Vehicle => ({
    id: 10,
    carrier_id: 1,
    make: "Volvo",
    model: "FH",
    year: 2022,
    plate: "ABC123",
    vehicle_type: "truck_large",
    max_load_kg: "5000.00",
    length_cm: 500,
    width_cm: 200,
    height_cm: 200,
    volume_cm3: 20_000_000,
    gps_enabled: false,
    description: null,
    photos: [],
    created_at: "",
    updated_at: "",
    ...over,
});

const fakeWindow = (over: Partial<TransportWindow> = {}): TransportWindow => ({
    id: 5,
    vehicle_id: 10,
    origin_zone: "Buenos Aires",
    destination_zone: "Córdoba",
    price_per_km: "1500",
    max_km: 1000,
    available_from: "2026-05-20T00:00:00Z",
    available_to: "2026-05-30T00:00:00Z",
    active: true,
    ...over,
});

const fakeCarrier = (vehicles: Vehicle[] = [fakeVehicle()]): CarrierDetail => ({
    id: 1,
    legal_name: "Transportes Test",
    tax_id: null,
    base_city: "Buenos Aires",
    province: "Buenos Aires",
    description: null,
    rating_avg: "4.5",
    reviews_count: 10,
    completed_shipments: 50,
    vehicles,
    transport_windows: [fakeWindow()],
    created_at: "",
    updated_at: "",
});

const fakeCargoOffer = (): quotesApi.CargoOffer => ({
    id: 42,
    cargo_id: 1,
    carrier_id: 1,
    transport_window_id: 5,
    amount_cents: 1_050_000_000,
    currency: "ARS",
    status: "pending",
    expires_at: "2026-05-30T00:00:00Z",
    created_at: "",
    updated_at: "",
});

// ── mount helper ──────────────────────────────────────────────────────────────

type MountOpts = {
    state?: object | null;
    search?: string;
};

function mount(
    { state = { carrier: fakeCarrier(), window: fakeWindow() }, search = "?window=5" }:
        MountOpts = {},
) {
    const initialEntry = {
        pathname: "/carriers/1/offers/new",
        search,
        state,
    };
    return render(
        <MemoryRouter initialEntries={[initialEntry]}>
            <Routes>
                <Route path="/carriers/:id/offers/new" element={<CreateOfferPage />} />
                <Route path="/carriers/:id" element={<div>carrier-detail-page</div>} />
                <Route path="/" element={<div>home-page</div>} />
            </Routes>
        </MemoryRouter>,
    );
}

// Fill both address groups with minimal valid data to enable advancing past step 1.
async function fillAddresses(user: ReturnType<typeof userEvent.setup>) {
    const pickup = screen.getByRole("group", { name: "Origen" });
    const delivery = screen.getByRole("group", { name: "Destino" });

    await user.type(within(pickup).getByLabelText("Calle"), "Av. Corrientes");
    await user.type(within(pickup).getByLabelText("Número"), "1234");
    await user.type(within(pickup).getByLabelText("Código postal"), "C1043");
    await user.type(within(pickup).getByLabelText("Localidad"), "CABA");
    await user.selectOptions(
        within(pickup).getByLabelText("Provincia"),
        "Ciudad Autónoma de Buenos Aires",
    );

    await user.type(within(delivery).getByLabelText("Calle"), "Av. Colón");
    await user.type(within(delivery).getByLabelText("Número"), "500");
    await user.type(within(delivery).getByLabelText("Código postal"), "X5000");
    await user.type(within(delivery).getByLabelText("Localidad"), "Córdoba");
    await user.selectOptions(within(delivery).getByLabelText("Provincia"), "Córdoba");
}

// ── tests ─────────────────────────────────────────────────────────────────────

describe("CreateOfferPage", () => {
    beforeEach(() => {
        vi.resetAllMocks();
    });

    it("redirects to carrier detail when navigation state is missing", () => {
        mount({ state: null });
        expect(screen.getByText("carrier-detail-page")).toBeInTheDocument();
    });

    it("renders step 1 (Addresses) by default with wizard progress", () => {
        mount();
        expect(screen.getByText("Crear oferta de carga")).toBeInTheDocument();
        expect(screen.getByText("¿Dónde retiramos y entregamos?")).toBeInTheDocument();
        expect(screen.getByRole("group", { name: "Origen" })).toBeInTheDocument();
        expect(screen.getByRole("group", { name: "Destino" })).toBeInTheDocument();
    });

    it("back button on step 1 is enabled and navigates to carrier detail", async () => {
        const user = userEvent.setup();
        mount();
        const backBtn = screen.getByRole("button", { name: "Atrás" });
        expect(backBtn).not.toBeDisabled();
        await user.click(backBtn);
        expect(screen.getByText("carrier-detail-page")).toBeInTheDocument();
    });

    it("next button disabled when addresses are empty", () => {
        mount();
        expect(screen.getByRole("button", { name: "Siguiente" })).toBeDisabled();
    });

    it("next button enabled when both addresses filled", async () => {
        const user = userEvent.setup();
        mount();
        await fillAddresses(user);
        expect(screen.getByRole("button", { name: "Siguiente" })).not.toBeDisabled();
    });

    it("advances to step 2 (Cargo) after filling addresses", async () => {
        const user = userEvent.setup();
        mount();
        await fillAddresses(user);
        await user.click(screen.getByRole("button", { name: "Siguiente" }));
        expect(screen.getByText("Detalle de la carga")).toBeInTheDocument();
    });

    it("shows vehicle weight capacity hint on step 2", async () => {
        const user = userEvent.setup();
        mount();
        await fillAddresses(user);
        await user.click(screen.getByRole("button", { name: "Siguiente" }));
        expect(screen.getByText(/Capacidad máxima del vehículo: 5000.00 kg/i)).toBeInTheDocument();
    });

    it("shows vehicle volume hint when vehicle has volume_cm3", async () => {
        const user = userEvent.setup();
        mount({
            state: {
                carrier: fakeCarrier([fakeVehicle({ volume_cm3: 20_000_000 })]),
                window: fakeWindow(),
            },
        });
        await fillAddresses(user);
        await user.click(screen.getByRole("button", { name: "Siguiente" }));
        expect(
            screen.getByText(/Capacidad máxima del vehículo: 20.000.000 cm³/i),
        ).toBeInTheDocument();
    });

    it("shows no-volume hint when vehicle.volume_cm3 is null", async () => {
        const user = userEvent.setup();
        mount({
            state: {
                carrier: fakeCarrier([fakeVehicle({ volume_cm3: null })]),
                window: fakeWindow(),
            },
        });
        await fillAddresses(user);
        await user.click(screen.getByRole("button", { name: "Siguiente" }));
        expect(
            screen.getByText("Este vehículo no tiene volumen máximo registrado."),
        ).toBeInTheDocument();
    });

    it("blocks step 2 and shows error when weight exceeds vehicle capacity", async () => {
        const user = userEvent.setup();
        mount();
        await fillAddresses(user);
        await user.click(screen.getByRole("button", { name: "Siguiente" }));

        await user.type(screen.getByLabelText("Peso (kg)"), "9999");
        expect(
            screen.getByText(/El peso supera la capacidad del vehículo \(5000.00 kg\)/i),
        ).toBeInTheDocument();
        expect(screen.getByRole("button", { name: "Siguiente" })).toBeDisabled();
    });

    it("blocks step 2 and shows error when volume exceeds vehicle capacity", async () => {
        const user = userEvent.setup();
        mount({
            state: {
                carrier: fakeCarrier([fakeVehicle({ volume_cm3: 20_000_000 })]),
                window: fakeWindow(),
            },
        });
        await fillAddresses(user);
        await user.click(screen.getByRole("button", { name: "Siguiente" }));

        await user.type(screen.getByLabelText("Descripción de la carga"), "Carga");
        await user.type(screen.getByLabelText("Peso (kg)"), "100");
        await user.type(screen.getByLabelText("Volumen (cm³)"), "99000000");
        expect(
            screen.getByText(/El volumen supera la capacidad del vehículo \(20.000.000 cm³\)/i),
        ).toBeInTheDocument();
        expect(screen.getByRole("button", { name: "Siguiente" })).toBeDisabled();
    });

    it("calls createCargoOffer with correct payload and shows confirmation on success", async () => {
        vi.mocked(quotesApi.createCargoOffer).mockResolvedValueOnce(fakeCargoOffer());
        const user = userEvent.setup();
        mount();

        // Step 1: Addresses
        await fillAddresses(user);
        await user.click(screen.getByRole("button", { name: "Siguiente" }));

        // Step 2: Cargo
        await user.type(screen.getByLabelText("Descripción de la carga"), "Pallets");
        await user.type(screen.getByLabelText("Peso (kg)"), "1500");
        await user.type(screen.getByLabelText("Volumen (cm³)"), "3000000");
        await user.type(screen.getByLabelText("Valor declarado (ARS)"), "5000");
        await user.click(screen.getByRole("button", { name: "Siguiente" }));

        // Step 3: Review
        await user.type(screen.getByLabelText("Kilómetros estimados del viaje"), "700");
        const dateInput = screen.getByLabelText("Fecha de retiro");
        await user.type(dateInput, "2026-05-25");

        await user.click(screen.getByRole("button", { name: "Enviar oferta" }));

        await waitFor(() => {
            expect(screen.getByTestId("confirmation-screen")).toBeInTheDocument();
        });
        expect(screen.getByText("Referencia de oferta: #42")).toBeInTheDocument();

        expect(quotesApi.createCargoOffer).toHaveBeenCalledWith(
            expect.objectContaining({
                transport_window_id: 5,
                pickup_address: "Av. Corrientes 1234, C1043 CABA, Ciudad Autónoma de Buenos Aires",
                delivery_address: "Av. Colón 500, X5000 Córdoba, Córdoba",
                cargo_description: "Pallets",
                weight_kg: "1500",
                volume_cm3: "3000000",
                declared_value_cents: "500000",
                estimated_km: "700",
            }),
        );
    });

    it("shows a top-level error alert when createCargoOffer fails", async () => {
        const { ApiError } = await import("../../api");
        vi.mocked(quotesApi.createCargoOffer).mockRejectedValueOnce(
            new ApiError(422, "unprocessable", "unprocessable", {}),
        );
        const user = userEvent.setup();
        mount();

        await fillAddresses(user);
        await user.click(screen.getByRole("button", { name: "Siguiente" }));
        await user.type(screen.getByLabelText("Descripción de la carga"), "Carga");
        await user.type(screen.getByLabelText("Peso (kg)"), "100");
        await user.type(screen.getByLabelText("Volumen (cm³)"), "100000");
        await user.type(screen.getByLabelText("Valor declarado (ARS)"), "0");
        await user.click(screen.getByRole("button", { name: "Siguiente" }));
        await user.type(screen.getByLabelText("Kilómetros estimados del viaje"), "100");
        await user.type(screen.getByLabelText("Fecha de retiro"), "2026-05-25");
        await user.click(screen.getByRole("button", { name: "Enviar oferta" }));

        await waitFor(() => {
            expect(
                screen.getByText(
                    "No se pudo enviar la oferta. Revisá los campos e intentá de nuevo.",
                ),
            ).toBeInTheDocument();
        });
    });

    it("shows cost estimate when km are entered on step 3", async () => {
        const user = userEvent.setup();
        mount();

        await fillAddresses(user);
        await user.click(screen.getByRole("button", { name: "Siguiente" }));
        await user.type(screen.getByLabelText("Descripción de la carga"), "Carga");
        await user.type(screen.getByLabelText("Peso (kg)"), "100");
        await user.type(screen.getByLabelText("Volumen (cm³)"), "100000");
        await user.type(screen.getByLabelText("Valor declarado (ARS)"), "0");
        await user.click(screen.getByRole("button", { name: "Siguiente" }));
        await user.type(screen.getByLabelText("Kilómetros estimados del viaje"), "700");

        // 700 km × $1500/km = $1,050,000
        const costEl = screen.getByTestId("cost-estimate");
        expect(costEl).toHaveTextContent("1.050.000");
    });
});
