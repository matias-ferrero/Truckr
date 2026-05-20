# REQ-BE-00032: Cargo fullstack — modelo, endpoints, FSM + "Mis cargas" UI (US27)

| Field | Value |
|-------|-------|
| **Tag** | REQ-BE-00032 |
| **Title** | Cargo fullstack — modelo, endpoints, FSM + "Mis cargas" UI (US27) |
| **Priority** | P1 |
| **Status** | IN REVIEW |
| **Created** | 2026-05-19 |
| **Updated** | 2026-05-19 |
| **Author** | Claude Code |
| **Depends On** | **None blocking** (verified 2026-05-19). `REF-BE-00002` is DONE — merged via PR #204; `Cargo`/`CargoOffer` models + `cargos`/`cargo_offers` tables are on `main`. `INF-FE-00003` routing is already effectively present. This issue is ready to implement. |
| **Decision Doc** | N/A |
| **Selected Approach** | N/A — the one architectural fork (matching algorithm) was resolved by user directive 2026-05-19: **defer Haversine + lat/lng until the GMaps integration lands** (`REQ-FE-00009`); this issue ships **zone-string matching** only. |

---

## 1. Problem Statement

US27 — a Shipper publishes a `Cargo` (a cargo to be moved) and sees which `TransportWindow`s could carry it. Today there is no API path for this and no UI: the funnel `US27 → US4 → US5 → US6 → US7` is cut at the root.

This issue lands, in one fullstack PR:

- **Backend**: the `Cargo` publication lifecycle (`open / accepted / cancelled` FSM), the six `/api/cargos` endpoints, the soft-cancel cascade, and a **zone-based** matching endpoint (`GET /api/cargos/:id/matches`).
- **Frontend**: the `/shipper/cargos[/new|/:id[/edit]]` route subtree — "Mis cargas" list, publication form, detail view with matches + offers, and soft-cancel.
- **`REQ-FE-00015` remediation**: fix the conflated `POST /api/cargo_offers` (which inline-creates a `Cargo`) so the request instead carries a `cargo_id` and the `CargoOffer` bids against an *existing* `Cargo`, and rework the US7 offer wizard into the cargo-first flow — see §2.7.

It is filed fullstack because the JSON contract between the two sides does not stabilise without both ends in the same PR (precedent: `REQ-BE-00023`, auth fullstack).

### Scope boundary — Haversine deferred

The issue body specifies the matching algorithm as Haversine over `origin_lat/lng`, `destination_lat/lng`, and `pickup_radius_km`. **None of those columns exist** and there is no real geo data: the shipped `transport_windows` table is zone-string based (`origin_zone` / `destination_zone` + transliterated `*_normalized` columns), and the merged carrier search already matches on those zones.

Per user directive (2026-05-19): **Haversine matching, lat/lng columns, and `distance_km` are out of scope** for this issue. They are deferred to a follow-up that depends on the Google Maps integration (`REQ-FE-00009`), which is what will actually produce reliable coordinates. This issue ships **zone-string matching** — the same dimensions the existing carrier search uses — so the funnel is unblocked without speculative geo columns.

### Dependency status (verified against `main` 2026-05-19)

The issue body's "Sequencing" assumptions are **stale**. Actual state:

- **`REF-BE-00002` — DONE.** Issue #197 closed; merged via **PR #204** (`refactor(domain): rename Quote→CargoOffer y CargoOffer→Cargo`). On `main`: models `cargo.rb` (publication) + `cargo_offer.rb` (bid); tables `cargos` + `cargo_offers`; `Shipment belongs_to :cargo_offer`. No longer a blocker.
- **PR #193 (`REQ-FE-00015`) — MERGED un-split.** The planned split of `POST /api/quotes` into `POST /api/cargos` + `POST /api/cargos/:id/offers` **never happened**. PR #204 only *renamed* `POST /api/quotes` → **`POST /api/cargo_offers`**, and that action still **inline-creates a `Cargo`** (`Api::CargoOffersController#create` runs `Cargo.create!` + `CargoOffer.create!` in one transaction).
- **`INF-FE-00003`** — `src/routes.tsx` + guards already exist; only the `/shipper/cargos*` subtree is missing. Effectively present.

**Consequence for this issue:** there is no `POST /api/cargos` and no `cargos_controller.rb` — creating them is this issue's job. **And** `REQ-FE-00015` shipped a non-compliant offer flow — the merged `Api::CargoOffersController#create` inline-creates a `Cargo`, and `CreateOfferPage` is a standalone wizard that collects cargo fields and posts the conflated payload. Per user directive (2026-05-19), **remediating `REQ-FE-00015` into the Cargo-first funnel is now in scope for this issue** — see §2.7. Effort is consequently **XL**, not L.

---

## 2. Solution Design

### 2.1 Schema reconciliation (the issue was written against an imagined schema)

The issue body assumes a schema that does not exist. The plan reconciles each gap against the **real** post-`REF-BE-00002` schema:

| Issue assumes | Reality (post-`REF-BE-00002`) | Plan decision |
|---|---|---|
| `cargos.status` (`open/accepted/cancelled`) | column absent | **add** `status:string` not-null default `"open"`, indexed |
| `cargos.pickup_window_start/end` | only single `pickup_date` | **add** the two `datetime` columns; backfill from `pickup_date`; then drop `pickup_date` |
| `Cargo` origin/destination `lat/lng` | absent | **NOT added** — deferred with Haversine (GMaps follow-up) |
| `Cargo` origin/destination zone | `cargos` has free-text `pickup_address` / `delivery_address` only | **add** `pickup_zone` / `delivery_zone` (+ transliterated `*_normalized`), mirroring `TransportWindow` |
| `TransportWindow.pickup_radius_km`, `lat/lng` | absent (zone-string model) | **NOT added** — out of scope; matching is zone-substring |
| `window.max_load_kg` | capacity lives on `Vehicle.max_load_kg`, not the window | matching joins `:vehicle` and compares `vehicles.max_load_kg` |
| Window statuses `pending_offer / reserved / closed` | `TransportWindow` has only an `active` boolean — no status FSM | "available window" is **derived**: `active: true` AND no associated `CargoOffer` in `pending`/`accepted` |
| `volume_m3` optional | `volume_cm3` exists, `null: false` | keep `volume_cm3` (unit consistency); make it **nullable** |

**Naming note:** `cargos` keeps the existing `pickup_*` / `delivery_*` column prefix (already on the table). The matching maps `cargo.pickup_zone ↔ window.origin_zone` and `cargo.delivery_zone ↔ window.destination_zone`.

### 2.2 `Cargo` FSM — hand-rolled, mirrors `Shipment`

No `aasm` gem in the repo; both `Quote` and `Shipment` use a hand-rolled transition table. `Cargo` follows the **`Shipment` pattern** (transaction + row lock + timestamp stamping):

```
open ──▶ accepted    (triggered by REQ-BE-00024 / US12 when a CargoOffer is accepted — out of scope here, but the transition must exist)
open ──▶ cancelled   (Shipper soft-cancel, only when no accepted CargoOffer)
accepted, cancelled  → terminal
```

