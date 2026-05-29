---
tag: REQ-BE-00039
title: 'feat(matching): migrate to address-driven matching, drop province matchers, add dropoff radius'
priority: P1
status: ready
created: '2026-05-26'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/267
author: Claude Code
github_issue: 267
github_repo: tcorzo/fiuba-gestion-tp
labels:
- REQ
- BE
- FE
- fulfilment
- matching
- mvp
- us52
- gmaps
assignee: tcorzo
plan: docs/features/REQ/REQ-BE-00039/REQ-BE-00039-address-driven-matching.plan.md
---

## Goal

Retire the legacy `(province, locality)` narrowing on `transport_windows` and `cargos`, restructure the matcher around the pins already captured by US48 / US49 / US50, and add `dropoff_radius_km` symmetric to `pickup_radius_km` so the Carrier has a real "open destination ↔ bounded destination" axis instead of the fake one that the province strings provided.

Closes the design captured in ADR-014 (`docs/01-technical-vision/technical-vision.md`) and umbrella US52 (`docs/artifacts/backlog-us.typ`). Companion artifacts: glossary deltas (`docs/05-appendices/glossary.md` — Destino abierto, Ventana de transporte, Carga, new Radio de entrega), plan file at `docs/features/REQ/REQ-BE-00039/REQ-BE-00039-address-driven-matching.plan.md`.

## Backlog reference

US52 in `docs/artifacts/backlog-us.typ` — "Migrar a Matching Dirigido por Dirección". Bundles every cross-cutting concern (schema delta, BE matcher rewrite, FE form changes, endpoint deletion, destructive migration). Supersedes the province-driven phrasing the legacy schema implied for US3 / US5 / US9 / US27 / US50.

## Scope

### Schema (destructive, one Rails migration)

- **`transport_windows`**: drop `origin_province`, `origin_province_normalized`, `origin_locality`, `origin_locality_normalized`, `destination_province`, `destination_province_normalized`, `destination_locality`, `destination_locality_normalized` (plus their four `_normalized` indexes). Add `origin_address :text, null: false`, `destination_address :text` (nullable), parsed `origin_locality :text, null: false`, `origin_admin_area :text, null: false`, `destination_locality :text` (nullable), `destination_admin_area :text` (nullable), `dropoff_radius_km :integer` (nullable, range 1–200, NULL iff destination is open).
- **`cargos`**: drop `pickup_zone`, `pickup_zone_normalized`, `delivery_zone`, `delivery_zone_normalized` (plus the two `_normalized` indexes). Add parsed `pickup_locality :text, null: false`, `pickup_admin_area :text, null: false`, `delivery_locality :text, null: false`, `delivery_admin_area :text, null: false`.
- **Truncate** the chain `tracking_events → payments → routes → shipments → cargo_offers → cargos / transport_windows` inside the migration's `up`. `down` raises `IrreversibleMigration`.
- New model invariant on `TransportWindow`: `destination_lat / destination_lng / destination_address / destination_locality / destination_admin_area / dropoff_radius_km` are either all present or all `NULL` (custom `validate :open_destination_consistency`). Not a DB constraint — Ruby-side.

### Backend

- Rewrite `Cargo#matching_windows`: (1) new `TransportWindow.within_bbox_of(lat, lng, PICKUP_RADIUS_KM_MAX)` SQL prefilter, with longitude span widened by `1 / cos(lat_radians)`; (2) existing `.within_pickup_radius_of(cargo)` from US50 (kept as-is); (3) new `.within_dropoff_radius_of(cargo)` that lets through any row with `destination_lat IS NULL` and otherwise applies Haversine against `dropoff_radius_km`. Sort key stays pickup distance only.
- Add `Truckr::Geo.bbox_for(lat, lng, radius_km)` returning `[min_lat, max_lat, min_lng, max_lng]`. Reuse the existing `Truckr::Geo.haversine_km` for the radius check.
- Drop the `_normalized` Ransack matchers (`origin_province_normalized_cont`, `destination_province_normalized_cont`, sibling locality matchers) from `Cargo` and `TransportWindow.ransackable_attributes`. Drop the `I18n.transliterate` `before_validation` callback on `TransportWindow`.
- **Delete** the public marketplace route `GET /api/transport_windows` (config/routes.rb) and the entire `Api::TransportWindowsController`. Carrier self-service (`GET /api/carriers/me/transport_windows`) and AA admin paths stay. Browse runs through `GET /api/cargos/:id/matches` exclusively.
- Update `TransportWindowResource` / `CargoResource` (or their JBuilder equivalents) to drop the removed columns and emit the new ones (addresses, parsed `_locality` / `_admin_area`, `dropoff_radius_km`).
- Rewrite ActiveAdmin filter sets in `backend/app/admin/transport_windows.rb` and `backend/app/admin/cargos.rb` to reference the new columns. Old filters on `_normalized` columns must go.

### Frontend

