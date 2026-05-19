---
name: Truckr® Landing
description: Plain-spoken Argentine freight marketplace — calm, paper-feeling, trust-forward.
colors:
  open-sky-blue: "oklch(70% 0.14 232)"       # #46aadc — committed cerulean
  manifest-cream: "oklch(80% 0.13 82)"       # #e1be5a — honey saffron
  cool-concrete: "oklch(67% 0.01 260)"       # #9ca0a8 — structural neutral
  signal-coral: "oklch(64% 0.18 25)"         # #e26464 — reserved error
  paper-white: "#ffffff"
  deep-harbor: "oklch(45% 0.09 220)"
  tinted-ink: "oklch(18% 0.02 240)"
  tinted-ink-2: "oklch(35% 0.02 240)"
  tinted-ink-3: "oklch(52% 0.02 240)"
  surface-warm: "oklch(97% 0.025 82)"        # white 96% + manifest-cream
  surface-warm-2: "oklch(94% 0.05 82)"       # white 90% + manifest-cream
  surface-warm-3: "oklch(89% 0.09 82)"       # white 82% + manifest-cream
  surface-cool: "oklch(94% 0.05 232)"        # white 88% + open-sky-blue
  surface-cool-2: "oklch(85% 0.11 232)"      # white 72% + open-sky-blue
typography:
  display:
    fontFamily: "Unbounded, ui-sans-serif, system-ui, sans-serif"
    fontSize: "clamp(2.6rem, 6.4vw, 5.6rem)"
    fontWeight: 700
    lineHeight: 0.98
    letterSpacing: "-0.045em"
  headline:
    fontFamily: "Unbounded, ui-sans-serif, system-ui, sans-serif"
    fontSize: "clamp(1.75rem, 3.6vw, 2.8rem)"
    fontWeight: 700
    lineHeight: 1.06
    letterSpacing: "-0.035em"
  title:
    fontFamily: "Unbounded, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1.35rem"
    fontWeight: 700
    lineHeight: 1.2
    letterSpacing: "-0.025em"
  body:
    fontFamily: "Alegreya Sans, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1rem"
    fontWeight: 400
    lineHeight: 1.55
    letterSpacing: "normal"
  label:
    fontFamily: "Unbounded, ui-sans-serif, system-ui, sans-serif"
    fontSize: "0.8125rem"
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: "0.08em"
rounded:
  sm: "10px"
  md: "16px"
  lg: "24px"
  pill: "999px"
spacing:
  "1": "4px"
  "2": "8px"
  "3": "12px"
  "4": "16px"
  "5": "24px"
  "6": "32px"
  "7": "48px"
  "8": "64px"
  "9": "96px"
components:
  button-primary:
    backgroundColor: "{colors.tinted-ink}"
    textColor: "{colors.paper-white}"
    rounded: "{rounded.pill}"
    padding: "13px 20px"
  button-primary-hover:
    backgroundColor: "{colors.tinted-ink}"
    textColor: "{colors.paper-white}"
    rounded: "{rounded.pill}"
    padding: "13px 20px"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.tinted-ink}"
    rounded: "{rounded.pill}"
    padding: "13px 20px"
  chip-kicker:
    backgroundColor: "{colors.surface-warm-2}"
    textColor: "{colors.tinted-ink-2}"
    rounded: "{rounded.pill}"
    padding: "6px 12px"
  audience-card-shipper:
    backgroundColor: "{colors.surface-cool}"
    textColor: "{colors.tinted-ink}"
    rounded: "{rounded.lg}"
    padding: "44px"
  audience-card-carrier:
    backgroundColor: "{colors.surface-warm-2}"
    textColor: "{colors.tinted-ink}"
    rounded: "{rounded.lg}"
    padding: "44px"
  feature-card:
    backgroundColor: "{colors.surface-warm}"
    textColor: "{colors.tinted-ink}"
    rounded: "{rounded.md}"
    padding: "24px"
  commitments-band:
    backgroundColor: "{colors.tinted-ink}"
    textColor: "{colors.paper-white}"
    rounded: "{rounded.lg}"
    padding: "40px"
---

# Design System: Truckr® Landing

## 1. Overview

**Creative North Star: "The Plain-Spoken Dispatch"**
**Color strategy: Committed (two-voice), drenched at the final CTA.**

Truckr®'s landing reads like an honest freight-office desk under daylight: paper-cream and open-sky surfaces carry real coverage now instead of whispering. The system is light-first and editorial — closer to a well-set printed dispatch sheet than a SaaS template — but the cream and sky tints are the page's voice, not a background hum. Two voices share the surface (Manifest Cream for the carrier side, Open-Sky Blue for the shipper side); a deep teal-navy stamp (Deep Harbor) earns its rare appearances. The display face (Unbounded) does the load-bearing personality work — geometric but not corporate, with negative letterspacing that gives headlines weight — while Alegreya Sans body keeps reading effortless.

