import { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { ApiError } from "../api";
import { useCurrentUser } from "./useCurrentUser";

type RegisterRole = "carrier" | "shipper" | "both";

type RegisterForm = {
    email: string;
    password: string;
    passwordConfirm: string;
    name: string;
    role: RegisterRole | "";
};

type FieldErrors = Partial<Record<keyof RegisterForm, string>>;

const PASSWORD_RULES = [
    { test: (v: string) => v.length >= 8, msg: "al menos 8 caracteres" },
    { test: (v: string) => /[A-Z]/.test(v), msg: "una mayúscula" },
    { test: (v: string) => /[a-z]/.test(v), msg: "una minúscula" },
    { test: (v: string) => /\d/.test(v), msg: "un dígito" },
];

function validate(form: RegisterForm): FieldErrors {
    const errs: FieldErrors = {};
    if (!form.name.trim()) errs.name = "Decinos cómo te llamás.";
    if (!form.email.trim()) errs.email = "Necesitamos un email para crear tu cuenta.";
    else if (!/.+@.+\..+/.test(form.email)) errs.email = "Ese email no parece válido.";
    if (!form.password) errs.password = "Elegí una contraseña segura.";
    else {
        const failed = PASSWORD_RULES.filter((r) => !r.test(form.password));
        if (failed.length) errs.password = `Debe contener ${failed.map((f) => f.msg).join(", ")}.`;
    }
    if (form.password !== form.passwordConfirm) errs.passwordConfirm = "Las contraseñas no coinciden.";
    if (!form.role) errs.role = "Elegí qué tipo de cuenta querés crear.";
    return errs;
}

export function RegisterPage() {
    const { register } = useCurrentUser();
    const navigate = useNavigate();
    const [form, setForm] = useState<RegisterForm>({
        email: "",
        password: "",
        passwordConfirm: "",
        name: "",
        role: "",
    });
    const [errors, setErrors] = useState<FieldErrors>({});
    const [serverError, setServerError] = useState<string | null>(null);
    const [submitting, setSubmitting] = useState(false);

    const update = <K extends keyof RegisterForm>(key: K, value: RegisterForm[K]) => {
        setForm((f) => ({ ...f, [key]: value }));
    };

    const onSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        const next = validate(form);
        setErrors(next);
        if (Object.keys(next).length > 0) return;

        setSubmitting(true);
        setServerError(null);
        try {
            await register({
                email: form.email,
                password: form.password,
                name: form.name,
                role: form.role as RegisterRole,
            });
            navigate("/");
        } catch (err) {
            if (err instanceof ApiError) {
                setServerError(err.message || "No pudimos crear tu cuenta. Probá de nuevo.");
            } else {
                setServerError("No pudimos crear tu cuenta. Probá de nuevo.");
            }
        } finally {
            setSubmitting(false);
        }
    };

    return (
        <main className="authMain" id="main">
            <section className="authCard" aria-labelledby="register-title">
                <h1 className="authTitle" id="register-title">Crear cuenta</h1>
                <p className="authLead">
                    Sumate a Truckr® como expedidor, transportista o ambos. Podés cambiarlo después.
                </p>

                {serverError ? (
                    <div className="authBanner" role="alert" aria-live="polite">
                        {serverError}
                    </div>
                ) : null}

                <form className="authForm" onSubmit={onSubmit} noValidate>
                    <div className="authField">
                        <label className="authLabel" htmlFor="name">Nombre completo</label>
                        <input
                            id="name"
                            className="authInput"
                            value={form.name}
                            autoComplete="name"
                            aria-invalid={errors.name ? "true" : "false"}
                            aria-describedby={errors.name ? "name-error" : "name-help"}
                            onChange={(e) => update("name", e.target.value)}
                        />
                        {errors.name ? (
                            <div className="authError" id="name-error">{errors.name}</div>
                        ) : (
                            <div className="authHelp" id="name-help">Como querés que te identifiquemos.</div>
                        )}
                    </div>

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
                            onChange={(e) => update("email", e.target.value)}
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
                            autoComplete="new-password"
                            aria-invalid={errors.password ? "true" : "false"}
                            aria-describedby={errors.password ? "password-error" : "password-help"}
                            onChange={(e) => update("password", e.target.value)}
                        />
                        {errors.password ? (
                            <div className="authError" id="password-error">{errors.password}</div>
                        ) : (
                            <div className="authHelp" id="password-help">
                                Mínimo 8 caracteres, con mayúscula, minúscula y un número.
                            </div>
                        )}
                    </div>

                    <div className="authField">
                        <label className="authLabel" htmlFor="passwordConfirm">Confirmar contraseña</label>
                        <input
                            id="passwordConfirm"
                            type="password"
                            className="authInput"
                            value={form.passwordConfirm}
                            autoComplete="new-password"
                            aria-invalid={errors.passwordConfirm ? "true" : "false"}
                            aria-describedby={errors.passwordConfirm ? "passwordConfirm-error" : undefined}
                            onChange={(e) => update("passwordConfirm", e.target.value)}
                        />
                        {errors.passwordConfirm ? (
                            <div className="authError" id="passwordConfirm-error">{errors.passwordConfirm}</div>
                        ) : null}
                    </div>

                    <fieldset className="authField" aria-describedby={errors.role ? "role-error" : undefined}>
                        <legend className="authLabel">Tipo de cuenta</legend>
                        <div className="authRoles" role="radiogroup">
                            <label className="authRoleOption">
                                <input
                                    type="radio"
                                    name="role"
                                    id="role-shipper"
                                    value="shipper"
                                    checked={form.role === "shipper"}
                                    onChange={() => update("role", "shipper")}
                                />
                                Expedidor
                            </label>
                            <label className="authRoleOption">
                                <input
                                    type="radio"
                                    name="role"
                                    id="role-carrier"
                                    value="carrier"
                                    checked={form.role === "carrier"}
                                    onChange={() => update("role", "carrier")}
                                />
                                Transportista
                            </label>
                            <label className="authRoleOption">
                                <input
                                    type="radio"
                                    name="role"
                                    id="role-both"
                                    value="both"
                                    checked={form.role === "both"}
                                    onChange={() => update("role", "both")}
                                />
                                Ambos
                            </label>
                        </div>
                        {errors.role ? <div className="authError" id="role-error">{errors.role}</div> : null}
                    </fieldset>

                    <button
                        className="authButton"
                        type="submit"
                        disabled={submitting}
                        aria-busy={submitting ? "true" : "false"}
                    >
                        {submitting ? "Creando cuenta…" : "Crear cuenta"}
                    </button>
                </form>

                <p className="authFootnote">
                    ¿Ya tenés cuenta? <Link to="/login">Iniciar sesión</Link>
                </p>
            </section>
        </main>
    );
}
