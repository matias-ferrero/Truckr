# REQ-BE-00033: US8 — Realizar pago del expedidor sobre Shipment aceptado (gateway mock)

## Summary

El Expedidor (Shipper) paga el `Shipment` que el Transportista aceptó (US12), desbloqueando los datos de contacto del Carrier y habilitando el pickup. El pago se modela como un `Payment` ligado al `Shipment` con una FSM **mínima e irreducible**: cada fila se crea ya en uno de dos estados terminales — `escrowed` (éxito) o `failed` (fracaso). La pasarela del MVP (`Payments::FakeGateway`) es **síncrona** y siempre montada (incluyendo producción). El diseño deja la puerta abierta para un gateway real (asincrónico, con `pending`) como cambio post-MVP — pero ese estado no existe hoy.

## Decisiones canónicas (alineadas con la sesión de grilling de Sprint 3 y con ADR-012)

| Tema | Decisión |
|---|---|
| FSM `Payment` | `escrowed` (terminal, éxito) o `failed` (terminal, fracaso). **No hay `pending`** — la fila se crea ya en su estado final. **No hay transiciones.** |
| Justificación | Mínimo de estados, sin estados derivables de relaciones. `pending` solo tiene sentido con un gateway asincrónico; el `FakeGateway` es síncrono. Cuando aterrice un gateway real (post-MVP), se agrega `pending` en ese momento. |
| FK | `Payment belongs_to :shipment` (1:N — per-attempt rows). |
| Creación | En el click "Pagar" del Shipper. El POST devuelve la fila ya en su estado terminal — no hay redirect a un gateway externo. |
| Multiplicidad | `Shipment has_many :payments`. AC de retry crea filas nuevas. |
| Retry | Una fila `failed` no transiciona — el Shipper crea una fila nueva con otro POST. La lista de Payments por Shipment es el audit trail de intentos. |
| Invariante | A lo sumo **un** `Payment` en `escrowed` por Shipment (índice único parcial-simulado vía guard de servicio, ver below — SQLite no soporta partial indexes nativamente). |
| Soft-delete | **Hard-delete only.** Audit trail = per-attempt rows (los `Payment` fallidos persisten en estado terminal). El interlock de cancelación garantiza que ninguna fila `escrowed` se destruya en pleno flujo. |
| `amount_cents` | Congelado en `create` desde `CargoOffer.amount_cents`. Inmutable. |
| `provider` enum | `fake \| mercadopago \| stripe \| other`. MVP escribe `fake`. |
| `provider_reference` | String — id que devuelve el gateway (fake o real). |
| Estados `refunded` / `disputed` / `released` / `settled` | **Fuera del MVP.** No se modelan. `settled` se descartó del modelo Shipment porque era derivable de `Payment.state == escrowed` (ver glossary). |
| Settlement / release job | **Fuera del MVP.** `escrowed` es terminal. |
| Endpoint create | `POST /api/shipments/:id/payments`. **Síncrono** — la respuesta incluye el `Payment` ya en su estado terminal. |
| Endpoint return / callback | **No existe.** Sin redirect, sin webhook. |
| Endpoint abandon | **No existe.** Sin `pending`, no hay nada que abandonar. |
| Shipment FSM | **Sin cambios respecto al estado canónico final**: `accepted → in_transit → delivered (+ cancelled)`. "A recoger" / "Pendiente de pago" son composiciones de UI (Shipment chip + Payment chip), no estados. |
| Cancellation interlock | El servicio `Shipments::Cancel` debe validar que **no exista un `Payment.escrowed`** para el Shipment antes de transicionar a `cancelled`. Refund/dispute están fuera de MVP. |
| Contact-info reveal | `CarrierResource` con shape condicional via `CarrierPolicy#can_view_contact?(current_shipper)`, evaluado contra `shipment.payments.escrowed.exists?`. |
| Contact-info fields | `users.full_name / email / phone` accedido via `Carrier.user`. No se agregan columnas. |

## User story (fuente canónica, post-rewrite)

`docs/artifacts/backlog-us.typ` — US8 — texto canónico vigente:

> Como expedidor, quiero poder pagar de forma segura una vez que el transportista aceptó mi envío, para reservar el servicio y cumplir con mi parte del trato.

(El término canónico es **`Envío`**; "Viaje" fue retirado del artefacto en el rename de Sprint 3.)

## Acceptance criteria

ACs de producto:

