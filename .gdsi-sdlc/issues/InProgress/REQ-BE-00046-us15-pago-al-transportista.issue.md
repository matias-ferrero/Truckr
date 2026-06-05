---
tag: REQ-BE-00046
title: US15 — Pago al Transportista
priority: P1
status: ready
created: '2026-06-05'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/318
author: Claude Code
github_issue: 318
github_repo: tcorzo/fiuba-gestion-tp
labels:
- BE
- FE
- REQ
- P1
- fulfilment
- carrier
- payments
- notifications
- mvp
- us15
sprint: 5
plan: .claude/plans/starry-crafting-pike.md
---

## Summary

Cierre del ciclo financiero del MVP. Cuando el Transportista confirma la entrega de un
envío (`POST /api/shipments/:id/deliver`, US19), la plataforma libera automáticamente
los fondos del escrow al Carrier, reteniendo una **comisión del 15%**.

A diferencia de US8 (que procesa un pago externo entrante del Expedidor vía gateway),
US15 es contabilidad interna: el dinero ya está en el `Payment.escrowed` creado por US8.
No se necesita gateway — `Payouts::Create` lee el `Payment.escrowed` real, calcula la
comisión, y registra el payout con el desglose completo.

**Desglose del pago:**

| Concepto | Fórmula | Ejemplo |
|---|---|---|
| Monto bruto | `Payment.escrowed.amount_cents` | $ 12.500 ARS |
| Comisión plataforma (15%) | `ceil(gross × 0.15)` | − $ 1.875 ARS |
| **Monto acreditado al Carrier** | `gross − commission` | **$ 10.625 ARS** |

El Transportista recibe una notificación en tiempo real al confirmar la entrega y puede
consultar el historial de pagos en `/carrier/payouts` y en el detalle de cada envío.

## User story (fuente)

`docs/artifacts/backlog-us/US015.typ`:

> **US15 — Pago al Transportista.** Como transportista, quiero recibir el pago por los
> envíos concretados, para cobrar por mi servicio de forma segura y en tiempo.

## Acceptance Criteria

### AC1 — Sin gateway: los fondos provienen del escrow

- [ ] `Payouts::Create` obtiene el monto bruto de `shipment.payments.where(state: "escrowed").first.amount_cents`.
- [ ] La tasa de comisión es `PLATFORM_COMMISSION_RATE = BigDecimal("0.15")`, constante en `Payouts::Create`.
- [ ] El payout row registra `gross_amount_cents`, `commission_rate`, `commission_cents`, y `amount_cents` (neto).
- [ ] El `payment_id` del escrow queda referenciado en el payout como FK auditora.

### AC2 — Pago disparado al confirmar entrega

- [ ] `POST /api/shipments/:id/deliver` transiciona el shipment a `delivered` y, como side-effect,
  llama a `Payouts::Create.call(shipment:)` en el mismo request.
- [ ] `Payouts::Create` es race-safe via `shipment.with_lock`; dos requests concurrentes producen
  exactamente un row `paid`.
- [ ] Si no existe un `Payment.escrowed` para el shipment, levanta `ConflictError(:no_escrowed_payment)`;
  surfacea como 500 (es error de programador, no de usuario).
- [ ] Si ya existe un payout `paid`, levanta `ConflictError(:already_paid)` → 500.
- [ ] `POST .../deliver` retorna 409 si el shipment no está en `in_transit` (FSM previo — sin regresión).

### AC3 — Transportista ve el desglose de cada pago

**En el detalle del envío (`GET /api/shipments/:id`):**
- [ ] La respuesta incluye `payout: { id, state, gross_amount_cents, commission_rate, commission_cents, amount_cents, currency, paid_at }` cuando el viewer es Carrier y existe payout.
- [ ] `payout: null` si no hay payout aún o si el viewer es Shipper.
- [ ] El FE renderiza la sección "Liquidación del envío" con los tres valores (bruto, comisión, neto) y el chip de estado.

