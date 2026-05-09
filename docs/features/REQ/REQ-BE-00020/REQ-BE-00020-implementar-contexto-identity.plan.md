# REQ-BE-00020: Implementar contexto Identity — migraciones + modelos AR (User, Carrier, Shipper, Vehicle)

| Field | Value |
|-------|-------|
| **Tag** | REQ-BE-00020 |
| **Title** | Implementar contexto Identity — migraciones + modelos AR (User, Carrier, Shipper, Vehicle) |
| **Priority** | P0 |
| **Status** | READY |
| **Created** | 2026-05-09 |
| **Updated** | 2026-05-09 |
| **Author** | Claude Code |
| **Depends On** | `REQ-BE-00005` (domain model design — must be merged), `INF-BE-00003` (ActiveAdmin scaffold — installed/installable) |
| **Supersedes** | `REQ-BE-00010` (1:N Vehicle expansion — folded into this issue from day one) |
| **Decision Doc** | N/A — single approach. ADRs already locked by `REQ-BE-00005` (ADR-007..010). |
| **Selected Approach** | Translate the ready-to-migrate Identity spec from `docs/02-high-level-design/domain-model.md` § 2 into Rails 8.1 migrations, ActiveRecord models, FactoryBot factories, seeds, ActiveAdmin read-only registrations, and RSpec model specs. |

---

## 1. Problem Statement

`backend/app/models/` currently only holds `ApplicationRecord` plus `AdminUser` (from `INF-BE-00003`). No domain table exists. `REQ-BE-00005` produced the design (ADRs + ERDs + `domain-model.md` § 2 ready-to-migrate spec) but no code. Every downstream backend feature — auth (`REQ-BE-00023`), Marketplace (`REQ-BE-00021`), Fulfilment (`REQ-BE-00022`), payment, tracking, search — is blocked on the four Identity tables existing.

This issue ports the design to code: migrations for `users`, `carriers`, `shippers`, `vehicles`; AR models with validations, associations and role predicates; factories + seeds; ActiveAdmin read-only screens; RSpec specs. **No public API endpoints, no auth flow** — both come in later issues.

The two sibling issues `REQ-BE-00021` (Marketplace) and `REQ-BE-00022` (Fulfilment) are being planned in parallel; their plans depend on the **Downstream Contract** declared in § 3 of this plan.

---

## 2. Solution Design

### 2.1 Approach

Direct translation of `docs/02-high-level-design/domain-model.md` § 2 into Rails 8.1. No new design decisions — ADRs already cover everything.

Sequence:

1. Bundle add `factory_bot_rails`, `faker`, `simplecov` (test/dev only).
2. Generate four migrations (in dependency order: `users`, `carriers`, `shippers`, `vehicles`).
3. Write AR models with validations, associations, scopes, role predicates, `has_secure_password` on `User`.
4. Register the four models in ActiveAdmin as read-only.
5. Add factories and seeds (3 Users, 2 Carriers, 2 Shippers, 2 Vehicles).
6. Write RSpec model specs (validations, associations, role predicates).
7. Verify with `bin/rails db:migrate`, `db:seed`, `rspec`.

### 2.2 Key Design Decisions (all inherited; nothing new)

| Decision | Source | Applied as |
|----------|--------|------------|
| **PK strategy** = `bigint` | ADR-007 | Rails default `t.references` — no override needed. |
| **Role state** = relation-derived (no `is_carrier`/`is_shipper` columns) | ADR-008 | `has_one :carrier`, `has_one :shipper` on `User`; predicates `user.carrier?`, `user.shipper?`; scopes `User.carriers`, `User.shippers`. |
| **Soft-delete** = NOT enabled on Identity tables | ADR-009 | Hard-delete with `dependent: :destroy` cascade from `User → Carrier/Shipper`, from `Carrier → Vehicle`. NO `discarded_at` / `deleted_at` column on any of the four tables. |
| **AdminUser** = isolated | ADR-008 D-section + `INF-BE-00003` | `users` carries no `admin` value; `User` has no relation to `AdminUser`; ActiveAdmin admin-side auth stays Devise. |
| **Geo storage** = N/A in Identity | ADR-010 | Not relevant here; first lat/lng columns appear in Marketplace (`REQ-BE-00021`). |
| **Naming** = English | ADR-008 + glossary | `users`, `carriers`, `shippers`, `vehicles`, `carrier_id`, etc. Zero `transportistas`/`clientes`/`expedidores` anywhere in code. |
| **`password_digest` + `has_secure_password`** | issue § Expected Behavior | Column ships in this issue's `users` migration; `has_secure_password` on `User` model. Auth controllers / sessions are out of scope — column exists so `REQ-BE-00023` can land without another migration. |
| **Vehicle ↔ Carrier** = 1:N from day one | orchestrator decision (collapses `REQ-BE-00010`) | `vehicles.carrier_id` has no unique index; `Carrier has_many :vehicles, dependent: :destroy`. A Carrier can register multiple trucks; the UX flow is sign up → register vehicle → publish TransportWindow. `REQ-BE-00010` is now redundant and should be closed as superseded by this issue. |
| **State machine / FSM** | N/A in Identity | First FSM lives on `Shipment` (`REQ-BE-00022`). |
| **Namespace** = flat | Decision G in `domain-model.md` | All four models directly under `app/models/`. |

