---
name: Truckr® Landing
description: Plain-spoken Argentine freight marketplace — calm, paper-feeling, trust-forward.
colors:
  open-sky-blue: "oklch(91% 0.05 230)"
  manifest-cream: "oklch(93% 0.06 95)"
  warm-concrete: "oklch(76% 0.005 240)"
  soft-alarm: "oklch(78% 0.13 25)"
  paper-white: "#ffffff"
  deep-harbor: "oklch(45% 0.09 220)"
  tinted-ink: "oklch(18% 0.02 240)"
  tinted-ink-2: "oklch(35% 0.02 240)"
  tinted-ink-3: "oklch(52% 0.02 240)"
  surface-warm: "oklch(98% 0.012 95)"
  surface-warm-2: "oklch(96% 0.022 95)"
  surface-cool: "oklch(98% 0.014 230)"
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

Truckr®'s landing reads like an honest freight-office desk: paper-cream surfaces, plain-spoken typography, and one deep teal-navy that earns its rare appearances. The system is light-first and editorial — closer to a well-set printed dispatch sheet than a SaaS template. Every surface is tinted (toward warm cream for the carrier voice, toward open sky for the shipper voice), so the page feels human instead of clinical. The display face (Unbounded) does the load-bearing personality work — geometric but not corporate, with negative letterspacing that gives headlines weight — while Alegreya Sans body keeps reading effortless.

The system explicitly rejects what trucking-tech usually defaults to: no "Uber for trucks" neon-on-black, no SaaS-cream-with-gradient-headline template, no logistics stock photography. Trust here is built by clarity (no hidden charges), real numbers (verifications, history), and restraint — not by exclamation. The single editorial accent (Deep Harbor) is the visual equivalent of a stamp: rare, deliberate, never decorative.

**Key Characteristics:**
- Light-first, warm-cream surfaces with cool-blue counterpoint for the shipper voice.
- Asymmetric two-up audience layout — shipper and carrier never look identical.
- Pill is the dominant radius for interactive elements; rectangles with 16–24px corners for containers.
- One editorial accent, used sparingly (kicker dots, section eyebrows, step numerals, bullet ticks).
- Hover lift is small (`translateY(-1px)` to `-2px`), never a scale transform.

## 2. Colors

A two-voice palette — warm cream for the carrier side, open-sky blue for the shipper side — pinned to a near-black tinted ink and one deep teal-navy accent.

### Primary
- **Open-Sky Blue** (`oklch(91% 0.05 230)`, source token `--brand-primary` / `#bee4fa`): the shipper voice. Used to tint the shipper audience card, the kicker dot's diffused ring, the icon dots in the feature grid, and a hero ambient wash. Soft, daylit, trustworthy — never used at full strength as a fill.
- **Manifest Cream** (`oklch(93% 0.06 95)`, source token `--brand-secondary` / `#f1e3aa`): the carrier voice. Used to tint the carrier audience card, surface base (mixed with white), the kicker chip background, and the secondary hero wash. Paper-feeling, ledger-warm.

### Secondary
- **Deep Harbor** (`oklch(45% 0.09 220)`, source token `--accent`): the single editorial accent. Appears on the kicker dot, the eyebrow kickers above each section, the step numerals (`01`, `02`, `03`), and the audience-bullet check icons. Rare on purpose.

### Tertiary
- **Warm Concrete** (`oklch(76% 0.005 240)`, source token `--brand-tertiary` / `#b4b4b4`): structural neutral. Used inside `color-mix` formulas to build borders (`var(--border)`) and rule-lines. Never a fill.
- **Soft Alarm** (`oklch(78% 0.13 25)`, source token `--brand-error` / `#ff9999`): error-state hint only. Currently held in reserve for form validation. Never used decoratively.

