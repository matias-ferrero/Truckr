import { beforeEach, describe, expect, it, vi } from "vitest";
import { render, screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import ShipperDashboardPage from "./ShipperDashboardPage";
import * as cargoApi from "../../../features/cargo/api";
import * as shipmentsApi from "../../../api/shipments";
import * as currentUser from "../../../auth/useCurrentUser";
import type { Cargo, CargoOffer } from "../../../types/Cargo";
import type { Shipment, ShipperActivityEvent } from "../../../api/shipments";
import type { Me } from "../../../auth/AuthContext";

vi.mock("../../../features/cargo/api");
vi.mock("../../../api/shipments");
vi.mock("../../../auth/useCurrentUser");

const cargos = vi.mocked(cargoApi);
const shipments = vi.mocked(shipmentsApi);
const auth = vi.mocked(currentUser);

// --- fixtures -------------------------------------------------------------

function makeMe(overrides: Partial<Me> = {}): Me {
    return {
        id: 1,
        email: "ana@truckr.test",
        full_name: "Ana Pérez",
        roles: ["shipper"],
        ...overrides,
    };
}

function mockUser(me: Me | null = makeMe()) {
    auth.useCurrentUser.mockReturnValue({
        me,
        loading: false,
        register: vi.fn(),
        login: vi.fn(),
        logout: vi.fn(),
        updateMe: vi.fn(),
    });
}

function makeOffer(overrides: Partial<CargoOffer> = {}): CargoOffer {
    return {
        id: 9001,
        cargo_id: 1,
        carrier_id: 5,
        transport_window_id: 7,
        amount_cents: 8_000_000,
        currency: "ARS",
        status: "pending",
        expires_at: "2026-06-20T10:00:00Z",
        created_at: "2026-06-11T10:00:00Z",
        updated_at: "2026-06-11T10:00:00Z",
        ...overrides,
    };
}

function makeCargo(overrides: Partial<Cargo> = {}): Cargo {
    return {
        id: 1,
        shipper_id: 1,
        status: "open",
        cargo_description: "Pallets",
        pickup_address: "Av. Corrientes 1234, CABA",
        pickup_lat: "-34.6",
        pickup_lng: "-58.4",
        pickup_locality: "CABA",
        pickup_admin_area: "CABA",
        delivery_address: "Av. Colón 500, Córdoba",
        delivery_lat: "-31.4",
        delivery_lng: "-64.2",
        delivery_locality: "Córdoba",
        delivery_admin_area: "Córdoba",
        pickup_window_start: "2026-06-01T08:00:00Z",
        pickup_window_end: "2026-06-03T18:00:00Z",
        weight_kg: "1500",
        volume_cm3: null,
        declared_value_cents: 5_000_000,
        cancelled_at: null,
        created_at: "2026-06-10T10:00:00Z",
        updated_at: "2026-06-10T10:00:00Z",
        editable: true,
        pending_offers_count: 0,
        cargo_offers: [],
        ...overrides,
    };
}

function makeShipment(overrides: Partial<Shipment> = {}): Shipment {
    return {
        id: 42,
        state: "delivered",
        origin: "Rosario",
        destination: "Mendoza",
        created_at: "2026-06-09T10:00:00Z",
        amount_cents: 10_000_000,
        currency: "ARS",
        latest_activity_at: "2026-06-09T10:00:00Z",
        payment_escrowed: false,
        shipper_reviewed: false,
        ...overrides,
    };
}

function makeActivity(
    overrides: Partial<ShipperActivityEvent> = {},
): ShipperActivityEvent {
    return {
        id: 1,
        shipment_id: 42,
        kind: "shipment_delivered",
        occurred_at: "2026-06-09T10:00:00Z",
        ...overrides,
    };
}

function cargoList(items: Cargo[]): cargoApi.CargoListResult {
    return {
        items,
        meta: { total: items.length, page: 1, perPage: 20, totalPages: 1 },
    };
}

function renderPage() {
    return render(
        <MemoryRouter initialEntries={["/shipper/dashboard"]}>
            <Routes>
                <Route path="/shipper/dashboard" element={<ShipperDashboardPage />} />
                <Route path="/shipper/cargos/new" element={<div>cargo-create-form</div>} />
            </Routes>
        </MemoryRouter>,
    );
}

// Resolve the three feeds to (by default) empty data.
function mockResolved({
    cargos: c = [],
    shipments: s = [],
    activity: a = [],
}: {
    cargos?: Cargo[];
    shipments?: Shipment[];
    activity?: ShipperActivityEvent[];
} = {}) {
    cargos.listCargos.mockResolvedValue(cargoList(c));
    shipments.listShipperShipments.mockResolvedValue(s);
    shipments.listShipperActivity.mockResolvedValue(a);
}

beforeEach(() => {
    vi.resetAllMocks();
    mockUser();
});

describe("ShipperDashboardPage", () => {
    it("shows the loading skeleton while the feeds are pending", () => {
        cargos.listCargos.mockReturnValue(new Promise(() => {}));
        shipments.listShipperShipments.mockReturnValue(new Promise(() => {}));
        shipments.listShipperActivity.mockReturnValue(new Promise(() => {}));
        renderPage();
        const status = screen.getByRole("status");
        expect(status).toBeInTheDocument();
        expect(status).toHaveAttribute("aria-busy", "true");
    });

    it("greets the shipper by first name", async () => {
        mockResolved();
        renderPage();
        expect(
            await screen.findByRole("heading", { name: /Hola, Ana/ }),
        ).toBeInTheDocument();
    });

    describe("error + retry", () => {
        it("shows an alert + retry button when a core feed rejects", async () => {
            cargos.listCargos.mockRejectedValue(new Error("Boom"));
            shipments.listShipperShipments.mockResolvedValue([]);
            shipments.listShipperActivity.mockResolvedValue([]);
            renderPage();
            const alert = await screen.findByRole("alert");
            expect(alert).toBeInTheDocument();
            expect(
                screen.getByRole("button", { name: "Reintentar" }),
            ).toBeInTheDocument();
        });

        it("falls back to the generic copy when the error has no message", async () => {
            cargos.listCargos.mockRejectedValue(new Error(""));
            shipments.listShipperShipments.mockResolvedValue([]);
            shipments.listShipperActivity.mockResolvedValue([]);
            renderPage();
            expect(
                await screen.findByText(/No pudimos cargar tu panel/),
            ).toBeInTheDocument();
        });

        it("refetches and renders content when retry succeeds", async () => {
            const user = userEvent.setup();
            cargos.listCargos.mockRejectedValueOnce(new Error("Network"));
            shipments.listShipperShipments.mockResolvedValue([]);
            shipments.listShipperActivity.mockResolvedValue([]);
            // After the first failure, the next attempt succeeds with a board.
            cargos.listCargos.mockResolvedValue(cargoList([makeCargo()]));
            renderPage();
            await screen.findByRole("alert");
            await user.click(screen.getByRole("button", { name: "Reintentar" }));
            expect(
                await screen.findByRole("heading", { name: "Mis cargas" }),
            ).toBeInTheDocument();
        });
    });

    describe("onboarding (brand-new shipper)", () => {
        it("shows the welcome empty state with the publish CTA", async () => {
            mockResolved({ cargos: [], shipments: [] });
            renderPage();
            const heading = await screen.findByRole("heading", {
                name: "Publicá tu primera carga",
            });
            expect(heading).toBeInTheDocument();
            // Scope to the onboarding section — the greeting also carries a
            // "Publicar carga" CTA, so the page-wide query is ambiguous.
            const onboarding = heading.closest(".dashOnboarding") as HTMLElement;
            const cta = within(onboarding).getByRole("link", { name: "Publicar carga" });
            expect(cta).toHaveAttribute("href", "/shipper/cargos/new");
        });

        it("does NOT show the board or attention panel for a new shipper", async () => {
            mockResolved({ cargos: [], shipments: [] });
            renderPage();
            await screen.findByRole("heading", { name: "Publicá tu primera carga" });
            expect(
                screen.queryByRole("heading", { name: "Mis cargas" }),
            ).not.toBeInTheDocument();
            expect(
                screen.queryByRole("heading", { name: "Atención requerida" }),
            ).not.toBeInTheDocument();
        });
    });

    describe("populated board", () => {
        function populated() {
            return {
                cargos: [
                    // searching: open cargo, no pending offers
                    makeCargo({ id: 1, pickup_locality: "CABA", delivery_locality: "La Plata" }),
                    // withOffers: open cargo with a pending offer
                    makeCargo({
                        id: 2,
                        pickup_locality: "Rosario",
                        delivery_locality: "Santa Fe",
                        cargo_offers: [makeOffer({ id: 50, cargo_id: 2, amount_cents: 7_000_000 })],
                        pending_offers_count: 1,
                    }),
                ],
                shipments: [
                    // acceptedOffers + payment pending
                    makeShipment({ id: 10, state: "accepted", payment_escrowed: false, origin: "Tucumán", destination: "Salta" }),
                    // inTransit
                    makeShipment({ id: 11, state: "in_transit", origin: "Córdoba", destination: "San Luis" }),
                    // delivered, not yet reviewed -> to_review
                    makeShipment({ id: 12, state: "delivered", shipper_reviewed: false, origin: "Neuquén", destination: "Bahía Blanca" }),
                ],
            };
        }

        it("renders all five column headers with correct counts", async () => {
            mockResolved(populated());
            renderPage();
            await screen.findByRole("heading", { name: "Mis cargas" });

            const col = (name: string) =>
                screen.getByRole("heading", { name, level: 3 }).closest(".dashColumn")!;

            const expectCount = (name: string, count: number) => {
                const region = col(name);
                expect(within(region as HTMLElement).getByText(String(count))).toBeInTheDocument();
            };

            expectCount("Buscando transporte", 1);
            expectCount("Con ofertas", 1);
            expectCount("Ofertas aceptadas", 1);
            expectCount("En tránsito", 1);
            expectCount("Entregadas", 1);
        });

        it("places each card in the right column via its link href", async () => {
            mockResolved(populated());
            renderPage();
            await screen.findByRole("heading", { name: "Mis cargas" });

            const inColumn = (colName: string, href: string) => {
                const region = screen
                    .getByRole("heading", { name: colName, level: 3 })
                    .closest(".dashColumn") as HTMLElement;
                const link = within(region).getByRole("link");
                expect(link).toHaveAttribute("href", href);
            };

            inColumn("Buscando transporte", "/shipper/cargos/1");
            inColumn("Con ofertas", "/shipper/cargos/2");
            inColumn("Ofertas aceptadas", "/shipper/shipments/10");
            inColumn("En tránsito", "/shipper/shipments/11");
            inColumn("Entregadas", "/shipper/shipments/12");
        });

        it("renders representative badge labels on cards", async () => {
            mockResolved(populated());
            renderPage();
            // Scope badge assertions to the board — "Calificar" is also an
            // attention-panel action label, so a page-wide query is ambiguous.
            const board = (await screen.findByRole("heading", { name: "Mis cargas" }))
                .closest(".dashBoard") as HTMLElement;
            const b = within(board);
            expect(b.getByText("Sin ofertas")).toBeInTheDocument();
            expect(b.getByText("1 oferta")).toBeInTheDocument();
            expect(b.getByText("Pago pendiente")).toBeInTheDocument();
            expect(b.getByText("En camino")).toBeInTheDocument();
            expect(b.getByText("Calificar")).toBeInTheDocument();
        });

        it("surfaces attention-panel counts that match the data", async () => {
            mockResolved(populated());
            renderPage();
            await screen.findByRole("heading", { name: "Atención requerida" });
            // toPay: 1 accepted+unescrowed; withoutOffers: 1 open cargo w/o offers;
            // toReview: 1 delivered+unreviewed.
            expect(screen.getByText("Envíos por pagar")).toBeInTheDocument();
            expect(screen.getByText("Cargas sin ofertas")).toBeInTheDocument();
            expect(screen.getByText("Transportistas por calificar")).toBeInTheDocument();
            // The accessible per-row count text ("1 envío" / "1 carga" / "1 entrega").
            expect(screen.getByText(/\(1 envío\)/)).toBeInTheDocument();
            expect(screen.getByText(/\(1 carga\)/)).toBeInTheDocument();
            expect(screen.getByText(/\(1 entrega\)/)).toBeInTheDocument();
        });

        it("renders the all-clear attention state when nothing is pending", async () => {
            // A single delivered+reviewed shipment: a board card exists (not a
            // new shipper) but no attention items remain.
            mockResolved({
                cargos: [],
                shipments: [makeShipment({ id: 12, state: "delivered", shipper_reviewed: true })],
            });
            renderPage();
            expect(await screen.findByText("Todo al día")).toBeInTheDocument();
        });

        it("hides the price on a card whose underlying value is absent", async () => {
            mockResolved({
                cargos: [],
                // amount_cents as a non-parseable value -> null price, no price node.
                shipments: [
                    makeShipment({
                        id: 13,
                        state: "in_transit",
                        amount_cents: Number.NaN,
                        origin: "X",
                        destination: "Y",
                    }),
                ],
            });
            renderPage();
            await screen.findByRole("heading", { name: "Mis cargas" });
            const region = screen
                .getByRole("heading", { name: "En tránsito", level: 3 })
                .closest(".dashColumn") as HTMLElement;
            expect(within(region).queryByText(/\$/)).not.toBeInTheDocument();
        });
    });

    describe("activity feed", () => {
        it("renders offer + lifecycle rows with Spanish descriptions, newest first", async () => {
            mockResolved({
                cargos: [
                    makeCargo({
                        id: 2,
                        cargo_offers: [
                            makeOffer({
                                id: 50,
                                cargo_id: 2,
                                amount_cents: 7_000_000,
                                // most recent event
                                created_at: "2026-06-12T10:00:00Z",
                            }),
                        ],
                        pending_offers_count: 1,
                    }),
                ],
                shipments: [makeShipment({ id: 12, state: "delivered", shipper_reviewed: true })],
                activity: [
                    makeActivity({
                        id: 1,
                        kind: "shipment_delivered",
                        occurred_at: "2026-06-11T10:00:00Z",
                    }),
                ],
            });
            renderPage();
            await screen.findByRole("heading", { name: "Actividad reciente" });

            expect(screen.getByText("Nueva oferta recibida")).toBeInTheDocument();
            expect(screen.getByText("Envío entregado")).toBeInTheDocument();

            // Ordering: the offer (2026-06-12) precedes the delivery (2026-06-11).
            const feed = screen
                .getByRole("heading", { name: "Actividad reciente" })
                .closest(".dashFeed") as HTMLElement;
            const rows = within(feed).getAllByRole("listitem");
            const order = rows.map((r) => r.textContent ?? "");
            const offerIdx = order.findIndex((t) => t.includes("Nueva oferta recibida"));
            const deliveredIdx = order.findIndex((t) => t.includes("Envío entregado"));
            expect(offerIdx).toBeLessThan(deliveredIdx);
        });

        it("renders the feed empty state when nothing happened yet but a board exists", async () => {
            mockResolved({
                cargos: [makeCargo({ id: 1 })],
                shipments: [],
                activity: [],
            });
            renderPage();
            await screen.findByRole("heading", { name: "Mis cargas" });
            expect(screen.getByText("Sin actividad reciente")).toBeInTheDocument();
        });

        it("keeps rendering the board when the activity feed fetch rejects (isolated failure)", async () => {
            cargos.listCargos.mockResolvedValue(cargoList([makeCargo({ id: 1 })]));
            shipments.listShipperShipments.mockResolvedValue([]);
            shipments.listShipperActivity.mockRejectedValue(new Error("feed down"));
            renderPage();
            // The board still renders despite the feed failure...
            expect(
                await screen.findByRole("heading", { name: "Mis cargas" }),
            ).toBeInTheDocument();
            // ...and the feed degrades to its empty state, not an error.
            expect(screen.getByText("Sin actividad reciente")).toBeInTheDocument();
            expect(screen.queryByRole("alert")).not.toBeInTheDocument();
        });
    });

    describe("greeting fallbacks", () => {
        it("falls back to the email local-part when full_name is empty", async () => {
            mockUser(makeMe({ full_name: "", email: "bruno@truckr.test" }));
            mockResolved();
            renderPage();
            expect(
                await screen.findByRole("heading", { name: /Hola, bruno/ }),
            ).toBeInTheDocument();
        });

        it("uses the anonymous greeting when there is no logged-in user", async () => {
            mockUser(null);
            mockResolved();
            renderPage();
            expect(
                await screen.findByRole("heading", { name: "Hola 👋" }),
            ).toBeInTheDocument();
        });
    });
});
