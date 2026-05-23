# REQ-BE-00034: Baja de vehículo por el transportista (soft delete, ADR-009) — US32

| Field | Value |
|-------|-------|
| **Tag** | REQ-BE-00034 |
| **Title** | Baja de vehículo por el transportista (soft delete, ADR-009) (US32) |
| **Priority** | P2 |
| **Status** | READY |
| **Created** | 2026-05-22 |
| **Updated** | 2026-05-22 |
| **Author** | Claude Code |
| **Depends On** | `REQ-BE-00009/10` (Vehicle CRUD + Carrier `Vehicle` resource — PR #144). `REQ-BE-00021` (Marketplace foundation — `TransportWindow`, `CargoOffer`). `REQ-BE-00022` (Fulfilment foundation — `Shipment.in_progress`). `REQ-FE-00016` (`TransportWindow` CRUD — provides modal/event patterns reused here via PR #194 / `QuoteInboxPage`). |
| **Decision Doc** | N/A (every domain decision locked in two grilling rounds; recorded inline in `.gdsi-sdlc/issues/Ready/REQ-BE-00034-...issue.md`) |
| **Selected Approach** | Hand-rolled ADR-009 soft-delete on `Vehicle` (no `discard` gem). Single fullstack PR: migration + model + controller + policy + locales + ActiveAdmin + frontend modal + docs amendment. |

---

## 1. Problem Statement

The Carrier needs to retire vehicles from their active fleet (sold, decommissioned, non-operational) **without breaking historical traceability**. A hard `DELETE FROM vehicles` would break references published in `TransportWindow`s and the historical trip chain that reaches the vehicle via `Shipment → CargoOffer → TransportWindow → Vehicle`. Today `Vehicle#destroy` is gated by `before_destroy :ensure_no_active_commitments` (`backend/app/models/vehicle.rb:18,89-97`) — which is a hard-delete check, not a baja flow, and exposes no Carrier-facing API.

This issue adds a **soft-delete path** to `Vehicle` following the established **ADR-009** pattern (same hand-rolled block already used by `Shipment`, `Payment`, `ArcaInvoice`), wires a `DELETE /api/carriers/me/vehicles/:id` endpoint to it, and exposes the **"Dar de baja"** CTA on the Carrier fleet UI. Hard-delete stays callable (Q9 decision) — `Vehicle#destroy` and ActiveAdmin's destroy action are NOT overridden; the productive baja path is `discard`.

State at the start of this plan:

- `Vehicle` model: no `discarded_at`, no scopes, hard-delete gated by `ensure_no_active_commitments`.
- `TransportWindow#vehicle` is a plain `belongs_to :vehicle, inverse_of: :transport_windows` — would 404 a historical lookup once the vehicle is soft-deleted.
- `Api::Carriers::Me::VehiclesController#destroy` calls `vehicle.destroy!` and returns `head :no_content`.
- ActiveAdmin `Vehicle` resource (`backend/app/admin/vehicles.rb`) reads through default scope.
- Glossary `Vehicle` row already carries "Soft-deleted (audit) since REQ-BE-00034" + canonical **"Dar de baja"** CTA (set in the triage PR — Lucas does NOT edit the glossary).
- ADR-009 lists `Vehicle` under hard-delete and uses the historical `deleted_at` wording (`docs/01-technical-vision/technical-vision.md:106-115`).

---

## 2. Solution Design

### 2.1 Approach — hand-rolled ADR-009, no gem

Same five-line block already in `Shipment` / `Payment` / `ArcaInvoice` (see `backend/app/models/shipment.rb:42-50`):

```ruby
default_scope { where(discarded_at: nil) }
scope :discarded,      -> { unscope(where: :discarded_at).where.not(discarded_at: nil) }
scope :with_discarded, -> { unscope(where: :discarded_at) }
```

…plus `discard` (no-bang, returns `true`/`false`, populates `errors`) and `discard!` (bang, raises `Vehicle::NotDiscardable`). The split exists so the Carrier controller can render 422 with `vehicle.errors` on a user-recoverable failure, while specs / `rails console` / future ActiveAdmin restore wiring can use the bang.

The repo-wide migration to the `jhawthorn/discard` gem is owned by the repo owner and is **out of scope here** — introducing it for a single model would create two soft-delete idioms until the wide migration lands.

### 2.2 Locked design decisions (all recorded in the issue body)

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | Column name **`discarded_at`** (not `deleted_at`). | Matches code already in `Shipment` / `Payment` / `ArcaInvoice`. ADR-009 amendment in AC12 canonizes this and supersedes the historical `deleted_at` wording. |
| D2 | Split `discard` (no-bang) + `discard!` (bang). Controller uses `discard`. | "Compromisos pendientes" is a user-recoverable error, not a system exception. Rails convention (cf. `save` vs `save!`). |
| D3 | AC4 commitments check stays strict — blocks on any non-terminal `CargoOffer` (`pending` / `accepted` / `paid`), not only `Shipment.in_progress`. | A `pending` `CargoOffer` is a promise made to a Shipper; discarding the Vehicle leaves it zombie until `CargoOfferExpirationJob` expires it (≤48h). Force the Carrier to reject / wait first. |
| D4 | AC5 historical reads via `belongs_to :vehicle, -> { unscope(where: :discarded_at) }` on **`TransportWindow`** (NOT on `Shipment`). | The canonical path is `Shipment → CargoOffer → TransportWindow → Vehicle`. Adding a `Shipment#vehicle` shortcut is denormalization that would need its own ADR. |
| D5 | AC14 model invariant on `TransportWindow`: `validate :vehicle_must_be_kept_when_active`. | Closes the deactivate→discard→reactivate loophole. Lives on the model (not the controller) so the guarantee is stack-independent. |
| D6 | **No cascade.** Discarding a vehicle does NOT auto-deactivate its TransportWindows. | AC3 (block on active windows) + AC14 (block reactivation) enforce coherence manually. Clearer UX, no implicit behaviour. |
| D7 | `Vehicle#destroy` stays callable (Q9, 2026-05-22). | `dependent: :restrict_with_error` on `TransportWindow.has_many :cargo_offers` already makes hard-delete impossible for any vehicle with history; orphan vehicles that *can* be destroyed have zero data loss. ActiveAdmin keeps its escape hatch. The existing `before_destroy :ensure_no_active_commitments` stays as a final safety net. |
| D8 | ADR-009 amendment is **in-place** (Q5) — append "Amendment 2026-05-22 (REQ-BE-00034)" subsection. No ADR-012. | The change is a list edit + wording superseding; in-place reads better than a sibling ADR pointing at it. |
| D9 | UI CTA copy **"Dar de baja"** (CTA + modal title). NOT "Eliminar" / "Retirar" / "Borrar". | Already locked in the glossary `Vehicle` row "UI canon (es-AR)" block. |
| D10 | ActiveAdmin restore (`undiscard` action) and Carrier "Vehículos archivados" view are OUT OF SCOPE. | Data-level reversibility only via `rails console`. Restore UI is a triaged follow-up (P3). |

### 2.3 Sequencing

**Backend → docs amendment → frontend**, in that order, because the FE depends on the backend response shape (422 + `errors[:base]` + i18n keys).

1. **Backend** — migration, `Vehicle` ADR-009 block, `TransportWindow#vehicle` unscope + AC14 invariant, controller `destroy` rewrite, locales, ActiveAdmin `with_discarded` scope, RSpec coverage.
2. **Docs** — ADR-009 amendment + domain-model table + 3 ERD `.puml` comments + README sentence. PDF rebuild via `just build-artifacts` for the touched section only (`docs/04-database-diagrams/README.md`).
3. **Frontend** — API client `deleteVehicle`, "Dar de baja" CTA on the row, confirmation modal (PR #194 pattern), 422 error surface, event-driven refresh, Vitest + Playwright specs.

---

## 3. Implementation Tasks

| # | Task | Layer | Files (primary) |
|---|------|-------|-----------------|
| 1 | Migration: `vehicles.discarded_at :datetime` + B-tree index | BE | `backend/db/migrate/{ts}_add_discarded_at_to_vehicles.rb` |
| 2 | `Vehicle` model: ADR-009 block (`default_scope`, scopes, `discard` / `discard!`, `NotDiscardable`, `can_be_discarded?`, `discarded?`) | BE | `backend/app/models/vehicle.rb` |
| 3 | `TransportWindow#vehicle` → `belongs_to :vehicle, -> { unscope(where: :discarded_at) }` (AC5/AC9) | BE | `backend/app/models/transport_window.rb` |
| 4 | `TransportWindow` invariant `vehicle_must_be_kept_when_active` (AC14) | BE | `backend/app/models/transport_window.rb` |
| 5 | `VehiclesController#destroy` → `vehicle.discard` + 422 on failure (AC3 / AC4 / AC10) | BE | `backend/app/controllers/api/carriers/me/vehicles_controller.rb` |
| 6 | `VehiclePolicy#destroy?` (no change needed: owner-only already) — add comment confirming it gates discard | BE | `backend/app/policies/vehicle_policy.rb` |
| 7 | i18n keys (en + es): `has_active_windows`, `has_pending_commitments`, `vehicle_must_be_kept_when_active` | BE | `backend/config/locales/en.yml`, `backend/config/locales/es.yml` |
| 8 | ActiveAdmin `Vehicle` resource: `scope :with_discarded` (read-only, no restore action) | BE | `backend/app/admin/vehicles.rb` |
| 9 | RSpec — model: `discard`/`discard!` happy + guards + scopes + historical resolution | BE | `backend/spec/models/vehicle_spec.rb`, `backend/spec/models/transport_window_spec.rb` |
| 10 | RSpec — request: `DELETE /api/carriers/me/vehicles/:id` (204 / 422 each error key / 403 cross-carrier) | BE | `backend/spec/requests/api/carriers/me/vehicles_spec.rb` |
| 11 | ADR-009 amendment (in-place subsection) | DOC | `docs/01-technical-vision/technical-vision.md:106-115` |
| 12 | Soft-delete table update in domain model | DOC | `docs/02-high-level-design/domain-model.md` (around line 354) |
| 13 | ERD `.puml` comment updates + README sentence | DOC | `docs/04-database-diagrams/erd-overview.puml`, `erd-fulfilment.puml`, `erd-marketplace.puml`, `docs/04-database-diagrams/README.md:25` |
| 14 | Frontend API client: `deleteVehicle(id)` returning 204 / 422 `{ errors: { base: [...] } }` shape | FE | `frontend/src/api/vehicles.ts` |
| 15 | `VehicleList.tsx`: "Dar de baja" CTA per row, opens modal | FE | `frontend/src/pages/carrier/VehicleList.tsx` |
| 16 | Confirmation modal: title "Dar de baja vehículo", confirm "Dar de baja", cancel "Cancelar" — reuses PR #194 pattern | FE | new `frontend/src/pages/carrier/DiscardVehicleDialog.tsx` |
| 17 | i18n strings (`carrierContent.ts`): CTA, modal copy, error-to-message map, success toast | FE | `frontend/src/pages/carrier/carrierContent.ts` |
| 18 | Event-driven refresh: dispatch `truckr:carrier-vehicle-updated` on success; `VehicleList` listens | FE | `frontend/src/pages/carrier/VehicleList.tsx`, `DiscardVehicleDialog.tsx` |
| 19 | MSW handlers for `DELETE /api/carriers/me/vehicles/:id` (204 + 422 each variant) | FE | `frontend/src/mocks/handlers.ts` (or equivalent) |
| 20 | Vitest: CTA renders, modal opens/cancels, 204 removes row + toast, 422 maps each error key to localized copy | FE | `frontend/src/pages/carrier/VehicleList.test.tsx`, `DiscardVehicleDialog.test.tsx` |
| 21 | Playwright e2e: (a) happy discard, (b) blocked-by-active-window with correct copy | FE | `frontend/e2e/carrier-vehicle-discard.spec.ts` |

---

## 4. Code Changes (file-by-file)

### 4.1 BE — `backend/db/migrate/{ts}_add_discarded_at_to_vehicles.rb`

**Purpose**: ADR-009 column on `vehicles`.

```ruby
class AddDiscardedAtToVehicles < ActiveRecord::Migration[7.1]
  def change
    add_column :vehicles, :discarded_at, :datetime
    add_index  :vehicles, :discarded_at
  end
end
```

SQLite-clean: plain `datetime` + B-tree. Same shape as `shipments.discarded_at`. No partial index.

### 4.2 BE — `backend/app/models/vehicle.rb`

**Purpose**: ADR-009 soft-delete block + discard guards.

Add at the top of the class (right after constants, before `belongs_to :carrier`):

```ruby
# ── Soft-delete (ADR-009) ─────────────────────────────────────────────
default_scope { where(discarded_at: nil) }
scope :discarded,      -> { unscope(where: :discarded_at).where.not(discarded_at: nil) }
scope :with_discarded, -> { unscope(where: :discarded_at) }

class NotDiscardable < StandardError; end

def discarded? = discarded_at.present?

# No-bang: populates errors and returns false on guard failure.
def discard
  return false unless can_be_discarded?
  update(discarded_at: Time.current)
end

# Bang: raises NotDiscardable on guard failure (specs / scripts / AA).
def discard!
  raise NotDiscardable, errors.full_messages.join("; ") unless can_be_discarded?
  update!(discarded_at: Time.current)
end

private

# Checks AC3 (active windows) + AC4 (pending commitments). Populates
# self.errors[:base] with i18n symbol keys so the controller can render 422.
def can_be_discarded?
  errors.clear
  errors.add(:base, :has_active_windows)     if transport_windows.active.exists?
  errors.add(:base, :has_pending_commitments) if pending_commitments?
  errors.empty?
end

def pending_commitments?
  return false unless defined?(CargoOffer) && defined?(TransportWindow)
  CargoOffer.joins(:transport_window)
            .where(transport_windows: { vehicle_id: id })
            .where.not(status: %w[expired cancelled])
            .exists?
end
```

**Keep** `before_destroy :ensure_no_active_commitments` (Q9 — D7). It is the safety net for the still-callable `Vehicle#destroy` path used from ActiveAdmin for orphan rows.

### 4.3 BE — `backend/app/models/transport_window.rb`

**Purpose**: keep historical reads resolving (AC5/AC9) + AC14 invariant.

```ruby
# was:
# belongs_to :vehicle, inverse_of: :transport_windows
belongs_to :vehicle, -> { unscope(where: :discarded_at) }, inverse_of: :transport_windows

# add to the validations block:
validate :vehicle_must_be_kept_when_active

# in private:
def vehicle_must_be_kept_when_active
  return unless active && vehicle&.discarded?
  errors.add(:base, :vehicle_must_be_kept_when_active)
end
```

Notes:

- The unscope ensures `shipment.cargo_offer.transport_window.vehicle` resolves even when the vehicle is soft-deleted (AC9 historical reads).
- AC14 protects against the reactivation loophole: a `TransportWindow` previously `active: false` whose `vehicle` was then discarded cannot flip back to `active: true`. The `current_carrier.vehicles.find` in the create path already 404s on a discarded vehicle id (because the controller is scoped through the default scope), so create is covered transitively; the validation makes the guarantee model-level and stack-independent.

### 4.4 BE — `backend/app/controllers/api/carriers/me/vehicles_controller.rb`

**Purpose**: swap `destroy!` for `discard` + render 422 on guard failure.

```ruby
def destroy
  vehicle = current_carrier.vehicles.find(params[:id])
  authorize vehicle
  if vehicle.discard
    head :no_content
  else
    render json: { errors: vehicle.errors.as_json(full_messages: false) },
           status: :unprocessable_entity
  end
end
```

Pundit gate is unchanged: `VehiclePolicy#destroy? = owner?`. The `current_carrier.vehicles.find` scope finds only **non-discarded** vehicles (default scope), so a second `discard` on an already-discarded vehicle returns 404, which is the right behavior.

### 4.5 BE — `backend/app/policies/vehicle_policy.rb`

**Purpose**: no behavioral change; `destroy?` already returns `owner?`. Add a one-line comment confirming the rule now covers `discard` since `discard` is the productive baja path.

### 4.6 BE — `backend/config/locales/en.yml`, `backend/config/locales/es.yml`

**Purpose**: i18n keys for the three new error symbols + frontend error map.

Under `activerecord.errors.models.vehicle.attributes.base` and `activerecord.errors.models.transport_window.attributes.base`:

```yaml
# en.yml
activerecord:
  errors:
    models:
      vehicle:
        attributes:
          base:
            has_active_windows: "Cannot discard: vehicle has active transport windows. Deactivate them first."
            has_pending_commitments: "Cannot discard: vehicle has pending offers or shipments in progress."
      transport_window:
        attributes:
          base:
            vehicle_must_be_kept_when_active: "Cannot activate: the associated vehicle has been discarded."

# es.yml
activerecord:
  errors:
    models:
      vehicle:
        attributes:
          base:
            has_active_windows: "No se puede dar de baja: el vehículo tiene ventanas de transporte activas. Dalas de baja primero."
            has_pending_commitments: "No se puede dar de baja: el vehículo tiene ofertas pendientes o viajes en curso."
      transport_window:
        attributes:
          base:
            vehicle_must_be_kept_when_active: "No se puede activar: el vehículo asociado fue dado de baja."
```

Frontend modal / toast copy lives in `frontend/src/pages/carrier/carrierContent.ts` (see §4.10).

### 4.7 BE — `backend/app/admin/vehicles.rb`

**Purpose**: make discarded vehicles visible in admin (AC11 reversibility from console requires being able to *see* them in AA).

Append before `index do`:

```ruby
controller do
  def scoped_collection
    Vehicle.with_discarded
  end
end

scope :all,       default: true
scope :kept,      -> { Vehicle.where(discarded_at: nil) }
scope :discarded, -> { Vehicle.discarded }

index do
  selectable_column
  id_column
  column :carrier
  column :plate
  column :capacity_kg
  column :vehicle_type
  column :gps_enabled
  column :discarded_at # NEW
  actions
end
```

**No** restore action wired this sprint (D10). Operator uses `Vehicle.with_discarded.find(id).update!(discarded_at: nil)` from `rails console`.

### 4.8 BE — RSpec coverage

`backend/spec/models/vehicle_spec.rb`:

- `#discard` returns `true` and sets `discarded_at` when no commitments.
- `#discard` returns `false` and adds `errors[:base]` with `:has_active_windows` when `transport_windows.active.exists?`.
- `#discard` returns `false` and adds `errors[:base]` with `:has_pending_commitments` when there is a `CargoOffer` `pending` / `accepted` / `paid` on any window (including `active: false` windows).
- `#discard!` raises `Vehicle::NotDiscardable` on guard failure; same effect as `discard` on success.
- Default scope: `Vehicle.all` excludes discarded; `Vehicle.discarded` returns only discarded; `Vehicle.with_discarded` returns both.
- `belongs_to`: the still-existing hard-delete safety net (`before_destroy :ensure_no_active_commitments`) still aborts `destroy!` when there are live cargo offers.

`backend/spec/models/transport_window_spec.rb`:

- `belongs_to :vehicle`: returns a discarded vehicle via `window.vehicle.reload` (proves the unscope).
- `validate :vehicle_must_be_kept_when_active`: `window.update(active: true)` fails with `:vehicle_must_be_kept_when_active` when `vehicle.discarded?`.
- An `active: false` window pointing at a discarded vehicle survives a `valid?` check (does not trigger AC14).

`backend/spec/requests/api/carriers/me/vehicles_spec.rb`:

- `DELETE /api/carriers/me/vehicles/:id` → 204; vehicle is gone from `GET /api/carriers/me/vehicles`.
- Same endpoint → 422 with `errors.base = [{ error: 'has_active_windows', ... }]` when there is an active window.
- Same endpoint → 422 with `errors.base = [{ error: 'has_pending_commitments', ... }]` when there is a pending cargo offer.
- Same endpoint → 403 (or 404 via scope) when the caller is a different Carrier.
- Hist­orical read: a `Shipment` whose `cargo_offer.transport_window.vehicle` was discarded still serializes the vehicle through whatever Resource references it (smoke spec).

### 4.9 DOC — ADR-009 amendment + diagram comments

**`docs/01-technical-vision/technical-vision.md:106-115`** — append immediately after the existing **Consequences** paragraph:

```markdown
**Amendment 2026-05-22 (REQ-BE-00034)**

- `Vehicle` moves from hard-delete to soft-delete. Reason: the historical chain `Shipment → CargoOffer → TransportWindow → Vehicle` requires the vehicle to remain resolvable after the Carrier removes it from the active fleet (US32). The original rationale ("audit-bearing for fiscal / contractual significance") is broadened to: "audit-bearing **or referenced by historical trip data**".
- Canonical column name is **`discarded_at`** (not `deleted_at`). The original wording of this ADR is superseded; the live implementations (`Shipment`, `Payment`, `ArcaInvoice`, and now `Vehicle`) all use `discarded_at`.
- Updated lists:
  - **Soft-delete**: `Shipment`, `Payment`, `ArcaInvoice`, **`Vehicle`**.
  - **Hard-delete**: `Carrier`, `Shipper`, `TransportWindow`, `CargoOffer`, `Cargo`, `TrackingEvent`, `Route`, `InsurancePolicy`.
- `TransportWindow#vehicle` declares `belongs_to :vehicle, -> { unscope(where: :discarded_at) }` so the historical chain keeps resolving.
```

**`docs/02-high-level-design/domain-model.md`** — add `Vehicle` to the soft-delete table around line 354 with note "since REQ-BE-00034".

**`docs/04-database-diagrams/erd-overview.puml`, `erd-fulfilment.puml`, `erd-marketplace.puml`** — wherever the existing comment lists soft-deleted tables, add `vehicles`.

**`docs/04-database-diagrams/README.md:25`** — change `Soft-delete (`deleted_at`) appears only on `shipments`, `payments`, `arca_invoices` (ADR-009).` to `Soft-delete (`discarded_at`) appears on `shipments`, `payments`, `arca_invoices`, `vehicles` (ADR-009; column renamed in the 2026-05-22 amendment).`.

### 4.10 FE — `frontend/src/api/vehicles.ts`

**Purpose**: typed client for the DELETE.

```ts
// inside the existing api/vehicles.ts module
export type DiscardVehicleErrorKey =
  | "has_active_windows"
  | "has_pending_commitments"
  | "vehicle_not_found"
  | "unauthorized";

export type DiscardVehicleErrorResponse = {
  errors: { base?: Array<{ error: DiscardVehicleErrorKey; message?: string }> };
};

export async function discardVehicle(id: number): Promise<void> {
  const res = await fetchAuthed(`/api/carriers/me/vehicles/${id}`, { method: "DELETE" });
  if (res.status === 204) return;
  if (res.status === 422) {
    const body = (await res.json()) as DiscardVehicleErrorResponse;
    throw new DiscardVehicleError(body.errors.base?.[0]?.error ?? "unknown");
  }
  throw new Error(`Unexpected status ${res.status}`);
}

export class DiscardVehicleError extends Error {
  constructor(public readonly key: string) { super(key); this.name = "DiscardVehicleError"; }
}
```

### 4.11 FE — `frontend/src/pages/carrier/VehicleList.tsx` + new `DiscardVehicleDialog.tsx`

**Purpose**: add the row CTA + confirmation modal (PR #194 / `QuoteInboxPage` pattern).

- Row CTA reads `carrierContent.fleet.list.actions.discard` (locked string: **"Dar de baja"**).
- Modal title: `carrierContent.fleet.discard.title` (**"Dar de baja vehículo"**).
- Confirm: `carrierContent.fleet.discard.confirm` (**"Dar de baja"**).
- Cancel: `carrierContent.fleet.discard.cancel` (**"Cancelar"**).
- On success: dispatch `new CustomEvent('truckr:carrier-vehicle-updated', { detail: { vehicleId } })`. `VehicleList` listens and re-fetches. Show success toast (`carrierContent.fleet.discard.toast.success`).
- On `DiscardVehicleError`: render the localized message via a key→string map in `carrierContent.fleet.discard.errors[key]`. Each non-success error offers a contextual next action:
  - `has_active_windows` → link `Mis Ventanas` (route `/carrier/availability`).
  - `has_pending_commitments` → link bandeja de ofertas (`/carrier/quotes` or current canonical route).

### 4.12 FE — `frontend/src/pages/carrier/carrierContent.ts`

Add the `fleet.discard` block with all the strings above. Single source of UI copy until i18n lib lands (per CLAUDE.md `landingContent.ts` carve-out).

### 4.13 FE — MSW handlers + Vitest + Playwright

- MSW: `rest.delete('/api/carriers/me/vehicles/:id', ...)` with three branches (204, 422 active windows, 422 pending commitments) parameterized via the test scenario.
- Vitest — `VehicleList.test.tsx`: CTA renders per row; click opens modal. `DiscardVehicleDialog.test.tsx`: cancel closes; confirm on 204 dispatches event + closes; confirm on 422 displays each localized message + next-action link.
- Playwright — `e2e/carrier-vehicle-discard.spec.ts`:
  - (a) happy path: seed a Carrier + a Vehicle with no commitments → click "Dar de baja" → confirm → row disappears + toast.
  - (b) blocked path: seed a Vehicle with an active `TransportWindow` → click → confirm → modal stays open with the "ventanas activas" message + the link to "Mis Ventanas".

---

## 5. Test Plan (summary)

| Layer | Coverage |
|-------|----------|
| RSpec model | `discard` / `discard!` happy + each guard; scopes (`discarded`, `with_discarded`, default); `TransportWindow#vehicle` resolves discarded; AC14 validation triggers/skips correctly. |
| RSpec request | 204 happy, 422 per error key, 403/404 cross-carrier, historical read smoke. |
| RSpec admin | `ActiveAdmin::Vehicle` resource lists discarded rows under the `discarded` scope. |
| Vitest | CTA + modal states + 422 mapping per key + event dispatch. |
| Playwright | Happy + active-window blocked. |

Coverage thresholds: `just frontend-test-coverage` (80% lines/functions/branches/statements). `just backend-test` for RSpec. Both must be green locally before opening the PR (CLAUDE.md "Pre-PR UI quality gate" + "expensive CI").

---

## 6. Acceptance Criteria Mapping

| AC | Implementation locus |
|----|----------------------|
| **AC1** "Dar de baja" CTA per row | §4.11 `VehicleList.tsx` + §4.12 `carrierContent.ts` |
| **AC2** Confirmation modal | §4.11 `DiscardVehicleDialog.tsx` (PR #194 pattern) |
| **AC3** Block on active windows | §4.2 `Vehicle#can_be_discarded?` → `:has_active_windows`; §4.6 i18n; §4.11 error surface |
| **AC4** Block on pending commitments | §4.2 `Vehicle#pending_commitments?` → `:has_pending_commitments`; §4.6 i18n; §4.11 error surface |
| **AC5** Hidden from active list, kept for history | §4.2 `default_scope` + §4.3 `belongs_to :vehicle, -> { unscope... }` |
| **AC6** Not selectable for new windows | §4.4 controller already scopes through `current_carrier.vehicles` (default scope filters); §4.3 AC14 validation reinforces |
| **AC7** Hand-rolled ADR-009; `discard` + `discard!` | §4.2 |
| **AC8** Active list hides discarded | §4.2 `default_scope` |
| **AC9** Historical reads resolve | §4.3 `unscope(where: :discarded_at)` |
| **AC10** All copy via i18n keys | §4.6 (BE) + §4.12 (FE) |
| **AC11** Reversibility at data level only | §4.7 `with_discarded` AA scope (no restore action) |
| **AC12** ADR-009 amendment + diagrams | §4.9 |
| **AC13** Glossary already updated in triage PR; Lucas verifies copy matches | Read-only verification step in PR review — no doc edits |
| **AC14** `TransportWindow` invariant | §4.3 `validate :vehicle_must_be_kept_when_active` |

---

## 7. Out of Scope

- **Hard-delete endpoint** — `Vehicle#destroy` stays callable but no new endpoint exposed (D7).
- **ActiveAdmin `undiscard` action / restore UI** — follow-up triage (P3). Operator uses `rails console` for now.
- **"Vehículos archivados" tab for the Carrier** — UI choice deferred.
- **Cascade on `TransportWindow`** — explicitly rejected (D6).
- **Migration to `discard` gem repo-wide** — separate effort owned by repo owner.
- **`Shipment#vehicle` shortcut** — denormalization that would need its own ADR (D4).

---

## 8. Files Summary

### New files

| File | Purpose |
|------|---------|
| `backend/db/migrate/{ts}_add_discarded_at_to_vehicles.rb` | ADR-009 column + B-tree index |
| `frontend/src/pages/carrier/DiscardVehicleDialog.tsx` | Confirmation modal (PR #194 pattern) |
| `frontend/src/pages/carrier/DiscardVehicleDialog.test.tsx` | Vitest for modal states + error surface |
| `frontend/e2e/carrier-vehicle-discard.spec.ts` | Playwright happy + blocked paths |

### Modified files

| File | Changes |
|------|---------|
| `backend/app/models/vehicle.rb` | ADR-009 block + `discard` / `discard!` / `can_be_discarded?` / `pending_commitments?` / `discarded?` |
| `backend/app/models/transport_window.rb` | `belongs_to :vehicle, -> { unscope ... }` + AC14 invariant |
| `backend/app/controllers/api/carriers/me/vehicles_controller.rb` | `destroy` → `vehicle.discard` + 422 rendering |
| `backend/app/policies/vehicle_policy.rb` | Comment update (no behavior change) |
| `backend/app/admin/vehicles.rb` | `scoped_collection` → `with_discarded`; scopes; `discarded_at` column |
| `backend/config/locales/en.yml`, `es.yml` | Three new error keys |
| `backend/spec/models/vehicle_spec.rb`, `transport_window_spec.rb` | Discard / AC14 coverage |
| `backend/spec/requests/api/carriers/me/vehicles_spec.rb` | DELETE 204 / 422 each / 403 |
| `frontend/src/api/vehicles.ts` | `discardVehicle(id)` + typed errors |
| `frontend/src/pages/carrier/VehicleList.tsx` | CTA + event listener |
| `frontend/src/pages/carrier/VehicleList.test.tsx` | CTA + event flow |
| `frontend/src/pages/carrier/carrierContent.ts` | `fleet.discard.*` strings |
| `frontend/src/mocks/handlers.ts` (or equivalent) | DELETE handler (204 / 422) |
| `docs/01-technical-vision/technical-vision.md` | ADR-009 amendment (§4.9) |
| `docs/02-high-level-design/domain-model.md` | Soft-delete table row |
| `docs/04-database-diagrams/erd-overview.puml`, `erd-fulfilment.puml`, `erd-marketplace.puml` | Comment list update |
| `docs/04-database-diagrams/README.md` | Soft-delete sentence updated |

---

## 9. Pre-PR Quality Gate

Per CLAUDE.md (CI is expensive — reproduce locally):

1. `/critique` → `/polish` → `/audit` over `DiscardVehicleDialog.tsx` + the modified row in `VehicleList.tsx`. The destructive-confirmation modal is exactly what `/critique` and `/audit` are for.
2. `just lint` clean (typstyle, stylelint design-system bans, pre-commit hooks).
3. `just frontend-test-coverage` ≥ 80% lines/functions/branches/statements.
4. `just frontend-test-e2e` (Playwright) green.
5. `just backend-test` (RSpec) green.
6. `just build-artifacts` clean (touches `docs/`).
7. `gh pr create --assignee @me --title "feat(carrier): baja de vehículo (soft delete, ADR-009)" --body "...Closes #215..."` — conventional commit subject, **no `[REQ-BE-00034]` bracket prefix** (would break the release-please parse — `.github/workflows/pr-title.yml` blocks it).

---

## 10. Follow-ups (do NOT bundle into this PR)

- New issue: **ActiveAdmin `undiscard` action on `Vehicle`** (P3, BE). Tracked from this issue's "Follow-ups a triagear" section.
- Repo-wide migration to `jhawthorn/discard` gem (owned by the repo owner).
