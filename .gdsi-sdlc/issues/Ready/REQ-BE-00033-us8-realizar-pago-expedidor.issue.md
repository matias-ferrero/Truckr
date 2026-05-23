---
tag: REQ-BE-00033
title: US8 — Realizar pago del expedidor sobre Shipment aceptado (gateway mock)
priority: P1
status: ready
created: '2026-05-22'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/213
author: Claude Code
github_issue: 213
github_repo: tcorzo/fiuba-gestion-tp
plan: docs/features/REQ/REQ-BE-00033/REQ-BE-00033-us8-realizar-pago-expedidor.plan.md
labels:
- REQ
- BE
- FE
- payments
- mvp
- us8
- P1
- checkout
---

## Summary

El Expedidor (Shipper) paga el `Shipment` que el Transportista aceptó (US12), desbloqueando los datos de contacto del Carrier y habilitando el pickup. El pago se modela como un `Payment` ligado al `Shipment` con FSM mínima (`pending → escrowed | rejected`). La pasarela real (MercadoPago) está diferida — `Payments::FakeGateway` es la pasarela del MVP **en todos los entornos, incluyendo producción**. El diseño de dominio queda alineado con `ADR-012` para que la incorporación de un gateway real sea swap-in de una clase.

## Decisiones canónicas (ver ADR-012)

