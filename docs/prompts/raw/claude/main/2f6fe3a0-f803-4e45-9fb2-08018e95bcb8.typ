#import "@preview/cmarker:0.1.8"

= Migrate Google Places API integration

_2026-05-25 20:43 UTC — rama `feature/REQ-FE-00025-us48-address-picker` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/clear`
  ```,
  h1-level: 4,
  label-prefix: "cc424-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  @/tmp/handoff-REQ-FE-00025-google-places-migration.md
  ```,
  h1-level: 4,
  label-prefix: "cc425-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Handoff read. Two viable paths — need your call before coding.
  ```,
  h1-level: 4,
  label-prefix: "cc426-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Path B. No code changes from me. Action items:

  **You / @FernandoYu:**
  1. GCP Console → project that owns the `VITE_GOOGLE_MAPS_API_KEY` → **APIs & Services → Library** → enable **Places API** (the legacy one, NOT "Places API (New)"). Maps JavaScript API must also be enabled (likely already is).
  2. Confirm the key's API restrictions (if any) include **Places API** alongside Maps JavaScript API.
  3. Hard-refresh `/transportista`... wait — frontend route should be English per CLAUDE.md. Anyway: reload the form, type into AddressPicker, confirm predictions return + no `ApiNotActivatedMapError`.

  **Follow-up issue (Path A):** want me to draft it now so it's queued before you forget? It'd cover the `PlaceAutocompleteElement` migration with a hard deadline note (Google's 12-month deprecation clock from 2025-03-01 → ~2026-03 hard cutoff already passed; we're on borrowed time).
  ```,
  h1-level: 4,
  label-prefix: "cc427-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  @/tmp/handoff-REQ-FE-00025-google-places-migration.md
  ```,
  h1-level: 4,
  label-prefix: "cc428-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Handoff loaded. Picker blocked because the GCP key targets the *legacy* `google.maps.places.Autocomplete`, which Google blocks for new projects since 2025-03-01. PR #256 open; 265/265 tests still pass.

  Two viable paths (plus an out-of-scope C):
  ```,
  h1-level: 4,
  label-prefix: "cc429-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Path A. Starting by reading the current implementation and verifying lib state.
  ```,
  h1-level: 4,
  label-prefix: "cc430-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Migration shipped. Pushed `64f620b` to PR #256.

  **Actions:**
  - Rewrote `AddressPicker/index.tsx` around `AutocompleteSuggestion.fetchAutocompleteSuggestions` + `Place.fetchFields(['formattedAddress','location'])`. Custom combobox/listbox (WAI-ARIA: `role=combobox` + `aria-activedescendant`, keyboard nav, escape to close). Public props identical — `TransportWindowForm.tsx` untouched.
  - Swapped `@react-google-maps/api@2.20.3` → `@googlemaps/js-api-loader@1.16.10` in `frontend/deno.json`.
  - Rewrote the test mock for `@googlemaps/js-api-loader` + global `google.maps.places`. 13 prior specs preserved + 1 new keyboard-selection spec → **14/14 pass**, full suite **266/266 pass**.
  - Coverage: AddressPicker **96.82%** lines / **85%** functions; overall **94.92 / 87.46 / 83.85 / 94.92** — clears 80% gate.
  - `prek` clean. Playwright: 3 passed, 8 skipped (address-picker e2e was already skipped behind the auth-fixture, unchanged).

  **Verify next:** open `/carrier/availability/new` in the browser with the real key — typing should now stream suggestions from the new endpoint without `ApiNotActivatedMapError`.
  ```,
  h1-level: 4,
  label-prefix: "cc431-",
)

== Intercambio 4

=== Prompt

#cmarker.render(
  ```
  [Image #1]

  {
      "2": {
          "id": 4,
          "vehicle_id": 1,
          "origin_province": "Buenos Aires",
          "origin_locality": "Comuna 11, Condarco 1688, C1416AQL Cdad. Autónoma de Buenos Aires, Argentina",
          "origin_lat": "-34.61329",
          "origin_lng": "-58.476398",
          "destination_province": null,
          "destination_locality": null,
          "destination_lat": null,
          "destination_lng": null,
          "price_per_km": "4500.0",
          "max_km": 200,
          "available_from": "2027-06-25T00:00:00.000Z",
          "available_to": "2028-05-30T23:59:00.000Z",
          "active": true,
          "status": "open",
          "created_at": "2026-05-25T21:15:31.642Z",
          "updated_at": "2026-05-25T21:15:31.642Z",
          "cargo_offers_count": 0,
          "vehicle": {
              "id": 1,
              "make": "Mercedes-Benz",
              "model": "Sprinter",
              "plate": "AA001XX",
              "vehicle_type": "truck_small"
          }
      }
  }

  When using a real address the text on the TW index is way to wide
  ```,
  h1-level: 4,
  label-prefix: "cc432-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Inspecting the index card layout.
  ```,
  h1-level: 4,
  label-prefix: "cc433-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Root cause: grid item `min-width` defaults to `min-content`, so the long unbreakable string blows the `1fr` track wider than its share. CSS one-liner fixes it.
  ```,
  h1-level: 4,
  label-prefix: "cc434-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Fixed. `514a86c` pushed.

  The header bar `<h2 class="windowRoute">` already had `overflow: hidden; text-overflow: ellipsis; white-space: nowrap`, but the `.windowCard` grid item's default `min-width: auto` (= min-content) was letting the long Google address widen the `1fr` track past its share. Added `min-width: 0` to `.windowCard`, `.windowCardHeader`, `.windowCardBody` — the title now ellipses at the card edge (full address visible via the `title=` tooltip on hover). 24/24 list tests pass.
  ```,
  h1-level: 4,
  label-prefix: "cc435-",
)
