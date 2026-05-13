import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter } from "react-router-dom";
import TransportWindowList from "./TransportWindowList";
import * as twApi from "../../api/transport_windows";

vi.mock("../../api/transport_windows");

const mockApi = vi.mocked(twApi);

function makeWindow(overrides: Partial<twApi.TransportWindow> = {}): twApi.TransportWindow {
    return {
        id: 1,
        vehicle_id: 10,
        origin_zone: "Buenos Aires",
        destination_zone: "Córdoba",
        price_per_km: "1500.0",
        max_km: 1200,
        available_from: "2026-05-15T00:00:00.000Z",
        available_to: "2026-05-25T00:00:00.000Z",
        active: true,
        vehicle: { id: 10, make: "MB", model: "Sprinter", plate: "AA001XX", vehicle_type: "truck_small" },
        created_at: "2026-05-11T00:00:00.000Z",
        updated_at: "2026-05-11T00:00:00.000Z",
        ...overrides,
    };
}

function emptyResult(): twApi.TransportWindowListResult {
    return { items: [], meta: { total: 0, page: 1, perPage: 20, totalPages: 1 } };
}

function makeResult(windows: twApi.TransportWindow[]): twApi.TransportWindowListResult {
    return { items: windows, meta: { total: windows.length, page: 1, perPage: 20, totalPages: 1 } };
}

function renderList() {
    return render(
        <MemoryRouter>
            <TransportWindowList />
        </MemoryRouter>
    );
}

beforeEach(() => {
    vi.resetAllMocks();
});

describe("TransportWindowList", () => {
    it("shows the heading", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(emptyResult());
        renderList();
        expect(screen.getByRole("heading", { name: /disponibilidad/i })).toBeInTheDocument();
    });

    it("shows loading state initially", () => {
        mockApi.listMyTransportWindows.mockReturnValue(new Promise(() => {}));
        renderList();
        expect(screen.getByLabelText(/cargando disponibilidad/i)).toBeInTheDocument();
    });

    it("shows empty state when no windows", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(emptyResult());
        renderList();
        await waitFor(() => {
            expect(screen.getByText(/todavía no publicaste/i)).toBeInTheDocument();
        });
    });

    it("shows window cards when data loads", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(makeResult([makeWindow()]));
        renderList();
        await waitFor(() => {
            expect(screen.getByText(/Buenos Aires → Córdoba/i)).toBeInTheDocument();
        });
        expect(screen.getByText(/Publicada/i)).toBeInTheDocument();
    });

    it("shows inactive badge for inactive windows", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(
            makeResult([makeWindow({ active: false })])
        );
        renderList();
        await waitFor(() => {
            expect(screen.getByText(/Sin publicar/i)).toBeInTheDocument();
        });
    });

    it("shows error panel on API failure", async () => {
        mockApi.listMyTransportWindows.mockRejectedValue(new Error("network error"));
        renderList();
        await waitFor(() => {
            expect(screen.getByRole("alert")).toHaveTextContent(/network error/i);
        });
    });

    it("calls deactivateTransportWindow when Despublicar is clicked", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(makeResult([makeWindow()]));
        mockApi.deactivateTransportWindow.mockResolvedValue(makeWindow({ active: false }));
        renderList();

        await waitFor(() => screen.getByRole("button", { name: /Despublicar/i }));
        await userEvent.click(screen.getByRole("button", { name: /Despublicar/i }));
        expect(mockApi.deactivateTransportWindow).toHaveBeenCalledWith(1);
    });

    it("calls deleteTransportWindow after confirm when Eliminar is clicked", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(makeResult([makeWindow()]));
        mockApi.deleteTransportWindow.mockResolvedValue(undefined);
        renderList();

        await waitFor(() => screen.getByRole("button", { name: /^Eliminar$/i }));
        await userEvent.click(screen.getByRole("button", { name: /^Eliminar$/i }));
        // confirm step appears
        await waitFor(() => screen.getByText(/permanente/i));
        // [0] is the card's trigger button; [1] is the dialog's confirm button
        await userEvent.click(screen.getAllByRole("button", { name: /^Eliminar$/i })[1]);
        expect(mockApi.deleteTransportWindow).toHaveBeenCalledWith(1);
    });

    it("calls updateTransportWindow when Publicar is clicked on an unpublished window", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(
            makeResult([makeWindow({ active: false })])
        );
        mockApi.updateTransportWindow.mockResolvedValue(makeWindow({ active: true }));
        renderList();

        // aria-label includes route context: "Publicar: Buenos Aires → Córdoba"
        await waitFor(() => screen.getByRole("button", { name: /Publicar/i }));
        await userEvent.click(screen.getByRole("button", { name: /Publicar/i }));
        expect(mockApi.updateTransportWindow).toHaveBeenCalledWith(1, { active: true });
    });
});
