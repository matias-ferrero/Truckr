# REQ-FE-00024: Detalles de Envío (US39 — pantalla compartida con acciones contextuales por rol)

| Field | Value |
|-------|-------|
| **Tag** | REQ-FE-00024 |
| **Title** | Detalles de Envío — pantalla compartida Carrier/Shipper |
| **Priority** | P1 |
| **Status** | READY |
| **Sprint** | 3 |
| **Author** | Claude Code |
| **Owner** | @tcorzo |
| **Depends On** | **Hard:** [[REQ-BE-00035]] (`GET /api/shipments/:id` con `available_actions`). **Soft (consume si están):** [[REQ-BE-00033]] (POST payments), [[REQ-BE-00038]] (POST start_transit / deliver). |
| **Decision Doc** | N/A — decisiones canónicas en este plan, AC en el issue. |
| **Selected Approach** | Un único componente `ShipmentDetailPage` montado en **dos rutas inglesas** (`/carrier/shipments/:id` y `/shipper/shipments/:id`). Botonera renderizada por iteración sobre `available_actions` (safe-by-delegation: backend gobierna visibilidad). Enum canónico de `available_actions` propiedad de REQ-BE-00035 §4.4: `start_transit \| deliver \| pay \| cancel`. UI labels compuestas («A recoger», «Pendiente de pago») se derivan en el FE a partir de `Shipment.state` + payment status — son composiciones de UI, NO estados del FSM. Refresh = refetch `GET /api/shipments/:id` post-mutación. |

---

## 1. Decisiones canónicas (LOCKED)

Estas decisiones están cerradas — no se reabren en implementación. Fuentes:

1. **Issue [REQ-FE-00024]** (`.gdsi-sdlc/issues/Ready/REQ-FE-00024-us39-detalles-de-envio.issue.md`) — Problem Statement + AC.
2. **Glossary** (`docs/05-appendices/glossary.md:25`, entrada **Envío**) — canon de las composiciones de UI:
   - **"A recoger"** es UI: `Shipment.state == accepted` y el transportista todavía no inició el transporte.
   - **"Pendiente de pago"** es UI: para el Expedidor sobre un envío `accepted` sin `Payment.escrowed`.
   - **NO** son estados del FSM. El frontend NO los envía al backend, NO los pide al backend; los compone localmente.
3. **ADR-012** (`docs/01-technical-vision/technical-vision.md:152`, enmienda 2026-05-24) — FSM canónico:
   - `Shipment`: `accepted → in_transit → delivered` (+ `cancelled` desde `accepted` solo si no hay `Payment.escrowed`). Sin `pending`, sin `settled`.
   - `Payment`: filas nacen terminales (`escrowed` o `failed`). El retry es una nueva fila (POST nuevo), nunca una transición.
4. **Contratos cross-issue (cerrados, no negociables):**
   - **[REQ-BE-00035]** — `GET /api/shipments/:id` retorna el recurso `Shipment` con `available_actions: string[]`. El FE confía en esta lista como única fuente de verdad para visibilidad de botones (safe-by-delegation).
   - **[REQ-BE-00038]** — `POST /api/shipments/:id/start_transit` y `POST /api/shipments/:id/deliver`. Autorización + transiciones FSM las hace el server; el FE solo dispara la llamada.
   - **[REQ-BE-00033]** — `POST /api/shipments/:id/payments`. Retry semantics: el FE reintenta reissue-ando el POST (cada intento es una `Payment` row nueva nacida terminal).

**Carve-out de scope:** la cancelación post-pago **no existe** (ADR-012). La cancelación pre-pago (`accepted` sin `escrowed`) está diferida a Sprint 4+ (decisión Q3 del triage 2026-05-24). El backend simplemente omite `"cancel"` de `available_actions`, así que el botón no se renderiza nunca en este sprint — sin código muerto, sin feature-flag.

## 2. Estructura de rutas y composición

**Decisión FE elegida (de convención existente):** se montan **dos rutas inglesas** que apuntan al **mismo componente** `ShipmentDetailPage`. El componente recibe el rol activo desde el contexto de auth (o como prop derivada del prefijo de ruta), y lo usa para resolver:

- URL de "volver al listado" (`/carrier/shipments` vs `/shipper/shipments`).
- Label de contraparte (i18n key `shipment.detail.counterparty.carrier` vs `.shipper`).
- Default-route guard: usuario sin el rol correspondiente → redirect a su dashboard con toast i18n.

| Ruta FE (inglés) | Rol esperado | Guard |
|---|---|---|
| `/carrier/shipments/:id` | `Carrier` | redirige no-Carrier al dashboard |
| `/shipper/shipments/:id` | `Shipper` | redirige no-Shipper al dashboard |

