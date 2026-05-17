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
];