### 2.3 Out of Scope

- Auth / session / login controllers (`REQ-BE-00023`).
- Public API endpoints touching Identity (`/api/users`, `/api/carriers/...`).
- Pundit policies — deferred until auth ships.
- Marketplace and Fulfilment models (sibling issues `00021`, `00022`).
- Soft-delete on any Identity entity (ADR-009 excludes them).
- Reviews entity (US17/US21 — separate later issue).
- E2E / integration request specs — model specs only here.
- ActiveAdmin write actions / admin custom forms — read-only is enough.

---

## 3. Downstream Contract (consumed by `REQ-BE-00021` and `REQ-BE-00022`)

> **CRITICAL — siblings depend on these names and types.** This section is the public schema this issue freezes for downstream contexts. Quote it verbatim from sibling plans.

### 3.1 Final table names (all English, plural snake_case)

| Model | Table |
|-------|-------|
| `User` | `users` |
| `Carrier` | `carriers` |
| `Shipper` | `shippers` |
| `Vehicle` | `vehicles` |

### 3.2 Primary-key type

- **`bigint`** for every Identity table (ADR-007). Rails default; no migration override.
- FKs from sibling contexts MUST be declared `t.references :carrier, foreign_key: true, null: false` (or equivalent) — implicitly bigint.

### 3.3 FK column names exposed to siblings

These are the canonical FK column names downstream tables MUST use when referencing Identity. Sibling plans should not invent alternatives:

| FK column (downstream) | Targets | Used by |
|------------------------|---------|---------|
| `carrier_id` | `carriers.id` | `quotes.carrier_id` (Marketplace). NOT denormalised onto `transport_windows` (reachable via `vehicle.carrier`) or `shipments` (reachable via `quote.carrier`). |
| `shipper_id` | `shippers.id` | `cargo_offers.shipper_id` (Marketplace), and later `payments.shipper_id`, `arca_invoices.shipper_id`. NOT denormalised onto `shipments` (reachable via `quote.cargo_offer.shipper`). |
| `vehicle_id` | `vehicles.id` | `transport_windows.vehicle_id` NOT NULL — every TransportWindow hard-links to a specific Vehicle (orchestrator decision). NOT projected onto `quotes` or `shipments` — reachable via `quote.transport_window.vehicle`. |
| `user_id` | `users.id` | Internal to Identity only (`carriers.user_id`, `shippers.user_id`). **Marketplace and Fulfilment tables MUST NOT reference `users` directly** — always go through `carriers` / `shippers`. |

### 3.4 Role predicate API on `User`

```ruby
user.carrier?   # => true if `user.carrier` row exists
user.shipper?   # => true if `user.shipper` row exists

User.carriers   # => scope, users joined to a carrier row
User.shippers   # => scope, users joined to a shipper row
```

These are the names siblings (and `REQ-BE-00023` auth) will call. Do **not** rename to `is_carrier?` / `acts_as_carrier?` etc.

### 3.5 Soft-delete columns on Identity tables

**None.** Per ADR-009, `users`, `carriers`, `shippers`, `vehicles` are hard-deleted. There is **no `discarded_at`** / `deleted_at` / `archived_at` column on any of the four tables.

Cascade rules (so siblings know what survives a delete):

- `User#destroy` cascades to `Carrier` and `Shipper` (`dependent: :destroy`).
- `Carrier#destroy` cascades to its `Vehicle`s (`has_many :vehicles, dependent: :destroy`).
- `Vehicle#destroy` cascades to `TransportWindow`s (`has_many :transport_windows, dependent: :destroy` — declared on `Vehicle` in this issue; the table itself is created by `REQ-BE-00021`). A `before_destroy` guard on `Vehicle` blocks the destroy if any live `Quote` (status not in `expired`/`cancelled`) is tied to one of its windows — so financial/audit rows can never be silently orphaned.
- Sibling tables that FK into Identity should declare their own `dependent:` rule. `quotes.carrier_id` should use `restrict_with_error` to anchor financial rows; the orchestrator-level invariant (no live Quote → Vehicle/Carrier deletable) is enforced by the `before_destroy` guard above.

### 3.6 Identity-side associations (declared in this issue)