- [ ] **AC1**: Una vez aceptado el envío por el transportista (estado `accepted`), se habilita la opción de realizar el pago para el Expedidor dueño del `Cargo`.
- [ ] **AC2**: Al completarse el pago con éxito, el chip de pago del envío en el listado y detalle (US17 / US39) pasa de "Pendiente de pago" a "Pagado". *Implementación:* el `Shipment.state` no cambia (sigue en `accepted`); el chip "Pagado" se deriva de `shipment.payments.escrowed.exists?`.
- [ ] **AC3**: Una vez completado el pago (`Payment.escrowed`), se desbloquean los datos de contacto del transportista (`full_name`, `email`, `phone`) al Expedidor.
- [ ] **AC4**: Si el pago falla (`Payment.failed`), se muestra un mensaje de error y se permite reintentar. El reintento crea una **fila nueva** de `Payment`; la fila `failed` queda en el historial y no transiciona.
- [ ] **AC5**: El monto del pago corresponde al precio acordado en la oferta aceptada (`Payment.amount_cents = CargoOffer.amount_cents`, congelado en `create`).

ACs de implementación:

- [ ] **AC6**: La pasarela es `Payments::FakeGateway`, **determinística y síncrona**, montada en **todos los entornos incluyendo producción**. Permite forzar `aprobado` o `rechazado` desde una UI de prueba en `/dev/fake-payment/new` (ver § Frontend). No hay outcome `pendiente` — la fake gateway no simula latencia async.
- [ ] **AC7**: Solo el Expedidor dueño del `Cargo` puede iniciar el pago (Pundit `PaymentPolicy#create?`). Otros roles reciben `403`.
- [ ] **AC8**: Reintentar el pago tras un fallo es posible mientras no exista un `Payment` en `escrowed` para ese `Shipment`. Cada reintento es un POST que crea una fila nueva. Si el Shipper intenta pagar habiendo ya un `escrowed`, recibe `409 Conflict`.
- [ ] **AC9**: Los datos de contacto del Transportista no son visibles para el Expedidor hasta que exista un `Payment.escrowed` para ese `Shipment`. `CarrierResource` omite `email` / `phone` / `full_name` cuando `CarrierPolicy#can_view_contact?(current_shipper)` es falso.
- [ ] **AC10**: Todas las cadenas visibles al usuario (UI + error messages) pasan por claves de i18n. Cero literales hardcoded en JSX ni en controllers.
- [ ] **AC11**: `POST /api/shipments/:id/payments` es race-safe — request specs con dos llamadas concurrentes confirman que a lo sumo una crea un `Payment` en `escrowed`. Implementación: `shipment.with_lock { return if shipment.payments.escrowed.exists?; ... gateway call ... ; create row in terminal state }`.
- [ ] **AC12**: `Payment.amount_cents` queda congelado al valor de `CargoOffer.amount_cents` en el momento de creación. Cambios posteriores al precio del `CargoOffer` no afectan al `Payment` ya creado.
- [ ] **AC13**: `Payment` es **hard-delete only**. El audit trail vive en las filas per-attempt (los `failed` persisten en estado terminal); el interlock de cancelación impide que se destruya un `escrowed` en mitad del flujo.
- [ ] **AC14**: La cancelación de un `Shipment` (desde US39 — botón Expedidor "Cancelar envío") sólo es admitida si **no existe** un `Payment.escrowed` para ese Shipment. El servicio `Shipments::Cancel` devuelve `409 Conflict` con mensaje i18n `errors.shipments.cancel.already_paid` cuando el interlock falla. (Esta AC encierra el interlock entre las FSM de `Shipment` y `Payment`; aterrizarla en este issue es consistente con que el dueño de la FSM de Payment es Brian.)

## Domain model

### Schema (`payments` table)

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | `bigint` | no | — | PK. |
| `shipment_id` | `bigint` | no | — | FK → `shipments.id`. Sin índice único — 1:N (per-attempt). |
| `amount_cents` | `integer` | no | — | Frozen from `CargoOffer.amount_cents` at create. Immutable post-create (model-level guard). |
| `currency` | `string` | no | `"ARS"` | Default ARS. |
| `provider` | `string` | no | `"fake"` | Enum: `fake \| mercadopago \| stripe \| other`. MVP escribe `"fake"`. |
| `provider_reference` | `string` | yes | — | Returned by `gateway.process_payment!`. Indexed para audit. |
| `state` | `string` | no | — | Enum: `escrowed \| failed`. **No default** — el state se setea en `create` desde el outcome del gateway sync. |
| `escrowed_at` | `datetime` | yes | — | Set on row create si `state = escrowed`. |
| `failed_at` | `datetime` | yes | — | Set on row create si `state = failed`. |
| `failure_reason` | `string` | yes | — | Set por el gateway cuando `state = failed`. Para diagnóstico / UI. |
| `created_at` | `datetime` | no | — | — |
| `updated_at` | `datetime` | no | — | — |

