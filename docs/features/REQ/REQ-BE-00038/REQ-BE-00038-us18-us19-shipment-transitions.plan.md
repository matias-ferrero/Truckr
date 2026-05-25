# REQ-BE-00038: Transiciones de `Shipment` por el Transportista — `start_transit` + `deliver` (US18 + US19)

| Field | Value |
|-------|-------|
| **Tag** | REQ-BE-00038 |
| **Title** | Shipment transitions (start_transit, deliver) Carrier-only — US18 + US19 |
| **Priority** | P1 |
| **Status** | READY |
| **Created** | 2026-05-24 |
| **Sprint** | 3 |
| **Author** | Claude Code |
| **Depends On** | `REQ-BE-00024` (US12 — `Shipment` nace `accepted` desde la aceptación de oferta). `REQ-BE-00033` (US8 — `Payment.escrowed | failed`, patrón `with_lock` + `transition_to!`, cancellation interlock). |
| **Decision Doc** | N/A — decisiones cerradas inline en `.gdsi-sdlc/issues/Ready/REQ-BE-00038-us18-us19-shipment-transitions.issue.md`, glossary (línea 25, «Envío») y ADR-012 (`docs/01-technical-vision/technical-vision.md:152`, enmienda 2026-05-24). |
| **Selected Approach** | Un PR — dos endpoints simétricos en `Api::ShipmentsController` (`start_transit`, `deliver`), modelo `Shipment` con FSM a mano (`transition_to!` espejando `Payment`), validación `timestamps_match_state`, dos guardas (estado + autorización; `start_transit` añade pre-pago), `tracking_events` append por transición, todo dentro de `with_lock` para race-safety. SQLite-forever — sin advisory locks, sin `EXCLUDE`. |

---

## 1. Decisiones canónicas

Re-lectura obligada del issue body en `.gdsi-sdlc/issues/Ready/REQ-BE-00038-us18-us19-shipment-transitions.issue.md` § «Decisiones canónicas» (es la fuente). Este plan es el «cómo» y no las redecide.

| Tema | Decisión | Fuente |
|---|---|---|
| FSM canónico del `Shipment` | `accepted → in_transit → delivered` + `cancelled` terminal desde `accepted` o `in_transit`. | Glossary `docs/05-appendices/glossary.md:25` «Envío»; ADR-012 enmendado 2026-05-24 (`docs/01-technical-vision/technical-vision.md:152`). |
| Endpoint US18 | `POST /api/shipments/:id/start_transit` — guard `state == accepted` AND `payments.escrowed.exists?`. Transición a `in_transit`. Sello `started_at = Time.current`. | Issue § «Decisiones canónicas» + AC1–AC4. |
| Endpoint US19 | `POST /api/shipments/:id/deliver` — guard `state == in_transit`. Transición a `delivered`. Sello `delivered_at = Time.current`. | Issue § «Decisiones canónicas» + AC5–AC9. |
| Autorización | Sólo el `Carrier` asignado (`current_carrier.present? && current_carrier.id == shipment.carrier_id`). Otros → `403 errors.unauthorized`. | Issue AC10. |
| Guard de FSM violado | `409 Conflict` con clave i18n `errors.shipments.{start_transit,deliver}.invalid_state`. | Issue § «Decisiones canónicas». |
| Pre-pago (sólo US18) | `Payment.escrowed.exists?` para el `Shipment` antes de transitar. Sin escrow → `409 errors.shipments.start_transit.not_paid`. | Issue AC4. Predicado idéntico al usado por `CarrierPolicy#can_view_contact?` en REQ-BE-00033. |
| Race-safety | `shipment.with_lock { guard; transition_to!(...); TrackingEvent.create! }`. Sin advisory locks ni `EXCLUDE`. | Issue AC11; CLAUDE.md «Database policy». |
| FSM modeling | A mano en `Shipment` model — método único `Shipment#transition_to!(new_state, at:)`, validación `timestamps_match_state`. Mismo patrón que `Payment` en REQ-BE-00033. **Sin** gema `aasm`. | Issue AC13. |
| Body request / response | Body request vacío. Response `200 OK` con `ShipmentResource` actualizado (incluye `state`, `started_at`, `delivered_at`, `available_actions`). | Issue § «API contract». |
| Idempotencia | Segundo POST al mismo endpoint sobre un `Shipment` ya transicionado → `409 invalid_state`. **No** `200` silencioso. | Issue § «Decisiones canónicas». |
| `available_actions` recomputado | El `ShipmentResource` re-deriva `available_actions` tras la transición. Tras `start_transit` → `[:mark_delivered]`. Tras `deliver` → `[]`. **No incluye `cancel`** (deferido — ver §8). | Issue AC14. |
| `tracking_events` append | Cada transición crea una fila en `tracking_events` con `kind: :picked_up` (US18) o `kind: :delivered` (US19), `occurred_at: Time.current`. Append-only. | Issue AC3, AC8. |
| Notificaciones / settlement | Fuera de alcance. Sin emit a `Notifications::Publisher` (INF-BE-00005 no aterrizó), sin job de settlement (ADR-012 — `escrowed` es terminal en MVP). | Issue § «Out of scope». |

