# Product

## Register

brand

## Users

Truckr® is a two-sided transportation platform in Argentina. This landing page must speak to **both**:

- **Expedidores**: people/businesses who need to ship something and want a fast, predictable way to request a quote and find a trustworthy carrier. (Persona ↔ model: `Expedidor` → `Shipper`. Replaces deprecated `Cliente` / `Productor` — see `docs/05-appendices/glossary.md`.)
- **Transportistas**: carriers/drivers evaluating whether the platform brings real demand, fair terms, and reduces friction.

Primary viewing context: **light-theme, mixed-device browsing**, with a strong assumption of **mobile-first scanning** (quick credibility checks, CTA discovery) plus desktop comparison for higher-intent users.

Primary job-to-be-done: **request a quote / publish a shipment** (the main CTA).

## Product Purpose

Convince an expedidor that requesting a quote on Truckr® is safer, clearer, and more humane than calling fleteros directly or posting on classifieds — and simultaneously convince a transportista that the demand on the other side is real and the terms are fair. Success = the request-a-quote CTA gets pressed by qualified shippers, and carriers sign up without feeling like the platform is built against them.

Hard constraints from the current app:

- Content is **API-driven** (hero, features, stats, palette).
- Spanish-first copy, Argentina context (es-AR).
- Content data lives in `src/landingContent.ts` (prototype-stage i18n bundle until a real i18n library lands).

## Brand Personality

Voice targets: **confiable / claro / humano**.

Emotional outcomes:

- Users should feel **safe** (legitimacy, verification, transparency).
- Users should feel **in control** (clear steps, clear expectations, no hidden surprises).
- Users should feel **welcomed** (helpful language, non-corporate warmth).

## Anti-references

- **"Uber for trucks" tech-bro aesthetic**: dark backdrops, neon gradients, hard-edged sans-serifs shouting velocity. Wrong emotional register for Argentine SMEs evaluating who to trust with their cargo.
- **Generic SaaS-cream landing template**: cream/off-white hero, pastel illustration, three-up feature card grid, gradient-text headline. Indistinguishable, slop-shaped.
- **Logistics-stock-photo collage**: forklifts, container ports, motion-blurred highways. Visually loud, semantically empty.
- **Aggressive crypto/fintech maximalism**: heavy 3D, bento-grid maximalism, glassmorphism layered over neon. Reads as risk, not safety.

## Design Principles

- **Trust before flourish**: credibility signals and clarity come first; decoration must earn its place.
- **Two-sided clarity**: make it instantly obvious what Truckr® offers to expedidores vs transportistas without duplicating content.
- **CTA is a verb**: the request-a-quote path is visually and semantically dominant.
- **Fast-feeling UI**: interactions should feel immediate; loading/empty/error states should teach, not punish.
- **Show the real product**: where possible, prefer real screens, real numbers, real testimonials over abstract illustration.

## Accessibility & Inclusion

- **WCAG 2.2 AA** is the floor, not the ceiling.
- Visible, high-contrast focus states on every interactive element; keyboard-only paths must reach the primary CTA without traps.
- Respect `prefers-reduced-motion`: motion is decorative, never load-bearing.
- Light theme is the primary viewing context; assume mobile-first scanning and validate touch targets ≥ 44×44 CSS px.
- Copy is Spanish-first (es-AR), written for plain reading; avoid jargon that locks out non-logistics-native expedidores.