- New helper `frontend/src/lib/places.ts`: from a `google.maps.places.PlaceResult`, returns `{ address, lat, lng, locality, admin_area }`. Cascade for `locality`: `locality → sublocality_level_1 → administrative_area_level_2 → formatted_address.split(",")[0]`. `admin_area` always from `administrative_area_level_1`.
- Refactor `frontend/src/components/PickupRadiusControl.tsx` into a generic `RadiusControl` with a `role: "pickup" | "dropoff"` prop parameterising the circle stroke, the i18n key, and the form-field name.
- `frontend/src/pages/carrier/TransportWindowForm.tsx`: mount `RadiusControl` twice (pickup + dropoff). Dropoff is conditionally rendered iff a destination pin exists; clearing the destination address auto-clears the dropoff radius.
- `frontend/src/features/cargo/CargoForm.tsx`: drop any vestigial province / locality input; pipe the four parsed `_locality` / `_admin_area` through the form state into the POST payload.
- Match-card label rendering on `GET /api/cargos/:id/matches`: `"Locality, AdminArea → Locality, AdminArea"` when destination is set, or `"Locality, AdminArea → {t('transport_window.open_destination')}"` when `destination_lat == null`. All copy via i18n keys per `CLAUDE.md` § "Language policy".

### Docs

- ADR-014 lives at `docs/01-technical-vision/technical-vision.md`. Glossary deltas at `docs/05-appendices/glossary.md` (Destino abierto, Ventana de transporte, Carga, new Radio de entrega). Umbrella US52 in `docs/artifacts/backlog-us.typ`. Plan file at `docs/features/REQ/REQ-BE-00039/REQ-BE-00039-address-driven-matching.plan.md`. All in place ahead of this implementation issue.

## Out of scope

- **`Carrier.province` / `Carrier.base_city`** stay on the `carriers` table. The carrier-signup `ProvinceSelect.tsx` component survives untouched — only the publish-Window / publish-Cargo forms drop province inputs. Province is profile metadata for the public Carrier detail page, never a matching input.
- **`delivery_radius_km` on `cargos`** (Shipper-side dropoff slop). Considered and rejected during design grilling — the radius semantics belong to the side doing the deviating (Carrier).
- **Forward-migration of pre-existing province strings into pseudo-coordinates.** Migration is destructive; demo data is re-seeded after.

## Acceptance Criteria