**En el listado (`GET /api/carriers/me/payouts`):**
- [ ] Endpoint protegido: 401 sin auth, 403 sin rol Carrier.
- [ ] Solo devuelve payouts del Carrier autenticado.
- [ ] Cada row incluye: desglose completo + `origin`, `destination`, `shipper_name`.
- [ ] El FE expone `/carrier/payouts` ("Mis Pagos") desde el nav del Carrier.
- [ ] Cada fila muestra: `origin → destination`, Expedidor, bruto, comisión, neto, estado, fecha, link al envío.
- [ ] Empty state: "Todavía no recibiste pagos. Aparecerán aquí cuando entregues un envío."

### AC4 — Notificación al Transportista

- [ ] Tras el payout `paid`, se emite `PAYOUT_APPROVED` al Carrier vía `Notifications::Publisher`
  con payload `{ shipment_id, gross_amount_cents, commission_cents, amount_cents, currency }`.
- [ ] `PAYOUT_APPROVED` y `PAYOUT_FAILED` registrados en `Notifications::Type::ALL` (BE)
  y en `NotificationType` (FE).
- [ ] Toast "Pago acreditado — Se transfirió el pago por tu envío." aparece en tiempo real
  al confirmar la entrega (canal ActionCable ya en uso desde US57/US58).

### ACs de implementación

- [ ] Sin literales en español en código Ruby ni JSX; todo vía `I18n.t()` o content file.
- [ ] Rutas, columnas, JSON keys en inglés (`/api/carriers/me/payouts`, `gross_amount_cents`, etc.).
- [ ] `spec/models/payout_spec.rb`: validaciones, inmutabilidad, factory `:paid` + `:failed`.
- [ ] `spec/services/payouts/create_spec.rb`: happy path con cálculo de comisión correcto, guards, notificación, race-safety.
- [ ] `spec/controllers/api/shipments/transitions_controller_spec.rb`: `deliver` crea Payout; 403/409 no crean Payout.
- [ ] `spec/controllers/api/carriers/me/payouts_controller_spec.rb`: scoping, 401, desglose en response.
- [ ] `spec/resources/shipment_detail_resource_spec.rb`: campo `payout` para Carrier, ausente para Shipper.
- [ ] Tests de FE y E2E cubriendo desglose de comisión visible (ver plan).
- [ ] `just backend-test` + `just frontend-test-coverage` (≥ 80%) + `just frontend-test-e2e` + `just lint` verdes.
- [ ] Pre-PR UI gate completo sobre `CarrierPayoutsPage` y la sección "Liquidación del envío"
  en `ShipmentDetailPage`, en este orden:
  `/critique` → `/layout` → `/typeset` → `/colorize` → `/bolder` → `/animate` → `/delight` → `/polish` → `/audit`.
  Findings bloqueantes (`/critique`, `/audit`) resueltos; findings de mejora anotados en el PR si son intencionales.

## API contract

### `POST /api/shipments/:id/deliver` (extensión de US19)

Sin cambio de contrato externo. Side-effect agregado: `Payouts::Create.call(shipment:)`.

### `GET /api/carriers/me/payouts` — Response 200

```json
[
  {
    "id": 1,
    "shipment_id": 42,
    "gross_amount_cents": 1250000,
    "commission_rate": "0.15",
    "commission_cents": 187500,
    "amount_cents": 1062500,
    "currency": "ARS",
    "state": "paid",
    "paid_at": "2026-06-05T14:32:00.000Z",
    "created_at": "2026-06-05T14:32:00.000Z",
    "origin": "Rosario, Santa Fe",
    "destination": "Buenos Aires, CABA",
    "shipper_name": "Agro Exportaciones SRL"
  }
]
```

### `GET /api/shipments/:id` — campo `payout` (solo Carrier)

```json
{
  "payout": {
    "id": 1,
    "state": "paid",
    "gross_amount_cents": 1250000,
    "commission_rate": "0.15",
    "commission_cents": 187500,
    "amount_cents": 1062500,
    "currency": "ARS",
    "paid_at": "2026-06-05T14:32:00.000Z"
  }
}
```