## 2. Schema / migrations

`shipments` necesita dos columnas timestamp opcionales — `started_at` y `delivered_at`. Verificar primero con `bundle exec rails runner 'puts Shipment.column_names.sort'` si REQ-BE-00035 ya las introdujo: si están, **diff vacío** en este paso (idempotente, no agregar duplicadas); si no, migración nueva:

```
db/migrate/20260525130000_add_transition_timestamps_to_shipments.rb
```

```ruby
class AddTransitionTimestampsToShipments < ActiveRecord::Migration[8.0]
  def change
    add_column :shipments, :started_at,   :datetime, null: true
    add_column :shipments, :delivered_at, :datetime, null: true
  end
end
```

Naming `{YYYYMMDDHHMMSS}_{snake}.rb` consistente con `20260524000000_update_shipment_statuses_for_payment_flow.rb` (REQ-BE-00033) y `20260525120000_*` (REQ-BE-00036). Sin defaults — nullable puro; el servicio sella con `Time.current` al transitar. Sin índices nuevos (no se filtra por estos timestamps en hot paths del MVP). SQLite-forever — no `EXCLUDE`, sin partial indexes.

No tocar `shipments.state` (lo gobierna REQ-BE-00033 / glossary). No tocar `tracking_events.kind` (el enum ya admite `:picked_up` y `:delivered`; si no — confirmar y, sólo si falta, abrir issue de cleanup separado en lugar de aterrizarlo acá).

## 3. FSM block (canónico)

```
        accepted ──start_transit──▶ in_transit ──deliver──▶ delivered  (terminal, éxito)
            │                          │
            └──── cancel ──────────────┴────▶ cancelled                (terminal, deferred — Sprint 4+)
```

**Sello de timestamps por estado** (validación `timestamps_match_state`):

| state | `started_at` | `delivered_at` |
|---|---|---|
| `accepted` | `nil` | `nil` |
| `in_transit` | NOT NULL (set en transición) | `nil` |
| `delivered` | NOT NULL (preservado) | NOT NULL (set en transición) |
| `cancelled` | depende del estado previo (preservado) | `nil` |

`cancelled` queda **fuera** del alcance de este PR — ver §8.

Modelado a mano (sin `aasm`), espejando `Payment#create_in_terminal_state!` de REQ-BE-00033:

```ruby
# app/models/shipment.rb (additions only)

STATES = %w[accepted in_transit delivered cancelled].freeze
LEGAL_TRANSITIONS = {
  "accepted"   => %w[in_transit cancelled],
  "in_transit" => %w[delivered cancelled],
  "delivered"  => [],
  "cancelled"  => []
}.freeze

%w[accepted in_transit delivered cancelled].each do |s|
  define_method("state_#{s}?") { state == s }
end

validate :timestamps_match_state

def transition_to!(new_state, at:)
  raise ArgumentError, "illegal transition #{state} → #{new_state}" \
    unless LEGAL_TRANSITIONS.fetch(state, []).include?(new_state.to_s)

  assignments = { state: new_state.to_s }
  case new_state.to_sym
  when :in_transit then assignments[:started_at]   = at
  when :delivered  then assignments[:delivered_at] = at
  end
  update!(assignments)
end

private

def timestamps_match_state
  errors.add(:started_at,   :missing_for_in_transit) if state_in_transit? && started_at.nil?
  if state_delivered?
    errors.add(:started_at,   :missing_for_delivered) if started_at.nil?
    errors.add(:delivered_at, :missing_for_delivered) if delivered_at.nil?
  end
end
```