```ruby
class User < ApplicationRecord
  has_secure_password
  has_one :carrier, dependent: :destroy
  has_one :shipper, dependent: :destroy
end

class Carrier < ApplicationRecord
  belongs_to :user
  has_many   :vehicles, dependent: :destroy
  # has_many :quotes             ← declared by REQ-BE-00021
end

class Shipper < ApplicationRecord
  belongs_to :user
  # has_many :cargo_offers       ← declared by REQ-BE-00021
  # has_many :payments           ← declared later by Commerce issues
end

class Vehicle < ApplicationRecord
  belongs_to :carrier
  has_many   :transport_windows, dependent: :destroy   # back-ref slot; the table is created by REQ-BE-00021
  before_destroy :ensure_no_active_commitments

  private

  # Hard-deleting a Vehicle cascades its TransportWindows away. We refuse the destroy
  # if any of those windows already back a live Quote (a Shipment-bound contract).
  # The Quote model is created by REQ-BE-00021 — guard tolerates its absence at boot.
  def ensure_no_active_commitments
    return unless defined?(Quote)
    has_live_quote = Quote.joins(:transport_window)
                          .where(transport_windows: { vehicle_id: id })
                          .where.not(status: %w[expired cancelled]).exists?
    throw(:abort) if has_live_quote
  end
end
```

Sibling plans MAY add their own `has_many` back-references on these models when their issues land; this plan reserves the slots above.

---

## 4. Implementation Tasks

| # | Task | Status | Files |
|---|------|--------|-------|
| 1 | Add `factory_bot_rails`, `faker` to `:development, :test` group; add `simplecov` to `:test` group; `bundle install` | Pending | `backend/Gemfile`, `backend/Gemfile.lock` |
| 2 | Configure FactoryBot integration in `rails_helper.rb` (`config.include FactoryBot::Syntax::Methods`) and SimpleCov in `spec_helper.rb` | Pending | `backend/spec/rails_helper.rb`, `backend/spec/spec_helper.rb` |
| 3 | Generate `users` migration: `bigint id`, `email (string, null: false)`, `password_digest (string, null: false)`, `full_name`, `phone`, `verified_at`, timestamps. Index: unique on `email`. **No `dni_or_cuit` on `users`** — fiscal identity belongs to the Carrier/Shipper profile, not the auth account. | Pending | `backend/db/migrate/<ts>_create_users.rb` |
| 4 | Generate `carriers` migration: `bigint id`, `t.references :user, null: false, foreign_key: true, index: { unique: true }`, `legal_name`, `tax_id`, `base_city`, `province`, `rating_avg (decimal(3,2), null: false, default: 0.0)`, `completed_shipments (integer, null: false, default: 0)`, timestamps. Composite index `(province, base_city)`; partial-unique index on `tax_id WHERE tax_id IS NOT NULL`. | Pending | `backend/db/migrate/<ts>_create_carriers.rb` |
| 5 | Generate `shippers` migration: `bigint id`, `t.references :user, null: false, foreign_key: true, index: { unique: true }`, `company_name`, `tax_id`, `billing_address`, timestamps. Partial-unique index on `tax_id WHERE tax_id IS NOT NULL`. | Pending | `backend/db/migrate/<ts>_create_shippers.rb` |
| 6 | Generate `vehicles` migration: `bigint id`, `t.references :carrier, null: false, foreign_key: true`, `plate (string, null: false)`, `capacity_kg (integer, null: false)`, `vehicle_type (string, null: false, default: 'truck_small')`, `gps_enabled (boolean, null: false, default: false)`, timestamps. Unique index on `plate` | Pending | `backend/db/migrate/<ts>_create_vehicles.rb` |
| 7 | Run `bin/rails db:migrate` and verify `db/schema.rb` is regenerated cleanly | Pending | `backend/db/schema.rb` |
| 8 | Implement `User` model (validations, `has_secure_password`, associations, scopes, role predicates, email canonicalisation) | Pending | `backend/app/models/user.rb` |
| 9 | Implement `Carrier` model (validations, associations, scopes) | Pending | `backend/app/models/carrier.rb` |
| 10 | Implement `Shipper` model (validations, associations) | Pending | `backend/app/models/shipper.rb` |
| 11 | Implement `Vehicle` model (validations, vehicle_type enum, associations) | Pending | `backend/app/models/vehicle.rb` |
| 12 | Register `User` in ActiveAdmin (read-only — no `permit_params`, `actions :index, :show`) | Pending | `backend/app/admin/users.rb` |
| 13 | Register `Carrier` in ActiveAdmin read-only | Pending | `backend/app/admin/carriers.rb` |
| 14 | Register `Shipper` in ActiveAdmin read-only | Pending | `backend/app/admin/shippers.rb` |
| 15 | Register `Vehicle` in ActiveAdmin read-only | Pending | `backend/app/admin/vehicles.rb` |
| 16 | Write factories: `:user`, `:carrier`, `:shipper`, `:vehicle`. Use Faker for unique values; sequence on `email` and `plate` | Pending | `backend/spec/factories/users.rb`, `carriers.rb`, `shippers.rb`, `vehicles.rb` |
| 17 | Extend `db/seeds.rb`: 3 Users (carrier1+vehicle, shipper1, both-roles user with carrier+vehicle and shipper). 2 Carriers, 2 Shippers, 2 Vehicles total. Idempotent (`find_or_create_by!`) | Pending | `backend/db/seeds.rb` |
| 18 | Write `User` model spec (validations, password digest, associations, role predicates, scopes, email canonicalisation) | Pending | `backend/spec/models/user_spec.rb` |
| 19 | Write `Carrier` model spec (validations, associations, rating_avg bounds) | Pending | `backend/spec/models/carrier_spec.rb` |
| 20 | Write `Shipper` model spec (validations, associations, tax_id partial-unique) | Pending | `backend/spec/models/shipper_spec.rb` |
| 21 | Write `Vehicle` model spec (validations, plate unique, capacity_kg > 0, vehicle_type enum) | Pending | `backend/spec/models/vehicle_spec.rb` |
| 22 | Run full suite: `cd backend && bin/rails db:reset db:migrate db:seed && bundle exec rspec`. Confirm all green and SimpleCov ≥ 80 % on `app/models/{user,carrier,shipper,vehicle}.rb` | Pending | — |
| 23 | Update `.gdsi-sdlc/issues/Backlog/REQ-BE-00020-...issue.md`: frontmatter `status: ready`, `plan: <path>`. Move to `Ready/` via `git mv` | Done (this planning step) | `.gdsi-sdlc/issues/...` |
| 24 | Conventional Commit: `chore(plan): create plan for REQ-BE-00020` (this planning step). Implementation will land under `feat(identity): add User, Carrier, Shipper, Vehicle models` (separate commit at implement time). | Done (this planning step) | — |

