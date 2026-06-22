#import "@preview/cmarker:0.1.8"

= Triage branch worktree for payment handoff

_2026-05-22 23:41 UTC — rama `fix/carrier-details-button` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  @/tmp/handoff-triage-brian-us8-payment.md

  WORK ON A TRIAGE BRANCH WORKTREE OFF main
  ```,
  h1-level: 4,
  label-prefix: "cc1022-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now add the ISSUES-INDEX row.
  ```,
  h1-level: 4,
  label-prefix: "cc1023-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now open the GitHub issue, then commit, push, and open PR.
  ```,
  h1-level: 4,
  label-prefix: "cc1024-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Triage done. Hand-off:

  - **gh issue**: https://github.com/tcorzo/fiuba-gestion-tp/issues/213 — `[REQ-BE-00033] US8 — Realizar pago del expedidor sobre CargoOffer aceptado (gateway mock)`
  - **PR**: https://github.com/tcorzo/fiuba-gestion-tp/pull/214 (assigned to you, body has `Tracks #213`)
  - **Local file**: `.gdsi-sdlc/issues/Ready/REQ-BE-00033-us8-realizar-pago-expedidor.issue.md`
  - **Index row**: added to `docs/features/ISSUES-INDEX.md`
  - **Branch/worktree**: `.claude/worktrees/triage-us8` on `triage/req-be-us8-payment` (off `origin/main`)

  Key decisions locked in the issue body:
  - MP integration **mocked** via `Payments::Gateway` + `Payments::FakeGateway`; real adapter deferred (no dependency on REQ-BE-00006).
  - Single fullstack issue (BE + FE).
  - `Payment.amount_cents` frozen from `CargoOffer.price` at create.
  - No new column for Carrier contact info — gated by Pundit predicate.
  - `Shipment` already created by PR #194 on accept; US8 transitions it.
  - `CargoOfferPaymentTimeoutJob` releases `TransportWindow` to `open` after 24h.
  - ACs: 5 verbatim from `backlog-us.typ:167-184` + 9 implementation-level ACs (AC6–AC14) in Spanish.

  **Open questions to confirm with the user before Brian implements** (also in issue body):
  1. Does `Cargo` go back to `open` when `CargoOffer` expires on payment timeout, or stay terminal?
  2. Are Carrier contact fields (phone/email) already on the model, or is that scope creep into this issue?
  3. Fake-gateway UI under `/dev/fake-payment/...` acceptable? Env guard vs feature flag?
  4. Timeout 24h fine, or 48–72h for demo safety?

  Side notes:
  - `shipper` label doesn't exist on the repo — used `checkout` + existing labels instead. Worth adding a `shipper` label to mirror `carrier` for symmetry.
  - `REQ-BE-00007` (old payment design) is still on disk in `Backlog/`; per handoff, didn't reference it — leave it for a separate cleanup pass.
  ```,
  h1-level: 4,
  label-prefix: "cc1025-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/grill-with-docs`
  ```,
  h1-level: 4,
  label-prefix: "cc1026-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Reading the domain docs I just hit a **load-bearing inconsistency** between the handoff/issue I wrote and the existing `docs/02-high-level-design/domain-model.md` + `docs/05-appendices/glossary.md`. Before going further, I want to resolve this before Brian implements — otherwise he's building against a domain model that two artifacts describe differently.

  ---

  **Q1 — Payment FSM and ownership.**

  Two incompatible models are on the table:

  | Surface | "Checkout intent" (my issue, your handoff) | "Escrow" (`domain-model.md` § 3, glossary, `external-systems.md`) |
  |---|---|---|
  | Belongs to | `cargo_offer` | `shipment` (1:1) |
  | FSM | `pending → approved \| rejected \| expired` | `pending → escrowed → released \| refunded \| disputed` |
  | Created when | Shipper clicks "Pagar" | Automatic side-effect of `Shipment.accept!` (already documented as opening in `escrowed`) |
  | Released when | N/A — `approved` is terminal | `Shipment` transitions to `settled` (post-delivery + dispute window) via `PaymentSettlementJob` |
  | Soft-delete | Not mentioned | Yes, per ADR-009 |
  | Provider column | Not mentioned | `provider` enum + `provider_reference` |

  The handoff & my issue treat the `Payment` as an Stripe-checkout-style intent that closes once the gateway returns `approved`. The domain model treats it as **escrow** that holds funds across the whole `Shipment` lifecycle until delivery, with release tied to `Shipment.settled`.

  These aren't compatible — they imply different tables, different controllers, different jobs.

  **My recommendation**: **Keep the escrow model** documented in `domain-model.md`. Rationale:
  1. It's already the source of truth — three artifacts converge on it (glossary, domain-model FSM, external-systems, `PaymentSettlementJob` in `scheduled-jobs.md`).
  2. Even with a mocked gateway, modelling escrow is **cheap**: a `Payment` opens in `escrowed`, `PaymentSettlementJob` fires on delivery and flips it to `released`. Fake-gateway swap-in is still trivial — the real MP integration becomes a single class.
  3. It future-proofs the dispute/refund stories (US20 / US21 likely) without re-modelling.
  4. **AC3** ("once paid, contact info is unlocked") is still satisfied: the predicate becomes `Payment.escrowed_or_released?` instead of `Payment.approved?`.

  **Adjustment to AC7 (timeout)**: instead of `Payment.expired`, the timeout becomes "if the **Shipper never confirms the charge** within 24h post-accept, the `Payment` stays at `pending`, the `CargoOffer` flips to `expired`, the `Shipment` gets `cancelled`, and the `Window` returns to `open`." The escrow never opens. That's coherent.

  **Question**: do you want me to rewrite REQ-BE-00033 to align with the escrow model, or do you want to explicitly **override** the domain-model.md (and update it + the glossary + scheduled-jobs.md to drop escrow framing)?
  ```,
  h1-level: 4,
  label-prefix: "cc1027-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  payment timeout is out of scope. no need for a paymentsettlementjob, clicking "pagar" simply advances any necessary states. the fake payment gateway is not env gated, always accessible, even in production.
  ```,
  h1-level: 4,
  label-prefix: "cc1028-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Updated. That removes the timeout job, the settlement job, AC7, AC14, and the env-gate carve-out. Reduces scope nicely.

  Three things still unresolved from the domain-model conflict — handling them one at a time.

  ---

  **Q2 — Payment FSM vocabulary.**

  With timeout & settlement out, the FSM collapses to two transitions. Two ways to name them:

  | Option | States | Pros | Cons |
  |---|---|---|---|
  | **A — Handoff vocabulary** | `pending → approved \| rejected` | Matches your handoff & the issue I wrote. Mental model = "did the charge succeed?" | Diverges from `docs/02-high-level-design/domain-model.md` § 5.1, glossary, `external-systems.md`, all of which use `escrowed`/`released`. Documents become stale or wrong. |
  | **B — Escrow vocabulary (reduced)** | `pending → escrowed \| rejected` | Aligns with existing docs verbatim. `escrowed` is terminal for the MVP — no `released` since there's no settlement job. Future US (dispute/refund) drops in cleanly. | The word "escrow" is technically incorrect when funds aren't actually held — they're charged-and-done with the fake gateway. Slightly misleading. |

  **My recommendation: B.** The docs are the authority and four artifacts already converge on the escrow vocabulary. Renaming all of them to "approved" creates more work and more drift than just adopting `escrowed` here. The "no release" stance becomes a documented limitation, not a contradiction: `escrowed` is terminal in the MVP, period. If a real MP integration ever lands, `released`/`refunded` get added — but that's not this issue's job to prefigure.

  Do you want **A** or **B**? (Or **C — rename `Payment.status` to something neutral like `paid`** if you're certain you'll never add escrow semantics.)
  ```,
  h1-level: 4,
  label-prefix: "cc1029-",
)

