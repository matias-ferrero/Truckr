#import "@preview/cmarker:0.1.8"

= Align Shipment model to ADR-012

_2026-05-25 13:53 UTC — rama `docs/sprint-3-plan` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/clear`
  ```,
  h1-level: 4,
  label-prefix: "cc947-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/grill-with-docs Let's implement the Payment model and policies and fix the Shipment FSM`
  ```,
  h1-level: 4,
  label-prefix: "cc948-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Read the canonical sources and the code. Substantial drift to call out before we touch anything.

  **Codebase reality (on `main`):**
  - `Shipment.ALLOWED_TRANSITIONS` = `pending_payment → to_pick_up → in_transit → delivered`. No `cancelled`.
  - Migration `20260524000000_update_shipment_statuses_for_payment_flow.rb` rewrote `accepted → pending_payment` and folded `cancelled`/`settled` into `delivered`.
  - This landed via PR #221 (Carrier offers inbox) as a `fix:` commit — likely a stowaway, not the PR's scope.

  **Canonical decisions (locked, ≥4 sources):**
  - ADR-012 amended **2026-05-24** (`technical-vision.md:152-174`): Shipment FSM is `accepted → in_transit → delivered (+ cancelled)`. "A recoger" / "Pendiente de pago" are **UI-derived labels, not states**.
  - Glossary (`docs/05-appendices/glossary.md:25`) — same.
  - REQ-BE-00033 (Brian's US8 plan, D7 row): "Sin cambios respecto al estado canónico final — `accepted → in_transit → delivered (+ cancelled)`".
  - REQ-BE-00035 (your own envíos-index plan, D7): same again.
  - PR #231 cross-cutting report: same.

  The `main` Shipment model contradicts every doc, every plan, and the explicit "no UI labels in FSM" carve-out in the glossary.

  ---

  ### Q1 — Direction of the fix

  By "fix the Shipment FSM", do you mean revert the model+migration back to canonical (`accepted → in_transit → delivered + cancelled`), or update the docs to ratify the new `pending_payment / to_pick_up` shape?

  **My recommendation:** **revert.** Reasons:
  1. ADR-012 was amended *yesterday* (2026-05-24) explicitly to lock the canonical shape — and the migration is also dated 2026-05-24, smuggled into a Carrier-offers PR. The amendment is the deliberate decision; the migration is the slip.
  2. Glossary explicitly bans `pending_payment` / "A recoger" / "Pendiente de pago" as FSM values — they are UI compositions over `(Shipment.state, payment_state)`.
  3. Canonical shape keeps Payment and Shipment FSMs orthogonal — the cancellation interlock is the *only* coupling point. The `main` shape collapses payment state into Shipment, the exact thing ADR-012 rejected.
  4. Both Sprint 3 plans you and Brian wrote consume canonical (`accepted` + derived `payment_state`). Ratifying the drift would invalidate REQ-BE-00033 §AC2, AC14, the entire `payment_state` derivation in REQ-BE-00035, and require rewriting US39's `available_actions` matrix.

  Confirm direction = **revert** before I ask Q2 (migration strategy: forward-migration vs. revert-the-bad-migration-then-new-one).
  ```,
  h1-level: 4,
  label-prefix: "cc949-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  I want to align the Shipment model to the ADR-012
  ```,
  h1-level: 4,
  label-prefix: "cc950-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Locked: revert direction.

  ### Q2 — Migration strategy

  The bad migration `20260524000000_update_shipment_statuses_for_payment_flow.rb` already shipped to `main`. Two ways to undo:

  **A. Delete the bad migration file + add a fresh `create_payments`-era migration that defines only canonical states.**
  Hostile to anyone who already ran `db:migrate` on `main` — their DB has the new states and their `schema_migrations` row points at a timestamp that no longer exists in the codebase. They'd need to manually roll back. Easy on a fresh clone, painful on existing checkouts.

  **B. Leave the bad migration in place. Add a new forward-migration `2026XXXXXXXXXX_revert_shipment_statuses_to_canonical_fsm.rb` that:**
  - drops the `pending_payment / to_pick_up / in_transit / delivered` CHECK constraint
  - `UPDATE shipments SET status = 'accepted' WHERE status IN ('pending_payment', 'to_pick_up')`
  - `UPDATE shipments SET status = 'delivered' WHERE status = 'delivered'` (no-op)
  - adds CHECK constraint `status IN ('accepted', 'in_transit', 'delivered', 'cancelled')`
  - normalizes `tracking_events.from_status`/`to_status` the same way
  - `down` reapplies the bad mapping (so `db:rollback` still works)

  **My recommendation: B.** Standard Rails practice — migrations are append-only once merged. The `down` of (A) is a manual ops note; the `down` of (B) is `db:rollback`.

  **Data-loss caveat to acknowledge in the commit message:** the bad migration already collapsed any pre-existing `cancelled` rows into `delivered` — that's unrecoverable in any DB that ran it. Acceptable because (a) academic coursework, no production data, (b) dev DBs are routinely reseeded, (c) we have no `cancel` codepath yet so the count of those rows is effectively zero. Worth a sentence in the migration's header comment so future-you doesn't go searching for missing `cancelled` shipments.

  Confirm **B**? Or do you have a reason to prefer A (e.g. nobody has run the bad migration yet anywhere that matters)?
  ```,
  h1-level: 4,
  label-prefix: "cc951-",
)

== Intercambio 4

=== Prompt