### Neutral
- **Tinted Ink** (`oklch(18% 0.02 240)`, source token `--ink`): body text, primary button fill, commitments band background. A near-black tinted toward the brand-primary hue — never `#000`.
- **Tinted Ink 2** (`oklch(35% 0.02 240)`, source token `--ink-2`): secondary text, nav links, audience-card lead copy.
- **Tinted Ink 3** (`oklch(52% 0.02 240)`, source token `--ink-3`): tertiary text, captions, footer legal line.
- **Surface Warm** (`oklch(98% 0.012 95)`, source token `--surface`): default page background — white mixed 96% with Manifest Cream.
- **Surface Warm 2** (`oklch(96% 0.022 95)`, source token `--surface-2`): stepped surface for the "Cómo funciona" section and footer.
- **Surface Cool** (`oklch(98% 0.014 230)`, source token `--surface-cool`): white mixed with Open-Sky Blue. Used inside the shipper audience card.
- **Paper White** (`#ffffff`, source token `--brand-neutral`): used for the "¿Para quién es Truckr®?" and "Confianza" section backgrounds — a tonal step lighter than the page surface for clear sectioning without shadow.

### Named Rules

**The One Stamp Rule.** Deep Harbor is the accent's only job. It appears on the kicker dot, section eyebrows, step numerals, and bullet ticks — and nowhere else. If it ever covers more than ~5% of any screen, it has been misused; recolor to ink or a tinted neutral instead.

**The Two-Voice Rule.** Open-Sky Blue speaks for shippers; Manifest Cream speaks for carriers. Never mix them on a single component. The shipper audience card is sky-tinted; the carrier card is cream-tinted; chips and stamps for each role inherit that tint.

**The No-Pure-Neutral Rule.** No `#000`, no `#fff` in text or interactive states. Every neutral is tinted toward the brand-primary hue (chroma 0.005–0.02). `#ffffff` is used as a sectioning surface only, never as ink.

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

Flat-by-default with two deliberate softnesses: an ambient drop on the primary button, and a low ambient lift on feature-card hover. The commitments band creates depth tonally instead — Tinted Ink fill on a cream surface — not with shadow. Sectioning happens through tonal stepping (surface → paper-white → surface-2) and 1px rule-lines, never through floating cards.

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
- **Shape:** pill, `padding: 6px 12px 6px 10px`, 1px tinted border.
- **Background:** white mixed 80% with Manifest Cream.
- **Type:** Unbounded 600, 0.8125rem, uppercase, `letter-spacing: 0.06em`, Tinted Ink 2.
- **Stamp dot:** 8×8 Deep Harbor circle with a 3px softened ring (`box-shadow: 0 0 0 3px color-mix(--accent 22%, transparent)`). The system's smallest editorial moment; never recolor.

### Audience cards (signature — two-up, asymmetric)
- **Layout:** 2-up grid, `1.05fr / 0.95fr` ratio at `min-width: 900px`; stacked under that. The carrier card carries `margin-top: var(--space-7)` at md+ so the two cards never align top-to-top.
- **Shape:** `border-radius: var(--radius-lg)` (24px), `padding: clamp(28px, 3vw, 44px)`.
- **Shipper card** (`.audienceCard--shipper`): white mixed 80% with Open-Sky Blue, border tints toward Open-Sky Blue.
- **Carrier card** (`.audienceCard--carrier`): white mixed 78% with Manifest Cream, border tints toward Manifest Cream.
- **Label:** Unbounded 600 eyebrow, uppercase, 0.8125rem, Tinted Ink 2.
- **Bullets:** custom list with a 22px column for the check SVG (Deep Harbor stroke) and a 1fr text column.
- **CTA:** text-link style — no pill button inside the card. Hover increases the icon gap from 8px to 14px.

### Step list
- **Layout:** 3-up grid at md+, stacked under. Each step is its own grid with a top rule (1px, Tinted Ink 14%).
- **Numeral:** Unbounded 700, `clamp(2.4rem, 5vw, 3.6rem)`, Deep Harbor, `font-variant-numeric: tabular-nums`. The largest the accent ever appears.
- **Title:** Title scale (Unbounded 700, 1.35rem).
- **Role tag:** inline pill (`padding: 2px 8px`, pill radius), Unbounded 600 0.7rem uppercase. Shipper role uses Open-Sky Blue 70/white; carrier role uses Manifest Cream 80/white.

