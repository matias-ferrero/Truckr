import { http, HttpResponse, type RequestHandler } from "msw";

const API = "http://localhost:3000";

// devise-jwt would issue real signed JWTs; tests just need a header-shaped
// string so the client's storage logic kicks in and subsequent requests
// carry an Authorization header.
const TEST_JWT = "header.payload.signature";
const TEST_AUTH_HEADER = `Bearer ${TEST_JWT}`;

type LoginBody = { user: { email: string; password: string } };
type RegisterBody = { email: string; password: string; name: string; role: string };

const TEST_PASSWORD = "Password1";

function meBody(email: string, fullName: string, roles: string[]) {
    return {
        id: 1,
        email,
        full_name: fullName,
        phone: null,
        verified_at: null,
        roles,
        carrier: roles.includes("carrier") ? { id: 1 } : null,
        shipper: roles.includes("shipper")
            ? { id: 1, company_name: null, tax_id: null, billing_address: null }
            : null,
    };
}

function fixtureVehicle(overrides: Record<string, unknown> = {}) {
    return {
        id: 7,
        carrier_id: 1,
        make: "Mercedes-Benz",
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
        description: null,
        photos: [],
        created_at: "2026-05-20T10:00:00Z",
        updated_at: "2026-05-20T10:00:00Z",
        ...overrides,
    };
}