== Intercambio 4

=== Prompt

#cmarker.render(
  ```
  B
  ```,
  h1-level: 4,
  label-prefix: "cc1030-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Locked in. The escrow vocabulary is already in the glossary and domain-model.md so no doc update needed — just the issue.

  ---

  **Q3 — Foreign key: `Payment belongs_to :shipment` or `:cargo_offer`?**

  | Option | Pros | Cons |
  |---|---|---|
  | **A — `:shipment`** | Domain-model.md § 1 says `Shipment 1:1 Payment`. Soft-delete (ADR-009) implies Payment outlives lifecycle churn — anchoring to the long-lived entity is natural. The state transition "Payment paid → Shipment moves to to_pickup" reads as "the Shipment's Payment". `Payment.shipment_id` already documented in § 5.1. | The `amount_cents` semantically comes from `CargoOffer.price`, not from the Shipment. Extra indirection (`shipment.cargo_offer.price`) at create time. |
  | **B — `:cargo_offer`** | Matches the handoff. `amount_cents` is directly readable from the parent. Shorter Pundit chain: `payment.cargo_offer.cargo.shipper_id == current_shipper.id`. | Conflicts with documented `Payment.shipment_id`. Would require updating `domain-model.md` § 5.1 + the ERD in `docs/04-database-diagrams/`. Future dispute/refund flows hang off `Shipment`, not `CargoOffer` — re-coupling later is annoying. |

  **My recommendation: A (`:shipment`)**. Snapshotting `amount_cents` from `cargo_offer.price` at create is one line; the alignment with the documented domain model is worth more. The fact that `Shipment 1:1 Payment` is already drawn in the ERD and stated in § 5.1 means choosing B forces an unrelated doc edit and a justification ADR.

  Note: with A, the `Payment` row is created on **Shipper's "Pagar" click**, not at Carrier accept — that's a small but real divergence from `domain-model.md` § 3 ("Open a `Payment` row in `escrowed` status [on `offered → accepted`]"). I'll surface that as Q4.

  A or B?
  ```,
  h1-level: 4,
  label-prefix: "cc1031-",
)

== Intercambio 5

=== Prompt

#cmarker.render(
  ```
  A
  ```,
  h1-level: 4,
  label-prefix: "cc1032-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Locked.

  ---

  **Q4 — When is the `Payment` row created, and is `Shipment ↔ Payment` 1:1 or 1:N?**

  These are coupled because AC9 (retry after rejection) forces a choice:

  | Option | Creation | Multiplicity | Retry mechanics |
  |---|---|---|---|
  | **A — Per-attempt rows, created on "Pagar" click** | Shipper clicks "Pagar" → new `Payment` in `pending` | `Shipment has_many :payments` | Each retry creates a new row. Failed attempts kept soft-deleted (ADR-009 → audit trail). Predicate becomes `shipment.payments.escrowed.exists?`. |
  | **B — Single row, created at Carrier accept** | Side effect of `Shipment.accept!`, in `pending` | `Shipment has_one :payment` (1:1, matches `domain-model.md` § 1) | `pending → rejected → pending` re-entrant on retry. Requires an `attempts` counter and `rejected` becomes non-terminal. |
  | **C — Single row, created on "Pagar" click** | Lazy — `Payment` doesn't exist until Shipper acts | `Shipment has_one :payment` | Like B but no row at accept time. Diverges from docs § 3 ("Open a `Payment` row [on `offered → accepted`]"). |

  **My recommendation: A.** Reasons:
  1. ADR-009's soft-delete-for-audit makes far more sense per attempt than as a single mutating row. Forensics on "why did this Shipment have three failed charges?" needs row history, not a counter.
  2. Re-entrant `rejected → pending` (Option B) breaks the "terminal means terminal" property and complicates `PaymentPolicy` predicates.
  3. The cost is one doc edit: `domain-model.md` § 1 changes from `Shipment 1:1 Payment` to `Shipment 1:N Payment` (at-most-one in `escrowed`), and § 3 drops "Open a `Payment` row [on accept]". I think this is the right correction — the 1:1 was likely written before AC4/AC9 retry was a constraint.
  4. The "to_pickup" Shipment transition fires on the first `pending → escrowed` transition of *any* Payment; idempotency via `with_lock { return if shipment.to_pickup? }`.

  A, B, or C?
  ```,
  h1-level: 4,
  label-prefix: "cc1033-",
)

