---
tag: REQ-BE-00035
title: Endpoints de índice y detalle de Envíos (Carrier / Shipper / detalle) (US17
  + US39)
priority: P1
status: backlog
created: '2026-05-24'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/233
author: Claude Code
github_issue: 233
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgtr3wg
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-24T23:53:55.238416+00:00Z
labels:
- REQ
- BE
- fulfilment
- carrier
- shipper
- mvp
- us17
- us39
---

## Summary

Tres endpoints de lectura sobre `Shipment` que habilitan US17 (listado) y US39 (detalle): `GET /api/carriers/me/shipments`, `GET /api/shippers/me/shipments`, `GET /api/shipments/:id`. Los dos listados devuelven los `Shipment` donde el usuario autenticado es la contraparte correspondiente (transportista o expedidor) e incluyen los datos resumidos que las filas de US17 muestran — incluido el chip de pago derivado de `Payment`. El detalle (`GET /api/shipments/:id`) responde 404 si quien consulta no es contraparte del envío (no se filtra por rol de URL; la autorización Pundit decide). **Es la dependencia BE load-bearing** del sprint para US17 (Carrier + Shipper) y US39.

## Problem Statement

`REQ-BE-00022` aterrizó los modelos de Fulfilment (`Shipment`, `TrackingEvent`, FSM, soft-delete) pero no expuso endpoints HTTP. Sin estos endpoints las US17 (Carrier + Shipper) y US39 quedan bloqueadas porque el frontend no tiene de dónde leer.

Hace falta entender *qué exactamente* devuelven estos endpoints para que las US17 dibujen sus dos chips (estado del envío y estado del pago) sin N+1 ni ida y vuelta al detalle, y para que US39 reciba todo el contexto (origen/destino/carga/vehículo/contraparte/historial de TrackingEvent + acciones permitidas) en una sola request.

## Expected Behavior

### Endpoints

#### `GET /api/carriers/me/shipments`

- Deved JWT → `current_carrier` (Pundit-gated). 401 si no autenticado, 403 si autenticado pero no es Carrier.
- Devuelve los `Shipment` donde `transport_window.vehicle.carrier_id == current_carrier.id` (camino canónico — no se denormaliza `carrier_id` en `Shipment`).
- Orden por defecto: actividad más reciente descendente. Definición pragmática para el MVP: `COALESCE(latest_tracking_event_at, updated_at)` — donde `latest_tracking_event_at` es el `MAX(tracking_events.created_at)` del envío. Implementable con un `LEFT JOIN LATERAL`-free en SQLite vía subquery o con un `eager_load(:tracking_events)` + sort en Ruby si el set es chico. **Default scope ya filtra discarded** (ADR-009).
- Sin paginación / filtros / búsqueda en este sprint (fuera de alcance de US17). Si el set crece, se triagea aparte.

#### `GET /api/shippers/me/shipments`

- JWT → `current_shipper`. Mismas reglas pero mirror sobre el lado Expedidor: `shipment.cargo_offer.cargo.shipper_id == current_shipper.id`.
- Mismo orden, mismo shape de payload.

#### `GET /api/shipments/:id`

- **No tiene prefijo `/carriers/me` ni `/shippers/me` en la ruta** — es una única ruta servida bajo el namespace `/api/shipments/`. La autorización Pundit (`ShipmentPolicy#show?`) determina el acceso: el usuario autenticado debe ser **(a) Carrier dueño del Vehicle de la TransportWindow** o **(b) Shipper dueño del Cargo del CargoOffer**. Cualquier otro caso → **404** (no 403). Razón del 404 sobre 403: no filtramos información sobre la existencia del envío a usuarios que no son contraparte.
- El detalle expone más datos que el listado: bloque completo `cargo` (origen, destino, descripción, peso), bloque `vehicle` (placa, tipo), bloque `counterparty` (depende de quién consulta — si es Carrier muestra al Shipper, si es Shipper muestra al Carrier), el `Payment` asociado en sí mismo (no solo el estado derivado), e historial de `TrackingEvent` en orden cronológico ascendente.

### Shape de respuesta

#### Listados (`/api/carriers/me/shipments`, `/api/shippers/me/shipments`)

