import React, { useMemo, useState } from "react";
import { landingContent } from "./landingContent";

type QuoteDraft = {
    origen: string;
    destino: string;
    carga: string;
    pesoKg: string;
    contacto: string;
};

function iconFor(name: string): string {
    switch (name) {
        case "truck":
            return "🚚";
        case "package":
            return "📦";
        case "shield":
            return "🛡️";
        default:
            return "✳";
    }
}

export default function LandingPage() {
    const [quote, setQuote] = useState<QuoteDraft>({
        origen: "",
        destino: "",
        carga: "",
        pesoKg: "",
        contacto: "",
    });
    const [quoteSubmitted, setQuoteSubmitted] = useState(false);
    const [quoteErrors, setQuoteErrors] = useState<Partial<Record<keyof QuoteDraft, string>>>({});

    const themeVars = useMemo(() => {
        const colors = landingContent.color_palette;
        return {
            ["--brand-primary" as string]: colors.primary,
            ["--brand-secondary" as string]: colors.secondary,
            ["--brand-tertiary" as string]: colors.tertiary,
            ["--brand-error" as string]: colors.error,
            ["--brand-neutral" as string]: colors.neutral,
        } satisfies React.CSSProperties;
    }, []);

    const validateQuote = (draft: QuoteDraft) => {
        const next: Partial<Record<keyof QuoteDraft, string>> = {};
        if (!draft.origen.trim()) next.origen = "Decinos desde dónde sale el envío.";
        if (!draft.destino.trim()) next.destino = "Decinos a dónde llega el envío.";
        if (!draft.carga.trim()) next.carga = "¿Qué se transporta? (Ej: cajas, pallet, muebles)";
        if (!draft.contacto.trim()) next.contacto = "Dejanos un email o WhatsApp para responderte.";
        return next;
    };

    const onSubmitQuote: React.FormEventHandler<HTMLFormElement> = (e) => {
        e.preventDefault();
        const nextErrors = validateQuote(quote);
        setQuoteErrors(nextErrors);
        if (Object.keys(nextErrors).length > 0) return;
        setQuoteSubmitted(true);
        const el = document.getElementById("cotizacion");
        el?.scrollIntoView({ behavior: "smooth", block: "start" });
    };

    return (
        <div className="page" style={themeVars}>
            <a className="skipLink" href="#main">
                Saltar al contenido
            </a>

            <header className="topbar">
                <div className="container">
                    <div className="topbarInner">
                        <a className="brand" href="#inicio" aria-label="Truckr — Inicio">
                            <span className="brandMark">Truckr®</span>
                            <span className="brandTag">Transporte en Argentina</span>
                        </a>
                        <nav className="nav" aria-label="Secciones">
                            <a href="#cotizacion">Pedir cotización</a>
                            <a href="#para-quien">Para quién</a>
                            <a href="#confianza">Confianza</a>
                        </nav>
                    </div>
                </div>
            </header>

            <main id="main">
                <section id="inicio" className="hero">
                    <div className="container">
                        <div className="heroGrid">
                            <div>
                                <h1 className="headline">{landingContent.hero.title}</h1>
                                <p className="subhead">
                                    {landingContent.hero.subtitle}. {landingContent.hero.description}
                                </p>

                                <div className="ctaRow">
                                    <a className="button buttonPrimary" href="#cotizacion">
                                        Pedir cotización
                                    </a>
                                    <a className="button buttonGhost" href="#para-quien">
                                        Ver cómo funciona
                                    </a>
                                </div>

                                <div className="proofRow" aria-label="Señales de confianza">
                                    <div className="proofChip">
                                        <span aria-hidden="true">🧾</span>
                                        <div>
                                            <strong>Precio claro</strong>
                                            <span>Sin sorpresas en el camino</span>
                                        </div>
                                    </div>
                                    <div className="proofChip">
                                        <span aria-hidden="true">🧑‍💬</span>
                                        <div>
                                            <strong>Soporte humano</strong>
                                            <span>Te acompañamos en el proceso</span>
                                        </div>
                                    </div>
                                    <div className="proofChip">
                                        <span aria-hidden="true">🛡️</span>
                                        <div>
                                            <strong>Más seguridad</strong>
                                            <span>Información y trazabilidad</span>
                                        </div>
                                    </div>
                                    <div className="proofChip">
                                        <span aria-hidden="true">🗺️</span>
                                        <div>
                                            <strong>Alcance federal</strong>
                                            <span>Envíos a todo el país</span>
                                        </div>
                                    </div>
                                </div>
                            </div>

                            <aside className="panel" id="cotizacion" aria-label="Formulario de cotización">
                                <h2 className="panelTitle">Pedí una cotización</h2>
                                <p className="panelHint">
                                    Te respondemos con opciones. Esto es una demo: el envío no se manda a ningún lado todavía.
                                </p>

                                {quoteSubmitted ? (
                                    <div aria-live="polite">
                                        <p style={{ margin: "16px 0 0 0" }}>
                                            <strong>Recibido.</strong> En breve te contactamos en <strong>{quote.contacto}</strong>.
                                        </p>
                                        <p style={{ margin: "8px 0 0 0" }}>
                                            Ruta: {quote.origen} → {quote.destino}. Carga: {quote.carga}
                                            {quote.pesoKg ? ` (${quote.pesoKg} kg)` : ""}.
                                        </p>
                                        <div className="ctaRow" style={{ marginTop: "16px" }}>
                                            <button
                                                type="button"
                                                className="button buttonGhost"
                                                onClick={() => {
                                                    setQuoteSubmitted(false);
                                                    setQuoteErrors({});
                                                }}
                                            >
                                                Pedir otra
                                            </button>
                                            <a className="button buttonPrimary" href="#confianza">
                                                Ver por qué confiar
                                            </a>
                                        </div>
                                    </div>
                                ) : (
                                    <form className="form" onSubmit={onSubmitQuote}>
                                        <div className="field">
                                            <div className="labelRow">
                                                <label htmlFor="origen">Origen</label>
                                                <em>Ej: CABA</em>
                                            </div>
                                            <input
                                                id="origen"
                                                className="input"
                                                value={quote.origen}
                                                placeholder="¿Desde dónde sale?"
                                                aria-invalid={quoteErrors.origen ? "true" : "false"}
                                                aria-describedby={quoteErrors.origen ? "origen-error" : undefined}
                                                onChange={(e) => setQuote((q) => ({ ...q, origen: e.target.value }))}
                                            />
                                            {quoteErrors.origen ? (
                                                <div id="origen-error" className="error">
                                                    {quoteErrors.origen}
                                                </div>
                                            ) : (
                                                <div className="help">Puede ser ciudad, provincia o barrio.</div>
                                            )}
                                        </div>

                                        <div className="field">
                                            <div className="labelRow">
                                                <label htmlFor="destino">Destino</label>
                                                <em>Ej: Rosario</em>
                                            </div>
                                            <input
                                                id="destino"
                                                className="input"
                                                value={quote.destino}
                                                placeholder="¿A dónde llega?"
                                                aria-invalid={quoteErrors.destino ? "true" : "false"}
                                                aria-describedby={quoteErrors.destino ? "destino-error" : undefined}
                                                onChange={(e) => setQuote((q) => ({ ...q, destino: e.target.value }))}
                                            />
                                            {quoteErrors.destino ? (
                                                <div id="destino-error" className="error">
                                                    {quoteErrors.destino}
                                                </div>
                                            ) : (
                                                <div className="help">Si no sabés exacto, aproximado alcanza.</div>
                                            )}
                                        </div>

                                        <div className="field">
                                            <div className="labelRow">
                                                <label htmlFor="carga">Carga</label>
                                                <em>Qué se transporta</em>
                                            </div>
                                            <input
                                                id="carga"
                                                className="input"
                                                value={quote.carga}
                                                placeholder="Ej: 10 cajas, 1 pallet, heladera"
                                                aria-invalid={quoteErrors.carga ? "true" : "false"}
                                                aria-describedby={quoteErrors.carga ? "carga-error" : undefined}
                                                onChange={(e) => setQuote((q) => ({ ...q, carga: e.target.value }))}
                                            />
                                            {quoteErrors.carga ? (
                                                <div id="carga-error" className="error">
                                                    {quoteErrors.carga}
                                                </div>
                                            ) : (
                                                <div className="help">Cuanto más claro, mejor la cotización.</div>
                                            )}
                                        </div>

                                        <div className="field">
                                            <div className="labelRow">
                                                <label htmlFor="peso">Peso (kg) (opcional)</label>
                                                <em>aprox.</em>
                                            </div>
                                            <input
                                                id="peso"
                                                className="input"
                                                inputMode="numeric"
                                                value={quote.pesoKg}
                                                placeholder="Ej: 120"
                                                onChange={(e) => setQuote((q) => ({ ...q, pesoKg: e.target.value }))}
                                            />
                                        </div>

                                        <div className="field">
                                            <div className="labelRow">
                                                <label htmlFor="contacto">Contacto</label>
                                                <em>Email o WhatsApp</em>
                                            </div>
                                            <input
                                                id="contacto"
                                                className="input"
                                                value={quote.contacto}
                                                placeholder="Ej: nombre@empresa.com o +54 9 11 …"
                                                aria-invalid={quoteErrors.contacto ? "true" : "false"}
                                                aria-describedby={quoteErrors.contacto ? "contacto-error" : undefined}
                                                onChange={(e) => setQuote((q) => ({ ...q, contacto: e.target.value }))}
                                            />
                                            {quoteErrors.contacto ? (
                                                <div id="contacto-error" className="error">
                                                    {quoteErrors.contacto}
                                                </div>
                                            ) : (
                                                <div className="help">Solo lo usamos para responderte.</div>
                                            )}
                                        </div>

                                        <button className="button buttonPrimary" type="submit">
                                            Enviar solicitud
                                        </button>
                                    </form>
                                )}
                            </aside>
                        </div>
                    </div>
                </section>

                <section id="para-quien" className="section">
                    <div className="container">
                        <h2 className="sectionTitle">Una plataforma, dos lados</h2>
                        <p className="sectionLead">
                            Expedidores y transportistas comparten el mismo objetivo: que el envío llegue bien, en tiempo y con
                            condiciones claras.
                        </p>

                        <div className="split">
                            <article className="splitCard">
                                <h3>Para expedidores</h3>
                                <p>
                                    Pedís cotización en minutos, comparás opciones y coordinás sin vueltas. Te ayudamos a
                                    anticipar tiempos y requisitos.
                                </p>
                            </article>
                            <article className="splitCard">
                                <h3>Para transportistas</h3>
                                <p>
                                    Recibís pedidos reales y coordinás con información completa. Menos fricción, más viajes
                                    cerrados con claridad.
                                </p>
                            </article>
                        </div>
                    </div>
                </section>

                <section id="confianza" className="section">
                    <div className="container">
                        <h2 className="sectionTitle">Confiable, claro, humano</h2>
                        <p className="sectionLead">
                            Elegimos señales simples que reducen dudas: pasos explícitos, comunicación directa y números que
                            se leen sin “marketing”.
                        </p>

                        <div className="featureGrid" aria-label="Características">
                            {landingContent.features.map((feature) => (
                                <article key={feature.id} className="featureItem">
                                    <div className="featureTop">
                                        <div className="iconDot" aria-hidden="true">
                                            {iconFor(feature.icon)}
                                        </div>
                                        <h3>{feature.title}</h3>
                                    </div>
                                    <p>{feature.description}</p>
                                </article>
                            ))}
                        </div>

                        <div className="statsRow" aria-label="Estadísticas">
                            {landingContent.stats.map((stat, idx) => (
                                <div key={`${stat.label}-${idx}`} className="stat">
                                    <p className="statValue">{stat.value}</p>
                                    <p className="statLabel">{stat.label}</p>
                                </div>
                            ))}
                        </div>
                    </div>
                </section>

                <footer className="footer">
                    <div className="container">
                        <div className="footerInner">
                            <div>
                                <strong>Truckr®</strong> — Conectando transportistas con expedidores en Argentina.
                            </div>
                            <div className="legal">© 2026 Truckr®. Todos los derechos reservados.</div>
                        </div>
                    </div>
                </footer>
            </main>
        </div>
    );
}
