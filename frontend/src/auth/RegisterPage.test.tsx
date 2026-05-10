import { describe, expect, it } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { MemoryRouter, Route, Routes } from "react-router-dom";
import { AuthProvider } from "./AuthContext";
import { RegisterPage } from "./RegisterPage";

const renderRegister = () =>
    render(
        <MemoryRouter initialEntries={["/signup"]}>
            <AuthProvider>
                <Routes>
                    <Route path="/signup" element={<RegisterPage />} />
                    <Route path="/" element={<div>landing</div>} />
                </Routes>
            </AuthProvider>
        </MemoryRouter>,
    );

describe("RegisterPage", () => {
    it("renders all required fields with Spanish labels", async () => {
        renderRegister();
        expect(await screen.findByRole("heading", { name: /crear cuenta/i })).toBeInTheDocument();
        expect(screen.getByLabelText(/nombre completo/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/^email$/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/^contraseña$/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/confirmar contraseña/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/transportista/i)).toBeInTheDocument();
        expect(screen.getByLabelText(/expedidor/i)).toBeInTheDocument();
    });

    it("blocks submit when fields are empty", async () => {
        const user = userEvent.setup();
        renderRegister();
        await user.click(screen.getByRole("button", { name: /^crear cuenta$/i }));

        expect(await screen.findByText(/Decinos cómo te llamás/i)).toBeInTheDocument();
        expect(screen.getByText(/Necesitamos un email/i)).toBeInTheDocument();
        expect(screen.getByText(/Elegí una contraseña segura/i)).toBeInTheDocument();
        expect(screen.getByText(/Elegí qué tipo de cuenta/i)).toBeInTheDocument();
    });

    it("rejects passwords that fail complexity rules", async () => {
        const user = userEvent.setup();
        renderRegister();

        await user.type(screen.getByLabelText(/nombre completo/i), "Ana");
        await user.type(screen.getByLabelText(/^email$/i), "ana@example.com");
        await user.type(screen.getByLabelText(/^contraseña$/i), "weak");
        await user.type(screen.getByLabelText(/confirmar contraseña/i), "weak");
        await user.click(screen.getByLabelText(/expedidor/i));

        await user.click(screen.getByRole("button", { name: /^crear cuenta$/i }));

        expect(await screen.findByText(/al menos 8 caracteres/i)).toBeInTheDocument();
        expect(screen.getByText(/una mayúscula/i)).toBeInTheDocument();
        expect(screen.getByText(/un dígito/i)).toBeInTheDocument();
    });

    it("complains when passwords do not match", async () => {
        const user = userEvent.setup();
        renderRegister();

        await user.type(screen.getByLabelText(/nombre completo/i), "Ana");
        await user.type(screen.getByLabelText(/^email$/i), "ana@example.com");
        await user.type(screen.getByLabelText(/^contraseña$/i), "Password1");
        await user.type(screen.getByLabelText(/confirmar contraseña/i), "Password2");
        await user.click(screen.getByLabelText(/expedidor/i));

        await user.click(screen.getByRole("button", { name: /^crear cuenta$/i }));

        expect(await screen.findByText(/no coinciden/i)).toBeInTheDocument();
    });

    it("submits successfully and navigates home", async () => {
        const user = userEvent.setup();
        renderRegister();

        await user.type(screen.getByLabelText(/nombre completo/i), "Ana");
        await user.type(screen.getByLabelText(/^email$/i), "ana@example.com");
        await user.type(screen.getByLabelText(/^contraseña$/i), "Password1");
        await user.type(screen.getByLabelText(/confirmar contraseña/i), "Password1");
        await user.click(screen.getByLabelText(/expedidor/i));

        await user.click(screen.getByRole("button", { name: /^crear cuenta$/i }));

        await waitFor(() => expect(screen.getByText(/landing/i)).toBeInTheDocument());
    });
});
