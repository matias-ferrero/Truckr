# REQ-BE-00033: US8 — Realizar pago del expedidor sobre Shipment aceptado (gateway mock)

| Field | Value |
|-------|-------|
| **Tag** | REQ-BE-00033 |
| **Title** | US8 — Realizar pago del expedidor sobre Shipment aceptado (gateway mock) |
| **Priority** | P1 |
| **Status** | READY |
| **Created** | 2026-05-22 |
| **Updated** | 2026-05-22 |
| **Author** | Claude Code |
| **Depends On** | REQ-BE-00024 (US12 — Carrier accepts CargoOffer → Shipment in `accepted`, PR #194). #215 (`discard` gem adoption) develops **in parallel** — not a blocker; conflicts resolved at merge. |
| **Decision Doc** | N/A — canonical decisions live in [ADR-012](../../../01-technical-vision/technical-vision.md) and the issue body itself |
| **Selected Approach** | Per ADR-012: per-attempt `Payment` rows, FSM `pending → escrowed \| rejected` with `escrowed` terminal, fake gateway always-on as production gateway |
| **GitHub Issue** | [#213](https://github.com/tcorzo/fiuba-gestion-tp/issues/213) |
| **PR** | [#214](https://github.com/tcorzo/fiuba-gestion-tp/pull/214) |

---

## 1. Problem Statement

El Expedidor (Shipper) necesita pagar un `Shipment` que el Transportista aceptó (US12). Hoy, el flujo se detiene tras `Shipment.accepted` — el Shipper no tiene forma de confirmar la reserva ni de obtener los datos de contacto del Carrier para coordinar el pickup. Sin pago, no hay viaje.

La pasarela real (MercadoPago) está fuera del MVP (`REQ-BE-00006`). Necesitamos un flujo de pago end-to-end usando **`Payments::FakeGateway`**, una pasarela falsa determinística montada **en todos los entornos, incluyendo producción**, diseñada para ser reemplazada por una real con un swap de inicializador.

El pago debe:

- Estar gateado por autorización (solo el Shipper dueño del Cargo asociado al Shipment).
- Ser reintentable tras un fallo, sin acumular `pending` zombies.
- Desbloquear los datos de contacto del Carrier cuando llega a `escrowed`.
- Funcionar sin tocar la FSM de `Shipment` (el estado "A recoger" es **un label de UI** derivado de `shipment.payments.escrowed.exists?`).

---

## 2. Solution Design

Diseño canónico en **ADR-012** y en el body del issue. Síntesis:

### 2.1 Modelo

- **Tabla `payments`** — 1:N contra `shipments` (cada intento crea fila nueva). Schema completo en § 3.1.
- **FSM `pending → escrowed | rejected`** modelada a mano en `Payment` (mismo patrón que `Shipment.transition_to!`, ver `backend/app/models/shipment.rb:76-84`). `escrowed` es terminal (no settlement en MVP). `rejected` es terminal (Shipper reintenta creando una nueva fila).
- **`amount_cents`** congelado en `create` desde `CargoOffer.amount_cents`. Inmutable post-create vía guard `before_update`.
- **`provider`** enum hardcoded en `"fake"` en MVP.
- **`provider_reference`** asignado por `gateway.create_intent`, indexado para lookups del return-URL.
- **Soft-delete** via `discard` gem. #215 incorpora la gema en paralelo — este PR no espera; si llega antes, no-op; si llega después, este PR incluye la línea de Gemfile y se reconcilia en merge.

### 2.2 Service layer (gateway abstraction)

- **`Payments::Gateway`** (`backend/app/services/payments/gateway.rb`) — módulo-interfaz con `create_intent(shipment:, return_to:)` y `confirm!(provider_reference:, outcome:)`.
- **`Payments::FakeGateway`** (`backend/app/services/payments/fake_gateway.rb`) — implementación determinística. `create_intent` devuelve `Struct(redirect_url:, provider_reference:)` apuntando a `/dev/fake-payment/:provider_reference`. `confirm!` mapea outcome → transición FSM.
- **DI** via `config/initializers/payments.rb` exponiendo `Payments.gateway`. Una sola línea cambia cuando aparezca `Payments::MercadoPagoGateway`. **Sin `Rails.env` guards** — el fake gateway corre en producción.

### 2.3 Controllers / routes

Tres endpoints nuevos, todos heredando del `Api::BaseController` existente (`backend/app/controllers/api/base_controller.rb`):

- **`POST /api/shipments/:id/payments`** → `Api::Shipments::PaymentsController#create`.
- **`GET /api/payments/:id/return?outcome=...`** → `Api::PaymentsController#return`. Idempotente bajo `shipment.with_lock`.
- **`POST /api/payments/:id/abandon`** → `Api::PaymentsController#abandon`.
- **`GET /api/payments/:id`** → `Api::PaymentsController#show` (necesario para que la página `/payments/:id` renderice estado y unlock).

Error envelope estándar (`{ error: { code:, message: } }`) ya patroneado en `BaseController` líneas 47-57. Mensajes vía `I18n.t("errors.payments.*")`.

### 2.4 Policies (Pundit)

- **`PaymentPolicy`** nueva — `create?` (Shipper dueño del Cargo, Shipment en `accepted`, sin `escrowed`, ≤1 `pending`), `show?` (Shipper dueño), `return?` (cualquiera con el `provider_reference` correcto — la auth viene del lookup; ver § 4.6), `abandon?` (Shipper dueño + Payment `pending`).
- **`CarrierPolicy#can_view_contact?(shipper)`** nueva — true si existe `Payment.escrowed` en algún `Shipment` que vincule ese Carrier con ese Shipper.

### 2.5 Resources (Alba)

- **`PaymentResource`** nueva — expone `id`, `shipment_id`, `amount_cents`, `currency`, `status`, `escrowed_at`, `rejected_at`, `created_at`. **NO** expone `provider` ni `provider_reference` (server-side only — confirmado por la "open question" del handoff, default recomendado).
- **`CarrierResource`** modificada — agrega atributos condicionales `full_name`, `email`, `phone` (provenientes de `Carrier.user`). Se incluyen solo si `CarrierPolicy#can_view_contact?(current_shipper)` es true. **Breaking change** del shape ya enviado en PR #194 — confirmado en el handoff que los consumidores internos pueden adaptarse.

### 2.6 Frontend

Tres rutas nuevas + un cambio en el detalle del Shipment:

- **`/shipments/:id/pay`** (Shipper-only, gated con `RequireShipper`).
- **`/dev/fake-payment/:provider_reference`** — pantalla del fake gateway. **Always-on, including production**. Sin auth de sesión; autorizada por posesión del `provider_reference`.
- **`/payments/:id`** — confirmación. Render condicional según `status`.
- **Shipment detail (Shipper view)** — CTA "Pagar" gateada por `shipment.status_accepted? && !shipment.payments.escrowed.exists?`. El label cambia de "Pendiente de pago" a "A recoger" cuando hay un Payment `escrowed`.

API client wrappers en `frontend/src/api/payments.ts` siguiendo el patrón de `frontend/src/api/cargoOffers.ts` (function-per-endpoint, `apiFetch` + `buildAuthHeaders`).

Copy en `frontend/src/pages/shipper/paymentContent.ts` (módulo de copy, mismo patrón que `landingContent.ts`) hasta que aterrice una librería i18n real — política documentada en `CLAUDE.md`. Backend i18n keys bajo `payments.*` en `backend/config/locales/{en,es}.yml`.

### 2.7 Tests

- **Backend**: model specs (FSM, immutability guard, validations, soft-delete), request specs (los 4 endpoints + idempotencia AC11), policy specs, gateway service spec.
- **Frontend**: Vitest para `/shipments/:id/pay`, `/dev/fake-payment/:provider_reference`, `/payments/:id`, MSW handlers en `frontend/src/test/mocks/handlers.ts`.
- **E2E**: Playwright `frontend/e2e/shipper-payment.spec.ts` cubriendo el golden path — Carrier acepta → Shipper paga (aprobado) → Shipper ve "A recoger" + contactos.

---

## 3. Implementation Tasks

| # | Task | Status | Files |
|---|------|--------|-------|
| 1 | Asegurar `discard` gem disponible (incluir línea Gemfile en este PR; #215 paralelo — si ya está, no-op). | Pending | `backend/Gemfile`, `backend/Gemfile.lock` |
| 2 | Crear migración `create_payments` con schema e índices del § 3.1 | Pending | `backend/db/migrate/<ts>_create_payments.rb`, `backend/db/schema.rb` |
| 3 | Crear modelo `Payment` con FSM, enum, validaciones, immutability guard, soft-delete | Pending | `backend/app/models/payment.rb` |
| 4 | Asociaciones: `Shipment has_many :payments`; (opcional) helper `Shipment#contact_unlocked?` | Pending | `backend/app/models/shipment.rb` |
| 5 | Crear `Payments::Gateway` (interfaz) y `Payments::FakeGateway` (impl) | Pending | `backend/app/services/payments/gateway.rb`, `backend/app/services/payments/fake_gateway.rb` |
| 6 | Inicializador DI `Payments.gateway = Payments::FakeGateway` | Pending | `backend/config/initializers/payments.rb` |
| 7 | Rutas: `POST /api/shipments/:id/payments`, `GET /api/payments/:id`, `GET /api/payments/:id/return`, `POST /api/payments/:id/abandon` | Pending | `backend/config/routes.rb` |
| 8 | Controller `Api::Shipments::PaymentsController#create` | Pending | `backend/app/controllers/api/shipments/payments_controller.rb` |
| 9 | Controller `Api::PaymentsController` — `show`, `return`, `abandon`; idempotencia bajo `shipment.with_lock` | Pending | `backend/app/controllers/api/payments_controller.rb` |
| 10 | `PaymentPolicy` (`create?`, `show?`, `return?`, `abandon?`) + `Scope` | Pending | `backend/app/policies/payment_policy.rb` |
| 11 | Extender `CarrierPolicy` con `can_view_contact?(shipper)` | Pending | `backend/app/policies/carrier_policy.rb` |
| 12 | `PaymentResource` (Alba) | Pending | `backend/app/resources/payment_resource.rb` |
| 13 | Modificar `CarrierResource` con shape condicional (contactos detrás de `can_view_contact?`) | Pending | `backend/app/resources/carrier_resource.rb` |
| 14 | i18n keys `payments.*` y `errors.payments.*` en `en.yml` / `es.yml` (+ `activerecord.errors.models.payment`) | Pending | `backend/config/locales/en.yml`, `backend/config/locales/es.yml` |
| 15 | RSpec — model spec | Pending | `backend/spec/models/payment_spec.rb` |
| 16 | RSpec — gateway spec | Pending | `backend/spec/services/payments/fake_gateway_spec.rb` |
| 17 | RSpec — request specs (4 endpoints, idempotencia AC11, autorización AC7) | Pending | `backend/spec/requests/api/payments_spec.rb`, `backend/spec/requests/api/shipments/payments_spec.rb` |
| 18 | RSpec — policy specs | Pending | `backend/spec/policies/payment_policy_spec.rb`, `backend/spec/policies/carrier_policy_spec.rb` |
| 19 | RSpec — `CarrierResource` conditional shape spec | Pending | `backend/spec/resources/carrier_resource_spec.rb` |
| 20 | FE API client `frontend/src/api/payments.ts` | Pending | `frontend/src/api/payments.ts` |
| 21 | FE página `/shipments/:id/pay` | Pending | `frontend/src/pages/shipper/PayShipmentPage.tsx`, `frontend/src/pages/shipper/paymentContent.ts` |
| 22 | FE página `/dev/fake-payment/:provider_reference` — always-on | Pending | `frontend/src/pages/dev/FakeGatewayPage.tsx` |
| 23 | FE página `/payments/:id` (confirmación, condicional por status) | Pending | `frontend/src/pages/shipper/PaymentConfirmationPage.tsx` |
| 24 | FE Shipment detail — CTA "Pagar" gateado, label "A recoger" derivado | Pending | `frontend/src/pages/shipper/ShipmentDetailPage.tsx` (ajuste; ya existe per scaffold) |
| 25 | Routing — agregar las 3 rutas FE | Pending | `frontend/src/App.tsx` o `frontend/src/router.tsx` (el que esté vigente al implementar) |
| 26 | MSW handlers para los 4 endpoints nuevos | Pending | `frontend/src/test/mocks/handlers.ts` |
| 27 | Vitest — specs por página + MSW | Pending | `frontend/src/pages/shipper/__tests__/PayShipmentPage.test.tsx`, etc. |
| 28 | Playwright E2E — `shipper-payment.spec.ts` (golden path) | Pending | `frontend/e2e/shipper-payment.spec.ts` |
| 29 | Pre-PR UI gate: `/critique` → `/polish` → `/audit` sobre las 3 páginas nuevas | Pending | — |
| 30 | Quality gate: `just lint`, `just frontend-test-coverage` (≥80%), `just frontend-test-e2e`, `just backend-test` verdes | Pending | — |
| 31 | PR (sobre #214 existente) — actualizar body con `Closes #213` y link al plan | Pending | PR #214 |

---

## 4. Code Changes

### 4.1 Migration — `backend/db/migrate/<ts>_create_payments.rb`

**Purpose**: tabla `payments` con índices SQLite-compatibles (b-tree).

```ruby
class CreatePayments < ActiveRecord::Migration[7.2]
  def change
    create_table :payments do |t|
      t.references :shipment, null: false, foreign_key: true
      t.integer  :amount_cents, null: false
      t.string   :currency, null: false, default: "ARS"
      t.string   :provider, null: false, default: "fake"
      t.string   :provider_reference
      t.string   :status, null: false, default: "pending"
      t.datetime :escrowed_at
      t.datetime :rejected_at
      t.datetime :discarded_at
      t.timestamps
    end

    add_index :payments, [:shipment_id, :status]
    add_index :payments, :provider_reference, unique: true, where: nil
    add_index :payments, :discarded_at
  end
end
```

**SQLite note**: `unique: true` sobre `provider_reference` es portable. `where:` se deja nil para evitar partial-index Postgres-isms (política SQLite-forever).

### 4.2 Model — `backend/app/models/payment.rb`

**Purpose**: FSM, immutability, soft-delete. Espeja el patrón de `Shipment` (líneas 40, 76-84, 115-120).

```ruby
class Payment < ApplicationRecord
  include Discard::Model            # #215 parallel — ver § 9 R1
  default_scope -> { kept }

  STATUSES = %w[pending escrowed rejected].freeze
  PROVIDERS = %w[fake mercadopago stripe other].freeze
  ALLOWED_TRANSITIONS = {
    pending: %i[escrowed rejected]
  }.freeze

  belongs_to :shipment

  enum :status, STATUSES.index_with(&:itself), prefix: true
  enum :provider, PROVIDERS.index_with(&:itself), prefix: true

  validates :amount_cents, numericality: { greater_than: 0 }
  validates :currency, presence: true
  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validate  :timestamps_match_status
  validate  :amount_cents_immutable, on: :update

  class IllegalTransition < StandardError; end

  def transition_to!(new_status, at: Time.current)
    new_status = new_status.to_sym
    transaction do
      with_lock do
        from = status.to_sym
        unless ALLOWED_TRANSITIONS.fetch(from, []).include?(new_status)
          raise IllegalTransition, "Payment #{id}: #{from} -> #{new_status} not allowed"
        end
        case new_status
        when :escrowed then update!(status: :escrowed, escrowed_at: at)
        when :rejected then update!(status: :rejected, rejected_at: at)
        end
      end
    end
  end

  private

  def timestamps_match_status
    case status.to_sym
    when :escrowed then errors.add(:escrowed_at, :blank) if escrowed_at.blank?
    when :rejected then errors.add(:rejected_at, :blank) if rejected_at.blank?
    end
  end

  def amount_cents_immutable
    errors.add(:amount_cents, :immutable) if amount_cents_changed?
  end
end
```

### 4.3 Service — `backend/app/services/payments/gateway.rb` + `fake_gateway.rb`

**Purpose**: interfaz mínima para que el adapter real sea swap-in.

```ruby
# app/services/payments/gateway.rb
module Payments
  Intent = Struct.new(:redirect_url, :provider_reference, keyword_init: true)

  module Gateway
    def create_intent(shipment:, return_to:); raise NotImplementedError; end
    def confirm!(payment:, outcome:);          raise NotImplementedError; end
  end
end
```

```ruby
# app/services/payments/fake_gateway.rb
module Payments
  module FakeGateway
    extend Gateway
    module_function

    def create_intent(shipment:, return_to:)
      reference = "fake_#{SecureRandom.hex(8)}"
      Intent.new(
        provider_reference: reference,
        redirect_url: Rails.application.routes.url_helpers.dev_fake_payment_path(reference, return_to:)
      )
    end

    def confirm!(payment:, outcome:)
      case outcome.to_s
      when "approved" then payment.transition_to!(:escrowed)
      when "rejected" then payment.transition_to!(:rejected)
      when "pending"  then nil   # no-op; Shipper recovers via abandon
      else raise ArgumentError, "unknown outcome=#{outcome.inspect}"
      end
    end
  end
end
```

```ruby
# config/initializers/payments.rb
Rails.application.config.to_prepare do
  Payments.singleton_class.attr_accessor :gateway
  Payments.gateway = Payments::FakeGateway
end
```

### 4.4 Routes — `backend/config/routes.rb`

Insertar dentro del `namespace :api` existente (después del bloque `:cargos`, antes del cierre):

```ruby
resources :shipments, only: [] do
  resources :payments, only: :create, controller: "shipments/payments"
end

resources :payments, only: %i[show] do
  member do
    get  :return,  to: "payments#return"
    post :abandon, to: "payments#abandon"
  end
end
```

### 4.5 Controller — `Api::Shipments::PaymentsController#create`

```ruby
class Api::Shipments::PaymentsController < Api::BaseController
  before_action :require_shipper!

  def create
    shipment = Shipment.find(params[:shipment_id])
    authorize shipment, policy_class: PaymentPolicy

    payment = Payment.new(
      shipment: shipment,
      amount_cents: shipment.cargo_offer.amount_cents,
      currency: shipment.cargo_offer.currency,
      provider: "fake"
    )
    intent = Payments.gateway.create_intent(shipment: shipment, return_to: payment_return_url(payment))
    payment.provider_reference = intent.provider_reference
    payment.save!

    render json: { payment_id: payment.id, redirect_url: intent.redirect_url }, status: :created
  end
end
```

### 4.6 Controller — `Api::PaymentsController`

```ruby
class Api::PaymentsController < Api::BaseController
  def show
    payment = Payment.find(params[:id])
    authorize payment
    render json: PaymentResource.new(payment).serialize
  end

  def return
    # Lookup-by-reference path: gateway no carga sesión.
    payment = Payment.find(params[:id])
    payment.shipment.with_lock do
      payment.reload
      return redirect_to_confirmation(payment) unless payment.status_pending?
      Payments.gateway.confirm!(payment: payment, outcome: params[:outcome])
    end
    redirect_to_confirmation(payment)
  end

  def abandon
    payment = Payment.find(params[:id])
    authorize payment
    payment.transition_to!(:rejected) if payment.status_pending?
    head :no_content
  end

  private

  def redirect_to_confirmation(payment)
    redirect_to "#{ENV.fetch('FRONTEND_BASE_URL', '')}/payments/#{payment.id}", allow_other_host: true
  end
end
```

**Idempotencia AC11**: el `with_lock` + early return cuando `status != pending` garantiza que dos hits concurrentes del return-URL no dupliquen la transición.

### 4.7 Policy — `backend/app/policies/payment_policy.rb`

```ruby
class PaymentPolicy < ApplicationPolicy
  # record es Shipment en #create; Payment en el resto.
  def create?
    shipper = user&.shipper
    return false unless shipper
    return false unless record.is_a?(Shipment) && record.status_accepted?
    return false unless record.cargo_offer.cargo.shipper_id == shipper.id
    return false if record.payments.status_escrowed.exists?
    return false if record.payments.status_pending.count >= 1
    true
  end

  def show?
    record.shipment.cargo_offer.cargo.shipper_id == user&.shipper&.id
  end

  def abandon?
    show? && record.status_pending?
  end
end
```

### 4.8 Policy — `CarrierPolicy#can_view_contact?`

```ruby
class CarrierPolicy < ApplicationPolicy
  # ...existing methods...

  def can_view_contact?(shipper = user&.shipper)
    return false unless shipper
    Payment
      .status_escrowed
      .joins(shipment: { cargo_offer: :cargo })
      .where(cargo_offers: { carrier_id: record.id }, cargos: { shipper_id: shipper.id })
      .exists?
  end
end
```

### 4.9 Resource — `PaymentResource`

```ruby
class PaymentResource
  include Alba::Resource
  attributes :id, :shipment_id, :amount_cents, :currency,
             :status, :escrowed_at, :rejected_at, :created_at
  # provider / provider_reference are server-side only.
end
```

### 4.10 Resource — `CarrierResource` (modificación)

```ruby
class CarrierResource
  include Alba::Resource
  attributes :id, :legal_name, :tax_id, :base_city, :province,
             :rating_avg, :reviews_count, :completed_shipments

  attribute :full_name, if: proc { CarrierPolicy.new(params[:current_user], object).can_view_contact? } do |c|
    c.user.full_name
  end
  attribute :email, if: proc { CarrierPolicy.new(params[:current_user], object).can_view_contact? } do |c|
    c.user.email
  end
  attribute :phone, if: proc { CarrierPolicy.new(params[:current_user], object).can_view_contact? } do |c|
    c.user.phone
  end
end
```

Callers must pass `params: { current_user: current_user }`. **Breaking change** vs PR #194 — confirm before merge (open question § 10).

### 4.11 i18n — `backend/config/locales/en.yml` (mirror in `es.yml`)

```yaml
en:
  errors:
    payments:
      forbidden_not_owner: "Only the cargo's shipper can pay."
      shipment_not_accepted: "Shipment must be accepted before payment."
      already_escrowed: "This shipment has already been paid."
      pending_exists: "A pending payment exists. Abandon it before retrying."
      unknown_outcome: "Unknown payment outcome."
  payments:
    statuses:
      pending: "Processing"
      escrowed: "Paid"
      rejected: "Failed"
  activerecord:
    errors:
      models:
        payment:
          attributes:
            amount_cents:
              immutable: "cannot be changed after creation"
            escrowed_at:
              blank: "must be set when status is escrowed"
            rejected_at:
              blank: "must be set when status is rejected"
```

### 4.12 Frontend API client — `frontend/src/api/payments.ts`

```typescript
import { apiFetch, buildAuthHeaders } from "../api";

export type PaymentStatus = "pending" | "escrowed" | "rejected";

export type Payment = {
  id: number;
  shipment_id: number;
  amount_cents: number;
  currency: string;
  status: PaymentStatus;
  escrowed_at: string | null;
  rejected_at: string | null;
  created_at: string;
};

export async function createPayment(shipmentId: number): Promise<{ payment_id: number; redirect_url: string }> {
  return apiFetch(`/api/shipments/${shipmentId}/payments`, {
    method: "POST",
    headers: buildAuthHeaders(),
  });
}

export async function getPayment(id: number): Promise<Payment> {
  return apiFetch(`/api/payments/${id}`, { headers: buildAuthHeaders() });
}

export async function abandonPayment(id: number): Promise<void> {
  await apiFetch(`/api/payments/${id}/abandon`, { method: "POST", headers: buildAuthHeaders() });
}
```

### 4.13 FE pages

- `PayShipmentPage.tsx`: muestra monto formateado, summary del Carrier (sin contactos), CTA "Pagar". `onClick` → `createPayment` → `window.location.assign(redirect_url)`. Si hay `pending`, ofrece `abandonPayment` antes de reintentar.
- `FakeGatewayPage.tsx`: tres botones. Cada uno hace `GET /api/payments/:id/return?outcome=<approved|rejected|pending>` directamente como navegación (sin auth de sesión — autorizada por el `provider_reference` en el path del fake gateway → `payment.id` resuelto en server vía lookup, ver § 4.6). **No env-gated** — siempre renderiza.
- `PaymentConfirmationPage.tsx`: hace `getPayment`, switch sobre `status`. Cuando `escrowed`, además fetch del Carrier (que ya retorna contactos por `CarrierPolicy`).

Copy en `frontend/src/pages/shipper/paymentContent.ts` (Spanish, mismo pattern que `landingContent.ts`).

---

## 5. Testing

### 5.1 Unit / model

- `Payment` valida `amount_cents > 0`, `currency` presente.
- `transition_to!`:
  - `pending → escrowed` setea `escrowed_at`.
  - `pending → rejected` setea `rejected_at`.
  - `escrowed → rejected` raises `IllegalTransition`.
  - `escrowed → escrowed` raises.
- `amount_cents_immutable` rechaza updates a `amount_cents`.
- `timestamps_match_status` valida que los timestamps acompañen el status.
- `default_scope -> { kept }` excluye `discarded` (#215 paralelo; ver § 9 R1).

### 5.2 Service

- `FakeGateway.create_intent` retorna `Intent` con `provider_reference` único y `redirect_url` que apunta a `/dev/fake-payment/:reference`.
- `FakeGateway.confirm!` mapea outcomes correctamente y propaga `IllegalTransition`.

### 5.3 Request specs

- **`POST /api/shipments/:id/payments`**:
  - Shipper dueño + Shipment `accepted` → 201, body con `payment_id` y `redirect_url`, fila creada en `pending`.
  - Otro Shipper → 403.
  - Carrier autenticado → 403.
  - Shipment no-`accepted` → 409.
  - Ya hay `escrowed` → 409.
  - Ya hay `pending` → 409.
- **`GET /api/payments/:id/return?outcome=approved`** → transition a `escrowed`, redirige a `/payments/:id`.
- **`GET /api/payments/:id/return?outcome=rejected`** → transition a `rejected`.
- **`GET /api/payments/:id/return?outcome=pending`** → no-op, redirige.
- **AC11 idempotencia**: dos requests concurrentes (`Thread.new` × 2, esperar ambos) con `outcome=approved` resultan en una sola transición; el segundo no duplica side-effects.
- **`POST /api/payments/:id/abandon`** → 204 si Shipper dueño + Payment `pending`; 403 si otro Shipper; 409 si no `pending`.

### 5.4 Policy specs

- `PaymentPolicy#create?`: cubrir las 4 condiciones (owner, accepted, no escrowed, no pending).
- `CarrierPolicy#can_view_contact?`: false hasta que exista `Payment.escrowed` linkeando ese Carrier-Shipper; true después.

### 5.5 Resource spec

- `CarrierResource` con `current_user` que no califica → no incluye `full_name`/`email`/`phone`.
- `CarrierResource` con `current_user` que sí → incluye los 3 atributos.

### 5.6 Frontend

- Vitest specs por página con MSW. Branches:
  - `PayShipmentPage` renderiza monto formateado; click CTA → llama `createPayment` y navega.
  - `PayShipmentPage` con `pending` existente → muestra "pago en curso" + abandon CTA.
  - `FakeGatewayPage` renderiza 3 botones; click navega a `/api/payments/.../return?outcome=...`.
  - `PaymentConfirmationPage` con `escrowed` → muestra contactos; con `rejected` → CTA retry; con `pending` → CTA cancel.
- Coverage threshold ≥80% (ver `frontend/vitest.config.ts`).

### 5.7 E2E

`frontend/e2e/shipper-payment.spec.ts`:

1. Login como Shipper que tiene un Shipment `accepted`.
2. Navegar al detalle, click "Pagar" → llega a `/shipments/:id/pay`.
3. Click "Pagar" → llega a `/dev/fake-payment/:reference` (fake gateway).
4. Click "Aprobar" → llega a `/payments/:id` con mensaje de éxito + contactos del Carrier visibles.
5. Volver al detalle del Shipment → label "A recoger" presente; CTA "Pagar" ausente.

---

## 6. Acceptance Criteria

Mapping ACs del issue → coverage en este plan:

- [ ] **AC1** — CTA "Pagar" gateada por `shipment.status_accepted?` en `ShipmentDetailPage` (Task 24).
- [ ] **AC2** — Label "A recoger" derivado de `shipment.payments.escrowed.exists?` en FE. **Sin cambio en FSM de Shipment** (verificado con E2E paso 5).
- [ ] **AC3** — `CarrierResource` expone contactos cuando `CarrierPolicy#can_view_contact?` (Task 11, 13; resource spec § 5.5).
- [ ] **AC4** — Mensaje de error + retry sin perder contexto en `PaymentConfirmationPage` rejected branch (Task 23).
- [ ] **AC5** — `amount_cents` copiado de `CargoOffer.amount_cents` en `create` (Task 8).
- [ ] **AC6** — `FakeGateway` always-on, sin `Rails.env` guards; `/dev/fake-payment/:reference` siempre montada (Task 5, 22). Verificado por E2E.
- [ ] **AC7** — `PaymentPolicy#create?` restringe a Shipper dueño; 403 para otros (Task 10; request spec § 5.3).
- [ ] **AC8** — Retry permitido si no hay `escrowed`; `pending` se abandona vía `POST /api/payments/:id/abandon` (Task 9, 10; request spec § 5.3).
- [ ] **AC9** — `CarrierPolicy#can_view_contact?` gate the contact reveal (Task 11; spec § 5.5).
- [ ] **AC10** — Cero literales hardcoded. Backend usa `I18n.t`. FE usa `paymentContent.ts`. Verificado en code review.
- [ ] **AC11** — `shipment.with_lock` + early-return en `#return`; spec con 2 requests concurrentes (Task 9, § 5.3).
- [ ] **AC12** — Guard `amount_cents_immutable` (Task 3; model spec § 5.1).
- [ ] **AC13** — `Payment` `include Discard::Model`, `default_scope -> { kept }`, índice en `discarded_at`. #215 paralelo — ver § 9 R1.
- [ ] Quality gate (Task 30): `just lint`, `just frontend-test-coverage` (≥80%), `just frontend-test-e2e`, `just backend-test` verdes.
- [ ] Pre-PR UI gate (Task 29): `/critique` → `/polish` → `/audit` ejecutados sobre las 3 páginas.

---

## 7. Files Summary

### New Files

| File | Description |
|------|-------------|
| `backend/db/migrate/<ts>_create_payments.rb` | `payments` table + indexes |
| `backend/app/models/payment.rb` | FSM, immutability, soft-delete |
| `backend/app/services/payments/gateway.rb` | Gateway interface module |
| `backend/app/services/payments/fake_gateway.rb` | Fake gateway impl (production gateway) |
| `backend/config/initializers/payments.rb` | DI wiring (`Payments.gateway`) |
| `backend/app/controllers/api/shipments/payments_controller.rb` | `create` |
| `backend/app/controllers/api/payments_controller.rb` | `show`, `return`, `abandon` |
| `backend/app/policies/payment_policy.rb` | Pundit policy |
| `backend/app/resources/payment_resource.rb` | Alba resource |
| `backend/spec/models/payment_spec.rb` | Model specs |
| `backend/spec/services/payments/fake_gateway_spec.rb` | Gateway specs |
| `backend/spec/requests/api/payments_spec.rb` | Request specs for top-level controller |
| `backend/spec/requests/api/shipments/payments_spec.rb` | Request specs for nested create |
| `backend/spec/policies/payment_policy_spec.rb` | Policy specs |
| `backend/spec/policies/carrier_policy_spec.rb` | `can_view_contact?` specs |
| `backend/spec/resources/carrier_resource_spec.rb` | Conditional shape specs |
| `frontend/src/api/payments.ts` | FE API client |
| `frontend/src/pages/shipper/PayShipmentPage.tsx` | Shipper-only payment entry page |
| `frontend/src/pages/shipper/PaymentConfirmationPage.tsx` | `/payments/:id` |
| `frontend/src/pages/shipper/paymentContent.ts` | Spanish copy bundle |
| `frontend/src/pages/dev/FakeGatewayPage.tsx` | `/dev/fake-payment/:reference` |
| `frontend/src/pages/shipper/__tests__/PayShipmentPage.test.tsx` | Vitest |
| `frontend/src/pages/shipper/__tests__/PaymentConfirmationPage.test.tsx` | Vitest |
| `frontend/src/pages/dev/__tests__/FakeGatewayPage.test.tsx` | Vitest |
| `frontend/e2e/shipper-payment.spec.ts` | Playwright golden path |

### Modified Files

| File | Changes |
|------|---------|
| `backend/Gemfile` / `Gemfile.lock` | Add `discard` gem (idempotent with #215 — whichever lands first wins, the other rebases) |
| `backend/db/schema.rb` | Updated by migration |
| `backend/app/models/shipment.rb` | `has_many :payments` (and optional `contact_unlocked?` helper) |
| `backend/app/policies/carrier_policy.rb` | Add `can_view_contact?` |
| `backend/app/resources/carrier_resource.rb` | Conditional contact attrs |
| `backend/app/controllers/api/base_controller.rb` | No change expected; `require_shipper!` ya existe (PR #194) |
| `backend/config/routes.rb` | 4 new routes |
| `backend/config/locales/en.yml` + `es.yml` | `payments.*` + `errors.payments.*` + `activerecord.errors.models.payment` |
| `frontend/src/pages/shipper/ShipmentDetailPage.tsx` | CTA "Pagar" + label "A recoger" |
| `frontend/src/App.tsx` (o `router.tsx`) | Mount 3 new routes |
| `frontend/src/test/mocks/handlers.ts` | 4 new MSW handlers |
| `docs/features/ISSUES-INDEX.md` | Status `READY` → `RDY`, add plan link |

---

## 8. Out of Scope (deferido por ADR-012)

- Integración real con MercadoPago (`REQ-BE-00006`).
- Settlement / release del escrow — `PaymentSettlementJob` **no existe** y `scheduled-jobs.md` lo refleja.
- Refunds, disputes (post-MVP).
- Timeout job para `pending` zombies — Shipper-initiated `abandon` cubre la recuperación.
- Notificaciones email de cambios de estado (depende de `INF-BE-00005`).

---

## 9. Risks

| # | Risk | Mitigation |
|---|------|------------|
| R1 | **`discard` gem en Gemfile.** #215 lo agrega en paralelo. | Este PR incluye `gem 'discard'` y la `default_scope` defensivamente. Quien mergee segundo rebasea — `Gemfile`/`Gemfile.lock` son idempotentes. No es blocker. |
| R2 | **`CarrierResource` breaking shape change.** PR #194 ya envió el shape sin contactos; este plan agrega 3 atributos condicionales. Cualquier consumidor que parsee strict podría fallar. | Confirmado en el handoff que los consumidores son internos. La condicional `if:` significa que callers que no pasen `current_user` siguen viendo el shape viejo. |
| R3 | **Idempotencia del return-URL** bajo `with_lock` solo funciona si dos requests llegan al mismo proceso. Con multi-puma worker es safe (DB lock); con `single_process` también. | `with_lock` toma row-lock en DB — funciona cross-process. Documentado en el spec § 5.3 con threads. |
| R4 | **Fake gateway always-on en producción.** Riesgo de uso accidental por external actors. | Es la pasarela del MVP por diseño (ADR-012). La autorización del flujo está en `PaymentPolicy#create?`. El `provider_reference` es un secret-by-obscurity para el return-URL. |
| R5 | **Coverage threshold 80%.** Tests deben aterrizar junto al código para no romper el gate. | Tasks 15-19 (BE) y 27-28 (FE) son obligatorios; nada se mergea sin verde. |

---

## 10. Open Questions (no-blocker)

Resueltas todas durante triage + grilling. Las siguientes son las únicas pendientes si surgen en implementación:

1. **i18n keys exactas** bajo `payments.*` — el plan propone una estructura (§ 4.11); confirmar antes de mergear si toca claves compartidas.
2. **`CarrierResource` shape change** — confirmar que ningún caller existente espera el shape pre-cambio. (Handoff: probablemente todos pueden adaptarse — interno.)
3. **Exposición de `provider` / `provider_reference` en JSON** — default: **server-side only**. Si la FE necesita uno de ellos (no debería), levantar antes de implementar.

Si alguna pregunta más surge en implementación, **levantar y enmendar ADR-012 antes de divergir** — no decisión silenciosa.

---

## 11. References

- Issue body: [REQ-BE-00033 — `.gdsi-sdlc/issues/Ready/REQ-BE-00033-us8-realizar-pago-expedidor.issue.md`](../../../.gdsi-sdlc/issues/Ready/REQ-BE-00033-us8-realizar-pago-expedidor.issue.md)
- **ADR-012** — `docs/01-technical-vision/technical-vision.md` (search `### ADR-012`)
- Domain model: `docs/02-high-level-design/domain-model.md` § 1, § 4.1, § 5.1
- Appendices: `api-overview.md`, `external-systems.md`, `scheduled-jobs.md`, `glossary.md`
- Patterns mirrored from: `backend/app/models/shipment.rb` (FSM), `backend/app/controllers/api/base_controller.rb` (auth helpers + error envelope), `backend/app/policies/cargo_policy.rb` (Pundit), `backend/app/resources/carrier_resource.rb` (Alba)
- Build/test commands: `CLAUDE.md` (build commands + pre-PR quality gate)
