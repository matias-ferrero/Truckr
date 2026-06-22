#import "@preview/cmarker:0.1.8"

= Remove cotización widget from landing page

_2026-05-12 23:15 UTC — rama `main` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  Open a draft PR removing the "Pedí una cotización" widget on the landing page
  ```,
  h1-level: 4,
  label-prefix: "cc764-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now remove the orphaned CSS rules (heroGrid, panel, panelTitle, panelHint, form, field, input, help, error). Verify each is unused elsewhere first — `labelRow` stays.
  ```,
  h1-level: 4,
  label-prefix: "cc765-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now run the local quality gate.
  ```,
  h1-level: 4,
  label-prefix: "cc766-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Tests pass, coverage holds. Now lint, E2E, and Playwright check for any e2e specs that reference the widget.
  ```,
  h1-level: 4,
  label-prefix: "cc767-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Pre-existing dirty files unrelated to my change — restore them.
  ```,
  h1-level: 4,
  label-prefix: "cc768-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Lint clean for my files. Now Playwright E2E.
  ```,
  h1-level: 4,
  label-prefix: "cc769-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  E2E passes. Commit and push.
  ```,
  h1-level: 4,
  label-prefix: "cc770-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Draft PR opened: https://github.com/tcorzo/fiuba-gestion-tp/pull/170

  **Summary**
  - `frontend/src/App.tsx` — removed the `Pedí una cotización` aside, form state, validation, submit handler, nav link, and hero CTA. Hero primary CTA now points to `#para-quien`.
  - `frontend/src/styles/landing.css` — dropped orphaned `.panel`, `.panelTitle`, `.panelHint`, `.heroGrid` rules. Kept `.form`/`.field`/`.input`/`.help`/`.error`/`.labelRow` (reused by `VehicleForm`/`VehicleSelect`).
  - `frontend/src/App.test.tsx` — replaced 3 quote-widget tests with absence + hero-CTA assertions.
  - Quality gate: vitest 60/60 ✅, playwright chromium ✅, prek clean ✅.
  - Commit title uses `feat(landing)!:` (breaking) so release-please cuts a minor (no major until 1.0). PR is draft with `@me` assigned per repo convention.
  ```,
  h1-level: 4,
  label-prefix: "cc771-",
)
