import { describe, expect, it, vi } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import { MemoryRouter } from "react-router-dom";
import { DashboardPage } from "./DashboardPage";
import * as authHook from "../../auth/useCurrentUser";
import * as vehiclesApi from "../../api/vehicles";
import * as transportWindowsApi from "../../api/transport_windows";
import * as carriersApi from "../../api/carriers";

vi.mock("../../auth/useCurrentUser");
vi.mock("../../api/vehicles");
vi.mock("../../api/transport_windows");
vi.mock("../../api/carriers");

type MeShape = Parameters<typeof authHook.useCurrentUser>[0] extends never ? object : never;
const _typeOnly: MeShape | undefined = undefined;
void _typeOnly;

function fakeMe(over: Partial<{ full_name: string | null; email: string; roles: string[] }> = {}) {
    return {
        id: 1,
        email: "ana@example.com",
        full_name: "Ana García",
        phone: null,
        verified_at: null,
        roles: ["shipper"],
        carrier: null,
        shipper: { id: 1 },
        ...over,
    };
}

function mockMe(me: ReturnType<typeof fakeMe> | null, loading = false) {
    (authHook.useCurrentUser as unknown as ReturnType<typeof vi.fn>).mockReturnValue({
        me,
        loading,
        bootstrap: vi.fn(),
        login: vi.fn(),
        register: vi.fn(),
        logout: vi.fn(),
    });
}

function fakeWindow(over: Partial<transportWindowsApi.TransportWindow> = {}): transportWindowsApi.TransportWindow {
    return {
        id: 1,
        vehicle_id: 1,
        origin_zone: "Centro",
        destination_zone: "Pilar",
        price_per_km: "150.00",
        max_km: 100,
        available_from: "2026-06-01T09:00:00.000Z",
        available_to: "2026-06-30T18:00:00.000Z",
        active: true,
        vehicle: { id: 1, make: "MB", model: "Sprinter", plate: "AAA111", vehicle_type: "van" },
        created_at: "",
        updated_at: "",
        ...over,
    };
}

function fakeVehicle(over: Partial<vehiclesApi.Vehicle> = {}): vehiclesApi.Vehicle {
    return {
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
    };
}

const renderPage = () =>
    render(
        <MemoryRouter>
            <DashboardPage />
        </MemoryRouter>,
    );

