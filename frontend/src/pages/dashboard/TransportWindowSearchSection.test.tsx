import { describe, expect, it, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter } from "react-router-dom";
import { TransportWindowSearchSection } from "./TransportWindowSearchSection";
import * as carriersApi from "../../api/carriers";
import { ApiError } from "../../api";

vi.mock("../../api/carriers");

function fakeResult(over: Partial<carriersApi.CarrierSearchResult> = {}): carriersApi.CarrierSearchResult {
    return {
        id: 1,
        legal_name: "Transportes SRL",
        display_name: "Transportes SRL",
        base_city: "CABA",
        province: "BA",
        rating_avg: "4.7",
        completed_shipments: 42,
        transport_windows: [
            {
                id: 99,
                origin_zone: "Buenos Aires",
                destination_zone: "Córdoba",
                price_per_km: "1500",
                max_km: 800,
                available_from: "2026-06-01T00:00:00Z",
                available_to: "2026-06-30T00:00:00Z",
                active: true,
            },
        ],
        ...over,
    };
}

const renderSection = () =>
    render(
        <MemoryRouter>
            <TransportWindowSearchSection />
        </MemoryRouter>,
    );

async function fillForm(user: ReturnType<typeof userEvent.setup>) {
    await user.type(screen.getByLabelText(/^origen$/i), "Buenos Aires");
    await user.type(screen.getByLabelText(/^destino$/i), "Córdoba");
    await user.type(screen.getByLabelText(/retiro desde/i), "2026-06-01");
    await user.type(screen.getByLabelText(/retiro hasta/i), "2026-06-30");
}

