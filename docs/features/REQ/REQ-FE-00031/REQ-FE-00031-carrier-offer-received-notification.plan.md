# REQ-FE-00031: Notificación en tiempo real al Transportista cuando un Expedidor le envía una oferta de carga

| Field | Value |
|-------|-------|
| **Tag** | REQ-FE-00031 |
| **Title** | Notificación en tiempo real al Transportista cuando un Expedidor le envía una oferta de carga |
| **Priority** | P2 |
| **Status** | READY |
| **Created** | 2026-06-03 |
| **Updated** | 2026-06-03 |
| **Author** | Claude Code |
| **Depends On** | INF-FE-00005 (notifications framework). Sibling: REQ-FE-00030 (shares 3 files — see §8 coordination) |
| **Decision Doc** | N/A — single clear approach (symmetric inverse of REQ-FE-00030, an already-built framework) |
| **Selected Approach** | N/A |
| **GitHub Issue** | [#306](https://github.com/tcorzo/fiuba-gestion-tp/issues/306) |

---

## 1. Problem Statement

When a **Shipper** creates a **`CargoOffer`** against a **Carrier's** `TransportWindow`, the Carrier gets no immediate in-app feedback. The only planned channel — `CargoOfferMailer.notify_carrier` — is a **stub** (`cargo_offer_mailer.rb:9-17`, "INF-BE-00005 pending"): it logs and renders a placeholder, no real email. So today the Carrier effectively **doesn't find out** unless they open `/api/carriers/me/cargo-offers?status=pending` and refresh. A realtime in-app toast would be, in practice, the **first real signal** the Carrier gets about a new offer.

This is the **symmetric inverse of [[REQ-FE-00030]]**: that issue notifies the Shipper when the Carrier *resolves* the offer; this one notifies the Carrier when the Shipper *creates* it. Together they cover the realtime offer↔resolution loop. It's the "oferta recibida" consumer listed in the [[INF-FE-00005]] plan.

**Scope guardrails.** No new domain logic — offer creation, the `window.lock!`, and the `TransportWindow → pending_offer` transition already exist and are tested. The notification is **additive** and **best-effort live** (ADR-013): no persistence, no new tables, nothing new in the DB (SQLite-portable). The durable email stays a stub until INF-BE-00005 wires it; this issue neither blocks nor replaces it.

**Domain direction (model comments are stale, same as REQ-FE-00030).** The **Shipper creates** the `CargoOffer` (`Api::CargoOffersController#create`, `require_shipper!`; body carries `cargo_id` + `transport_window_id`). The **Carrier is the recipient** — owner of the offered `TransportWindow` — and later accepts/rejects (which fires REQ-FE-00030 back to the Shipper).

---

## 2. Solution Design

Mirror the existing mailer enqueue site with a `Notifications::Publisher.publish` call. One trigger, one new type.

### Trigger (backend)

`Api::CargoOffersController#create` (`cargo_offers_controller.rb:54`) — the offer-creation transaction (which takes `window.lock!`) closes at line 52; the mailer is enqueued at line 54, **after commit**. Emit the notification at the same point → **AC4** (outside the transaction/lock) is satisfied for free.

**Recipient:** `cargo_offer.carrier.user_id`. `CargoOffer#carrier` is set in `set_defaults` (`self.carrier ||= transport_window&.carrier`); `carriers.user_id` is a column, so `cargo_offer.carrier.user_id` reads the FK after loading the carrier (≤1 extra query, no `User` row loaded). The window was loaded with `includes(vehicle: :carrier)`, so the carrier is typically already in memory.

### Best-effort dispatch (AC5)

A broadcast failure **must not** break the `201 Created`. The publisher's `publish` is **synchronous** and can raise (`User.find` → `RecordNotFound`, or a broadcast error), unlike the mailer's `deliver_later`. Wrap the post-commit dispatch (mailer + publish) in a `rescue StandardError` that logs and continues, then render 201.

> Bonus correctness: the mailer's own header comment already claims *"The controller calls `.deliver_later` inside a rescue block so the CargoOffer is created even if this raises"* — but line 54 is currently **bare, no rescue**. This change makes that comment finally accurate.

### New type (closed whitelist)

`Notifications::Type` (`type.rb`):
```ruby
CARGO_OFFER_RECEIVED = :cargo_offer_received
```
added to `ALL`. Frontend mirrors it in the `NotificationType` union. Publishing an unregistered type raises `Notifications::UnknownTypeError` — register first.

### Payload (English snake_case)

```json
{ "cargo_offer_id": 123, "cargo_id": 45, "transport_window_id": 9, "amount_cents": 1500000, "currency": "ARS" }
```
Enough for the toast and a future deep-link to the Carrier's pending-offers inbox. No Shipper PII beyond what the notice needs. Renderer must tolerate a missing optional field (see §5 harden).

### Behaviour (frontend)

- Register a renderer for `cargo_offer_received` in `notificationsRegistry.ts`, returning `{ title, body }` from the i18n bundle.
- Add copy to `landingContent.ts` under `notifications` (CLAUDE.md i18n carve-out; es-AR voseo to match existing entries). No JSX literals.
- Toast/badge appear via the existing `NotificationsProvider`/`NotificationsToast`/`NotificationsBadge` — **unchanged**. Unknown types stay ignored by `isKnownNotificationType()` (no framework regression).

### Key Components

- **`Notifications::Type`** — whitelist the new symbol.
- **`Api::CargoOffersController#create`** — best-effort post-commit publish next to the mailer.
- **`notificationsRegistry.ts`** — union + renderer.
- **`landingContent.ts`** — one i18n entry.

**Untouched:** `publisher.rb`, `NotificationsProvider/Toast/Badge`, `notificationsContent.ts`, DB/schema, the offer-creation transaction itself.

---

## 3. Implementation Tasks

| # | Task | Status | Files |
|---|------|--------|-------|
| 1 | Register `cargo_offer_received` in `Type::ALL` | Pending | `backend/app/services/notifications/type.rb` |
| 2 | Emit `cargo_offer_received` post-commit in `#create`, wrapped in best-effort `rescue` (mailer + publish) | Pending | `backend/app/controllers/api/cargo_offers_controller.rb` |
| 3 | Extend `NotificationType` union + add renderer | Pending | `frontend/src/components/notifications/notificationsRegistry.ts` |
| 4 | Add `notifications.cargo_offer_received` to interface + data | Pending | `frontend/src/landingContent.ts` |
| 5 | RSpec: create publishes `cargo_offer_received` to the window-owner Carrier's `user_id`; 201 still returned when the Publisher raises (best-effort); payload shape | Pending | `backend/spec/requests/api/cargo_offers_spec.rb` |
| 6 | Vitest: registry renders `{title,body}` for `cargo_offer_received`; missing optional field doesn't break the renderer | Pending | `frontend/src/components/notifications/notificationsRegistry.test.ts` |
| 7 | Playwright e2e: Carrier session open → broadcast real type via `POST /api/dev/notifications/broadcast` → toast appears | Pending | `frontend/e2e/notifications-cargo-offer-received.spec.ts` |
| 8 | UI gate (`/critique`→`/polish`→`/audit`) on toast/copy, then `just lint`, `frontend-test-coverage`, `frontend-test-e2e`, `backend-test` | Pending | — |

---

## 4. Code Changes

### 4.1 `backend/app/services/notifications/type.rb`

**Purpose:** Whitelist the new type. (If rebased after REQ-FE-00030, `ALL` will already carry `cargo_offer_accepted`/`rejected` — add `cargo_offer_received` alongside.)

```ruby
PING = :ping
CARGO_OFFER_RECEIVED = :cargo_offer_received
# (+ cargo_offer_accepted / cargo_offer_rejected from REQ-FE-00030 after rebase)

ALL = [ PING, CARGO_OFFER_RECEIVED ].freeze
```

### 4.2 `backend/app/controllers/api/cargo_offers_controller.rb`

**Purpose:** Best-effort post-commit dispatch — mailer + realtime notification — without risking the 201.

```ruby
      cargo_offer = nil
      ActiveRecord::Base.transaction do
        window.lock!
        # ... unchanged: status guard, CargoOffer.create!, window → pending_offer ...
      end

      notify_carrier_of_new_offer(cargo_offer)
      render json: CargoOfferResource.new(cargo_offer).serialize, status: :created
    end

    private

    # Best-effort, post-commit (AC4/AC5): a mailer or broadcast failure must not
    # break the 201 the Shipper already earned by creating the offer.
    def notify_carrier_of_new_offer(cargo_offer)
      CargoOfferMailer.notify_carrier(cargo_offer).deliver_later
      Notifications::Publisher.publish(
        user_id: cargo_offer.carrier.user_id,
        type: Notifications::Type::CARGO_OFFER_RECEIVED,
        payload: {
          cargo_offer_id: cargo_offer.id,
          cargo_id: cargo_offer.cargo_id,
          transport_window_id: cargo_offer.transport_window_id,
          amount_cents: cargo_offer.amount_cents,
          currency: cargo_offer.currency
        }
      )
    rescue StandardError => e
      Rails.logger.error(
        "[CargoOffersController#create] notification dispatch failed for " \
        "CargoOffer##{cargo_offer.id}: #{e.class}: #{e.message}"
      )
    end
```

### 4.3 `frontend/src/components/notifications/notificationsRegistry.ts`

```typescript
export type NotificationType = "ping" | "cargo_offer_received";
// (+ "cargo_offer_accepted" | "cargo_offer_rejected" from REQ-FE-00030 after rebase)

// in notificationsRegistry:
cargo_offer_received: () => ({
    title: landingContent.notifications.cargo_offer_received.title,
    body: landingContent.notifications.cargo_offer_received.body,
}),
```

### 4.4 `frontend/src/landingContent.ts`

```typescript
// interface (LandingData.notifications)
cargo_offer_received: { title: string; body: string };

// data (landingContent.notifications)
cargo_offer_received: {
    title: "Nueva oferta recibida",
    body: "Un expedidor te envió una oferta de carga. Revisala en tu bandeja para aceptarla o rechazarla.",
},
```
(Final copy refined through `/critique`→`/polish` per the UI gate.)

---

## 5. Testing

### Request (RSpec — `spec/requests/api/cargo_offers_spec.rb`)

Spy on `Notifications::Publisher.publish` (`allow(...).to receive(:publish)`), mirroring REQ-FE-00030's specs:

- **Publishes to the Carrier:** `POST /api/cargo_offers` publishes `cargo_offer_received` to the window-owner Carrier's `user_id`, payload `hash_including(cargo_offer_id, cargo_id, transport_window_id, amount_cents, currency)`.
- **Best-effort (AC5):** when `Notifications::Publisher.publish` is stubbed to `raise`, the request still returns **201** and the `CargoOffer` persists.
- Whitelist guard (`UnknownTypeError`) is already covered by `notifications/type_spec.rb` / `publisher_spec.rb` — no duplicate needed.

### Unit (Vitest — `notificationsRegistry.test.ts`)

- The iterate-all-types test now covers `cargo_offer_received` (backed by `landingContent`).
- `isKnownNotificationType("cargo_offer_received")` → `true`.
- **Harden:** the renderer returns valid `{title, body}` for a payload missing an optional field (and for `{}`), without throwing.

### E2E (Playwright)

- Golden path: Carrier session open; drive the real type via `POST /api/dev/notifications/broadcast` (`{ type: "cargo_offer_received", payload: {...} }` — the dev endpoint added in REQ-FE-00030); assert the toast renders the `cargo_offer_received` copy, then dismiss. (Two-role orchestration — Shipper offers against the Carrier's window — is brittle for e2e; the dev broadcast is the sanctioned shortcut.)

---

## 6. Acceptance Criteria

- [ ] **AC1** — `Type::ALL` includes `cargo_offer_received`; frontend union mirrors it.
- [ ] **AC2** — Creating an offer (`POST /api/cargo_offers`) → the window-owner Carrier gets realtime `cargo_offer_received` (toast + badge).
- [ ] **AC3** — Payload has `cargo_offer_id`, `cargo_id`, `transport_window_id`, `amount_cents`, `currency`; English snake_case.
- [ ] **AC4** — Emission occurs outside the creation transaction/`window.lock!`.
- [ ] **AC5** — A broadcast failure does not prevent offer creation (endpoint still returns 201).
- [ ] **AC6** — All UI copy via `landingContent.ts`; no Spanish literals in JSX/code; types/payload/routes English.
- [ ] **AC7** — Unknown type still silently ignored by the frontend (no framework regression).
- [ ] **AC8** — No notification persistence / new tables (best-effort, ADR-013); SQLite-portable.
- [ ] All tests passing; coverage ≥ 80%; `just lint` clean.

---

## 7. Files Summary

### New Files
| File | Description |
|------|-------------|
| `frontend/e2e/notifications-cargo-offer-received.spec.ts` | Golden-path toast e2e via dev broadcast |

### Modified Files
| File | Changes |
|------|---------|
| `backend/app/services/notifications/type.rb` | Register `cargo_offer_received` |
| `backend/app/controllers/api/cargo_offers_controller.rb` | Best-effort post-commit publish + mailer in a private `rescue` helper |
| `frontend/src/components/notifications/notificationsRegistry.ts` | Union + renderer |
| `frontend/src/landingContent.ts` | One `notifications.cargo_offer_received` entry (interface + data) |
| `backend/spec/requests/api/cargo_offers_spec.rb` | Publish + best-effort 201 specs |
| `frontend/src/components/notifications/notificationsRegistry.test.ts` | Renderer + harden test |

---

## 8. Coordination with REQ-FE-00030 (sibling)

Both issues touch the **same three files**: `type.rb`, `notificationsRegistry.ts`, `landingContent.ts` (each just *adds* a type/renderer/copy entry). REQ-FE-00030 is already open as **PR #310** into `feature/INF-FE-00005-notifications-framework`. Whichever merges second hits a **trivial additive conflict** in those three files and rebases — the resolution is mechanical (keep both entries). The `Type::ALL` array, the `NotificationType` union, and the `notifications` i18n block each end up listing all the sibling types.

The dev broadcast endpoint (`POST /api/dev/notifications/broadcast`) this plan's e2e relies on was **introduced by REQ-FE-00030**; if REQ-FE-00031 lands first, move that endpoint into this PR instead.

---

## Notes for the assignee

- **Branch:** off `feature/INF-FE-00005-notifications-framework` until the framework merges to `main`, then rebase. Coordinate PR order with REQ-FE-00030 (#310).
- **PR title:** conventional prefix required — `feat(notifications): ...`; no `[REQ-FE-00031]` bracket. Reference the TAG in the body (`Closes #306`) and branch.
- **`gh pr create --assignee @me`.**
- **Do not touch `.gdsi-sdlc/config.json`.**
- **Pre-PR UI gate:** `/critique` → `/polish` → `/audit` on the toast/copy, then `just lint`, `just frontend-test-coverage` (80%), `just frontend-test-e2e`, `just backend-test`.