---

## 5. Code Changes

### 5.1 New file: `backend/db/migrate/<ts>_create_users.rb`

```ruby
class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string   :email,           null: false
      t.string   :password_digest, null: false
      t.string   :full_name
      t.string   :phone
      t.datetime :verified_at
      t.timestamps
    end

    add_index :users, :email, unique: true
  end
end
```

> **Tax-id placement**: `tax_id` (CUIT) lives on `carriers` and `shippers`, NOT on `users`. The User is the auth account; the fiscal entity is the Carrier or Shipper profile. A user can have one of each (e.g. an independent transporter who also ships) and may carry two different tax IDs across the two profiles — `users.dni_or_cuit` would have collapsed that. Flag for `docs/02-high-level-design/domain-model.md`: § 2.1 should be updated to remove `dni_or_cuit` from `users`.

### 5.2 New file: `backend/db/migrate/<ts>_create_carriers.rb`

```ruby
class CreateCarriers < ActiveRecord::Migration[8.1]
  def change
    create_table :carriers do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string  :legal_name
      t.string  :tax_id
      t.string  :base_city
      t.string  :province
      t.decimal :rating_avg,          precision: 3, scale: 2, null: false, default: 0.0
      t.integer :completed_shipments, null: false, default: 0
      t.timestamps
    end

    add_index :carriers, [:province, :base_city]
    # Partial-unique — same shape used on `shippers.tax_id` (ADR-002).
    add_index :carriers, :tax_id, unique: true, where: "tax_id IS NOT NULL"
  end
end
```

### 5.3 New file: `backend/db/migrate/<ts>_create_shippers.rb`

```ruby
class CreateShippers < ActiveRecord::Migration[8.1]
  def change
    create_table :shippers do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :company_name
      t.string :tax_id
      t.string :billing_address
      t.timestamps
    end

    add_index :shippers, :tax_id, unique: true, where: "tax_id IS NOT NULL"
  end
end
```

### 5.4 New file: `backend/db/migrate/<ts>_create_vehicles.rb`

```ruby
class CreateVehicles < ActiveRecord::Migration[8.1]
  def change
    create_table :vehicles do |t|
      t.references :carrier, null: false, foreign_key: true
      t.string  :plate,        null: false
      t.integer :capacity_kg,  null: false
      t.string  :vehicle_type, null: false, default: "truck_small"
      t.boolean :gps_enabled,  null: false, default: false
      t.timestamps
    end

    add_index :vehicles, :plate, unique: true
  end
end
```

> **Schema note**: NO unique index on `vehicles.carrier_id` — Carrier has many Vehicles from day one. Seed creates 1 Vehicle per Carrier for demo simplicity but the schema, model, and factories all support N. (`REQ-BE-00010` is superseded by this issue.)

### 5.5 New file: `backend/app/models/user.rb`