#cmarker.render(
  ```
  I don't care about the migration, there's no production data
  ```,
  h1-level: 4,
  label-prefix: "cc952-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  B it is — but you don't care, so I'll keep it short in the plan and move on.

  ### Q3 — Ownership & scope of "Payment model and policies"

  REQ-BE-00033 is **Brian's** issue. The plan says: "**Coordinar con Brian sobre el modelo `Payment`** — el shape final del estado `escrowed` y la columna `captured_at` deben estar alineados con `REQ-BE-00033` antes de freezear el serializer del detalle."

  Three plausible readings of what you actually want here:

  **A. Takeover.** You're absorbing REQ-BE-00033 fully — model + migration + `Payments::FakeGateway` + `Payments::Create` service + `POST /api/shipments/:id/payments` + cancellation interlock service + all policies. Brian gets reassigned.

  **B. Schema-only stub for REQ-BE-00035 unblock.** You land *only* the `payments` table + the `Payment` AR model + `belongs_to :shipment` + the enum + Pundit `PaymentPolicy` (read-only — `show?` / `Scope`, used by `ShipmentDetailResource#payment`). No service, no gateway, no `POST` endpoint, no cancellation interlock. Brian later lands the write side in his PR.

  **C. Model + policies + the cancellation interlock service** — but no gateway, no `POST`. You give REQ-BE-00035 the Payment shape *and* the `Shipments::Cancel` service it needs (REQ-BE-00035's `available_actions` includes `cancel` for the Shipper). Brian still owns the `POST /payments` write flow + `FakeGateway`.

  **My recommendation: B.** Reasons:
  1. REQ-BE-00033's whole *substance* (FSM justification, AC1–AC14, the FakeGateway abstraction, the `with_lock` race-safe service, the `:provider_reference` audit story) is Brian's design work. Absorbing it (A) burns his sprint contribution and PR. Bad for the team optics, and your sprint plan already commits him to it.
  2. The cancellation interlock (C) is genuinely entangled with Payment write-side semantics — it asks "does an escrowed Payment exist?" which is a predicate over Brian's invariant ("at most one escrowed per Shipment, guarded by `with_lock` in `Payments::Create`"). Writing the cancel service before Brian's lock semantics land risks a coupling rewrite. Better Brian lands `Shipments::Cancel` together with `Payments::Create`, because both are mutations on the same aggregate root and benefit from one set of integration tests.
  3. (B) gives REQ-BE-00035 *exactly* what its plan §4.1 needs — the `payment` block in `ShipmentDetailResource`, the `payment_state` derivation, and policy-scoped reads. Nothing more.
  4. (B) is the minimum surface that unblocks your own add-on (REQ-BE-00035) without stepping on Brian.

  Pick A, B, or C — and I'll ask Q4 about the table shape diffs you'd want vs. REQ-BE-00033's plan §3.
  ```,
  h1-level: 4,
  label-prefix: "cc953-",
)

== Intercambio 5

=== Prompt

#cmarker.render(
  ```
  B
  ```,
  h1-level: 4,
  label-prefix: "cc954-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  Locked: schema-only stub for REQ-BE-00035 unblock.

  ### Q4 — Schema fidelity vs. REQ-BE-00033 plan §3

  There's a real naming mismatch between the two plans you'll be straddling:

  | Surface | REQ-BE-00033 §3 (Brian, FSM owner) | REQ-BE-00035 §4.1 (you, consumer) |
  |---|---|---|
  | Success timestamp | `escrowed_at` (+ symmetric `failed_at`) | `captured_at` |
  | Currency column | `currency` | `amount_currency` |

  REQ-BE-00033 §3 is the canonical schema:

  ```
  shipment_id     bigint NOT NULL FK
  amount_cents    integer NOT NULL
  currency        string NOT NULL default "ARS"
  provider        string NOT NULL default "fake"   -- enum fake|mercadopago|stripe|other
  provider_reference string nullable
  state           string NOT NULL                  -- enum escrowed|failed, no default
  escrowed_at     datetime nullable
  failed_at       datetime nullable
  failure_reason  string nullable
  discarded_at    datetime nullable                -- discard gem
  created_at, updated_at
  ```

  Indexes: `(shipment_id, state)` composite, `(provider_reference)`, `(discarded_at)`.

  **My recommendation:** **Land REQ-BE-00033 §3 verbatim** (`escrowed_at`/`failed_at`/`currency`). Treat `captured_at` and `amount_currency` in your REQ-BE-00035 plan as **presentation aliases**, resolved in `PaymentResource` (Alba supports `attribute :captured_at, key_from: :escrowed_at` or `attribute(:captured_at) { |p| p.escrowed_at }`).

  Why:
  1. **Brian owns the FSM**, so column names should reflect FSM state names. `escrowed_at`/`failed_at` is a symmetric pair; renaming the success leg to `captured_at` orphans the failure leg ("`captured_at`/`failed_at`" reads oddly — capture is a Stripe/Adyen concept, escrow is yours).
  2. The Alba serializer is the correct seam for presentation naming; keeps the DB column stable across FE renames.
  3. **Fix the inconsistency in REQ-BE-00035 §4.1 as a doc edit** in this same PR — change `captured_at` → `escrowed_at` in the contract table, or document explicitly that it's an alias. The current wording reads like a column.

  One concrete fork before I commit to this: **do you want the serializer to expose `escrowed_at` (column name leaks) or `captured_at` (rename in resource)?**

  Two reasonable answers:
  - **Expose `escrowed_at` directly** — simplest, no aliasing, FE consumes the canonical FSM term. Fix REQ-BE-00035 §4.1 to say `escrowed_at`. (My pick.)
  - **Keep `captured_at` in the FE contract** — alias in the resource. Slightly more code, but if FE has already written code against `captured_at`, this avoids a FE rename.

  Which? — and is the column name `currency` or `amount_currency` (same question, smaller stakes)?
  ````,
  h1-level: 4,
  label-prefix: "cc955-",
)

== Intercambio 6

=== Prompt

#cmarker.render(
  ```
  No, it should all be absolutely consistent, no presentation aliases, just fix REQ-BE-00035
  ```,
  h1-level: 4,
  label-prefix: "cc956-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  Locked: schema verbatim per REQ-BE-00033 §3, fix REQ-BE-00035 docs to match. No aliases.

  ### Q5 — `PaymentPolicy` surface in this PR

  Scope B has **no Payment endpoints**. The `payment` block is reached transitively through `ShipmentDetailResource`. So strictly, the policy file might not even be called by anything in this PR.

  You said "Payment model and policies", so I assume you want the policy file landed even if it's only consumed by Brian's later PR. The question is *how much* policy.

  | Predicate | Include? | Why |
  |---|---|---|
  | `show?` | **yes** | Symmetric — true iff user is Shipper of the Cargo OR Carrier on the CargoOffer. Mirrors `ShipmentPolicy#show?` one hop down (`record.shipment.cargo_offer.carrier_id`/`.cargo.shipper_id`). Brian will reuse it for any `GET /payments/:id` if he ever adds one; meanwhile any defensive `authorize @payment` you sprinkle in resources won't blow up. |
  | `Scope` | **yes** | Same join logic. Useful if anyone calls `policy_scope(Payment)`. Cheap to write, expensive to retrofit. |
  | `create?` | **no** | Brian's territory. Predicate is non-trivial: requires the Shipper (not Carrier) and `shipment.state == 'accepted'`. Hardcoding it now risks Brian rewriting it when AC1/AC4 land. |
  | `index?` | **no** | No `/api/payments` index planned. |
  | `update? / destroy?` | **no** | Payments are immutable post-create (model-level guard). Default-deny via `ApplicationPolicy` is correct. |

  **My recommendation:** ship `show?` + `Scope` only. Default-deny everything else via `ApplicationPolicy`. No stubs for `create?`.

  One concrete consequence to confirm: **the policy will join through `cargo_offer` for both sides**, same as `ShipmentPolicy`. Specifically:

  ```ruby
  def show?
    return false if user.nil? || record.nil?

    offer = record.shipment&.cargo_offer
    return false if offer.nil?

    user.carrier? && offer.carrier_id == user.carrier.id ||
      user.shipper? && offer.cargo&.shipper_id == user.shipper.id
  end
  ```

  — two cargo joins deep. Acceptable on SQLite for the access patterns we have (always `find(id)` then `authorize`), but I want you to be aware before I commit.

  Confirm: **`show?` + `Scope` only, joining through `shipment.cargo_offer`**? Or do you want me to also stub `create?` to encode the "Shipper of Cargo + Shipment.state==accepted" predicate so Brian has a known shape to fight with later?
  ````,
  h1-level: 4,
  label-prefix: "cc957-",
)

