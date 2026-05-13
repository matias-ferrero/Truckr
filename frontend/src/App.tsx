import React, { useMemo } from "react";
import { Link } from "react-router-dom";
import { landingContent } from "./landingContent";
import { SessionWidget } from "./components/SessionWidget";

function FeatureIcon({ name }: { name: string }): React.ReactElement {
    const common = {
        width: 22,
        height: 22,
        viewBox: "0 0 24 24",
        fill: "none",
        stroke: "currentColor",
        strokeWidth: 1.6,
        strokeLinecap: "round" as const,
        strokeLinejoin: "round" as const,
        "aria-hidden": true,
    };
    switch (name) {
        case "tag":
            return (
                <svg {...common}>
                    <path d="M3 12 12 3h8v8l-9 9z" />
                    <circle cx="15.5" cy="8.5" r="1.5" />
                </svg>
            );
        case "chat":
            return (
                <svg {...common}>
                    <path d="M4 5h16v11H8l-4 4z" />
                    <path d="M8 10h8M8 13h5" />
                </svg>
            );
        case "route":
            return (
                <svg {...common}>
                    <circle cx="6" cy="6" r="2.2" />
                    <circle cx="18" cy="18" r="2.2" />
                    <path d="M8 7c4 0 4 5 0 5s-4 5 0 5h8" />
                </svg>
            );
        default:
            return (
                <svg {...common}>
                    <circle cx="12" cy="12" r="5" />
                </svg>
            );
    }
}

function BulletCheck(): React.ReactElement {
    return (
        <svg
            width={16}
            height={16}
            viewBox="0 0 16 16"
            fill="none"
            stroke="currentColor"
            strokeWidth={1.8}
            strokeLinecap="round"
            strokeLinejoin="round"
            aria-hidden="true"
        >
            <path d="M3 8.5 6.5 12 13 4.5" />
        </svg>
    );
}