== Intercambio 6

=== Prompt

#cmarker.render(
  ```
  A
  ```,
  h1-level: 4,
  label-prefix: "cc1034-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Locked. Noting that this changes `domain-model.md` § 1 (1:1 → 1:N) and § 3 (drop "open Payment at accept") — I'll batch the doc edits at the end.

  ---

  **Q5 — API surface.**

  Three slots in the existing docs that conflict with what I wrote:

  | Endpoint | Docs (`api-overview.md`) | My issue | Now that FK is `shipment` |
  |---|---|---|---|
  | Create payment | `POST /api/payments` | `POST /api/cargo-offers/:id/payments` | `POST /api/shipments/:id/payments` is most natural — REST-nested under the parent. |
  | Gateway callback | `POST /api/payments/webhook` | `GET /api/payments/:id/return?outcome=...` | Differ in shape (webhook vs return-URL). |

  The webhook-vs-return distinction is meaningful:

  - **Webhook** (`POST /api/payments/webhook`): real-MP idiom. Server-to-server, signed payload, gateway is authoritative. The Shipper's browser is redirected to a thank-you page that just polls Payment status. With the **fake gateway**, the fake page would `POST` to the webhook endpoint itself when the user clicks Aprobar/Rechazar, then redirect the user to the thank-you page.
  - **Return URL** (`GET /api/payments/:id/return`): pre-MP-style. The Shipper's browser is the channel for the outcome (`?outcome=approved`). Simpler for a fake gateway but doesn't map cleanly to real MP if it ever arrives.

  **My recommendation**:

  - **Create endpoint**: `POST /api/shipments/:id/payments` (REST-nested, matches the new FK; the docs' `POST /api/payments` line in `api-overview.md` gets updated to the nested form).
  - **Callback**: `POST /api/payments/webhook` per docs. The fake gateway POSTs to it from server-side when the Shipper clicks a button on the fake page. Browser redirect lands on a thank-you page (`/payments/:id` or `/shipments/:id/payment-complete`) that fetches Payment status. This way the real-MP swap is literally one class — the webhook endpoint stays, just the signature-verification adapter changes.

  Does the webhook-style callback feel right, or do you want the simpler return-URL style? (The argument for return-URL is "we have no real gateway anyway, why pretend"; the argument for webhook is "you said 'design as if MP were real' in the handoff".)
  ```,
  h1-level: 4,
  label-prefix: "cc1035-",
)

== Intercambio 7

=== Prompt

#cmarker.render(
  ```
  we have no real gateway anyway, why pretend
  ```,
  h1-level: 4,
  label-prefix: "cc1036-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Locked. That also kills `POST /api/payments/webhook` from `api-overview.md` (I'll edit it out).

  ---

  **Q6 — AC2: "a recoger" — which Shipment state, exactly?**

  Need to verify against the current `Shipment` FSM before pinning the AC.
  ```,
  h1-level: 4,
  label-prefix: "cc1037-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  Found it. The actual FSM (verified against `backend/app/models/shipment.rb:34-40`):

  ```
  draft → offered → accepted → in_transit → delivered → settled
                                         ↓
                                     cancelled (from any pre-settled state)
  ```

  There is **no `to_pickup` / `a recoger` state**. AC2 ("estado 'a recoger'") is product-speak from the artifact, not a literal FSM state.

  | Option | What changes |
  |---|---|
  | **A — No FSM change** | Shipment stays at `accepted`. "A recoger" is a **UI-derived label** (`shipment.status_accepted? && shipment.payments.escrowed.exists? → "a recoger"` else `"pendiente de pago"`). |
  | **B — Add `paid`/`to_pickup` state between `accepted` and `in_transit`** | Touches Shipment FSM, requires migration & updating PR #194's tests. Literal AC2 read. |

  **My recommendation: A.** Reasons:
  1. The FSM is already documented & tested (PR #194). Inserting a state would require coordination with Fran's branch and a Shipment FSM change ADR.
  2. AC2's "instantáneamente con estado 'a recoger'" is satisfied by re-rendering the UI label after the payment succeeds — the user-perceived state changes instantly, the canonical state doesn't move.
  3. The FSM keeps its property "each state corresponds to a real-world physical event" — `paid` would be an internal financial state, not a physical one.

  Tradeoff: a future reader will look at the FSM and wonder where "paid" lives. Mitigation — `domain-model.md` § 4 gets one paragraph documenting "payment doesn't appear as a Shipment state; presence of an `escrowed` Payment is the predicate that unlocks pickup".

  A or B?
  ````,
  h1-level: 4,
  label-prefix: "cc1038-",
)

== Intercambio 8

=== Prompt

#cmarker.render(
  ```
  A
  ```,
  h1-level: 4,
  label-prefix: "cc1039-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Locked.

  ---

  **Q7 — `Payment.provider` and `provider_reference` columns: include from day 1 or defer?**

  `domain-model.md` § 5.1 specifies `provider` (`mercadopago` / `stripe` / `other`) + `provider_reference` (the ID returned by the gateway). For the MVP with only a fake gateway:

  | Option | Schema | Pros | Cons |
  |---|---|---|---|
  | **A — Include both columns now** | `provider:string`, `provider_reference:string`. Fake gateway writes `provider: "fake"` and a generated reference. | Matches docs verbatim. Real-MP swap-in needs zero migrations. Audit trail per attempt knows which gateway processed it. | Two columns carrying constant `"fake"` until real-MP lands (which may be never). |
  | **B — Omit, add later** | Only `gateway_reference` (or rename to `provider_reference`). No `provider` column. | Less ceremony. | When real MP lands you migrate live data — pointless friction. Doc divergence (need to update § 5.1). |

  **My recommendation: A.** Two extra string columns with constants is cheap and matches the documented schema. The `provider` enum is just a string in SQLite — no real cost.

  But a question inside this: should the enum allow `"fake"` as a value, or should the fake gateway pretend to be `"mercadopago"`?
  - `provider: "fake"` → explicit; you can `Payment.where.not(provider: "fake")` to filter test data later.
  - `provider: "mercadopago"` → looks production-real even in dev/test; cleaner if you ever ship to production with the fake gateway still wired.

  Recommendation inside the recommendation: **`provider: "fake"` as a distinct enum value**. The fake gateway is **always-on** even in production (per your earlier answer), so we already have to live with `"fake"` rows in real data — better to label them honestly.

  A with `"fake"` as a distinct enum value? Or just `gateway_reference` and skip the provider field?
  ```,
  h1-level: 4,
  label-prefix: "cc1040-",
)

== Intercambio 9

=== Prompt

#cmarker.render(
  ```
  A
  ```,
  h1-level: 4,
  label-prefix: "cc1041-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Locked.

  ---

  **Q8 — Carrier contact-info source (original Open Question #2).**

  Let me find this in code rather than ask.
  ```,
  h1-level: 4,
  label-prefix: "cc1042-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Answer from schema: contact info lives on `users` (`email`, `phone`, `full_name`), reached via `Carrier.user`. No new column needed — Open Question #2 from the original handoff is resolved.

  But the access pattern needs a choice:

  | Option | Shape | Pros | Cons |
  |---|---|---|---|
  | **A — Scoped `CarrierResource`** | `CarrierResource` conditionally includes `email`/`phone`/`full_name` when `Pundit::CarrierPolicy#can_view_contact?(current_shipper)` is true. Same `GET /api/carriers/:id` endpoint, different shape per viewer. | One endpoint. Less surface area. | Polymorphic responses are harder to spec in OpenAPI/swagger. Tests need to cover both shapes. Easy to accidentally leak fields when refactoring. |
  | **B — Dedicated endpoint** | `GET /api/shipments/:id/carrier-contact` → returns `{ full_name, email, phone }` only if `shipment.payments.escrowed.exists?` and viewer is the owning Shipper. Otherwise `403`. | Explicit. One predicate, one test. Easy to spec. Hard to accidentally leak — there's literally one place to mess up. | Extra endpoint. Two requests to display the carrier card after payment (one for shipment, one for contacts). |

  **My recommendation: B.** Reasons:
  1. Contact-info reveal is a **discrete domain event** (post-payment), not a generic Carrier read — modelling it as its own endpoint makes the semantics obvious.
  2. The `403` failure mode is clearer than "field absent from response".
  3. The two-request cost is negligible (the Shipment fetch already has to happen; the contact fetch can be done in parallel after success).
  4. Re-usable post-MVP: if disputes/returns ever expose contact info later, the same endpoint serves.

  A or B?
  ```,
  h1-level: 4,
  label-prefix: "cc1043-",
)

== Intercambio 10

=== Prompt

#cmarker.render(
  ```
  A
  ```,
  h1-level: 4,
  label-prefix: "cc1044-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Locked. So `CarrierResource` gets a conditional shape via `policy.can_view_contact?(current_shipper)`.

  ---

  **Q9 — Schema finalization batch (mostly confirmations of documented decisions).**

  Three small leftover schema calls. All are documented elsewhere; I want explicit yes/no to avoid silent re-derivation:

  1. **Soft-delete on `Payment`** — ADR-009 mandates it. The pattern Shipment already uses (`discarded_at:datetime` + `default_scope { where(discarded_at: nil) }` + `discard!` method, hand-rolled, no gem) is the cheapest path. **Confirm: yes, same hand-rolled pattern.**

  2. **`refunded` and `disputed` states** — `domain-model.md` § 5.1 lists them as valid Payment states. With no settlement job, no timeout, and the MVP scope you've defined, both are unreachable. **Recommend: drop them from the FSM in this issue, leaving `pending → escrowed | rejected`.** Update `domain-model.md` § 5.1 to mark them as "post-MVP — not implemented" rather than valid current states (otherwise the FSM doc lies).

  3. **`currency`** — docs spec it (`Payment.currency`). Recommend: `string`, default `"ARS"`, no DB constraint (validated at the model). Cheap and matches Cargo/CargoOffer conventions.

  All three as recommended? Any one you want to change?
  ```,
  h1-level: 4,
  label-prefix: "cc1045-",
)

