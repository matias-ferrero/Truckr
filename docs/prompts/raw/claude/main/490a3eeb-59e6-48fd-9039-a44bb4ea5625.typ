#import "@preview/cmarker:0.1.8"

= Resolve singleton conflict in Google Maps loader

_2026-05-26 01:23 UTC — rama `chore/just-review-worktree` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/clear`
  ```,
  h1-level: 4,
  label-prefix: "cc681-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  @/tmp/handoff-gmaps-loader-singleton-conflict.md
  ```,
  h1-level: 4,
  label-prefix: "cc682-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Confirmed: three callsites construct separate Loaders with different `libraries`. Tests mock the package directly, so a shared module that wraps `Loader` won't break them. Going with the small-diff fix: shared loader module with union libraries.
  ```,
  h1-level: 4,
  label-prefix: "cc683-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Tests mock the package, so the shared module passes through transparently — each `.load()` call re-evaluates the mock state. Running gate.
  ```,
  h1-level: 4,
  label-prefix: "cc684-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  All 91 tests pass. But the handoff flags that unit tests can't catch the singleton bug (each file mocks in isolation). Adding a regression test on the shared module that pins the contract — single instance + union libraries.
  ```,
  h1-level: 4,
  label-prefix: "cc685-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  ## Fix landed locally on `feature/gmaps-fulfilment`

  **Diff (4 files, ~+30/-6):**
  - `frontend/src/lib/gmaps.ts` (new) — shared `getGoogleMapsLoader(apiKey)` returns memoized Loader with union `libraries: ["places", "maps"]`, version `"weekly"`.
  - `frontend/src/components/AddressPicker/index.tsx:77` — now `getGoogleMapsLoader(apiKey)`.
  - `frontend/src/components/PickupRadiusControl/index.tsx:82` — now `getGoogleMapsLoader(apiKey)`.
  - `frontend/src/features/cargo/CargoMapPreview.tsx:40` — now `getGoogleMapsLoader(apiKey)`.
  - `frontend/src/lib/gmaps.test.ts` (new) — pins the contract: single Loader instance + union libraries. Catches future regressions that unit-file mocks would miss.

  **Local gate:**
  - stylelint clean.
  - vitest: 91 existing + 2 new — all pass.

  **Not yet done** (need your call):
  - Manual dev-server verification per handoff "Repro" steps — only real way to confirm the singleton fix in the browser. Want me to boot `deno task dev` and walk through it?
  - Commit + push. PR #264 is open; the fix needs its own commit before merge. Suggested subject: `fix(frontend): share gmaps Loader across map components`. OK to commit and push?
  ```,
  h1-level: 4,
  label-prefix: "cc686-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  push it
  ```,
  h1-level: 4,
  label-prefix: "cc687-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Pushed `8b66a95` → `feature/gmaps-fulfilment` (PR #264). Pre-commit hooks clean.

  **Still pending:** manual dev-server verification — boot `deno task dev` in the worktree and walk the publish-transport-window form to confirm both controls now mount? Or leave that to you.
  ```,
  h1-level: 4,
  label-prefix: "cc688-",
)