There is **no intermediate `offered` state** (decision locked 2026-05-19): a `Cargo` stays `open` while it has `pending` offers and only becomes `accepted` when one is accepted.

### 2.3 Matching — zone-string, on-demand

`GET /api/cargos/:id/matches` mirrors `Api::TransportWindowsController#index` (Ransack over normalized zone columns). A `TransportWindow` is a match when **all** hold:

1. `window.active == true`;
2. the window has **no** associated `CargoOffer` in `pending` or `accepted` (derived availability — replaces the imagined `pending_offer/reserved/closed` exclusion; enforced symmetrically at offer-create, see §2.7 "window-lock");
3. `window.origin_zone_normalized` contains `cargo.pickup_zone_normalized` **and** `window.destination_zone_normalized` contains `cargo.delivery_zone_normalized`;
4. date overlap: `window.available_from <= cargo.pickup_window_end` **and** `window.available_to >= cargo.pickup_window_start`;
5. capacity: `window.vehicle.max_load_kg >= cargo.weight_kg`.

No cache — recalculated on demand. No `distance_km` in the response (no geo data). Result is paginated (Pagy) and ordered by `available_from`.

### 2.4 Soft-cancel cascade (`DELETE /api/cargos/:id`)

In one transaction: `cargo.transition_to!(:cancelled)`; every `pending` sibling `CargoOffer` gets `transition_to!(:expired)`. Windows need **no explicit write** — window availability is derived (§2.3 rule 2), so expiring the pending offers makes those windows match again automatically. Blocked when any `CargoOffer` is `accepted`.

### 2.5 Backend pattern conformance

- Controller `Api::CargosController < Api::BaseController` — uses the standard error envelope `{ error: { code, message?, details? } }`, `authenticate_user!`, `require_shipper!`, Pundit `authorize` / `policy_scope`, Pagy via `render_collection`.
- Serializers: **Alba** resources (`CargoResource`, `CargoMatchResource`).
- Authorization: `CargoPolicy` + `Policy::Scope` — a Shipper only ever sees their own `Cargo`s (`policy_scope` filters by `shipper_id`).
- i18n: validation messages via symbolic keys resolved from `config/locales/cargos.{es,en}.yml`; zero hardcoded Spanish in code.

### 2.6 Frontend pattern conformance & deferred decisions

The issue defers two choices to "decidir en plan":

- **i18n** → **keep the `*Content.ts` pattern** (`features/cargo/cargosContent.ts`). Introducing a real i18n library is out of scope — it has no ADR, and CLAUDE.md's carve-out explicitly sanctions the `*Content.ts` bundle until a library lands. Routes stay English; all copy goes through the content module.
- **Form library** → **plain `useState` + inline validators**, mirroring the existing `CreateOfferPage` wizard. `react-hook-form` + `zod` are *not installed*; adding them needs an ADR and would make the new form inconsistent with every other form in the repo (`CreateOfferPage`, vehicle/window CRUD all use plain state). "Alinear con `REQ-FE-00016`" therefore means the plain-state pattern. The issue's `zod` suggestion is recorded here as a **deliberate deviation** — note it in the PR description.