export const handlers: RequestHandler[] = [
    // /me: 200 when the request carries Authorization, 401 otherwise.
    // Tests can override with server.use() for richer scenarios.
    http.get(`${API}/api/auth/me`, ({ request }) => {
        if (!request.headers.get("Authorization")) {
            return HttpResponse.json(
                { error: { code: "unauthorized", message: "Autenticación requerida" } },
                { status: 401 },
            );
        }
        return HttpResponse.json(meBody("me@example.com", "Test User", ["shipper"]));
    }),

    // Default PATCH /me: echoes the patched fields onto a shipper Me.
    // Individual tests override this with server.use() for richer
    // scenarios (422 duplicate email, verified_at reset, etc.).
    http.patch(`${API}/api/auth/me`, async ({ request }) => {
        if (!request.headers.get("Authorization")) {
            return HttpResponse.json(
                { error: { code: "unauthorized", message: "Autenticación requerida" } },
                { status: 401 },
            );
        }
        const body = (await request.json()) as Partial<{
            name: string;
            email: string;
            phone: string;
        }>;
        return HttpResponse.json({
            ...meBody(body.email ?? "me@example.com", body.name ?? "Test User", ["shipper"]),
            phone: body.phone ?? null,
        });
    }),

    http.post(`${API}/api/auth/login`, async ({ request }) => {
        const body = (await request.json()) as LoginBody;
        const { email, password } = body.user ?? {};
        if (password === TEST_PASSWORD) {
            return HttpResponse.json(
                meBody(email, "Test User", ["shipper"]),
                { headers: { Authorization: TEST_AUTH_HEADER } },
            );
        }
        return HttpResponse.json(
            { error: { code: "invalid_credentials", message: "Email o contraseña inválidos" } },
            { status: 401 },
        );
    }),

    http.post(`${API}/api/auth/register`, async ({ request }) => {
        const body = (await request.json()) as RegisterBody;
        return HttpResponse.json(
            meBody(body.email, body.name, [body.role]),
            { status: 201, headers: { Authorization: TEST_AUTH_HEADER } },
        );
    }),

    http.delete(`${API}/api/auth/logout`, () => new HttpResponse(null, { status: 204 })),

    http.get(`${API}/api/carriers/me/vehicles`, ({ request }) => {
        if (!request.headers.get("Authorization")) {
            return HttpResponse.json(
                { error: { code: "unauthorized", message: "Autenticación requerida" } },
                { status: 401 },
            );
        }
        return HttpResponse.json([fixtureVehicle()], { headers: pagyHeaders(1) });
    }),

    http.delete(`${API}/api/carriers/me/vehicles/:id`, ({ request, params }) => {
        if (!request.headers.get("Authorization")) {
            return HttpResponse.json(
                { error: { code: "unauthorized", message: "Autenticación requerida" } },
                { status: 401 },
            );
        }
        const id = Number(params.id);
        if (id === 404) {
            return HttpResponse.json(
                {
                    error: {
                        code: "unprocessable",
                        details: {
                            base: ["No podés dar de baja este vehículo porque todavía tiene ventanas activas."],
                        },
                    },
                },
                { status: 422 },
            );
        }
        if (id === 405) {
            return HttpResponse.json(
                {
                    error: {
                        code: "unprocessable",
                        details: {
                            base: ["No podés dar de baja este vehículo porque tiene ofertas o viajes pendientes."],
                        },
                    },
                },
                { status: 422 },
            );
        }
        return new HttpResponse(null, { status: 204 });
    }),

    // ── Cargo funnel (US27 / REQ-BE-00032) ──────────────────────────────────
    // Default handlers exercise the golden path. Individual specs override
    // with server.use() for richer scenarios (empty list, 422, 403, …).

    http.get(`${API}/api/cargos`, () =>
        HttpResponse.json([fixtureCargo()], {
            headers: pagyHeaders(1),
        })),

    http.get(`${API}/api/cargos/:id`, ({ params }) =>
        HttpResponse.json(fixtureCargo({ id: Number(params.id) }))),

    http.post(`${API}/api/cargos`, async ({ request }) => {
        const body = (await request.json()) as { cargo: Record<string, unknown> };
        return HttpResponse.json(
            fixtureCargo({ ...body.cargo, id: 99, matches: [fixtureMatch()] }),
            { status: 201 },
        );
    }),

    http.patch(`${API}/api/cargos/:id`, async ({ request, params }) => {
        const body = (await request.json()) as { cargo: Record<string, unknown> };
        return HttpResponse.json(
            fixtureCargo({ ...body.cargo, id: Number(params.id) }),
        );
    }),

    http.delete(`${API}/api/cargos/:id`, () => new HttpResponse(null, { status: 204 })),

    http.get(`${API}/api/cargos/:id/matches`, () =>
        HttpResponse.json([fixtureMatch()], { headers: pagyHeaders(1) })),

    http.post(`${API}/api/cargo_offers`, async ({ request }) => {
        const body = (await request.json()) as {
            cargo_offer: { cargo_id: number; transport_window_id: number };
        };
        return HttpResponse.json(
            {
                id: 1,
                cargo_id: body.cargo_offer.cargo_id,
                carrier_id: 1,
                transport_window_id: body.cargo_offer.transport_window_id,
                amount_cents: 105_000_000,
                currency: "ARS",
                status: "pending",
                expires_at: "2026-05-27T10:00:00Z",
                created_at: "2026-05-20T10:00:00Z",
                updated_at: "2026-05-20T10:00:00Z",
            },
            { status: 201 },
        );
    }),

    http.get(`${API}/api/cargo_offers`, () =>
        HttpResponse.json([], { headers: pagyHeaders(0) })),

    http.get(`${API}/api/carriers/me/cargo-offers`, ({ request }) => {
        const status = new URL(request.url).searchParams.get("status") ?? "pending";
        const all = [
            {
                id: 11,
                cargo_id: 7,
                carrier_id: 1,
                transport_window_id: 5,
                status: "pending",
                expires_at: "2026-06-15T12:00:00Z",
                accepted_at: null,
                rejected_at: null,
                created_at: "2026-06-10T10:00:00Z",
                updated_at: "2026-06-10T10:00:00Z",
                price_amount_cents: 105_000_000,
                cargo: {
                    id: 7,
                    pickup_address: "Av. Corrientes 1234, CABA",
                    delivery_address: "Av. Colón 500, Córdoba",
                    weight_kg: "1500.0",
                    volume_cm3: 3_000_000,
                    declared_value_cents: 5_000_000,
                    pickup_window_start: "2026-06-12T08:00:00Z",
                    pickup_window_end: "2026-06-13T18:00:00Z",
                    cargo_description: "Pallets",
                    status: "open",
                },
                shipper: { id: 1, name: "Test User" },
                transport_window: {
                    id: 5,
                    origin_locality: "CABA",
                    origin_admin_area: "Buenos Aires",
                    destination_locality: "Córdoba",
                    destination_admin_area: "Córdoba",
                    available_from: "2026-06-11T08:00:00Z",
                    available_to: "2026-06-16T18:00:00Z",
                    price_per_km: "1500.0",
                    max_km: 1000,
                    status: "pending_offer",
                },
            },
        ];

        const filtered = all.filter((item) => item.status === status);
        return HttpResponse.json(filtered, { headers: pagyHeaders(filtered.length) });
    }),

    http.post(`${API}/api/carriers/me/cargo-offers/:id/accept`, ({ params }) => {
        const id = Number(params.id);
        return HttpResponse.json({
            cargo_offer: {
                id,
                cargo_id: 7,
                carrier_id: 1,
                transport_window_id: 5,
                status: "accepted",
                expires_at: "2026-06-15T12:00:00Z",
                accepted_at: "2026-06-11T10:00:00Z",
                rejected_at: null,
                created_at: "2026-06-10T10:00:00Z",
                updated_at: "2026-06-11T10:00:00Z",
                price_amount_cents: 105_000_000,
                cargo: {
                    id: 7,
                    pickup_address: "Av. Corrientes 1234, CABA",
                    delivery_address: "Av. Colón 500, Córdoba",
                    weight_kg: "1500.0",
                    volume_cm3: 3_000_000,
                    declared_value_cents: 5_000_000,
                    pickup_window_start: "2026-06-12T08:00:00Z",
                    pickup_window_end: "2026-06-13T18:00:00Z",
                    cargo_description: "Pallets",
                    status: "accepted",
                },
                shipper: { id: 1, name: "Test User" },
                transport_window: {
                    id: 5,
                    origin_locality: "CABA",
                    origin_admin_area: "Buenos Aires",
                    destination_locality: "Córdoba",
                    destination_admin_area: "Córdoba",
                    available_from: "2026-06-11T08:00:00Z",
                    available_to: "2026-06-16T18:00:00Z",
                    price_per_km: "1500.0",
                    max_km: 1000,
                    status: "reserved",
                },
            },
            shipment: {
                id: 31,
                cargo_offer_id: id,
                status: "accepted",
                accepted_at: "2026-06-11T10:00:00Z",
                picked_up_at: null,
                delivered_at: null,
                created_at: "2026-06-11T10:00:00Z",
                updated_at: "2026-06-11T10:00:00Z",
            },
        });
    }),

    http.post(`${API}/api/carriers/me/cargo-offers/:id/reject`, ({ params }) => {
        const id = Number(params.id);
        return HttpResponse.json({
            id,
            cargo_id: 7,
            carrier_id: 1,
            transport_window_id: 5,
            status: "rejected",
            expires_at: "2026-06-15T12:00:00Z",
            accepted_at: null,
            rejected_at: "2026-06-11T10:00:00Z",
            created_at: "2026-06-10T10:00:00Z",
            updated_at: "2026-06-11T10:00:00Z",
            price_amount_cents: 105_000_000,
            cargo: {
                id: 7,
                pickup_address: "Av. Corrientes 1234, CABA",
                delivery_address: "Av. Colón 500, Córdoba",
                weight_kg: "1500.0",
                volume_cm3: 3_000_000,
                declared_value_cents: 5_000_000,
                pickup_window_start: "2026-06-12T08:00:00Z",
                pickup_window_end: "2026-06-13T18:00:00Z",
                cargo_description: "Pallets",
                status: "open",
            },
            shipper: { id: 1, name: "Test User" },
            transport_window: {
                id: 5,
                origin_zone: "Buenos Aires",
                destination_zone: "Córdoba",
                available_from: "2026-06-11T08:00:00Z",
                available_to: "2026-06-16T18:00:00Z",
                price_per_km: "1500.0",
                max_km: 1000,
                status: "open",
            },
        });
    }),

    http.get(`${API}/api/carriers/me/shipments`, () =>
        HttpResponse.json([fixtureShipment()])),

    http.get(`${API}/api/shippers/me/shipments`, () =>
        HttpResponse.json([fixtureShipment({ id: 42, state: "delivered" })])),

    // REQ-BE-00033 — single-shipment detail used by the payment success
    // screen to pull contact details after the escrow lands.
    http.get(`${API}/api/shipments/:id`, ({ params }) =>
        HttpResponse.json(fixtureShipmentDetail({ id: Number(params.id) }))),

    // REQ-BE-00033 — POST /api/shipments/:id/payments. Default lands escrowed.
    http.post(`${API}/api/shipments/:id/payments`, ({ params }) =>
        HttpResponse.json(
            { payment_id: 1, state: "escrowed", shipment_id: Number(params.id) },
            { status: 201 },
        )),

    // REQ-BE-00038 — POST start_transit / deliver (Carrier FSM transitions).
    http.post(`${API}/api/shipments/:id/start_transit`, () =>
        HttpResponse.json({}, { status: 200 })),

    http.post(`${API}/api/shipments/:id/deliver`, () =>
        HttpResponse.json({}, { status: 200 })),

    // US30 / REQ-BE-00044 — POST carrier_reviews. Echoes the submitted rating /
    // body back as a carrier-authored ReviewResource (201). Tests that need a
    // conflict / forbidden path override this per-case with server.use(...).
    http.post(`${API}/api/shipments/:id/carrier_reviews`, async ({ request }) => {
        const payload = (await request.json()) as { rating: number; body: string | null };
        return HttpResponse.json(
            {
                id: 999,
                rating: payload.rating,
                body: payload.body ?? null,
                authored_by: "carrier",
                created_at: "2026-06-12T10:00:00Z",
            },
            { status: 201 },
        );
    }),
];