```ruby
# frozen_string_literal: true

# User — auth account. A user MAY have a Carrier profile, a Shipper profile, both, or neither.
# Role state is derived from those relation rows — there are NO is_carrier / is_shipper columns
# on this table (ADR-008). See domain-model.md § 2.1.
class User < ApplicationRecord
  has_secure_password

  has_one :carrier, dependent: :destroy
  has_one :shipper, dependent: :destroy

  before_validation :canonicalise_email

  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  # Role accessors (ADR-008). Do NOT denormalise into boolean columns.
  scope :carriers, -> { joins(:carrier).distinct }
  scope :shippers, -> { joins(:shipper).distinct }

  def carrier? = carrier.present?
  def shipper? = shipper.present?

  private

  def canonicalise_email
    self.email = email.to_s.strip.downcase.presence
  end
end
```

### 5.6 New file: `backend/app/models/carrier.rb`

```ruby
# frozen_string_literal: true

# Carrier — Transportista profile. One row per User-with-carrier-role; presence of the row
# IS the role state (ADR-008).
#
# NOTE on Vehicle cardinality: 1:N from day one (orchestrator decision; supersedes REQ-BE-00010).
# Seeds populate one Vehicle per Carrier for demo simplicity; the schema and association
# permit N. UX flow: User signs up → registers Vehicle(s) → publishes TransportWindow(s).
class Carrier < ApplicationRecord
  belongs_to :user
  has_many   :vehicles, dependent: :destroy

  validates :user_id, uniqueness: true
  validates :tax_id,  uniqueness: { allow_blank: true }
  validates :rating_avg,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
  validates :completed_shipments,
            numericality: { greater_than_or_equal_to: 0, only_integer: true }
end
```

### 5.7 New file: `backend/app/models/shipper.rb`

```ruby
# frozen_string_literal: true

# Shipper — Expedidor profile. Replaces the deprecated terms "Cliente" / "Productor"
# (see docs/05-appendices/glossary.md). Presence of this row IS the shipper-role state (ADR-008).
class Shipper < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :tax_id,  uniqueness: { allow_blank: true }
end
```

### 5.8 New file: `backend/app/models/vehicle.rb`

```ruby
# frozen_string_literal: true

# Vehicle — truck owned by a Carrier. SQLite has no native enum, so vehicle_type is stored
# as text and constrained at the AR layer (ADR-002).
#
# Lifecycle: hard-delete via Carrier#destroy cascade is fine for orphaned trucks.
# Direct vehicle.destroy is blocked if any TransportWindow on it backs a live Quote —
# `before_destroy :ensure_no_active_commitments` is the orchestrator-level guard that
# reconciles "Vehicle deleted → its windows cascade away" with "Shipment.quote_id is
# on_delete: :restrict". Empty windows die; live commitments block the destroy.
class Vehicle < ApplicationRecord
  VEHICLE_TYPES = %w[van truck_small truck_large semi_trailer].freeze

  belongs_to :carrier
  has_many :transport_windows, dependent: :destroy   # back-ref; table created by REQ-BE-00021

  before_destroy :ensure_no_active_commitments

  validates :plate,
            presence: true,
            uniqueness: { case_sensitive: false },
            length: { in: 6..8 }
  validates :capacity_kg,  numericality: { greater_than: 0, only_integer: true }
  validates :vehicle_type, inclusion: { in: VEHICLE_TYPES }

  private

  # Refuses to hard-delete if any TransportWindow on this Vehicle has a live (non-terminal)
  # Quote tied to it. Tolerates Quote being absent at boot — REQ-BE-00021 introduces it.
  def ensure_no_active_commitments
    return unless defined?(Quote)
    has_live_quote = Quote.joins(:transport_window)
                          .where(transport_windows: { vehicle_id: id })
                          .where.not(status: %w[expired cancelled]).exists?
    throw(:abort) if has_live_quote
  end
end
```

### 5.9 New files: `backend/app/admin/{users,carriers,shippers,vehicles}.rb`

All four follow the same read-only pattern. Example for `users.rb`:

```ruby
ActiveAdmin.register User do
  actions :index, :show
  config.batch_actions = false

  index do
    selectable_column
    id_column
    column :email
    column :full_name
    column :verified_at
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :email
      row :full_name
      row :phone
      row :verified_at
      row :created_at
      row :updated_at
      row :carrier
      row :shipper
    end
  end
end
```

`carriers.rb`, `shippers.rb`, `vehicles.rb` follow the same shape with the relevant columns. No `permit_params`, no `form do`, no batch actions — read-only is the explicit deliverable.

### 5.10 New file: `backend/spec/factories/users.rb`

```ruby
FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@truckr.test" }
    password { "password123" }
    full_name { Faker::Name.name }
    phone     { Faker::PhoneNumber.cell_phone_in_e164 }

    trait :verified do
      verified_at { Time.current }
    end

    trait :with_carrier do
      after(:create) { |u| create(:carrier, user: u) }
    end

    trait :with_shipper do
      after(:create) { |u| create(:shipper, user: u) }
    end
  end
end
```

