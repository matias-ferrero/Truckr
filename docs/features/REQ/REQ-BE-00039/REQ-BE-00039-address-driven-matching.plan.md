# REQ-BE-00039 — Migrate to address-driven matching, drop province matchers, add dropoff radius

> **Scope note.** Single PR on the `feature/gmaps-fulfilment` worktree branch covering BE schema + matcher, BE API surface, FE forms and helper, plus docs. Tagged `REQ-BE-00039` for backend numbering convention (no `REQ-FS-` prefix exists in this repo); the FE deliverables ride in the same PR rather than splitting into a `REQ-FE-XXXXX` companion. The `One issue / one PR` slicing in the design synthesis takes precedence over the prefix-fallback hint in the original handoff.

## Background

US48 (`REQ-FE-00025` / `REQ-BE-00036`) put a Google Places picker on the TransportWindow publish form, capturing `origin_lat` / `origin_lng` / `destination_lat` / `destination_lng` at `DECIMAL(9,6)`. US49 (`REQ-FE-00026`) did the same for Cargo's pickup / delivery pins. US50 (`REQ-FE-00027` / `REQ-BE-00037`) added `pickup_radius_km` on TransportWindow and switched `Cargo#matching_windows` to Haversine over the pickup pin.

The pre-existing province / locality string columns (`transport_windows.{origin_province, origin_province_normalized, origin_locality, origin_locality_normalized, destination_province, destination_province_normalized, destination_locality, destination_locality_normalized}` and `cargos.{pickup_zone, pickup_zone_normalized, delivery_zone, delivery_zone_normalized}`) were the original narrowing prefilter under ADR-010. They now duplicate the Haversine path (UX dead weight: publish forms don't surface them anymore) and risk drift between the pin and the string. ADR-014 retires them.

A second branch of the same decision: the matcher today filters on pickup distance only. The Carrier has no symmetric way to bound the destination ("I'll deliver in Buenos Aires province but not Patagonia") short of either pinning a precise destination or going fully open-destination. ADR-014 introduces `dropoff_radius_km` on `transport_windows` symmetric to `pickup_radius_km`.

Companion artifacts: ADR-014 (`docs/01-technical-vision/technical-vision.md`), glossary deltas (`docs/05-appendices/glossary.md` — Destino abierto, Ventana de transporte, Carga, new Radio de entrega), umbrella US52 (`docs/artifacts/backlog-us.typ`).

## Schema migration

One Rails migration, destructive (truncates dependents before column drops). Coursework data only; no seeds need to be preserved across the migration boundary.

**`transport_windows`:**

- Drop columns: `origin_province`, `origin_province_normalized`, `origin_locality`, `origin_locality_normalized`, `destination_province`, `destination_province_normalized`, `destination_locality`, `destination_locality_normalized`.
- Drop indexes: `index_transport_windows_on_origin_province_normalized`, `index_transport_windows_on_destination_province_normalized`, `index_transport_windows_on_origin_locality_normalized`, `index_transport_windows_on_destination_locality_normalized`.
- Add columns: `origin_address :text, null: false`; `destination_address :text` (nullable); `origin_locality :text, null: false`; `origin_admin_area :text, null: false`; `destination_locality :text` (nullable); `destination_admin_area :text` (nullable); `dropoff_radius_km :integer` (nullable, range enforced in model).
- New columns reuse the names `origin_locality` / `destination_locality` that the migration just dropped — the column type changes from `string` (Ransack `_normalized` sibling) to `text` (display-only, no normalization). The destructive truncate before the migration avoids any data-type-conflict salvage.

**`cargos`:**

- Drop columns: `pickup_zone`, `pickup_zone_normalized`, `delivery_zone`, `delivery_zone_normalized`.
- Drop indexes: `index_cargos_on_pickup_zone_normalized`, `index_cargos_on_delivery_zone_normalized`.
- Add columns: `pickup_locality :text, null: false`; `pickup_admin_area :text, null: false`; `delivery_locality :text, null: false`; `delivery_admin_area :text, null: false`.

**Truncate order** (FK chain): `tracking_events` → `payments` → `routes` → `shipments` → `cargo_offers` → `cargos` and `transport_windows`. Use raw `DELETE FROM` (SQLite) inside the migration's `up`; `down` is `raise IrreversibleMigration` per the destructive contract.

**Model invariant** (not a DB constraint): `TransportWindow` validates that `destination_lat`, `destination_lng`, `destination_address`, `destination_locality`, `destination_admin_area`, and `dropoff_radius_km` are either all present or all `NULL` — the "open destination" trio expands to a sextet. Add a single custom validator `validate :open_destination_consistency` that returns an `:open_destination_partial` error on mixed state.

## BE changes

### Matcher (`backend/app/models/cargo.rb`, `backend/app/models/transport_window.rb`, `backend/lib/truckr/geo.rb`)

- Define `TransportWindow::PICKUP_RADIUS_KM_MAX = 200` (or `Truckr::Geo::PICKUP_RADIUS_KM_MAX`, whichever is more idiomatic with the existing constant landing). Reuse for both `pickup_radius_km` and `dropoff_radius_km` upper bound validation.
- Add a `TransportWindow.within_bbox_of(lat, lng, radius_km)` scope that emits `WHERE origin_lat BETWEEN ? AND ? AND origin_lng BETWEEN ? AND ?`, with the longitude span widened by `1 / cos(lat_radians)` so it stays correct near the equator and the south of Argentina. Helper math in `Truckr::Geo.bbox_for(lat, lng, radius_km)` returning `[min_lat, max_lat, min_lng, max_lng]`.
- Rewrite `Cargo#matching_windows` to: (1) `TransportWindow.within_bbox_of(pickup_lat, pickup_lng, PICKUP_RADIUS_KM_MAX)`, (2) `.within_pickup_radius_of(pickup_lat, pickup_lng)` already in place from US50 — keep, (3) new scope `.within_dropoff_radius_of(delivery_lat, delivery_lng)` that lets through any row with `destination_lat IS NULL` and otherwise applies Haversine in Ruby against `dropoff_radius_km`.
- Drop the Ransack matchers `origin_province_normalized_cont`, `destination_province_normalized_cont` from `Cargo` (and any sibling `TransportWindow.ransackable_attributes` entries pointing at the removed columns). Drop the `I18n.transliterate` `before_validation` callback on `TransportWindow` that populated the `_normalized` columns.

### Serializer + controller

- `TransportWindowResource` (or equivalent JBuilder partial — match the existing pattern): drop province / locality string fields; add `origin_address`, `destination_address`, the four parsed `_locality` / `_admin_area`, `dropoff_radius_km`.
- `CargoResource`: drop `pickup_zone` / `delivery_zone`; add the four parsed `_locality` / `_admin_area`.
- The match-card payload at `GET /api/cargos/:id/matches` includes both endpoints' parsed `_locality` / `_admin_area` so the FE can render `"Locality, AdminArea → Locality, AdminArea"` without a second roundtrip. The "open destination" case is signalled by `destination_lat == null` on the wire; the FE renders the i18n key `transport_window.open_destination` accordingly.

### Routes + endpoint deletion

- Delete the public marketplace route `GET /api/transport_windows` from `config/routes.rb`. Remove the entire `Api::TransportWindowsController` file (`backend/app/controllers/api/transport_windows_controller.rb`).
- Leave `GET /api/carriers/me/transport_windows` (`Api::Carriers::Me::TransportWindowsController`) and the AA admin paths in place — both consumers are scoped to a Carrier or admin and don't search by province.
- Update any e2e spec / FE call site that hit `GET /api/transport_windows` to use `GET /api/cargos/:id/matches` instead, or delete it if no replacement makes sense.

### ActiveAdmin

`backend/app/admin/transport_windows.rb` has Ransack-backed filters on the removed `_normalized` columns. List as a TODO bullet in the issue body — the rewrite is in scope of this PR. New filter set: `origin_address_cont`, `destination_address_cont`, `origin_lat_gteq` / `_lteq`, `pickup_radius_km_eq`, `dropoff_radius_km_eq` (whichever subset fits the AA filter ergonomics). Same pass on `backend/app/admin/cargos.rb` if it filtered on `pickup_zone_normalized` / `delivery_zone_normalized`.

## FE changes

### `frontend/src/lib/places.ts` (new)

Pure helper. Given a `google.maps.places.PlaceResult`, returns `{ address: string, lat: number, lng: number, locality: string, admin_area: string }`. The `_locality` / `_admin_area` extraction cascade:

1. Look for a component with type `locality` (most cities).
2. Else `sublocality_level_1` (CABA neighbourhoods like Palermo, Caballito).
3. Else `administrative_area_level_2` (partido / departamento — La Plata, Pilar).
4. Fallback: `formatted_address.split(",")[0].trim()`.

`admin_area` always comes from `administrative_area_level_1` (the province / CABA proper). No backend round-trip — the FE owns the cascade and the BE persists what it receives.

### `RadiusControl` refactor

Rename `frontend/src/components/PickupRadiusControl.tsx` to `frontend/src/components/RadiusControl.tsx`. Add a `role: "pickup" | "dropoff"` prop that parameterises:

- The map circle stroke colour (`pickup` reuses today's colour; `dropoff` a distinct hue per `frontend/.impeccable.md` palette — pick one that contrasts).
- The i18n key for the numeric input label, placeholder, and aria-label: `transport_window.{role}_radius.{label|placeholder|aria_label}`.
- The form-field name posted to the BE: `pickup_radius_km` or `dropoff_radius_km`.

Mount in `frontend/src/pages/carrier/TransportWindowForm.tsx` once per role. The dropoff control is conditionally rendered: visible iff `destinationLat != null && destinationLng != null`. Clearing the destination address auto-clears the dropoff radius (form-state reset on destination blur with empty value).

### Form changes

- `frontend/src/pages/carrier/TransportWindowForm.tsx`: bind `origin_address`, `destination_address`, the four parsed `_locality` / `_admin_area`, and `dropoff_radius_km` into the form state and POST payload. The AddressPicker now invokes `places.ts` on confirm and passes the full extracted object up.
- `frontend/src/features/cargo/CargoForm.tsx`: same for `pickup_address`, `delivery_address`, the four parsed Cargo `_locality` / `_admin_area`.
- Both forms drop any vestigial province / locality `<input>` / `<select>` that survived US48 / US49. If `ProvinceSelect.tsx` is still imported by either form (it shouldn't be after US48 / US49), remove the import.

### Match card label

In whichever component renders cards on the matches screen (look at `frontend/src/features/cargo/MatchesList.tsx` or equivalent after US50's distance-per-match landed), format the location label as `${origin_locality}, ${origin_admin_area} → ${destination_locality}, ${destination_admin_area}` when destination is set, or `${origin_locality}, ${origin_admin_area} → ${t('transport_window.open_destination')}` when `destination_lat == null`. All copy via i18n keys; no hardcoded literals per `CLAUDE.md` § "Language policy".

### Carrier signup untouched

`frontend/src/components/ProvinceSelect.tsx` and its one consumer in the Carrier signup form are out of scope. `Carrier.province` and `Carrier.base_city` columns on `carriers` are not touched by the migration.

## Tests

- **Backend RSpec**: model specs for `TransportWindow` open-destination validator (all-NULL vs all-set vs mixed), `Cargo#matching_windows` bbox + Haversine pickup + Haversine dropoff + open-destination skip, `Truckr::Geo.bbox_for` at high/low latitude, `Truckr::Geo.haversine_km` (already in place — verify still green). Request specs for `GET /api/cargos/:id/matches` exercising open-destination and bounded-destination ventanas in the same dataset. Request spec asserting `GET /api/transport_windows` returns 404 (route deleted).
- **Frontend Vitest**: unit spec for `frontend/src/lib/places.ts` covering each cascade branch (locality / sublocality / admin_area_level_2 / formatted_address fallback). Component spec for `RadiusControl` with `role="dropoff"` and conditional visibility tied to a destination pin prop.
- **Frontend Playwright**: extend the existing publish-window golden-path spec to set a destination pin + drag a dropoff radius circle + submit; assert the card label on the matches screen renders `"Locality, AdminArea → Locality, AdminArea"`. Add an open-destination variant asserting the dropoff control is hidden and the matches-card label ends in `"Cualquier destino"`.

## Risks

- **Bbox math at edge cases**: very high or very low latitudes (Patagonia south, e.g. Ushuaia at ~54°S) widen the longitude span considerably (1 / cos(54°) ≈ 1.7×). Verify the bbox stays correct for the Argentine bounding rectangle; outside Argentina is unreachable per the Google Places `componentRestrictions: { country: 'ar' }` set in US48.
- **Truncating live carrier / shipper rows**: the migration trims `transport_windows`, `cargos`, `cargo_offers`, `shipments`, dependents — but NOT `users`, `carriers`, `shippers`, `vehicles`. Demo flows that depend on having shipments will need to re-seed; document the seed re-run in the PR body.
- **AA filter breakage during code-review**: AA filter forms reference column names directly. Missing one will surface as an AA page that 500s on load. Mitigate by grepping `app/admin/` for `_province` / `_locality` / `_zone` before PR.
- **`open_destination_consistency` validator interplay with FE form**: the FE must clear `destination_lat`, `destination_lng`, `destination_address`, both destination `_locality` / `_admin_area`, and `dropoff_radius_km` together when the Carrier blanks the destination field. A partial clear (e.g. address blanked but coords stale) trips the validator and surfaces as a confusing 422.
- **Match-card label rendering with very long locality + admin_area**: e.g. `"Villa General Belgrano, Córdoba → San Carlos de Bariloche, Río Negro"` may wrap awkwardly on narrow viewports. Pass through the `impeccable` UI quality gate; truncate with ellipsis if the design calls for it.

## TODOs to track in the issue (not in this plan's scope)

- ActiveAdmin filter rewrites for `TransportWindow` and `Cargo` (touched above, but specifics depend on AA's idiomatic filter API in this repo).
- Seed file update for the new column shape — re-run after the destructive migration to restore a usable demo dataset.
- Confirm the FE `landingContent.ts` doesn't reference province / locality copy that drifts now.