```json
{
  "shipments": [
    {
      "id": 42,
      "state": "in_transit",
      "payment_state": "paid",
      "origin": "Buenos Aires, CABA",
      "destination": "Rosario, Santa Fe",
      "created_at": "2026-05-20T14:32:00Z",
      "amount_cents": 18500000,
      "amount_currency": "ARS",
      "latest_activity_at": "2026-05-23T09:11:00Z"
    }
  ]
}
```

Detalles sobre `payment_state`:

- Es un valor derivado, calculado en el serializer (no es una columna en `shipments`).
- Estados: `"pending"` si no hay un `Payment` en estado `escrowed` para ese envío; `"paid"` si existe. **Si `shipment.state == "cancelled"`** el campo `payment_state` se omite del payload (el chip se oculta en el frontend; explicitar la omisión a nivel API es más limpio que devolver `null`).
- Se calcula en una sola query: el listado hace `eager_load(:payment)` y el serializer decide; sin N+1.

`latest_activity_at` es el `COALESCE(tracking_events.MAX(created_at), shipments.updated_at)` mencionado arriba — el frontend no lo usa pero lo expone para verificación / debugging y para confirmar que el orden es el esperado.

#### Detalle (`/api/shipments/:id`)

```json
{
  "shipment": {
    "id": 42,
    "state": "in_transit",
    "payment_state": "paid",
    "created_at": "2026-05-20T14:32:00Z",
    "amount_cents": 18500000,
    "amount_currency": "ARS",
    "cargo": {
      "id": 17,
      "origin": "Buenos Aires, CABA",
      "destination": "Rosario, Santa Fe",
      "description": "Pallets de bebidas",
      "weight_kg": 850
    },
    "vehicle": {
      "id": 9,
      "plate": "AB123CD",
      "kind": "camion_mediano"
    },
    "counterparty": {
      "kind": "shipper",
      "id": 33,
      "display_name": "Logística del Sur SRL"
    },
    "payment": {
      "id": 11,
      "state": "escrowed",
      "amount_cents": 18500000,
      "amount_currency": "ARS",
      "captured_at": "2026-05-21T10:02:00Z"
    },
    "tracking_events": [
      { "id": 80, "kind": "created",   "occurred_at": "2026-05-20T14:32:00Z" },
      { "id": 81, "kind": "picked_up", "occurred_at": "2026-05-22T08:15:00Z" }
    ],
    "available_actions": ["deliver"]
  }
}
```

- `counterparty.kind` es siempre lo opuesto al usuario que consulta — si el Carrier consulta, devuelve al Shipper; si el Shipper consulta, devuelve al Carrier. Esto evita que el frontend tenga que saber quién es quién: el componente de detalle es agnóstico de rol para el bloque de contraparte.
- `payment` puede ser `null` si todavía no se inició el flujo de pago. Si `shipment.state == "cancelled"` se omite (mismo criterio que `payment_state` en los listados).
- `available_actions` es la lista de transiciones que **el usuario autenticado** puede disparar **en el estado actual** del envío. Esto es la fuente única de verdad para los botones de US39 — el frontend no recalcula. Reglas (mirror de los AC de US39):
  - Carrier, `shipment.state == "accepted"` + `payment_state == "paid"`: `["start_transit"]`.
  - Carrier, `shipment.state == "in_transit"`: `["deliver"]`.
  - Shipper, `shipment.state == "accepted"` + `payment_state == "pending"`: `["pay", "cancel"]`.
  - Shipper, `shipment.state == "accepted"` + `payment_state == "paid"`: `[]` (interlock — no cancelación post-pago per ADR-012).
  - `shipment.state in ["delivered", "cancelled"]`: `[]` (solo lectura).
- Los `kind` de `available_actions` son strings estables (`start_transit`, `deliver`, `pay`, `cancel`) que el frontend mapea a clave i18n y endpoint.
- `tracking_events` viene ordenado ascendente por `occurred_at`. El campo `kind` reusa los valores ya definidos por `REQ-BE-00022`.

### Errores y autorización

- 401 sin JWT en cualquiera de los tres endpoints.
- 403 si el JWT es válido pero el rol no corresponde (Shipper consulta `/api/carriers/me/shipments` → 403). En el detalle no hay 403 — ver siguiente bullet.
- 404 en `GET /api/shipments/:id` si el `:id` no existe **O** si el usuario autenticado no es contraparte. Misma respuesta para ambos casos — no se filtra información de existencia.