`carriers.rb`, `shippers.rb`, `vehicles.rb` factories follow the same convention; `vehicles` uses a `sequence(:plate) { |n| format("AA%03dXX", n) }` to satisfy the 6–8 char rule and uniqueness.

### 5.11 Modified file: `backend/db/seeds.rb`

Add idempotent identity fixtures **after** the existing `AdminUser` block:

```ruby
# Identity fixtures — REQ-BE-00020.
# 3 users: one carrier-only, one shipper-only, one with both roles.
identity_users = [
  { email: "carrier1@truckr.test", full_name: "Carrier One",   role: :carrier },
  { email: "shipper1@truckr.test", full_name: "Shipper One",   role: :shipper },
  { email: "both@truckr.test",     full_name: "Both Roles",    role: :both    }
]

identity_users.each do |spec|
  user = User.find_or_create_by!(email: spec[:email]) do |u|
    u.password  = "password"
    u.full_name = spec[:full_name]
  end

  if %i[carrier both].include?(spec[:role])
    carrier = Carrier.find_or_create_by!(user: user) do |c|
      c.legal_name = "#{spec[:full_name]} Transport SRL"
      c.tax_id     = "30#{format('%08d', user.id)}1"
      c.base_city  = "Buenos Aires"
      c.province   = "CABA"
    end
    Vehicle.find_or_create_by!(carrier: carrier) do |v|
      v.plate        = "AA#{format('%03d', user.id)}XX"
      v.capacity_kg  = 5_000
      v.vehicle_type = "truck_small"
    end
  end

  if %i[shipper both].include?(spec[:role])
    Shipper.find_or_create_by!(user: user) do |s|
      s.company_name = "#{spec[:full_name]} S.A."
      s.tax_id       = "20#{format('%08d', user.id)}9"
    end
  end
end
```

Final counts: 3 Users, 2 Carriers, 2 Shippers, 2 Vehicles — matches the issue acceptance criteria.

### 5.12 New file: `backend/spec/models/user_spec.rb` (sketch)

```ruby
require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
    it "rejects malformed emails" do
      expect(build(:user, email: "nope")).not_to be_valid
    end
    it "enforces email uniqueness case-insensitively" do
      create(:user, email: "Foo@Bar.com")
      expect(build(:user, email: "FOO@bar.com")).not_to be_valid
    end
    it "canonicalises email to lower case" do
      u = create(:user, email: "MIXED@Case.Com")
      expect(u.email).to eq("mixed@case.com")
    end
    it "requires a password (has_secure_password)" do
      expect(build(:user, password: nil)).not_to be_valid
    end
    it "does not have a tax_id column — it lives on Carrier / Shipper" do
      expect(User.column_names).not_to include("tax_id")
      expect(User.column_names).not_to include("dni_or_cuit")
    end
  end

  describe "associations" do
    it { is_expected.to have_one(:carrier).dependent(:destroy) }
    it { is_expected.to have_one(:shipper).dependent(:destroy) }
  end

  describe "role predicates (ADR-008)" do
    let(:user) { create(:user) }

    it "carrier? is false without a carrier row" do
      expect(user.carrier?).to be false
    end

    it "carrier? becomes true when a carrier row exists" do
      create(:carrier, user: user)
      expect(user.reload.carrier?).to be true
    end

    it "shipper? mirrors carrier? but on shippers" do
      expect(user.shipper?).to be false
      create(:shipper, user: user)
      expect(user.reload.shipper?).to be true
    end

    it "scope .carriers returns only users with a carrier row" do
      with_carrier    = create(:user, :with_carrier)
      _without        = create(:user)
      expect(User.carriers).to contain_exactly(with_carrier)
    end
  end
end
```

`carrier_spec.rb`, `shipper_spec.rb`, `vehicle_spec.rb` follow the same shape — validation matchers + association matchers (using `shoulda-matchers` if convenient, otherwise plain RSpec). Each spec MUST cover at least: required fields, uniqueness constraints, association presence/`belongs_to`, the model's distinguishing rule (e.g. `Vehicle` plate format, `Carrier` rating bounds).

> Note: `shoulda-matchers` is not currently in the Gemfile. If we add it (optional, recommended for terseness), include in Task 1: `gem "shoulda-matchers", "~> 6.0", group: %i[test]`. Otherwise specs use plain RSpec — slightly more verbose but no extra dependency.

---

## 6. Testing

### 6.1 Test pyramid for this issue

- **Unit (model specs)** — primary. `spec/models/{user,carrier,shipper,vehicle}_spec.rb`. Coverage target: ≥ 80 % on the four model files (SimpleCov).
- **Integration / request specs** — none. ActiveAdmin pages are scaffolded boilerplate; testing them is low-value at this depth. Smoke spec already exists for `/up`.
- **Migration tests** — implicit via `rails_helper.rb`'s `maintain_test_schema!`.