function pagyHeaders(total: number): Record<string, string> {
    return {
        "X-Total": String(total),
        "X-Page": "1",
        "X-Per-Page": "20",
        "X-Total-Pages": "1",
    };
}

export function fixtureShipment(overrides: Record<string, unknown> = {}) {
    return {
        id: 31,
        state: "accepted",
        origin: "Av. Corrientes 1234, CABA",
        destination: "Av. Colón 500, Córdoba",
        created_at: "2026-06-11T10:00:00Z",
        amount_cents: 105_000_000,
        currency: "ARS",
        latest_activity_at: "2026-06-11T10:00:00Z",
        counterparty_display_name: "Transportes Demo SRL",
        ...overrides,
    };
}

export function fixtureShipmentDetail(overrides: Record<string, unknown> = {}) {
    return {
        id: 31,
        state: "delivered",
        created_at: "2026-06-11T10:00:00Z",
        picked_up_at: "2026-06-12T09:00:00Z",
        delivered_at: "2026-06-13T14:30:00Z",
        amount_cents: 105_000_000,
        currency: "ARS",
        cargo: {
            origin: "Av. Corrientes 1234, CABA",
            destination: "Av. Colón 500, Córdoba",
            description: "Pallets de electrodomésticos",
            weight_kg: "1500.0",
        },
        vehicle: {
            plate: "AAA111",
            kind: "truck_small",
        },
        counterparty: { kind: "carrier", id: 1, display_name: "Transportes Demo SRL" },
        counterparty_contact: {
            full_name: "Carrier Demo",
            email: "carrier@demo.test",
            phone: "+54 11 5555-1111",
        },
        payment: {
            id: 1,
            state: "escrowed",
            amount_cents: 105_000_000,
            currency: "ARS",
            escrowed_at: "2026-06-11T10:05:00Z",
        },
        tracking_events: [],
        available_actions: [],
        carrier_review: null,
        ...overrides,
    };
}