The system explicitly rejects what trucking-tech usually defaults to: no "Uber for trucks" neon-on-black, no SaaS-cream-with-gradient-headline template, no logistics stock photography. Trust here is built by clarity (no hidden charges), real numbers (verifications, history), and a deliberate palette — not by exclamation. The Committed strategy means surfaces can be 30–60% saturated brand color (the para-quien split, the audience cards, the final CTA band); the One-Stamp Rule still constrains Deep Harbor to under ~5% per screen.

**Key Characteristics:**
- Light-first, **committed** two-voice surfaces — Manifest Cream for the carrier voice, Open-Sky Blue for the shipper voice — each carrying real chromatic coverage, not a faint wash.
- Asymmetric two-up audience layout; shipper card sits in sky, carrier card sits in cream, and the para-quien section ground is a vertical split echoing the same two voices.
- Pill is the dominant radius for interactive elements; rectangles with 16–24px corners for containers.
- One editorial accent (Deep Harbor), used sparingly as a stamp (kicker dots, section eyebrows, step numerals, bullet ticks, the third feature card's icon dot, the chromatic ribbon at the foot of the commitments band).
- The final CTA band is **drenched** — Open-Sky Blue runs corner-to-corner with a Manifest Cream radial bleed, type stays solid ink, no inner panel.
- Hover lift is small (`translateY(-1px)` to `-2px`), never a scale transform.

## 2. Colors

A two-voice palette — warm cream for the carrier side, open-sky blue for the shipper side — pinned to a near-black tinted ink and one deep teal-navy accent.

### Primary
- **Open-Sky Blue** (`oklch(70% 0.14 232)`, source token `--brand-primary` / `#46aadc`): the shipper voice. A committed cerulean — not a wash. Carries real coverage at the source, so mixes work at higher white percentages without going monochrome. Tints the shipper audience card (white 70% + sky), the left half of the para-quien split, the second feature card and its icon dot, the upper-right hero wash, and **drenches** the final CTA band (white 30–55% + sky across the full surface). Used at full strength only inside the chromatic ribbon segment under the commitments band.
- **Manifest Cream** (`oklch(80% 0.13 82)`, source token `--brand-secondary` / `#e1be5a`): the carrier voice. A committed honey saffron — ledger-warm without going washed-out. Tints the carrier audience card (white 68% + cream), the right half of the para-quien split, the steps section ground, the first feature card and its icon dot, the kicker chip, the lower-left hero wash, the footer surface, and the warm radial bleed in the final CTA. The page background is white mixed with cream throughout.

### Secondary
- **Deep Harbor** (`oklch(45% 0.09 220)`, source token `--accent`): the single editorial accent. A deep teal-navy that stays distinct from the now-richer Open-Sky by sitting much darker and slightly cooler in hue. Appears on the kicker dot, the eyebrow kickers above each section, the step numerals (`01`, `02`, `03`), the audience-bullet check icons, the third feature card's icon dot fill (the "trazabilidad" stamp), and the rightmost 1/3 segment of the commitments band's chromatic ribbon. Rare on purpose.

### Tertiary
- **Cool Concrete** (`oklch(67% 0.01 260)`, source token `--brand-tertiary` / `#9ca0a8`): structural neutral. Used inside `color-mix` formulas to build borders (`var(--border)`) and rule-lines. Cooler than the prior warm-concrete to keep border tones from leaning into the now-saturated honey hue. Never a fill.
- **Signal Coral** (`oklch(64% 0.18 25)`, source token `--brand-error` / `#e26464`): error-state hint only. A confident coral — pairs with the saturated brand voices rather than reading as a pink wash. Currently held in reserve for form validation. Never used decoratively.

### Neutral
- **Tinted Ink** (`oklch(18% 0.02 240)`, source token `--ink`): body text, primary button fill. A near-black tinted toward the brand-primary hue — never `#000`. No longer used as a section or band surface; the page is fully light-first now.
- **Tinted Ink 2** (`oklch(35% 0.02 240)`, source token `--ink-2`): secondary text, nav links, audience-card lead copy.
- **Tinted Ink 3** (`oklch(52% 0.02 240)`, source token `--ink-3`): tertiary text, captions, footer legal line.
- **Surface Warm** (`--surface`): default page background — white mixed 94% with Manifest Cream.
- **Surface Warm 2** (`--surface-2`): white mixed 84% with cream — the cream-side ground of the para-quien split.
- **Surface Warm 3** (`--surface-3`): white mixed 70% with cream — the steps section ground, the carrier card's denser cream neighbor.
- **Surface Cool** (`--surface-cool`): white mixed 80% with Open-Sky Blue — the sky-side ground of the para-quien split.
- **Surface Cool 2** (`--surface-cool-2`): white mixed 62% with Open-Sky Blue — the high-coverage sky band used inside the final CTA gradient stops.
- **Tint Sky** (`--tint-sky`): white mixed 50% with Open-Sky Blue — reserved for inline emphasis chips and large coverage moments inside the shipper voice.
- **Tint Cream** (`--tint-cream`): white mixed 48% with Manifest Cream — reserved for inline emphasis chips and large coverage moments inside the carrier voice.
- **Paper White** (`#ffffff`, `--brand-neutral`): reserved for the inverted ghost button surface on the drenched CTA — never as ink, never as a section ground. Every section now sits on a tinted committed surface.

### Named Rules

**The One Stamp Rule.** Deep Harbor is the accent's only job. It appears on the kicker dot, section eyebrows, step numerals, bullet ticks, and the third feature card's icon dot fill (with a small accent-tinted shadow) — and nowhere else. If it ever covers more than ~5% of any screen, it has been misused; recolor to ink or a tinted neutral instead. The third feature card's surface is sky (not ink); only its icon dot carries the accent.

**The Two-Voice Rule.** Open-Sky Blue speaks for shippers; Manifest Cream speaks for carriers. Never mix them on a single role-paired component. The shipper audience card is sky-tinted; the carrier card is cream-tinted; chips and stamps for each role inherit that tint. Where the two voices coexist on the same surface (the para-quien vertical split, the final CTA's sky-with-cream-bleed, the commitments chromatic ribbon), the split is geometric and deliberate — not a blend.

**The Committed-Coverage Rule.** Brand colors carry real coverage at the source — Open-Sky is a committed cerulean (`#46aadc`, `oklch 70% 0.14 232`), not a pale wash; Manifest Cream is a honey saffron (`#e1be5a`, `oklch 80% 0.13 82`), not an ivory tint. Because the source has real chroma, surface mixes use higher white percentages (audience cards 68–70%, feature cards 84%) than would be needed for a pale-source palette and still read as confident hues. The para-quien section is a sky-and-cream split (not paper-white); the final CTA is drenched corner-to-corner. If a surface reads monochrome, the fix is at the source — bump the brand hex, not the mix ratio.

**The No-Pure-Neutral Rule.** No `#000`, no `#fff` in text or interactive states. Every neutral is tinted toward the brand-primary hue (chroma 0.005–0.02). `#ffffff` is reserved for the Confianza section ground and the inverted ghost button on the drenched CTA — never as ink.

## 3. Typography

**Display Font:** Unbounded (with `ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif` fallback)
**Body Font:** Alegreya Sans (with the same sans fallback)

**Character:** Unbounded carries the personality — geometric, slightly architectural, but warmed by curved counters; tight negative letterspacing (`-0.03em` to `-0.045em`) gives headlines weight without shouting. Alegreya Sans body is a humanist sans with generous x-height that stays readable down to 0.8125rem captions, balancing Unbounded's geometry.

### Hierarchy
- **Display** (Unbounded 700, `clamp(2.6rem, 6.4vw, 5.6rem)`, `line-height: 0.98`, `letter-spacing: -0.045em`): hero headline only. Capped at 18ch with `text-wrap: balance`.
- **Headline** (Unbounded 700, `clamp(1.75rem, 3.6vw, 2.8rem)`, `line-height: 1.06`, `letter-spacing: -0.035em`): section titles ("¿Para quién es Truckr®?", "Cómo funciona", "Una plataforma con compromisos"). Capped at 24ch with balanced wrap.
- **Title** (Unbounded 700, `1.35rem`, `letter-spacing: -0.025em`): audience card titles, step titles, feature card `h3`, commitments `h3`.
- **Body** (Alegreya Sans 400, `1rem`, `line-height: 1.55`): paragraph text. Capped at 50–64ch depending on container.
- **Body Large** (Alegreya Sans 400, `clamp(1.05rem, 1.6vw, 1.25rem)`, `line-height: 1.45`): hero subhead, section lead. Capped at 56ch.
- **Caption** (Alegreya Sans 400, `0.9375rem`): step lines, footer nav, proof-chip descriptions.
- **Label / Eyebrow** (Unbounded 600, `0.8125rem`, `letter-spacing: 0.08em`, uppercase): section kickers, audience labels, role chips, step role tags. Color is Deep Harbor on a light surface, Tinted Ink 2 on a tinted surface.

### Named Rules

**The Single Display Rule.** Unbounded is the only display face. Headlines, eyebrows, numerals, role tags, brand wordmark — all Unbounded. Never substitute a second display face "for variety."

**The Negative-Space Rule.** Display sizes always carry negative letterspacing (`-0.025em` to `-0.045em`). Positive letterspacing belongs to uppercase labels only (`+0.06em` to `+0.08em`). Body copy is `normal`.

**The Balanced-Wrap Rule.** Hero headline and section titles use `text-wrap: balance` with explicit `max-width` in ch. Long headlines that wrap to a stubby last line are forbidden — adjust the max-width or rewrite the copy.

## 4. Elevation

Flat-by-default with two deliberate softnesses: an ambient drop on the primary button, and a low ambient lift on feature-card hover. The commitments band creates depth chromatically — a deep honey saffron sitting on the lighter cream Confianza ground — supported by an ambient cream-tinted shadow. Sectioning happens through tonal stepping of committed surfaces and 1px rule-lines, never through floating cards.

### Shadow Vocabulary
- **Button shadow** (`box-shadow: 0 8px 24px color-mix(in oklab, var(--ink) 18%, transparent)`): the primary button at rest. Reinforces "this is the action."
- **Button shadow lifted** (`box-shadow: 0 12px 28px color-mix(in oklab, var(--ink) 24%, transparent)`): primary button on hover, paired with `translateY(-1px)`.
- **Feature hover ambient** (`box-shadow: 0 16px 40px color-mix(in oklab, var(--ink) 10%, transparent)`): only appears on `:hover` of feature cards, only when `(hover: hover)` matches.
- **Skip-link drop** (`box-shadow: var(--shadow-md)`, defined as `0 10px 30px color-mix(in oklab, black 16%, transparent)`): only visible when the skip link is focused.

### Named Rules

**The Flat-By-Default Rule.** Surfaces are flat at rest. Shadows appear only as a response to state (button rest, button hover, feature hover, focus on skip-link). A card sitting still must not float.

**The No-Inner-Shadow Rule.** No `inset` shadows, no glassmorphism blur as decoration. The topbar uses a `backdrop-filter` because it sits over scrolling content — that is its only earned use.

## 5. Components

Components are described in the order they appear on the page.

### Topbar (sticky)
- **Layout:** flex, brand left, nav right, `padding: var(--space-3) 0`.
- **Surface:** sticky, `backdrop-filter: saturate(140%) blur(8px)`, background is the page surface at 78% opacity. 1px bottom border (Warm Concrete-tinted).
- **Brand:** wordmark in Unbounded 700, 1.05rem, `letter-spacing: -0.03em`, paired with a smaller Alegreya Sans tagline in Tinted Ink 3.
- **Nav links:** pill (`border-radius: 999px`), padding `10px 12px`, color Tinted Ink 2, font-size `0.9375rem`. Hover fills with `color-mix(--brand-primary 30%, transparent)`.
- **Mobile:** nav hidden under `max-width: 700px`. The brand stays.

### Buttons
- **Shape:** pill (`border-radius: 999px`). `min-height: 44px`. On coarse pointers, padding grows to `15px 22px` (touch target).
- **Primary** (`.buttonPrimary`): Tinted Ink fill, Paper White text, 1px Tinted Ink border, the button shadow at rest. Hover: shifts background to `color-mix(--ink 86%, --accent)`, lifts `translateY(-1px)`, larger shadow.
- **Ghost** (`.buttonGhost`): transparent background, 1px Tinted Ink border, Tinted Ink text. Hover: fills with `color-mix(--ink 6%, transparent)`.
- **Transitions:** `transform 200ms`, `background-color 200ms`, `border-color 200ms`, `box-shadow 200ms`, all on `cubic-bezier(0.16, 1, 0.3, 1)` (ease-out-expo).
- **Text link** (`.textLink`): underline-only with a 1px Tinted-Ink-30% bottom border. Hover fully colors the border and the text to Tinted Ink. Used for the secondary CTA on rows where two pill buttons would compete.

### Kicker chip
- **Shape:** pill, `padding: 6px 12px 6px 10px`, 1px Border-Cream.
- **Background:** white mixed 56% with Manifest Cream — a committed cream chip, not a wash.
- **Type:** Unbounded 600, 0.8125rem, uppercase, `letter-spacing: 0.06em`, Tinted Ink.
- **Stamp dot:** 8×8 Deep Harbor circle with a 3px softened ring (`box-shadow: 0 0 0 3px color-mix(--accent 22%, transparent)`). The system's smallest editorial moment; never recolor.

### Hero (signature)
- **Layout:** kicker → display headline (cap 18ch) → subhead → aside → CTA row → proof chips rule. Padding `clamp(56px, 8vw, 112px) 0 clamp(48px, 6vw, 80px)`.
- **Background:** two diffused radial washes carry the two-voice story — Open-Sky 82% upper-right (deeply cyan now that the source is committed), Manifest Cream 86% lower-left (honey saffron now that the source is committed) — plus a tonal floor radial keeping the center from going flat. No hard-edged ribbon at the right; the saturated washes do all the work without a separate accent block.

### Para-quien section (the two-voice split)
- **Layout:** the section ground is a vertical split — Surface Cool on the left (sky voice) from 0–46%, Surface Warm 2 on the right (cream voice) from 54–100%, with a soft transition between. The shipper audience card sits on the cool half; the carrier card sits on the warm half.
- **Mobile:** under `max-width: 899px`, the split collapses to Surface Warm 2; the audience cards still carry their own committed tints.
- **Why:** the page ground itself enacts the two-voice rule before the cards reinforce it.

### Audience cards (signature — two-up, asymmetric)
- **Layout:** 2-up grid, `1.05fr / 0.95fr` ratio at `min-width: 900px`; stacked under that. The carrier card carries `margin-top: var(--space-7)` at md+ so the two cards never align top-to-top.
- **Shape:** `border-radius: var(--radius-lg)` (24px), `padding: clamp(28px, 3vw, 44px)`.
- **Shipper card** (`.audienceCard--shipper`): white mixed **70%** with Open-Sky Blue, Border-Sky border, ambient sky shadow (`0 18px 50px sky-32%`). Sits on the Surface Cool half of the para-quien split. (Percentage is calibrated against the saturated brand source — the resulting surface is a confident sky-cyan, not a wash.)
- **Carrier card** (`.audienceCard--carrier`): white mixed **68%** with Manifest Cream, Border-Cream border, ambient cream shadow (`0 18px 50px cream-34%`). Sits on the Surface Warm 2 half. (Same calibration: a confident honey, not an ivory variation.)
- **Label:** Unbounded 600 eyebrow, uppercase, 0.8125rem, Tinted Ink 2.
- **Bullets:** custom list with a 22px column for the check SVG (Deep Harbor stroke) and a 1fr text column.
- **CTA:** text-link style — no pill button inside the card. Hover increases the icon gap from 8px to 14px.

### Step list
- **Layout:** 3-up grid at md+, stacked under. Each step is its own grid with a top rule (1px, Tinted Ink 14%). Section ground is Surface Warm 3 (deep cream).
- **Numeral:** Unbounded 700, `clamp(2.4rem, 5vw, 3.6rem)`, Deep Harbor, `font-variant-numeric: tabular-nums`. The largest the accent ever appears.
- **Title:** Title scale (Unbounded 700, 1.35rem).
- **Role tag:** inline pill (`padding: 2px 8px`, pill radius), Unbounded 600 0.7rem uppercase. Shipper role uses Open-Sky Blue 92/white; carrier role uses Manifest Cream 95/white — saturated chips, not whispers.

### Feature grid (two-voice trio, sky-weighted)
- **Layout:** `repeat(auto-fit, minmax(260px, 1fr))`.
- **Card 1 — "Tarifas claras":** white mixed 84% with Manifest Cream surface, Border-Cream border, saturated cream icon dot (cream 92/white). Carrier-voice tinted (pricing is the carrier-side conversation).
- **Card 2 — "Trato directo":** white mixed 84% with Open-Sky Blue surface, Border-Sky border, saturated sky icon dot (sky 88/white). Shipper-voice tinted (the conversation is the shipper's first reach).
- **Card 3 — "Trazabilidad real":** Surface Cool 2 (white 72% + sky) — a deeper saturation of the shipper voice. Border tints further toward full sky. Ink text on a confident sky ground, with a **Deep Harbor icon dot** carrying a soft 4-px accent shadow as the trust stamp. The trio reads as cream / sky / deeper-sky, weighted toward the shipper voice because data/trust is a shipper-side concern.
- **Hover** (only when `hover: hover`): `translateY(-2px)`, ambient shadow at `ink-14%`, border darkens. The deep-sky card's hover deepens to a near-full Open-Sky border with a sky-tinted shadow.

### Commitments band
- **Layout:** full-width within container, 24px radius, `padding: clamp(24px, 3vw, 40px)`, 3-up grid of commitments under md+.
- **Surface:** white mixed 35% with Manifest Cream — a deep honey saffron, the deepest carrier-voice moment on the page. Carries a 1px ink-tinted cream border and an ambient cream shadow (`0 20px 50px cream-38%`) lifting it off the lighter Confianza ground. Bounded — does not bleed past the container.
- **Lead text:** Unbounded 600, Tinted Ink. Dark-on-honey is the stamp's "ledger ink" feel.
- **Body text:** Tinted Ink 2 (`oklch 35% 0.02 240`), ~7:1 against the honey ground.
- **Dividers:** 1px top-rule on each commitment, `color-mix(in oklab, var(--ink) 22%, transparent)` — visible ink rule on cream, not a faint white rule on dark.

### Final CTA (drenched)
- **Layout:** full-bleed section, `padding: clamp(64px, 8vw, 120px) 0`, 1px top/bottom borders.
- **Surface:** drenched — a 135° linear gradient from sky 70-mix → sky 48-mix → cream 40-mix across the corner-to-corner expanse, with a 70%-diameter radial of Manifest Cream bleeding from the bottom-right edge. The surface IS the color. No inner panel.
- **Type:** Tinted Ink for the headline (`--ink`), Tinted Ink for the kicker (`--ink-on-sky`), Tinted-Ink-on-Sky for lead and login text. The two CTA buttons sit directly on the sky: primary (ink fill, larger ambient shadow), ghost-invert (Paper White fill, ink border).
- **Why:** the final CTA is the page's single Drenched moment — Open-Sky carries the surface because the call-to-action is a shipper-side ask (request a quote). Cream radiates from the carrier corner so neither voice is silenced.

### Footer
- **Surface:** white mixed 76% with Manifest Cream — a deeper cream tone, 1px top border. Continues the committed two-voice ground onto the page's foot.
- **Layout:** 3-col grid at md+ (`1.4fr 1fr auto`) with brand, nav, legal.
- **Type:** small caption scale; legal uses tabular numerals.

### Inputs (system reserve)
The landing page itself has no form fields; the auth and carrier flows do (see `src/styles/auth.css`, `carrier.css`). When extending the landing with a form on this surface, follow:
- 16px radius, 1px Warm-Concrete-tinted border at rest.
- Focus uses the global `:focus-visible` rule (3px Tinted-Ink-15% outline, 3px offset).
- Never replace the global focus ring with a custom border-swap; the outline is the system's accessibility floor.

### Named Rules

**The Asymmetric-Pair Rule.** When two role-paired components appear side by side (audience cards, role tags, paired CTAs), they must differ in at least two of: width, offset, tint, copy length. Identical mirroring is forbidden; it flattens the two-sided story.

**The Pill-or-Container Rule.** Pill radius (`999px`) is reserved for interactive elements (buttons, chips, nav links, role tags, icon dots). Containers (cards, sections, the commitments band) use the 16px/24px square-radius scale. Never use pill on a container.

## 6. Transactional Components (US7 — Offer Wizard)

These components live in the shipper offer flow (`/carriers/:id/offers/new`) and inherit the Open-Sky Blue shipper voice throughout.

### Wizard shell (`.wizard`, `.wizardPage`)

- **`.wizardPage`**: A `680px`-capped grid wrapper with `padding: var(--space-6) 0 var(--space-8)` and `gap: var(--space-4)`. Houses the page `<h1>`, an optional error `Alert`, and the wizard itself.
- **`.wizard`**: A `680px`-capped grid with `gap: var(--space-5)`. Contains the step indicator nav, the body card, and the nav row.

### Step indicator (`.wizardSteps`, `.wizardStep`, `.wizardStepNumber`, `.wizardStepLabel`)

- **Layout**: Horizontal flex strip. A single 1px connector line is drawn via `.wizardSteps::before` spanning from centre of first circle to centre of last circle. Step circles sit above it via `z-index: 1`.
- **Circle (22×22px pill)**: Three states:
  - *Upcoming*: border `color-mix(var(--ink) 30%, white)`, text `var(--ink-2)`, background `var(--page-bg)` (occludes the line).
  - *Current*: background `var(--accent)` (Deep Harbor), text `var(--paper)`. The single high-contrast moment in the strip; Deep Harbor at full strength here is its only fill-use in the wizard.
  - *Done*: number text replaced with `✓` via `::before`, light tinted fill.
- **Labels (Unbounded 600, 0.6875rem)**: Upcoming → `var(--ink-2)` (≥4.5:1), Current → `var(--ink)`, Done → `var(--ink-2)` (≥4.5:1 — WCAG 1.4.3 AA floor for 12px text). Transitions at 200ms ease-out-expo.

### Step body card (`.wizardBody`)

- Surface: `var(--surface)`, 1px border, `var(--radius-lg)` (24px) radius.
- Padding: 24px on mobile, 32px on ≥560px.

### Step fieldset (`.wizardFieldset`, `.wizardLegend`)

- **`.wizardFieldset`**: A grid with `gap: var(--space-5)`. Form fields stack vertically.
- **`.wizardLegend`**: Unbounded 700, 1.05rem, `letter-spacing: -0.02em`. Acts as the step question or section title.

### Window summary card (`.windowSummaryCard`)

- Shipper-voice card: background tinted 18% with `var(--brand-primary)`, border 50% brand-primary.
- Route (`.windowZone`): Unbounded 700, `0.9375rem`, tight letterspacing.
- Rate (`.windowRate`): Alegreya Sans, `var(--text-sm)`, `var(--ink-2)`.
- 16px radius (`.radius-md`), 16px/24px padding.

### Cost estimate (`.costEstimate`)

- The emotional anchor of step 3: a branded flex row on a 45% brand-secondary tinted surface.
- Label span: Alegreya Sans sm, `var(--ink-2)`.
- Amount `<strong>`: Unbounded 700, `clamp(1.5rem, 5vw, 2rem)`, `letter-spacing: -0.04em`, Deep Harbor — the largest number the shipper sees before submitting. Fluid sizing keeps it from overflowing on 320px viewports.

### Confirmation panel (`.confirmationPanel`)

- Centered grid, `max-width: 520px`, auto-margins, `var(--radius-lg)`, 16px gap.
- `text-align: center`, `justify-items: center`.
- Reference chip (`.confirmationRef`): Unbounded 700 uppercase, pill radius, 15% brand-primary background tint.
- Status text (`.confirmationStatus`): Alegreya Sans sm, `var(--ink-2)`, `max-width: 44ch`.

### Named Rules (wizard-specific)

**The Shipper-Voice-Throughout Rule.** Every information surface in the offer wizard (summary card, cost estimate, connector line tint) uses Open-Sky Blue (`var(--brand-primary)`). The carrier voice (Manifest Cream) does not appear on any element the shipper directly interacts with in this flow.

**The Constraint-as-Gift Rule.** Capacity hints (weight/volume) and date bounds are shown proactively in `FormField help` props, not only surfaced on error. The user should feel informed, not corrected.

**The Anchor-the-Number Rule.** The cost estimate amount is in Unbounded 700 at `clamp(1.5rem, 5vw, 2rem)` — larger than any label in the form, scaling down gracefully on narrow viewports. The financial figure is the most important thing on step 3; style it accordingly.

## 7. Motion

One orchestrated entrance carries the page; afterwards motion is feedback, not decoration.

### Tokens
- `--motion-entry: 620ms` — base duration for the hero entrance and scroll reveals.
- `--motion-stagger: 140ms` — default stagger step between siblings (steps, features, audience cards).
- `--motion-ease: cubic-bezier(0.22, 1, 0.36, 1)` — ease-out-quint. Used for all reveal transitions and `@keyframes`. Confident, decisive, no overshoot.
- `--motion-ease-soft: cubic-bezier(0.16, 1, 0.3, 1)` — ease-out-expo. Used for button hover and the topbar elevation. Slightly slower-feeling at the end for atmospheric settling.

### Hero entrance (on mount)
- Pure CSS `@keyframes hero-rise` (opacity + translateY 24 → 0) on every immediate child of `.hero > .container`, sequenced by `animation-delay`:
  - Kicker: 80ms
  - Headline: 200ms
  - Subhead: 360ms
  - CTA row: 500ms
  - Proof chips: 680ms
- The radial washes (`.hero::before`) ride a separate `hero-wash` keyframe — slight zoom-out (scale 1.06 → 1) over 1100ms — so the page literally "develops" before the type lands.
- Total choreography clears in ~1.3s. After that the hero is static; no parallax, no autoplay video, no scroll-jacking.

### Scroll reveals (per section)
- Each revealable element carries `data-reveal`. A single `IntersectionObserver` mounted in `LandingPage` toggles `data-revealed` once the element crosses **18% threshold with a -6% bottom rootMargin** (fires slightly before the element enters the viewport).
- Elements start `opacity: 0` + `translateY(22px)` and animate to neutral over `--motion-entry` with optional per-element delay via `--reveal-delay` (CSS custom property set inline).
- Stagger pattern within a section: kicker (0ms) → title (100ms) → first-child (220ms) → stagger by 140ms.
- Audience cards reveal with **asymmetric start vectors** — shipper translates from `-14px, 22px`, carrier from `+14px, 22px` — so the two voices converge on landing instead of fading in identically.
- Step numerals get an extra `+80ms` delay and travel an additional 10px upward — they feel "stamped into place" against their step body.
- The observer disconnects after each element fires; reveals don't replay.

### Topbar elevation (scroll-driven)
- The topbar starts with a transparent bottom border and no shadow. A scroll listener on `window` toggles `data-scrolled="true"` on `.page` whenever `scrollY > 24`.
- When elevated: background opacity rises from 82% → 94%, border-bottom becomes visible, a soft ink-tinted shadow (`0 6px 24px ink-8%`) appears. Transition runs 280ms with `--motion-ease-soft`.
- This is the only scroll-driven UI change. No parallax, no scroll-linked color shifts.

### In-page navigation
- `html { scroll-behavior: smooth }` lets nav anchor jumps (`#para-quien`, `#como-funciona`, `#confianza`) glide instead of teleport.

### Accessibility
- `prefers-reduced-motion: reduce` cancels all entrance animations and reveal transitions — elements appear in their landed state immediately. The hero washes appear without zoom; cards appear without translate. The smooth scroll behavior also collapses to `auto`.
- The global rule in `global.css` collapses `animation-duration` and `transition-duration` to `0.01ms`; the landing CSS additionally strips the `opacity: 0` and `transform` initial states under reduced motion so users never see the "not yet revealed" frame.
- The IntersectionObserver path also explicitly checks `matchMedia('(prefers-reduced-motion: reduce)')` and marks every reveal target as `data-revealed` immediately when set, so even before CSS kicks in the elements render.

### Named Rules

**The One-Entrance Rule.** The page has exactly one orchestrated load sequence — the hero — and one reveal idiom per section. No element animates twice on its own. No bouncing icons, no looping pulses, no autoplaying carousels. If a motion can't be explained by "I'm appearing" or "you scrolled past me," it doesn't belong here.

**The Asymmetric-Stagger Rule.** The audience-card pair must reveal with mirrored-but-opposite start vectors. They are the layout's signature; their motion has to reinforce the two-voice metaphor, not flatten it.

**The Reveal-Once Rule.** Reveal targets fire exactly once on first intersection and the observer disconnects. Re-entering the viewport doesn't replay; the page is meant to feel "set" after the first read-through, not a kinetic loop.

## 8. Do's and Don'ts

### Do:
- **Do** keep the page **light-first throughout** with committed cream and sky surfaces. The single drenched moment is the final CTA; the deepest committed moment is the honey commitments band. No section, band, or card uses a dark fill — Tinted Ink is reserved for text and the primary button.
- **Do** tint every neutral toward the brand hue. Use `color-mix(in oklab, …)` against `--brand-primary` or `--brand-secondary`.
- **Do** treat Deep Harbor as a stamp — kicker dot, section eyebrow, step numeral, bullet tick, third feature card's icon dot, and the rightmost ribbon segment under the commitments band. Nowhere else.
- **Do** keep the shipper voice in Open-Sky Blue and the carrier voice in Manifest Cream, always paired with role-specific copy. When the two voices coexist on a single surface (para-quien split, drenched CTA, chromatic ribbon), the split is geometric — not a blend.
- **Do** use Unbounded 700 with tight negative letterspacing (`-0.025em` to `-0.045em`) for headlines, and `text-wrap: balance` to control wrap.
- **Do** make hover a 1–2px lift and a soft shadow change. No scale, no spring, no bounce.
- **Do** respect `prefers-reduced-motion`; the global rule already collapses animations to `0.01ms`.
- **Do** use the global `:focus-visible` outline (3px Tinted-Ink-15%, 3px offset). It is the accessibility floor.

### Don't:
- **Don't** style anything to look like "Uber for trucks" tech-bro aesthetic — neon-on-black, hard sans shouting velocity, motion-blurred highway hero. This is the explicit anti-reference in PRODUCT.md.
- **Don't** ship the generic SaaS-cream landing template (pastel hero illustration, three identical icon-heading-text cards in a row, gradient-text headline). PRODUCT.md rejects this by name.
- **Don't** use logistics stock photography — forklifts, container ports, blurred trucks. Visually loud, semantically empty.
- **Don't** apply `background-clip: text` with a gradient to any headline. Solid Tinted Ink, always.
- **Don't** add a colored **side-stripe** (`border-left: 4px solid …`) to any card, callout, or list item. The bottom-side chromatic ribbon under the commitments band is the only intentional thick-stripe in the system, and it sits at the foot — not on a side.
- **Don't** put glassmorphism (heavy blur, glass card) anywhere except the topbar's earned `backdrop-filter`.
- **Don't** use `#000` or `#fff` as ink or as a focus state. Every neutral is tinted (chroma ≥ 0.005 toward 240).
- **Don't** make the audience cards identical mirrors. The asymmetric pair (size + vertical offset + tint) is the layout's point.
- **Don't** add pill radius to containers, or square radius to interactive chips. The Pill-or-Container Rule is load-bearing.
- **Don't** raise Deep Harbor's coverage on a screen above ~5%. If it spreads, recolor to Tinted Ink or a tinted neutral.
- **Don't** drench any surface other than the final CTA. Committed coverage (30–60%) is allowed throughout; Drenched coverage (corner-to-corner) is the final CTA's signature alone.
- **Don't** introduce a second display face. Unbounded is the only display family; substitutions break the "Plain-Spoken Dispatch" character.