### 6.2 Verification commands

```sh
cd backend
bundle install
bin/rails db:drop db:create db:migrate    # clean slate
bin/rails db:seed                          # MUST exit 0
bundle exec rspec spec/models              # all green
bundle exec rspec --format documentation   # human-readable summary
# SimpleCov writes to coverage/index.html — verify ≥ 80% on app/models/
```

### 6.3 Manual verification (after implementation)

```sh
bin/rails server
# Visit http://localhost:3000/admin → log in as the seeded AdminUser.
# Confirm: Users, Carriers, Shippers, Vehicles tabs render.
# Confirm: each tab is read-only (no "New" / "Edit" / "Destroy" buttons).
# Confirm: clicking a User shows their carrier/shipper relations inline (Section 5.9 show block).
```

### 6.4 Manual review checklist

- [ ] No `is_carrier` / `is_shipper` boolean column on `users` (ADR-008 enforced).
- [ ] No `discarded_at` / `deleted_at` column on any of the four tables (ADR-009 enforced — Identity is hard-delete).
- [ ] `users.password_digest` is `null: false`; `User` calls `has_secure_password`.
- [ ] `users` has NO `tax_id` / `dni_or_cuit` column — fiscal identity lives on Carrier/Shipper.
- [ ] `carriers.tax_id` and `shippers.tax_id` exist with partial-unique indexes (`WHERE tax_id IS NOT NULL`).
- [ ] All migration filenames are sequential (`db:migrate` runs without skip).
- [ ] `db/schema.rb` reflects every index declared above (unique on email, partial unique on `carriers.tax_id` and `shippers.tax_id`, etc.).
- [ ] Zero Spanish identifiers in migrations or models (`grep -niE '(transportista|cliente|expedidor|productor)' db/migrate app/models app/admin spec` → no hits).
- [ ] Seeds idempotent — running `db:seed` twice does not duplicate rows or raise.
- [ ] ActiveAdmin: no `permit_params`, no `form` blocks, no batch actions on the four registrations.

---

## 7. Acceptance Criteria

