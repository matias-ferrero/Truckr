# Design System — Truckr®

Generated from the live codebase. Run `/impeccable document` to refresh after major visual changes.

---

## Color

### Strategy: Committed two-voice palette

Truckr uses a **Committed** color strategy — not a single timid accent, but two complementary brand colors that each carry 30–50% surface coverage depending on the active role. Neither pure black nor pure white appears on large surfaces; every neutral is tinted.

### Brand tokens (source of truth: `global.css`)

| Token | Value | Role |
|---|---|---|
| `--brand-primary` | `#46aadc` | Open-Sky Blue — **Carrier** dominant voice |
| `--brand-secondary` | `#e1be5a` | Honey Saffron — **Shipper** dominant voice |
| `--brand-success` | `oklch(72% 0.13 150)` | Semantic success (green) |
| `--brand-warning` | `oklch(78% 0.13 80)` | Semantic warning (amber) |
| `--brand-error` | `#e26464` | Signal Coral — error states |
| `--brand-tertiary` | `#9ca0a8` | Cool Concrete — structural neutral |
| `--ink` | `oklch(18% 0.02 240)` | Primary text (never pure black) |
| `--ink-2` | `color-mix(in oklab, var(--ink) 78%, white)` | Secondary text |
| `--ink-3` | `color-mix(in oklab, var(--ink) 58%, white)` | Tertiary/disabled text — use sparingly, always check contrast |

### Two-voice system

Every authenticated screen belongs to one of two roles. The role determines which brand color is **dominant** (large surfaces, structural borders, dt labels) and which is the **detail** (small accents — connector lines, count badges, dividers, hover cues). Consistent application across every surface is mandatory.

| Surface / element | Carrier (sky dominant) | Shipper (saffron dominant) |
|---|---|---|
| Page background | `brand-primary 5%` + `--surface` | `brand-secondary 7%` + `--surface` |
| Primary action button | sky (via `--color-brand-warm` override) | saffron (Tailwind default) |
| Detail body card background | `--surface-cool` (12% sky) | `--surface` (4% cream) |
| Detail body card border | `--border-sky` | `--border-cream` |
| `dt` field label color | `--chip-ink-primary` (dark sky, oklch 36% 0.14 235) | `--chip-ink-warning` (dark saffron, oklch 36% 0.14 80) |
| Back link resting | `38% brand-primary` → `--ink-2` (sky tint) | `32% brand-secondary` → `--ink-2` (saffron tint) |
| Back link hover | `--chip-ink-primary` (dark sky) | `--chip-ink-warning` (dark saffron) |
| Contact section divider | `brand-secondary 32%` (saffron — detail voice) | `brand-primary 28%` (sky — detail voice, default) |
| Timeline connector | `brand-secondary 55%` → fade (saffron — detail) | `brand-primary 55%` → fade (sky — detail, default) |
| Timeline count badge | saffron tint + `--chip-ink-warning` (detail) | sky tint + `--ink-on-sky` (detail, default) |
| Action zone background | `brand-primary 7%` + `--surface` | `brand-secondary 8%` + `--surface` |
| Action zone border | `brand-primary 22%` | `brand-secondary 22%` |
| Timeline dot colors | **Semantic** — independent of role voice (see below) | same |

**Why dominant + detail, not dominant-only?**
Structural/interactive elements (page bg, card, dt labels, back link, buttons, action zone) use the **dominant voice** so each page has a clear color identity. Small accents (connector line, count badge, contact divider) use the **detail/opposite voice** so they stay visible against the dominant-colored surface — a sky connector on a sky card would be invisible.

**Button voicing mechanism:**
The `Button` component uses the Tailwind token `--color-brand-warm` (saffron by default). On carrier pages, `.shipmentDetailPage--carrier` overrides this custom property to `var(--brand-primary)` (sky). This cascades to all `Button` instances in the subtree with zero component changes.

**Rule:** structural elements = dominant voice. Accent decorations = detail voice. Only one dominant per page.

**The default selector = shipper values.** Carrier always needs an explicit override. This means: if you add a new element and only write the default CSS (no override), it will look correct on shipper pages. Add the `.shipmentDetailPage--carrier` override afterward.