export default function LandingPage() {
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

    const { hero, audiences, steps, features, commitments, finalCta } = landingContent;

    return (
        <div className="page" style={themeVars}>
            <a className="skipLink" href="#main">
                Saltar al contenido
            </a>

            <header className="topbar">
                <div className="container">
                    <div className="topbarInner">
                        <a className="brand" href="#inicio" aria-label="Truckr, ir al inicio">
                            <span className="brandMark">{hero.brand}</span>
                            <span className="brandTag">Transporte en Argentina</span>
                        </a>
                        <nav className="nav" aria-label="Secciones">
                            <Link to="/transport_windows/search">Buscar transportistas</Link>
                            <a href="#para-quien">Para quién</a>
                            <a href="#como-funciona">Cómo funciona</a>
                            <a href="#confianza">Confianza</a>
                        </nav>
                        <SessionWidget />
                    </div>
                </div>
            </header>

            <main id="main">
                <section id="inicio" className="hero">
                    <div className="container">
                        <p className="kicker" aria-hidden="false">
                            <span className="kickerDot" aria-hidden="true" />
                            {hero.kicker}
                        </p>
                        <h1 className="headline">{hero.title}</h1>
                        <p className="subhead">{hero.subtitle}</p>
                        <p className="subheadAside">{hero.description}</p>

                        <div className="ctaRow">
                            <Link className="button buttonPrimary" to="/signup?role=shipper">
                                {hero.cta_primary}
                            </Link>
                            <Link className="button buttonGhost" to="/signup?role=carrier">
                                {hero.cta_secondary}
                            </Link>
                            <a className="textLink" href="#como-funciona">
                                Ver cómo funciona <span aria-hidden="true">→</span>
                            </a>
                        </div>

                        <ul className="proofRow" aria-label="Señales de confianza">
                            <li className="proofChip">
                                <strong>Precio acordado antes de salir</strong>
                                <span>Sin recargos en el camino</span>
                            </li>
                            <li className="proofChip">
                                <strong>Verificación de transportistas</strong>
                                <span>Licencia, seguro y patente</span>
                            </li>
                            <li className="proofChip">
                                <strong>Alcance federal</strong>
                                <span>Envíos a todo el país</span>
                            </li>
                        </ul>
                    </div>
                </section>

                <section id="para-quien" className="section section--paraQuien">
                    <div className="container">
                        <p className="sectionKicker">Para quién</p>
                        <h2 className="sectionTitle">
                            Una plataforma, dos lados. Ningún intermediario.
                        </h2>

                        <div className="audienceSplit">
                            <article className="audienceCard audienceCard--shipper">
                                <p className="audienceLabel">{audiences.shipper.label}</p>
                                <h3 className="audienceTitle">{audiences.shipper.title}</h3>
                                <p className="audienceLead">{audiences.shipper.description}</p>
                                <ul className="audienceBullets">
                                    {audiences.shipper.bullets.map((b) => (
                                        <li key={b}>
                                            <BulletCheck />
                                            <span>{b}</span>
                                        </li>
                                    ))}
                                </ul>
                                <Link className="audienceCta" to="/signup?role=shipper">
                                    {audiences.shipper.cta} <span aria-hidden="true">→</span>
                                </Link>
                            </article>

                            <article className="audienceCard audienceCard--carrier">
                                <p className="audienceLabel">{audiences.carrier.label}</p>
                                <h3 className="audienceTitle">{audiences.carrier.title}</h3>
                                <p className="audienceLead">{audiences.carrier.description}</p>
                                <ul className="audienceBullets">
                                    {audiences.carrier.bullets.map((b) => (
                                        <li key={b}>
                                            <BulletCheck />
                                            <span>{b}</span>
                                        </li>
                                    ))}
                                </ul>
                                <Link className="audienceCta" to="/signup?role=carrier">
                                    {audiences.carrier.cta} <span aria-hidden="true">→</span>
                                </Link>
                            </article>
                        </div>
                    </div>
                </section>

                <section id="como-funciona" className="section section--steps">
                    <div className="container">
                        <p className="sectionKicker">Cómo funciona</p>
                        <h2 className="sectionTitle">Tres pasos. Sin formularios eternos.</h2>

                        <ol className="stepList" aria-label="Pasos del proceso">
                            {steps.map((step) => (
                                <li key={step.n} className="stepItem">
                                    <span className="stepNumber" aria-hidden="true">
                                        {step.n}
                                    </span>
                                    <div className="stepBody">
                                        <h3 className="stepTitle">{step.title}</h3>
                                        <p className="stepLine">
                                            <span className="stepRole">Expedidor</span>
                                            {step.shipper}
                                        </p>
                                        <p className="stepLine">
                                            <span className="stepRole stepRole--carrier">
                                                Transportista
                                            </span>
                                            {step.carrier}
                                        </p>
                                    </div>
                                </li>
                            ))}
                        </ol>
                    </div>
                </section>

                <section id="confianza" className="section section--confianza">
                    <div className="container">
                        <p className="sectionKicker">Por qué Truckr®</p>
                        <h2 className="sectionTitle">Honesto en el precio. Claro en la información. Humano en el trato.</h2>

                        <div className="featureGrid" aria-label="Características">
                            {features.map((feature) => (
                                <article key={feature.id} className="featureItem">
                                    <div className="featureTop">
                                        <span className="iconDot">
                                            <FeatureIcon name={feature.icon} />
                                        </span>
                                        <h3>{feature.title}</h3>
                                    </div>
                                    <p>{feature.description}</p>
                                </article>
                            ))}
                        </div>

                        <div className="commitments" aria-label="Compromisos">
                            <p className="commitmentsLead">
                                Nuestros tres compromisos, sin asteriscos:
                            </p>
                            <ul>
                                {commitments.map((c) => (
                                    <li key={c.title}>
                                        <h3>{c.title}</h3>
                                        <p>{c.body}</p>
                                    </li>
                                ))}
                            </ul>
                        </div>
                    </div>
                </section>

                <section id="empezar" className="section section--cta" aria-labelledby="empezar-title">
                    <div className="container">
                        <div className="ctaPanel">
                            <p className="sectionKicker sectionKicker--invert">{finalCta.kicker}</p>
                            <h2 className="sectionTitle sectionTitle--cta" id="empezar-title">
                                {finalCta.title}
                            </h2>
                            <p className="ctaPanelLead">{finalCta.subtitle}</p>
                            <div className="ctaPanelRow">
                                <Link className="button buttonPrimary buttonPrimary--invert" to="/signup?role=shipper">
                                    {finalCta.shipper}
                                </Link>
                                <Link className="button buttonGhost buttonGhost--invert" to="/signup?role=carrier">
                                    {finalCta.carrier}
                                </Link>
                            </div>
                            <p className="ctaPanelLogin">
                                {finalCta.loginPrompt}{" "}
                                <Link to="/login">{finalCta.loginLabel}</Link>
                            </p>
                        </div>
                    </div>
                </section>

                <footer className="footer">
                    <div className="container">
                        <div className="footerInner">
                            <div className="footerBrand">
                                <strong>{hero.brand}</strong>
                                <span>Transportistas independientes y expedidores, en un mismo lugar.</span>
                            </div>
                            <nav className="footerNav" aria-label="Enlaces secundarios">
                                <a href="#para-quien">Para quién</a>
                                <a href="#como-funciona">Cómo funciona</a>
                                <a href="#confianza">Confianza</a>
                            </nav>
                            <div className="legal">© 2026 Truckr®. Hecho en FIUBA.</div>
                        </div>
                    </div>
                </footer>
            </main>
        </div>
    );
}
