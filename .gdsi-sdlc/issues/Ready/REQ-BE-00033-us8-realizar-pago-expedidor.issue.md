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
last_synced: 2026-05-24T23:59:44.859623+00:00Z
labels:
- BE
- FE
- REQ
- payments
- mvp
- us8
- checkout
plan: docs/features/REQ/REQ-BE-00033/REQ-BE-00033-us8-realizar-pago-expedidor.plan.md
---

## Summary

El Expedidor (Shipper) paga el `Shipment` que el Transportista aceptó (US12), desbloqueando los datos de contacto del Carrier y habilitando el pickup. El pago se modela como un `Payment` ligado al `Shipment` con FSM **mínima e irreducible**: cada fila se crea ya en uno de dos estados terminales — `escrowed` (éxito) o `failed` (fracaso). `Payments::FakeGateway` es **síncrona** y siempre montada (incluyendo producción). Cuando aterrice un gateway real (post-MVP), `pending` se agrega en ese momento; el MVP no lo necesita.

El plan completo (rationale, schema, endpoint, ACs detallados, cancellation interlock con `Shipment`) vive en `docs/features/REQ/REQ-BE-00033/REQ-BE-00033-us8-realizar-pago-expedidor.plan.md` — re-escrito 2026-05-24 para alinear con el resultado de la sesión de grilling del Sprint 3.

## Decisiones canónicas (ver ADR-012 + plan)