- [ ] **AC1** — Single Rails migration drops the eight `transport_windows` legacy columns + four legacy indexes, drops the four `cargos` legacy columns + two legacy indexes, adds the listed new columns, and truncates the chain `tracking_events → payments → routes → shipments → cargo_offers → cargos / transport_windows`. `db:migrate` runs clean; `down` raises `IrreversibleMigration`.
- [ ] **AC2** — `TransportWindow` validates `open_destination_consistency`: the six destination-side fields (`destination_lat`, `destination_lng`, `destination_address`, `destination_locality`, `destination_admin_area`, `dropoff_radius_km`) are all-present-or-all-NULL. Symbolic error key `:open_destination_partial` resolved via locale files.
- [ ] **AC3** — `TransportWindow` validates `dropoff_radius_km` numericality 1–200 (constants `PICKUP_RADIUS_KM_MIN` / `PICKUP_RADIUS_KM_MAX` reused from US50) when present.
- [ ] **AC4** — `Truckr::Geo.bbox_for(lat, lng, radius_km)` exists as a pure function returning a 4-tuple, with the longitude span correctly scaled by `1 / cos(lat_radians)`. Tabular spec covers low-latitude and high-latitude rectangles inside Argentina (CABA, Bariloche).
- [ ] **AC5** — `TransportWindow.within_bbox_of(lat, lng, radius_km)` emits a SQL `WHERE` clause directly on `origin_lat` / `origin_lng` (no province strings).
- [ ] **AC6** — `TransportWindow.within_dropoff_radius_of(cargo)` exists; lets through any row with `destination_lat IS NULL` and otherwise applies Haversine against `dropoff_radius_km`.
- [ ] **AC7** — `Cargo#matching_windows` composes: bbox prefilter → pickup-radius Haversine → dropoff-radius Haversine → sort by pickup distance. No province strings consulted at any layer.
- [ ] **AC8** — `GET /api/transport_windows` is removed from `config/routes.rb` and `Api::TransportWindowsController` no longer exists. A request spec asserts `GET /api/transport_windows` returns 404.
- [ ] **AC9** — `GET /api/cargos/:id/matches` payload includes `origin_address`, `destination_address`, the four parsed `_locality` / `_admin_area`, `pickup_radius_km`, and `dropoff_radius_km`. Open-destination rows carry `destination_lat == null` on the wire.
- [ ] **AC10** — ActiveAdmin TransportWindow / Cargo filter sets reference the new columns only. Loading the AA index page after migration produces no 500.
- [ ] **AC11** — New helper `frontend/src/lib/places.ts` extracts `_locality` via the cascade `locality → sublocality_level_1 → administrative_area_level_2 → formatted_address.split(",")[0]` and `_admin_area` from `administrative_area_level_1`. Vitest spec covers each cascade branch.
- [ ] **AC12** — `RadiusControl` component takes `role: "pickup" | "dropoff"`; the i18n key, circle stroke, and form-field name are parameterised by role. Old `PickupRadiusControl` import sites updated.
- [ ] **AC13** — `TransportWindowForm.tsx` mounts two `RadiusControl` instances; the dropoff control is rendered iff `destinationLat != null && destinationLng != null`. Clearing the destination address resets the dropoff radius. Playwright golden-path covers the bounded-destination case; a sibling spec covers open-destination (dropoff control hidden).
- [ ] **AC14** — `CargoForm.tsx` POSTs the four parsed `_locality` / `_admin_area` fields alongside the lat/lng pins. No province / locality `<input>` / `<select>` remains in either publish form.
- [ ] **AC15** — Match-card label renders `"Locality, AdminArea → Locality, AdminArea"` when destination is set, `"Locality, AdminArea → Cualquier destino"` (via i18n key `transport_window.open_destination`) when it isn't. No hardcoded literals.
- [ ] **AC16** — `Carrier.province` and `Carrier.base_city` columns are untouched; `frontend/src/components/ProvinceSelect.tsx` still mounts on the Carrier signup form unchanged.
- [ ] **AC17** — Changing `dropoff_radius_km` via PATCH on `TransportWindow` does NOT cascade-cancel any `CargoOffer` already in `pending` (mirror of US50's `pickup_radius_km` non-retroactivity contract). RSpec covers this explicitly.
- [ ] **AC18** — SQLite-only. No PostGIS, no GIN / GIST / spatial indexes, no `unaccent`, no `EXCLUDE` constraints, no "Phase-2" comments anywhere in the diff. Per `CLAUDE.md` § "Database policy".
- [ ] **AC19** — All code identifiers + routes English; UI copy and validation errors via i18n keys (`config/locales/*.yml` for BE, the prototype-stage `landingContent.ts` bundle for FE where applicable). Per `CLAUDE.md` § "Language policy".

## Risk notes

- **Truncate blast radius.** The migration wipes every `shipment`, `cargo_offer`, `tracking_event`, `payment`, `route`, `cargo`, `transport_window`. Demo flows depending on a pre-existing shipment will need to re-seed after migration; document the seed re-run in the PR body.
- **AA filter forms 500 on stale column refs.** Grep `app/admin/` for `_province`, `_locality`, `_zone` before opening the PR; an AA page that 500s on load will burn CI time for diagnosis.
- **`open_destination_consistency` validator + FE form state.** The FE must clear all six destination fields together on a destination-blank event. A partial clear (e.g. address blanked but coords stale) trips the validator and surfaces as a confusing 422. The Playwright open-destination spec catches this.
- **Bbox math at high latitudes** (Patagonia). 1 / cos(54°) ≈ 1.7×. Spec covers Bariloche-latitude bbox.
- **Match-card label overflow.** Long Argentine compound names (e.g. `"Villa General Belgrano, Córdoba → San Carlos de Bariloche, Río Negro"`) may wrap on narrow viewports. Pre-PR `/critique` + `/polish` should catch.

## Test plan

- [ ] RSpec model — `TransportWindow#open_destination_consistency` validator (all-NULL, all-set, every partial state).
- [ ] RSpec model — `TransportWindow` `dropoff_radius_km` numericality (`nil` allowed iff destination is open, otherwise 1–200).
- [ ] RSpec lib — `Truckr::Geo.bbox_for` low / mid / high latitude.
- [ ] RSpec model — `TransportWindow.within_bbox_of`, `.within_dropoff_radius_of` (open-destination passthrough + bounded-destination Haversine).
- [ ] RSpec model — `Cargo#matching_windows` end-to-end: cargo in CABA + window in Salta with `pickup_radius_km=50` → excluded; window in Rosario with bounded destination matching the cargo → included; window with open destination → included regardless of dropoff.
- [ ] RSpec request — `GET /api/transport_windows` returns 404.
- [ ] RSpec request — `GET /api/cargos/:id/matches` includes the new columns and respects the dropoff filter.
- [ ] RSpec request — PATCH `/api/carriers/me/transport_windows/:id` changing `dropoff_radius_km` doesn't touch `CargoOffer` `pending` rows.
- [ ] Vitest unit — `places.ts` cascade across locality / sublocality_level_1 / administrative_area_level_2 / formatted_address fallback.
- [ ] Vitest component — `RadiusControl` with `role="dropoff"` and conditional mount based on a destination-pin prop.
- [ ] Playwright — publish-window golden path with bounded destination + draggable dropoff circle + match-card label assertion.
- [ ] Playwright — open-destination variant: dropoff control hidden, match-card label ends in `"Cualquier destino"`.

## Notes for the implementer

- **PR title format**: conventional type at the start, no `[REQ-BE-00039]` bracket prefix. `feat(matching): migrate to address-driven matching, drop province matchers, add dropoff radius` is the canonical title; reference the issue TAG via `Closes #N` in the body.
- **`gh pr create --assignee @me`** — repo convention.
- Pre-PR gate per `CLAUDE.md`: `/critique` → `/polish` → `/audit` on the FE diff (publish-window form, RadiusControl, match card), then `just lint` + `just frontend-test-coverage` + `just frontend-test-e2e` + `just backend-test` + `just build-artifacts`. CI is expensive.