describe("TransportWindowSearchSection", () => {
    beforeEach(() => {
        vi.clearAllMocks();
    });

    it("renders heading, lead, and the four form fields", () => {
        renderSection();
        expect(screen.getByRole("heading", { level: 2, name: /encontrá un transportista/i })).toBeInTheDocument();
        expect(screen.getByText(/filtrá por zonas de retiro/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/^origen$/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/^destino$/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/retiro desde/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/retiro hasta/i)).toBeInTheDocument();
    });

    it("shows the idle state by default with hint copy", () => {
        renderSection();
        expect(screen.getByText(/empezá completando los filtros/i)).toBeInTheDocument();
    });

    it("disables submit until all fields are filled", async () => {
        const user = userEvent.setup();
        renderSection();
        const submit = screen.getByRole("button", { name: /^buscar$/i });
        expect(submit).toBeDisabled();
        await fillForm(user);
        expect(submit).toBeEnabled();
    });

    it("blocks submission and shows range error when date_from > date_to", async () => {
        const user = userEvent.setup();
        renderSection();
        await user.type(screen.getByLabelText(/^origen$/i), "Buenos Aires");
        await user.type(screen.getByLabelText(/^destino$/i), "Córdoba");
        await user.type(screen.getByLabelText(/retiro desde/i), "2026-06-30");
        await user.type(screen.getByLabelText(/retiro hasta/i), "2026-06-01");
        await user.click(screen.getByRole("button", { name: /^buscar$/i }));

        expect(await screen.findByRole("alert")).toHaveTextContent(/fecha hasta debe ser igual o posterior/i);
        expect(carriersApi.searchCarriers).not.toHaveBeenCalled();
        expect(screen.getByLabelText(/retiro hasta/i)).toHaveAttribute("aria-invalid", "true");
    });

    it("submits and renders result cards with carrier name, route, rating, and price", async () => {
        (carriersApi.searchCarriers as unknown as ReturnType<typeof vi.fn>).mockResolvedValue([
            fakeResult(),
        ]);
        const user = userEvent.setup();
        renderSection();
        await fillForm(user);
        await user.click(screen.getByRole("button", { name: /^buscar$/i }));

        await waitFor(() => expect(carriersApi.searchCarriers).toHaveBeenCalledTimes(1));
        expect(carriersApi.searchCarriers).toHaveBeenCalledWith({
            originZone: "Buenos Aires",
            destinationZone: "Córdoba",
            dateFrom: "2026-06-01",
            dateTo: "2026-06-30",
        });

        const card = (await screen.findByRole("link", { name: /transportes srl/i })) as HTMLAnchorElement;
        expect(card).toHaveAttribute("href", "/carriers/1");
        expect(screen.getByText(/buenos aires → córdoba/i)).toBeInTheDocument();
        expect(screen.getByText(/4\.7 · 42 viajes · caba, ba/i)).toBeInTheDocument();
        expect(screen.getByText("$ 1.500")).toBeInTheDocument();
    });

    it("renders the empty state when the API returns zero results", async () => {
        (carriersApi.searchCarriers as unknown as ReturnType<typeof vi.fn>).mockResolvedValue([]);
        const user = userEvent.setup();
        renderSection();
        await fillForm(user);
        await user.click(screen.getByRole("button", { name: /^buscar$/i }));

        await waitFor(() => expect(carriersApi.searchCarriers).toHaveBeenCalled());
        expect(await screen.findByText(/no encontramos resultados/i)).toBeInTheDocument();
    });

    it("renders the error state with retry on ApiError, then retries on click", async () => {
        const fn = carriersApi.searchCarriers as unknown as ReturnType<typeof vi.fn>;
        fn.mockRejectedValueOnce(new ApiError(500, "El servidor falló"));
        fn.mockResolvedValueOnce([fakeResult()]);
        const user = userEvent.setup();
        renderSection();
        await fillForm(user);
        await user.click(screen.getByRole("button", { name: /^buscar$/i }));

        const alert = await screen.findByRole("alert");
        expect(alert).toHaveTextContent(/no pudimos completar/i);
        expect(alert).toHaveTextContent(/el servidor falló/i);

        await user.click(screen.getByRole("button", { name: /reintentar/i }));
        await waitFor(() => expect(fn).toHaveBeenCalledTimes(2));
        expect(await screen.findByRole("link", { name: /transportes srl/i })).toBeInTheDocument();
    });

    it("falls back to legal_name when display_name is null, and to fallback when both are null", async () => {
        (carriersApi.searchCarriers as unknown as ReturnType<typeof vi.fn>).mockResolvedValue([
            fakeResult({ id: 2, display_name: null, legal_name: "Legalonly SA" }),
            fakeResult({ id: 3, display_name: null, legal_name: null }),
        ]);
        const user = userEvent.setup();
        renderSection();
        await fillForm(user);
        await user.click(screen.getByRole("button", { name: /^buscar$/i }));

        await waitFor(() => expect(carriersApi.searchCarriers).toHaveBeenCalled());
        expect(await screen.findByRole("link", { name: /legalonly sa/i })).toBeInTheDocument();
        expect(screen.getByRole("link", { name: /transportista sin nombre/i })).toBeInTheDocument();
    });

    it("shows the result count badge on the section heading after a search", async () => {
        (carriersApi.searchCarriers as unknown as ReturnType<typeof vi.fn>).mockResolvedValue([
            fakeResult({ id: 1 }),
            fakeResult({ id: 2 }),
        ]);
        const user = userEvent.setup();
        renderSection();
        await fillForm(user);
        await user.click(screen.getByRole("button", { name: /^buscar$/i }));

        await waitFor(() => expect(screen.getByLabelText(/2 resultados/i)).toBeInTheDocument());
    });

    it("shows the View all link only when results exceed the preview limit and links to the full search page with query string", async () => {
        const many = Array.from({ length: 7 }, (_, i) => fakeResult({ id: i + 1 }));
        (carriersApi.searchCarriers as unknown as ReturnType<typeof vi.fn>).mockResolvedValue(many);
        const user = userEvent.setup();
        renderSection();
        await fillForm(user);
        await user.click(screen.getByRole("button", { name: /^buscar$/i }));

        const viewAll = await screen.findByRole("link", { name: /ver todos los resultados/i });
        expect(viewAll).toHaveAttribute(
            "href",
            "/transport_windows/search?origin_zone=Buenos+Aires&destination_zone=C%C3%B3rdoba&date_from=2026-06-01&date_to=2026-06-30",
        );
        // Only 6 visible (preview limit)
        expect(screen.getAllByRole("link", { name: /transportes srl/i })).toHaveLength(6);
    });
});