== Intercambio 7

=== Prompt

#cmarker.render(
  ```
  drop the policy if it's not needed
  ```,
  h1-level: 4,
  label-prefix: "cc958-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Locked: no `PaymentPolicy`. Just model + migration. Brian writes the policy with his service.

  Quick check before the next question.
  ```,
  h1-level: 4,
  label-prefix: "cc959-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Found: `discard` gem is **not** in the Gemfile despite both plans calling it out. Shipment uses a hand-rolled `default_scope { where(discarded_at: nil) }` + manual `discard!` method.

  ### Q6 — Soft-delete pattern for `Payment`

  The plans both say "`discard` gem (alineado con #215)" — but #215 didn't actually install the gem. There's drift between doc and reality.

  **A. Match the hand-rolled pattern in `Shipment`.** Copy the `default_scope`, the `discarded` / `with_discarded` scopes, and the `discard!` method into Payment (or extract a concern). Don't install the gem. Fix REQ-BE-00033 + REQ-BE-00035 plan text to say "hand-rolled `discarded_at` (consistent with Shipment, ADR-009)" instead of "discard gem".

  **B. Install the gem now.** Add `gem "discard"` to the Gemfile, `include Discard::Model` in Payment, leave Shipment as-is for now (or migrate it in a follow-up). Plan text was right, codebase was lagging.

  **C. Extract a `SoftDeletable` concern.** Move Shipment's pattern into `app/models/concerns/soft_deletable.rb`, include it in both Shipment and Payment. Concern-as-DIY-gem.

  **My recommendation: A.** Reasons:
  1. **Minimum scope.** Adding a gem is its own decision with its own surface (`kept` scope, callbacks, `discard!`/`undiscard!` shape, RSpec helpers). Worth a real decision, not a sneak-in. ADR-009 already chose hand-rolled.
  2. **Consistency.** Shipment is hand-rolled; Carrier, Vehicle, Cargo, CargoOffer etc. either don't soft-delete or also do it hand-rolled per the existing Shipment pattern. Payment matching them is more consistent than introducing a new pattern.
  3. **Plans are wrong, not code.** Fix the doc text in this PR. Cheap.
  4. **C is correct long-term but premature.** With 2 callers (Shipment + Payment) it's borderline; with 3+ it becomes obvious. Defer the extraction to whichever PR adds the 3rd caller — that one earns the refactor.

  Confirm **A** (hand-rolled, copy Shipment's pattern, fix plan text inline)? Or B / C?
  ```,
  h1-level: 4,
  label-prefix: "cc960-",
)

