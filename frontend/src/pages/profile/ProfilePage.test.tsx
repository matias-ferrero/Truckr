import { describe, expect, it } from "vitest";
import { render, screen, waitFor, within } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { http, HttpResponse } from "msw";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { AuthProvider } from "../../auth/AuthContext";
import { server } from "../../test/mocks/server";
import ProfilePage from "./ProfilePage";

const API = "http://localhost:3000";

// Helper that mounts ProfilePage with a pre-seeded JWT, so the auth
// bootstrap inside AuthProvider succeeds and the page actually
// hydrates from the GET /me handler. The "/previous" entry sits below
// "/profile" in history so a Cancel click (navigate(-1)) lands on a
// recognisable sentinel route.
function renderProfile() {
    window.localStorage.setItem("truckr.jwt", "header.payload.signature");
    return render(
        <MemoryRouter initialEntries={["/previous", "/profile"]} initialIndex={1}>
            <AuthProvider>
                <Routes>
                    <Route path="/profile" element={<ProfilePage />} />
                    <Route path="/carrier/vehicles" element={<div>vehicles</div>} />
                    <Route path="/previous" element={<div>previous page</div>} />
                </Routes>
            </AuthProvider>
        </MemoryRouter>,
    );
}

function shipperMe(overrides: Record<string, unknown> = {}) {
    return {
        id: 1,
        email: "ana@example.com",
        full_name: "Ana Pérez",
        phone: "+5491133334444",
        verified_at: "2026-01-01T00:00:00Z",
        roles: ["shipper"],
        carrier: null,
        shipper: { id: 1, company_name: null, tax_id: null, billing_address: null },
        ...overrides,
    };
}

function carrierMe(overrides: Record<string, unknown> = {}) {
    return {
        ...shipperMe(),
        roles: ["carrier"],
        carrier: { id: 1 },
        shipper: null,
        ...overrides,
    };
}