### Decisión: por qué hay dos endpoints de listado en lugar de uno multi-rol

Alternativa rechazada: un único `GET /api/shipments` que decide qué devolver mirando el rol del JWT. Razón del rechazo:

- La URL es documentación: `/api/carriers/me/shipments` deja claro en el log de acceso, en el código del frontend, y en la spec de Pundit qué persona es la que está leyendo. Un endpoint multi-rol mezcla los dos caminos en un único controller action y hace que el split de la respuesta sea implícito.
- Los dos endpoints comparten serializer y query base (es 5 líneas de Ruby por endpoint), así que el "DRY" del multi-rol no compra nada real.

El detalle sí es multi-rol — pero ahí la URL no puede expresar el rol porque el mismo envío es accesible desde ambos lados, y duplicar la URL para los dos roles sería ruido.

### Específicos de implementación

- **Controllers**:
  - `Api::Carriers::ShipmentsController#index` (acción única) — Pundit `ShipmentPolicy::Scope` con `current_carrier`.
  - `Api::Shippers::ShipmentsController#index` (acción única) — Pundit `ShipmentPolicy::Scope` con `current_shipper`.
  - `Api::ShipmentsController#show` — Pundit `ShipmentPolicy#show?`. **404 (no 403)** cuando el policy rechaza, vía `rescue_from Pundit::NotAuthorizedError, with: :render_not_found` SOLO en esta acción (no cambiar el comportamiento global del rescue de Pundit, que en otros endpoints sigue siendo 403). Implementar override local al action o un módulo `ShowSecretly` para ese ergonomic-vs-explicit.
- **Serializers** — un `ShipmentListSerializer` (campos del listado) y un `ShipmentDetailSerializer` (campos del detalle). Ambos reciben `current_user` para resolver `payment_state`, `counterparty`, y `available_actions`. Sin AMS / sin gem nuevo: serializadores plain Ruby siguen el patrón ya usado en `cargo_offer_serializer.rb` (revisar el camino actual del repo).
- **N+1** — los dos listados hacen `eager_load(:payment, :cargo_offer => { :cargo => :shipper }, :transport_window => { :vehicle => :carrier }, :tracking_events)`. Si el grafo arrastra demasiada data, separar el último (`tracking_events`) y resolverlo solo en el detalle.
- **Sorting** — `latest_activity_at` se calcula con un `LEFT JOIN tracking_events` + `MAX(...)` + `GROUP BY shipments.id` + `ORDER BY COALESCE(MAX(tracking_events.created_at), shipments.updated_at) DESC`. SQLite-clean. Cobertura con índice en `tracking_events(shipment_id, created_at)` — agregar si no existe.
- **Pundit** — `ShipmentPolicy#show?` retorna true si `record.cargo_offer.cargo.shipper_id == user.shipper&.id || record.transport_window.vehicle.carrier_id == user.carrier&.id`. La traducción a 404 vive en el controller (no en el policy — el policy retorna boolean limpio).

## Technical Notes

**Sin endpoints de mutación en este issue.** Las transiciones (`start_transit`, `deliver`, `pay`, `cancel`) son otros endpoints, ya cubiertos por:

- US18 (`start_transit`) y US19 (`deliver`) — ya parte de Sprint 3 backlog (issues separados).
- US8 (`pay`) — `REQ-BE-00033` (Brian, Ready).
- `cancel` — fuera de alcance del MVP per ADR-012 si el envío ya está pagado; la única ruta de cancelación pre-pago de momento es el flujo ya existente del Shipper. Confirmar con el sprint plan si el endpoint dedicado de cancelación cae en este sprint o se difiere.

**SQLite-clean** — todo el join + sort se queda en SQL portable. Sin window functions no soportadas, sin `LATERAL JOIN`, sin `unaccent`. Tested con la base local; si performance es un issue real, se ataca con índices, no con ORM PG-specific.

**Lenguaje** — rutas en inglés (`/api/carriers/me/shipments` — NO `/api/transportistas/...`), JSON keys en `snake_case` inglés, errores via `I18n.t(...)`. Compatible con language policy de CLAUDE.md.

**`payment_state` no es columna** — explícitamente derivado. Si en el futuro el modelo `Payment` gana estados intermedios (`processing`, `failed`, `refunded`), este derivador es el único punto donde la lógica vive. No agregar una columna `shipments.payment_state` "para query convenience" — denormalización innecesaria (ver `feedback_no_denormalized_role_flags`).