== Intercambio 8

=== Prompt

#cmarker.render(
  ```
  THE FUCKING SHIPMENT MODEL IS WRONG IT DOES NOT RESPECT THE FUCKING ADR
  ```,
  h1-level: 4,
  label-prefix: "cc961-",
)

== Intercambio 9

=== Prompt

#cmarker.render(
  ```
  B
  ```,
  h1-level: 4,
  label-prefix: "cc962-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Locked: `discard` gem installed. Plan text was right.

  One follow-up before I move past soft-delete.

  ### Q6b — Migrate `Shipment` to the gem in this PR too?

  You're already opening `Shipment` to revert the FSM. Two sub-options:

  **B.1.** Install gem, use `include Discard::Model` in `Payment` only. Leave Shipment's hand-rolled `default_scope { where(discarded_at: nil) }` + manual `discard!` + `discarded` / `with_discarded` scopes alone. **Two patterns coexist** until someone migrates Shipment in a follow-up.

  **B.2.** Install gem, use it in **both** Payment and Shipment in this PR. Delete Shipment's hand-rolled lines (default_scope, the two scopes, the manual `discard!`). Gem provides `Shipment.kept` (≈ default scope semantics but opt-in, not default-scoped), `discard!`, `undiscard!`, `discarded` / `kept` scopes.

  **My recommendation: B.2.** Reasons:
  1. **Same-PR consistency.** Shipping the gem to introduce a *new* pattern while leaving the *existing* caller on the old pattern is exactly the kind of half-finished refactor that goes "we'll clean it up later" and rots. CLAUDE.md guideline: *"No half-finished implementations either."*
  2. **`discard` gem doesn't apply `default_scope`** — it requires explicit `Model.kept` or `with_discarded` at query sites. That's a **semantic change** for Shipment, not a refactor: code today that says `Shipment.where(...)` implicitly filters out discarded rows; with the gem it would return them. **You will need to audit every Shipment query for callers that relied on the implicit filter and add `.kept`.** Worth knowing before saying yes.
  3. The audit is tractable — Shipment has ~5 controllers and a handful of resources/services. Doable in this PR.
  4. Avoiding the audit (B.1) means Shipment specs continue exercising one behavior while the doc and Payment exercise another — invisible drift between code and reality, the exact thing this whole grilling session is unwinding.

  Caveat: this expands the PR scope. If you're optimizing for "small PR, ship today", **B.1** is defensible — just commit to a follow-up issue (`REQ-BE-XXXX: migrate Shipment to discard gem`) so it doesn't rot.

  Which? **B.2 (migrate both, audit callers)** or **B.1 (Payment only, follow-up issue)**?
  ```,
  h1-level: 4,
  label-prefix: "cc963-",
)

== Intercambio 10

=== Prompt

#cmarker.render(
  ```
  B.2
  ```,
  h1-level: 4,
  label-prefix: "cc964-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Locked: B.2 (discard gem in both Payment and Shipment, audit callers, single PR).

  ### Q7 — `Payment` model behaviors: what lands now vs. Brian later

  Schema-only stub is locked. But "model" has a fuzzy boundary — does the model include factory methods, immutability guards, predicates, or just the bare AR class?

  REQ-BE-00033 plan **§FSM** explicitly says:

  > *"Modelado a mano en el model — no hay `aasm` gem. El método `Payment.create_in_terminal_state!(shipment:, gateway_outcome:)` setea `state`, `escrowed_at`/`failed_at`, `provider`, `provider_reference` y `failure_reason` en un solo pasaje atómico."*

  So Brian considers `create_in_terminal_state!` to live **on the model**, called by his service. Brian also documents column-level immutability ("Frozen from `CargoOffer.amount_cents` at create. Immutable post-create (model-level guard).").

  Three sub-scopes:

  **A — Bare AR class.** `belongs_to :shipment`, `enum :state`, presence/inclusion validations, `include Discard::Model`, `ransackable_*`. **No** factory method, **no** immutability guard. Brian writes both with his service.

  **B — Bare + immutability guard.** Adds `before_update :prevent_terminal_field_mutation` that raises on attempts to change `state`, `amount_cents`, `currency`, `provider`, `shipment_id`, `escrowed_at`, `failed_at`. Brian writes the factory method.

  **C — Bare + immutability + factory.** Adds Brian's `Payment.create_in_terminal_state!(shipment:, gateway_outcome:)`. Tested with a stub `gateway_outcome` Struct in spec. Brian's service calls this method directly with no further model changes.

  **My recommendation: B.** Reasons:
  1. **Immutability is a model invariant.** It's not gateway-specific — it's a hard rule on the row, true for fake/mercadopago/stripe/`other` providers alike. Writing it in the model now means specs encode the contract from day 1, and Brian can't accidentally violate it from his service.
  2. **The factory method (C) is gateway-shaped.** Its signature `gateway_outcome:` is determined by `Payments::Gateway#process_payment!`'s return value — which Brian hasn't designed yet. Writing the factory before the gateway means I'm guessing at the outcome shape; Brian will refactor it. Dead code that imposes future churn.
  3. **Brian still has substantive work in (B).** He writes `Payments::Gateway` interface, `Payments::FakeGateway`, `Payments::Create` service, the `with_lock` invariant guard, the `POST /api/shipments/:id/payments` controller, all six AC tests. The model is genuinely the smaller half.
  4. **(A) is too minimal.** A model without immutability invariants is a model with a footgun. `payment.update!(state: "failed")` succeeding on an `escrowed` row would be a real bug — worth a guard now.

  Confirm **B** (bare AR + immutability guard, no factory method)? Or pull factory in (C) / push immutability out (A)?
  ```,
  h1-level: 4,
  label-prefix: "cc965-",
)

== Intercambio 11

=== Prompt

#cmarker.render(
  ```
  B
  ```,
  h1-level: 4,
  label-prefix: "cc966-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Locked: B (bare + immutability guard).

  Quick check before Q8.
  ```,
  h1-level: 4,
  label-prefix: "cc967-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  Confirmed: all timestamp columns (`accepted_at`, `picked_up_at`, `delivered_at`, `cancelled_at`, `cancellation_reason`, `settled_at`) already exist. No schema additions needed for the revert — just the CHECK constraint + data normalization.

  ### Q8 — Reverted FSM shape: allowed transitions, timestamps, and column-default

  Three sub-decisions need locking together because they're entangled.

  #### Q8a — Allowed transitions at the model level

  ADR-012 says "(+ `cancelled`) reachable from `accepted` **or** `in_transit`". REQ-BE-00035 D8 narrows it to "this sprint only `accepted → cancelled` (pre-pago)".

  | Option | `ALLOWED_TRANSITIONS` at model |
  |---|---|
  | **Permissive (ADR-012 verbatim)** | `accepted → {in_transit, cancelled}`; `in_transit → {delivered, cancelled}`; `delivered`/`cancelled` terminal |
  | **Sprint-restrictive (D8)** | `accepted → {in_transit, cancelled}`; `in_transit → {delivered}`; `delivered`/`cancelled` terminal |

  **My recommendation: permissive.** The model is the FSM truth; service-layer policy (interlock, sprint scope) restricts. Easier to gate at the service (`Shipments::Cancel` rejects `in_transit → cancelled` until Sprint 4) than to add a transition at model level later (needs migration + spec churn).

  #### Q8b — `STATUS_TIMESTAMP_COLUMNS`

  Columns exist: `accepted_at`, `picked_up_at`, `delivered_at`, `cancelled_at`, `cancellation_reason`, `settled_at`, `estimated_delivery_at`.

  ```ruby
  STATUS_TIMESTAMP_COLUMNS = {
    accepted:   :accepted_at,
    in_transit: :picked_up_at,
    delivered:  :delivered_at,
    cancelled:  :cancelled_at,
  }
  ```

  `settled_at` and `estimated_delivery_at` are leftovers — `settled` was dropped per glossary, `estimated_delivery_at` looks like dead schema from an earlier draft. **Recommendation: leave both columns in place, ignore them in this PR.** Dropping unused columns is its own decision; flag them for a `chore: drop dead shipment columns` follow-up.

  #### Q8c — `default: "draft"` on `shipments.status`

  The original `CreateShipments` migration set `default: "draft"`. `draft` is no longer in the FSM. Two clean answers:

  - **Remove the default** — `status` becomes NOT NULL with no default, model setter required. Safer (no accidental rows in an illegal state if a caller forgets to set status).
  - **Change default to `"accepted"`** — matches reality (Shipments are created at offer acceptance, never in `draft`).

  **My recommendation: change default to `"accepted"`.** REQ-BE-00033 plan §1: "*no Shipment row exists before acceptance*", so every new row is born `accepted`. Removing the default would just be defensive ceremony with no caller benefit.

  ---

  Combined recommendation:
  - **Q8a:** permissive FSM (`accepted → {in_transit, cancelled}`; `in_transit → {delivered, cancelled}`).
  - **Q8b:** four-row `STATUS_TIMESTAMP_COLUMNS` including `cancelled: :cancelled_at`. Leave `settled_at` / `estimated_delivery_at` dead but in place.
  - **Q8c:** change column default `"draft"` → `"accepted"`.

  Accept all three? Override any? — and is the `chore: drop dead shipment columns` follow-up worth filing now, or is dead schema acceptable forever in academic-coursework land?
  ````,
  h1-level: 4,
  label-prefix: "cc968-",
)

