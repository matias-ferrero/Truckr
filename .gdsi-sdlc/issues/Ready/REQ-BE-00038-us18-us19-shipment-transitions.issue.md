---
tag: REQ-BE-00038
title: US18+US19 — Shipment transitions (start_transit, deliver) Carrier-only
priority: P1
status: ready
created: '2026-05-24'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/243
author: Claude Code
github_issue: 243
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgtsjAo
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-25T03:38:24.191799+00:00Z
labels:
- BE
- REQ
- fulfilment
- carrier
- shipment
- mvp
- us18
- us19
- fsm
sprint: 3
plan: docs/features/REQ/REQ-BE-00038/REQ-BE-00038-us18-us19-shipment-transitions.plan.md
---

## Summary

Endpoints del Transportista para mover el `Shipment` por los dos tramos físicos del FSM canónico: `accepted → in_transit` (US18 — "carga retirada") y `in_transit → delivered` (US19 — "entregada"). Comparten autorización (sólo el Carrier asignado al `Shipment`), guard de estado, patrón de race-safety (`with_lock`), y suite de specs — por eso aterrizan combinados en un único issue / PR. Splittearlos sería artificial.

Los dos endpoints NO modifican el FSM canónico documentado en glossary y ADR-012 — sólo lo implementan. El estado terminal `cancelled` y el endpoint de cancelación son **fuera de alcance** (deferred a Sprint 4+ — ver REQ-FE-00024 plan). Tampoco hay endpoint `accept` acá: el `Shipment` ya nace en `accepted` desde el flujo de aceptación de oferta (REQ-BE-00024, US12).

## Decisiones canónicas (ver glossary + ADR-012)

| Tema | Decisión |
|---|---|
| FSM `Shipment` | `accepted → in_transit → delivered` (+ `cancelled` terminal, fuera de este issue). Sin cambios — implementación, no rediseño. |
| Endpoint US18 | `POST /api/shipments/:id/start_transit`. Guard: `state == accepted`. Transición: `in_transit`. Sello: `started_at = Time.current`. |
| Endpoint US19 | `POST /api/shipments/:id/deliver`. Guard: `state == in_transit`. Transición: `delivered`. Sello: `delivered_at = Time.current`. |
| Autorización | Sólo el `Carrier` asignado al `Shipment` (`current_carrier.present? && current_carrier.id == shipment.carrier_id`). Otros roles / otros Carriers → `403`. |
| Guard de FSM violado | `409 Conflict` con clave i18n `errors.shipments.{start_transit,deliver}.invalid_state`. Mismo código que el cancellation interlock de REQ-BE-00033 — convención del Shipment FSM. |
| Race-safety | `shipment.with_lock { return if !shipment.state_accepted?; shipment.transition_to!(:in_transit, at: Time.current) }` (análogo para `deliver`). No `EXCLUDE`, no advisory locks — SQLite-forever. |
| FSM modeling | A mano en el modelo `Shipment`, mismo patrón que `Payment` (sin gema `aasm`). Método `Shipment#transition_to!(new_state, at:)` único; validación `timestamps_match_state` espeja la de `Payment`. |
| Body de request | Vacío. La acción es implícita en el endpoint. |
| Response | `200 OK` con el `ShipmentResource` actualizado (incluye `state`, `started_at`, `delivered_at`, `available_actions`). Para que el FE de US39 / US17 refresque su chip + acciones disponibles sin un GET extra. |
| Idempotencia | El `with_lock` + guard hace que un segundo POST llegado a un `Shipment` ya en `in_transit` (US18) o ya en `delivered` (US19) reciba `409`. No 200 silencioso — el FE debe distinguir éxito de "ya estaba". |
| Pre-pago | US18 sólo se permite cuando hay un `Payment.escrowed` para el `Shipment`. Sin pago en escrow → `409`. (AC4 textual de US18: "No se puede marcar como en tránsito un envío que aún no fue aceptado y pagado".) |
| Notificaciones | Fuera de alcance acá. El emit a `Notifications::Publisher` se agrega cuando aterrice INF-BE-00005 (framework de notificaciones); este issue no lo bloquea. |
| Tracking events | Cada transición append-only en `tracking_events` con `kind: picked_up` (US18) y `kind: delivered` (US19). Mismo `with_lock`. La timeline de US39 los lee. |

## User stories (fuente)

`docs/artifacts/backlog-us.typ` — US18 y US19:

> **US18 — Actualización de Envío — Carga Retirada.** Como transportista, quiero poder marcar una carga como retirada, para que el expedidor sepa que ya recogí su carga y el envío está en curso.

> **US19 — Actualización de Envío — Carga Entregada.** Como transportista, quiero poder marcar una carga como entregada, para que el expedidor lo sepa y se concrete el pago del servicio.

