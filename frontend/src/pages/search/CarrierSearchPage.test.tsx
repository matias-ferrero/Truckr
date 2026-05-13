import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { describe, expect, it } from "vitest";
import { AppRoutes } from "../../routes";
import { server } from "../../test/mocks/server";

const API = "http://localhost:3000";

function searchResultPayload() {
    return [
        {
            id: 77,
            legal_name: "Fletes del Centro",
            display_name: "Fletes del Centro",
            base_city: "Buenos Aires",
            province: "CABA",
            rating_avg: "4.7",
            completed_shipments: 39,
            transport_windows: [
                {
                    id: 991,
                    origin_zone: "Buenos Aires",
                    destination_zone: "Córdoba",
                    price_per_km: "2200.0",
                    max_km: 1200,
                    available_from: "2026-05-12T08:00:00.000Z",
                    available_to: "2026-05-16T18:00:00.000Z",
                    active: true,
                },
            ],
        },
    ];
}

function carrierDetailPayload() {
    return {
        id: 77,
        legal_name: "Fletes del Centro",
        tax_id: "30700000077",
        base_city: "Buenos Aires",
        province: "CABA",
        description: null,
        rating_avg: "4.7",
        reviews_count: 12,
        completed_shipments: 39,
        vehicles: [],
        transport_windows: [],
        created_at: "",
        updated_at: "",
    };
}

describe("CarrierSearchPage", () => {
    it("busca transportistas y navega al detalle", async () => {
        server.use(
            http.get(`${API}/api/transport_windows`, () =>
                HttpResponse.json(searchResultPayload())
            ),
            http.get(`${API}/api/carriers/77`, () =>
                HttpResponse.json(carrierDetailPayload())
            ),
        );

        window.history.pushState({}, "", "/transport_windows/search");
        render(<AppRoutes />);

        const originInput = await screen.findByLabelText("Zona de origen");
        const destinationInput = await screen.findByLabelText("Zona de destino");
        const dateFromInput = await screen.findByLabelText("Retiro desde");
        const dateToInput = await screen.findByLabelText("Retiro hasta");

        await userEvent.type(originInput, "Buenos Aires");
        await userEvent.type(destinationInput, "Córdoba");
        await userEvent.type(dateFromInput, "2026-05-12");
        await userEvent.type(dateToInput, "2026-05-14");

        await userEvent.click(screen.getByRole("button", { name: "Buscar" }));

        expect(await screen.findByText("Fletes del Centro")).toBeInTheDocument();
        await userEvent.click(screen.getByRole("link", { name: "Ver detalle" }));

        expect(
            await screen.findByRole("heading", { name: "Fletes del Centro" }),
        ).toBeInTheDocument();
    });

    it("hidrata filtros desde la URL y dispara la búsqueda automáticamente", async () => {
        server.use(
            http.get(`${API}/api/transport_windows`, ({ request }) => {
                const url = new URL(request.url);
                expect(url.searchParams.get("origin_zone")).toBe("Tigre");
                expect(url.searchParams.get("destination_zone")).toBe("Belgrano");
                expect(url.searchParams.get("date_from")).toBe("2026-05-12");
                expect(url.searchParams.get("date_to")).toBe("2026-05-14");
                return HttpResponse.json(searchResultPayload());
            }),
        );

        window.history.pushState(
            {},
            "",
            "/transport_windows/search?origin_zone=Tigre&destination_zone=Belgrano&date_from=2026-05-12&date_to=2026-05-14",
        );
        render(<AppRoutes />);

        const originInput = await screen.findByLabelText("Zona de origen");
        expect(originInput).toHaveValue("Tigre");
        expect(await screen.findByLabelText("Zona de destino")).toHaveValue("Belgrano");
        expect(await screen.findByText("Fletes del Centro")).toBeInTheDocument();
    });
});
