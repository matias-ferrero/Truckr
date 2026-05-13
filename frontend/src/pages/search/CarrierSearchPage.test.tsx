import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { describe, expect, it } from "vitest";
import { AppRoutes } from "../../routes";
import { server } from "../../test/mocks/server";

const API = "http://localhost:3000";

describe("CarrierSearchPage", () => {
    it("busca transportistas y navega al detalle", async () => {
        server.use(
            http.get(`${API}/api/transport_windows`, () =>
                HttpResponse.json([
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
                ])
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

        expect(await screen.findByText("Detalle del transportista")).toBeInTheDocument();
    });
});
