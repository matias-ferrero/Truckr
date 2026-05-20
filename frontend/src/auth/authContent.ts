/* Prototype-stage i18n bundle for auth pages. Mirrors the carve-out in
   landingContent.ts: copy lives in a typed object until a real i18n
   library lands. UI components must read strings from here, never inline. */

export const authContent = {
    forbidden: {
        title: "No tenés acceso a esta página",
        lead:
            "Esta sección es solo para cuentas de tipo Expedidor. Si creés que es un error, revisá con qué cuenta iniciaste sesión.",
        backHome: "Volver al panel",
    },
    register: {
        errors: {
            nameRequired: "Decinos cómo te llamás.",
            emailRequired: "Necesitamos un email para crear tu cuenta.",
            emailInvalid: "Ese email no parece válido.",
            passwordRequired: "Elegí una contraseña para proteger tu cuenta.",
            passwordMissing: (parts: string) => `Tu contraseña necesita ${parts}.`,
            passwordRules: {
                minLength: "al menos 8 caracteres",
                upper: "una mayúscula",
                lower: "una minúscula",
                digit: "un número",
            },
            passwordMismatch: "Las contraseñas no coinciden.",
            roleRequired: "Elegí qué tipo de cuenta querés crear.",
        },
        serverErrors: {
            generic: "No pudimos crear tu cuenta. Revisá los datos y probá de nuevo.",
            network: "Hubo un problema de conexión. Revisá tu internet y probá de nuevo.",
        },
    },
} as const;

export type PasswordRuleKey = keyof typeof authContent.register.errors.passwordRules;