Other FE specifics: React Router subtree under `RequireShipper`; reuse the structured address sub-form (`street/number/floor/postal_code/city/province`) and `ui/` primitives from `CreateOfferPage`; API via `apiFetch` (`src/api.ts`) with the automatic `Authorization: Bearer` header; `features/cargo/` is the first `features/` module (aligns with `INF-FE-00003`'s feature-based intent).

### 2.7 `REQ-FE-00015` remediation — cargo-first offer flow

`REQ-FE-00015` (PR #193) shipped before the 2026-05-19 domain reframe and is **not compliant** with the Cargo-first model this issue establishes: `Api::CargoOffersController#create` inline-creates a `Cargo` from the same payload as the `CargoOffer`, and `CreateOfferPage` is a standalone 3-step wizard (`/carriers/:id/offers/new`) that collects every cargo field. A `Cargo` is therefore never a *published* entity the Shipper manages in "Mis cargas" — it is a side effect of bidding.

This issue remediates it so a `CargoOffer` always bids against an **already-published** `Cargo`:

**Backend — keep the flat route, change the payload.**
- `POST /api/cargo_offers` stays as-is — no nesting under `cargos`, no route added or removed. The fix is to the request *body*: it now carries a `cargo_id` referencing an existing `Cargo` instead of inline cargo fields. This is consistent with how `transport_window_id` already rides in the body.
- `CargoOffersController#create` no longer creates a `Cargo`: it loads the `Cargo` from `cargo_offer_params[:cargo_id]`, loads the `TransportWindow`, and creates **only** the `CargoOffer`. `cargo_offer_params` permits `:cargo_id`, `:transport_window_id`, `:estimated_km` — the `cargo_attrs` builder and the `Cargo.create!` call are deleted.
- Authorization: the offering `current_shipper` must own the referenced `Cargo` (`CargoPolicy#offer?` — `record.shipper_id == user.shipper&.id`).
- `GET /api/cargo_offers#index` is unchanged. `resources :cargo_offers, only: %i[index create]` stays exactly as it is on `main`.

**Backend — validation coupling.** `CargoOffer` inherits a cross-record validation from the pre-rename `Quote` (`pickup_date_within_window`) that reads `cargo.pickup_date` — a column this issue **drops** (§4.1). It must be retargeted to overlap `cargo.pickup_window_start..pickup_window_end` against `window.available_from..available_to`. The capacity validation that reads `cargo.volume_cm3` must tolerate `nil` (volume is now optional).

**Backend — window-lock.** `CargoOffer` gains a create-time validation: the chosen `TransportWindow` must hold **no** other `CargoOffer` in `pending`/`accepted` — `422` otherwise. This makes the §2.3 rule-2 exclusion *authoritative*: a stale match list, a concurrent shipper, or a direct API call cannot stack a second offer onto an already-contended window. SQLite serialises writes, so the check inside the create transaction is race-safe with no explicit row lock (CLAUDE.md concurrency policy — solved at the application layer, not deferred).

**Frontend — cargo-scoped wizard.**
- Offer creation moves to `/shipper/cargos/:id/offers/new?window=:windowId`, reached from the `MatchCard` "Ofertar" CTA on the Cargo detail. The old `/carriers/:id/offers/new` route is removed.
- `CreateOfferPage` is refactored from 3 steps (Addresses, Cargo, Date+Budget) to **one** confirm step: it loads the `Cargo` + the target `TransportWindow`, shows read-only summaries of both, collects `estimated_km`, shows the cost estimate, and posts `{ cargo_offer: { cargo_id, transport_window_id, estimated_km } }` to `POST /api/cargo_offers`. The address and cargo-field steps are deleted — that data already lives on the published `Cargo`.
- `frontend/src/api/quotes.ts` is renamed `frontend/src/api/cargoOffers.ts`; `createCargoOffer` takes `(cargoId, draft)` and posts to the flat `/api/cargo_offers` with `cargo_id` in the body; `listMyCargoOffers` is unchanged. `DashboardPage` updates its import.

### Key Components

| Component | Responsibility |
|---|---|
| `Cargo` model | FSM, validations, associations, zone normalization, scopes |
| `Api::CargosController` | `index / show / create / update / destroy / matches` |
| `CargoResource` / `CargoMatchResource` | Alba serialization (cargo + nested offers / window + carrier) |
| `CargoPolicy` | shipper-only ownership authorization (incl. `offer?`) |
| `Api::CargoOffersController` (refactored) | `POST /api/cargo_offers` now takes a `cargo_id` — bids against an existing `Cargo` (`REQ-FE-00015` remediation) |
| `features/cargo/*` (FE) | typed API client, list, form (new/edit), detail, match card |
| `CreateOfferPage` (refactored) | one-step cargo-scoped offer confirm (`REQ-FE-00015` remediation) |

---

## 3. Implementation Tasks

| # | Task | Status | Files |
|---|------|--------|-------|
| 1 | Migration: add `status`, `pickup_window_start/end`, `pickup_zone`/`delivery_zone` (+normalized), `cancelled_at`, `cancellation_reason`; backfill + drop `pickup_date`; make `volume_cm3` nullable | Pending | `backend/db/migrate/<ts>_add_cargo_publication_fields.rb`, `backend/db/schema.rb` |
| 2 | `Cargo` model: FSM (`transition_to!`), validations, `has_many :cargo_offers, dependent: :destroy`, `has_one :accepted_cargo_offer`, zone-normalize callback, scopes | Pending | `backend/app/models/cargo.rb` |
| 3 | `Api::CargosController` — 6 actions; strong params; soft-cancel cascade tx | Pending | `backend/app/controllers/api/cargos_controller.rb` |
| 4 | Routes: `resources :cargos` + `get :matches, on: :member` | Pending | `backend/config/routes.rb` |
| 5 | `CargoPolicy` + `Policy::Scope` (shipper-only) | Pending | `backend/app/policies/cargo_policy.rb` |
| 6 | Alba resources: `CargoResource`, `CargoMatchResource` | Pending | `backend/app/resources/cargo_resource.rb`, `cargo_match_resource.rb` |
| 7 | Backend i18n locale files | Pending | `backend/config/locales/cargos.es.yml`, `cargos.en.yml` |
| 8 | Backend specs: model spec, request/rswag specs for 6 endpoints; update `:cargo` factory | Pending | `backend/spec/models/cargo_spec.rb`, `backend/spec/requests/api/cargos_spec.rb`, `backend/spec/factories/cargos.rb` |
| 9 | FE domain types | Pending | `frontend/src/types/Cargo.ts` |
| 10 | FE typed API client | Pending | `frontend/src/features/cargo/api.ts` |
| 11 | FE content bundle (i18n) | Pending | `frontend/src/features/cargo/cargosContent.ts` |
| 12 | FE `CargoList` — cards, status filter, paging, empty state | Pending | `frontend/src/features/cargo/CargoList.tsx` |
| 13 | FE `CargoForm` — shared new/edit, validation, POST/PATCH | Pending | `frontend/src/features/cargo/CargoForm.tsx` |
| 14 | FE `CargoDetail` + `MatchCard` — header, matches section, offers section, actions, cancel modal | Pending | `frontend/src/features/cargo/CargoDetail.tsx`, `MatchCard.tsx` |
| 15 | Routes: mount `/shipper/cargos[/new|/:id[/edit]]` under `RequireShipper`; 403 for non-Shipper | Pending | `frontend/src/routes.tsx`, `frontend/src/auth/RequireShipper.tsx` |
| 16 | FE unit/component specs (≥80% coverage on new files) + MSW handlers | Pending | `frontend/src/features/cargo/*.test.tsx`, `frontend/src/test/mocks/handlers.ts` |
| 17 | Playwright E2E golden path | Pending | `frontend/e2e/shipper-cargo.spec.ts` |
| 18 | `/critique` → `/polish` → `/audit` on new screens; resolve findings | Pending | `frontend/src/features/cargo/*` |
| 19 | **`REQ-FE-00015` BE remediation**: refactor `CargoOffersController#create` to take a `cargo_id` param and bid against an existing `Cargo` (drop `cargo_attrs` + `Cargo.create!`); `POST /api/cargo_offers` route unchanged | Pending | `backend/app/controllers/api/cargo_offers_controller.rb` |
| 20 | `CargoOffer` validations: retarget `pickup_date_within_window` → `pickup_window_*` overlap; capacity check tolerates `nil` volume; **add window-lock** (reject create if the window already has a `pending`/`accepted` offer) | Pending | `backend/app/models/cargo_offer.rb` |
| 21 | `CargoPolicy#offer?` — Shipper must own the cargo being bid on | Pending | `backend/app/policies/cargo_policy.rb`, `cargo_offer_policy.rb` |
| 22 | Update `cargo_offers` request specs for the `cargo_id`-based create + ownership 403 + "no `Cargo` created" assertion | Pending | `backend/spec/requests/api/cargo_offers_spec.rb` |
| 23 | **`REQ-FE-00015` FE remediation**: refactor `CreateOfferPage` to the 1-step cargo-scoped confirm flow; rename `api/quotes.ts` → `api/cargoOffers.ts`; update `DashboardPage` import | Pending | `frontend/src/pages/shipper/CreateOfferPage.tsx`, `frontend/src/api/cargoOffers.ts`, `frontend/src/pages/dashboard/DashboardPage.tsx` |
| 24 | Routes: add `/shipper/cargos/:id/offers/new`, remove `/carriers/:id/offers/new`; `MatchCard` CTA targets the new route | Pending | `frontend/src/routes.tsx`, `frontend/src/features/cargo/MatchCard.tsx` |
| 25 | Update `CreateOfferPage` + offer-api specs and the offer E2E for the cargo-first flow | Pending | `frontend/src/pages/shipper/CreateOfferPage.test.tsx`, `frontend/src/api/cargoOffers.test.ts`, `frontend/e2e/shipper-cargo.spec.ts` |

---

## 4. Code Changes

### 4.1 `backend/db/migrate/<ts>_add_cargo_publication_fields.rb` (new)

**Purpose:** the `cargos` table delta. SQLite-portable (Rails rebuilds the table for `change_column_null` / `remove_column`).

```ruby
class AddCargoPublicationFields < ActiveRecord::Migration[8.1]
  def up
    add_column :cargos, :status, :string, null: false, default: "open"
    add_index  :cargos, :status

    add_column :cargos, :pickup_window_start, :datetime
    add_column :cargos, :pickup_window_end,   :datetime

    add_column :cargos, :pickup_zone,              :string
    add_column :cargos, :delivery_zone,            :string
    add_column :cargos, :pickup_zone_normalized,   :string
    add_column :cargos, :delivery_zone_normalized, :string
    add_index  :cargos, :pickup_zone_normalized
    add_index  :cargos, :delivery_zone_normalized

    add_column :cargos, :cancelled_at,        :datetime
    add_column :cargos, :cancellation_reason, :string

    # Single pickup_date → pickup window. Backfill collapses both bounds onto the old date.
    execute "UPDATE cargos SET pickup_window_start = pickup_date, pickup_window_end = pickup_date"
    change_column_null :cargos, :pickup_window_start, false
    change_column_null :cargos, :pickup_window_end,   false
    remove_column :cargos, :pickup_date, :datetime

    change_column_null :cargos, :volume_cm3, true # US27: volume optional
  end

  def down
    add_column :cargos, :pickup_date, :datetime
    execute "UPDATE cargos SET pickup_date = pickup_window_start"
    change_column_null :cargos, :pickup_date, false
    change_column_null :cargos, :volume_cm3, false
    remove_column :cargos, :status, :pickup_window_start, :pickup_window_end,
                  :pickup_zone, :delivery_zone, :pickup_zone_normalized,
                  :delivery_zone_normalized, :cancelled_at, :cancellation_reason
  end
end
```

### 4.2 `backend/app/models/cargo.rb` (modified — `REF-BE-00002` creates the class, this issue adds the lifecycle)

**Purpose:** FSM, validations, associations, zone normalization.

```ruby
class Cargo < ApplicationRecord
  class IllegalTransition < StandardError; end

  STATUSES = %w[open accepted cancelled].freeze
  ALLOWED_TRANSITIONS = {
    open:      [ :accepted, :cancelled ],
    accepted:  [],
    cancelled: []
  }.freeze

  belongs_to :shipper, inverse_of: :cargos
  has_many   :cargo_offers, dependent: :destroy, inverse_of: :cargo
  has_one    :accepted_cargo_offer, -> { where(status: "accepted") },
             class_name: "CargoOffer", inverse_of: :cargo

  before_save :normalize_zone_fields

  validates :cargo_description, presence: true, length: { maximum: 200 }
  validates :pickup_address, :delivery_address, :pickup_zone, :delivery_zone, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :weight_kg, numericality: { greater_than: 0 }
  validates :volume_cm3, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validates :declared_value_cents, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :pickup_window_start, :pickup_window_end, presence: true
  validate  :pickup_window_is_coherent

  scope :for_shipper, ->(shipper) { where(shipper_id: shipper.id) }
  scope :with_status, ->(s) { s.present? ? where(status: s) : all }

  def editable?    = status == "open" && accepted_cargo_offer.nil?
  def cancellable? = status == "open" && accepted_cargo_offer.nil?

  # Mirrors Shipment#transition_to! — transaction + row lock + timestamp stamping.
  def transition_to!(new_status, reason: nil, at: Time.current)
    new_status = new_status.to_sym
    transaction do
      with_lock do
        from = status.to_sym
        unless ALLOWED_TRANSITIONS.fetch(from, []).include?(new_status)
          raise IllegalTransition, "Cargo #{id}: #{from} -> #{new_status} not allowed"
        end
        attrs = { status: new_status.to_s }
        if new_status == :cancelled
          attrs[:cancelled_at] = at
          attrs[:cancellation_reason] = reason
        end
        update!(attrs)
      end
    end
  end

  private

  def normalize_zone_fields
    self.pickup_zone_normalized   = I18n.transliterate(pickup_zone.to_s).downcase   if pickup_zone.present?
    self.delivery_zone_normalized = I18n.transliterate(delivery_zone.to_s).downcase if delivery_zone.present?
  end

  def pickup_window_is_coherent
    return if pickup_window_start.blank? || pickup_window_end.blank?
    errors.add(:pickup_window_end, :must_be_after_start) if pickup_window_end <= pickup_window_start
  end
end
```

> `Shipper` must gain `has_many :cargos` (currently `has_many :cargo_offers` post-`REF-BE-00002`). Add `has_many :cargos, inverse_of: :shipper` to `backend/app/models/shipper.rb`.
> The `open → accepted` transition is exercised by `REQ-BE-00024` (US12); this issue only defines it. The `CargoOffer#transition_to!(:expired)` call in the cancel cascade relies on the bid model's `pending → expired` edge (already present in the pre-rename `Quote` FSM).

### 4.3 `backend/app/controllers/api/cargos_controller.rb` (new)

**Purpose:** the six endpoints + soft-cancel cascade.

```ruby
module Api
  class CargosController < Api::BaseController
    before_action :authenticate_user!
    before_action :require_shipper!
    before_action :set_cargo, only: %i[show update destroy matches]

    def index
      render_collection(CargoResource, policy_scope(Cargo)
        .with_status(params[:status]).order(created_at: :desc))
    end

    def show
      authorize @cargo
      render json: CargoResource.new(@cargo).serialize
    end

    def create
      authorize Cargo
      cargo = current_shipper.cargos.create!(cargo_params)
      @pagy, matches = pagy(matches_scope(cargo))
      render json: CargoResource.new(cargo, params: { matches: matches }).serialize,
             status: :created
    end

    def update
      authorize @cargo
      return render_error(code: "cargo_locked", status: :unprocessable_entity,
        details: { status: [ "no editable" ] }) unless @cargo.editable?
      @cargo.update!(cargo_params)
      render json: CargoResource.new(@cargo).serialize
    end

    def destroy
      authorize @cargo
      return render_error(code: "cargo_locked", status: :unprocessable_entity,
        details: { status: [ "no cancelable" ] }) unless @cargo.cancellable?
      ActiveRecord::Base.transaction do
        @cargo.transition_to!(:cancelled, reason: params[:reason])
        @cargo.cargo_offers.where(status: "pending").find_each { |o| o.transition_to!(:expired) }
      end
      head :no_content
    end

    def matches
      authorize @cargo
      render_collection(CargoMatchResource, matches_scope(@cargo))
    end

    private

    def set_cargo = (@cargo = Cargo.find(params[:id]))

    def cargo_params
      params.require(:cargo).permit(
        :cargo_description, :pickup_address, :delivery_address,
        :pickup_zone, :delivery_zone, :pickup_window_start, :pickup_window_end,
        :weight_kg, :volume_cm3, :declared_value_cents
      )
    end

    # Zone-string matching — see plan §2.3. No Haversine, no distance_km.
    def matches_scope(cargo)
      blocked = CargoOffer.where(status: %w[pending accepted]).select(:transport_window_id)
      TransportWindow.active.where.not(id: blocked)
        .ransack(
          origin_zone_normalized_cont:      cargo.pickup_zone_normalized,
          destination_zone_normalized_cont: cargo.delivery_zone_normalized,
          available_from_lteq:              cargo.pickup_window_end,
          available_to_gteq:                cargo.pickup_window_start
        ).result(distinct: true)
        .joins(:vehicle).where("vehicles.max_load_kg >= ?", cargo.weight_kg)
        .includes(vehicle: :carrier).order(:available_from)
    end
  end
end
```

> `CargoPolicy#show?/update?/destroy?/matches?` must verify `record.shipper_id == user.shipper&.id` so a Shipper cannot touch another's cargo (→ 403 via the `Pundit::NotAuthorizedError` rescue).

### 4.4 `backend/config/routes.rb` (modified)

```ruby
namespace :api do
  # ... existing ...
  resources :cargos, only: %i[index show create update destroy] do
    get :matches, on: :member
  end
  # Unchanged. The REQ-FE-00015 remediation is a payload change, not a route
  # change: #create now takes a `cargo_id` for an existing Cargo (no inline create).
  resources :cargo_offers, only: %i[index create]
end
```

### 4.5 `backend/app/resources/cargo_resource.rb` + `cargo_match_resource.rb` (new)

**Purpose:** Alba serialization. `CargoResource` optionally embeds initial `matches` (for the `create` response) and nests its `cargo_offers` with the target window.

```ruby
class CargoResource
  include Alba::Resource

  attributes :id, :shipper_id, :status, :cargo_description,
             :pickup_address, :delivery_address, :pickup_zone, :delivery_zone,
             :pickup_window_start, :pickup_window_end,
             :weight_kg, :volume_cm3, :declared_value_cents,
             :cancelled_at, :created_at, :updated_at

  attribute :editable, &:editable?
  attribute :pending_offers_count { |c| c.cargo_offers.count { |o| o.status == "pending" } }

  many :cargo_offers, resource: CargoOfferResource # status + target window summary

  attribute :matches do |_cargo, params|
    next nil unless params&.key?(:matches)
    CargoMatchResource.new(params[:matches]).to_h
  end
end
```

`CargoMatchResource` serializes a `TransportWindow` + its vehicle + carrier (name, rating). **No `distance_km`** — deferred with Haversine.

### 4.6 `backend/config/locales/cargos.es.yml` (new)

```yaml
es:
  activerecord:
    errors:
      models:
        cargo:
          attributes:
            pickup_window_end:
              must_be_after_start: "debe ser posterior al inicio de la ventana"
            cargo_description:
              too_long: "no puede superar los 200 caracteres"
  errors:
    cargo_locked: "La carga no se puede modificar en su estado actual"
```

(`cargos.en.yml` mirrors it for parity with the existing `en.yml`.)

### 4.7 Frontend — `frontend/src/features/cargo/` (new module)

- **`types/Cargo.ts`** — `CargoStatus = "open" | "accepted" | "cancelled"`; `Cargo`, `CargoOffer`, `CargoMatch` interfaces (snake_case keys, matching the serializers). First domain types in the FE — set the convention.
- **`api.ts`** — typed client over `apiFetch`: `listCargos(status?)`, `getCargo(id)`, `createCargo(draft)`, `updateCargo(id, draft)`, `cancelCargo(id, reason?)`, `getMatches(id)`. Maps `ApiError.details` → field errors.
- **`cargosContent.ts`** — typed copy bundle (es-AR), same shape as `offerContent.ts`.
- **`CargoList.tsx`** — cards: short description, `pickup_zone → delivery_zone`, pickup window date, status badge, `pending_offers_count`; status filter (`open/accepted/cancelled/all`); Pagy paging; empty state with "Publicá tu primera carga" CTA; top-right "Publicar carga" button.
- **`CargoForm.tsx`** — shared new/edit; structured pickup + delivery address sub-form (reuse `CreateOfferPage`'s `AddressDraft`) + zone fields + pickup-window start/end (`end > start`) + weight + volume (optional) + declared value; plain `useState` validation; submit → `POST`/`PATCH` → redirect to detail; server-error mapping into field `Alert`s.
- **`CargoDetail.tsx`** — header (fields + Editar/Cancelar gated on `editable`); **Matches** section (`getMatches`) of `MatchCard`s; **Mis ofertas** section (nested `cargo_offers`); `accepted` → winning carrier block; `cancelled` → badge; cancel confirm modal (focus-trapped, `Esc`-dismissable) warning that pending offers will be expired.
- **`MatchCard.tsx`** — window + carrier (name, rating) + capacity; "Ofertar" CTA → `/shipper/cargos/:id/offers/new?window=:windowId` (the remediated cargo-first offer flow — §2.7 / §4.10). No distance shown.

### 4.8 `frontend/src/routes.tsx` (modified)

```tsx
const CargoList   = lazy(() => import("./features/cargo/CargoList"));
const CargoForm   = lazy(() => import("./features/cargo/CargoForm"));
const CargoDetail = lazy(() => import("./features/cargo/CargoDetail"));

// inside <Routes>, each wrapped in <RequireShipper> + <Suspense>:
<Route path="/shipper/cargos"           element={/* RequireShipper → CargoList      */} />
<Route path="/shipper/cargos/new"       element={/* RequireShipper → CargoForm       */} />
<Route path="/shipper/cargos/:id"       element={/* RequireShipper → CargoDetail     */} />
<Route path="/shipper/cargos/:id/edit"  element={/* RequireShipper → CargoForm       */} />
<Route path="/shipper/cargos/:id/offers/new"
                                        element={/* RequireShipper → CreateOfferPage  */} />
// REMOVED — superseded by the cargo-scoped offer route above:
// <Route path="/carriers/:id/offers/new" ... />
```

`RequireShipper` already redirects unauthenticated → `/login`. For "authenticated but not Shipper", replace the current silent `Navigate to="/"` with a visible 403 view (small `Forbidden` component) so the AC's "403 page" is met.

### 4.9 `backend/app/controllers/api/cargo_offers_controller.rb` (modified — `REQ-FE-00015` remediation)

**Purpose:** stop inline-creating a `Cargo`; bid against an existing one.

```ruby
module Api
  class CargoOffersController < Api::BaseController
    before_action :authenticate_user!
    before_action :require_shipper!, only: :create

    def index # unchanged
      render_collection(CargoOfferResource,
        policy_scope(CargoOffer).includes(:cargo).order(created_at: :desc))
    end

    # POST /api/cargo_offers
    # body: { cargo_offer: { cargo_id, transport_window_id, estimated_km } }
    def create
      cargo  = Cargo.find(cargo_offer_params[:cargo_id])
      authorize cargo, :offer?            # current_shipper must own the cargo
      window = TransportWindow.active.includes(vehicle: :carrier)
                              .find(cargo_offer_params[:transport_window_id])
      offer = CargoOffer.create!(
        cargo: cargo, carrier: window.carrier, transport_window: window,
        currency: "ARS", status: "pending",
        estimated_km: cargo_offer_params[:estimated_km]
      )
      CargoOfferMailer.notify_carrier(offer).deliver_later
      render json: CargoOfferResource.new(offer).serialize, status: :created
    end

    private

    def cargo_offer_params
      params.require(:cargo_offer).permit(:cargo_id, :transport_window_id, :estimated_km)
    end
  end
end
```

> The `cargo_attrs` builder and the `Cargo.create!` call are **deleted**. `CargoOffer`'s `pickup_date_within_window` validation must be retargeted to `cargo.pickup_window_start..pickup_window_end` (the `pickup_date` column is dropped by §4.1), and the capacity check must tolerate a `nil` `cargo.volume_cm3`. `CargoOffer` also gains a create-time **window-lock** validation — the target `TransportWindow` must have no other `pending`/`accepted` offer (§2.7) — e.g. `validate :window_not_already_taken, on: :create` checking `transport_window.cargo_offers.where(status: %w[pending accepted]).exists?`.

### 4.10 `frontend/src/pages/shipper/CreateOfferPage.tsx` (modified — `REQ-FE-00015` remediation)

**Purpose:** the offer wizard becomes cargo-scoped — it bids an existing `Cargo` against a chosen `TransportWindow`.

- Route `/shipper/cargos/:id/offers/new?window=:windowId`, reached from the Cargo-detail `MatchCard`.
- On mount: `getCargo(id)` + the chosen `TransportWindow` (passed via router state from the match list, with a refetch fallback).
- The 3 steps (Addresses, Cargo, Date+Budget) collapse to **one** confirm step: read-only cargo summary + read-only window/carrier summary + an `estimated_km` input + the derived cost estimate.
- Submit → `createCargoOffer(cargoId, { transport_window_id, estimated_km })` → `POST /api/cargo_offers` with `{ cargo_offer: { cargo_id, transport_window_id, estimated_km } }` → redirect to `/shipper/cargos/:id` (the offer appears under "Mis ofertas").
- `frontend/src/api/quotes.ts` → renamed `frontend/src/api/cargoOffers.ts`; `createCargoOffer` signature becomes `(cargoId, draft)`; `listMyCargoOffers` unchanged; `DashboardPage` import updated.
- The address + cargo-field steps and the `/carriers/:id/offers/new` entry point are deleted.

---

## 5. Testing

### Backend (RSpec + rswag)

**Model spec** (`spec/models/cargo_spec.rb`):
- validations: `cargo_description` presence + 200-char cap; `weight_kg > 0`; `volume_cm3` nullable; `pickup_window_end > start`.
- FSM: `open → accepted` ok; `open → cancelled` ok; `accepted`/`cancelled` terminal raise `IllegalTransition`; `cancelled` stamps `cancelled_at` + `cancellation_reason`.
- associations: `cargo_offers` `dependent: :destroy`; `accepted_cargo_offer` returns only the accepted bid.
- `editable?` / `cancellable?` false once an accepted offer exists.
- zone-normalize callback transliterates (`"Córdoba"` → `"cordoba"`).

**Request specs** (`spec/requests/api/cargos_spec.rb`, rswag) — for the 6 endpoints:
- happy paths: `POST` 201 (body includes `matches`), `GET` index/show 200, `PATCH` 200, `DELETE` 204.
- `401` with no JWT; `403` when the user is not a Shipper, and when the cargo belongs to another Shipper.
- `422`: `weight_kg <= 0`, `pickup_window_end < start`, missing required params; `PATCH`/`DELETE` blocked when an offer is `accepted`.
- `DELETE` cascade: `pending` sibling `CargoOffer`s become `expired`; their windows reappear in `matches`.
- `matches`: excludes `active: false` windows and windows with a `pending`/`accepted` offer; filters by zone substring, date overlap, and `vehicle.max_load_kg`.
- `grep -rn '\bQuote\b\|/api/quotes' backend/app` returns no domain hits.

### Frontend (Vitest — ≥80% lines/functions/branches/statements on new files)

- `CargoForm`: client validation branches (required fields, `end > start`, weight > 0), server-error mapping.
- `CargoList`: empty state + CTA, status filter, paging.
- `CargoDetail`: per-status branches (`open` actions visible, `accepted` winner block, `cancelled` badge), cancel modal focus-trap + `Esc`.
- `MatchCard`: renders window/carrier, "Ofertar" CTA target.
- Network mocked with **MSW** — add `/api/cargos*` handlers to `src/test/mocks/handlers.ts`.

### E2E (Playwright, chromium) — `frontend/e2e/shipper-cargo.spec.ts`

Golden path: login as Shipper → empty "Mis cargas" → publish a cargo → land on detail with matches → **"Ofertar" on a match → confirm the offer → offer appears under "Mis ofertas"** → back to list. (Depends on seeded fixtures from `db/seeds.rb`; if fixtures aren't ready, ship with `test.skip` + a note, per `05-testing-strategy.md`.)

### `REQ-FE-00015` remediation

- Backend request spec (`cargo_offers_spec.rb`, rswag): `POST /api/cargo_offers` with a `cargo_id` — 201 happy path; **assert no extra `Cargo` row is created** (`expect { post }.not_to change(Cargo, :count)`); 403 when the cargo is not the caller's; 404 for an unknown `cargo_id`; 422 for an inactive/incompatible window **and for a window that already has a `pending`/`accepted` offer (window-lock)**. `GET /api/cargo_offers#index` regression check still green.
- `CargoOffer` model spec: the retargeted window-date validation passes when the cargo's `pickup_window_*` overlaps the window and fails otherwise; capacity check passes with `volume_cm3` nil.
- Frontend: `CreateOfferPage.test.tsx` rewritten for the single confirm step (cargo + window summaries render, `estimated_km` validation, submit posts `cargo_id` + offer fields to `/api/cargo_offers`); `api/cargoOffers.test.ts` covers the new `(cargoId, draft)` signature.

---

## 6. Acceptance Criteria

- [ ] **Schema**: migration adds `status`, `pickup_window_start/end`, `pickup_zone`/`delivery_zone` (+normalized), `cancelled_at`, `cancellation_reason`; `pickup_date` dropped after backfill; `volume_cm3` nullable; `schema.rb` regenerated.
- [ ] `Cargo` model: FSM (`open / accepted / cancelled`, no `offered`), `transition_to!` mirrors `Shipment`; associations `belongs_to :shipper`, `has_many :cargo_offers, dependent: :destroy`, `has_one :accepted_cargo_offer`.
- [ ] `POST /api/cargos` → 201, `status: open`, body includes initial zone-matches.
- [ ] `GET /api/cargos` lists the Shipper's cargos; `?status=` filter; paginated.
- [ ] `GET /api/cargos/:id` returns detail with nested offers; 403 if not owner.
- [ ] `GET /api/cargos/:id/matches` returns zone-compatible `TransportWindow`s (zone substring + date overlap + `vehicle.max_load_kg`); excludes inactive windows and windows with a `pending`/`accepted` offer; paginated; **no `distance_km`**.
- [ ] `PATCH /api/cargos/:id` blocked (422) when an offer is `accepted`.
- [ ] `DELETE /api/cargos/:id` soft-cancels + expires `pending` siblings in one transaction.
- [ ] Backend i18n: messages from `config/locales/cargos.{es,en}.yml`; zero hardcoded strings; routes English.
- [ ] FE routes `/shipper/cargos[/new|/:id[/edit]]` mounted under `RequireShipper`; non-Shipper sees a 403 view.
- [ ] FE list (filter + paging + empty CTA), form (client validation → `POST`/`PATCH` → redirect), detail (matches + offers sections, "Ofertar" CTA, cancel modal).
- [ ] All FE copy via `cargosContent.ts`; routes English.
- [ ] Vitest coverage ≥ 80% on new files; Playwright golden-path green on chromium; a11y (labels, `aria-live` errors, modal focus-trap).
- [ ] **`REQ-FE-00015` remediation (backend)**: `POST /api/cargo_offers` takes a `cargo_id`, creates a `CargoOffer` against an existing `Cargo` and creates **no** `Cargo` row; route shape unchanged; 403 when the cargo is not the caller's, 404 for an unknown `cargo_id`.
- [ ] `CargoOffer`'s window-date validation retargeted to `cargo.pickup_window_*`; capacity check tolerates `nil` volume; **window-lock validation rejects (422) an offer against a window that already has a `pending`/`accepted` offer**; `cargo_offers` request specs updated and green.
- [ ] **`REQ-FE-00015` remediation (frontend)**: `CreateOfferPage` refactored to the one-step cargo-scoped confirm flow at `/shipper/cargos/:id/offers/new`; `/carriers/:id/offers/new` removed; `MatchCard` "Ofertar" reaches it; `api/quotes.ts` renamed `api/cargoOffers.ts` and `DashboardPage` updated.
- [ ] `/critique` + `/polish` + `/audit` run on the new screens; findings resolved or annotated in the PR.
- [ ] `just lint`, `just frontend-test-coverage`, `just frontend-test-e2e`, `just backend-test` all green.
- [ ] PR title `feat(cargo): cargo fullstack — modelo, endpoints + mis cargas UI (US27)`; body references `REQ-BE-00032` + `Closes #198`; `--assignee @me`.
- [ ] PR description records: the deliberate deviations (zone matching instead of Haversine — deferred to GMaps follow-up; plain-state form instead of `react-hook-form`+`zod`) **and** the `REQ-FE-00015` remediation (endpoint split + wizard rework).

---

## 7. Files Summary

### New Files

| File | Description |
|------|-------------|
| `backend/db/migrate/<ts>_add_cargo_publication_fields.rb` | `cargos` schema delta |
| `backend/app/controllers/api/cargos_controller.rb` | 6 endpoints + cancel cascade |
| `backend/app/policies/cargo_policy.rb` | shipper-only authorization + scope |
| `backend/app/resources/cargo_resource.rb` | Alba serializer (cargo + nested offers + optional matches) |
| `backend/app/resources/cargo_match_resource.rb` | Alba serializer (window + vehicle + carrier; no distance) |
| `backend/config/locales/cargos.es.yml`, `cargos.en.yml` | validation/error messages |
| `backend/spec/requests/api/cargos_spec.rb` | rswag request specs (6 endpoints) |
| `frontend/src/types/Cargo.ts` | FE domain types |
| `frontend/src/features/cargo/api.ts` | typed REST client |
| `frontend/src/features/cargo/cargosContent.ts` | es-AR copy bundle |
| `frontend/src/features/cargo/CargoList.tsx` | "Mis cargas" list |
| `frontend/src/features/cargo/CargoForm.tsx` | publish/edit form |
| `frontend/src/features/cargo/CargoDetail.tsx` | detail + matches + offers |
| `frontend/src/features/cargo/MatchCard.tsx` | match card |
| `frontend/src/features/cargo/*.test.tsx` | Vitest unit/component specs |
| `frontend/e2e/shipper-cargo.spec.ts` | Playwright golden path |

### Modified Files

| File | Changes |
|------|---------|
| `backend/app/models/cargo.rb` | add FSM, validations, associations, zone-normalize callback (class created by `REF-BE-00002`) |
| `backend/app/models/cargo_offer.rb` | retarget `pickup_date_within_window` validation to `pickup_window_*`; capacity check tolerates `nil` volume |
| `backend/app/models/shipper.rb` | add `has_many :cargos` |
| `backend/app/controllers/api/cargo_offers_controller.rb` | drop inline `Cargo.create!` / `cargo_attrs`; bid against an existing cargo (`REQ-FE-00015` remediation) |
| `backend/app/policies/cargo_policy.rb` | add `offer?` ownership check |
| `backend/app/policies/cargo_offer_policy.rb` | `create?` stays shipper-gated; cargo ownership checked via `CargoPolicy#offer?` |
| `backend/config/routes.rb` | add `resources :cargos` + `matches` member route (`cargo_offers` route untouched) |
| `backend/db/schema.rb` | regenerated after migration |
| `backend/spec/models/cargo_spec.rb` | extend with FSM + new validations (file created by `REF-BE-00002`) |
| `backend/spec/models/cargo_offer_spec.rb` | cover the retargeted window-date + capacity validations |
| `backend/spec/requests/api/cargo_offers_spec.rb` | `cargo_id`-based create happy path, ownership 403, "no `Cargo` created" assertion |
| `backend/spec/factories/cargos.rb` | add `status`, `pickup_window_*`, zone traits (file created by `REF-BE-00002`) |
| `frontend/src/pages/shipper/CreateOfferPage.tsx` | 3-step wizard → 1-step cargo-scoped confirm (`REQ-FE-00015` remediation) |
| `frontend/src/pages/shipper/CreateOfferPage.test.tsx` | rewritten for the new single-step flow |
| `frontend/src/pages/dashboard/DashboardPage.tsx` | import from the renamed `api/cargoOffers` module |
| `frontend/src/routes.tsx` | mount `/shipper/cargos*` subtree incl. `/offers/new`; remove `/carriers/:id/offers/new` |
| `frontend/src/auth/RequireShipper.tsx` | non-Shipper → visible 403 view instead of silent redirect |
| `frontend/src/test/mocks/handlers.ts` | MSW handlers for `/api/cargos*` and the `cargo_id`-based `POST /api/cargo_offers` |

### Renamed Files

| From → To | Reason |
|-----------|--------|
| `frontend/src/api/quotes.ts` → `frontend/src/api/cargoOffers.ts` | stale name; `createCargoOffer` signature becomes `(cargoId, draft)` and posts `cargo_id` in the body to `/api/cargo_offers` |
| `frontend/src/api/quotes.test.ts` → `frontend/src/api/cargoOffers.test.ts` | follows the module rename |

---

## 8. Risks & Sequencing

| Risk | Mitigation |
|------|------------|
| ~~`REF-BE-00002` not merged~~ | **Resolved** — merged via PR #204 (2026-05-19). `Cargo`/`CargoOffer` models + `cargos`/`cargo_offers` tables are on `main`. No action needed. |
| **`REQ-FE-00015` remediation widens the PR** — the merged offer flow conflates `Cargo` + `CargoOffer` creation | Folded into this issue as in-scope (§2.7) per directive 2026-05-19, not deferred. Net effect: this is an **XL** PR that also touches the `cargo_offers` controller/specs and `CreateOfferPage`. Mitigation: the remediation lands in dedicated commits (6–7 below), **after** the `POST /api/cargos` surface exists, so each commit is independently green. |
| **`CreateOfferPage` is a shipped, tested screen** — refactoring it risks regressing US7 | The window/cargo summaries are read-only; only the submit path and step count change. Keep `CreateOfferPage.test.tsx` green at every step; run the offer E2E before pushing. |
| `Cargo has_many :cargo_offers` is `:restrict_with_error` on `main` | This issue changes it to `dependent: :destroy` (per the issue AC) — note the change in the PR; the soft-cancel cascade expires `pending` offers explicitly before any destroy path is reachable. |
| `INF-FE-00003` (routing) | `src/routes.tsx` + guards already exist; this issue only adds the `/shipper/cargos*` subtree. Effectively unblocked. |
| Map picker (`REQ-FE-00009`) not ready | The form uses the structured text address sub-form from `CreateOfferPage`. No map dependency. |
| Zone-substring matching is coarse (province/zone granularity) | Accepted as the **final MVP behaviour** — documented, not deferred work. Precise geo matching arrives with the GMaps integration as a separate issue; do **not** write "Phase-2 PostGIS" framing (CLAUDE.md DB policy). |
| Large XL fullstack PR | Develop in the commit sequence below, CI green at each step. |

**Suggested commit sequence:** (1) migration + `Cargo` model + FSM + model spec; (2) `Api::CargosController` + routes + policy + resources + request specs; (3) FE types + `api.ts` + `CargoList` + empty state; (4) `CargoForm` (new/edit) + validation; (5) `CargoDetail` + `MatchCard` + cancel modal; (6) **BE remediation** — `CargoOffersController#create` refactor (`cargo_id` param, no inline `Cargo`), `CargoOffer` validation fix, updated `cargo_offers` specs; (7) **FE remediation** — `CreateOfferPage` cargo-first refactor, `api/cargoOffers.ts` rename, route swap, updated specs; (8) Playwright E2E (publish → match → offer) + `/critique`/`/polish`/`/audit` fixes.

---

## 9. Flow rework — cargo-first funnel (added 2026-05-19)

Post-implementation UX correction, resolved in a grilling session and folded into
PR #205 **before merge** — the elements it removes are this branch's own unmerged
additions, so this is revising US27 in-flight, not new scope. Flag the scope change
in the PR description (the issue is *InReview*).

**Canonical funnel — the only offer flow:**
`Dashboard "Mis cargas"` → click `open` cargo → `/shipper/cargos/:id/matches` →
click a match → `/shipper/cargos/:id/offers/new`.

### Decisions

| # | Decision |
|---|----------|
| D1 | **Land on the current branch / PR #205.** Branch is unmerged — splitting would merge a flow then immediately tear it down, burning a release bump. |
| D2 | **New cargo-scoped route `/shipper/cargos/:id/matches`** (nested in the `/shipper/cargos` subtree, `ShipperLayout`). Renders the existing `GET /api/cargos/:id/matches` results with the selected-cargo card pinned on top. Chosen over repurposing the free-form `/transport_windows/search`: data source already exists, cargo id in the path is deep-linkable, and it cleanly orphans the free-form search for deletion. |
| D3 | **Card-body click is status-aware.** `open` cargo → `/shipper/cargos/:id/matches`; `accepted`/`cancelled` → `CargoDetail` (matches are meaningless for non-open cargos — routing them to the matches screen is a dead-end). "Ver detalle" stays on every card. |
| D4 | **New dashboard "Mis cargas" section** (top, new component): capped-preview **status swimlanes** — labeled "Abiertas / Aceptadas / Canceladas", ~4 cards/lane, "Ver todas (N)" → `/shipper/cargos`. Data from the existing `listCargos()`, grouped + sorted **client-side**; the "Abiertas" lane sorts zero-`pending_offers_count` first ("no offers" = zero *pending* offers). |
| D5 | **`CargoList` (`/shipper/cargos`) stays as-is** — keeps its status-filter dropdown, pagination, and `created_at: :desc` order. **`cargos#index` backend unchanged.** Swimlanes + "no offers first" live *only* in the new dashboard section. |
| D6 | **`MatchCard` → whole card is a `<Link>`** to `/shipper/cargos/:id/offers/new?window=:wid` (`state:{window}`); the explicit "Ofertar" `<Button>` is removed (one action per result; `<Link>`-wrapped card matches the existing carrier-dashboard pattern and passes `/audit`). |
| D7 | **`CargoDetail`**: delete the Matches `<section>` (lines 258–296) + its `getMatches` effect; add a **"Buscar transportistas"** button in the detail header, shown only when `status === "open"`, → `/shipper/cargos/:id/matches`. The Offers section stays. |
| D8 | **`CarrierDetail`**: remove the "Ofertar" button + `onOffer`/navigate. Keep the page — it is the public carrier profile, still reached via `/carriers/me`. |
| D9 | **Remove `TransportWindowSearchSection`** from the dashboard. Keep the "Mis ofertas" and "Mis viajes" sections (only the search section was in scope to remove). |
| D10 | **Delete the now-orphaned free-form search**: `TransportWindowSearchSection`, `CarrierSearchPage`, the `/transport_windows/search` route line, and the `searchCarriers` API client (+ its tests). Zero entry points remain after D8/D9, and a live route to a search that no longer fits the product contradicts the single-funnel goal. |

### Files touched by the rework

| File | Change |
|------|--------|
| `frontend/src/pages/dashboard/DashboardPage.tsx` | drop `TransportWindowSearchSection`; add the "Mis cargas" swimlane section at the top |
| `frontend/src/features/cargo/` *(new component)* | dashboard "Mis cargas" preview component — swimlanes, client-side group/sort, capped per lane |
| `frontend/src/features/cargo/CargoList.tsx` | **unchanged** |
| `frontend/src/features/cargo/CargoMatches.tsx` *(new)* | `/shipper/cargos/:id/matches` screen — selected-cargo card + match list |
| `frontend/src/features/cargo/MatchCard.tsx` | convert to a whole-card `<Link>`; remove the "Ofertar" button |
| `frontend/src/features/cargo/CargoDetail.tsx` | delete the Matches section + `getMatches` effect; add the `open`-only "Buscar transportistas" header button |
| `frontend/src/pages/public/CarrierDetail.tsx` | remove the "Ofertar" button + `onOffer`/navigate |
| `frontend/src/routes.tsx` | add `/shipper/cargos/:id/matches`; remove the `/transport_windows/search` route |
| `frontend/src/pages/dashboard/TransportWindowSearchSection.tsx` | **delete** |
| `frontend/src/pages/search/CarrierSearchPage.tsx` | **delete** |
| `frontend/src/api/` (`searchCarriers` client + test) | **delete** |
| `frontend/e2e/shipper-cargo.spec.ts` | refresh for the new funnel (Dashboard → cargo → matches → offer) |
| `*.test.tsx` (`DashboardPage`, `MatchCard`, `CargoDetail`) | update for the reworked surfaces; keep coverage ≥ 80% |

**Execution check:** verify `CreateOfferPage` reads the cargo from the `:id` path
param and the window from `state` / `?window=` — it was rewritten in this branch,
so the matches→offer payload (`state:{window}`) must match what it expects.