`LEGAL_TRANSITIONS` enumera `cancelled` como destino legal desde `accepted` e `in_transit` porque eso es lo que dice el FSM canónico — el hecho de que el **endpoint** `cancel` no se exponga en este sprint no rompe la tabla. Quien lo aterrice en Sprint 4+ sólo agrega ruta + policy; el modelo ya está listo.

## 4. API contract

Ambos endpoints viven bajo `Api::ShipmentsController` (ya existente en la jerarquía de REQ-BE-00035 / REQ-BE-00024) como member actions sobre el resource `shipments`. Ruta:

```ruby
# config/routes.rb
namespace :api do
  resources :shipments, only: %i[index show] do
    member do
      post :start_transit
      post :deliver
    end
  end
end
```

### 4.1 `POST /api/shipments/:id/start_transit` (US18)

- **Authz**: `ShipmentPolicy#start_transit?` — `current_carrier.present? && current_carrier.id == record.carrier_id`.
- **Guards** (dentro de `with_lock`):
  1. `shipment.state_accepted?` — si no, `409 errors.shipments.start_transit.invalid_state`.
  2. `shipment.payments.escrowed.exists?` — si no, `409 errors.shipments.start_transit.not_paid`.
- **Body request**: vacío.
- **Side effect**: `transition_to!(:in_transit, at: now)` + `TrackingEvent.create!(shipment:, kind: :picked_up, occurred_at: now)`.
- **Response**:
  - `200 OK` con `ShipmentResource` actualizado (`state: "in_transit"`, `started_at` set, `available_actions: ["mark_delivered"]`).
- **Errors**:
  - `403 errors.unauthorized` — no es el Carrier asignado.
  - `409 errors.shipments.start_transit.invalid_state` — estado distinto de `accepted`.
  - `409 errors.shipments.start_transit.not_paid` — sin `Payment.escrowed`.
  - `404` — Shipment inexistente o soft-deleted (convención existente de `ApplicationController` o `BaseController`).

### 4.2 `POST /api/shipments/:id/deliver` (US19)

- **Authz**: `ShipmentPolicy#deliver?` — mismo predicado que `start_transit?`.
- **Guards** (dentro de `with_lock`):
  1. `shipment.state_in_transit?` — si no, `409 errors.shipments.deliver.invalid_state`.
- **Body request**: vacío.
- **Side effect**: `transition_to!(:delivered, at: now)` + `TrackingEvent.create!(shipment:, kind: :delivered, occurred_at: now)`.
- **Response**:
  - `200 OK` con `ShipmentResource` actualizado (`state: "delivered"`, `delivered_at` set, `available_actions: []`).
- **Errors**:
  - `403 errors.unauthorized`.
  - `409 errors.shipments.deliver.invalid_state` — estado distinto de `in_transit`.
  - `404` — Shipment inexistente o soft-deleted.

### 4.3 Controller — shape canónico

```ruby
# app/controllers/api/shipments_controller.rb (additions only)

def start_transit
  shipment = policy_scope(Shipment).find(params[:id])
  authorize shipment, :start_transit?

  shipment.with_lock do
    unless shipment.state_accepted?
      return render_error(:conflict, "errors.shipments.start_transit.invalid_state")
    end
    unless shipment.payments.escrowed.exists?
      return render_error(:conflict, "errors.shipments.start_transit.not_paid")
    end

    now = Time.current
    shipment.transition_to!(:in_transit, at: now)
    TrackingEvent.create!(shipment:, kind: :picked_up, occurred_at: now)
  end

  render json: ShipmentResource.new(shipment).serialize, status: :ok
end

def deliver
  shipment = policy_scope(Shipment).find(params[:id])
  authorize shipment, :deliver?

  shipment.with_lock do
    unless shipment.state_in_transit?
      return render_error(:conflict, "errors.shipments.deliver.invalid_state")
    end

    now = Time.current
    shipment.transition_to!(:delivered, at: now)
    TrackingEvent.create!(shipment:, kind: :delivered, occurred_at: now)
  end

  render json: ShipmentResource.new(shipment).serialize, status: :ok
end
```