### Semantic colors (role-independent)

Timeline dots and state chips use semantic colors regardless of role. These must not be swapped to match voice:

| State | Color token | Usage |
|---|---|---|
| `shipment_accepted` | `--accent` (`oklch(45% 0.09 220)`) | Timeline dot |
| `shipment_in_transit` | `--brand-primary` | Timeline dot |
| `shipment_delivered` | `--brand-success` | Timeline dot |
| `shipment_cancelled` | `--brand-error` | Timeline dot |
| `payment_escrowed` | `--brand-success` | Timeline dot |
| `payment_failed` | `--brand-error` | Timeline dot |
| Chip: accepted | `18% brand-primary` bg + `--chip-ink-primary` | `.shipmentStateChip--accepted` |
| Chip: in_transit | `22% brand-warning` bg + `--chip-ink-warning` | `.shipmentStateChip--in_transit` |
| Chip: delivered | `22% brand-success` bg + `--chip-ink-success` | `.shipmentStateChip--delivered` |
| Chip: cancelled | `15% brand-error` bg + `--chip-ink-error` | `.shipmentStateChip--cancelled` |

### Chip foreground inks

| Token | Value | Paired with |
|---|---|---|
| `--chip-ink-primary` | `oklch(36% 0.14 235)` | sky / blue surfaces |
| `--chip-ink-warning` | `oklch(36% 0.14 80)` | amber / saffron surfaces |
| `--chip-ink-success` | `oklch(36% 0.13 150)` | green surfaces |
| `--chip-ink-error` | `oklch(36% 0.16 25)` | red / coral surfaces |
| `--ink-on-sky` | `oklch(20% 0.04 230)` | sky count badge background |

### Absolute bans

- No raw `#000`, `#fff`, `white`, `black` on surfaces or text — use OKLCH or color-mix.
- No `rgb()` / `rgba()` — use `oklch()` or `color-mix(in oklab, ...)`.
- No `border-left` or `border-right` > 1px as a colored accent stripe — use full borders, surface tints, or leading glyphs instead.
- No `background-clip: text` gradient text.

---

## Typography

### Fonts

| Role | Family | Loaded from |
|---|---|---|
| Display / labels | `Unbounded` | Google Fonts via `index.html` |
| Body / reading | `Alegreya Sans` | Google Fonts via `index.html` |

**Display (Unbounded)** is used for: page titles, section headings, field labels (`dt`), chip text, count badges, numeric amounts, banners. Its geometric character reads at very small sizes when tracked open, and commands attention at large display sizes.

**Body (Alegreya Sans)** is used for: `dd` field values, timeline event labels, paragraph copy, back links. Its humanist letterforms are comfortable for reading data.

**Never** use Alegreya Sans for labels or Unbounded for long-form reading.

### Type scale (fixed rem — product UI)

| Token / class | Size | Weight | Tracking | Usage |
|---|---|---|---|---|
| `.shipmentDetailTitle` | `2rem` (mobile: `1.5rem`) | 700 | `-0.035em` | Page h1 |
| `.shipmentTimelineTitle` | `1.0625rem` | 700 | `-0.02em` | Section h2 (timeline) |
| `.shipmentDetailContactTitle` | `0.9375rem` | 700 | `-0.01em` | Section h2 (contact) |
| `.shipmentDetailNextStep` | `0.9375rem` | 700 | `-0.01em` | Banner CTA |
| `dd`, `.trackingTimelineKind` | `1rem` / `0.9375rem` | 500 | default | Field values, timeline labels |
| `dt` labels | `0.8125rem` | 600 | `+0.08em` + uppercase | Field labels |
| `.shipmentTimelineCount` | `0.75rem` | 700 | `+0.02em` | Count pill |
| `.trackingTimelineTime` | `0.75rem` | 400 | default + tabular-nums | Timestamp pill |
| `.shipmentDetailBack` | `0.875rem` | 500 | default | Back navigation |

**Section heading hierarchy rule:** h2 elements (timeline title, contact title) must be visually distinct from `dt` field labels. dt labels use uppercase + wide tracking; h2s use sentence case + tight tracking. Do not make h2s match dt styling.