| Tema | Decisión |
|---|---|
| FSM `Payment` | `pending → escrowed \| rejected`. `escrowed` es terminal (no hay settlement / release en el MVP). |
| FK | `Payment belongs_to :shipment` (1:N — per-attempt rows). |
| Creación | En el click "Pagar" del Shipper (no se abre `Payment` al accept). |
| Multiplicidad | `Shipment has_many :payments`. AC9 (retry) crea filas nuevas. |
| Soft-delete | Vía `discard` gem (alineado con #215). `discarded_at` en `payments`. |
| `amount_cents` | Congelado en `create` desde `CargoOffer.amount_cents`. Inmutable. |
| `provider` enum | `fake \| mercadopago \| stripe \| other`. MVP escribe `fake`. |
| `provider_reference` | String — id que devuelve el gateway (fake o real). |
| Estados `refunded` / `disputed` | **Fuera del MVP**. No se modelan. |
| Settlement job | **Fuera del MVP**. No hay `escrowed → released`. |
| Timeout job | **Fuera del MVP**. Stuck-pending se recupera con `abandon!`. |
| Fake gateway | **Siempre activo, incluso en producción**. No hay env-gate. Es la pasarela del MVP. |
| Endpoint create | `POST /api/shipments/:id/payments`. |
| Endpoint callback | `GET /api/payments/:id/return?outcome=...` (return-URL, no webhook). |
| Endpoint abandon | `POST /api/payments/:id/abandon`. |
| Shipment FSM | **Sin cambios**. "A recoger" es label de UI derivado de `shipment.payments.escrowed.exists?`. |
| Contact-info reveal | `CarrierResource` con shape condicional via `CarrierPolicy#can_view_contact?`. |
| Contact-info fields | `users.full_name / email / phone` accedido via `Carrier.user`. No se agregan columnas. |

## User story (fuente)

`docs/artifacts/backlog-us.typ:167-184`:

> Como expedidor, quiero poder pagar de forma segura una vez que el transportista aceptó mi viaje, para reservar el servicio y cumplir con mi parte del trato.

## Acceptance criteria

ACs originales del artefacto:

- [ ] **AC1**: Una vez aceptado el viaje por el transportista, se habilita la opción de realizar el pago.
- [ ] **AC2**: Al completarse el pago, el viaje pasa **instantáneamente** a la presentación "a recoger" en la UI del Shipper. (Implementación: el `Shipment.status` se mantiene en `accepted`; el label "a recoger" se deriva de `shipment.payments.escrowed.exists?`. No hay cambio en la FSM de `Shipment`.)
- [ ] **AC3**: Una vez completado el pago, se otorgan los datos de contacto del transportista (`full_name`, `email`, `phone`) al Shipper.
- [ ] **AC4**: Si el pago falla, se muestra un mensaje de error y se permite reintentar sin perder el contexto de la oferta.
- [ ] **AC5**: El monto del pago corresponde al precio acordado en la oferta aceptada (`Payment.amount_cents = CargoOffer.amount_cents` congelado en `create`).

ACs de implementación:

- [ ] **AC6**: La pasarela es `Payments::FakeGateway`, determinística, montada en **todos los entornos incluyendo producción**. Permite forzar `aprobado`, `rechazado` o `pendiente` desde la UI de prueba (`/dev/fake-payment/:provider_reference`).
- [ ] **AC7**: Solo el Expedidor dueño del `Cargo` puede iniciar el pago (Pundit `PaymentPolicy#create?`). Otros roles reciben `403`.
- [ ] **AC8**: Reintentar el pago tras un fallo es posible mientras no exista un `Payment` `escrowed` para ese `Shipment`. Cada reintento crea una fila nueva. Si existe un `Payment` `pending`, el Shipper puede abandonarlo (`POST /api/payments/:id/abandon`) para desbloquear el retry.
- [ ] **AC9**: Los datos de contacto del Transportista no son visibles para el Expedidor hasta que exista un `Payment.escrowed` para ese `Shipment`. `CarrierResource` omite `email` / `phone` / `full_name` cuando `CarrierPolicy#can_view_contact?(current_shipper)` es falso.
- [ ] **AC10**: Todas las cadenas visibles al usuario (UI + error messages) pasan por claves de i18n. Cero literales hardcoded en JSX ni en controllers.
- [ ] **AC11**: `GET /api/payments/:id/return` es idempotente — request specs con dos llamadas concurrentes confirman que no se duplican side-effects (notificaciones, unlocks). Implementación: `shipment.with_lock { return if payment.status_escrowed? || payment.status_rejected?; ... }`.
- [ ] **AC12**: `Payment.amount_cents` queda congelado al valor de `CargoOffer.amount_cents` en el momento de creación. Cambios posteriores al precio del `CargoOffer` no afectan al `Payment` ya creado.
- [ ] **AC13**: `Payment` soporta soft-delete vía `discard` gem (alineado con #215). `discarded_at` indexado para consultas de audit. `default_scope` filtra discarded.

## Domain model

### Schema (`payments` table)

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | `bigint` | no | — | PK. |
| `shipment_id` | `bigint` | no | — | FK → `shipments.id`. **No `unique` index** — 1:N (per-attempt). |
| `amount_cents` | `integer` | no | — | Frozen from `CargoOffer.amount_cents` at create. Immutable post-create (model-level guard). |
| `currency` | `string` | no | `"ARS"` | Default ARS, unused for the time being. |
| `provider` | `string` | no | `"fake"` | Enum: `fake \| mercadopago \| stripe \| other`. MVP writes `"fake"`. |
| `provider_reference` | `string` | yes | — | Set by `gateway.create_intent`. Indexed for return-URL lookups. |
| `status` | `string` | no | `"pending"` | Enum: `pending \| escrowed \| rejected`. |
| `escrowed_at` | `datetime` | yes | — | Set on `pending → escrowed`. |
| `rejected_at` | `datetime` | yes | — | Set on `pending → rejected`. |
| `discarded_at` | `datetime` | yes | — | `discard` gem. |
| `created_at` | `datetime` | no | — | — |
| `updated_at` | `datetime` | no | — | — |

**Indexes**:

- `payments(shipment_id, status)` — composite. Powers `shipment.payments.escrowed.exists?` and policy predicates.
- `payments(provider_reference)` — for return-URL lookups.
- `payments(discarded_at)` — soft-delete query.

### FSM

```
pending --gateway:approved-> escrowed   (terminal — unlocks contact + pickup)
pending --gateway:rejected-> rejected   (terminal — Shipper retries by creating a new Payment)
pending --shipper:abandon!> rejected    (manual recovery from stuck pending)
```

Modeled by hand in the model (same pattern as `Shipment` — no `aasm` gem). Each transition lives in a `Payment#transition_to!(new_status, at: Time.current)` method. Validation `timestamps_match_status` mirrors `Shipment`'s pattern.

## API contract

### `POST /api/shipments/:id/payments`

- **Authz**: `PaymentPolicy#create?`
  - `current_shipper.present?` and `current_shipper.id == shipment.cargo_offer.cargo.shipper_id`.
  - `shipment.status_accepted?`.
  - **No** `Payment` `escrowed` exists for this `Shipment`.
  - At most one `Payment` `pending` for this `Shipment` (if one exists, the Shipper must `abandon` it first).
- **Body**: empty (the amount comes from the Shipment's accepted offer).
- **Side effect**: creates `Payment` in `pending`, copies `amount_cents` from `CargoOffer.amount_cents`, calls `gateway.create_intent(shipment:, return_to: ...)`, persists the returned `provider_reference`.
- **Response**: `{ payment_id: <id>, redirect_url: <url> }`.
- **Errors**: `403` (not Shipper / not owner), `409` (already paid, or `pending` Payment exists, or Shipment not `accepted`), all via `I18n.t('errors.payments.*')`.

### `GET /api/payments/:id/return?outcome=approved|rejected|pending`

- Called by the gateway's redirect. With `Payments::FakeGateway` this is reached via the fake gateway UI clicking a button → redirect.
- **Idempotent**: wraps the state transition in `shipment.with_lock { ... }`. If `payment.status != pending` on entry, no-op.
- **`?outcome=approved`**: `payment.transition_to!(:escrowed, at: Time.current)`. No Shipment FSM change (Shipment stays `accepted`; the predicate `shipment.payments.escrowed.exists?` now returns true, which the UI surfaces as "a recoger" and which `CarrierResource` consults to reveal contacts).
- **`?outcome=rejected`**: `payment.transition_to!(:rejected, at: Time.current)`.
- **`?outcome=pending`**: no transition; renders a "todavía procesando" page. The Shipper can either reload (no-op) or click "Cancelar y reintentar" → `POST /api/payments/:id/abandon`.
- **Response**: redirects (or renders, depending on FE wiring) to `/payments/:id` with state-appropriate content.

### `POST /api/payments/:id/abandon`

- **Authz**: only the Shipper who created the Payment, and only if `payment.status_pending?`.
- **Side effect**: `payment.transition_to!(:rejected, at: Time.current)`.
- **Response**: `204 No Content`.

## Gateway abstraction

```ruby
# app/services/payments/gateway.rb
module Payments
  module Gateway
    # @return [Struct(redirect_url:, provider_reference:)]
    def self.create_intent(shipment:, return_to:); end

    # @return [Payment]
    def self.confirm!(provider_reference:, outcome:); end
  end
end

# app/services/payments/fake_gateway.rb
module Payments
  class FakeGateway
    extend Gateway
    # Deterministic. create_intent returns a redirect URL pointing
    # at /dev/fake-payment/:provider_reference. confirm! mutates Payment.
  end
end
```

The fake gateway is wired as the production `Payments.gateway` via a single line in `config/initializers/payments.rb`. The future real adapter (`Payments::MercadoPagoGateway`) replaces that line.

## Frontend scope

- **`/shipments/:id/pay`** (Shipper-only, gated with `RequireShipper`): muestra monto formateado, summary del Carrier sin contactos, CTA "Pagar". Al click → `POST` al endpoint y `window.location.assign(redirect_url)`. Si ya existe un `Payment` `pending`, muestra "Tienes un pago en curso" + CTA "Cancelar e iniciar otro" (→ `abandon`).
- **`/dev/fake-payment/:provider_reference`**: pantalla del gateway falso. Tres botones — `Aprobar` / `Rechazar` / `Pendiente`. **Siempre montada, incluso en producción** (es la pasarela). Sin auth especial — está autorizada por la posesión del `provider_reference`.
- **`/payments/:id`**: página de confirmación. Render condicional según `status`:
  - `escrowed` → mensaje de éxito + datos de contacto del Carrier (AC3).
  - `rejected` → mensaje de error + CTA "Reintentar pago" → vuelve a `/shipments/:id/pay`.
  - `pending` → "Procesando" + CTA "Cancelar y reintentar".
- **Shipment detail (Shipper view)**: CTA "Pagar" aparece solo si `shipment.status_accepted? && !shipment.payments.escrowed.exists?`. El label de estado cambia de "Pendiente de pago" a "A recoger" cuando hay un `Payment` `escrowed`.
- **Tests**: Vitest para componentes, MSW para los endpoints nuevos, **Playwright e2e** para el golden path: Carrier acepta → Shipper paga (aprobado) → Shipper ve "A recoger" + contactos del Carrier.

## i18n

Claves nuevas bajo `payments.*` en `backend/config/locales/{en,es}.yml` y en el bundle de copy del frontend (`frontend/src/pages/shipper/paymentContent.ts` o equivalente, hasta que aterrice una librería i18n real). **Sin literales hardcoded en JSX ni en controllers.**

## Out of scope (deliberadamente diferido)

- Integración real con MercadoPago (`REQ-BE-00006`).
- Settlement / release de escrow (no hay `PaymentSettlementJob`; `escrowed` es terminal en el MVP).
- Refunds, disputes (post-MVP).
- Timeout automático para `pending` rows (Shipper-initiated `abandon!` cubre la recuperación).
- Notificaciones email de cambios de estado del `Payment` (opcional; depende de `INF-BE-00005`).

## Related

- **Construye sobre**: `REQ-BE-00024` (US12 — Carrier accepts CargoOffer → crea `Shipment` en `accepted`) y `REQ-FE-00017` (inbox de ofertas), ambos en PR #194 al momento del triage.
- **ADR-012** — la decisión canónica del modelo de pago (`docs/01-technical-vision/technical-vision.md`).
- **Issue #215** — adopción del `discard` gem para soft-deletes. Este issue lo usa desde día 1 para `Payment`.
- **No depende de** `REQ-BE-00006` (integración MP real, post-MVP).

## Implementation notes (pre-PR)

- **Branch name**: `feature/REQ-BE-00033-us8-realizar-pago-expedidor`.
- **PR title** (UTMOST): conventional type al inicio, sin `[TAG]` prefix. Ejemplo: `feat(payments): US8 — Shipper payment flow with fake gateway`. TAG va en body (`Closes #213`) y branch.
- **`gh pr create --assignee @me`**.
- **Pre-PR UI gate**: `/critique` → `/polish` → `/audit` sobre `/shipments/:id/pay`, `/dev/fake-payment/:id`, `/payments/:id`. `just lint`, `just frontend-test-coverage` (80%), `just frontend-test-e2e`, `just backend-test` verdes.
- **Migration**: `db/migrate/<ts>_create_payments.rb` con índices del schema-block de arriba.
- **Docs ya actualizados en este triage**: `domain-model.md` § 1 / § 4.1 / § 5.1, `api-overview.md`, `external-systems.md`, `scheduled-jobs.md`, `glossary.md`, `technical-vision.md` (ADR-012).