`render_error` es el helper existente (envoltorio sobre `RenderableError` o equivalente — espejo del shape `{ error: { code, message } }` que ya usa REQ-BE-00033). Si el helper no existe aún en el árbol main al momento de implementar, replicar el shape de los errores 422/409 ya producidos por la API (mirar `Api::PaymentsController` como referencia).

### 4.4 i18n keys (nuevas)

`backend/config/locales/es.yml` + `en.yml`:

```yaml
es:
  errors:
    shipments:
      start_transit:
        invalid_state: "El envío no se encuentra en estado «aceptado»."
        not_paid: "El envío aún no fue pagado."
      deliver:
        invalid_state: "El envío no se encuentra en tránsito."
```

```yaml
en:
  errors:
    shipments:
      start_transit:
        invalid_state: "Shipment is not in 'accepted' state."
        not_paid: "Shipment has not been paid yet."
      deliver:
        invalid_state: "Shipment is not in transit."
```

Validation messages en `activerecord.errors.models.shipment.attributes.{started_at,delivered_at}.{missing_for_in_transit,missing_for_delivered}`. Reutilizar `errors.unauthorized` ya existente (REQ-BE-00033).

## 5. Policies

`ShipmentPolicy` (Pundit) — añadir dos métodos. Si la clase ya existe (lo más probable, REQ-BE-00035 la usa para `show?`/`index?`), extender; si no, crear:

```ruby
# app/policies/shipment_policy.rb
class ShipmentPolicy < ApplicationPolicy
  # existing: show?, index? — gestionados por REQ-BE-00035

  def start_transit?
    user_is_assigned_carrier?
  end

  def deliver?
    user_is_assigned_carrier?
  end

  private

  def user_is_assigned_carrier?
    return false unless user.respond_to?(:carrier) && user.carrier.present?
    user.carrier.id == record.carrier_id
  end
end
```

`user` acá es el `current_user` (no el `current_carrier` directamente) — para evitar acoplar el policy a un helper de controller. El predicado `user.carrier.present?` cumple el rol de «el usuario tiene perfil Carrier activo». No agregar booleano denormalizado al `User`.

`policy_scope(Shipment)` en `index` / `show` ya filtra por dueño (REQ-BE-00035 lo asegura) — `start_transit` / `deliver` heredan ese scope vía `policy_scope(Shipment).find(params[:id])`, dando `404` (vs `403`) cuando el `Shipment` existe pero pertenece a otro Carrier. Eso es deliberado: no leak de IDs ajenos.

## 6. Tests (RSpec)

Cobertura exigida — SimpleCov no baja del baseline existente. Mínimo, los specs listados acá. Espejar el patrón de `spec/requests/api/payments_spec.rb` (REQ-BE-00033).

### 6.1 Model — `spec/models/shipment_spec.rb`

- `transition_to!(:in_transit, at:)` desde `accepted` setea `state` y `started_at`. Desde otro estado raise `ArgumentError`.
- `transition_to!(:delivered, at:)` desde `in_transit` setea `state` y `delivered_at`. Desde otro estado raise `ArgumentError`.
- `transition_to!(:cancelled, at:)` desde `accepted` o `in_transit` legal (sin endpoint, pero el modelo lo permite — sanity check para el aterrizaje de Sprint 4+).
- Validación `timestamps_match_state`:
  - `state: "in_transit", started_at: nil` → `errors[:started_at]` con clave `:missing_for_in_transit`.
  - `state: "delivered", delivered_at: nil` → `errors[:delivered_at]`.
  - `state: "delivered", started_at: nil` → `errors[:started_at]`.

### 6.2 Request — `spec/requests/api/shipments/start_transit_spec.rb`

- Carrier dueño + `state: "accepted"` + `Payment.escrowed` existe → `200`, response body `{ state: "in_transit", started_at: present, available_actions: ["mark_delivered"] }`. `tracking_events` cuenta sube en 1 con `kind: "picked_up"`.
- Otro Carrier (no asignado) → `403 errors.unauthorized`.
- Shipper-only user → `403`.
- Carrier dueño + `state: "in_transit"` → `409 errors.shipments.start_transit.invalid_state`.
- Carrier dueño + `state: "accepted"` + sin `Payment.escrowed` (sólo `failed`) → `409 errors.shipments.start_transit.not_paid`.
- Race-safety: dos `Thread.new { post ... }` concurrentes — exactamente uno recibe `200`, el otro `409`. `tracking_events` cuenta sube en 1 (no 2).