**Por qué un solo componente:** el 90% del DOM es idéntico (datos del envío, chips, timeline). La única ramificación real es (a) la URL de back y (b) qué label tiene la contraparte — el backend ya emite `available_actions` y `counterparty` resueltos por rol. Mantener dos componentes paralelos sería overhead puro.

Archivos:

- `frontend/src/pages/shipments/ShipmentDetailPage.tsx` — nuevo, multi-rol.
- `frontend/src/components/shipments/TrackingEventTimeline.tsx` — nuevo.
- `frontend/src/components/shipments/ShipmentActions.tsx` — nuevo. Mapea `available_actions[]` → botones.
- `frontend/src/hooks/useShipmentDetail.ts` — nuevo. Wrappea `GET /api/shipments/:id` + refetch + estado.
- Entradas i18n bajo `shipment.detail.*` (en el `*Content.ts` correspondiente — el repo todavía no tiene librería i18n real; se sigue la convención prototype-stage de archivos `*Content.ts`).

## 3. Layout (bloques verticales)

En orden vertical, top-to-bottom:

1. **Header**
   - Breadcrumb / link "← Volver a Mis Envíos" → `/carrier/shipments` o `/shipper/shipments` según rol.
   - Título: `t('shipment.detail.title', { id })`.
   - **Chip de estado** (`ShipmentStateChip` reusado de US17). El chip muestra el estado del FSM (`accepted` / `in_transit` / `delivered` / `cancelled`).
   - **Etiqueta UI compuesta** (NO es chip del FSM, ver §1.2 glossary):
     - "A recoger" si `state == accepted` y aún no inició transporte (Carrier-view).
     - "Pendiente de pago" si rol == Shipper, `state == accepted` y no hay `Payment.escrowed`.
     - Renderizada como sub-label visual junto al chip principal, no como chip duplicado.
   - **Chip de pago** (`PaymentStateChip`) — oculto si `state == cancelled`.

2. **Cuerpo — datos del envío** (bloque tabulado, key/value, semántica `<dl>`):
   - Origen / destino (texto + lat/lng truncado a 6 decimales).
   - Descripción y peso de la carga (kg, formato es-AR).
   - Vehículo asignado: placa + tipo (`vehicle.kind.*`).
   - Contraparte: nombre + label de rol según consulta (`shipment.detail.counterparty.carrier` o `.shipper`).
   - Fecha de creación (es-AR, `dd/MM/yyyy HH:mm`).
   - Monto acordado (es-AR, ARS).

3. **Sección de recorrido** — placeholder anclado con `<section id="shipment-tracking-map">`. Copy: `t('shipment.detail.tracking.placeholder')`. Reemplazado por [[REQ-FE-00028]] (US51, Sprint 4) sin tocar el resto del componente.

4. **Timeline de TrackingEvent** — lista vertical (`TrackingEventTimeline`), un item por evento. Si el array está vacío, omitir la sección entera (no mostrar "sin eventos").

5. **Sidebar / footer de acciones** — bloque `ShipmentActions` derivado de `available_actions` (ver §4). Si `available_actions == []` la sección no se renderiza.

## 4. Available actions — contrato de renderizado

**Safe-by-delegation.** El FE itera `available_actions` y renderiza un botón por cada entry. Sin lógica local de elegibilidad. Sin recalcular el FSM. Si el backend dice `[]`, no hay botones — punto.

**Mapping action → label → endpoint → confirmación:**

El enum canónico de `available_actions` es **propiedad de REQ-BE-00035 §4.4** y se compone exactamente de cuatro strings estables: `start_transit | deliver | pay | cancel`. El FE NO inventa otros entries ni mappea aliases — si el backend no lo emite, el botón no existe.

| `available_actions` entry | i18n label key | Endpoint disparado | Confirmación |
|---|---|---|---|
| `start_transit` | `shipment.detail.actions.start_transit` ("Iniciar transporte") | `POST /api/shipments/:id/start_transit` (REQ-BE-00038) | Modal de confirmación. |
| `deliver` | `shipment.detail.actions.deliver` ("Confirmar entrega") | `POST /api/shipments/:id/deliver` (REQ-BE-00038) | Modal. |
| `pay` | `shipment.detail.actions.pay` ("Pagar") — o `.retry_payment` ("Reintentar pago") si el payload trae un `Payment.failed` previo (label-only switch; el action enum sigue siendo `pay`) | `POST /api/shipments/:id/payments` (REQ-BE-00033). Retry = mismo POST otra vez (nueva fila terminal). | Sin modal — el wizard de pago tiene su propio gating. |
| `cancel` | `shipment.detail.actions.cancel` ("Cancelar envío") | Endpoint diferido a Sprint 4+ (Q3 triage 2026-05-24). El backend NO emite `cancel` en `available_actions` en Sprint 3, así que el botón no se renderiza nunca este sprint — código listo para activarse sin cambios cuando el backend lo agregue. | Modal con copy fuerte ("Esta acción no se puede deshacer"). |

