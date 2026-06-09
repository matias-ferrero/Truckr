# Shipper Dashboard v2 — Deferred / Adapted Features

Features visible in the concept mockup that cannot be honestly backed by the **current**
backend without new model columns or heavy changes (out of scope per the task). Each is
either **deferred** (not built) or **adapted** (built differently, faithfully, within
current data). The backend itself required no deferrals — see the report; these are the
client-side gaps.

## Deferred

### 1. "Nueva oferta" — literal unread/unseen offer badge
**Concept:** board cards in *Con ofertas* show a "Nueva oferta" badge implying an unread state.
**Why deferred:** Offers (`CargoOffer`) have no `seen_at` / `read_at` / per-shipper read
state, and adding one is a new column (out of scope). There is no way to know which offers
the Shipper has already looked at.
**What we ship instead (adapted):** the *Con ofertas* card shows the **offer count**
(e.g. "3 ofertas") and the best price. A subtle emphasis treatment marks the column, but no
false "new/unread" claim is made. True unread semantics would need a `cargo_offer_views`
table or a `seen_at` column — a deliberate future feature, not faked here.

### 2. Carrier name / identity on pre-payment surfaces (board cards & offer activity)
**Concept:** cards and the activity feed appear to name the carrier / show their avatar.
**Why deferred:** This is **intentional and aligned with the backend privacy model**, not just
a data gap. The backend deliberately **hides counterparty contact/identity until payment is
escrowed** (`counterparty_display_name` is null pre-escrow; contact reveal is a documented
post-escrow behavior). The cargos/offers list also exposes only `carrier_id`, not a name.
**What we ship instead (adapted):** pre-payment cards/feed items are carrier-anonymous
(amount + route + time only). Carrier identity appears on surfaces where the backend already
reveals it (accepted/in-transit/delivered shipments via `counterparty_display_name`).
Surfacing carrier names earlier would both require a serializer change AND violate the
reveal-after-escrow policy — so it stays deferred by design.

### 3. Avatars / profile photos (header + activity feed)
**Concept:** circular avatar images for the account and feed entries.
**Why deferred:** No image/avatar storage exists on `User` (no `avatar_url` column, no
Active Storage attachment for avatars). Adding one is out of scope.
**What we ship instead (adapted):** monogram/initial chips and semantic kind-icons (built
from existing data) stand in for avatars — consistent with the existing app chrome.

### 4. "Ofertas enviadas" top-nav item
**Concept:** a top-nav link labelled "Ofertas enviadas" (sent offers).
**Why deferred / adapted:** "Sent offers" is a **Carrier** concept — Carriers *send* offers,
Shippers *receive* them. A Shipper has no "sent offers". This is a mockup artifact. The
dashboard's nav uses the Shipper-appropriate destinations (Inicio = this dashboard, Cargas,
Envíos, Reseñas) rather than a mislabelled carrier item.

## Adapted (built, with a note)

### 5. Activity feed richness ("offer received · $X")
The backend `GET /api/shippers/me/activity` endpoint returns `TrackingEvent` rows, which only
exist **after** a shipment is created (accepted → in_transit → delivered → payment). It does
**not** capture "offer received" events (offers predate shipments). To match the concept's
richer feed, the client **merges** two honest sources it already has loaded:
- **offer-received** items derived from `cargo.cargo_offers[].created_at` (+ amount), and
- **shipment-lifecycle** items from the `TrackingEvent` activity endpoint.
Merged, sorted by time, capped. No fabricated events; everything maps to a real record.

### 6. Route shown as locality ("Córdoba → Mendoza")
Cargo rows expose `pickup_locality`/`delivery_locality`; **shipment** list rows expose only
full `origin`/`destination` addresses (no locality split). Cargo cards therefore show clean
localities; shipment cards show the address (truncated). Exposing locality on the shipment
list serializer is a possible trivial future tweak but was not required for a faithful build.