### Feature grid
- **Layout:** `repeat(auto-fit, minmax(260px, 1fr))`.
- **Card** (`.featureItem`): 16px radius, padding `var(--space-5)`, Surface Warm background, Warm-Concrete-tinted border.
- **Icon dot:** 40×40 pill, white mixed 55% with Open-Sky Blue, 1px border, Tinted Ink icon stroke.
- **Hover** (only when `hover: hover`): `translateY(-2px)`, Feature hover ambient shadow, border darkens toward Tinted Ink 24%.

### Commitments band
- **Layout:** full-width within container, 24px radius, `padding: clamp(24px, 3vw, 40px)`, 3-up grid of commitments under md+.
- **Surface:** Tinted Ink fill. The only dark-mode surface in the system, and it's bounded — it does not bleed past the container.
- **Lead text:** Unbounded 600, color is white mixed 70% with Manifest Cream — cream-warmed white on dark, never pure white.
- **Body text:** white mixed 78% with Warm Concrete (cool-warmed soft white).
- **Dividers:** 1px top-rule on each commitment, `color-mix(white 22%, transparent)`.

### Footer
- **Surface:** Surface Warm 2, 1px top border.
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

## 6. Do's and Don'ts

### Do:
- **Do** keep the page light-first with warm cream-tinted surfaces. The only dark surface is the bounded commitments band.
- **Do** tint every neutral toward the brand hue. Use `color-mix(in oklab, …)` against `--brand-primary` or `--brand-secondary`.
- **Do** treat Deep Harbor as a stamp — kicker dot, section eyebrow, step numeral, bullet tick. Nowhere else.
- **Do** keep the shipper voice in Open-Sky Blue and the carrier voice in Manifest Cream, always paired with role-specific copy.
- **Do** use Unbounded 700 with tight negative letterspacing (`-0.025em` to `-0.045em`) for headlines, and `text-wrap: balance` to control wrap.
- **Do** make hover a 1–2px lift and a soft shadow change. No scale, no spring, no bounce.
- **Do** respect `prefers-reduced-motion`; the global rule already collapses animations to `0.01ms`.
- **Do** use the global `:focus-visible` outline (3px Tinted-Ink-15%, 3px offset). It is the accessibility floor.

### Don't:
- **Don't** style anything to look like "Uber for trucks" tech-bro aesthetic — neon-on-black, hard sans shouting velocity, motion-blurred highway hero. This is the explicit anti-reference in PRODUCT.md.
- **Don't** ship the generic SaaS-cream landing template (pastel hero illustration, three identical icon-heading-text cards in a row, gradient-text headline). PRODUCT.md rejects this by name.
- **Don't** use logistics stock photography — forklifts, container ports, blurred trucks. Visually loud, semantically empty.
- **Don't** apply `background-clip: text` with a gradient to any headline. Solid Tinted Ink, always.
- **Don't** add a colored side-stripe (`border-left: 4px solid …`) to any card, callout, or list item. Full borders or tonal fills only.
- **Don't** put glassmorphism (heavy blur, glass card) anywhere except the topbar's earned `backdrop-filter`.
- **Don't** use `#000` or `#fff` as ink or as a focus state. Every neutral is tinted (chroma ≥ 0.005 toward 240).
- **Don't** make the audience cards identical mirrors. The asymmetric pair (size + vertical offset + tint) is the layout's point.
- **Don't** add pill radius to containers, or square radius to interactive chips. The Pill-or-Container Rule is load-bearing.
- **Don't** raise Deep Harbor's coverage on a screen above ~5%. If it spreads, recolor to Tinted Ink or a tinted neutral.
- **Don't** introduce a second display face. Unbounded is the only display family; substitutions break the "Plain-Spoken Dispatch" character.