== Intercambio 11

=== Prompt

#cmarker.render(
  ```
  1. use the discard gem as https://github.com/tcorzo/fiuba-gestion-tp/issues/215
  2. drop them
  3. default to ARS, will be unused for the time being
  ```,
  h1-level: 4,
  label-prefix: "cc1046-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Noted — Payment uses the `discard` gem (per #215), Payment FSM is `pending → escrowed | rejected`, currency `ARS`. Locked.

  ---

  **Q10 — Last one: retry mechanics with no timeout.**

  The choice in Q4 (per-attempt rows) + no timeout creates an awkward edge case I want to resolve before it bites:

  **Scenario**: Shipper clicks "Pagar" → `Payment #1` created in `pending` → Shipper lands on `/dev/fake-payment/...` → **clicks "Pendiente"** (or closes the tab) → `Payment #1` is now `pending` forever.

  The "no other `escrowed` or `pending` Payment exists" Pundit guard (for AC9 retry) then **blocks the Shipper from retrying** until `Payment #1` resolves — but with no timeout, it never will.

  Options:

  | Option | Mechanics |
  |---|---|
  | **A — Allow abandon: Shipper can transition stuck `pending` → `rejected` themselves** | `POST /api/payments/:id/abandon` (or a "Cancelar" CTA on `/payments/:id/return`). FSM becomes `pending → escrowed \| rejected \| abandoned` (or fold `abandoned` into `rejected`). |
  | **B — Loosen the guard: retry allowed while pending exists; first-resolves-wins** | Pundit only blocks if an **`escrowed`** Payment exists. Multiple `pending` rows can coexist; the first one to flip `pending → escrowed` triggers Shipment unlock, others get orphaned. |
  | **C — Single-pending guard + manual cleanup** | Pundit blocks if `pending` or `escrowed` exists. Stuck pendings require admin action (ActiveAdmin) to clean up. Punts the problem. |

  **My recommendation: A**, folding `abandoned` into `rejected` (so the FSM stays `pending → escrowed | rejected`). The Shipper-initiated transition is just `pending → rejected` via an `abandon!` action. Reasons:
  1. Keeps the FSM clean (still two terminal states).
  2. Gives the Shipper a real recovery path that doesn't require admin/dev intervention.
  3. The "Pendiente" button on the fake gateway becomes a legitimate test scenario for "Shipper got stuck and recovered" — exercises a real production code path.
  4. The return-URL page can offer "¿Te quedaste sin completar? Cancelar y reintentar" → POSTs abandon, then immediately allows a new "Pagar" click.

  A, B, or C?
  ```,
  h1-level: 4,
  label-prefix: "cc1047-",
)

== Intercambio 12

=== Prompt

#cmarker.render(
  ```
  A
  ```,
  h1-level: 4,
  label-prefix: "cc1048-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  All 10 resolved. Locking and applying changes now.
  ```,
  h1-level: 4,
  label-prefix: "cc1049-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Resolved. Locking everything in. Writing now:

  1. Rewrite `REQ-BE-00033` issue with the 10 decisions
  2. Update `domain-model.md`, `api-overview.md`, `scheduled-jobs.md`, `external-systems.md`, `glossary.md` to match
  3. ADR-012 for the load-bearing payment-model decision
  4. Update GitHub issue #213 body
  5. Amend the triage commit
  ```,
  h1-level: 4,
  label-prefix: "cc1050-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now `api-overview.md`, `scheduled-jobs.md`, `external-systems.md`, `glossary.md`.
  ```,
  h1-level: 4,
  label-prefix: "cc1051-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now ADR-012. Read ADR-011 to match style.
  ```,
  h1-level: 4,
  label-prefix: "cc1052-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now the issue rewrite.
  ```,
  h1-level: 4,
  label-prefix: "cc1053-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now update the GitHub issue body, commit, and push.
  ```,
  h1-level: 4,
  label-prefix: "cc1054-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Grilling done — all 10 decisions locked in, docs updated, ADR-012 written, issue rewritten, PR/issue bodies refreshed.

  **Final artifact set:**

  | Artifact | Location |
  |---|---|
  | Issue file | `.gdsi-sdlc/issues/Ready/REQ-BE-00033-us8-realizar-pago-expedidor.issue.md` |
  | GitHub issue | https://github.com/tcorzo/fiuba-gestion-tp/issues/213 |
  | PR | https://github.com/tcorzo/fiuba-gestion-tp/pull/214 |
  | **ADR-012** | `docs/01-technical-vision/technical-vision.md` |
  | Domain model updates | `docs/02-high-level-design/domain-model.md` § 1, § 4.1, § 5.1, decisions index |
  | API surface | `docs/05-appendices/api-overview.md` (webhook out, return-URL + abandon in) |
  | External systems | `docs/05-appendices/external-systems.md` (fake gateway is THE prod gateway) |
  | Scheduled jobs | `docs/05-appendices/scheduled-jobs.md` (`PaymentSettlementJob` removed) |
  | Glossary | `docs/05-appendices/glossary.md` (added `Pasarela falsa`, refreshed `Pago`) |

  **What changed materially from the first triage**:
  - `Payment` is now per-Shipment (1:N), not per-CargoOffer (1:1).
  - FSM trimmed from 5 states to 2 (`escrowed` is terminal, drops `released`/`refunded`/`disputed`).
  - Fake gateway is production-mounted (not env-gated).
  - New `abandon!` action replaces the timeout job for stuck-`pending` recovery.
  - Contact-info reveal happens via resource-shape conditioning, not a dedicated endpoint.
  - Documented all of it in **ADR-012** so future readers see why.
  ```,
  h1-level: 4,
  label-prefix: "cc1055-",
)

== Intercambio 13

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/handoff the /issues-plan phase`
  ```,
  h1-level: 4,
  label-prefix: "cc1056-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Handoff written: `/tmp/handoff-plan-req-be-00033-us8-payment.md`

  Self-contained brief for the next session. Pointers (not duplicates) to:
  - Issue file `.gdsi-sdlc/issues/Ready/REQ-BE-00033-...issue.md`
  - ADR-012 in `technical-vision.md`
  - Updated domain-model / appendices
  - gh issue #213, PR #214

  Tells the next agent: continue on `triage/req-be-us8-payment`, run `/gdsi-sdlc:issues:plan`, don't re-open decisions, don't implement, don't open a new PR.
  ```,
  h1-level: 4,
  label-prefix: "cc1057-",
)