== Intercambio 12

=== Prompt

#cmarker.render(
  ```
  confirm
  ```,
  h1-level: 4,
  label-prefix: "cc969-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Locked: permissive FSM, four-row timestamp map, default `accepted`. Dead columns deferred indefinitely.

  ### Q9 — `discard` gem audit strategy + association semantics

  Switching Shipment from `default_scope { where(discarded_at: nil) }` to `include Discard::Model` is a **semantic change**, not a refactor. The gem **does not** apply a default scope; you must say `Shipment.kept` (or `with_discarded`/`discarded`) explicitly.

  Every site that touches `Shipment` (or queries `Payment` once it exists) needs review. Two strategy questions:

  #### Q9a — Audit approach

  | Option | What it does |
  |---|---|
  | **A. Blanket `.kept`** | Add `.kept` to every Shipment/Payment query site to preserve today's behavior. Mechanical, defensive. |
  | **B. Per-site judgment** | At each site, decide whether the query *should* exclude discarded rows. Some sites legitimately want all rows (admin views, audit logs, soft-delete recovery). |
  | **C. Keep a default scope alongside the gem** | `default_scope { kept }`. Defeats the gem's central design choice. Anti-pattern. |

  **Recommendation: B.** The gem's value proposition is making "include or exclude discarded" **an explicit, per-query decision**. (A) wastes the gem; (C) is anti-pattern.

  #### Q9b — `Shipment has_many :payments` default scope

  When Brian's `shipment.payments.escrowed.exists?` predicate fires (AC2 + AC14 interlock), should it count **discarded** escrowed Payments?

  Concretely: imagine an escrowed Payment that someone soft-deleted out-of-band (refund, fraud reversal, dev-tool cleanup). Should `shipment.cancel!` later be **blocked** by that ghost row, or **allowed**?

  | Option | `has_many` definition | AC14 behavior |
  |---|---|---|
  | **Kept-only association** | `has_many :payments, -> { kept }, dependent: :restrict_with_error` | A discarded escrow does not block cancellation. The active-row predicate matches the intuitive "is money currently held?" |
  | **All rows** | `has_many :payments` | Discarded escrows still block. Defensive — "if we soft-deleted an escrow, that's a data inconsistency; refuse to cancel until investigated." |

  **Recommendation: kept-only.** Reasons:
  1. The predicate's intent (per REQ-BE-00033 §FSM) is "is there real money in escrow right now?" — discarded means there isn't.
  2. Symmetric with how soft-delete is used elsewhere — the live world ignores tombstones; audit views explicitly opt in.
  3. Auditing forensics (Brian's plan: "supports forensics on 'why did this Shipment have three failed charges?'") uses `payments.with_discarded` — explicit, not magical.

  Caveat to acknowledge: this means a buggy/malicious soft-delete on an escrowed Payment **can** unblock a Shipper from cancelling. Mitigation: don't expose a "delete an escrowed Payment" path. `payment.discard!` should ideally be forbidden when `escrowed?` — but that's a service-level guard belonging to Brian's PR. Worth a TODO note pointed at his issue.

  ---

  Combined: **B (per-site audit) + kept-only `has_many :payments` association**, with the "block discard of escrowed Payment" caveat called out for Brian. Confirm?
  ```,
  h1-level: 4,
  label-prefix: "cc970-",
)

== Intercambio 13

=== Prompt

#cmarker.render(
  ```
  roll back the discard gem, I don't care for discarding payments nor shipments
  ```,
  h1-level: 4,
  label-prefix: "cc971-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Reading "I don't care for discarding payments nor shipments" two ways — need to disambiguate.

  ### Q6c — Scope of the discard-gem rollback

  **A.** Don't install the gem. Payment gets **no soft-delete** at all — no `discarded_at` column, no `kept` semantics. **Shipment is left exactly as it is today** (hand-rolled `default_scope { where(discarded_at: nil) }` + manual `discard!` stays untouched). No change to Shipment in this PR beyond the FSM revert.

  **B.** Don't install the gem **and** rip out Shipment's hand-rolled soft-delete too. Both models become hard-delete only. Drop `discarded_at` column from Shipment, drop the default_scope, drop `discard!`, drop `discarded` / `with_discarded` scopes. Effectively reverts ADR-009 for the Fulfilment aggregate. Requires updating ADR-009, REQ-BE-00022 plan, glossary.

  **My recommendation: A.** Reasons:
  1. **Minimum scope** to honor your direction. "Roll back the gem" reads literally as "undo the gem decision"; tearing out an existing pattern that ADR-009 specifically chose is a much larger move.
  2. **ADR-009 is amendable, not free.** Reverting fulfilment soft-delete is its own decision worth its own grilling round — has implications for audit, fiscal records (ARCA invoices reference Shipments), and post-MVP. Worth doing on purpose, not as a side effect.
  3. **Payment specifically doesn't need soft-delete** — Brian's "failed-attempts audit trail" use case is satisfied by the per-attempt-row design (failed rows just stay around; they're already terminal and immutable). The plan's `discarded_at` was speculative; you can remove it cleanly.
  4. **Inline doc fix:** drop `discarded_at` from REQ-BE-00033 §3 schema in this PR; drop the "(discard gem)" parenthetical; nothing else moves.

  Confirm **A** (Payment is hard-delete only; Shipment unchanged from current `main`)?
  ```,
  h1-level: 4,
  label-prefix: "cc972-",
)

