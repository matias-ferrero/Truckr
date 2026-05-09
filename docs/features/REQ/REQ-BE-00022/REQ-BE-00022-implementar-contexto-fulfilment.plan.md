# REQ-BE-00022: Implementar contexto Fulfilment — Shipment (state machine), TrackingEvent, Route

| Field | Value |
|-------|-------|
| **Tag** | REQ-BE-00022 |
| **Title** | Implementar contexto Fulfilment — Shipment (state machine), TrackingEvent, Route |
| **Priority** | P0 |
| **Status** | READY |
| **Created** | 2026-05-03 |
| **Updated** | 2026-05-09 |
| **Author** | Claude Code |
| **Depends On** | `REQ-BE-00005` (design) — must be merged. `REQ-BE-00020` (Identity) and `REQ-BE-00021` (Marketplace) — must be merged before implementing this plan. |
| **Decision Doc** | N/A — design closed in REQ-BE-00005; this plan only translates it to code. |
| **Selected Approach** | Single approach: hand-rolled `Shipment#transition_to!` driven by an `ALLOWED_TRANSITIONS` constant, wrapped in `with_lock`, emitting `TrackingEvent` rows from the transition method (no callbacks, no gem). |

---

## 1. Problem Statement

`REQ-BE-00005` defines the Fulfilment context **conceptually**:
[`docs/02-high-level-design/domain-model.md` § 4](../../../02-high-level-design/domain-model.md#4-fulfilment-conceptual--fsm) gives the FSM table, attributes, and side effects. `REQ-BE-00020` lands `users` / `carriers` / `shippers` / `vehicles`; `REQ-BE-00021` lands `transport_windows` / `cargo_offers` / `quotes`. Neither writes a single Fulfilment row.

`Shipment` is the **operational core** of the platform. Without it:

- US15 (mark picked-up), US16 (mark delivered), US18 (live tracking), US19 (chained trips), US20 (insurance), US21 (review post-trip) are blocked outright.
- `REQ-BE-00006` / `REQ-BE-00007` / `REQ-BE-00011` (payments / payout) have no foreign key target.
- `REQ-FE-00010` (live tracking UI) has no event stream to consume.

This plan delivers:

1. Migrations for `shipments`, `tracking_events`, `routes`.
2. AR models with the full state machine (`draft → quoted → accepted → in_transit → delivered → settled` + `cancelled`), validations, scopes, factories, seeds.
3. ActiveAdmin read-only screens (with the tracking log inlined into `Shipment`).
4. Specs that exercise every permitted transition and at least one rejected one (and the locking semantics where testable).

The endpoint that pushes GPS updates (`POST /api/trips/:id/locations`) is **out of scope** — owned by a downstream tracking issue. This plan only ensures the model accepts that kind of event.

---

## 2. Solution Design

### 2.1 Approach

Hand-rolled FSM, no gem. Decision F in `domain-model.md` § 7 + Tech Notes of the issue close this debate: 7 states with linear transitions are below the pain threshold that justifies `aasm` / `state_machines`. The model owns:

- A frozen `ALLOWED_TRANSITIONS` map.
- `Shipment#transition_to!(new_status, **side_effect_attrs)` that:
  1. Acquires a row-level lock (`with_lock`) inside an AR transaction.
  2. Validates the (current, new) pair against `ALLOWED_TRANSITIONS`.
  3. Sets `status` plus the matching timestamp column (`picked_up_at`, `delivered_at`, `settled_at`, `cancelled_at`).
  4. Emits exactly one `TrackingEvent` of `kind: :status_change`.
  5. Saves; raises `Shipment::IllegalTransition` if the pair is not allowed; lets AR validation errors propagate.
- Side-effect emission lives **inside** the transition method, not a callback (per the issue's Tech Notes — predictable for tests, no surprise event ordering).

`TrackingEvent` is append-only — no update / delete in domain code. The model exposes `kind: :gps_update` so the future tracking endpoint can write GPS rows without further migration.

`Route` is a 1:1 sidecar to `Shipment` with **all geo / distance fields nullable** until a downstream issue calculates them via Google Maps Directions.

### 2.2 Key Design Decisions

#### Decision H — `ALLOWED_TRANSITIONS` as a frozen constant on the model

Single source of truth in the codebase. Lives in `Shipment`, not in a YAML or initializer, because (a) it is co-located with the method that enforces it, (b) it is small enough to read top-to-bottom, (c) it must be referenced by specs. Documented inline with an ASCII state diagram so a reader does not need to open a separate file.

Map (verbatim — this is the spec):

```ruby
ALLOWED_TRANSITIONS = {
  draft:      [:quoted],
  quoted:     [:accepted, :cancelled],
  accepted:   [:in_transit, :cancelled],
  in_transit: [:delivered, :cancelled],
  delivered:  [:settled],
  settled:    [],
  cancelled:  []
}.freeze
```

Note: `delivered → cancelled` is **NOT** allowed — once goods are delivered the only forward path is `settled`. Disputes are handled in the Commerce context (refund / chargeback against `Payment`) and do not roll the `Shipment` back. Documented in the model.

#### Decision I — Status stored as string, `enum` declaration without backing integer

`enum status: { draft: "draft", quoted: "quoted", ... }` — Rails 8 supports string-backed enums and they survive schema dumps cleanly. This gives us:

- `Shipment.in_transit` scope for free.
- `shipment.delivered?` predicates for free.
- A check constraint to reject unknown values at DB level (added in the migration).

We deliberately do **not** use integer-backed enums: searching a SQL log for `status = 7` is unreadable, and our tracking_events table stores the same status strings, so consistency wins.

#### Decision J — `Shipment.quote_id` FK is `restrict` on delete

`quotes` is hard-deleted (per `REQ-BE-00005` Decision C — soft-delete only on `Shipment`, `Payment`, `ArcaInvoice`). However, an accepted Quote that has a Shipment must not vanish silently: deleting the upstream `Quote` would orphan a shipment that already represents a contractual / fiscal obligation. We therefore set `on_delete: :restrict` on the FK (Rails: `foreign_key: { to_table: :quotes, on_delete: :restrict }`).

If `REQ-BE-00021` decides Quotes get soft-delete (deviation from REQ-BE-00005), the assumption section flags it; we revisit `restrict` → `nullify` then.

#### Decision K — `TrackingEvent` rows are emitted explicitly, not via AR callbacks

The issue's Tech Notes are explicit: side effects in the transition method, not in `after_save` / `after_update_commit`. Reasons:

- Specs can stub `Shipment.transition_to!` without worrying about callback ordering.
- The set of side effects is local to the method body — easy to audit.
- Future expansion (e.g. emitting domain events to a Solid Queue topic) drops in cleanly.

#### Decision L — Soft-delete on `Shipment` only, not on `TrackingEvent` / `Route`

Per REQ-BE-00005 Decision C. `TrackingEvent` and `Route` have `dependent: :destroy` from `Shipment`, but since `Shipment` itself is soft-deleted, the cascade only fires on a hard `destroy!` call (operator action via console). This preserves the audit trail for the lifetime of the shipment row.

Implementation: `discarded_at` column on `shipments`, `default_scope { where(discarded_at: nil) }` (with `unscoped` escape for ActiveAdmin), `Shipment#discard!` helper. We follow REQ-BE-00020's pattern (assumed: a `Discardable` concern). If the upstream concern doesn't exist yet, we inline `discarded_at` directly here and refactor later.

#### Decision M — `TrackingEvent.metadata` JSON column

SQLite stores JSON as text; Rails 8's `jsonb` casting works on SQLite by serialising to text and parsing on read. We use `t.text :metadata` + `serialize :metadata, coder: JSON` so the same code path works once Postgres lands. Cap it at "small key/value bag" — anything large goes in a future blob.

### 2.3 Out of Scope

- `POST /api/trips/:id/locations` and any other controller / API endpoint.
- The triggers for `accepted` (REQ-BE-00021's quote-acceptance flow / US12) and for `settled` (REQ-BE-00011 carrier payout, REQ-BE-00018 insurance settlement). We make the transitions **available**; we do not invoke them.
- Google Maps Directions integration to populate `Route` (separate issue).
- Real-time push to the frontend (Action Cable / SSE) — frontend issue.
- Geo / PostGIS — deferred (ADR-010, Phase 2).
- `aasm` / `state_machines` gem adoption.
- `Review` (US17 / US21) — not modelled yet (see `domain-model.md` § 9).
- Vehicle reassignment mid-shipment — explicitly out of scope (`domain-model.md` § 4.1: "cancel + re-quote" is the workflow).

---

## 3. Upstream Contract (consumed)

This plan **assumes** the following from REQ-BE-00020 and REQ-BE-00021. Each row is something the orchestrator must verify against the sibling plans before all three are merged.

### 3.1 From `REQ-BE-00020` (Identity)

| Assumption | Value | Source |
|------------|-------|--------|
| PK type | `bigint` (Rails default) | ADR-007 in `technical-vision.md`; `domain-model.md` § 2.1 |
| Tables | `users`, `carriers`, `shippers`, `vehicles` (plural, English) | `domain-model.md` § 2 |
| `carriers.id`, `shippers.id` | `bigint` PK | ADR-007 |
| Soft-delete on `carriers` / `shippers` | **No** — hard-delete (ADR-009) | `domain-model.md` § 7 |
| Soft-delete on `vehicles` | **No** — hard-delete | ADR-009 |
| `Carrier has_many :vehicles` (1:N from day one) | Yes | Orchestrator decision; supersedes `REQ-BE-00010` |
| `Vehicle#before_destroy :ensure_no_active_commitments` blocks delete when any `TransportWindow` on the vehicle backs a non-terminal `Quote` | Yes | `REQ-BE-00020` plan — protects `shipments.quote_id on_delete: :restrict` chain |

Implication for this plan: Fulfilment relates to Identity only **transitively** through `quotes`. The reachability chain is:
- `shipment.quote.carrier` → Carrier
- `shipment.quote.cargo_offer.shipper` → Shipper
- `shipment.quote.transport_window.vehicle` → Vehicle (vehicle is pinned at the `TransportWindow` level per `REQ-BE-00021` — orchestrator decision)

We do **not** add direct FKs to `carriers` / `shippers` / `vehicles` on `shipments` — the issue only specifies `quote_id`. The denormalisation hinted at in `domain-model.md` § 4.1 (`Shipment.carrier_id`, `Shipment.shipper_id`, `Shipment.vehicle_id` as frozen-at-acceptance copies) is a **deliberate non-decision**: premature optimisation rejected by the orchestrator. If join cost ever surfaces in payout/invoice queries (`REQ-BE-00006/7/11`), a follow-up migration adds the columns then.

> **Flag (resolved)**: `domain-model.md` § 4.1 lists `carrier_id`, `shipper_id`, `vehicle_id` as Shipment columns ("frozen at acceptance"). The REQ-BE-00022 issue's Expected Behavior lists **only** `quote_id` plus timestamps. **Orchestrator's decision: keep the issue's narrow column set; no denormalisation.** `domain-model.md` § 4.1 is the artifact that should be updated to match (out-of-scope for this plan; flag for the documentation pass).

### 3.2 From `REQ-BE-00021` (Marketplace)

| Assumption | Value | Source |
|------------|-------|--------|
| `quotes` table name | `quotes` (plural) | `domain-model.md` § 3.3 |
| `quotes.id` PK type | `bigint` (must match 00020) | ADR-007 |
| `quotes.status` values | `pending`, `accepted`, `paid`, `expired`, `cancelled` (string) | issue 00021 Expected Behavior + Tech Notes |
| Trigger value for `Shipment.transition_to!(:accepted)` | `Quote.status == 'accepted'` (set by US12 / REQ-BE-00021's caller, not invoked here) | issue 00021 Tech Notes; FSM table in `domain-model.md` § 4.1 |
| Hard-delete on `quotes` | Yes (per ADR-009 — Quote is **not** in the soft-delete allowlist) | ADR-009 |
| FK behaviour | `Shipment.quote_id` references `quotes.id` with `on_delete: :restrict` | Decision J above |
| `quotes.carrier_id`, `quotes.cargo_offer_id`, `quotes.transport_window_id` exist | Yes (issue 00021 Expected Behavior) | issue 00021 |
| `quotes.vehicle_id` does NOT exist | Confirmed — vehicle is pinned at `TransportWindow.vehicle_id` (orchestrator decision); reachable via `quote.transport_window.vehicle` | `REQ-BE-00021` plan §4.3, §6.3 |
| `transport_windows.vehicle_id NOT NULL` with FK `on_delete: :cascade` | Yes | `REQ-BE-00021` plan §4.1 |

**Lifecycle invariant assumed**: a `Quote` row in `accepted` (or later) state remains live for the lifetime of its `Shipment`. The 00021 plan must not introduce a path that hard-deletes an accepted Quote while a Shipment references it. With `on_delete: :restrict` we get a DB-level safety net; the orchestrator should verify 00021 doesn't add a `dependent: :destroy` cascade from `CargoOffer → quotes` that would bypass the restriction (a `dependent: :destroy` triggers AR-level destroys per row, which DOES respect FK constraints in Rails, so the restriction wins — a destroy of a CargoOffer with an accepted Quote backing a Shipment would fail loudly. That's the desired behaviour.)

### 3.3 From `INF-BE-00003` (ActiveAdmin)

| Assumption | Value |
|------------|-------|
| ActiveAdmin is mounted at `/admin` and resource files live in `backend/app/admin/` | Yes |
| `ActiveAdmin.register MyModel do ... end` works against domain models | Yes |
| Domain `User` is **isolated** from `AdminUser` | Yes (ADR-008 / `domain-model.md` § 2.5) |

---

## 4. Implementation Tasks

| # | Task | Files |
|---|------|-------|
| 1 | Branch `feature/req-be-00022-fulfilment` from a clean `main` (after 00020 + 00021 merge) | — |
| 2 | Add `factory_bot_rails` and `faker` to `:development, :test` in `Gemfile` if missing | `backend/Gemfile`, `backend/Gemfile.lock` |
| 3 | Migration: `CreateShipments` — columns per § 5.1, FK `quote_id` (unique, `on_delete: :restrict`), CHECK constraint on `status` | `backend/db/migrate/<ts>_create_shipments.rb` |
| 4 | Migration: `CreateTrackingEvents` — columns per § 5.2, FK `shipment_id`, indexes on `shipment_id`, `(shipment_id, recorded_at)`, `kind` | `backend/db/migrate/<ts+1>_create_tracking_events.rb` |
| 5 | Migration: `CreateRoutes` — columns per § 5.3, FK `shipment_id` (unique) | `backend/db/migrate/<ts+2>_create_routes.rb` |
| 6 | Run migrations; verify `db/schema.rb` updated | `backend/db/schema.rb` |
| 7 | Model: `Shipment` — associations, validations, `ALLOWED_TRANSITIONS`, `transition_to!`, scopes, soft-delete, ASCII FSM diagram | `backend/app/models/shipment.rb` |
| 8 | Model: `TrackingEvent` — associations, validations, scopes, kind enum | `backend/app/models/tracking_event.rb` |
| 9 | Model: `Route` — associations, validations | `backend/app/models/route.rb` |
| 10 | Custom error class `Shipment::IllegalTransition < StandardError` | embedded in `shipment.rb` |
| 11 | Factories for `Shipment` (one per state via traits), `TrackingEvent` (status_change / gps_update / note traits), `Route` | `backend/spec/factories/shipments.rb`, `tracking_events.rb`, `routes.rb` |
| 12 | Seed: one shipment per state plus a few tracking events, all referencing seeded quotes from 00021 | `backend/db/seeds.rb` (append) |
| 13 | ActiveAdmin: `Shipment` register with sidebar tracking log + read-only Route panel; `TrackingEvent` register; `Route` register | `backend/app/admin/shipments.rb`, `tracking_events.rb`, `routes.rb` |
| 14 | Specs: `Shipment` — every permitted transition (12 transitions) + ≥3 rejected + idempotency check + locking sanity | `backend/spec/models/shipment_spec.rb` |
| 15 | Specs: `TrackingEvent` — validations, scopes, kind enum | `backend/spec/models/tracking_event_spec.rb` |
| 16 | Specs: `Route` — validations, association | `backend/spec/models/route_spec.rb` |
| 17 | Run `bin/rails db:seed RAILS_ENV=development` to verify idempotency; run `bundle exec rspec spec/models` and check ≥80% coverage on touched files | — |
| 18 | Move issue `Backlog/` → `Ready/`; frontmatter `status: ready` + `plan: <path>` | `.gdsi-sdlc/issues/Ready/REQ-BE-00022-...issue.md` |
| 19 | Conventional Commit: `chore(plan): create plan for REQ-BE-00022` (planning commit) — implementation commit later: `feat(fulfilment): add Shipment, TrackingEvent and Route with hand-rolled FSM` | — |

---

## 5. Code Changes

### 5.1 New file: `backend/db/migrate/<ts>_create_shipments.rb`

```ruby
class CreateShipments < ActiveRecord::Migration[8.1]
  def change
    create_table :shipments do |t|
      t.references :quote, null: false, foreign_key: { on_delete: :restrict }, index: { unique: true }

      t.string   :status, null: false, default: "draft"

      t.datetime :picked_up_at
      t.datetime :delivered_at
      t.datetime :settled_at
      t.datetime :cancelled_at
      t.string   :cancellation_reason

      t.datetime :discarded_at # soft-delete (ADR-009)

      t.timestamps
    end

    # Reject unknown status values at the DB level. SQLite ≥ 3.8 supports CHECK.
    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE INDEX index_shipments_on_status ON shipments(status);
        SQL
        # CHECK constraint — rebuilt on every status change set.
        execute <<~SQL
          CREATE INDEX index_shipments_on_discarded_at ON shipments(discarded_at);
        SQL
      end
    end

    add_check_constraint :shipments,
      "status IN ('draft','quoted','accepted','in_transit','delivered','settled','cancelled')",
      name: "shipments_status_check"
  end
end
```

### 5.2 New file: `backend/db/migrate/<ts+1>_create_tracking_events.rb`

```ruby
class CreateTrackingEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :tracking_events do |t|
      t.references :shipment, null: false, foreign_key: { on_delete: :cascade }

      t.string   :kind, null: false # status_change | gps_update | note
      t.string   :from_status
      t.string   :to_status

      t.decimal  :lat, precision: 9, scale: 6
      t.decimal  :lng, precision: 9, scale: 6

      t.text     :metadata
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    add_index :tracking_events, [:shipment_id, :recorded_at]
    add_index :tracking_events, :kind
    add_check_constraint :tracking_events,
      "kind IN ('status_change','gps_update','note')",
      name: "tracking_events_kind_check"
  end
end
```

### 5.3 New file: `backend/db/migrate/<ts+2>_create_routes.rb`

```ruby
class CreateRoutes < ActiveRecord::Migration[8.1]
  def change
    create_table :routes do |t|
      t.references :shipment, null: false, foreign_key: { on_delete: :cascade }, index: { unique: true }

      t.text     :polyline               # Google Maps encoded polyline
      t.integer  :distance_m
      t.integer  :duration_s
      t.string   :provider, null: false, default: "google_maps_directions"
      t.datetime :calculated_at

      t.timestamps
    end
  end
end
```

### 5.4 New file: `backend/app/models/shipment.rb`

```ruby
# frozen_string_literal: true

# Shipment — Fulfilment context aggregate root.
#
# State machine (hand-rolled, no gem — Decision F in domain-model.md):
#
#   ┌───────┐   ┌────────┐   ┌──────────┐   ┌────────────┐   ┌───────────┐   ┌──────────┐
#   │ draft │──▶│ quoted │──▶│ accepted │──▶│ in_transit │──▶│ delivered │──▶│ settled  │
#   └───────┘   └────┬───┘   └────┬─────┘   └─────┬──────┘   └───────────┘   └──────────┘
#                    │            │               │
#                    │            ▼               ▼
#                    │       ┌─────────┐     ┌─────────┐
#                    └──────▶│cancelled│◀────│cancelled│   (cancellation allowed from
#                            └─────────┘     └─────────┘    quoted / accepted / in_transit)
#
# `delivered → cancelled` is NOT allowed: once goods are delivered the only forward
# path is `settled`. Disputes are handled in Commerce against the Payment row.
class Shipment < ApplicationRecord
  class IllegalTransition < StandardError; end

  ALLOWED_TRANSITIONS = {
    draft:      [:quoted],
    quoted:     [:accepted, :cancelled],
    accepted:   [:in_transit, :cancelled],
    in_transit: [:delivered, :cancelled],
    delivered:  [:settled],
    settled:    [],
    cancelled:  []
  }.freeze

  STATUS_TIMESTAMP_COLUMNS = {
    in_transit: :picked_up_at,
    delivered:  :delivered_at,
    settled:    :settled_at,
    cancelled:  :cancelled_at
  }.freeze

  STATUSES = ALLOWED_TRANSITIONS.keys.map(&:to_s).freeze

  enum :status, STATUSES.index_with(&:itself), prefix: true

  # ── Soft-delete (ADR-009) ─────────────────────────────────────────────
  default_scope { where(discarded_at: nil) }
  scope :discarded, -> { unscope(where: :discarded_at).where.not(discarded_at: nil) }
  scope :with_discarded, -> { unscope(where: :discarded_at) }

  def discard!
    update!(discarded_at: Time.current)
  end

  # ── Associations ──────────────────────────────────────────────────────
  belongs_to :quote, inverse_of: :shipment
  has_many   :tracking_events, dependent: :destroy, inverse_of: :shipment
  has_one    :route, dependent: :destroy, inverse_of: :shipment

  # ── Validations ───────────────────────────────────────────────────────
  validates :quote_id, presence: true, uniqueness: true
  validates :status,   presence: true, inclusion: { in: STATUSES }
  validates :cancellation_reason,
            presence: true,
            if: -> { status_cancelled? }
  validate  :timestamps_match_status, on: :update

  # ── Scopes ────────────────────────────────────────────────────────────
  scope :active,      -> { where.not(status: %w[settled cancelled]) }
  scope :completed,   -> { where(status: %w[settled cancelled]) }
  scope :in_progress, -> { where(status: %w[accepted in_transit]) }

  # ── State machine ─────────────────────────────────────────────────────
  #
  # Atomically advances `status` to `new_status`, validates the transition,
  # stamps the matching timestamp column, and emits a TrackingEvent of
  # kind=:status_change. Raises Shipment::IllegalTransition on a rejected
  # pair. Wrapped in a row-level lock so concurrent transition attempts
  # serialise instead of racing.
  #
  # @param new_status [Symbol]
  # @param reason [String, nil] required when `new_status == :cancelled`
  # @param at [Time] timestamp to record (default Time.current)
  # @return [TrackingEvent] the event row that was just emitted
  def transition_to!(new_status, reason: nil, at: Time.current)
    new_status = new_status.to_sym
    transaction do
      with_lock do
        from = status.to_sym
        unless ALLOWED_TRANSITIONS.fetch(from, []).include?(new_status)
          raise IllegalTransition,
                "Shipment #{id}: transition #{from} -> #{new_status} is not allowed"
        end

        attrs = { status: new_status.to_s }
        if (col = STATUS_TIMESTAMP_COLUMNS[new_status])
          attrs[col] = at
        end
        attrs[:cancellation_reason] = reason if new_status == :cancelled
        update!(attrs)

        tracking_events.create!(
          kind:        :status_change,
          from_status: from.to_s,
          to_status:   new_status.to_s,
          recorded_at: at,
          metadata:    { reason: reason }.compact
        )
      end
    end
  end

  private

  def timestamps_match_status
    case status.to_sym
    when :cancelled
      errors.add(:cancelled_at, "must be set when cancelled") if cancelled_at.blank?
    when :settled
      errors.add(:settled_at, "must be set when settled") if settled_at.blank?
    end
  end
end
```

### 5.5 New file: `backend/app/models/tracking_event.rb`

```ruby
# frozen_string_literal: true

# TrackingEvent — append-only log entry tied to a Shipment.
#
# `kind` is one of:
#   - status_change : emitted by Shipment#transition_to! on every FSM step.
#   - gps_update    : emitted by POST /api/trips/:id/locations (owned by a
#                     downstream tracking issue; this model just admits it).
#   - note          : free-form operational note (ActiveAdmin / staff).
class TrackingEvent < ApplicationRecord
  KINDS = %w[status_change gps_update note].freeze

  belongs_to :shipment, inverse_of: :tracking_events

  serialize :metadata, coder: JSON

  validates :kind,        inclusion: { in: KINDS }
  validates :recorded_at, presence: true
  validates :from_status, presence: true, if: -> { kind == "status_change" }
  validates :to_status,   presence: true, if: -> { kind == "status_change" }
  validates :lat, :lng,   presence: true, if: -> { kind == "gps_update" }

  scope :gps,        -> { where(kind: "gps_update") }
  scope :recent,     ->(n = 50) { order(recorded_at: :desc).limit(n) }
  scope :for_status, -> { where(kind: "status_change") }
end
```

### 5.6 New file: `backend/app/models/route.rb`

```ruby
# frozen_string_literal: true

# Route — single calculated route for a Shipment.
#
# All geo / metric fields are nullable: the row is created together with
# the Shipment but populated by a downstream Google Maps Directions
# integration (separate issue). Provider defaults to google_maps_directions.
class Route < ApplicationRecord
  belongs_to :shipment, inverse_of: :route

  validates :shipment_id, uniqueness: true
  validates :provider,    presence: true
  validates :distance_m,  numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :duration_s,  numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  def calculated?
    polyline.present? && calculated_at.present?
  end
end
```

### 5.7 New file: `backend/app/admin/shipments.rb`

```ruby
ActiveAdmin.register Shipment do
  actions :index, :show
  config.sort_order = "created_at_desc"

  filter :status, as: :select, collection: Shipment::STATUSES
  filter :created_at

  index do
    selectable_column
    id_column
    column :quote_id
    column :status
    column :picked_up_at
    column :delivered_at
    column :settled_at
    column :cancelled_at
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :quote_id
      row :status
      row :picked_up_at
      row :delivered_at
      row :settled_at
      row :cancelled_at
      row :cancellation_reason
      row :discarded_at
      row :created_at
      row :updated_at
    end

    panel "Tracking log (most recent 100)" do
      table_for shipment.tracking_events.recent(100) do
        column :recorded_at
        column :kind
        column :from_status
        column :to_status
        column :lat
        column :lng
        column(:metadata) { |e| e.metadata.to_json if e.metadata }
      end
    end

    panel "Route" do
      if shipment.route
        attributes_table_for shipment.route do
          row :provider
          row :distance_m
          row :duration_s
          row :calculated_at
          row(:polyline) { |r| r.polyline.to_s.truncate(120) }
        end
      else
        para "No route calculated yet."
      end
    end
  end
end
```

### 5.8 New file: `backend/app/admin/tracking_events.rb`

```ruby
ActiveAdmin.register TrackingEvent do
  actions :index, :show

  filter :shipment_id
  filter :kind, as: :select, collection: TrackingEvent::KINDS
  filter :recorded_at

  index do
    selectable_column
    id_column
    column :shipment_id
    column :kind
    column :from_status
    column :to_status
    column :recorded_at
    actions
  end
end
```

### 5.9 New file: `backend/app/admin/routes.rb`

```ruby
ActiveAdmin.register Route do
  actions :index, :show

  filter :shipment_id
  filter :provider
  filter :calculated_at

  index do
    selectable_column
    id_column
    column :shipment_id
    column :provider
    column :distance_m
    column :duration_s
    column :calculated_at
    actions
  end
end
```

### 5.10 New file: `backend/spec/factories/shipments.rb`

```ruby
FactoryBot.define do
  factory :shipment do
    association :quote
    status { "draft" }

    trait :draft      do; status { "draft" } end
    trait :quoted     do; status { "quoted" } end
    trait :accepted   do; status { "accepted" } end
    trait :in_transit do
      status        { "in_transit" }
      picked_up_at  { 1.hour.ago }
    end
    trait :delivered  do
      status        { "delivered" }
      picked_up_at  { 4.hours.ago }
      delivered_at  { 30.minutes.ago }
    end
    trait :settled    do
      status        { "settled" }
      picked_up_at  { 1.day.ago }
      delivered_at  { 6.hours.ago }
      settled_at    { 30.minutes.ago }
    end
    trait :cancelled  do
      status              { "cancelled" }
      cancelled_at        { 5.minutes.ago }
      cancellation_reason { "demo cancellation" }
    end
  end
end
```

### 5.11 New file: `backend/spec/factories/tracking_events.rb`

```ruby
FactoryBot.define do
  factory :tracking_event do
    association :shipment
    kind         { "status_change" }
    from_status  { "draft" }
    to_status    { "quoted" }
    recorded_at  { Time.current }
    metadata     { {} }

    trait :gps_update do
      kind        { "gps_update" }
      from_status { nil }
      to_status   { nil }
      lat         { -34.6037 }
      lng         { -58.3816 }
    end

    trait :note do
      kind        { "note" }
      from_status { nil }
      to_status   { nil }
      metadata    { { author: "ops", body: "Demo note" } }
    end
  end
end
```

### 5.12 New file: `backend/spec/factories/routes.rb`

```ruby
FactoryBot.define do
  factory :route do
    association :shipment
    provider { "google_maps_directions" }

    trait :calculated do
      polyline       { "u{~vFvyys@fS]" }
      distance_m     { 25_000 }
      duration_s     { 1_800 }
      calculated_at  { Time.current }
    end
  end
end
```

### 5.13 New file: `backend/spec/models/shipment_spec.rb`

```ruby
require "rails_helper"

RSpec.describe Shipment, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:quote) }
    it { is_expected.to have_many(:tracking_events).dependent(:destroy) }
    it { is_expected.to have_one(:route).dependent(:destroy) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:quote_id) }
    it { is_expected.to validate_inclusion_of(:status).in_array(described_class::STATUSES) }

    it "requires cancellation_reason when cancelled" do
      s = create(:shipment, :quoted)
      expect { s.transition_to!(:cancelled) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "ALLOWED_TRANSITIONS" do
    it "is frozen and contains the canonical map" do
      expect(described_class::ALLOWED_TRANSITIONS).to be_frozen
      expect(described_class::ALLOWED_TRANSITIONS).to eq(
        draft:      [:quoted],
        quoted:     [:accepted, :cancelled],
        accepted:   [:in_transit, :cancelled],
        in_transit: [:delivered, :cancelled],
        delivered:  [:settled],
        settled:    [],
        cancelled:  []
      )
    end
  end

  describe "#transition_to! — permitted transitions" do
    permitted = [
      [:draft,      :quoted,     {}],
      [:quoted,     :accepted,   {}],
      [:quoted,     :cancelled,  { reason: "buyer changed mind" }],
      [:accepted,   :in_transit, {}],
      [:accepted,   :cancelled,  { reason: "carrier no-show" }],
      [:in_transit, :delivered,  {}],
      [:in_transit, :cancelled,  { reason: "vehicle failure" }],
      [:delivered,  :settled,    {}]
    ]

    permitted.each do |from, to, extra|
      it "transitions #{from} -> #{to}" do
        s = create(:shipment, from)
        expect { s.transition_to!(to, **extra) }.to change { s.reload.status.to_sym }.from(from).to(to)
      end

      it "emits a status_change tracking event for #{from} -> #{to}" do
        s = create(:shipment, from)
        expect { s.transition_to!(to, **extra) }.to change { s.tracking_events.count }.by(1)
        ev = s.tracking_events.order(:recorded_at).last
        expect(ev.kind).to eq("status_change")
        expect(ev.from_status).to eq(from.to_s)
        expect(ev.to_status).to eq(to.to_s)
      end
    end
  end

  describe "#transition_to! — rejected transitions" do
    rejected = [
      [:delivered,  :in_transit],
      [:settled,    :in_transit],
      [:cancelled,  :quoted],
      [:draft,      :delivered],
      [:delivered,  :cancelled] # explicit: no rollback after delivery
    ]

    rejected.each do |from, to|
      it "rejects #{from} -> #{to}" do
        s = create(:shipment, from)
        expect {
          s.transition_to!(to, reason: "n/a")
        }.to raise_error(Shipment::IllegalTransition)
        expect(s.reload.status.to_sym).to eq(from)
      end
    end
  end

  describe "#transition_to! — locking" do
    it "wraps the transition in a row lock and a transaction" do
      s = create(:shipment, :quoted)
      expect(s).to receive(:with_lock).and_call_original
      s.transition_to!(:accepted)
    end
  end

  describe "scopes" do
    let!(:draft)      { create(:shipment, :draft) }
    let!(:in_transit) { create(:shipment, :in_transit) }
    let!(:settled)    { create(:shipment, :settled) }
    let!(:cancelled)  { create(:shipment, :cancelled) }

    it ".active excludes settled and cancelled" do
      expect(Shipment.active).to match_array([draft, in_transit])
    end

    it ".completed includes settled and cancelled" do
      expect(Shipment.completed).to match_array([settled, cancelled])
    end

    it ".in_progress matches accepted/in_transit only" do
      expect(Shipment.in_progress).to match_array([in_transit])
    end
  end

  describe "soft-delete" do
    it "hides discarded rows from the default scope" do
      s = create(:shipment, :delivered)
      s.discard!
      expect(Shipment.where(id: s.id)).to be_empty
      expect(Shipment.with_discarded.where(id: s.id)).to include(s)
    end
  end
end
```

### 5.14 New file: `backend/spec/models/tracking_event_spec.rb`

```ruby
require "rails_helper"

RSpec.describe TrackingEvent, type: :model do
  it { is_expected.to belong_to(:shipment) }
  it { is_expected.to validate_inclusion_of(:kind).in_array(described_class::KINDS) }
  it { is_expected.to validate_presence_of(:recorded_at) }

  it "requires from_status / to_status on status_change" do
    e = build(:tracking_event, kind: "status_change", from_status: nil)
    expect(e).not_to be_valid
  end

  it "requires lat/lng on gps_update" do
    e = build(:tracking_event, :gps_update, lat: nil, lng: nil)
    expect(e).not_to be_valid
  end

  it "scopes .gps and .recent work" do
    s = create(:shipment, :in_transit)
    create(:tracking_event, :gps_update, shipment: s, recorded_at: 2.minutes.ago)
    create(:tracking_event, shipment: s, recorded_at: 1.minute.ago)
    expect(s.tracking_events.gps.count).to eq(1)
    expect(s.tracking_events.recent(10).first.recorded_at)
      .to be_within(1.second).of(1.minute.ago)
  end
end
```

### 5.15 New file: `backend/spec/models/route_spec.rb`

```ruby
require "rails_helper"

RSpec.describe Route, type: :model do
  it { is_expected.to belong_to(:shipment) }
  it { is_expected.to validate_uniqueness_of(:shipment_id) }

  it "is not calculated until polyline + calculated_at are set" do
    r = build(:route)
    expect(r.calculated?).to eq(false)
    r.polyline = "abc"
    r.calculated_at = Time.current
    expect(r.calculated?).to eq(true)
  end
end
```

### 5.16 Modified file: `backend/db/seeds.rb`

Append (idempotent) — pick existing seeded `Quote` rows from REQ-BE-00021 and create one Shipment per state:

```ruby
# … existing AdminUser seed …

if defined?(Quote) && defined?(Shipment) && Quote.exists?
  Shipment::STATUSES.each_with_index do |state, i|
    quote = Quote.offset(i).first or next
    next if Shipment.with_discarded.exists?(quote_id: quote.id)

    attrs = { quote: quote, status: state }
    case state
    when "in_transit" then attrs[:picked_up_at] = 1.hour.ago
    when "delivered"  then attrs.merge!(picked_up_at: 4.hours.ago, delivered_at: 30.minutes.ago)
    when "settled"    then attrs.merge!(picked_up_at: 1.day.ago, delivered_at: 6.hours.ago, settled_at: 30.minutes.ago)
    when "cancelled"  then attrs.merge!(cancelled_at: 1.minute.ago, cancellation_reason: "demo")
    end

    Shipment.create!(attrs)
  end
end
```

---

## 6. Testing

### 6.1 Unit (RSpec)

```sh
bundle exec rspec spec/models/shipment_spec.rb \
                  spec/models/tracking_event_spec.rb \
                  spec/models/route_spec.rb
```

Coverage target: ≥ 80% on the three touched files (consistent with REQ-BE-00020 / 00021 ACs).

Coverage of the AC's spec checklist:

- ≥ 8 permitted transitions explicitly tested.
- ≥ 5 rejected transitions explicitly tested (including `delivered → in_transit`, `delivered → cancelled`).
- Locking call verified by partial-double on `with_lock`.
- `TrackingEvent` emission verified per transition.
- `cancellation_reason` enforcement verified.

### 6.2 Migration smoke

```sh
cd backend
bin/rails db:drop db:create db:migrate db:seed RAILS_ENV=development
bin/rails runner 'puts Shipment.group(:status).count.inspect'
```

Expected: a non-empty hash with at least one row per state for which a quote exists.

### 6.3 ActiveAdmin smoke

```sh
bin/rails server
# Open http://localhost:3000/admin/shipments — table renders, click a row,
# verify Tracking log panel and Route panel render.
```

### 6.4 Lint

```sh
bin/rubocop app/models app/admin spec/models spec/factories
```

---

## 7. Acceptance Criteria

(Issue checklist verbatim, plus plan-derived items.)

### From the issue

- [ ] Migraciones aplicadas para `shipments`, `tracking_events`, `routes`.
- [ ] `Shipment.transition_to!` con validación de transiciones permitidas + lock + emisión de `TrackingEvent`.
- [ ] State machine documentada en el modelo (constante `ALLOWED_TRANSITIONS` + comentario con diagrama).
- [ ] ActiveAdmin muestra `Shipment` con su tracking log.
- [ ] Factories + seeds.
- [ ] Specs cubren todas las transiciones permitidas + ≥1 transición rechazada.
- [ ] Identifiers en inglés.

### Plan-derived

- [ ] CHECK constraint at the DB level rejects unknown `Shipment.status` values.
- [ ] `quotes.id` FK on `shipments` declared with `on_delete: :restrict` (Decision J).
- [ ] `shipments.discarded_at` soft-delete column + `default_scope` honoured (ADR-009).
- [ ] `TrackingEvent` admits `kind: gps_update` (lat/lng required) without further migration — required by the future `POST /api/trips/:id/locations` endpoint.
- [ ] `Route` row creatable with all geo / metric fields nullable; `calculated?` predicate works.
- [ ] Scopes documented: `Shipment.{active,completed,in_progress}`, `TrackingEvent.{gps,recent,for_status}`.
- [ ] `delivered → cancelled` is a rejected transition (explicit, with spec coverage).
- [ ] No controllers / API endpoints introduced (out of scope).
- [ ] No `aasm` / `state_machines` gem added (Decision F preserved).
- [ ] `db:seed` is idempotent — re-running does not create duplicate shipments.
- [ ] Coverage ≥ 80% on `app/models/shipment.rb`, `app/models/tracking_event.rb`, `app/models/route.rb`.

---

## 8. Files Summary

### New files

| File | Purpose |
|------|---------|
| `docs/features/REQ/REQ-BE-00022/REQ-BE-00022-implementar-contexto-fulfilment.plan.md` | This plan. |
| `backend/db/migrate/<ts>_create_shipments.rb` | Shipment table. |
| `backend/db/migrate/<ts+1>_create_tracking_events.rb` | TrackingEvent table. |
| `backend/db/migrate/<ts+2>_create_routes.rb` | Route table. |
| `backend/app/models/shipment.rb` | Aggregate root + FSM. |
| `backend/app/models/tracking_event.rb` | Append-only log. |
| `backend/app/models/route.rb` | Calculated route sidecar. |
| `backend/app/admin/shipments.rb` | AA register (read-only) with tracking + route panels. |
| `backend/app/admin/tracking_events.rb` | AA register. |
| `backend/app/admin/routes.rb` | AA register. |
| `backend/spec/factories/shipments.rb` | Factory + per-state traits. |
| `backend/spec/factories/tracking_events.rb` | Factory + kind traits. |
| `backend/spec/factories/routes.rb` | Factory + `:calculated` trait. |
| `backend/spec/models/shipment_spec.rb` | FSM, locking, scopes, soft-delete coverage. |
| `backend/spec/models/tracking_event_spec.rb` | Validations + scopes. |
| `backend/spec/models/route_spec.rb` | Validations + `calculated?`. |

### Modified files

| File | Changes |
|------|---------|
| `backend/db/schema.rb` | Auto-regenerated post-migrate. |
| `backend/db/seeds.rb` | Append idempotent Shipment-per-state block. |
| `backend/Gemfile` / `Gemfile.lock` | Add `factory_bot_rails` + `faker` to `:development, :test` (if not added by 00020). |
| `.gdsi-sdlc/issues/Backlog/REQ-BE-00022-...issue.md` → `Ready/` | Frontmatter `status: ready`, `plan: <path>`. |

### Out of scope (deliberate)

| File / topic | Reason |
|--------------|--------|
| `app/controllers/api/trips_controller.rb` | Endpoint owned by downstream tracking issue. |
| Google Maps Directions integration | Separate issue; `Route` columns nullable until then. |
| Action Cable / SSE for live tracking push | Frontend issue. |
| Triggers for `accepted` / `settled` (US12, REQ-BE-00011, REQ-BE-00018) | Owned by those issues; this plan only allows the transitions. |
| Vehicle / Carrier / Shipper denormalised columns on `Shipment` | Issue spec lists only `quote_id`; flagged in § 3.1. |

---

## 9. Notes for Implementer

- **Branch hygiene**: implement only after `REQ-BE-00020` and `REQ-BE-00021` are merged to `main`. The migration will fail otherwise (no `quotes` table to FK against).
- **Order of writing**: migrations first, run `db:migrate`, then models (so `bin/rails console` can be used to sanity-check associations as the model file grows), then factories, then specs, then ActiveAdmin (cheapest to last).
- **Locking spec**: `with_lock` is hard to truly race-test in a single-process spec runner. The included spec only verifies the call is issued. A concurrency test (two threads attempting the same transition) is appropriate but flaky on SQLite — defer to the integration test suite if/when it gets added.
- **`enum` syntax**: Rails 8 deprecates the positional-hash form. Use `enum :status, { ... }, prefix: true`. The spec uses `s.status_cancelled?` accordingly.
- **CHECK constraint on SQLite**: `add_check_constraint` works on SQLite ≥ 3.37 (Rails 8 ships with newer). If the local SQLite is older, swap to `execute "..."` directly. This matters for `mise`-pinned dev envs.
- **Conventional commit (implementation)**: `feat(fulfilment): add Shipment, TrackingEvent and Route with hand-rolled FSM`. The planning commit is `chore(plan): create plan for REQ-BE-00022`.
- **PR**: open with `--assignee @me` (per project rule).
- **If the orchestrator surfaces a contradiction** between this plan and 00021 (e.g. `quotes` ends up soft-deleted, or `Quote` PK is UUID), revisit § 3 and adjust before the implementation commit.