describe("ProfilePage", () => {
    it("hydrates the form with the current user's data", async () => {
        server.use(http.get(`${API}/api/auth/me`, () => HttpResponse.json(shipperMe())));

        renderProfile();

        const nameInput = await screen.findByLabelText(/nombre completo/i);
        expect(nameInput).toHaveValue("Ana Pérez");
        expect(screen.getByLabelText(/^email$/i)).toHaveValue("ana@example.com");
        expect(screen.getByLabelText(/teléfono/i)).toHaveValue("+5491133334444");
    });

    it("keeps the save button disabled until the form is dirty", async () => {
        server.use(http.get(`${API}/api/auth/me`, () => HttpResponse.json(shipperMe())));

        const user = userEvent.setup();
        renderProfile();

        const saveBtn = await screen.findByRole("button", { name: /^guardar cambios$/i });
        expect(saveBtn).toBeDisabled();

        await user.clear(screen.getByLabelText(/nombre completo/i));
        await user.type(screen.getByLabelText(/nombre completo/i), "Ana M. Pérez");
        expect(saveBtn).toBeEnabled();
    });

    it("validates email format inline before submitting", async () => {
        server.use(http.get(`${API}/api/auth/me`, () => HttpResponse.json(shipperMe())));

        const user = userEvent.setup();
        renderProfile();

        const emailInput = await screen.findByLabelText(/^email$/i);
        await user.clear(emailInput);
        await user.type(emailInput, "not-an-email");

        await user.click(screen.getByRole("button", { name: /^guardar cambios$/i }));
        expect(await screen.findByText(/no parece válido/i)).toBeInTheDocument();
    });

    it("validates the phone format inline", async () => {
        server.use(http.get(`${API}/api/auth/me`, () => HttpResponse.json(shipperMe())));

        const user = userEvent.setup();
        renderProfile();

        const phone = await screen.findByLabelText(/teléfono/i);
        await user.clear(phone);
        await user.type(phone, "abc!!!");

        await user.click(screen.getByRole("button", { name: /^guardar cambios$/i }));
        expect(await screen.findByText(/solo puede contener números/i)).toBeInTheDocument();
    });

    it("rejects an empty name", async () => {
        server.use(http.get(`${API}/api/auth/me`, () => HttpResponse.json(shipperMe())));

        const user = userEvent.setup();
        renderProfile();

        const nameInput = await screen.findByLabelText(/nombre completo/i);
        await user.clear(nameInput);
        // Trigger a save attempt by editing another field to mark dirty, then clearing name.
        await user.type(screen.getByLabelText(/teléfono/i), "0");
        await user.click(screen.getByRole("button", { name: /^guardar cambios$/i }));
        expect(await screen.findByText(/no puede estar vacío/i)).toBeInTheDocument();
    });

    it("shows a success message after saving", async () => {
        server.use(
            http.get(`${API}/api/auth/me`, () => HttpResponse.json(shipperMe())),
            http.patch(`${API}/api/auth/me`, async ({ request }) => {
                const body = (await request.json()) as { name?: string };
                return HttpResponse.json(shipperMe({ full_name: body.name ?? "Ana Pérez" }));
            }),
        );

        const user = userEvent.setup();
        renderProfile();

        const nameInput = await screen.findByLabelText(/nombre completo/i);
        await user.clear(nameInput);
        await user.type(nameInput, "Ana M. Pérez");

        await user.click(screen.getByRole("button", { name: /^guardar cambios$/i }));
        expect(await screen.findByText(/actualizados correctamente/i)).toBeInTheDocument();

        // After save, the button goes back to disabled (no dirty diff).
        await waitFor(() =>
            expect(screen.getByRole("button", { name: /^guardar cambios$/i })).toBeDisabled()
        );
    });

    it("also surfaces the email re-verification notice when email changes", async () => {
        server.use(
            http.get(`${API}/api/auth/me`, () => HttpResponse.json(shipperMe())),
            http.patch(`${API}/api/auth/me`, async ({ request }) => {
                const body = (await request.json()) as { email?: string };
                return HttpResponse.json(
                    shipperMe({ email: body.email, verified_at: null }),
                );
            }),
        );

        const user = userEvent.setup();
        renderProfile();

        const emailInput = await screen.findByLabelText(/^email$/i);
        await user.clear(emailInput);
        await user.type(emailInput, "ana2@example.com");

        await user.click(screen.getByRole("button", { name: /^guardar cambios$/i }));
        expect(await screen.findByText(/verificar la nueva dirección/i)).toBeInTheDocument();
    });

    it("renders inline error when the backend reports a duplicate email", async () => {
        server.use(
            http.get(`${API}/api/auth/me`, () => HttpResponse.json(shipperMe())),
            http.patch(`${API}/api/auth/me`, () =>
                HttpResponse.json(
                    {
                        error: {
                            code: "unprocessable",
                            details: { email: ["has already been taken"] },
                        },
                    },
                    { status: 422 },
                )),
        );

        const user = userEvent.setup();
        renderProfile();

        const emailInput = await screen.findByLabelText(/^email$/i);
        await user.clear(emailInput);
        await user.type(emailInput, "taken@example.com");

        await user.click(screen.getByRole("button", { name: /^guardar cambios$/i }));
        expect(await screen.findByText(/ya está en uso/i)).toBeInTheDocument();
    });

    it("Cancelar navigates back to the previous page without saving", async () => {
        server.use(http.get(`${API}/api/auth/me`, () => HttpResponse.json(shipperMe())));

        const user = userEvent.setup();
        renderProfile();

        // Type a change so we can prove Cancel doesn't persist it.
        const nameInput = await screen.findByLabelText(/nombre completo/i);
        await user.clear(nameInput);
        await user.type(nameInput, "Otro Nombre");

        await user.click(screen.getByRole("button", { name: /^cancelar$/i }));

        // History rewinds to the previous entry — the profile form is gone.
        await waitFor(() => expect(screen.getByText("previous page")).toBeInTheDocument());
        expect(screen.queryByLabelText(/nombre completo/i)).toBeNull();
    });

    it("Cancelar is enabled even when the form has no unsaved changes", async () => {
        server.use(http.get(`${API}/api/auth/me`, () => HttpResponse.json(shipperMe())));

        renderProfile();

        const cancelBtn = await screen.findByRole("button", { name: /^cancelar$/i });
        expect(cancelBtn).toBeEnabled();
    });

    it("shows the carrier-vehicle link block only for carriers", async () => {
        server.use(http.get(`${API}/api/auth/me`, () => HttpResponse.json(carrierMe())));

        renderProfile();

        const vehicleSection = await screen.findByRole("region", {
            name: /datos del camión/i,
        });
        const link = within(vehicleSection).getByRole("link", {
            name: /mis vehículos/i,
        });
        expect(link).toHaveAttribute("href", "/carrier/vehicles");
    });

    it("does NOT show the carrier-vehicle link block for shippers", async () => {
        server.use(http.get(`${API}/api/auth/me`, () => HttpResponse.json(shipperMe())));

        renderProfile();

        // Wait for hydration so we know the page rendered fully.
        await screen.findByLabelText(/nombre completo/i);
        expect(
            screen.queryByRole("region", { name: /datos del camión/i }),
        ).not.toBeInTheDocument();
    });
});