### 6.3 Request — `spec/requests/api/shipments/deliver_spec.rb`

- Carrier dueño + `state: "in_transit"` → `200`, body `{ state: "delivered", delivered_at: present, available_actions: [] }`. `tracking_events` +1 con `kind: "delivered"`.
- Otro Carrier → `403`.
- Carrier dueño + `state: "accepted"` → `409 errors.shipments.deliver.invalid_state`.
- Carrier dueño + `state: "delivered"` → `409 errors.shipments.deliver.invalid_state` (idempotencia explícita — segundo POST = `409`, NO `200` silencioso).
- Race-safety: análogo a §6.2.

### 6.4 Factories

`spec/factories/shipments.rb` — verificar que existen traits `:accepted`, `:in_transit`, `:delivered` con los timestamps correlativos. Si REQ-BE-00035 los introdujo, idempotente. Si no, agregarlos:

```ruby
factory :shipment do
  carrier
  cargo_offer
  state { "accepted" }

  trait :with_escrowed_payment do
    after(:create) { |s| create(:payment, :escrowed, shipment: s) }
  end

  trait :in_transit do
    state { "in_transit" }
    started_at { Time.current }
  end

  trait :delivered do
    state { "delivered" }
    started_at { 1.hour.ago }
    delivered_at { Time.current }
  end
end
```

Coordinar con REQ-BE-00035 si el archivo entra en conflicto — `git diff` antes de commit.

## 7. Task list (ordenada)

| # | Task | Layer | Files |
|---|------|-------|-------|
| 1 | Migración `add_transition_timestamps_to_shipments` — idempotente (skip si REQ-BE-00035 las introdujo) | DB | `backend/db/migrate/20260525130000_add_transition_timestamps_to_shipments.rb` |
| 2 | Constante `STATES` + `LEGAL_TRANSITIONS` + predicados `state_*?` + `transition_to!` en `Shipment` | Model | `backend/app/models/shipment.rb` |
| 3 | Validación `timestamps_match_state` en `Shipment` | Model | `backend/app/models/shipment.rb` |
| 4 | Locales `errors.shipments.{start_transit,deliver}.*` + validation keys | i18n | `backend/config/locales/es.yml`, `en.yml` |
| 5 | Rutas member `:start_transit` + `:deliver` | Routes | `backend/config/routes.rb` |
| 6 | Actions `start_transit` + `deliver` en `Api::ShipmentsController` | Controller | `backend/app/controllers/api/shipments_controller.rb` |
| 7 | `start_transit?` + `deliver?` en `ShipmentPolicy` | Policy | `backend/app/policies/shipment_policy.rb` |
| 8 | `available_actions` re-derivado en `ShipmentResource` — verificar que ya consume `state_*?` predicates. Si el resource es propiedad de REQ-BE-00035, coordinar via PR review en lugar de duplicar el atributo. | Resource | (sin archivo en este PR si REQ-BE-00035 ya lo emite; sólo confirmar shape) |
| 9 | Factory traits `:in_transit`, `:delivered`, `:with_escrowed_payment` | Spec | `backend/spec/factories/shipments.rb` |
| 10 | Model spec — transitions + `timestamps_match_state` | Spec | `backend/spec/models/shipment_spec.rb` |
| 11 | Request spec `start_transit` — happy path + 403 + 409 (invalid_state + not_paid) + race | Spec | `backend/spec/requests/api/shipments/start_transit_spec.rb` |
| 12 | Request spec `deliver` — happy path + 403 + 409 + race | Spec | `backend/spec/requests/api/shipments/deliver_spec.rb` |
| 13 | `just backend-test` + `just lint` verdes localmente antes del PR | CI gate | — |

## 8. Out of scope