describe("DashboardPage", () => {
    it("renders a skeleton while bootstrapping", () => {
        mockMe(null, true);
        const { container } = renderPage();
        expect(container.querySelector('[aria-busy="true"]')).toBeInTheDocument();
        expect(container.querySelectorAll(".dashboardSkeletonCard").length).toBe(3);
    });

    it("renders nothing when bootstrap finishes and there is no user", () => {
        mockMe(null, false);
        const { container } = renderPage();
        expect(container.firstChild).toBeNull();
    });

    it("renders the shipper view: greeting, role eyebrow, carrier-search section, and trips — no carrier-only sections, no redundant profile CTAs in the hero", () => {
        mockMe(fakeMe({ roles: ["shipper"], full_name: "Ana García", email: "ana@example.com" }));
        renderPage();

        expect(screen.getByRole("heading", { level: 1, name: /hola, ana/i })).toBeInTheDocument();
        expect(screen.getByText(/panel · expedidor/i)).toBeInTheDocument();
        expect(screen.getByRole("heading", { level: 2, name: /encontrá un transportista/i })).toBeInTheDocument();
        expect(screen.getByRole("heading", { level: 2, name: /mis viajes/i })).toBeInTheDocument();
        expect(screen.queryByRole("heading", { level: 2, name: /mi disponibilidad/i })).toBeNull();
        expect(screen.queryByRole("heading", { level: 2, name: /mi flota/i })).toBeNull();
        // Profile entry lives in the header now; the hero must not duplicate it.
        expect(screen.queryByText("ana@example.com")).toBeNull();
        expect(screen.queryByRole("link", { name: /editar mi perfil/i })).toBeNull();
        expect(screen.queryByRole("link", { name: /ver mi perfil público/i })).toBeNull();
    });

    it("does not render the carrier-search section in the carrier view", async () => {
        mockMe(fakeMe({ roles: ["carrier"], full_name: "Beto" }));
        const listMock = vehiclesApi.listMyVehicles as unknown as ReturnType<typeof vi.fn>;
        listMock.mockResolvedValue({
            items: [],
            meta: { total: 0, page: 1, perPage: 20, totalPages: 0 },
        });
        (transportWindowsApi.listMyTransportWindows as unknown as ReturnType<typeof vi.fn>).mockResolvedValue({
            items: [],
            meta: { total: 0, page: 1, perPage: 20, totalPages: 1 },
        });
        renderPage();
        await waitFor(() => expect(listMock).toHaveBeenCalled());
        expect(screen.queryByRole("heading", { level: 2, name: /encontrá un transportista/i })).toBeNull();
        expect(carriersApi.searchCarriers).not.toHaveBeenCalled();
        // Don't leak call counts into later carrier-view tests.
        listMock.mockClear();
        (transportWindowsApi.listMyTransportWindows as unknown as ReturnType<typeof vi.fn>).mockClear();
    });

    it("uses the email local-part as fallback greeting when full_name is empty", () => {
        mockMe(fakeMe({ full_name: "", email: "ana@example.com" }));
        renderPage();
        expect(screen.getByRole("heading", { level: 1, name: /hola, ana/i })).toBeInTheDocument();
    });

    it("shows the empty-state for trips (no real trips API yet)", () => {
        mockMe(fakeMe());
        renderPage();
        expect(screen.getByText(/todavía no tenés viajes/i)).toBeInTheDocument();
        // Filters and "new trip" CTA were dropped along with the mocked trip data —
        // they implied features the backend doesn't ship yet.
        expect(screen.queryByRole("button", { name: /^todos$/i })).toBeNull();
        expect(screen.queryByRole("link", { name: /nuevo viaje/i })).toBeNull();
    });

    it("renders the carrier view: disponibilidad + vehículos sections and fetches vehicles", async () => {
        mockMe(fakeMe({ roles: ["carrier"], full_name: "Beto", email: "beto@example.com" }));
        (vehiclesApi.listMyVehicles as unknown as ReturnType<typeof vi.fn>).mockResolvedValue({
            items: [fakeVehicle({ plate: "AAA111", make: "MB", model: "Sprinter" })],
            meta: { total: 1, page: 1, perPage: 20, totalPages: 1 },
        });
        (transportWindowsApi.listMyTransportWindows as unknown as ReturnType<typeof vi.fn>).mockResolvedValue({
            items: [
                fakeWindow({ origin_zone: "Centro", destination_zone: "Pilar" }),
                fakeWindow({ id: 2, origin_zone: "San Isidro", destination_zone: "CABA" }),
            ],
            meta: { total: 2, page: 1, perPage: 20, totalPages: 1 },
        });

        renderPage();

        expect(screen.getByText(/panel · transportista/i)).toBeInTheDocument();
        expect(screen.getByRole("heading", { level: 2, name: /mi disponibilidad/i })).toBeInTheDocument();
        expect(screen.getByRole("heading", { level: 2, name: /mi flota/i })).toBeInTheDocument();

        await waitFor(() => {
            expect(screen.getByText("Centro → Pilar")).toBeInTheDocument();
            expect(screen.getByText("San Isidro → CABA")).toBeInTheDocument();
            expect(screen.getByText("AAA111")).toBeInTheDocument();
        });
        expect(screen.getByText(/mb sprinter/i)).toBeInTheDocument();
        expect(vehiclesApi.listMyVehicles).toHaveBeenCalledTimes(1);
        expect(transportWindowsApi.listMyTransportWindows).toHaveBeenCalledTimes(1);
    });

    it("shows the empty vehicle state when the carrier has no vehicles", async () => {
        mockMe(fakeMe({ roles: ["carrier"], full_name: "Beto" }));
        (vehiclesApi.listMyVehicles as unknown as ReturnType<typeof vi.fn>).mockResolvedValue({
            items: [],
            meta: { total: 0, page: 1, perPage: 20, totalPages: 0 },
        });
        (transportWindowsApi.listMyTransportWindows as unknown as ReturnType<typeof vi.fn>).mockResolvedValue({
            items: [],
            meta: { total: 0, page: 1, perPage: 20, totalPages: 1 },
        });

        renderPage();

        await waitFor(() =>
            expect(screen.getByText(/aún no cargaste un vehículo/i)).toBeInTheDocument()
        );
    });

    it("swallows vehicle-fetch errors and still renders the page", async () => {
        mockMe(fakeMe({ roles: ["carrier"], full_name: "Beto" }));
        (vehiclesApi.listMyVehicles as unknown as ReturnType<typeof vi.fn>).mockRejectedValue(
            new Error("boom"),
        );
        (transportWindowsApi.listMyTransportWindows as unknown as ReturnType<typeof vi.fn>).mockResolvedValue({
            items: [],
            meta: { total: 0, page: 1, perPage: 20, totalPages: 1 },
        });
        const consoleError = vi.spyOn(console, "error").mockImplementation(() => {});

        renderPage();

        await waitFor(() => expect(vehiclesApi.listMyVehicles).toHaveBeenCalled());
        expect(screen.getByRole("heading", { level: 2, name: /mi flota/i })).toBeInTheDocument();
        consoleError.mockRestore();
    });
});
