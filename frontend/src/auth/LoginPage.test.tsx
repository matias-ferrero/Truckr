import { describe, expect, it } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { AuthProvider } from "./AuthContext";
import { LoginPage } from "./LoginPage";

const renderLogin = () =>
    render(
        <MemoryRouter initialEntries={["/login"]}>
            <AuthProvider>
                <Routes>
                    <Route path="/login" element={<LoginPage />} />
                    <Route path="/" element={<div>landing</div>} />
                </Routes>
            </AuthProvider>
        </MemoryRouter>,
    );

describe("LoginPage", () => {
    it("renders email + password fields with Spanish labels", async () => {
        renderLogin();
        expect(await screen.findByRole("heading", { name: /iniciar sesión/i })).toBeInTheDocument();
        expect(screen.getByLabelText(/email/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/contraseña/i)).toBeInTheDocument();
    });

    it("blocks submission when fields are blank", async () => {
        const user = userEvent.setup();
        renderLogin();
        await user.click(screen.getByRole("button", { name: /^iniciar sesión$/i }));

        expect(await screen.findByText(/Necesitamos tu email/i)).toBeInTheDocument();
        expect(screen.getByText(/Ingresá tu contraseña/i)).toBeInTheDocument();
    });

    it("shows the server error on bad credentials", async () => {
        const user = userEvent.setup();
        renderLogin();

        await user.type(screen.getByLabelText(/email/i), "ana@example.com");
        await user.type(screen.getByLabelText(/contraseña/i), "WrongOne1");

        await user.click(screen.getByRole("button", { name: /^iniciar sesión$/i }));

        expect(await screen.findByRole("alert")).toHaveTextContent(/email o contraseña inválidos/i);
    });

    it("navigates home on successful login", async () => {
        const user = userEvent.setup();
        renderLogin();

        await user.type(screen.getByLabelText(/email/i), "ana@example.com");
        await user.type(screen.getByLabelText(/contraseña/i), "Password1");

        await user.click(screen.getByRole("button", { name: /^iniciar sesión$/i }));

        await waitFor(() => expect(screen.getByText(/landing/i)).toBeInTheDocument());
    });
});