**`available_actions` viaja desde el BE** — patrón "server-rendered button visibility". Razón: la lógica de qué acción se permite depende de **(a)** el estado del FSM, **(b)** el estado de pago derivado, **(c)** el rol del usuario, **(d)** invariantes ADR-012. Cualquiera de esos puede cambiar; replicarlos en el frontend duplica reglas que se desincronizarán. El frontend solo *traduce* las strings a botones + i18n + endpoint POST.

**Soft-delete (ADR-009)** — `Shipment` ya tiene `discarded_at`; los listados heredan el `default_scope` y no devuelven envíos descartados. El detalle también respeta el default scope: si un envío se descarta, el ID retorna 404. Esto es deliberado — no exponer envíos descartados a la contraparte.

## Related

- **US fuente:** US17 (`docs/artifacts/backlog-us.typ:295-326`), US39 (`docs/artifacts/backlog-us.typ:364-396`).
- **Dependencia BE upstream:** [[REQ-BE-00022]] (modelos Fulfilment, mergeado) — define `Shipment`, `TrackingEvent`, FSM, soft-delete.
- **Dependencia BE lateral:** [[REQ-BE-00033]] (US8 pago, Brian, Ready) — define `Payment` y sus estados. El derivador `payment_state` consume ese estado; coordinar cuando aterrice el modelo final.
- **Consumidores FE:** [[REQ-FE-00022]] (US17 Carrier), [[REQ-FE-00023]] (US17 Shipper), [[REQ-FE-00024]] (US39 detalle).
- **Modelos / archivos a tocar:**
  - `backend/app/controllers/api/carriers/shipments_controller.rb` (nuevo).
  - `backend/app/controllers/api/shippers/shipments_controller.rb` (nuevo).
  - `backend/app/controllers/api/shipments_controller.rb` (nuevo — solo `show`).
  - `backend/app/serializers/shipment_list_serializer.rb`, `shipment_detail_serializer.rb` (nuevos).
  - `backend/app/policies/shipment_policy.rb` (extender con `Scope` y `show?`).
  - `backend/config/routes.rb` (rutas namespaced).
  - Migración: índice `tracking_events(shipment_id, created_at)` si no existe.
- **Política:** [`CLAUDE.md`](../../../CLAUDE.md) — DB SQLite forever, language policy, no denormalized flags.

## Notas de implementación para el assignee

- **PR title format** — conventional prefix obligatorio (`feat(fulfilment): ...`), sin `[REQ-BE-00035]` bracket. TAG va en body (`Closes #N`) y nombre de rama (`feature/REQ-BE-00035-...`).
- **`gh pr create --assignee @me`**.
- **No tocar `.gdsi-sdlc/config.json`.**
- **Coordinar con Brian** sobre el modelo `Payment` — el shape final del estado `escrowed` y la columna `captured_at` deben estar alineados con `REQ-BE-00033` antes de freezear el serializer del detalle. Si Brian aún no lo aterrizó, el serializer puede arrancar con `payment_state` derivado de "existe registro `Payment`" y refinarse cuando aterrice.
- **Pre-PR gate** (CLAUDE.md): `just backend-test` + `just lint`. Sin cambios FE, no aplica el bloque `/critique` → `/polish` → `/audit`.

## Acceptance Criteria

> AC1–AC10 son los contratos de los tres endpoints. AC11–AC13 son las garantías cross-cutting.