## Acceptance criteria

ACs de producto (verbatim del backlog, etiquetadas):

- [ ] **AC1 [US18]** — Al retirar la carga, el transportista puede marcarla como "en tránsito" con un botón (botón vive en FE de US39; este issue entrega el endpoint que dispara).
- [ ] **AC2 [US18]** — Al expedidor se le muestra que el transportista ya recogió su carga en el estado del envío (chip `in_transit` derivado de `shipment.state` en el `ShipmentResource`).
- [ ] **AC3 [US18]** — La fecha y hora del retiro quedan registradas (`shipments.started_at = Time.current` + `tracking_events` row con `kind: picked_up`).
- [ ] **AC4 [US18]** — No se puede marcar como "en tránsito" un envío que aún no fue aceptado y pagado. Implementación: guard adicional verifica `shipment.payments.escrowed.exists?`; si falta, `409` con clave `errors.shipments.start_transit.not_paid`.
- [ ] **AC5 [US19]** — Al entregar la carga, el transportista puede marcarla como "entregada" con un botón (botón vive en FE de US39; este issue entrega el endpoint).
- [ ] **AC6 [US19]** — Al expedidor se le muestra el estado del envío como completado (chip `delivered`).
- [ ] **AC7 [US19]** — La confirmación de entrega dispara el proceso de transferencia de pago al transportista. **Nota de alcance:** en el MVP el `Payment.escrowed` ya es terminal (ADR-012); "transferencia" se materializa post-MVP. Para este issue: la transición a `delivered` queda registrada y el chip de Payment del Shipment se renombra a "Pago liberado" en el FE (composición de UI, no estado FSM). Sin job de settlement.
- [ ] **AC8 [US19]** — La fecha y hora de entrega quedan registradas (`shipments.delivered_at = Time.current` + `tracking_events` row con `kind: delivered`).
- [ ] **AC9 [US19]** — No se puede marcar como entregado un envío que no fue previamente marcado como "en tránsito". Implementación: guard `state == in_transit` → `409` con clave `errors.shipments.deliver.invalid_state`.

ACs de implementación (compartidas US18 + US19):

- [ ] **AC10** — Sólo el `Carrier` dueño del `Shipment` puede invocar ambos endpoints (`ShipmentPolicy#start_transit?` / `#deliver?`). Otros usuarios → `403` con clave `errors.unauthorized`.
- [ ] **AC11** — Ambos endpoints son race-safe — request specs con dos llamadas concurrentes confirman que a lo sumo una transición ocurre. Implementación: `shipment.with_lock { guard; transition; create tracking_event }`.
- [ ] **AC12** — Todas las claves de error pasan por `I18n.t(...)`. Cero literales en controllers. Backend locales en `config/locales/{en,es}.yml`.
- [ ] **AC13** — `Shipment#transition_to!(new_state, at:)` modelado a mano (sin `aasm`), análogo al patrón ya usado por `Payment` en REQ-BE-00033. Validación `timestamps_match_state` asegura coherencia `state ↔ {started_at, delivered_at}`.
- [ ] **AC14** — `ShipmentResource` incluye `available_actions` re-derivado tras cada transición (consume FE US17 / US39). Tras `start_transit` exitoso, la respuesta lista `mark_delivered`; tras `deliver`, lista `[]`.
- [ ] **AC15** — RSpec cubre: happy-path por endpoint, guard de estado (`409`), guard de autorización (`403`), pre-pago para US18 (`409` cuando no hay `Payment.escrowed`), race-safety (concurrent specs), y append en `tracking_events`. SimpleCov no baja del baseline.

## API contract

### `POST /api/shipments/:id/start_transit` (US18)

- **Authz**: `ShipmentPolicy#start_transit?` — `current_carrier.present? && current_carrier.id == shipment.carrier_id`.
- **Guards**: `shipment.state_accepted?` AND `shipment.payments.escrowed.exists?`.
- **Body**: vacío.
- **Side effect**: `shipment.with_lock { shipment.transition_to!(:in_transit, at: Time.current); TrackingEvent.create!(shipment:, kind: :picked_up, occurred_at: Time.current) }`.
- **Response**: `200 OK` con `ShipmentResource` actualizado.
- **Errors**:
  - `403` (no autorizado, no es el Carrier asignado) — `errors.unauthorized`.
  - `409` (estado distinto de `accepted`) — `errors.shipments.start_transit.invalid_state`.
  - `409` (sin `Payment.escrowed`) — `errors.shipments.start_transit.not_paid`.
  - `404` (Shipment inexistente o soft-deleted) — convención existente.

### `POST /api/shipments/:id/deliver` (US19)