(Mirror of the issue's `Acceptance Criteria` checklist, plus plan-derived items.)

**From the issue:**

- [ ] Migraciones para `users`, `carriers`, `shippers`, `vehicles` aplicadas; `db:schema:dump` actualizado.
- [ ] Modelos AR con validaciones + asociaciones + predicados de rol (sin columnas booleanas desnormalizadas).
- [ ] `password_digest` + `has_secure_password` configurado en `User`.
- [ ] ActiveAdmin lista los 4 modelos en read-only.
- [ ] Seeds + factories cargan sin error (`bin/rails db:seed`).
- [ ] Model specs cubren validaciones + asociaciones (≥ 80 % coverage sobre `app/models/{user,carrier,shipper,vehicle}.rb`).
- [ ] CHANGELOG entry no requerido (issue interno).
- [ ] Identifiers en inglés.

**Plan-derived (additional):**

- [ ] `User.carriers` and `User.shippers` scopes + `user.carrier?` / `user.shipper?` predicates exist and are spec-covered (ADR-008 contract surface — sibling plans depend on these names).
- [ ] FK columns and types match § 3 Downstream Contract verbatim (`carrier_id`, `shipper_id`, `vehicle_id`, `user_id`; all bigint; `null: false` where the contract says NOT NULL).
- [ ] No `discarded_at` / `deleted_at` on any of the four Identity tables (ADR-009).
- [ ] `vehicles.carrier_id` has NO unique index (Carrier `has_many :vehicles` from day one; supersedes `REQ-BE-00010`).
- [ ] `User#destroy` cascades to `Carrier`, `Shipper`; `Carrier#destroy` cascades to all `Vehicle`s (`has_many :vehicles, dependent: :destroy`). Verified by spec.
- [ ] `Vehicle#destroy` is blocked when any of its `TransportWindow`s backs a non-terminal `Quote` (`before_destroy :ensure_no_active_commitments`). Spec covers: destroy succeeds when no windows / only terminal quotes; destroy aborts when a live quote exists. The spec is gated on `REQ-BE-00021` having created the `Quote` model — until then, the assertion is `defined?(Quote) || pending`.
- [ ] `bin/rails db:seed` is idempotent (can be re-run on an already-seeded DB without error or duplicate rows).
- [ ] `domain-model.md` § 2 column-by-column spec is implemented exactly — any divergence calls for an updated `domain-model.md` (flag in PR description).

---

## 8. Files Summary

### New Files

| File | Description |
|------|-------------|
| `docs/features/REQ/REQ-BE-00020/REQ-BE-00020-implementar-contexto-identity.plan.md` | This plan. |
| `backend/db/migrate/<ts>_create_users.rb` | Users table migration. |
| `backend/db/migrate/<ts>_create_carriers.rb` | Carriers table migration. |
| `backend/db/migrate/<ts>_create_shippers.rb` | Shippers table migration. |
| `backend/db/migrate/<ts>_create_vehicles.rb` | Vehicles table migration. |
| `backend/app/models/user.rb` | User model — validations, has_secure_password, role predicates. |
| `backend/app/models/carrier.rb` | Carrier model. |
| `backend/app/models/shipper.rb` | Shipper model. |
| `backend/app/models/vehicle.rb` | Vehicle model. |
| `backend/app/admin/users.rb` | ActiveAdmin User read-only registration. |
| `backend/app/admin/carriers.rb` | ActiveAdmin Carrier read-only registration. |
| `backend/app/admin/shippers.rb` | ActiveAdmin Shipper read-only registration. |
| `backend/app/admin/vehicles.rb` | ActiveAdmin Vehicle read-only registration. |
| `backend/spec/factories/users.rb` | FactoryBot User factory. |
| `backend/spec/factories/carriers.rb` | FactoryBot Carrier factory. |
| `backend/spec/factories/shippers.rb` | FactoryBot Shipper factory. |
| `backend/spec/factories/vehicles.rb` | FactoryBot Vehicle factory. |
| `backend/spec/models/user_spec.rb` | User model spec. |
| `backend/spec/models/carrier_spec.rb` | Carrier model spec. |
| `backend/spec/models/shipper_spec.rb` | Shipper model spec. |
| `backend/spec/models/vehicle_spec.rb` | Vehicle model spec. |

### Modified Files

| File | Changes |
|------|---------|
| `backend/Gemfile` | Add `factory_bot_rails`, `faker`, `simplecov` (test/dev only). Optionally `shoulda-matchers`. |
| `backend/Gemfile.lock` | Resolved by `bundle install`. |
| `backend/spec/rails_helper.rb` | Wire `FactoryBot::Syntax::Methods`. |
| `backend/spec/spec_helper.rb` | Start SimpleCov before app load. |
| `backend/db/schema.rb` | Auto-regenerated by `db:migrate`. |
| `backend/db/seeds.rb` | Append Identity fixtures (3 Users, 2 Carriers, 2 Shippers, 2 Vehicles). |
| `.gdsi-sdlc/issues/Backlog/REQ-BE-00020-...issue.md` → `Ready/` | Frontmatter `status: ready`, `plan: <path>`. (Done in this planning step.) |

### Out of Scope (deliberate)

| File / area | Reason |
|-------------|--------|
| `backend/app/controllers/api/**` | No public endpoints in this issue. |
| `backend/app/controllers/sessions_controller.rb` | Auth flow lives in `REQ-BE-00023`. |
| Pundit policies | Deferred until auth ships. |
| `discarded_at` columns | Excluded by ADR-009 for Identity. |
| Marketplace / Fulfilment models | `REQ-BE-00021` / `REQ-BE-00022`. |

---

## 9. Notes for Implementer

- **Sequence migration timestamps so they apply in dependency order** (`users` → `carriers` → `shippers` → `vehicles`). Rails generators produce timestamps automatically; if generated out of order, rename the files.
- **Email canonicalisation**: implemented as `before_validation`, not `before_save`, so the uniqueness check and the persistence both see the lower-cased value. Spec asserts both behaviours.
- **`has_secure_password` requires `bcrypt`**: the gem is commented out in the current `Gemfile`. Uncomment it as part of Task 1 (bundling `factory_bot_rails`).
- **SQLite partial-unique indexes**: confirmed supported on SQLite ≥ 3.8 (Phase 0 baseline per ADR-002). Verify the bundled `sqlite3` gem ships ≥ 3.8 — if not, the partial index can be expressed as a CHECK constraint instead. Document the choice inline in the migration if so.
- **ActiveAdmin compilation**: `dartsass-rails` must compile AA's SCSS during `assets:precompile`. Already wired by `INF-BE-00003`; no additional config in this issue.
- **`shoulda-matchers`**: optional. If included, configure in `rails_helper.rb` per the gem README. Without it, association/validation specs use plain RSpec — slightly more verbose but zero dependency cost.
- **Cross-plan alignment**: this plan's § 3 (Downstream Contract) is the public surface `REQ-BE-00021` and `REQ-BE-00022` quote. If the implementer changes any name or type during implementation, the sibling plans must be updated in the same PR (or a follow-up PR landed before the sibling implementation begins).
- **Conventional Commits**: planning step → `chore(plan): create plan for REQ-BE-00020`. Implementation later → `feat(identity): add User, Carrier, Shipper, Vehicle models`.
- **PR title** (when implementing): `[REQ-BE-00020] feat(identity): implement Identity context (User, Carrier, Shipper, Vehicle)`.
- **PR assignee**: `--assignee @me` per project rule.
