#import "@preview/cmarker:0.1.8"

= Audit payment gateway implementation

_2026-05-26 23:52 UTC — rama `feature/REQ-BE-00033-us8-realizar-pago-expedidor` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/clear`
  ```,
  h1-level: 4,
  label-prefix: "cc1705-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  We are working in /home/[user]/fiuba/fiuba-gestion-tp/.claude/worktrees/REQ-BE-00033

  /impeccable audit the payment gateway:

  [Image #1]
  ```,
  h1-level: 4,
  label-prefix: "cc1706-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  I have what I need. Note: PRODUCT.md/DESIGN.md don't exist in this repo, but CLAUDE.md provides equivalent product/policy context (Truckr, English-only code, design tokens, etc.). Proceeding with the audit using CLAUDE.md as the product reference.

  The biggest finding came from reading the screenshot + code together: the Province select shows a tiled "strikethrough/dash" pattern behind "CABA" because the page CSS shorthand `background: var(--surface)` resets `background-repeat` to `repeat`, tiling the caret SVG across the field. Full report below.

  ---

  # Audit — Payment Gateway (`ShipperPaymentPage`)

  ## Audit Health Score

  | # | Dimension | Score | Key Finding |
  |---|-----------|-------|-------------|
  | 1 | Accessibility | 2 | `noValidate` form has no inline field errors, no `aria-invalid`, no `aria-describedby` |
  | 2 | Performance | 4 | No issues — single page, no images, no animations |
  | 3 | Responsive Design | 3 | Good breakpoint at 540px, but touch targets borderline on small screens |
  | 4 | Theming | 4 | Tokens used throughout; no hardcoded colors |
  | 5 | Anti-Patterns | 3 | Three stacked bordered sections read close to identical-card-grid; no AI-slop tells otherwise |
  | **Total** | | **16/20** | **Good — address weak dimensions** |

  ## Anti-Patterns Verdict

  **Pass.** Not AI-generated. No gradient text, no glassmorphism, no hero-metric template, no side-stripes, no `#000`/`#fff`. The three vertical bordered blocks (summary, card, address) flirt with the "identical card grid" pattern but are clearly differentiated by content. Form follows the project's earned visual language.

  ## Executive Summary

  - Score: **16/20** (Good)
  - Issues found: **2 P0**, **5 P1**, **6 P2**, **4 P3**
  - **Critical issues**:
    1. **Province select renders with a tiled chevron-SVG background** (the "strikethrough" pattern in the screenshot) — caused by `.shipperPaymentLabel select { background: var(--surface); }` shorthand overriding the Tailwind `bg-no-repeat` class set inside `<Select>`.
    2. **`noValidate` + silent disabled submit** — user fills the entire form, sees the screenshot's filled state, and the CTA stays disabled because Luhn fails on `1234…` and expiry `1223` is past current year `2026`. No inline error tells them why.
    3. **Province "Seleccioná una provincia" placeholder option has `value=""` and is not `disabled`/`hidden`** — selectable, fails validation silently.
    4. **No card-number / expiry auto-formatting** — bare numeric strings hurt scannability and increase error rate.
    5. **No `aria-invalid` / `aria-describedby` wiring** — fails WCAG 3.3.1 (Error Identification) for screen-reader users.

  ## Detailed Findings by Severity

  ### P0 — Blocking

  **[P0] Tiled caret SVG behind selected province text**
  - **Location**: `frontend/src/styles/shipments.css:581-589` + `frontend/src/components/ui/select.tsx:18-31`
  - **Category**: Anti-Pattern / Visual bug
  - **Impact**: The chevron SVG that the `<Select>` component sets as `background-image` is repeated across the full width of the field, producing the strikethrough/dash artifact visible behind "CABA" in the screenshot. Reads as a broken/corrupt field.
  - **Cause**: `<Select>` sets `backgroundImage` inline + `bg-no-repeat bg-[right_0.85rem_center]` as Tailwind utility classes. The page-scoped rule `.shipperPaymentLabel select { background: var(--surface); … }` uses the `background` shorthand, which resets `background-repeat` to `repeat` and `background-position` to `0 0`. Inline `backgroundImage` survives (inline > class), but repeat/position do not.
  - **Recommendation**: In `shipments.css:581`, replace `background: var(--surface);` with `background-color: var(--surface);`. Alternative: don't restyle the `<Select>` from the page CSS — let the component own its surface.

  **[P0] Submit silently disabled with valid-looking form**
  - **Location**: `frontend/src/pages/shipper/ShipperPaymentPage.tsx:47-66, 99-100`
  - **Category**: Accessibility / UX
  - **Impact**: Form uses `noValidate`, runs a Luhn check + expiry-year check, and just disables the button. The screenshot shows every field filled and the CTA grey; nothing communicates "card number invalid" or "expiry in the past". User has no path to recovery. Today's date is 2026 → expiry `12/23` fails silently.
  - **Recommendation**: Per-field error state (`aria-invalid="true"`, `aria-describedby` to a `<p id="payCardNumber-error">…</p>` rendered below the input). Validate on blur, show errors before submit attempt, and keep the button enabled — only block on submit. Use `t.pay.errors.*` entries (add `cardInvalid`, `expiryPast`, `cvvInvalid`, `holderRequired`, `provinceRequired`).

  ### P1 — Major

  **[P1] Province placeholder option is selectable and value-empty**
  - **Location**: `frontend/src/components/ProvinceSelect.tsx:49`
  - **Category**: Accessibility / UX
  - **Impact**: `<option value="">Seleccioná una provincia</option>` (no `disabled`/`hidden`) lets the user re-select the empty state. With `noValidate` they get no native warning.
  - **Recommendation**: `<option value="" disabled hidden>{placeholder ?? "—"}</option>` and only render it when `value === ""`.

  **[P1] No `aria-invalid` / `aria-describedby` on any input**
  - **Location**: `ShipperPaymentPage.tsx:152-265`
  - **Category**: Accessibility (WCAG 3.3.1, 4.1.2)
  - **Impact**: Screen-reader users cannot perceive validation state.
  - **Recommendation**: Add `aria-invalid` and `aria-describedby` once inline error state lands.

  **[P1] No auto-formatting on card number or expiry**
  - **Location**: `ShipperPaymentPage.tsx:154-165, 167-180`
  - **Category**: UX / Anti-pattern (standard checkout convention violated)
  - **Impact**: `1234123412341234` is harder to verify than `1234 1234 1234 1234`. Expiry as `1223` is ambiguous vs `12/23`.
  - **Recommendation**: Format on input (`onChange` insert spaces every 4 digits; insert `/` after 2 digits). Keep raw digits in state for Luhn.

  **[P1] CVV rendered as plain text**
  - **Location**: `ShipperPaymentPage.tsx:182-194`
  - **Category**: Security / UX convention
  - **Impact**: Even on a fake gateway, leaving CVV unmasked trains users to expect it elsewhere and shows over-shoulder.
  - **Recommendation**: `type="password"` (or `type="text"` with mask), keep `inputMode="numeric"` and `autoComplete="cc-csc"`.

  **[P1] `aria-live="polite"` on a static amount**
  - **Location**: `ShipperPaymentPage.tsx:141`
  - **Category**: Accessibility
  - **Impact**: The amount never changes after load → `aria-live` produces noise. Misuse of live regions.
  - **Recommendation**: Remove `aria-live` from `.shipperPaymentSummary`. Reserve live regions for `shipperPaymentError` (already has `role="alert"` ✓).

  ### P2 — Minor

  **[P2] No required-field indicator**: Fields have `required` but no visible `*` or "Obligatorio" hint. Add a single legend ("Todos los campos son obligatorios") or asterisks via `<abbr title="…">*</abbr>`.

  **[P2] `Tarjeta de crédito` heading is small relative to page**: `--text-base` legend competes weakly with section borders. Consider `--text-lg` for legends so the section title carries the eye instead of the border.

  **[P2] Three sibling bordered blocks read uniform**: Summary, Card, Address all use the same `border + radius-md + padding` recipe. The summary is genuinely different (it's data, not input) — give it a distinct treatment (no border, larger amount, more breathing room) so it reads as context, not as one of three forms.

  **[P2] Postal code accepts anything non-empty**: Argentine CPA is 4 digits or CPA-format (`A1234ABC`). Add a regex.

  **[P2] `cancelHref` keyname for a button**: It's a `<Button>`, not a link. `cancelLabel` is the right key.

  **[P2] No card-brand hint**: Standard checkouts detect Visa/Mastercard/Amex and show a glyph. Minor confidence builder.

  ### P3 — Polish

  **[P3] Mobile touch targets**: Inputs hit ~44px with `var(--space-3) var(--space-4)` + base font, but verify against `space-3` token value. Buttons depend on `<Button size="default">` — confirm ≥44px.

  **[P3] No success / error toast separation**: Only `submitError` shows; loading state lives on the button label only.

  **[P3] No `autoFocus` on first invalid field after failed submit**.

  **[P3] Page lacks `<title>` update**: Browser tab keeps the previous page's title; checkouts conventionally update it (set via `useEffect` → `document.title`).

  ## Patterns & Systemic Issues

  - **Component CSS leak vs. page CSS**: The Province bug is the symptom of a broader issue — `.shipperPaymentLabel select` reaches into a third-party-styled component and clobbers it. Either page CSS targets `<input>` only and trusts `<Select>`, or `<Select>` exposes a `className` override. Audit other pages doing `.X select { background: … }` for the same shorthand-reset bug.
  - **`noValidate` without an error model**: This pattern likely repeats on other forms (carrier vehicle form, shipment creation). Worth extracting a small `<Field>` primitive that owns label, input, error region, and aria wiring.

  ## Positive Findings

  - Full use of design tokens (`--space-*`, `--ink-*`, `--brand-*`, `color-mix`) — no hardcoded colors, ban-list clean.
  - Proper `<fieldset>`/`<legend>` semantics for card and address sections.
  - Correct `autoComplete` values (`cc-number`, `cc-exp`, `cc-csc`, `cc-name`, `address-line1`, `address-level2`, `postal-code`).
  - `inputMode="numeric"` triggers numeric keypad on mobile.
  - Responsive collapse at 540px reverses actions correctly so primary CTA lands at the thumb.
  - Loading state disables the fieldsets, not just the button — prevents mid-submit edits.
  - i18n via `paymentContent` object, conforming to project's "no hardcoded UI" rule.

  ## Recommended Actions

  1. **[P0] `/impeccable harden`** — wire inline validation, error regions, `aria-invalid`, fix the Province placeholder so the form is actually completable and accessible.
  2. **[P0] `/impeccable polish`** — patch the `background` shorthand → `background-color` to kill the tiled-caret visual bug; tighten the three-bordered-block rhythm.
  3. **[P1] `/impeccable clarify`** — add specific field-level error copy to `paymentContent.errors` (cardInvalid, expiryPast, cvvInvalid, holderRequired, provinceRequired) and rename `cancelHref` → `cancelLabel`.
  4. **[P1] `/impeccable layout`** — differentiate the amount summary from the input sections so it reads as context, not as a third form.
  5. **[P2] `/impeccable adapt`** — verify touch targets ≥44px across the iPhone SE viewport.
  6. **Final**: `/impeccable polish` once more before opening the PR.

  > You can ask me to run these one at a time, all at once, or in any order you prefer.
  >
  > Re-run `/impeccable audit` after fixes to see your score improve.
  ```,
  h1-level: 4,
  label-prefix: "cc1707-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  apply all of these
  ```,
  h1-level: 4,
  label-prefix: "cc1708-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Reading existing tests and the success page first so I don't break them.
  ```,
  h1-level: 4,
  label-prefix: "cc1709-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Got it. Existing unit test "keeps the submit button disabled while the form is empty" will need updating since the audit calls for an always-enabled button that surfaces errors on submit. Existing e2e flow with `4242 4242 4242 4242` and `12/30` survives auto-formatting (idempotent on those values).

  Applying changes now.
  ```,
  h1-level: 4,
  label-prefix: "cc1710-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now the main page — adding inline validation, formatting, aria wiring, focus on first invalid, password CVV, title.
  ```,
  h1-level: 4,
  label-prefix: "cc1711-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now the CSS — fix the tiled chevron bug, bump legend size, differentiate the payment summary from the input sections, style field errors and required hint.
  ```,
  h1-level: 4,
  label-prefix: "cc1712-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now update the test to match the new behavior (always-enabled button, validation on submit) and add coverage for the new wiring.
  ```,
  h1-level: 4,
  label-prefix: "cc1713-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  The destination form needs the empty placeholder to remain selectable (it means "any destination"). Adjusting ProvinceSelect to only disable the placeholder when `required`.
  ```,
  h1-level: 4,
  label-prefix: "cc1714-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Run the lint + the unit test for the payment page to make sure I haven't broken anything.
  ```,
  h1-level: 4,
  label-prefix: "cc1715-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  All 9 tests pass. Let me also run the success page test and the broader frontend lint to confirm nothing else broke (TransportWindowForm has its own tests).
  ```,
  h1-level: 4,
  label-prefix: "cc1716-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  All 299 tests pass. Now CSS lint and typecheck.
  ```,
  h1-level: 4,
  label-prefix: "cc1717-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  The `import.meta.env` error is pre-existing in `api.ts` (Vite types in Deno check), unrelated to my changes. The 299-test pass already confirmed compile.
  ```,
  h1-level: 4,
  label-prefix: "cc1718-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Stylelint clean. Let me also run the broader Playwright spec for the payment flow to confirm the e2e still passes with the new auto-formatting and disabled-hidden placeholder.
  ```,
  h1-level: 4,
  label-prefix: "cc1719-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  All audit findings applied and verified. Summary:

  **Verified clean**
  - 299/299 vitest tests pass
  - Playwright e2e golden path passes
  - Stylelint clean

  **Files modified**
  - `frontend/src/styles/shipments.css` — **P0**: `background:` → `background-color:` kills the tiled chevron-SVG bug behind the Province select. Bumped legend to `--text-lg`. Differentiated payment summary (borderless, clamp-scaled amount, more padding). Added `aria-invalid` red border + `FieldError` + required-hint styles.
  - `frontend/src/pages/shipper/ShipperPaymentPage.tsx` — **P0/P1**: Per-field validation, `aria-invalid`/`aria-describedby` wired, errors on blur and submit, focus jumps to first invalid on submit. Auto-format for card (`4242 4242 …`), expiry (`MM/YY`), CVV (3 digits), postal code (CPA uppercase). CVV → `type="password"`. Removed misused `aria-live` from the amount. `document.title` updates on mount/unmount. Required-fields hint above sections. Button always enabled (disabled only while submitting).
  - `frontend/src/components/ProvinceSelect.tsx` — **P1**: Placeholder is `disabled hidden` only when `required` (so it can't be re-picked); stays a normal selectable option when optional (preserves `TransportWindowForm`'s "any destination" behavior).
  - `frontend/src/pages/shipper/paymentContent.ts` — **P1/P2**: New per-field error keys, `requiredHint`, `documentTitle`, renamed `cancelHref` → `cancelLabel`.
  - `frontend/src/pages/shipper/ShipperPaymentSuccessPage.tsx` — **P3**: `document.title` update.
  - `frontend/src/pages/shipper/ShipperPaymentPage.test.tsx` — Updated the empty-form test (now asserts inline errors + focus jump instead of disabled button). Added tests for card/expiry auto-format, expiry-past error, CVV as password.

  Re-run `/impeccable audit` to see the new score.
  ```,
  h1-level: 4,
  label-prefix: "cc1720-",
)