- **Authz**: `ShipmentPolicy#deliver?` — `current_carrier.present? && current_carrier.id == shipment.carrier_id`.
- **Guards**: `shipment.state_in_transit?`.
- **Body**: vacío.
- **Side effect**: `shipment.with_lock { shipment.transition_to!(:delivered, at: Time.current); TrackingEvent.create!(shipment:, kind: :delivered, occurred_at: Time.current) }`.
- **Response**: `200 OK` con `ShipmentResource` actualizado.
- **Errors**:
  - `403` (no autorizado) — `errors.unauthorized`.
  - `409` (estado distinto de `in_transit`) — `errors.shipments.deliver.invalid_state`.
  - `404` (Shipment inexistente o soft-deleted).

## Domain model

### Schema (`shipments` table — additions only)

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `started_at` | `datetime` | yes | — | Set on `accepted → in_transit`. Frozen post-transition. |
| `delivered_at` | `datetime` | yes | — | Set on `in_transit → delivered`. Frozen post-transition. |

Migración nueva si las columnas no existen aún. Si REQ-BE-00035 (factories del Shipment) ya las introdujo, idempotente — no agregar columnas duplicadas, sólo verificar.

### Validación `timestamps_match_state`

Espeja la convención de `Payment` (REQ-BE-00033):

```ruby
validate :timestamps_match_state

def timestamps_match_state
  if state_in_transit? && started_at.nil?
    errors.add(:started_at, :missing_for_in_transit)
  end
  if state_delivered? && (started_at.nil? || delivered_at.nil?)
    errors.add(:delivered_at, :missing_for_delivered)
  end
end
```

## Frontend scope

Ninguno. Los botones que disparan estos endpoints viven en el FE de US39 (REQ-FE-00024) y/o en US17 listado, ambos issues separados. Este issue es backend-only — sólo el endpoint + tests + i18n keys.

## i18n

Claves nuevas bajo `errors.shipments.start_transit.*` y `errors.shipments.deliver.*` en `backend/config/locales/{en,es}.yml`. Sin literales hardcoded.

## Out of scope (deliberadamente diferido)

- Endpoint `POST /api/shipments/:id/cancel` (cancelación por el Expedidor con interlock de Payment). Diferido a Sprint 4+ — la cancelación interlock por parte del **Shipment FSM** ya está cubierta en REQ-BE-00033 AC14 desde el lado de `Payment`; el lado Shipment espera issue propio.
- Endpoint `POST /api/shipments/:id/accept` — el `Shipment` ya nace `accepted` desde el flujo de aceptación de oferta del Carrier (REQ-BE-00024).
- Emisión de `Notifications::Publisher` (depende de INF-BE-00005).
- Settlement / transferencia real al Carrier (ADR-012 explícitamente fuera del MVP).
- Mapa / waypoint updates (US51, Sprint 4).

## Related

- **Glossary**: «Envío» (`docs/05-appendices/glossary.md` línea ~25) — fuente canónica del FSM.
- **ADR-012** (`docs/01-technical-vision/technical-vision.md`, ~línea 152) — confirma que `accepted → in_transit → delivered` es el FSM canónico y que `settled` quedó fuera.
- **Construye sobre**: REQ-BE-00024 (US12, Shipment nace `accepted`), REQ-BE-00033 (US8, Payment escrow + cancellation interlock, patrón `with_lock` + `transition_to!`).
- **Cliente FE**: REQ-FE-00024 (US39, detalle de envío con `available_actions`) — consume `mark_picked_up` / `mark_delivered` actions y refetcha tras el POST.
- **Coordinar con**: REQ-BE-00035 (factories del Shipment cubren los 6 combos relevantes — verificar que `accepted+paid` y `in_transit` están presentes).
- **No depende de**: INF-BE-00005 (notificaciones — feature flag implícita; el emit se agrega cuando aterrice).

## Implementation notes (pre-PR)

- **Branch name**: `feature/REQ-BE-00038-us18-us19-shipment-transitions`.
- **PR title** (UTMOST): conventional type al inicio, sin `[TAG]` prefix. Ejemplo: `feat(fulfilment): US18+US19 — Carrier shipment transitions (start_transit, deliver)`. TAG va en body (`Closes #N`) y branch.
- **`gh pr create --assignee @me`**.
- **Pre-PR gate**: `just lint`, `just backend-test` (SimpleCov no baja del baseline). Sin FE en este issue → no aplica el quality gate de impeccable.
- **Migration**: sólo si `started_at` / `delivered_at` no fueron introducidas por REQ-BE-00035. Idempotente.
- **Plan**: ver `docs/features/REQ/REQ-BE-00038/REQ-BE-00038-us18-us19-shipment-transitions.plan.md` (autoría en paralelo).