**Indexes**:

- `payments(shipment_id, state)` — composite. Powers `shipment.payments.escrowed.exists?` y policy predicates.
- `payments(provider_reference)` — for audit lookups.

**Nota de columna `state` vs `status`**: usamos `state` para alinearnos con el resto del dominio (`Shipment.state`). La columna `status` fue descartada por consistencia.

### FSM

```
(create) ──gateway:approved──▶ escrowed   (terminal, éxito)
(create) ──gateway:rejected──▶ failed     (terminal, fracaso)
```

**Sin transiciones internas.** Cada fila nace en su estado final.

**Invariante:** `payments.where(shipment_id: X, state: 'escrowed').count <= 1`. SQLite no soporta partial indexes con expresiones complejas, así que la unicidad se garantiza en el servicio (`Payments::Create` envuelto en `shipment.with_lock`).

Modelado a mano en el model — no hay `aasm` gem. El método `Payment.create_in_terminal_state!(shipment:, gateway_outcome:)` setea `state`, `escrowed_at`/`failed_at`, `provider`, `provider_reference` y `failure_reason` en un solo pasaje atómico.

## API contract

### `POST /api/shipments/:id/payments`

**Único endpoint** del flujo de pago. Síncrono, idempotente bajo `with_lock`.

- **Authz**: `PaymentPolicy#create?`
  - `current_shipper.present?` and `current_shipper.id == shipment.cargo_offer.cargo.shipper_id`.
  - `shipment.state == 'accepted'`.
  - **No** `Payment` en `escrowed` existe para este `Shipment` (el guard).
- **Body**: vacío (el monto viene del `CargoOffer.amount_cents` del Shipment).
- **Side effect**: dentro de `shipment.with_lock`:
  1. Re-verifica el guard (`no Payment escrowed`).
  2. Llama a `Payments.gateway.process_payment!(shipment:)` (síncrono — devuelve `{ outcome: :approved | :rejected, provider_reference:, failure_reason: }`).
  3. Crea la fila `Payment` directamente en `escrowed` (si approved) o `failed` (si rejected), con todos los timestamps + `amount_cents` congelados.
- **Response**:
  - `201 Created` — body: `{ payment_id:, state: "escrowed" | "failed", failure_reason?: string }`.
  - `403 Forbidden` — el shipper no es dueño del cargo asociado.
  - `409 Conflict` — ya existe un `Payment.escrowed`, o el Shipment no está en `accepted`.
- **Errors message**: vía `I18n.t('errors.payments.*')`. Cero literales.

### Endpoints retirados respecto al plan anterior

- ~~`GET /api/payments/:id/return?outcome=...`~~ — no aplica con gateway síncrono.
- ~~`POST /api/payments/:id/abandon`~~ — no existe el estado `pending`, no hay nada que abandonar.

## Gateway abstraction

