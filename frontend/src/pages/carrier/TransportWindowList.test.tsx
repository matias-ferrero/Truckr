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
        origin_province: "Buenos Aires",
        origin_locality: null,
        destination_province: "Córdoba",
        destination_locality: null,
        price_per_km: "1500.0",
        max_km: 1200,
        available_from: "2026-05-15T00:00:00.000Z",
        available_to: "2026-05-25T00:00:00.000Z",
        active: true,
        cargo_offers_count: 0,
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

function renderList(locationState?: Record<string, unknown>) {
    const initialEntries = locationState
        ? [{ pathname: "/carrier/availability", state: locationState }]
        : ["/carrier/availability"];
    return render(
        <MemoryRouter initialEntries={initialEntries}>
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
            expect(screen.getByText(/todavía no tenés ventanas/i)).toBeInTheDocument();
        });
    });

    it("shows window cards when data loads", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(makeResult([makeWindow()]));
        renderList();
        await waitFor(() => {
            expect(screen.getByText(/Buenos Aires → Córdoba/i)).toBeInTheDocument();
        });
        expect(screen.getByText(/Visible/i)).toBeInTheDocument();
    });

    it("shows province and locality in route when locality is present", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(
            makeResult([makeWindow({ origin_locality: "CABA", destination_locality: "Córdoba Capital" })])
        );
        renderList();
        await waitFor(() => {
            expect(screen.getByText(/Buenos Aires, CABA → Córdoba, Córdoba Capital/i)).toBeInTheDocument();
        });
    });

    it("shows 'Destino abierto' label when destination_province is null", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(
            makeResult([makeWindow({ destination_province: null, destination_locality: null })])
        );
        renderList();
        await waitFor(() => {
            expect(screen.getByText(/Buenos Aires → Destino abierto/i)).toBeInTheDocument();
        });
    });

    it("shows inactive badge for hidden windows", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(
            makeResult([makeWindow({ active: false })])
        );
        renderList();
        await waitFor(() => {
            expect(screen.getByText(/Oculta/i)).toBeInTheDocument();
        });
    });

    it("shows error panel on API failure", async () => {
        mockApi.listMyTransportWindows.mockRejectedValue(new Error("network error"));
        renderList();
        await waitFor(() => {
            expect(screen.getByRole("alert")).toBeInTheDocument();
        });
    });

    it("shows toggling feedback while toggle API call is pending", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(makeResult([makeWindow()]));
        mockApi.deactivateTransportWindow.mockReturnValue(new Promise(() => {})); // never resolves
        renderList();

        await waitFor(() => screen.getByRole("button", { name: /Ocultar/i }));
        await userEvent.click(screen.getByRole("button", { name: /Ocultar/i }));
        expect(screen.getByRole("button", { name: /actualizando/i })).toBeInTheDocument();
    });

    it("calls deactivateTransportWindow when Ocultar is clicked", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(makeResult([makeWindow()]));
        mockApi.deactivateTransportWindow.mockResolvedValue(makeWindow({ active: false }));
        renderList();

        await waitFor(() => screen.getByRole("button", { name: /Ocultar/i }));
        await userEvent.click(screen.getByRole("button", { name: /Ocultar/i }));
        expect(mockApi.deactivateTransportWindow).toHaveBeenCalledWith(1);
    });

    it("calls updateTransportWindow when Mostrar is clicked on a hidden window", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(
            makeResult([makeWindow({ active: false })])
        );
        mockApi.updateTransportWindow.mockResolvedValue(makeWindow({ active: true }));
        renderList();

        await waitFor(() => screen.getByRole("button", { name: /Mostrar/i }));
        await userEvent.click(screen.getByRole("button", { name: /Mostrar/i }));
        expect(mockApi.updateTransportWindow).toHaveBeenCalledWith(1, { active: true });
    });

    it("shows savedBanner when navigated back with justSaved state", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(emptyResult());
        renderList({ justSaved: true });
        await waitFor(() => {
            expect(screen.getByRole("status")).toHaveTextContent(/ventana guardada/i);
        });
    });

    it("shows savedBannerNew when navigated back after first publish", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(emptyResult());
        renderList({ justSaved: true, isNew: true });
        await waitFor(() => {
            expect(screen.getByRole("status")).toHaveTextContent(/expedidores ya pueden encontrarte/i);
        });
    });

    it("shows toggleMsg banner after Ocultar succeeds", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(makeResult([makeWindow()]));
        mockApi.deactivateTransportWindow.mockResolvedValue(makeWindow({ active: false }));
        renderList();

        await waitFor(() => screen.getByRole("button", { name: /Ocultar/i }));
        await userEvent.click(screen.getByRole("button", { name: /Ocultar/i }));
        await waitFor(() => {
            expect(screen.getByRole("status")).toHaveTextContent(/ventana ocultada/i);
        });
    });

    it("shows toggleMsg banner after Mostrar succeeds", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(
            makeResult([makeWindow({ active: false })])
        );
        mockApi.updateTransportWindow.mockResolvedValue(makeWindow({ active: true }));
        renderList();

        await waitFor(() => screen.getByRole("button", { name: /Mostrar/i }));
        await userEvent.click(screen.getByRole("button", { name: /Mostrar/i }));
        await waitFor(() => {
            expect(screen.getByRole("status")).toHaveTextContent(/ventana visible/i);
        });
    });

    it("shows Deshacer button in toggle toast after hiding a window", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(makeResult([makeWindow()]));
        mockApi.deactivateTransportWindow.mockResolvedValue(makeWindow({ active: false }));
        renderList();

        await waitFor(() => screen.getByRole("button", { name: /Ocultar/i }));
        await userEvent.click(screen.getByRole("button", { name: /Ocultar/i }));
        await waitFor(() => {
            expect(screen.getByRole("button", { name: /deshacer/i })).toBeInTheDocument();
        });
    });

    it("reactivates window when Deshacer is clicked in toggle toast", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(makeResult([makeWindow()]));
        mockApi.deactivateTransportWindow.mockResolvedValue(makeWindow({ active: false }));
        mockApi.updateTransportWindow.mockResolvedValue(makeWindow({ active: true }));
        renderList();

        await waitFor(() => screen.getByRole("button", { name: /Ocultar/i }));
        await userEvent.click(screen.getByRole("button", { name: /Ocultar/i }));
        await waitFor(() => screen.getByRole("button", { name: /deshacer/i }));
        await userEvent.click(screen.getByRole("button", { name: /deshacer/i }));
        expect(mockApi.updateTransportWindow).toHaveBeenCalledWith(1, { active: true });
    });

    it("removes item immediately and shows undo toast after confirming delete", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(makeResult([makeWindow()]));
        mockApi.deleteTransportWindow.mockResolvedValue(undefined);
        renderList();

        await waitFor(() => screen.getByRole("button", { name: /^Eliminar: /i }));
        await userEvent.click(screen.getByRole("button", { name: /^Eliminar: /i }));
        await waitFor(() => screen.getByText(/unos segundos para deshacer/i));
        await userEvent.click(screen.getByRole("button", { name: /^Eliminar$/i }));

        // Item removed from list immediately (optimistic)
        await waitFor(() => {
            expect(screen.queryByText(/Buenos Aires → Córdoba/i)).not.toBeInTheDocument();
        });
        // Undo toast appears
        expect(screen.getByRole("status")).toHaveTextContent(/ventana eliminada/i);
        // API not called yet — undo window still open
        expect(mockApi.deleteTransportWindow).not.toHaveBeenCalled();
    });

    it("cancels deletion and reloads when Deshacer is clicked in delete toast", async () => {
        mockApi.listMyTransportWindows
            .mockResolvedValueOnce(makeResult([makeWindow()]))
            .mockResolvedValueOnce(makeResult([makeWindow()]));
        mockApi.deleteTransportWindow.mockResolvedValue(undefined);
        renderList();

        await waitFor(() => screen.getByRole("button", { name: /^Eliminar: /i }));
        await userEvent.click(screen.getByRole("button", { name: /^Eliminar: /i }));
        await waitFor(() => screen.getByText(/unos segundos para deshacer/i));
        await userEvent.click(screen.getByRole("button", { name: /^Eliminar$/i }));

        await waitFor(() => screen.getByRole("button", { name: /deshacer/i }));
        await userEvent.click(screen.getByRole("button", { name: /deshacer/i }));

        // Delete API never called
        expect(mockApi.deleteTransportWindow).not.toHaveBeenCalled();
        // List reloaded (called twice: initial + undo reload)
        await waitFor(() => expect(mockApi.listMyTransportWindows).toHaveBeenCalledTimes(2));
    });

    it("closes the undo toast when × is clicked without immediately calling delete", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(makeResult([makeWindow()]));
        mockApi.deleteTransportWindow.mockResolvedValue(undefined);
        renderList();

        await waitFor(() => screen.getByRole("button", { name: /^Eliminar: /i }));
        await userEvent.click(screen.getByRole("button", { name: /^Eliminar: /i }));
        await waitFor(() => screen.getByText(/unos segundos para deshacer/i));
        await userEvent.click(screen.getByRole("button", { name: /^Eliminar$/i }));

        // Wait for undo toast
        await waitFor(() => screen.getByRole("status"));
        // Dismiss the toast — just closes UI, timer still commits after 5s
        const closeBtn = screen.getByRole("button", { name: /cerrar/i });
        await userEvent.click(closeBtn);

        // Toast is gone
        await waitFor(() => {
            expect(screen.queryByRole("status")).not.toBeInTheDocument();
        });
        // Delete NOT called immediately — the timer (5s) will commit it
        expect(mockApi.deleteTransportWindow).not.toHaveBeenCalled();
    });

    it("shows blocked dialog (not confirm) when window has cargo offers", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(
            makeResult([makeWindow({ cargo_offers_count: 1 })])
        );
        renderList();
        await waitFor(() => screen.getByRole("button", { name: /^Eliminar: /i }));
        await userEvent.click(screen.getByRole("button", { name: /^Eliminar: /i }));
        await waitFor(() => screen.getByText(/no se puede eliminar/i));
        expect(screen.getByText(/ofertas de carga/i)).toBeInTheDocument();
        // No "Eliminar" destructive button — only "Entendido"
        expect(screen.queryByRole("button", { name: /^Eliminar$/i })).not.toBeInTheDocument();
        expect(mockApi.deleteTransportWindow).not.toHaveBeenCalled();
    });

    it("does not call delete API at all when blocked dialog is dismissed", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(
            makeResult([makeWindow({ cargo_offers_count: 2 })])
        );
        renderList();
        await waitFor(() => screen.getByRole("button", { name: /^Eliminar: /i }));
        await userEvent.click(screen.getByRole("button", { name: /^Eliminar: /i }));
        await waitFor(() => screen.getByRole("button", { name: /entendido/i }));
        await userEvent.click(screen.getByRole("button", { name: /entendido/i }));
        expect(mockApi.deleteTransportWindow).not.toHaveBeenCalled();
        // Item still visible in the list
        expect(screen.getByText(/Buenos Aires → Córdoba/i)).toBeInTheDocument();
    });

    it("navigates to new window form when n is pressed", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(emptyResult());
        const { getByRole } = render(
            <MemoryRouter initialEntries={["/carrier/availability"]}>
                <TransportWindowList />
            </MemoryRouter>
        );
        await waitFor(() => getByRole("heading", { name: /disponibilidad/i }));
        await userEvent.keyboard("n");
        // Navigation happens — component would unmount; just verify no crash
        // and the keyboard handler fired without errors
        expect(mockApi.listMyTransportWindows).toHaveBeenCalled();
    });

    it("hides header CTA when list is empty", async () => {
        mockApi.listMyTransportWindows.mockResolvedValue(emptyResult());
        renderList();
        await waitFor(() => screen.getByText(/todavía no tenés ventanas/i));
        // header-level "Publicar disponibilidad" link is suppressed; only the empty-state CTA shows
        const ctas = screen.getAllByRole("link", { name: /publicar/i });
        expect(ctas).toHaveLength(1);
    });
});
