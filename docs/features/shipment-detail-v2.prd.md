# Shipment Detail v2 — design brief

Status: planning · 2026-06-09 · supersedes the vertical-stack layout of
`frontend/src/pages/shipments/ShipmentDetailPage.tsx`.

Companion to the shipper-dashboard-v2 work (PR #332). Same goal: move a
"vertically obsessed" single-column page to a role-aware 2D layout that surfaces
the **most valuable experience per role and per state**.

## Problem

Today the shipment detail page is a 10-section vertical stack, role-parameterized
but action-last: the Shipper's pay CTA is a buried banner, the Carrier's
state-transition buttons sit at the bottom inside the timeline, the payout block
is below the fold, and the route map is dead last. The page does not answer the
one question each role opens it to ask: **"what's my situation and what do I do
now?"**

## Most valuable experience, per role (research-grounded)

The decisive insight: value is almost entirely **state-driven**, and at any
moment one party holds *the* action while the other is waiting. Payment gates the
whole machine — a shipment cannot leave `accepted` until the Shipper escrows.

- **Shipper (sky):** `accepted`+unpaid → **pay/escrow** is THE action; paid →
  "where's my cargo?" (status + carrier contact, no ETA); `delivered` → **leave a
  review** + read carrier reputation.
- **Carrier (saffron):** `accepted`+unpaid → **blocked, waiting on payment**;
  paid → **Confirmar Retiro** + navigate to pickup; `in_transit` → **Confirmar
  Entrega** + navigate to delivery; `delivered` → **payout breakdown** + review.

## Locked decisions

### 1. Skeleton — sticky action rail + 2-column body
- Header band: title + `ShipmentStateChip` + `PaymentStateChip`.
- **Main column** (~2/3, scrolls): route map (top), facts card, event timeline.
- **Rail** (~1/3, `position: sticky`): primary action card + money block +
  contact card. Stays in view while the main column scrolls.
- Collapses to a single column under the dashboard's mobile breakpoint.

### 2. One shared component, divergence isolated to the rail (ADR-015)
- Keep a single `ShipmentDetailPage` (do **not** split per role like the
  dashboard did — same shipment viewed from two sides, ~70% shared spine).
- Refactor so **all role/state branching lives in the rail**: extract
  `<PrimaryActionCard role state payment />` and `<MoneyBlock role />`.
- The main column stays role-agnostic, with **one deliberate exception**: the
  map's primary nav button is role/state-aware (see §4).

### 3. Primary action card — never a dead button
Top of the rail. Always answers "situation + what can I do." When the role can't
act, it shows **reassuring status, not a greyed-out button.** Action buttons
render strictly off the backend's `available_actions: string[]` (safe by
delegation); waiting/status copy is derived FE-side from state + payment.

| Role | State / payment | Mode | Content |
|---|---|---|---|
| Shipper | `accepted`, unpaid | ACTION | "Reservá tu envío" → **Pagar ahora** |
| Shipper | `accepted`, payment `failed` | ACTION | "El pago no se procesó — reintentá" → **Reintentar pago** |
| Shipper | `accepted`, paid | WAITING | "Pago confirmado ✓ — esperando que el transportista retire la carga" |
| Shipper | `in_transit` | STATUS | "Tu carga está en camino" |
| Shipper | `delivered`, no review | ACTION | "¿Cómo fue tu experiencia?" → **Dejá tu reseña** |
| Shipper | `delivered`, reviewed | DONE | "¡Gracias por tu reseña!" |
| Carrier | `accepted`, unpaid / `failed` | WAITING | "Esperando el pago del expedidor para poder retirar" |
| Carrier | `accepted`, paid | ACTION | "Listo para retirar" → **Confirmar Retiro** |
| Carrier | `in_transit` | ACTION | "Carga en tránsito" → **Confirmar Entrega** |
| Carrier | `delivered` | MONEY+ACTION | payout breakdown (gross / 15% commission / net / paid_at) + **Dejá tu reseña** |

`cancelled` is deferred (Sprint 4+); no card mode designed for it yet.

### 4. State-aware navigation (the one role-aware exception in the main column)
Reuses `OpenInGmapsButton` + the Cargo's `pickup_*`/`delivery_*` coords. No new
data — state-driven emphasis only.
- Carrier `accepted`+paid → prominent **"Navegar al retiro"**, delivery demoted.
- Carrier `in_transit` → prominent **"Navegar a la entrega"**, pickup demoted.
- Carrier `delivered` → both demoted to plain "Ver ruta".
- Shipper, any state → single **"Ver ruta completa"** (origin→destination `dir`).

### 5. Review form — modal
Rail card "Dejá tu reseña" is the entry point; clicking opens a focused
`<dialog>` (reusing the existing pay-confirm dialog pattern) with stars +
1000-char comment. On submit the rail card flips to "¡Gracias por tu reseña!"
`ShipperReviewForm`/`CarrierReviewForm` differ only in copy.

### 6. Counterparty reputation — link-only, both sides
Rail contact card gets a deep-link to the counterparty's profile/reviews:
- Shipper side → **"Ver reputación del transportista →"** (US26 route).
- Carrier side → **"Ver reputación del expedidor →"** (symmetric).
Frontend-only; no backend coupling. Inline aggregate (★ 4.5 · N reseñas) is a
fast-follow *if* the detail payload later includes the rating summary.

## Non-goals (hard out-of-scope — do not reintroduce to "enrich" the layout)
1. ETA / countdown / "llega en Xh" — no ETA field exists in the data model.
2. Live GPS position / moving truck — US21 is Release 3 / post-MVP.
3. Progress bar / "% del viaje" — no position data to compute from.
4. Notification history / inbox — notifications are ephemeral WebSocket-only (ADR-013).
5. Proof of delivery (photo/signature) — no model field, in no spec.

The discrete event timeline (`accepted → in_transit → delivered`) is the only
honest progress representation and stays.

## Affected code
- `frontend/src/pages/shipments/ShipmentDetailPage.tsx` (restructure)
- `frontend/src/styles/shipment-detail.css` (rail + 2-col grid, sticky)
- `frontend/src/pages/shipments/shipmentDetailContent.ts` (new copy: waiting/status/done modes)
- New: `PrimaryActionCard`, `MoneyBlock` (rail components)
- Reuse: `ShipmentMap`, `OpenInGmapsButton`, `TrackingEventTimeline`,
  `ShipmentStateChip`, `PaymentStateChip`, `ShipmentActions`, review forms,
  `ui/button`, design tokens, `.dashCard`/sticky patterns from dashboard v2.