**Reglas de label compuesta (UI derivation, no del backend):**

- **"A recoger"** se muestra en el header (sub-label) cuando `shipment.state == "accepted"` y `payment_state == "escrowed"` (equivalentemente, para el Carrier, cuando `available_actions` incluye `start_transit`). Es visible para **ambos roles** — al Shipper le confirma que su pago surtió efecto y el envío está listo para ser retirado; al Carrier le sirve de pista visual de fulfilment. Derivación pura UI, no se envía ni se pide al backend. Anclado en `docs/05-appendices/glossary.md:25` (rol-agnóstico) y en US8 AC.2.
- **"Pendiente de pago"** se muestra al Shipper cuando `shipment.state == "accepted"` y no hay `Payment.escrowed` (derivable del `payment_state` del payload o de la presencia de `pay` en `available_actions`). Es UI label, no estado.

**Variantes visuales del design system:**

- Acciones constructivas (`start_transit`, `deliver`, `pay`) → variante primary.
- Acciones destructivas (`cancel`, cuando aterrice) → variante danger con copy fuerte. Hoy no se renderiza ninguna.

**Modales de confirmación:** reusar el patrón de `QuoteInboxPage` (PR #194) y del modal de baja de vehículo de [[REQ-BE-00034]]. No reinventar.

## 5. Refresh / state freshness

Después de cualquier mutación con éxito (status 2xx del POST):

1. Refetch `GET /api/shipments/:id`.
2. El re-render actualiza chips, timeline, etiqueta UI compuesta, y `available_actions` (la botonera se rerenderiza automáticamente, posiblemente vaciándose si el envío llegó a `delivered`).
3. **Optimistic update:** **no**. La autoridad es el backend; el round-trip es barato y la combinatoria de estados es sensible (un optimistic mal hecho mostraría botones inválidos por unos ms — peor UX que el spinner).
4. Emitir evento global `truckr:shipment-updated` para que el listado (US17) lo reciba si está montado.

En caso de error de mutación: mostrar toast con `t('shipment.detail.actions.error.<action>')`, **no** refetchear (el estado del server no cambió).

## 6. Estados visibles (matriz)

Matriz Shipment.state × payment status × rol → UI mostrada. (Solo combinaciones reales del FSM ADR-012; sin `pending`, sin `settled`.)

| Shipment.state | Payment | Rol | Chip principal | Etiqueta UI compuesta | `available_actions` típicas | Botones renderizados |
|---|---|---|---|---|---|---|
| `accepted` | (sin pago) | Shipper | "Aceptado" | "Pendiente de pago" | `["pay"]` | "Pagar" |
| `accepted` | `failed` | Shipper | "Aceptado" | "Pendiente de pago" | `["pay"]` | "Reintentar pago" (label-only switch por `payment_state == failed`) |
| `accepted` | `escrowed` | Shipper | "Aceptado" | "A recoger" | `[]` | (ninguno) |
| `accepted` | `escrowed` | Carrier | "Aceptado" | "A recoger" | `["start_transit"]` | "Iniciar transporte" |
| `in_transit` | `escrowed` | Carrier | "En tránsito" | — | `["deliver"]` | "Confirmar entrega" |
| `in_transit` | `escrowed` | Shipper | "En tránsito" | — | `[]` | (ninguno) |
| `delivered` | `escrowed` | ambos | "Entregado" | — | `[]` | (ninguno) |
| `cancelled` | (cualquiera) | ambos | "Cancelado" | — (chip de pago oculto) | `[]` | (ninguno) |

Estados auxiliares de carga/error:

- **Loading**: skeleton sobre el bloque principal mientras la primera request está en vuelo.
- **404**: pantalla específica "Envío no encontrado" + CTA al listado. El backend consolida "no existe" y "no sos contraparte" en 404 — el FE no discrimina.
- **Error ≠ 404**: mensaje + botón retry (rehace el GET).

## 7. i18n keys (propuestas)

Bajo el namespace `shipment.detail.*`. Valores en es-AR. Materializados en el `*Content.ts` correspondiente hasta que aterrice una librería i18n real.

```
shipment.detail.title                              → "Envío #{id}"
shipment.detail.back                               → "Volver a Mis Envíos"
shipment.detail.counterparty.carrier               → "Transportista"
shipment.detail.counterparty.shipper               → "Expedidor"
shipment.detail.composite.to_pick_up               → "A recoger"
shipment.detail.composite.pending_payment          → "Pendiente de pago"
shipment.detail.tracking.placeholder               → "Se mostrará el recorrido cuando esté disponible"
shipment.detail.actions.start_transit              → "Iniciar transporte"
shipment.detail.actions.deliver                    → "Confirmar entrega"
shipment.detail.actions.pay                        → "Pagar"
shipment.detail.actions.retry_payment              → "Reintentar pago"
shipment.detail.actions.cancel                     → "Cancelar envío"
shipment.detail.actions.confirm.title              → "¿Confirmás la acción?"
shipment.detail.actions.error.generic              → "No pudimos completar la acción. Intentá de nuevo."
shipment.detail.notfound.title                     → "Envío no encontrado"
shipment.detail.notfound.cta                       → "Volver al listado"
shipment.detail.error.retry                        → "Reintentar"
```

**Política recordatoria:** ningún literal español en JSX. Todo via clave.

## 8. Tests

### Vitest (component)

- Render con cada combinación de `available_actions` de la matriz §6 (incluyendo `[]`).
- Chip de pago oculto cuando `state == cancelled`.
- Etiqueta compuesta "A recoger" visible solo en el caso (carrier, accepted, escrowed, available_actions incluye `start_transit`).
- Etiqueta compuesta "Pendiente de pago" visible solo en el caso (shipper, accepted, sin `Payment.escrowed`).
- Label del botón de pago alterna "Pagar" / "Reintentar pago" según `payment_state` (`null`/`failed`) — pero el action enum es siempre `pay`.
- Bloque contraparte muestra el label correcto según rol.
- Timeline omitido si la lista está vacía; ordenado si hay eventos.
- Modal de confirmación visible para `start_transit`, `deliver`; ausente para `pay`.
- Post-acción exitosa: refetch del detalle + evento `truckr:shipment-updated` emitido.
- Pantalla 404 cuando el backend responde 404.
- Pantalla de error con retry cuando responde ≠ 404/200.

### Playwright (e2e, chromium)

- **Golden path Carrier**: envío `accepted+escrowed` → abre detalle, dispara `start_transit` → chip cambia a "En tránsito" → dispara `deliver` → chip cambia a "Entregado", botonera vacía.
- **Golden path Shipper**: envío `accepted` sin pago → abre detalle, ve "Pendiente de pago" + botón "Pagar" → completa pago → label compuesta desaparece, botón desaparece.
- **404**: usuario no-contraparte abre `/carrier/shipments/:id` por URL directa → pantalla 404 + CTA.

**Cobertura mínima:** 80% líneas/funciones/ramas/sentencias (configurado en `frontend/vitest.config.ts`).

## 9. Out of scope (Sprint 3)

- **Botón "Cancelar envío"** — el backend no emite `"cancel"` en `available_actions` en Sprint 3 (decisión Q3 triage 2026-05-24). Cuando aterrice en Sprint 4+, el componente lo renderiza automáticamente sin cambios (safe-by-delegation): la entrada del enum canónico `cancel` ya está mappeada a `shipment.detail.actions.cancel` + modal con copy "Esta acción no se puede deshacer".
- **Mapa visual del recorrido** — sección reservada con copy placeholder. Reemplazada por [[REQ-FE-00028]] (US51, Sprint 4).
- **Cancelación post-pago** — no existe (ADR-012, interlock cancelación-vs-escrow).
- **Optimistic UI updates** — explícitamente diferido. Round-trip authoritative refetch.

## 10. Related

- **US fuente:** US39 en `docs/artifacts/backlog-us.typ`.
- **Glossary:** `docs/05-appendices/glossary.md:25` (canon de "A recoger" / "Pendiente de pago" como composiciones de UI).
- **ADR:** [`docs/01-technical-vision/technical-vision.md`](../../../01-technical-vision/technical-vision.md), ADR-012 (FSM Payment + Shipment, enmienda 2026-05-24).
- **Contratos BE consumidos:**
  - [[REQ-BE-00035]] — `GET /api/shipments/:id` con `available_actions`. Bloquea este issue.
  - [[REQ-BE-00038]] — `POST /api/shipments/:id/{start_transit,deliver}`.
  - [[REQ-BE-00033]] — `POST /api/shipments/:id/payments` (retry = nueva fila).
- **Hermanos FE:** [[REQ-FE-00022]] / [[REQ-FE-00023]] (US17 listings, fuente de chips compartidos), [[REQ-FE-00028]] (US51 mapa, Sprint 4).
- **Política:** [`CLAUDE.md`](../../../../CLAUDE.md) — language policy, pre-PR UI quality gate, design system.
