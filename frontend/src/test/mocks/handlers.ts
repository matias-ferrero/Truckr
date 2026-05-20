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
];

function pagyHeaders(total: number): Record<string, string> {
    return {
        "X-Total": String(total),
        "X-Page": "1",
        "X-Per-Page": "20",
        "X-Total-Pages": "1",
    };
}

export function fixtureCargo(overrides: Record<string, unknown> = {}) {
    return {
        id: 7,
        shipper_id: 1,
        status: "open",
        cargo_description: "Pallets de electrodomésticos",
        pickup_address: "Av. Corrientes 1234, CABA",
        delivery_address: "Av. Colón 500, Córdoba",
        pickup_zone: "Buenos Aires",
        delivery_zone: "Córdoba",
        pickup_window_start: "2026-06-01T08:00:00Z",
        pickup_window_end: "2026-06-03T18:00:00Z",
        weight_kg: "1500.0",
        volume_cm3: 3_000_000,
        declared_value_cents: 5_000_000,
        cancelled_at: null,
        created_at: "2026-05-20T10:00:00Z",
        updated_at: "2026-05-20T10:00:00Z",
        editable: true,
        pending_offers_count: 0,
        cargo_offers: [],
        ...overrides,
    };
}

export function fixtureMatch(overrides: Record<string, unknown> = {}) {
    return {
        id: 5,
        origin_zone: "Buenos Aires",
        destination_zone: "Córdoba",
        price_per_km: "1500.0",
        max_km: 1000,
        available_from: "2026-05-25T00:00:00Z",
        available_to: "2026-06-10T00:00:00Z",
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
