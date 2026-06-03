# REQ-FE-00030: Notificación en tiempo real al Expedidor cuando el Transportista acepta o rechaza su oferta de carga

| Field | Value |
|-------|-------|
| **Tag** | REQ-FE-00030 |
| **Title** | Notificación en tiempo real al Expedidor cuando el Transportista acepta o rechaza su oferta de carga |
| **Priority** | P2 |
| **Status** | READY |
| **Created** | 2026-06-03 |
| **Updated** | 2026-06-03 |
| **Author** | Claude Code |
| **Depends On** | INF-FE-00005 (notifications framework — transport, publisher, UI primitives), REQ-BE-00021 (CargoOffer/TransportWindow + accept/reject) |
| **Decision Doc** | N/A — single clear approach (first real consumer of an already-built, tested framework) |
| **Selected Approach** | N/A |
| **GitHub Issue** | [#304](https://github.com/tcorzo/fiuba-gestion-tp/issues/304) |

---

## 1. Problem Statement

When a **Carrier** accepts or rejects the **`CargoOffer`** a **Shipper** sent, the Shipper only learns via **deferred email** (`CargoOfferMailer.notify_shipper_offer_{accepted,rejected}`, `deliver_later`). A Shipper sitting in the app waiting for a response gets no immediate in-app feedback — they must refresh or check their inbox.

The realtime framework from [[INF-FE-00005]] (Action Cable + Solid Cable transport, `Notifications::Publisher` contract, toast/badge UI primitives) is built and tested end-to-end, but only knows the test type `:ping`. This issue ships the **first real business consumer**: add two whitelisted types, call the publisher at the exact points where the mailer is enqueued today, and add the frontend renderers + i18n copy.

**Scope guardrails.** No new domain logic — accept/reject and their state transitions already exist and are tested. The in-app notification is **additive**: the durable email stays. Per ADR-013, delivery is **best-effort live** — no persistence, no notifications table, nothing new in the DB (portable to SQLite).

**Domain direction (important — model comments are stale).** Despite outdated comments in `cargo_offer.rb` ("Carrier's bid" / "shipper accepts"), the real flow matches this issue's title:
- The **Shipper creates the `CargoOffer`** (`CargoOfferPolicy#create? = user&.shipper.present?`).
- The **Carrier accepts/rejects** (routes under `carriers/me/cargo-offers/:id/{accept,reject}`).
- The **Shipper is the recipient** of the notification — `cargo_offer.cargo.shipper.user.id`.

> Non-blocking cleanup: the stale `cargo_offer.rb` comments are flagged for the next docs/code sweep, **not** fixed in this PR unless trivial.

---

## 2. Solution Design

Mirror the existing mailer enqueue sites with a `Notifications::Publisher.publish` call. Three trigger points, two new types, one closed whitelist on each side (backend `Type::ALL`, frontend `NotificationType` union).

### Triggers (backend)

| # | Site | Type emitted | Recipient |
|---|------|--------------|-----------|
| 1a | `CargoOfferAcceptanceService#enqueue_notifications` (`cargo_offer_acceptance_service.rb:72-80`) | `cargo_offer_accepted` | Shipper of the accepted offer |
| 1b | same method, cascade over `rejected_siblings` | `cargo_offer_rejected` | Shipper of **each** auto-rejected sibling — may be **different** Shippers, each to their own `user_id` |
| 2 | `Api::Carriers::Me::CargoOffersController#reject` (`cargo_offers_controller.rb:53`) | `cargo_offer_rejected` | Shipper of the explicitly rejected offer |

**AC7 — emit outside `with_lock`.** In the acceptance service, `enqueue_notifications` (line 41) is already called **inside the transaction but after the `with_lock` block closes** (line 39). The `shipment` local (declared line 16, assigned line 34) is in scope there, so `shipment.id` is available for the accepted payload. We add the `publish` call right where the mailer is enqueued — no transaction/lock change needed. In `reject`, the mailer is enqueued inside the `transaction` but after `with_lock` closes (line 52); we emit at the same point.

**Cascade fidelity.** Iterate `rejected_siblings`, publish `cargo_offer_rejected` only for siblings that actually ended `rejected` — reuse the existing `next unless sibling.status == "rejected"` guard the mailer already uses. Each sibling's recipient is `sibling.cargo.shipper.user.id`.

**N+1 avoidance.** `sibling_pending_offers` already `includes(:transport_window)`. Resolving `sibling.cargo.shipper.user.id` for each sibling will touch `cargo → shipper → user`. Extend the eager-load to `includes(:transport_window, cargo: { shipper: :user })` so the cascade does not issue per-sibling queries.

### New types (closed whitelist)

`Notifications::Type` (`type.rb`):
```ruby
CARGO_OFFER_ACCEPTED = :cargo_offer_accepted
CARGO_OFFER_REJECTED = :cargo_offer_rejected
ALL = [ PING, CARGO_OFFER_ACCEPTED, CARGO_OFFER_REJECTED ].freeze
```
Frontend mirrors the union in `notificationsRegistry.ts`. Publishing an unregistered type raises `Notifications::UnknownTypeError` (guard already enforced) — registering the types first is mandatory.

### Payload (English snake_case)

```json
{ "cargo_offer_id": 123, "cargo_id": 45, "amount_cents": 1500000, "currency": "ARS" }
```
For `cargo_offer_accepted`, also include `"shipment_id"` (the acceptance creates a `Shipment`) to enable a future deep-link to the shipment detail. The renderer **must not break** if an optional field (`shipment_id`) is absent (see §5 harden test).

Helper to keep the three call sites DRY:
```ruby
# in CargoOfferAcceptanceService (private) and reused/inlined for the controller
def offer_payload(offer, shipment_id: nil)
  {
    cargo_offer_id: offer.id,
    cargo_id: offer.cargo_id,
    amount_cents: offer.amount_cents,
    currency: offer.currency
  }.tap { |p| p[:shipment_id] = shipment_id if shipment_id }
end
```
(The controller's `reject` builds the same 4-key hash inline; no shared module required for one extra site, but a small private method is fine.)

### Behaviour (frontend)

- Register renderers for `cargo_offer_accepted` / `cargo_offer_rejected` in `notificationsRegistry.ts`, each returning `{ title, body }` from the i18n bundle — same shape as the `ping` renderer.
- Add copy to `landingContent.ts` under `notifications` (CLAUDE.md carve-out: this is the prototype-stage i18n bundle). No literals in JSX/code.
- Toast/badge appear via the existing `NotificationsProvider` / `NotificationsToast` / `NotificationsBadge` — **unchanged**. Unknown types stay silently ignored by `isKnownNotificationType()` (framework behaviour, no regression).

### Locale gap (cheap to close)

`backend/config/locales/es.yml` is missing the `cargo_offer_mailer.notify_shipper_offer_accepted/rejected` subject keys that `en.yml` has (en.yml lines 6-9). Since we touch the copy area, add the two Spanish subjects so `I18n.t(...)` resolves under `:es`. Not strictly required by the AC but in-scope and low-risk.

### Key Components

- **`Notifications::Type`** — whitelist of the two new symbols.
- **`Notifications::Publisher.publish(user_id:, type:, payload:)`** — unchanged entry point; raises on unknown type / non-Hash payload.
- **`CargoOfferAcceptanceService`** — accept trigger + cascade; eager-load extension.
- **`Api::Carriers::Me::CargoOffersController#reject`** — explicit-reject trigger.
- **`notificationsRegistry.ts`** — union + two renderers.
- **`landingContent.ts`** — two i18n entries.

**Untouched:** `publisher.rb`, `NotificationsProvider.tsx`, `NotificationsToast.tsx`, `NotificationsBadge.tsx`, `notificationsContent.ts`, DB/schema (ADR-013).

---

## 3. Implementation Tasks

| # | Task | Status | Files |
|---|------|--------|-------|
| 1 | Register `cargo_offer_accepted` / `cargo_offer_rejected` in `Type::ALL` | Pending | `backend/app/services/notifications/type.rb` |
| 2 | Emit `cargo_offer_accepted` (+`shipment_id`) and cascade `cargo_offer_rejected` in `enqueue_notifications`; pass `shipment` in; extend eager-load | Pending | `backend/app/services/marketplace/cargo_offer_acceptance_service.rb` |
| 3 | Emit `cargo_offer_rejected` in `#reject`, alongside the mailer | Pending | `backend/app/controllers/api/carriers/me/cargo_offers_controller.rb` |
| 4 | Add missing `es.yml` mailer subjects (locale-gap close) | Pending | `backend/config/locales/es.yml` |
| 5 | Extend `NotificationType` union + add two renderers | Pending | `frontend/src/components/notifications/notificationsRegistry.ts` |
| 6 | Add `notifications.cargo_offer_{accepted,rejected}` to interface + data | Pending | `frontend/src/landingContent.ts` |
| 7 | RSpec: accept publishes to accepted Shipper; cascade publishes per rejected sibling (multi-Shipper) to correct `user_id`; reject publishes; email no-regression; unknown-type raises | Pending | `backend/spec/...` |
| 8 | Vitest: registry renders `{title,body}` for both types; missing-`shipment_id` payload doesn't break renderer | Pending | `frontend/src/components/notifications/notificationsRegistry.test.ts` |
| 9 | Playwright e2e golden path: Shipper session open, Carrier accepts → accepted toast appears (use dev/seed broadcast trigger if two roles can't be orchestrated) | Pending | `frontend/tests/e2e/...` |
| 10 | Pre-PR UI gate (`/critique`→`/polish`→`/audit`) on toast/copy, then `just lint`, `frontend-test-coverage` (80%), `frontend-test-e2e`, `backend-test` | Pending | — |

---

## 4. Code Changes

### 4.1 `backend/app/services/notifications/type.rb`

**Purpose:** Whitelist the two new types so the publisher accepts them.

```ruby
module Notifications
  module Type
    PING = :ping
    CARGO_OFFER_ACCEPTED = :cargo_offer_accepted
    CARGO_OFFER_REJECTED = :cargo_offer_rejected

    ALL = [ PING, CARGO_OFFER_ACCEPTED, CARGO_OFFER_REJECTED ].freeze

    def self.registered?(type)
      ALL.include?(type)
    end
  end
end
```

### 4.2 `backend/app/services/marketplace/cargo_offer_acceptance_service.rb`

**Purpose:** Publish the accepted notification (with `shipment_id`) and cascade rejected notifications to each sibling's Shipper. Emission stays at line 41 — inside the transaction, outside `with_lock` (AC7).

```ruby
# sibling_pending_offers — extend eager-load to avoid N+1 on cascade recipients
def sibling_pending_offers
  cargo_offer.cargo.cargo_offers
            .where(status: "pending")
            .where.not(id: cargo_offer.id)
            .includes(:transport_window, cargo: { shipper: :user })
end

# call — thread the created shipment into enqueue_notifications
#   ... inside transaction, after with_lock block (line 41):
enqueue_notifications(rejected_siblings, shipment)

def enqueue_notifications(rejected_siblings, shipment)
  CargoOfferMailer.notify_shipper_offer_accepted(cargo_offer).deliver_later
  Notifications::Publisher.publish(
    user_id: cargo_offer.cargo.shipper.user_id,
    type: Notifications::Type::CARGO_OFFER_ACCEPTED,
    payload: offer_payload(cargo_offer, shipment_id: shipment&.id)
  )

  rejected_siblings.each do |sibling|
    next unless sibling.status == "rejected"

    CargoOfferMailer.notify_shipper_offer_rejected(sibling).deliver_later
    Notifications::Publisher.publish(
      user_id: sibling.cargo.shipper.user_id,
      type: Notifications::Type::CARGO_OFFER_REJECTED,
      payload: offer_payload(sibling)
    )
  end
end

def offer_payload(offer, shipment_id: nil)
  payload = {
    cargo_offer_id: offer.id,
    cargo_id: offer.cargo_id,
    amount_cents: offer.amount_cents,
    currency: offer.currency
  }
  payload[:shipment_id] = shipment_id if shipment_id
  payload
end
```

> `cargo.shipper.user_id` avoids loading the full `User` row vs. `user.id`. If `shipper` belongs_to `user` with `user_id` FK, `shipper.user_id` is the column read — cheapest path. Verify the column name at implementation; fall back to `shipper.user.id` if `user_id` is not the FK.

### 4.3 `backend/app/controllers/api/carriers/me/cargo_offers_controller.rb`

**Purpose:** Publish `cargo_offer_rejected` on explicit reject, next to the mailer (line 53, inside transaction, after `with_lock`).

```ruby
ActiveRecord::Base.transaction do
  offer.with_lock do
    # ... existing transition_to!("rejected"), rejected_at, transport_window open ...
  end

  CargoOfferMailer.notify_shipper_offer_rejected(offer).deliver_later
  Notifications::Publisher.publish(
    user_id: offer.cargo.shipper.user_id,
    type: Notifications::Type::CARGO_OFFER_REJECTED,
    payload: {
      cargo_offer_id: offer.id,
      cargo_id: offer.cargo_id,
      amount_cents: offer.amount_cents,
      currency: offer.currency
    }
  )
end
```

### 4.4 `backend/config/locales/es.yml`

**Purpose:** Close the locale gap so the mailer subjects resolve under `:es`.

```yaml
cargo_offer_mailer:
  notify_carrier:
    subject: "Nueva oferta de carga recibida — Truckr®"
  notify_shipper_offer_accepted:
    subject: "Tu oferta de carga fue aceptada — Truckr®"
  notify_shipper_offer_rejected:
    subject: "Actualización de tu oferta de carga — Truckr®"
```

### 4.5 `frontend/src/components/notifications/notificationsRegistry.ts`

**Purpose:** Extend the type union and add two renderers reading from the i18n bundle. Renderers ignore the payload (copy is static); they must not throw on a missing optional field.

```typescript
export type NotificationType = "ping" | "cargo_offer_accepted" | "cargo_offer_rejected";

export const notificationsRegistry: Record<NotificationType, Renderer> = {
    ping: () => ({
        title: landingContent.notifications.ping.title,
        body: landingContent.notifications.ping.body,
    }),
    cargo_offer_accepted: () => ({
        title: landingContent.notifications.cargo_offer_accepted.title,
        body: landingContent.notifications.cargo_offer_accepted.body,
    }),
    cargo_offer_rejected: () => ({
        title: landingContent.notifications.cargo_offer_rejected.title,
        body: landingContent.notifications.cargo_offer_rejected.body,
    }),
};
```

### 4.6 `frontend/src/landingContent.ts`

**Purpose:** Add the two i18n entries (interface + data). Spanish copy, no JSX literals.

```typescript
// interface (LandingData.notifications)
notifications: {
    ping: { title: string; body: string };
    cargo_offer_accepted: { title: string; body: string };
    cargo_offer_rejected: { title: string; body: string };
};

// data (landingContent.notifications)
notifications: {
    ping: { title: "Notificaciones activas", body: "Recibís avisos en tiempo real mientras tu sesión está abierta." },
    cargo_offer_accepted: {
        title: "Tu oferta fue aceptada",
        body: "El transportista aceptó tu oferta de carga. Ya podés continuar con el pago.",
    },
    cargo_offer_rejected: {
        title: "Tu oferta fue rechazada",
        body: "El transportista no aceptó tu oferta de carga. Podés enviar una nueva oferta.",
    },
},
```
(Final copy refined through `/critique`→`/polish` per the UI gate.)

---

## 5. Testing

### Unit / Service (RSpec — `backend/spec/`)

Use the established matcher `have_broadcasted_to(user).from_channel(NotificationsChannel)` (see `spec/services/notifications/publisher_spec.rb`), or spy on `Notifications::Publisher.publish` with `expect(...).to have_received`. Wrap broadcast assertions in `type: :channel` examples.

- **`CargoOfferAcceptanceService`** publishes `cargo_offer_accepted` to the accepted offer's Shipper `user_id`, payload includes `cargo_offer_id`, `cargo_id`, `amount_cents`, `currency`, **and** `shipment_id`.
- **Cascade:** publishes `cargo_offer_rejected` once per sibling that ends `rejected`, each to its **own** Shipper `user_id` — include a **multi-Shipper** fixture (two siblings owned by different Shippers). No publish for siblings not ending `rejected`.
- **`CargoOffersController#reject`** publishes `cargo_offer_rejected` to the offer's Shipper (request/controller spec).
- **No-regression:** `notify_shipper_offer_{accepted,rejected}` are still `deliver_later`-enqueued alongside the publish (`have_enqueued_mail`).
- **Whitelist guard:** publishing an unregistered type still raises `Notifications::UnknownTypeError`.
- **AC7 (optional but valuable):** assert the publish is not called from within the row lock — e.g. the service still completes/raises consistently; primary coverage is structural (emit site is post-`with_lock`).

### Unit (Vitest — `notificationsRegistry.test.ts`)

- Existing iterate-all-types test now also covers the two new types (renders `{title, body}` backed by `landingContent`).
- `isKnownNotificationType("cargo_offer_accepted")` / `("cargo_offer_rejected")` → `true`.
- **Harden:** calling each new renderer with a payload **missing** `shipment_id` (and with `{}`) returns valid `{title, body}` without throwing.

### E2E (Playwright — chromium)

- Golden path: Shipper session open; Carrier accepts the Shipper's offer; accepted **toast** appears (+ badge increment). If two-role orchestration is impractical in e2e, drive the real-type broadcast via a dev/seed endpoint and assert the toast renders the `cargo_offer_accepted` copy.

---

## 6. Acceptance Criteria

- [ ] **AC1** — `Type::ALL` includes `cargo_offer_accepted` + `cargo_offer_rejected`; frontend union mirrors both.
- [ ] **AC2** — Accept → accepted offer's Shipper gets realtime `cargo_offer_accepted` (toast + badge).
- [ ] **AC3** — Explicit reject → that offer's Shipper gets `cargo_offer_rejected`.
- [ ] **AC4** — Accept cascade → each owner of an auto-rejected sibling gets `cargo_offer_rejected` to their own `user_id`; non-`rejected` siblings not notified.
- [ ] **AC5** — Payload has `cargo_offer_id`, `cargo_id`, `amount_cents`, `currency` (+`shipment_id` on accepted when present); English snake_case.
- [ ] **AC6** — Existing `deliver_later` emails still sent unchanged (additive).
- [ ] **AC7** — Emission occurs outside `with_lock`.
- [ ] **AC8** — All UI copy via `landingContent.ts`; no Spanish literals in JSX/code; types/payload/routes English.
- [ ] **AC9** — Unknown type still silently ignored by the frontend (no framework regression).
- [ ] **AC10** — No notification persistence / new tables (best-effort, ADR-013); SQLite-portable.
- [ ] All tests passing; coverage ≥ 80%; `just lint` clean.

---

## 7. Files Summary

### New Files
| File | Description |
|------|-------------|
| (tests may add fixtures/specs under `backend/spec/...` and `frontend/tests/e2e/...`) | New RSpec + Playwright coverage |

### Modified Files
| File | Changes |
|------|---------|
| `backend/app/services/notifications/type.rb` | Register two new whitelist types |
| `backend/app/services/marketplace/cargo_offer_acceptance_service.rb` | Publish accepted + cascade rejected; pass `shipment`; eager-load `cargo: { shipper: :user }`; add `offer_payload` |
| `backend/app/controllers/api/carriers/me/cargo_offers_controller.rb` | Publish `cargo_offer_rejected` on explicit reject |
| `backend/config/locales/es.yml` | Add missing `notify_shipper_offer_{accepted,rejected}` subjects |
| `frontend/src/components/notifications/notificationsRegistry.ts` | Extend union + two renderers |
| `frontend/src/landingContent.ts` | Add two `notifications.*` i18n entries (interface + data) |
| `backend/spec/...` / `frontend/...test.ts` / `frontend/tests/e2e/...` | New tests per §5 |

---

## Notes for the assignee

- **Branch:** off `feature/INF-FE-00005-notifications-framework` until the framework merges to `main`, then rebase onto `main`.
- **PR title:** conventional prefix required — `feat(notifications): ...`; no `[REQ-FE-00030]` bracket. Reference the TAG in the body (`Closes #304`) and branch.
- **`gh pr create --assignee @me`.**
- **Do not touch `.gdsi-sdlc/config.json`.**
- **Pre-PR UI gate:** `/critique` → `/polish` → `/audit` on the toast/copy changes, then `just lint`, `just frontend-test-coverage` (80%), `just frontend-test-e2e`, `just backend-test`.
- **Stale-comment cleanup** in `cargo_offer.rb` is non-blocking — flag for the next sweep, don't fix here unless trivial.
