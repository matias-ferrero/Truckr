import { useState } from "react";
import { Link, useNavigate, useSearchParams } from "react-router-dom";
import { ApiError } from "../api";
import { useCurrentUser } from "./useCurrentUser";
import { Button } from "../components/ui/button";
import { Input } from "../components/ui/input";
import { Alert } from "../components/ui/alert";
import { FormField } from "../components/ui/form-field";
import { RadioGroup, RadioOption } from "../components/ui/radio-group";

type RegisterRole = "carrier" | "shipper";

function roleFromQuery(value: string | null): RegisterRole | "" {
    return value === "carrier" || value === "shipper" ? value : "";
}

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
    const [searchParams] = useSearchParams();
    const [form, setForm] = useState<RegisterForm>({
        email: "",
        password: "",
        passwordConfirm: "",
        name: "",
        role: roleFromQuery(searchParams.get("role")),
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
        <main
            id="main"
            className="flex-1 flex items-center justify-center px-5 py-6"
        >
            <section
                aria-labelledby="register-title"
                className="w-full max-w-[440px] bg-paper border border-stroke rounded-md p-6 sm:p-7 shadow-[0_4px_18px_color-mix(in_oklab,var(--color-ink)_8%,transparent)]"
            >
                <h1
                    id="register-title"
                    className="font-display text-3xl font-bold tracking-tight mb-2"
                >
                    Crear cuenta
                </h1>
                <p className="text-sm text-ink-soft mb-5 max-w-[65ch] leading-relaxed">
                    Sumate a Truckr® como expedidor o transportista.
                </p>

                {serverError ? (
                    <Alert tone="error" aria-live="polite" className="mb-4">
                        {serverError}
                    </Alert>
                ) : null}

                <form className="flex flex-col gap-3.5" onSubmit={onSubmit} noValidate>
                    <FormField
                        id="name"
                        label="Nombre completo"
                        error={errors.name}
                        help="Como querés que te identifiquemos."
                    >
                        <Input
                            id="name"
                            value={form.name}
                            autoComplete="name"
                            onChange={(e) => update("name", e.target.value)}
                        />
                    </FormField>

                    <FormField id="email" label="Email" error={errors.email}>
                        <Input
                            id="email"
                            type="email"
                            value={form.email}
                            autoComplete="email"
                            onChange={(e) => update("email", e.target.value)}
                        />
                    </FormField>

                    <FormField
                        id="password"
                        label="Contraseña"
                        error={errors.password}
                        help="Mínimo 8 caracteres, con mayúscula, minúscula y un número."
                    >
                        <Input
                            id="password"
                            type="password"
                            value={form.password}
                            autoComplete="new-password"
                            onChange={(e) => update("password", e.target.value)}
                        />
                    </FormField>

                    <FormField
                        id="passwordConfirm"
                        label="Confirmar contraseña"
                        error={errors.passwordConfirm}
                    >
                        <Input
                            id="passwordConfirm"
                            type="password"
                            value={form.passwordConfirm}
                            autoComplete="new-password"
                            onChange={(e) => update("passwordConfirm", e.target.value)}
                        />
                    </FormField>

                    <FormField
                        id="role"
                        label="Tipo de cuenta"
                        error={errors.role}
                        asFieldset
                    >
                        <RadioGroup>
                            <RadioOption
                                id="role-shipper"
                                name="role"
                                value="shipper"
                                checked={form.role === "shipper"}
                                onChange={() => update("role", "shipper")}
                                label="Expedidor"
                            />
                            <RadioOption
                                id="role-carrier"
                                name="role"
                                value="carrier"
                                checked={form.role === "carrier"}
                                onChange={() => update("role", "carrier")}
                                label="Transportista"
                            />
                        </RadioGroup>
                    </FormField>

                    <Button
                        type="submit"
                        disabled={submitting}
                        aria-busy={submitting ? "true" : "false"}
                    >
                        {submitting ? "Creando cuenta…" : "Crear cuenta"}
                    </Button>
                </form>

                <p className="mt-5 text-sm text-ink-soft text-center">
                    ¿Ya tenés cuenta?{" "}
                    <Link to="/login" className="text-ink font-semibold underline underline-offset-2">
                        Iniciar sesión
                    </Link>
                </p>
            </section>
        </main>
    );
}
