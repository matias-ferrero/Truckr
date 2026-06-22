#import "@preview/cmarker:0.1.8"

= Resolve loader conflict in frontend build

_2026-05-25 23:20 UTC — rama `docs/sprint-3-plan` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/clear`
  ```,
  h1-level: 4,
  label-prefix: "cc2239-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  @/tmp/handoff-REQ-FE-00027-loader-conflict.md
  ```,
  h1-level: 4,
  label-prefix: "cc2240-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now write the regression test that mounts both components together with a singleton-aware Loader mock that counts instantiations.
  ```,
  h1-level: 4,
  label-prefix: "cc2241-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now run the test suite to verify nothing regressed.
  ```,
  h1-level: 4,
  label-prefix: "cc2242-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  39/40 files pass. The 1 failure is in `SessionWidget.test.tsx` — unrelated to my changes (test isolation issue between authenticated/anonymous state). Let me confirm by running it in isolation, and verify my changes pass.
  ```,
  h1-level: 4,
  label-prefix: "cc2243-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Confirmed pre-existing: SessionWidget flake exists without my changes too. Now run full suite with my changes restored.
  ```,
  h1-level: 4,
  label-prefix: "cc2244-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Waiting for the coverage run to complete.
  ```,
  h1-level: 4,
  label-prefix: "cc2245-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  I'm hitting a Google Maps JavaScript API error: ApiNotActivatedMapError
  What API restriction am I missing?
  ```,
  h1-level: 4,
  label-prefix: "cc2246-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  `ApiNotActivatedMapError` = the API isn't enabled on the Cloud project that owns the key.

  Your code uses two APIs — enable both in Google Cloud Console → APIs & Services → Library:

  1. **Maps JavaScript API** — for `Map`, `Circle`, `importLibrary("maps")`.
  2. **Places API (New)** — for `AutocompleteSuggestion.fetchAutocompleteSuggestions`. The legacy "Places API" does NOT cover the new endpoint your `AddressPicker` migrated to (commit 64f620b). Both must be on; enabling only the legacy one is the most common trip-up here.

  Then on the key itself (APIs & Services → Credentials → your key):
  - **API restrictions:** if set to "Restrict key", the allowlist must include *Maps JavaScript API* and *Places API (New)*.
  - **Application restrictions:** if HTTP referrers, add `http://localhost:5173/*` (and your prod origin).

  Hard-reload after enabling — the SDK caches the failed bootstrap until the page reloads.

  Side note from the handoff: that key has been pasted into prior conversation history. Rotate it (Credentials → ⋮ → Regenerate key) once Maps is working, and update `VITE_GOOGLE_MAPS_API_KEY`.
  ```,
  h1-level: 4,
  label-prefix: "cc2247-",
)