== Intercambio 14

=== Prompt

#cmarker.render(
  ```
  A
  ```,
  h1-level: 4,
  label-prefix: "cc973-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Locked: Payment hard-delete only; Shipment soft-delete untouched. Plan §3 to drop `discarded_at` row + index.

  ### Q10 — PR boundaries

  Your working tree right now has REQ-BE-00035 work staged (`shipment_policy.rb` + `routes.rb` diff). The new work you're asking for (FSM revert + Payment model) is **technically independent** from REQ-BE-00035 and lives in a different conventional-commit category (`fix:` vs `feat:`).

  Three ways to land this:

  **I. One mega-PR.** FSM revert + Payment model + REQ-BE-00035 endpoints, all in one branch. Single review, single CI run, but a fat diff. Conventional commit subject becomes awkward — is it `fix:` or `feat:`?

  **II. Two PRs.** (a) FSM revert + Payment model, `fix(fulfilment): align Shipment FSM with ADR-012 + add Payment model`, lands first as a domain-consistency repair. (b) REQ-BE-00035 endpoints, rebases on (a), `feat(fulfilment): shipment list and detail endpoints (REQ-BE-00035)`. Two CI runs, but each PR has a clear scope and conventional commit.

  **III. Three PRs.** (a) Shipment FSM revert only — pure `fix:`. (b) Payment model stub — `feat(payments):`. (c) REQ-BE-00035 endpoints. Cleanest tagging, but three review/CI cycles for what's already tightly coupled.

  **My recommendation: II.** Reasons:
  1. **CI cost is real per CLAUDE.md.** Three PRs (III) triples the Typst + Vitest + Playwright + RSpec runs for what's effectively one "fix domain inconsistencies surfaced before Brian and Tomás's PRs land" piece of work.
  2. **The FSM revert and Payment model are tightly coupled by review.** They share the same domain reasoning (ADR-012 canonical shape). Reviewer needs both diffs side-by-side to confirm the Payment FSM (born-terminal) matches the Shipment FSM (no `pending_payment`).
  3. **Conventional commit hygiene.** A `feat(fulfilment): shipment list and detail endpoints` PR title would be a lie if it also reverted a CHECK constraint. Splitting at the `fix` / `feat` seam is the natural cut.
  4. **Sequencing unblocks Brian.** PR (a) gives him the `Payment` model and `accepted` FSM state his REQ-BE-00033 service can build against — that's the whole point. PR (b) is independent of him.

  #### Tagging the new PR

  Sub-question: PR (a) doesn't have a sprint issue yet. Options:

  - **No new issue.** PR body says "Fixes the regression from #221 + lays Payment schema for REQ-BE-00033 and REQ-BE-00035". Conventional commit subject + body do the tracking.
  - **New issue, new REQ tag** (`REQ-BE-00037: align Shipment FSM with ADR-012 + Payment model stub`). Gets tracked on the sprint board, gets a `.gdsi-sdlc/issues/InProgress/` file. Costs ~5 minutes of triage skill work.

  **Recommendation: new issue.** Sprint visibility matters — this is mid-sprint scope addition, the PM (you) should be the one to track it explicitly. Without a tag, it ships invisibly and the "team performance" math at retro forgets it happened.

  Combined: **II + new REQ tag**. Confirm?
  ```,
  h1-level: 4,
  label-prefix: "cc974-",
)

== Intercambio 15

=== Prompt

#cmarker.render(
  ```
  One single PR with FSM revert + Payment model, I'll handle REQ-BE-00035at some other point
  No issue, we don't have time
  ```,
  h1-level: 4,
  label-prefix: "cc975-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Locked: single PR `fix(fulfilment): ...`, no REQ tag, REQ-BE-00035 working-tree diff is your problem to park.

  A couple of final small forks before we have a complete plan. Batching since they're routine.

  ### Q11 — Spec scope

  `just backend-test` must pass and coverage shouldn't regress. The model spec changes are unavoidable; the question is **how much beyond model specs**.

  **Minimum:**
  - `spec/models/shipment_spec.rb` — update FSM examples to canonical states. Cover all transitions: `accepted → in_transit`, `accepted → cancelled`, `in_transit → delivered`, `in_transit → cancelled`, illegal-transition raises, timestamp stamping for each.
  - `spec/models/payment_spec.rb` — **new.** Presence/inclusion validations, enum `state`, `belongs_to :shipment`, immutability guard (update on `state`/`amount_cents`/etc. raises).
  - `spec/models/tracking_event_spec.rb` — verify any examples that reference `pending_payment` / `to_pick_up` are updated.

  **Add (recommended):**
  - A migration spec is **not** standard in this codebase — skip.
  - **Don't** add request specs for Payment (no endpoints in this PR — Brian's territory).
  - **Don't** add policy specs (no PaymentPolicy in this PR).

  **Recommendation: minimum-only.** No service-layer specs (no service exists in this PR). No request specs (no endpoints). Just the three model specs. That's exactly the scope of the production code we're touching.

  ### Q12 — Inline doc updates in the same PR

  These fixes ride along because they're directly contradicted by the code we're landing:

  - `docs/features/REQ/REQ-BE-00033/REQ-BE-00033-us8-realizar-pago-expedidor.plan.md` §3 schema: **drop `discarded_at` row**, drop `(discarded_at)` index, drop "Soft-delete vía `discard` gem" row in the Decisiones table. Replace with "Hard-delete only — failed rows persist as audit trail; cancellation interlock means no escrowed rows are ever destroyed."
  - `docs/features/REQ/REQ-BE-00035/REQ-BE-00035-envios-index-endpoints.plan.md` §4.1: **rename `captured_at` → `escrowed_at`**, **rename `amount_currency` → `currency`** to match Brian's canonical schema.
  - **No** changes to ADR-012 (already canonical), glossary (already canonical), or technical-vision.md.

  **Recommendation: yes, ride-along.** Reasons: (a) the docs already contradict the code we're landing; leaving the contradiction is worse than fixing in place, (b) `just build-artifacts` runs anyway since the PR touches `docs/`, no extra CI cost, (c) keeps doc + code freshly aligned, which is the whole *point* of the FSM grilling.

  ---

  Final scope summary, confirm/override:

  | # | Decision | Status |
  |---|---|---|
  | 1 | Revert Shipment FSM to canonical `accepted → in_transit → delivered (+ cancelled)` | locked |
  | 2 | Migration B (new forward-migration, don't delete the bad one) | locked |
  | 3 | Schema-only Payment stub (no policy, no service, no gateway, no POST) | locked |
  | 4 | Brian's canonical column names (`escrowed_at`, `failed_at`, `currency`) — no aliases | locked |
  | 5 | No `PaymentPolicy` | locked |
  | 6 | No `discard` gem; Payment hard-delete only; Shipment unchanged | locked |
  | 7 | Payment model = bare AR + immutability guard, no factory method | locked |
  | 8 | FSM permissive (both `accepted → cancelled` and `in_transit → cancelled`); `cancelled: :cancelled_at`; default `"accepted"`; dead columns stay | locked |
  | 9 | (moot — no discard gem) | — |
  | 10 | One PR, no REQ tag, REQ-BE-00035 work parked | locked |
  | 11 | Spec scope: three model specs only | proposed |
  | 12 | Inline doc fixes to REQ-BE-00033 §3 and REQ-BE-00035 §4.1 in the same PR | proposed |

  Confirm 11 + 12, and I'll write the implementation plan.
  ```,
  h1-level: 4,
  label-prefix: "cc976-",
)