```ruby
# app/services/payments/gateway.rb
module Payments
  module Gateway
    # @return [Struct(outcome: Symbol, provider_reference: String, failure_reason: String?)]
    # outcome is one of :approved or :rejected
    def self.process_payment!(shipment:); end
  end
end

# app/services/payments/fake_gateway.rb
module Payments
  class FakeGateway
    extend Gateway

    # Deterministic, synchronous.
    # Default behavior: approves. Override via Thread-local or test-only header
    # to force a rejection — used by the /dev/fake-payment/new screen and by RSpec.
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

Cableado en `config/initializers/payments.rb`:

```ruby
Payments.gateway = Payments::FakeGateway
```

El adaptador futuro (`Payments::MercadoPagoGateway`) reemplaza esa línea. Ese adaptador real **sí** requerirá agregar el estado `pending` y un endpoint de callback (modificación de schema + FSM) — pero eso es trabajo post-MVP.

## Frontend scope

- **`/shipper/shipments/:id/pay`** (Shipper-only, gated con `RequireShipper`): pantalla que muestra monto formateado, summary del Carrier *sin* contactos, y un único CTA "Pagar". Al click:
  1. `POST /api/shipments/:id/payments` (síncrono).
  2. Si la respuesta es `state: escrowed` → redirige a `/shipper/shipments/:id` (US39 detail), donde ahora aparecen los datos de contacto y el chip de pago es "Pagado".
  3. Si la respuesta es `state: failed` → muestra el mensaje de error (vía `failure_reason` mapeado a clave i18n) + CTA "Reintentar pago" (que dispara otro POST → otra fila).
  4. Si la respuesta es `409 Conflict` (ya pagado) → mensaje "Este envío ya está pagado" + redirige al detalle.
- **`/dev/fake-payment/new`** (dev/demo only): formulario para forzar el outcome del próximo POST de la fake gateway (approved / rejected / random). Persiste el override en una cookie o en el server-side por `provider_reference`. **No es parte del flujo de producción** — es una herramienta de demo y QA. (Cambio respecto al plan anterior: antes era una pantalla a la que el usuario era redirigido durante el flujo; ahora es una tool independiente, porque el flujo es síncrono.)
- **No existe**: `/payments/:id`, `/shipments/:id/pay` (sin prefijo de rol). Los flujos son siempre `/shipper/shipments/...`.
- **Shipment detail (US39, Shipper view)**: en estado `accepted` + sin `Payment.escrowed`, se ofrecen dos CTAs: "Pagar" → navega a `/shipper/shipments/:id/pay`, y "Cancelar envío" → dispara `DELETE /api/shipments/:id` (que ejecuta el servicio `Shipments::Cancel` con el interlock de AC14). En `accepted` + pagado, solo el chip de "Pagado" aparece — no se ofrece cancelación.
- **Tests**: Vitest para componentes; MSW para `POST /api/shipments/:id/payments`; **Playwright e2e** para el golden path: Carrier acepta → Shipper paga (approved) → Shipper ve "Pagado" + contactos del Carrier → Carrier marca retirada.

## i18n

Claves nuevas bajo `payments.*` y `errors.payments.*` en `backend/config/locales/{en,es}.yml` y en el bundle de copy del frontend. Claves nuevas para los chips de estado de envío + de pago bajo `shipment.state.*` y `payment.state.*`. **Sin literales hardcoded en JSX ni en controllers.**

## Out of scope (deliberadamente diferido)

- Integración real con MercadoPago (`REQ-BE-00006`). Cuando llegue, se agregan: `pending` state, endpoint de callback, webhook signing, timeout job. Schema migration y FSM addition.
- Settlement / release de escrow (`escrowed` es terminal en MVP).
- Refunds, disputes, mid-transit cancellation (post-MVP — la cancelación con dinero en escrow se trata como dispute, no como cancellation).
- Notificaciones email de cambios de estado del `Payment` (opcional; depende de `INF-FE-00005` / `INF-BE-00005`).

## Related

- **Construye sobre**: `REQ-BE-00024` (US12 — Carrier accepts CargoOffer → crea `Shipment` en `accepted`) y `REQ-FE-00017` (inbox de ofertas), ambos mergeados en PR #221.
- **Acopla con**: las issues nuevas de Sprint 3 para US17 + US39 (listado + detalle de envíos). El chip de pago y el botón "Cancelar envío" del detalle dependen de este issue.
- **ADR-012** — la decisión canónica del modelo de pago (`docs/01-technical-vision/technical-vision.md`). Pendiente: actualizar el ADR para reflejar el cambio sync mock + drop de `pending` (cleanup en este sprint o el siguiente, según prioridades).
- **Issue #215** — adopción del `discard` gem para soft-deletes. **No aplica a `Payment`**: la tabla es hard-delete only y el audit trail vive en las filas per-attempt.
- **No depende de** `REQ-BE-00006` (integración MP real, post-MVP).

## Implementation notes (pre-PR)

- **Branch name**: `feature/REQ-BE-00033-us8-realizar-pago-expedidor`.
- **PR title** (UTMOST): conventional type al inicio, sin `[TAG]` prefix. Ejemplo: `feat(payments): US8 — Shipper payment flow with sync fake gateway`. TAG va en body (`Closes #213`) y branch.
- **`gh pr create --assignee @me`**.
- **Pre-PR UI gate**: `/critique` → `/polish` → `/audit` sobre `/shipper/shipments/:id/pay` y `/dev/fake-payment/new`. `just lint`, `just frontend-test-coverage` (80%), `just frontend-test-e2e`, `just backend-test` verdes.
- **Migration**: `db/migrate/<ts>_create_payments.rb` con índices del schema-block de arriba. Columna `state` NOT NULL, sin default — siempre seteada en `create` por el servicio.
- **Docs a actualizar como parte del PR**:
  - `domain-model.md` § Payments — schema + FSM nuevos.
  - `api-overview.md` — endpoint único `POST /api/shipments/:id/payments`.
  - `glossary.md` — ya actualizado en el sprint (Payment FSM y cancellation interlock).
  - `technical-vision.md` (ADR-012) — addendum reflejando sync mock + drop de `pending`.