export function fixtureCargo(overrides: Record<string, unknown> = {}) {
    return {
        id:                   7,
        shipper_id:           1,
        status:               "open",
        cargo_description:    "Pallets de electrodomésticos",
        pickup_address:       "Av. Corrientes 1234, CABA",
        pickup_lat:           "-34.603722",
        pickup_lng:           "-58.381592",
        pickup_locality:      "CABA",
        pickup_admin_area:    "Ciudad Autónoma de Buenos Aires",
        delivery_address:     "Av. Colón 500, Córdoba",
        delivery_lat:         "-31.420083",
        delivery_lng:         "-64.188776",
        delivery_locality:    "Córdoba",
        delivery_admin_area:  "Córdoba",
        pickup_window_start:  "2026-06-01T08:00:00Z",
        pickup_window_end:    "2026-06-03T18:00:00Z",
        weight_kg:            "1500.0",
        volume_cm3:           3_000_000,
        declared_value_cents: 5_000_000,
        created_at:           "2026-05-20T10:00:00Z",
        updated_at:           "2026-05-20T10:00:00Z",
        editable:             true,
        pending_offers_count: 0,
        cargo_offers:         [],
        ...overrides,
    };
}

export function fixtureMatch(overrides: Record<string, unknown> = {}) {
    return {
        id:                     5,
        origin_address:         "Av. Corrientes 1234, CABA",
        origin_locality:        "CABA",
        origin_admin_area:      "Ciudad Autónoma de Buenos Aires",
        origin_lat:             "-34.603722",
        origin_lng:             "-58.381592",
        destination_address:    "Av. Colón 500, Córdoba",
        destination_locality:   "Córdoba",
        destination_admin_area: "Córdoba",
        destination_lat:        "-31.420083",
        destination_lng:        "-64.188776",
        pickup_radius_km:       10,
        dropoff_radius_km:      10,
        price_per_km:           "1500.0",
        max_km:                 1000,
        available_from:         "2026-05-25T00:00:00Z",
        available_to:           "2026-06-10T00:00:00Z",
        active:                 true,
        vehicle: {
            id: 10,
            make: "Volvo",
            model: "FH",
            plate: "AB123CD",
            max_load_kg: "8000.0",
        },
        carrier: {
            id: 1,
            display_name: "Transportes del Sur",
            rating_avg: "4.7",
        },
        ...overrides,
    };
}
