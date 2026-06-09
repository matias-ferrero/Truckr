# REQ-BE-00046: US53 — Autocalculado de Distancia en Carga (fullstack)

| Field | Value |
|---|---|
| **Tag** | REQ-BE-00046 |
| **Title** | US53 — Autocalculado de Distancia en Carga (fullstack) |
| **Priority** | P2 |
| **Status** | IR |
| **PR** | [#322](https://github.com/tcorzo/fiuba-gestion-tp/pull/322) |
| **Created** | 2026-06-06 |
| **Sprint** | 4 |
| **Author** | Claude Code |
| **Depends On** | **Hard:** [[REQ-BE-00036]] (lat/lng columns on `cargos` — already merged). **Soft:** [[REQ-FE-00028]] (future `<ShipmentMap/>` swap for `CargoMapPreview`). |
| **Decision Doc** | N/A — decisions closed inline below. |
| **Selected Approach** | Single fullstack PR: BE migration + Google Routes API v2 `before_create` callback + `CargoResource` attribute; FE route polyline + distance label via `DirectionsService` in `CargoMapPreview` + locked distance display in `CreateOfferPage`. |
| **GitHub Issue** | [#321](https://github.com/tcorzo/fiuba-gestion-tp/issues/321) |

---

## 1. Problem Statement

US53 requires that, when a Shipper creates a cargo, the route distance is shown automatically — and that price is visible without manual km entry when making an offer.

**AC analysis:**

- **AC1** ("conexión a Google Maps para observar el recorrido"): Satisfied by `CargoMapPreview` — renders a `google.maps.Map` with origin/destination markers, `fitBounds`, and a `DirectionsRenderer` polyline drawn via `DirectionsService`.
- **AC2** ("calcular y mostrar distancia correctamente"): `distance_km` persisted on every cargo create via `GoogleMaps::DistanceService` (Google Routes API v2); displayed in the form as a read-only label below the map canvas.
- **AC3** ("eliminar ingreso manual de distancia"): No manual distance field exists in the current form — this AC is vacuously satisfied; no deletion needed.
- **AC4** ("precio a pagar al hacer una oferta"): `CreateOfferPage` reads `cargo.distance_km` directly — no user input required. The submit button is disabled when `distance_km` is null (legacy rows or API failure on create).

---

## 2. Solution Design

### 2.1 Backend

1. **Migration** — add `distance_km DECIMAL(10,2)` (nullable) to `cargos`. Nullable covers pre-existing rows; every new `create` will have it set.
2. **`GoogleMaps::DistanceService`** — module with a single class method `fetch_km(origin_lat, origin_lng, dest_lat, dest_lng)` that calls the **Google Routes API v2** (`routes.googleapis.com/directions/v2:computeRoutes`) using `Net::HTTP` (stdlib, no new gem). Returns distance in km (Float, 2dp) or nil on any error.
3. **Cargo model** — two callbacks:
   - `before_create :set_distance_km` — calls `DistanceService.fetch_km`; aborts with a validation error if nil (hard failure: cargo must not be created without a computable route).
   - `before_save :refresh_distance_on_route_change` — fires only on updates when any lat/lng column is dirty; silently preserves the previous value if the API fails.
4. **CargoResource** — add `distance_km` to the Alba attributes list.

### 2.2 Frontend

**CargoMapPreview (AC1 + AC2):**
- Load `@googlemaps/js-api-loader`; once the API is ready, render a `google.maps.Map` with two `Marker` objects and call `DirectionsService.route()` for the road polyline.
- `DirectionsRenderer` draws the route with a high-contrast cobalt blue polyline (`#0041c2`, weight 6).
- Distance is shown below the canvas as a read-only label derived from the `DirectionsService` response (or from the `distanceKm` prop when pre-loaded in detail view).
- `distanceState: "idle" | "loading" | "ready" | "error"` manages async UI.
- Stale `mapRef` guard: `mapRef.current.getDiv() !== mapElRef.current` detects when the canvas div has remounted (e.g. after an address was cleared) and reinitialises `google.maps.Map` on the new element.

**CreateOfferPage (AC4):**
- Reads `cargo.distance_km` from the already-fetched cargo. Distance is displayed as a read-only `<dd>` — no input field.
- `estimated_km` is passed directly to the API from `cargo.distance_km` (string, as returned by the backend).
- The submit button is disabled when `distance_km` is null.

### 2.3 Key decisions

| Decision | Choice | Why |
|---|---|---|
| Distance formula | Google Routes API v2 | US requirement: road distance, not straight-line. Haversine does not satisfy AC2. |
| API client | `Net::HTTP` (stdlib) | No new gem dependency; the API returns JSON that `JSON.parse` handles natively. |
| Cargo create failure | Hard (422) | A cargo without a computable route should not be created — coordinates are unreachable or the API key is misconfigured. |
| Cargo update failure | Soft (preserve previous) | A stale distance is acceptable on update; blocking edits on a transient API failure would be worse UX. |
| Distance in `CreateOfferPage` | Locked — read from `cargo.distance_km` | AC4 specifies the distance is calculated by the system; no manual adjustment is meaningful or permitted. |
| `GOOGLE_MAPS_API_KEY` | `ENV["GOOGLE_MAPS_API_KEY"]` | Loaded via `dotenv-rails` in dev/test; must be set in production deployment. |
| CargoMapPreview | Extend (not replace) | Replacement by `<ShipmentMap/>` is a separate future task ([[REQ-FE-00028]]). |

---

## 3. Implementation Tasks

### Backend

| # | File | Change |
|---|---|---|
| B1 | `db/migrate/20260606000000_add_distance_km_to_cargos.rb` | New migration |
| B2 | `app/services/google_maps/distance_service.rb` | New service — Routes API v2 via Net::HTTP |
| B3 | `app/models/cargo.rb` | `before_create :set_distance_km` + `before_save :refresh_distance_on_route_change` |
| B4 | `app/resources/cargo_resource.rb` | Add `distance_km` to attributes |
| B5 | `spec/services/google_maps/distance_service_spec.rb` | 5 cases: ok, no routes, HTTP error, timeout, missing key |
| B6 | `spec/models/cargo_spec.rb` | Distance callback: create, non-route update, coordinate update, API fail on update, pre-assigned skip, nil API on create |
| B7 | `spec/requests/api/cargos_spec.rb` | Assert `distance_km` in POST 201; 422 when service returns nil |
| B8 | `spec/rails_helper.rb` | Global stub prevents real HTTP calls across all specs |

### Frontend

| # | File | Change |
|---|---|---|
| F1 | `src/types/Cargo.ts` | Add `distance_km: string \| null` to `Cargo` type; `reviews_count` to `CargoCarrierSummary` |
| F2 | `src/features/cargo/cargosContent.ts` | Distance label strings (loading / ready / error); match card strings |
| F3 | `src/features/cargo/CargoMapPreview.tsx` | DirectionsService polyline, distance state machine, stale-ref fix |
| F4 | `src/features/cargo/CargoForm.tsx` | Remove client-side Haversine; distance comes from backend |
| F5 | `src/pages/shipper/offerContent.ts` | Update distance/cost label strings |
| F6 | `src/pages/shipper/CreateOfferPage.tsx` | Distance read-only from `cargo.distance_km`; submit disabled if null |
| F7 | `src/features/cargo/CargoMapPreview.test.tsx` | Loading / road distance / error / stale-ref remount cases |
| F8 | `src/pages/shipper/CreateOfferPage.test.tsx` | Locked distance display, null disabled state, submit payload |
| F9 | `src/lib/format-distance.ts` | New utility: meters / 1-decimal km / whole km formatting |

---

## 4. Test Strategy

### Backend (RSpec)

- **Service spec:** HTTP success → km; no routes → nil; HTTP error → nil; timeout → nil; missing key → nil (no HTTP call).
- **Model spec:** `distance_km` set on `before_create` via the service stub; non-route field update does not re-call service; coordinate update does re-call; API fail on update preserves previous value; pre-assigned `distance_km` skips the call; nil API on create aborts with validation error.
- **Request spec:** `POST /api/cargos` 201 includes `distance_km` matching `/\A\d+\.\d+\z/`; 422 when service returns nil.

### Frontend (Vitest)

- **Unit:** `CargoMapPreview` shows loading indicator during pending `DirectionsService` call; shows road distance on OK; shows error on ZERO_RESULTS; reinitialises `google.maps.Map` on canvas remount after address clear.
- **Unit:** `CreateOfferPage` shows formatted distance and cost from `cargo.distance_km`; disables submit when `distance_km` is null; posts `estimated_km` directly from `cargo.distance_km` without user input.

---

## 5. Acceptance Criteria

- [x] AC1: Mapa de recorrido visible en el formulario de carga — `CargoMapPreview` con marcadores y polilínea de ruta en azul cobalto vía `DirectionsRenderer`.
- [x] AC2: Distancia calculada y mostrada correctamente — Google Routes API v2 en backend; `DirectionsService` en el mapa del formulario.
- [x] AC3: Sin ingreso manual de distancia — campo nunca existió, vacuamente satisfecho.
- [x] AC4: Precio a pagar visible al hacer una oferta — `distanceKm` y `totalCost` derivados de `cargo.distance_km` sin input del usuario.

---

## 6. Out of Scope

- Back-filling `distance_km` on existing Cargo rows (not needed for MVP; can be a future rake task).
- Replacing `CargoMapPreview` with `<ShipmentMap/>` (tracked by [[REQ-FE-00028]]).
- Carrier-editable distance: the distance is authoritative from the Google Routes API and is not adjustable by either party.
