import { http, HttpResponse, type RequestHandler } from "msw";

const API = "http://localhost:3000";

type LoginBody = { email: string; password: string };
type RegisterBody = { email: string; password: string; name: string; role: string };

const TEST_PASSWORD = "Password1";

export const handlers: RequestHandler[] = [
    http.get(`${API}/api/auth/csrf`, () =>
        HttpResponse.json({ csrf_token: "test-csrf-token" })
    ),

    // Default: anonymous /me. Tests can override per-spec via server.use().
    http.get(`${API}/api/auth/me`, () =>
        HttpResponse.json(
            { error: { code: "unauthorized", message: "Autenticación requerida" } },
            { status: 401 },
        )
    ),

    http.post(`${API}/api/auth/login`, async ({ request }) => {
        const body = (await request.json()) as LoginBody;
        if (body.password === TEST_PASSWORD) {
            return HttpResponse.json({
                id: 1,
                email: body.email,
                full_name: "Test User",
                phone: null,
                verified_at: null,
                roles: ["shipper"],
                carrier: null,
                shipper: { id: 1, company_name: null, tax_id: null, billing_address: null },
            });
        }
        return HttpResponse.json(
            { error: { code: "invalid_credentials", message: "Email o contraseña inválidos" } },
            { status: 401 },
        );
    }),

    http.post(`${API}/api/auth/register`, async ({ request }) => {
        const body = (await request.json()) as RegisterBody;
        const roles = body.role === "both" ? ["carrier", "shipper"] : [body.role];
        return HttpResponse.json(
            {
                id: 42,
                email: body.email,
                full_name: body.name,
                phone: null,
                verified_at: null,
                roles,
                carrier: roles.includes("carrier") ? { id: 1 } : null,
                shipper: roles.includes("shipper") ? { id: 1 } : null,
            },
            { status: 201 },
        );
    }),

    http.delete(`${API}/api/auth/logout`, () => new HttpResponse(null, { status: 204 })),
];
