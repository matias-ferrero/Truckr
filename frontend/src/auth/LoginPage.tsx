import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { ApiError } from "../api";
import { useCurrentUser } from "./useCurrentUser";

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
        <main className="authMain" id="main">
            <section className="authCard" aria-labelledby="login-title">
                <h1 className="authTitle" id="login-title">Iniciar sesión</h1>
                <p className="authLead">Bienvenido de vuelta. Entrá con tu email y contraseña.</p>

                {serverError ? (
                    <div className="authBanner" role="alert" aria-live="polite">
                        {serverError}
                    </div>
                ) : null}

                <form className="authForm" onSubmit={onSubmit} noValidate>
                    <div className="authField">
                        <label className="authLabel" htmlFor="email">Email</label>
                        <input
                            id="email"
                            type="email"
                            className="authInput"
                            value={form.email}
                            autoComplete="email"
                            aria-invalid={errors.email ? "true" : "false"}
                            aria-describedby={errors.email ? "email-error" : undefined}
                            onChange={(e) => setForm((f) => ({ ...f, email: e.target.value }))}
                        />
                        {errors.email ? <div className="authError" id="email-error">{errors.email}</div> : null}
                    </div>

                    <div className="authField">
                        <label className="authLabel" htmlFor="password">Contraseña</label>
                        <input
                            id="password"
                            type="password"
                            className="authInput"
                            value={form.password}
                            autoComplete="current-password"
                            aria-invalid={errors.password ? "true" : "false"}
                            aria-describedby={errors.password ? "password-error" : undefined}
                            onChange={(e) => setForm((f) => ({ ...f, password: e.target.value }))}
                        />
                        {errors.password ? <div className="authError" id="password-error">{errors.password}</div> : null}
                    </div>

                    <button
                        className="authButton"
                        type="submit"
                        disabled={submitting}
                        aria-busy={submitting ? "true" : "false"}
                    >
                        {submitting ? "Entrando…" : "Iniciar sesión"}
                    </button>
                </form>

                <p className="authFootnote">
                    ¿No tenés cuenta? <Link to="/signup">Crear cuenta</Link>
                </p>
            </section>
        </main>
    );
}