- [ ] **AC1** — `GET /api/carriers/me/shipments` devuelve `200` con `{ shipments: [...] }` para Carriers autenticados; `401` sin JWT; `403` si el JWT es de un usuario sin rol Carrier.
- [ ] **AC2** — `GET /api/shippers/me/shipments` espejo simétrico de AC1 para Shippers.
- [ ] **AC3** — Cada fila del listado incluye: `id`, `state`, `payment_state` (omitido si `state == "cancelled"`), `origin`, `destination`, `created_at`, `amount_cents`, `amount_currency`, `latest_activity_at`.
- [ ] **AC4** — `payment_state` se deriva en el serializer (no es columna). Vale `"paid"` si existe `Payment` en `escrowed` para el envío; `"pending"` en caso contrario.
- [ ] **AC5** — Orden por defecto del listado: `latest_activity_at DESC` calculado como `COALESCE(MAX(tracking_events.created_at), shipments.updated_at)`.
- [ ] **AC6** — `GET /api/shipments/:id` devuelve `200` con `{ shipment: { ... } }` si el usuario autenticado es contraparte del envío (Carrier dueño del Vehicle o Shipper dueño del Cargo). Devuelve `404` en cualquier otro caso (incluido id inexistente, contraparte equivocada, envío descartado).
- [ ] **AC7** — El payload del detalle incluye: `id`, `state`, `payment_state`, `created_at`, `amount_cents`, `amount_currency`, `cargo` (id, origin, destination, description, weight_kg), `vehicle` (id, plate, kind), `counterparty` (kind ∈ `{carrier, shipper}`, id, display_name — siempre la contraparte de quien consulta), `payment` (id, state, amount_cents, amount_currency, captured_at — o omitido si no existe / cancelled), `tracking_events` (ordenados ascendentemente), `available_actions`.
- [ ] **AC8** — `available_actions` viene del backend siguiendo las reglas tabuladas arriba. El frontend NO recalcula la disponibilidad de los botones.
- [ ] **AC9** — Sin paginación / filtros / búsqueda en este issue. Set completo en una respuesta. Si el set crece y duele, se triagea aparte.
- [ ] **AC10** — Todos los listados y el detalle respetan el `default_scope` de soft-delete: envíos descartados no aparecen en listados ni son accesibles vía show (404).
- [ ] **AC11** — Sin N+1: cada uno de los tres endpoints emite a lo sumo 1 query principal + eager loads. Verificar con `Bullet` / specs con count de queries.
- [ ] **AC12** — Mensajes de error y respuestas pasan por claves i18n. Sin literales hardcodeados en controllers ni en serializers.
- [ ] **AC13** — Todas las rutas y JSON keys en inglés. Sin Spanish en código (CLAUDE.md language policy).

### Tests requeridos

- [ ] RSpec — listado carrier: 401 sin JWT, 403 con JWT no-carrier, 200 con datos esperados, orden por `latest_activity_at`.
- [ ] RSpec — listado shipper: simétrico.
- [ ] RSpec — `payment_state` correcto en ambos casos (pendiente y paid); omitido si el envío está cancelled.
- [ ] RSpec — show: 401 sin JWT, 404 con id inexistente, 404 con JWT de no-contraparte, 200 con JWT de carrier dueño, 200 con JWT de shipper dueño.
- [ ] RSpec — show: `counterparty.kind` es shipper cuando consulta el carrier y viceversa.
- [ ] RSpec — show: `available_actions` retorna el set correcto para los 6 combos (carrier accepted+paid → `start_transit`; carrier in_transit → `deliver`; shipper accepted+pending → `pay, cancel`; shipper accepted+paid → `[]`; estado delivered → `[]`; estado cancelled → `[]`).
- [ ] RSpec — soft-delete: envíos descartados no aparecen en listados ni en show (404).
- [ ] RSpec — query count: listado emite ≤ 3 queries totales (1 principal + eager_load consolidado + agregación de tracking_events).

## Decisiones cerradas en triage (2026-05-24)

1. ~~**Endpoint multi-rol vs split**~~ — **split**: dos endpoints de listado (`/api/carriers/me/shipments`, `/api/shippers/me/shipments`) en lugar de un único `/api/shipments` multi-rol. Razón: claridad de logs + simplicidad de Pundit scope.
2. ~~**Detalle multi-rol vs split**~~ — **multi-rol con 404**: un único `GET /api/shipments/:id`. La autorización vive en Pundit; los no-contraparte reciben 404 (no 403) para no filtrar existencia.
3. ~~**`available_actions` en BE vs FE**~~ — **BE**. El backend es la fuente única de verdad sobre qué transiciones están permitidas en el estado actual + rol + invariantes.
4. ~~**`payment_state` columna vs derivado**~~ — **derivado**. No agregar columna a `shipments`.
5. ~~**Paginación / filtros / búsqueda**~~ — **fuera de alcance** en este sprint (US17 entrega el listado plano explícitamente).
6. ~~**Mapa de recorrido en detalle**~~ — **fuera de alcance** (`tracking_events` lista plana; el mapa lo entrega la US "marcar Recorrido" de Tomás).