### Special treatments

- **Amount** (`.shipmentDetailAmount`): `1.5rem`, 700, `-0.03em`, colored with `75% brand-secondary` + ink — always Unbounded, always amber-tinted regardless of role (monetary weight belongs to the saffron voice).
- **Latest timeline event** (`.trackingTimelineItem[data-latest]`): `1rem`, 700, `--ink` — promoted weight signals recency.
- All numbers in timestamp pills use `font-variant-numeric: tabular-nums` for column alignment.

---

## Spacing

4pt base grid via `--space-N` tokens (`4px, 8px, 12px, 16px, 24px, 32px, 48px, 64px, 96px`). Use tokens exclusively — no arbitrary pixel values.

---

## Elevation & borders

| Token | Value | Usage |
|---|---|---|
| `--shadow-sm` | `0 1px 0.5px` ink-tinted shadow | Subtle separation |
| `--shadow-md` | `0 10px 30px` ink-tinted shadow | Cards, modals |
| `--border-2` | `14% ink transparent-mix` | Default card borders |
| `--border-sky` | `78% brand-primary` + `--border` | Carrier card borders |
| `--border-cream` | `82% brand-secondary` + `--border` | Shipper card borders |

Shadows are tinted toward `oklch(10% 0.02 240)` (cool ink hue) so they don't punch into warm cream surfaces.

---

## Radius

| Token | Value | Usage |
|---|---|---|
| `--radius-sm` | `10px` | Chips, inputs, skeleton bones |
| `--radius-md` | `16px` | Banners, panels, timeline items |
| `--radius-lg` | `24px` | Body card, action section |

---

## Motion

| Token | Value | Usage |
|---|---|---|
| `--ease-out` | `cubic-bezier(0.16, 1, 0.3, 1)` | All exits and reveals |
| `--ease-in` | `cubic-bezier(0.7, 0, 0.84, 0)` | Entry animations (sparingly) |

- Page enter: `translateY(8px)` → none, 280ms ease-out
- Banner enter: `translateY(-6px)` → none, 240ms ease-out
- Timeline items: `translateX(-6px)` → none, 240ms ease-out, staggered by `60ms × index` (capped at 360ms)
- All animations respect `prefers-reduced-motion: reduce`.

---

## Components

### ShipmentDetailBody card

Structural container for field data. Role-voiced background and border. No shadow — separation comes from the border and the page background contrast.

```
carrier: background = --surface-cool, border = --border-sky
shipper: background = --surface,      border = --border-cream
```

### dt / dd field grid

`display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr))`. Labels (`dt`) use Unbounded uppercase small caps with the dominant voice color at readable contrast against `--ink-2`. Values (`dd`) use Alegreya Sans at 1rem/500.

The `dt` contrast floor is `--ink-2` (78% ink) — never `--ink-3` (58% ink), which fails WCAG AA for small caps at 0.8125rem.

### Timeline connector

The vertical `::before` line uses the **detail voice** (opposite of dominant) to stay visible against the dominant-colored card surface. Same gradient bottom-fade in both voices.

### Count badge

Pill chip adjacent to the timeline section heading. Uses the **detail voice** (opposite of dominant) — same reason as the connector.

### Action zone (ShipmentActions)

Sticky on mobile (docks to viewport bottom, radiused only on top corners). Uses the **dominant voice** at 7–8% coverage. Border uses dominant voice at 22%.

### Confirm dialog

Rendered as a native `<dialog>` (`.confirmDialog`). Invoked only for destructive or financially significant actions (`pay`, `start_transit`, `deliver`, `cancel`). Not role-voiced — neutral surface.

---

## How to extend: adding a new role-specific element

1. Decide if the element is **structural** (uses dominant voice) or **accent/detail** (uses the opposite/detail voice).
2. Write the default selector using the **shipper** values (sky = detail = default).
3. Add a `.shipmentDetailPage--carrier` override with the carrier-specific values.
4. Document the element in the table under "Two-voice system" above.
5. Run `just frontend-lint-css` to verify no banned patterns.
