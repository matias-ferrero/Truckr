// US20 / US30 — i18n bundles for shipment review forms.
// Flat object so it can move into a real i18n library without rewrites
// (mirrors paymentContent.ts). Backend error keys live in
// config/locales/{en,es}.yml; these are the FE-side labels + composed copy.
export const reviewsContent = {
    // US20 / REQ-BE-00042 — Shipper → Carrier (reviews.rating.label, etc.)
    shipperReview: {
        title: "Dejar reseña",
        lead: "Contanos cómo fue tu experiencia con el transportista de este envío.",
        ratingLabel: "Puntuación",
        ratingHint: "Seleccioná de 1 a 5 estrellas.",
        starLabel: (n: number) => `${n} ${n === 1 ? "estrella" : "estrellas"}`,
        bodyLabel: "Comentario (opcional)",
        bodyPlaceholder: "Compartí los detalles de tu experiencia…",
        bodyCounter: (used: number, max: number) => `${used} / ${max}`,
        submit: "Enviar reseña",
        submitLoading: "Enviando…",
        errors: {
            ratingRequired: "Elegí una puntuación de 1 a 5 estrellas.",
            bodyTooLong: "El comentario no puede superar los 1000 caracteres.",
            alreadyReviewed: "Ya dejaste una reseña para este envío.",
            forbidden: "No tenés permiso para reseñar este envío.",
            generic: "No pudimos guardar la reseña. Intentá de nuevo.",
        },
        success: {
            heading: "¡Gracias por tu reseña!",
            yourRating: "Tu puntuación",
        },
    },
    carrierReview: {
        title: "Reseñar al expedidor",
        lead: "Contanos cómo fue trabajar con este expedidor. Tu reseña ayuda a otros transportistas.",
        ratingLabel: "Puntuación",
        ratingHint: "Seleccioná de 1 a 5 estrellas.",
        starLabel: (n: number) => `${n} ${n === 1 ? "estrella" : "estrellas"}`,
        bodyLabel: "Comentario (opcional)",
        bodyPlaceholder: "Compartí los detalles de tu experiencia…",
        bodyCounter: (used: number, max: number) => `${used} / ${max}`,
        submit: "Enviar reseña",
        submitLoading: "Enviando…",
        errors: {
            ratingRequired: "Elegí una puntuación de 1 a 5 estrellas.",
            bodyTooLong: "El comentario no puede superar los 1000 caracteres.",
            alreadyReviewed: "Ya dejaste una reseña para este envío.",
            notDelivered: "Sólo se puede reseñar un envío entregado.",
            forbidden: "No tenés permiso para reseñar este envío.",
            generic: "No pudimos guardar la reseña. Intentá de nuevo.",
        },
        success: {
            heading: "¡Gracias por tu reseña!",
            yourRating: "Tu puntuación",
        },
    },
} as const;

export const REVIEW_BODY_MAX = 1_000;
export const REVIEW_MIN_RATING = 1;
export const REVIEW_MAX_RATING = 5;
