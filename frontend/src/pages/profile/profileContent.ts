/* Prototype-stage i18n bundle for the profile page. Mirrors the
   carve-out in landingContent.ts / carrierContent.ts: content lives in a
   typed object until a real i18n library lands. UI components must read
   strings from here, never inline. */

export const profileContent = {
    title: "Mi perfil",
    lead:
        "Actualizá tus datos personales. Los cambios se aplican en tu " +
        "perfil cuando presionás «Guardar cambios».",
    sections: {
        personal: {
            title: "Datos personales",
            description:
                "Estos datos son visibles para otros usuarios cuando " +
                "interactúan con vos en la plataforma.",
        },
        vehicle: {
            title: "Datos del camión",
            description:
                "Los datos de tu vehículo se gestionan en la pantalla " +
                "de vehículos.",
            link: "Ir a mis vehículos",
        },
    },
    fields: {
        name: "Nombre completo",
        email: "Email",
        phone: "Teléfono",
        emailHelp:
            "Si cambiás tu email vas a tener que volver a verificarlo.",
        phoneHelp:
            "Formato internacional recomendado (ej. +5491133334444).",
    },
    errors: {
        nameRequired: "El nombre no puede estar vacío.",
        emailRequired: "Necesitamos un email.",
        emailInvalid: "Ese email no parece válido.",
        emailTaken: "Ese email ya está en uso.",
        phoneInvalid:
            "El teléfono solo puede contener números, espacios, guiones, " +
            "paréntesis y un + inicial.",
        saveGeneric: "No pudimos guardar tus datos. Probá de nuevo.",
        loading: "Cargando tu perfil…",
    },
    submit: {
        save: "Guardar cambios",
        saving: "Guardando…",
        cancel: "Cancelar",
    },
    feedback: {
        saved: "Datos actualizados correctamente.",
        emailReverify:
            "Cambiaste tu email. Vas a recibir un mail para verificar la " +
            "nueva dirección.",
    },
} as const;