## Domain model

### Tabla `payouts` (nueva)

| Columna | Tipo | Null | Default | Notas |
|---|---|---|---|---|
| `payment_id` | integer FK | no | — | `→ payments.id` (fuente del escrow) |
| `shipment_id` | integer FK | no | — | `→ shipments.id` |
| `gross_amount_cents` | integer | no | — | Lo que pagó el Expedidor |
| `commission_rate` | decimal(5,4) | no | — | `0.1500` en MVP |
| `commission_cents` | integer | no | — | Retención de plataforma |
| `amount_cents` | integer | no | — | Neto al Carrier (`gross − commission`) |
| `currency` | string | no | `"ARS"` | — |
| `state` | string | no | — | `paid` \| `failed` (born-terminal) |
| `paid_at` | datetime | sí | — | — |
| `failed_at` | datetime | sí | — | — |
| `failure_reason` | string | sí | — | — |
| `discarded_at` | datetime | sí | — | Soft-delete (discard gem, ADR-009) |

Índice: `(shipment_id, state)`.

## Frontend integration

**3 puntos de entrada para el Carrier:**

1. **`/carrier/shipments/:id` (detalle de envío)** — sección "Liquidación del envío" con
   los tres montos (bruto, comisión, neto) + chip de estado. Se muestra al Carrier en el
   mismo detalle que ya usa para ver el estado del envío. Sin navegación extra.

2. **`/carrier/payouts` ("Mis Pagos")** — historial completo de cobros. Accesible desde
   el nav del Carrier junto a "Mis Envíos". Cada fila muestra el desglose + ruta + expedidor.

3. **Toast de notificación** — aparece automáticamente al confirmar la entrega ("Confirmar
   entrega" → backend transiciona + crea payout → emite por ActionCable → toast "Pago
   acreditado" en pantalla).

## i18n

**Backend** — claves nuevas en `config/locales/{en,es}.yml`:
- `errors.payouts.shipment_not_delivered`
- `errors.payouts.already_paid`
- `errors.payouts.no_escrowed_payment`

**Frontend** — copy en `carrierPayoutsContent.ts` y `shipmentDetailContent.ts`
(sección liquidación). Notificaciones en `landingContent.ts`.

## Out of scope

- Integración real con Mercado Pago. Los fondos están en el `Payment.escrowed`; la
  transferencia real al CBU/CVU del Carrier es post-MVP.
- Tasa de comisión variable o configurable por usuario. En MVP es 15% fijo.
- Comprobante / factura electrónica.
- Payout visible para el Shipper.
- Reembolso o reversión de payout.

## Related

- **US fuente**: US15 (`docs/artifacts/backlog-us/US015.typ`).
- **Construye sobre**: REQ-BE-00033 (US8 — crea el `Payment.escrowed` que US15 consume);
  REQ-BE-00038 (US18+US19 — endpoint `deliver` que US15 extiende).
- **Notificaciones**: canal ActionCable activo desde Sprint 3 (US57/US58).
- **Sprint 5 plan**: `docs/features/SPRINT-5-PLAN.md` — US15, Franco, prioridad Alta.
- **Glosario**: `docs/05-appendices/glossary.md`.
- **ADR-012** — Payment FSM born-terminal; patrón replicado en Payout.
- **DB policy**: SQLite forever. Race-safety via `with_lock`.

## Implementation notes (pre-PR)

- **Branch**: `feature/REQ-BE-00046-us15-pago-al-transportista`.
- **PR title**: `feat(fulfilment): US15 — Carrier payout on delivery`. TAG en body (`Closes #N`).
- **Assignee**: `@FrancoRicciardo`.
- **Plan detallado** (15 pasos, contrato, tests, archivos): `.claude/plans/starry-crafting-pike.md`.
- Secuencia: BE (migración → modelo → servicio → wire → endpoint) → FE (tipos → notificaciones
  → página → detail → ruta) → tests → UI gate.