| Tema | Decisión |
|---|---|
| FSM `Payment` | Cada fila nace en `escrowed` (éxito) o `failed` (fracaso). Ambos son terminales. **No hay `pending`** ni transiciones internas. |
| Justificación | Mínimo de estados, sin estados derivables de relaciones. `pending` aplica sólo con gateway asincrónico; el MVP usa `Payments::FakeGateway` síncrona. |
| FK | `Payment belongs_to :shipment` (1:N — per-attempt rows). |
| Creación | En el click "Pagar" del Shipper — POST devuelve la fila ya en estado terminal. Sin redirect externo. |
| Retry | Una fila `failed` no transiciona — el Shipper crea una fila nueva con otro POST. Audit trail = lista de Payments del Shipment. |
| Invariante | A lo sumo **un** `Payment.escrowed` por Shipment (guard de servicio bajo `shipment.with_lock`). |
| Soft-delete | Vía `discard` gem (alineado con #215). `discarded_at` en `payments`. |
| `amount_cents` | Congelado en `create` desde `CargoOffer.amount_cents`. Inmutable. |
| `provider` enum | `fake \| mercadopago \| stripe \| other`. MVP escribe `fake`. |
| Estados `refunded` / `disputed` / `released` / `settled` | **Fuera del MVP.** No se modelan. |
| Fake gateway | **Siempre activo, incluso en producción**. Síncrona y determinística. Override de outcome vía `/dev/fake-payment/new` (tool dev/demo, no parte del flujo de producción). |
| Endpoint único | `POST /api/shipments/:id/payments`. **Síncrono.** Persiste una fila born-terminal dentro de `shipment.with_lock`. |
| Endpoints retirados | `GET /api/payments/:id/return` y `POST /api/payments/:id/abandon` — no existen. Sin gateway async y sin `pending`, no hay callback ni nada que abandonar. |
| Shipment FSM | **Sin cambios** — final canónica `accepted → in_transit → delivered (+ cancelled)`. "A recoger" / "Pendiente de pago" son composiciones de UI (chip de Shipment + chip de Payment), no estados. |
| Cancellation interlock | `Shipments::Cancel` rechaza la transición a `cancelled` si existe un `Payment.escrowed` para ese envío (HTTP 409). Implementado como parte de este issue (AC14). |
| Contact-info reveal | `CarrierResource` con shape condicional via `CarrierPolicy#can_view_contact?(current_shipper)`, evaluado contra `shipment.payments.escrowed.exists?`. |

## User story (fuente)

`docs/artifacts/backlog-us.typ` — US8:

> Como expedidor, quiero poder pagar de forma segura una vez que el transportista aceptó mi envío, para reservar el servicio y cumplir con mi parte del trato.

## Acceptance criteria

ACs de producto:

- [ ] **AC1**: Una vez aceptado el envío por el transportista (`accepted`), se habilita la opción de realizar el pago para el Expedidor dueño del Cargo.
- [ ] **AC2**: Al completarse el pago con éxito, el envío se muestra al Expedidor con la etiqueta UI compuesta «A recoger» (derivada de `Shipment.state == "accepted"` + `shipment.payments.escrowed.exists?`). Implementación: el `Shipment.state` no cambia; la etiqueta «A recoger» se compone en UI y es visible tanto para el Shipper como para el Carrier (anclada en `docs/05-appendices/glossary.md:25`).
- [ ] **AC3**: Una vez completado el pago (`Payment.escrowed`), se desbloquean los datos de contacto del transportista (`full_name`, `email`, `phone`) al Shipper.
- [ ] **AC4**: Si el pago falla (`Payment.failed`), se muestra un mensaje de error y se permite reintentar. El reintento crea una **fila nueva**; la fila `failed` queda en historial.
- [ ] **AC5**: El monto del pago corresponde al precio acordado en la oferta aceptada (`Payment.amount_cents = CargoOffer.amount_cents`, congelado en `create`).

ACs de implementación:

- [ ] **AC6**: La pasarela es `Payments::FakeGateway`, **determinística y síncrona**, montada en todos los entornos incluyendo producción. Permite forzar `approved` / `rejected` vía `/dev/fake-payment/new` (tool dev/demo). No hay outcome `pendiente`.
- [ ] **AC7**: Solo el Expedidor dueño del `Cargo` puede iniciar el pago (Pundit `PaymentPolicy#create?`). Otros roles reciben `403`.
- [ ] **AC8**: Reintentar el pago tras un fallo es posible mientras no exista un `Payment.escrowed` para ese `Shipment`. Cada reintento es un POST nuevo. Si ya hay un `escrowed`, el POST devuelve `409 Conflict`.
- [ ] **AC9**: Los datos de contacto del Transportista no son visibles para el Expedidor hasta que exista un `Payment.escrowed` para ese `Shipment`. `CarrierResource` omite `email` / `phone` / `full_name` cuando `CarrierPolicy#can_view_contact?(current_shipper)` es falso.
- [ ] **AC10**: Todas las cadenas visibles al usuario (UI + error messages) pasan por claves de i18n. Cero literales hardcoded en JSX ni en controllers.
- [ ] **AC11**: `POST /api/shipments/:id/payments` es race-safe — request specs con dos llamadas concurrentes confirman que a lo sumo una crea un `Payment.escrowed`. Implementación: `shipment.with_lock { return if shipment.payments.escrowed.exists?; gateway call; create row in terminal state }`.
- [ ] **AC12**: `Payment.amount_cents` queda congelado al valor de `CargoOffer.amount_cents` en el momento de creación. Cambios posteriores no afectan al `Payment` ya creado.
- [ ] **AC13**: `Payment` soporta soft-delete vía `discard` gem (alineado con #215). `discarded_at` indexado para consultas de audit. `default_scope` filtra discarded.
- [ ] **AC14** (nuevo — cancellation interlock): `Shipments::Cancel` rechaza la transición `accepted → cancelled` si existe un `Payment.escrowed` para el envío. Devuelve `409 Conflict` con mensaje i18n `errors.shipments.cancel.already_paid`. Cubre el acoplamiento entre las FSM de `Shipment` y `Payment`; aterriza en este issue porque el dueño de la FSM de Payment es Brian.

## Domain model

### Schema (`payments` table)

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | `bigint` | no | — | PK. |
| `shipment_id` | `bigint` | no | — | FK → `shipments.id`. **No `unique` index** — 1:N (per-attempt). |
| `amount_cents` | `integer` | no | — | Frozen from `CargoOffer.amount_cents` at create. Immutable post-create (model-level guard). |
| `currency` | `string` | no | `"ARS"` | Default ARS, unused for the time being. |
| `provider` | `string` | no | `"fake"` | Enum: `fake \| mercadopago \| stripe \| other`. MVP writes `"fake"`. |
| `provider_reference` | `string` | yes | — | Returned by `gateway.process_payment!`. Indexed for audit lookups. |
| `state` | `string` | no | — | Enum: `escrowed \| failed`. **No default** — siempre se setea en `create` desde el outcome síncrono del gateway. NOT NULL. |
| `escrowed_at` | `datetime` | yes | — | Set on row create cuando `state = escrowed`. |
| `failed_at` | `datetime` | yes | — | Set on row create cuando `state = failed`. |
| `failure_reason` | `string` | yes | — | Seteado por el gateway cuando `state = failed`. Para diagnóstico / UI. |
| `discarded_at` | `datetime` | yes | — | `discard` gem. |
| `created_at` | `datetime` | no | — | — |
| `updated_at` | `datetime` | no | — | — |

**Indexes**:

- `payments(shipment_id, state)` — composite. Powers `shipment.payments.escrowed.exists?` and policy predicates.
- `payments(provider_reference)` — for audit lookups.
- `payments(discarded_at)` — soft-delete query.

**Nota `state` vs `status`**: la columna se llama `state` para alinearse con `Shipment.state`. No usar `status`.

### FSM

```
(create) ──gateway:approved──▶ escrowed   (terminal, éxito — unlocks contact + pickup)
(create) ──gateway:rejected──▶ failed     (terminal, fracaso — Shipper retries by creating a new Payment)
```

**Born-terminal — sin transiciones internas.** Cada fila nace en su estado final (`escrowed` o `failed`). No existe `pending`, no existen `released` / `refunded` / `disputed`. Una fila `failed` **no transiciona**: el reintento es un nuevo POST que persiste otra fila.

**Invariante:** `payments.where(shipment_id: X, state: 'escrowed').count <= 1`. Garantizado en el servicio `Payments::Create` envuelto en `shipment.with_lock` (SQLite — race-safety en la capa de aplicación).

Modelado a mano en el model — no hay `aasm` gem. El método `Payment.create_in_terminal_state!(shipment:, gateway_outcome:)` setea `state`, `escrowed_at`/`failed_at`, `provider`, `provider_reference` y `failure_reason` en un único pasaje atómico.

## API contract

### `POST /api/shipments/:id/payments`

**Único endpoint** del flujo de pago. Síncrono — persiste una fila born-terminal dentro de `shipment.with_lock`.

- **Authz**: `PaymentPolicy#create?`
  - `current_shipper.present?` y `current_shipper.id == shipment.cargo_offer.cargo.shipper_id`.
  - `shipment.state == 'accepted'`.
  - **No** existe `Payment` `escrowed` para este `Shipment` (guard).
- **Body**: vacío (el monto viene del `CargoOffer.amount_cents` del Shipment).
- **Side effect**: dentro de `shipment.with_lock`:
  1. Re-verifica el guard (`no Payment escrowed`).
  2. Llama a `Payments.gateway.process_payment!(shipment:)` (síncrono — devuelve `{ outcome: :approved | :rejected, provider_reference:, failure_reason: }`).
  3. Crea la fila `Payment` directamente en `escrowed` (si `approved`) o `failed` (si `rejected`), con `amount_cents` congelado y `escrowed_at` / `failed_at` / `failure_reason` seteados en el mismo `create`.
- **Response**:
  - `201 Created` — body: `{ payment_id:, state: "escrowed" | "failed", failure_reason?: string }`.
  - `403 Forbidden` — el shipper no es dueño del cargo asociado.
  - `409 Conflict` — ya existe un `Payment.escrowed`, o el Shipment no está en `accepted`.
- **Errors message**: vía `I18n.t('errors.payments.*')`. Cero literales.

### Endpoints retirados respecto al plan anterior

- ~~`GET /api/payments/:id/return?outcome=...`~~ — no aplica: sin gateway async no hay redirect/callback.
- ~~`POST /api/payments/:id/abandon`~~ — no existe el estado `pending`, no hay nada que abandonar.
- ~~Webhook endpoint~~ — no existe. La fake gateway es síncrona y no envía callbacks.

## Gateway abstraction

```ruby
# app/services/payments/gateway.rb
module Payments
  module Gateway
    # @return [Struct(outcome: Symbol, provider_reference: String, failure_reason: String?)]
    # outcome is one of :approved or :rejected — synchronous, no :pending.
    def self.process_payment!(shipment:); end
  end
end

# app/services/payments/fake_gateway.rb
module Payments
  class FakeGateway
    extend Gateway

    # Deterministic, synchronous. Default behavior approves; override via
    # /dev/fake-payment/new (Thread-local or server-side keyed by shipment).
    def self.process_payment!(shipment:)
      outcome = forced_outcome_for(shipment) || :approved
      OpenStruct.new(
        outcome: outcome,
        provider_reference: "fake-#{SecureRandom.uuid}",
        failure_reason: (outcome == :rejected ? "fake_rejection" : nil)
      )
    end
  end
end
```

Cableado en `config/initializers/payments.rb` con `Payments.gateway = Payments::FakeGateway`. El adaptador futuro (`Payments::MercadoPagoGateway`) reemplaza esa línea — ese cambio post-MVP es el que (eventualmente) introduce `pending` + endpoint de callback. Hoy no.

## Frontend scope

- **`/shipper/shipments/:id/pay`** (Shipper-only, gated con `RequireShipper`): muestra monto formateado, summary del Carrier *sin* contactos, y un único CTA "Pagar". Al click:
  1. `POST /api/shipments/:id/payments` (síncrono).
  2. Si la respuesta es `state: escrowed` → redirige a `/shipper/shipments/:id` (US39 detail); ahora aparecen los datos de contacto y el chip de pago es "Pagado".
  3. Si la respuesta es `state: failed` → muestra el mensaje de error (vía `failure_reason` mapeado a clave i18n) + CTA "Reintentar pago" (otro POST → otra fila nueva).
  4. Si la respuesta es `409 Conflict` (ya pagado) → mensaje "Este envío ya está pagado" + redirige al detalle.
- **`/dev/fake-payment/new`** (dev/demo only): formulario para forzar el outcome del próximo POST de la fake gateway (`approved` / `rejected` / `random`). Override persistido vía cookie o server-side keyed por shipment. **No es parte del flujo de producción** — es herramienta de QA/demo. (Sin auth especial.)
- **No existe**: `/payments/:id`, `/shipments/:id/pay` sin prefijo de rol, ni pantalla de "Procesando". El flujo es síncrono — no hay estado intermedio que renderizar.
- **Shipment detail (US39, Shipper view)**: en `accepted` + sin `Payment.escrowed`, CTAs "Pagar" → `/shipper/shipments/:id/pay` y "Cancelar envío" → `DELETE /api/shipments/:id` (con el interlock de AC14). En `accepted` + pagado, solo el chip "Pagado" — no se ofrece cancelación.
- **Tests**: Vitest para componentes, MSW para `POST /api/shipments/:id/payments`, **Playwright e2e** para el golden path: Carrier acepta → Shipper paga (approved) → Shipper ve "Pagado" + contactos del Carrier.

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
- **Migration**: `db/migrate/<ts>_create_payments.rb` con índices del schema-block de arriba. Columna `state` NOT NULL, **sin default** — siempre seteada en `create` por el servicio.
- **Docs ya actualizados en este triage**: `domain-model.md` § 1 / § 4.1 / § 5.1, `api-overview.md`, `external-systems.md`, `scheduled-jobs.md`, `glossary.md`, `technical-vision.md` (ADR-012).