== Intercambio 16

=== Prompt

#cmarker.render(
  ```
  confirm
  ```,
  h1-level: 4,
  label-prefix: "cc977-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Grilling complete. Implementation plan:

  ## Plan

  ### Migrations (new, in this order)

  1. **`db/migrate/<ts>_revert_shipment_statuses_to_canonical_fsm.rb`**
     - Drop CHECK constraint `shipments_status_check`
     - `UPDATE shipments SET status='accepted' WHERE status IN ('pending_payment','to_pick_up')`
     - `UPDATE tracking_events SET from_status='accepted' WHERE from_status IN ('pending_payment','to_pick_up')`
     - `UPDATE tracking_events SET to_status='accepted' WHERE to_status IN ('pending_payment','to_pick_up')`
     - Re-add CHECK constraint `status IN ('accepted','in_transit','delivered','cancelled')`
     - `change_column_default :shipments, :status, from: 'draft', to: 'accepted'`
     - `down`: reapply the bad mapping (rollbackable)
     - Header comment: notes that pre-existing `cancelled`/`settled` rows were already lost to the 2026-05-24 regression — acceptable, no production data

  2. **`db/migrate/<ts+1>_create_payments.rb`**
     - Per REQ-BE-00033 §3 **minus** `discarded_at`
     - Columns: `shipment_id`, `amount_cents`, `currency` (default `"ARS"`), `provider` (default `"fake"`), `provider_reference`, `state` (no default), `escrowed_at`, `failed_at`, `failure_reason`, timestamps
     - Indexes: `(shipment_id, state)` composite, `(provider_reference)`
     - CHECK: `state IN ('escrowed','failed')`, `provider IN ('fake','mercadopago','stripe','other')`
     - FK to `shipments`, NOT NULL, `on_delete: :restrict`

  ### Models

  3. **`app/models/shipment.rb`** — replace `ALLOWED_TRANSITIONS`, `STATUS_TIMESTAMP_COLUMNS`, `STATUSES`, scopes (`active`, `completed`); `has_many :payments, dependent: :restrict_with_error`. Update `ransackable_attributes` if it references dropped states.

  4. **`app/models/payment.rb`** — new. `belongs_to :shipment`; `enum :state, %w[escrowed failed].index_with(&:itself), prefix: true`; presence + inclusion validations; immutability guard via `before_update :prevent_terminal_mutation` raising `ActiveRecord::ReadOnlyRecord` on changes to `state`/`amount_cents`/`currency`/`provider`/`shipment_id`/`escrowed_at`/`failed_at`; `ransackable_*` for ActiveAdmin.

  ### Specs

  5. `spec/models/shipment_spec.rb` — canonical FSM transitions (5 happy + N illegal), timestamp stamping, default `"accepted"`.
  6. `spec/models/payment_spec.rb` — new. Validations, enum, association, immutability raises.
  7. `spec/models/tracking_event_spec.rb` — scan + fix any state literal references.

  ### Docs (inline)

  8. `docs/features/REQ/REQ-BE-00033/...plan.md` §3 — drop `discarded_at` row, drop `(discarded_at)` index, change "Soft-delete: discard gem" → "Hard-delete only; audit trail = per-attempt failed rows".
  9. `docs/features/REQ/REQ-BE-00035/...plan.md` §4.1 — `captured_at` → `escrowed_at`, `amount_currency` → `currency`.

  ### Verification gate

  `just lint` + `just backend-test` + `just build-artifacts`. Coverage must not regress.

  ### PR

  - Branch: `fix/align-shipment-fsm-and-payment-model` (or similar)
  - Title: `fix(fulfilment): align Shipment FSM with ADR-012 and add Payment model`
  - Body: explains the #221 regression, links ADR-012 + REQ-BE-00033 §3, notes the doc fixes
  - `gh pr create --assignee @me`

  ### Out of scope (parked)

  - REQ-BE-00035 endpoints (your working-tree diff — stash/branch before starting)
  - `PaymentPolicy`, `Payments::Gateway`, `Payments::FakeGateway`, `Payments::Create`, `Shipments::Cancel`, `POST /api/shipments/:id/payments` — all Brian's REQ-BE-00033
  - Dropping dead Shipment columns (`settled_at`, `estimated_delivery_at`)

  Ready to implement, or anything to revise first?
  ```,
  h1-level: 4,
  label-prefix: "cc978-",
)

== Intercambio 17

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/handoff`
  ```,
  h1-level: 4,
  label-prefix: "cc979-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Handoff saved to `/tmp/handoff-shipment-fsm-payment-model.md`.

  Contains the 12 locked decisions, step-by-step implementation order (park REQ-BE-00035 wip → two migrations → model changes → specs → doc fixes → pre-PR gate → PR), exact column lists and model code skeletons, hard rules from CLAUDE.md + memories, parked scope, and suggested skills (`/verify`, `/code-review` medium — skip impeccable suite, no FE).
  ```,
  h1-level: 4,
  label-prefix: "cc980-",
)
