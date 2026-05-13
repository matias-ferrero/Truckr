import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { ApiError } from "../api";
import { useCurrentUser } from "./useCurrentUser";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Alert } from "../components/ui/alert";
import { FormField } from "../components/ui/form-field";

type LoginForm = { email: string; password: string };
type FieldErrors = Partial<Record<keyof LoginForm, string>>;

function validate(form: LoginForm): FieldErrors {
    const errs: FieldErrors = {};
    if (!form.email.trim()) errs.email = "Necesitamos tu email.";
    else if (!/.+@.+\..+/.test(form.email)) errs.email = "Ese email no parece válido.";
    if (!form.password) errs.password = "Ingresá tu contraseña.";
    return errs;
}

export function LoginPage() {
    const { login } = useCurrentUser();
    const navigate = useNavigate();
    const [form, setForm] = useState<LoginForm>({ email: "", password: "" });
    const [errors, setErrors] = useState<FieldErrors>({});
    const [serverError, setServerError] = useState<string | null>(null);
    const [submitting, setSubmitting] = useState(false);

    const onSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        const next = validate(form);
        setErrors(next);
        if (Object.keys(next).length > 0) return;

        setSubmitting(true);
        setServerError(null);
        try {
            await login(form);
            navigate("/");
        } catch (err) {
            if (err instanceof ApiError && err.status === 429) {
                setServerError("Demasiados intentos. Esperá unos minutos antes de volver a intentar.");
            } else if (err instanceof ApiError) {
                setServerError(err.message || "Email o contraseña inválidos.");
            } else {
                setServerError("Hubo un problema de conexión. Revisá tu internet y probá de nuevo.");
            }
        } finally {
            setSubmitting(false);
        }
    };

    return (
        <main
            id="main"
            className="flex-1 flex items-start justify-center px-5 py-12"
        >
            <section
                aria-labelledby="login-title"
                className="w-full max-w-[440px] bg-paper border border-stroke rounded-md p-8 shadow-[0_4px_18px_color-mix(in_oklab,var(--color-ink)_8%,transparent)]"
            >
                <h1
                    id="login-title"
                    className="font-display text-3xl font-bold tracking-tight mb-2"
                >
                    Iniciar sesión
                </h1>
                <p className="text-sm text-ink-soft mb-6 max-w-[65ch] leading-relaxed">
                    Bienvenido de vuelta. Entrá con tu email y contraseña.
                </p>

                {serverError ? (
                    <Alert tone="error" aria-live="polite" className="mb-4">
                        {serverError}
                    </Alert>
                ) : null}

                <form className="flex flex-col gap-4" onSubmit={onSubmit} noValidate>
                    <FormField id="email" label="Email" error={errors.email}>
                        <Input
                            id="email"
                            type="email"
                            value={form.email}
                            autoComplete="email"
                            onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
                        />
                    </FormField>

                    <FormField id="password" label="Contraseña" error={errors.password}>
                        <Input
                            id="password"
                            type="password"
                            value={form.password}
                            autoComplete="current-password"
                            onChange={(e) => setForm((f) => ({ ...f, password: e.target.value }))}
                        />
                    </FormField>

                    <Button
                        type="submit"
                        disabled={submitting}
                        aria-busy={submitting ? "true" : "false"}
                    >
                        {submitting ? "Entrando…" : "Iniciar sesión"}
                    </Button>
                </form>

                <p className="mt-6 text-sm text-ink-soft text-center">
                    ¿No tenés cuenta?{" "}
                    <Link to="/signup" className="text-ink font-semibold underline underline-offset-2">
                        Crear cuenta
                    </Link>
                </p>
            </section>
        </main>
    );
}