- **Endpoint `POST /api/shipments/:id/cancel`** — diferido a Sprint 4+. La columna `state: "cancelled"` y la transición en `LEGAL_TRANSITIONS` ya quedan declaradas en el modelo (§3) para no rehacer trabajo cuando aterrice; pero **ninguna ruta lo expone**. REQ-FE-00024 (US39 detalles de envío) oculta el botón cuando `available_actions` no incluye el verbo — y este PR garantiza que `available_actions` nunca lista `:cancel`.
- **Endpoint `POST /api/shipments/:id/accept`** — no existe. El `Shipment` nace `accepted` desde la aceptación de oferta del Carrier (REQ-BE-00024, PR #221).
- **Settlement job / release de escrow** — ADR-012 fija `escrowed` como terminal en el MVP. Sin `PaymentSettlementJob`, sin transferencia automática al Carrier. La «transferencia» de US19 AC7 se materializa post-MVP; en este sprint, el FE de US39 simplemente re-rotula el chip de Payment como «Pago liberado» cuando `shipment.state == "delivered"` (composición de UI, sin estado FSM nuevo).
- **Emisión a `Notifications::Publisher`** — INF-BE-00005 (framework de notificaciones) no aterrizó. El emit se agrega cuando exista, como follow-up no bloqueante de este issue.
- **Mapa / waypoint updates en vivo** — US51, Sprint 4. `tracking_events` registra los hitos `:picked_up` / `:delivered` pero no se materializa una timeline geográfica en este PR.
- **Cambios al shape JSON del `Cargo` en `ShipmentResource`** — propiedad de REQ-BE-00035 / REQ-BE-00036 (cargo lat/lng). Este PR no toca ese bloque.
- **Soft-delete o discard del `Shipment`** — fuera de alcance.

## 9. Related

- **Issue body**: `.gdsi-sdlc/issues/Ready/REQ-BE-00038-us18-us19-shipment-transitions.issue.md` — fuente canónica de AC y decisiones.
- **User stories**: `docs/artifacts/backlog-us.typ` — US18 + US19.
- **Glossary**: `docs/05-appendices/glossary.md:25` — «Envío», FSM canónico.
- **ADR-012**: `docs/01-technical-vision/technical-vision.md:152` (enmendado 2026-05-24) — Payment born-terminal + Shipment FSM `accepted → in_transit → delivered` (+ `cancelled`).
- **Construye sobre**:
  - REQ-BE-00024 (US12 — `Shipment` nace `accepted`).
  - REQ-BE-00033 (US8 — `Payment.escrowed | failed` + patrón `with_lock` + cancellation interlock). Este PR consume el predicado `shipment.payments.escrowed.exists?` que REQ-BE-00033 ya implementó; **no lo redefine**.
- **Cliente FE**:
  - REQ-FE-00024 (US39 — detalles de envío) — consume `available_actions` (`mark_picked_up` / `mark_delivered`) y refetcha el detail tras el POST.
  - REQ-FE-00023 (US17 — listado de envíos del Carrier) — consume `available_actions` para chips/CTAs en cada fila.
- **Coordinación**:
  - REQ-BE-00035 (ShipmentResource emission, factories del Shipment, cargo lat/lng) — dueño del shape `ShipmentResource`. Este PR depende de que `available_actions` esté ya emitido y se re-derive del `Shipment.state`. Si la columna `started_at` / `delivered_at` ya fue introducida por REQ-BE-00035, la migración de §2 queda como diff vacío (idempotente).
- **No depende de**:
  - INF-BE-00005 (notificaciones — feature flag implícita).
  - REQ-BE-00006 (integración real MercadoPago — post-MVP).

## 10. Pre-PR checks

- **Branch name**: `feature/REQ-BE-00038-us18-us19-shipment-transitions`.
- **PR title** (UTMOST): conventional type al inicio, sin `[TAG]` prefix. Ejemplo: `feat(fulfilment): US18+US19 — Carrier shipment transitions (start_transit, deliver)`. TAG en body (`Closes #N`) y branch.
- **`gh pr create --assignee @me`**.
- **Quality gate**: backend-only (sin FE en este PR → no aplica `/critique` `/polish` `/audit`).
  - `just lint` — limpio.
  - `just backend-test` — RSpec verde, SimpleCov no baja del baseline.
- **Migration sanity**: si `Shipment.column_names.include?("started_at")` antes de migrar, omitir el `add_column` (idempotente).
