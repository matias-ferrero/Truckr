#import "@preview/cmarker:0.1.8"

= Handoff sprint 3 triage and planning

_2026-05-24 15:57 UTC — rama `chore/sprint-status-skill` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/clear`
  ```,
  h1-level: 4,
  label-prefix: "cc2797-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  @/tmp/handoff-sprint3-tomas-triage.md
  ```,
  h1-level: 4,
  label-prefix: "cc2798-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  I'll start by reading the live state — PR #219 plan body, the backlog US file, glossary, and SDLC config — so I know exactly what to triage into.
  ```,
  h1-level: 4,
  label-prefix: "cc2799-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  State of play: `Route` model + `TrackingEvent` already exist (REQ-BE-00022 merged). `Route.polyline` is nullable with a code comment saying it's "populated by a downstream Google Maps Directions integration (separate issue)" — that's exactly the hole this US fills. Next free tags: `REQ-BE-00035`, `REQ-FE-00022`.

  Two calls only you (the user, on behalf of Tomás) can make before I create issues. Asking both at once.
  ```,
  h1-level: 4,
  label-prefix: "cc2800-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Drafting the US + a proposed split for your sign-off before I touch any files.

  ---

  ## US draft (Spanish, INVEST shape, mirrors US13/US21)

  > **US48: Marcar el Recorrido del Envío**
  >
  > **Release:** MVP   **Prioridad:** Alta   **Épica:** Aceptar Viaje
  >
  > **Descripción:**
  > Como transportista, una vez aceptado un envío, quiero marcar el recorrido planificado sobre Google Maps, para que el sistema persista la ruta del envío y tanto yo como el expedidor podamos visualizarla en sus pantallas correspondientes (navegación, tracking).
  >
  > **Criterios de aceptación:**
  > 1. Sobre un `Shipment` en estado `accepted` o posterior (no `cancelled` / `delivered`), el transportista accede a una pantalla "Marcar recorrido" desde el detalle del envío.
  > 2. El sistema calcula un recorrido sugerido entre el origen y el destino del envío usando Google Maps Directions, y lo muestra dibujado sobre el mapa.
  > 3. El transportista puede aceptar el recorrido sugerido, o ajustarlo agregando/moviendo hasta N waypoints intermedios antes de confirmar.
  > 4. Al confirmar, se persisten en el `Route` del envío: la polyline codificada, `distance_m`, `duration_s`, `calculated_at`, `provider`, y los waypoints elegidos.
  > 5. El transportista no puede marcar recorrido en envíos que no son suyos (autorización por `current_user.carrier`).
  > 6. Si Google Maps Directions falla o no devuelve resultado para el par origen/destino, se muestra un error claro y el transportista puede reintentar o (decisión de UX en `/critique`) marcar manualmente.
  > 7. Marcar el recorrido es **idempotente**: re-confirmar reemplaza el `Route` existente y actualiza `calculated_at`.
  > 8. Identifiers, rutas y params en inglés; copy de UI vía i18n (no literales hardcoded); error messages del backend vía `I18n.t`.

  ---

  ## Proposed atomic split (3 issues, fullstack)

  | # | TAG (proposed) | Scope | What ships | Depends on |
  |---|---|---|---|---|
  | 1 | `REQ-BE-00035` | BE — service layer | `Routes::DirectionsGateway` port + `Routes::FakeGateway` (deterministic, always-on dev/test, mirrors `Payments::FakeGateway` / ADR-012 pattern). Unit tests on the service alone. **No controller.** Includes whatever wiring (`config/initializers/routes_gateway.rb`) selects fake vs real. | none |
  | 2 | `REQ-BE-00036` | BE — endpoint | `PATCH /api/shipments/:id/route` controller, policy (`ShipmentPolicy#mark_route?`), serializer for the persisted `Route`, request specs, I18n error keys, glossary update for **"Recorrido"** synonym row on `Route`. | #1 |
  | 3 | `REQ-FE-00022` | FE — carrier UI | "Marcar recorrido" screen on shipment detail: GMaps render of origin/destination, fetch suggested route from the endpoint, allow confirm + optional waypoint edit, persist, surface errors. E2E spec for golden path. | #2 mergeable (can dev against mock) |

  **Why this split (and not 2 or 4):**

  - **Not 2** (collapse #1 into #2): the gateway-port pattern is the single piece of architecture worth its own review and unit-test surface. Bundling it with the controller creates a 600-line PR that mixes "should we ship a fake gateway?" with "is the endpoint shape right?".
  - **Not 4** (split real Google adapter from fake): the real Google Directions adapter is post-MVP. Following ADR-012's pattern (Payments uses `FakeGateway` *forever* for the academic MVP — see CLAUDE.md "SQLite forever"), I'd treat `Routes::FakeGateway` as the canonical MVP implementation too, and skip a `GoogleDirectionsAdapter` issue entirely. **Flag**: if you want the real Google call in scope, we add a 4th issue.

  **Sprint commitment fit:**

  - All three are net-new and #1 → #2 → #3 is a serial chain. #3 also touches `Shipment` indirectly (associated `Route`), which puts it in soft-conflict territory with Franco's #194 until that lands. Realistic for Tomás in 3 days: **#1 + start #2.** Whole chain shipping by 2026-05-27 is aggressive but not impossible.

  ---

  ## Open decisions before I write files / create issues

  1. **`Routes::FakeGateway` as MVP-final** (recommended, mirrors Payments) **or** real Google call in scope (adds a 4th issue + API key + cost story)?
  2. **Acceptance criterion #3 — waypoint editing**: in scope from day 1, or defer "manual edit" to a later REQ-FE and ship #3 as "confirm suggested only"?
  3. **PR #219 row update** — do you want me to push directly to `docs/sprint-3-plan` (already open as PR #219), or hand the diff back for Tomás to commit?

  Pick / redirect and I'll proceed.
  ```,
  h1-level: 4,
  label-prefix: "cc2801-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/grill-with-docs`
  ```,
  h1-level: 4,
  label-prefix: "cc2802-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Pre-grill check — pulling the ADR list so I can cross-reference architecture decisions during the interview.
  ```,
  h1-level: 4,
  label-prefix: "cc2803-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Pulling at the first thread — the semantic core. Everything else (state machine gating, idempotency, the FE flow, whether this is even one US) collapses out of this answer.

  ## Q1 — What does "marcar el Recorrido" actually *do* to data?

  Two completely different features share the Spanish phrase "marcar el recorrido", and the existing backlog already has BOTH framings floating around:

  | Framing | What persists | Trigger | Lifecycle | Existing US it lives inside |
  |---|---|---|---|---|
  | **(A) Plan the route** | One row in `routes` per Shipment — `polyline`, `distance_m`, `duration_s`, `calculated_at`, `provider`. Single source of truth for "the route I will take". | Carrier action, **once**, before/at start of trip. Replaceable. | Bound to the `Shipment` lifecycle. | None yet — this is the gap. `route.rb` comment literally says "populated by a downstream Google Maps Directions integration (separate issue)". |
  | **(B) Trace the realized path** | A stream of `tracking_events` rows of `event_type='position'` (per REQ-BE-00022 plan, lines 286+) emitted while moving. | Background GPS ping while `status=in_transit`. Append-only. | Bound to actual driving time. | US21 ("Tracking de Envío"), US13 ("Navegación GPS"). Both already exist. |

  These are not the same feature. They are not even the same model.

  **The handoff hint** ties this to "Fulfilment context (Shipment / Route / TrackingEvent from REQ-BE-00022)" — i.e. it lists *both* models — so the original ambiguity is real, not something I invented.

  **Recommended answer: (A) Plan the route.**

  Reasons:
  1. The hole in the codebase is (A) — `Route.polyline` is null with an explicit TODO comment pointing to "a separate issue". Nothing similar exists for (B); the `tracking_events` table is already defined per REQ-BE-00022.
  2. (B) is already promised by US13 and US21, which are higher in the existing backlog and not Tomás's row.
  3. The verb "marcar" + the Google Maps interaction fits (A) — a one-time UI decision to "pin down" the route — better than (B), which is passive GPS streaming with no UI affordance to "mark" anything.
  4. (A) ships in days; (B) needs a GPS pipeline (browser geolocation + interval + batching + auth + a `POST /tracking_events` endpoint + map redraw) that's a sprint of its own.

  If you confirm (A), I'll keep all subsequent grilling within that framing. If (B), most of the previous plan is wrong and I'll restart from the GPS pipeline.

  Which framing — (A), (B), or some explicit mix I'm not seeing?
  ```,
  h1-level: 4,
  label-prefix: "cc2804-",
)

== Intercambio 4

=== Prompt

#cmarker.render(
  ```
  Let's talk in human and value terms before addressing any code, what are we building?
  ```,
  h1-level: 4,
  label-prefix: "cc2805-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Right — stepping out of the spec for a second.

  ## What we're building, in plain words

  When a Transportista and Expedidor agree on a Shipment, there's a hole: **there's no actual path between origin and destination yet.** The system knows two points; it knows nothing about how the cargo gets from A to B. "Marcar el Recorrido" is the moment the Carrier fills that hole — they sit down with a map and **commit to a path** before they ever turn the key.

  The artifact is a drawing on a map. The semantic is **a contract**: "this is how I'm going to take your stuff there."

  ## Why it matters — by who

  **For the Transportista** — it's a planning aid that doubles as cover.
  - They think through the trip *before* driving it: which highways, where to refuel, how long it'll actually take given Google's traffic estimate. Today they do this in a separate Google Maps tab; we're bringing it into the deal.
  - If something goes wrong later ("you're late!"), they have a concrete artifact to point at: "this is what I committed to, and here's where I am vs that."

  **For the Expedidor** — it's visibility and trust.
  - Right now they hand cargo to a stranger and get a black box until it arrives. A drawn route + ETA is the trust artifact that fills that gap.
  - They get a real ETA based on real roads, not straight-line distance — which is a huge UX upgrade from what we have.

  **For the platform** — it's the substrate everything else on the map needs.
  - US13 (Carrier navigation) and US21 (Shipper tracking) are both meaningless without it. They both say "show the route" — but there is no route to show. This US is what gives them something to render.
  - It's also what makes "did the trip deviate?" answerable later — you can't measure deviation from nothing.

  ## The product question hiding in here

  There's one decision that isn't technical at all and shapes the whole feature:

  > **Is the route something the Carrier *authors*, or something the system *proposes* and the Carrier *accepts*?**

  Two very different stories:

  - **"Carrier authors"** — the Carrier draws / picks / edits their own path, using Google as a starting suggestion. The route reads as a *commitment from a professional driver*. Higher Carrier agency. Higher trust signal to the Shipper ("a person decided this").
  - **"System proposes, Carrier accepts"** — Google Directions returns one optimal path, the Carrier clicks "OK". Route reads as *an algorithm's output that someone rubber-stamped*. Lower agency, lower friction, but also lower trust narrative.

  The current draft AC implicitly assumes the second one with optional editing. **My read is the first is the right product story** for a marketplace whose value prop is "trust independent drivers" — but it costs more UX work, and you may have a different read.

  A related question: **what does the Expedidor actually see?** Read-only polyline + ETA on their shipment detail? Or do they get to react ("¿por qué pasás por Córdoba?") before pickup? MVP is probably read-only, but worth naming.

  ---

  So: before we slice issues, does that framing match what Tomás had in mind? And which authorship model — Carrier authors, or system proposes?
  ```,
  h1-level: 4,
  label-prefix: "cc2806-",
)

== Intercambio 5

=== Prompt

#cmarker.render(
  ```
  Ok, for the MVP the GMaps integration I was thinking of is, first of all, I need location pickers for the transport window and cargo origin and destinations. Both of those should be... right now, they have a very bad user experience because they have to input the addresses manually, and we have no checks of whether those addresses exist. They're within the country or anything. Um, addresses should be strictly within Argentina, and we should be able to have The user is input that location and be able to see the two points in a map. In the case of the carrier, we should also be able to have the carrier drop a pin on the map and drag a radius around that pin because that'll determine... that is only for the origin. That'll determine how much a carrier is willing to go out of their current location to pick up a cargo, and that'll help filter transport windows for shippers.
  ```,
  h1-level: 4,
  label-prefix: "cc2807-",
)

== Intercambio 6

=== Prompt

#cmarker.render(
  ```
  Ok, for the MVP the GMaps integration I was thinking of is, first of all, I need location pickers for the transport window and cargo origin and destinations. Both of those should be... right now, they have a very bad user experience because they have to input the addresses manually, and we have no checks of whether those addresses exist. They're within the country or anything. Um, addresses should be strictly within Argentina, and we should be able to have The user is input that location and be able to see the two points in a map. In the case of the carrier, we should also be able to have the carrier drop a pin on the map and drag a radius around that pin because that'll determine... that is only for the origin. That'll determine how much a carrier is willing to go out of their current location to pick up a cargo, and that'll help filter transport windows for shippers. Additionally, I want the shipment views, which are not yet implemented, but this will be deferred to have a map with the origin and destination for a given shipment. Additionally, I want to add Google Maps shortcut buttons so the carrier can quickly get a route to the shipment's origin or destination. The in app route and live tracking will be kept out of the MVP.
  ```,
  h1-level: 4,
  label-prefix: "cc2808-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Got it — major rescope. Let me reflect it back and then surface the real product questions.

  ## What we're actually building (MVP)

  This is **not a route-drawing feature**. It's a **location-quality + matching feature**. Two distinct values:

  **Value 1 — addresses become real.**
  Today both sides type addresses as free text with zero validation. Someone can type "calle falsa 123" or "Buenos Aires" and the system happily accepts it. We replace those inputs with a map-backed picker that:
  - guarantees the place actually exists
  - guarantees it's in Argentina (no accidental Montevideos)
  - stores a real lat/lng alongside the human-readable string
  - shows the user a pin on a map so they confirm "yes, that's the place"

  Applies to: TransportWindow (origin + destination), Cargo (origin + destination).

  **Value 2 — Carriers declare how far they'll go.**
  Right now the matching between a Cargo and a TransportWindow is effectively textual / on-trust. We replace it with a real spatial filter:
  - When a Carrier publishes a TransportWindow, they drop a pin at their origin and **drag a radius** ("I'm willing to go this far out of my way to pick up").
  - When a Shipper searches for compatible windows for a Cargo, the system only shows windows whose pickup radius actually covers the Cargo's origin.

  That radius is the new product mechanic. Everything else (geocoding, the map UI) exists to *serve* it.

  ## Explicitly deferred (post-MVP)

  - Shipment detail page with map of origin/destination
  - "Open in Google Maps" shortcut buttons for the Carrier
  - In-app route drawing / live tracking — i.e. nothing of what I drafted before

  ## The product decisions actually open

  A few real calls only you can make:

  **1. What about destination matching?**
  You said radius is *only* on origin. But a Cargo has a fixed destination point too, and so does the TransportWindow. How do they match?
  - (a) **Destinations don't filter** — only origin radius matters; Shipper sees any TW whose origin radius covers Cargo origin, regardless of where the TW is going. Carrier sorts it out post-offer.
  - (b) **Destinations must be "close"** — there's an implicit destination tolerance (a system default like 50 km, or a second drag-radius on the TW destination).
  - (c) **Cargo destination must lie roughly *along the way*** — fancier, probably post-MVP.

  My read: (a) is the honest MVP — anything else needs a UX you haven't asked for. But it's a real call.

  **2. Carrier input flow for the pickup pin.**
  Two shapes:
  - (a) Type address → pin auto-drops → drag radius. Address-first.
  - (b) Drop pin freely on the map → optional reverse-geocode for display → drag radius. Map-first.

  (a) is more guided (good for "registrar mi punto de partida habitual"); (b) is more flexible ("estoy hoy en este descampado"). MVP probably (a) with the pin draggable for nudges — but worth naming.

  **3. What happens to TransportWindows/Cargos that already exist with free-text addresses?**
  We have FIX-BE-00001 in flight that's making `destination` nullable, plus existing seed data. Once geocoded lat/lng become required:
  - (a) Hard cutover: old rows are invalid until re-entered. Demo-friendly if we just reseed.
  - (b) Backfill via reverse geocode at migration time. More work, risk of bad data.
  - (c) Old rows keep working in "legacy mode" without radius matching. Tech-debt forever.

  Coursework MVP context says (a) is fine, but flag it.

  **4. Default + bounds for the pickup radius.**
  Default 50 km? Min 5 km, max 500 km? This is a sensible-defaults question — happy to pick if you don't care.

  **5. Who pays the Google bill?**
  Geocoding + Places Autocomplete + map tiles are billable per call. For coursework MVP, we either (a) cache aggressively + cap with a free-tier API key, or (b) build a `Locations::FakeGeocoder` that returns deterministic answers from a small fixture set and use the real Google only in a manual demo. Mirrors the `Payments::FakeGateway` pattern from ADR-012. My strong recommendation: (b) for dev/test, (a) for the live demo.

  ---

  Want to call those five before I draft anything?
  ```,
  h1-level: 4,
  label-prefix: "cc2809-",
)

== Intercambio 7

=== Prompt

#cmarker.render(
  ```
  Ok, for the MVP the GMaps integration I was thinking of is, first of all, I need location pickers for the transport window and cargo origin and destinations. Both of those should be... right now, they have a very bad user experience because they have to input the addresses manually, and we have no checks of whether those addresses exist. They're within the country or anything. Um, addresses should be strictly within Argentina, and we should be able to have The user is input that location and be able to see the two points in a map. In the case of the carrier, we should also be able to have the carrier drop a pin on the map and drag a radius around that pin because that'll determine... that is only for the origin. That'll determine how much a carrier is willing to go out of their current location to pick up a cargo, and that'll help filter transport windows for shippers. Additionally, I want the shipment views, which are not yet implemented, to have a map with the origin and destination for a given shipment. Additionally, I want to add Google Maps shortcut buttons so the carrier can quickly get a route to the shipment's origin or destination. The in app route and live tracking will be kept out of the MVP.
  ```,
  h1-level: 4,
  label-prefix: "cc2810-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  That's a much more honest framing than what I was drafting. Let me play it back so we know we're saying the same thing.

  ## What "GMaps en el MVP" actually is

  It's **four small product upgrades**, not one big feature. They share a building block (Google Maps + an Argentina-restricted address picker) but each gives value to a different person at a different moment.

  ### 1. "Donde digo *acá*, que sea acá de verdad" — picker en formularios

  Today both flows have the same bug: a Transportista types an address to publish a Ventana, an Expedidor types an address to publicar Carga, and we trust the string. No idea if it exists, no idea if it's en Argentina, two users can write the same place ten different ways.

  **Valor:** la dirección sale validada y geo-localizada de origen. Menos viajes a la nada, menos mismatches al hacer match, y ya tenemos lat/lng para todo lo demás.

  **Quién recibe:** Carrier (al publicar TransportWindow) y Shipper (al publicar Cargo) — son dos slices simétricos, posiblemente dos US distintas porque los actores y los formularios son distintos.

  ### 2. "Yo me muevo, pero no infinito" — radio del Transportista

  Una Ventana hoy es "salgo de A, voy a B". Pero un Transportista realmente está diciendo "salgo *cerca* de A" — está dispuesto a desviarse N km para retirar una carga que no esté exactamente en A. Sin esto, o el Carrier publica un punto único y pierde cargas cercanas, o publica algo demasiado amplio y le aparece cualquier cosa.

  **Valor:** el Carrier expresa su tolerancia espacial real; el Shipper sólo ve matches a quienes literalmente le llegan. Mata un montón de fricción de match.

  **Quién recibe:** el Carrier al definirlo, el Shipper al buscar — pero la *acción* es del Carrier. El lado Shipper es un cambio en la lógica de filtrado existente (US5), no una US nueva propia.

  ### 3. "Mostrame en un mapa de qué estamos hablando" — Shipment detail con mapa

  Hoy un Envío aceptado es un par de strings y un estado. Falta la representación visual de "esto va de acá hasta allá". El mapa cumple ese rol — read-only, sin polyline trazada, sólo los dos puntos.

  **Valor:** trust artifact compartido. Ambas partes miran lo mismo. Es también la pantalla que más tarde podría llevar tracking en vivo (post-MVP), pero hoy es sólo geografía estática.

  **Quién recibe:** Carrier y Shipper, en sus respectivas pantallas de detalle del Shipment.

  ### 4. "Llevame a Google Maps" — atajos al app nativo

  Renunciamos a la navegación in-app (que era US13) y la reemplazamos por un botón. El Carrier abre Google Maps con destino el origen del Cargo (para retirar) o el destino del Cargo (para entregar). Eso es lo que Google ya hace mejor que nosotros — no compitamos.

  **Valor:** el Carrier llega adonde tiene que llegar sin tener que copiar la dirección a otra app. Costo de implementación: ridículamente bajo (es una URL bien armada). Costo de no tenerlo: el Carrier se queja todos los viajes.

  **Quién recibe:** el Carrier, en el detalle del Shipment.

  ---

  ## Cómo se relaciona con lo que ya hay en el backlog

  - **US9 (Publicar Ventana)** y **US27 (Publicar Carga)** todavía no se construyeron — el picker (#1) es la forma correcta de hacerlas la primera vez, no un retrofit. Esto es bueno: no estamos rompiendo nada, estamos definiendo bien.
  - **US5 (Filtrar Ventanas Compatibles)** ya existe — el radio (#2) probablemente sea *un criterio de aceptación nuevo dentro de US5*, no una US separada. O lo mete en US5 o sale un US5b.
  - **US13 (Navegación GPS in-app)** y **US21 (Tracking en vivo)** salen del MVP, conforme dijiste. Hay que reflejarlo en el backlog — esas US no se "redactan mal", se *mueven a Release 2/3* para que el alcance del MVP quede honesto.

  ---

  ## Preguntas honestas antes de seguir

  Cinco cosas que no son código, son decisiones de producto, y las tengo flojas:

  1. **El radio: ¿alrededor del origen publicado o de la ubicación del Carrier?** Dijiste "current location" pero también dijiste que el live-location está fuera del MVP. La lectura razonable es: **alrededor del origen publicado de la Ventana** — el Carrier dice "salgo cerca de Mar del Plata, dispuesto a desviarme 50 km". ¿Confirmás?

  2. **Quién construye la pantalla de detalle de Shipment.** El mapa va sobre una pantalla que no existe todavía. ¿La US de Tomás incluye crear esa pantalla, o sólo agregar el mapa a algo que arma otra persona en otra US?

  3. **Radio: ¿lo edita después o sólo al publicar?** O sea, ¿la Ventana queda con su radio fijo, o el Carrier lo retoca? Esto cambia si es un atributo del form o una pantalla aparte.

  4. **Validación "dentro de Argentina": ¿UI-only o también server-side?** El picker de Google ya restringe por país con `componentRestrictions`. ¿Confiás en eso o el backend también valida que lat/lng caigan en el bounding box AR? (Lo segundo es más defensivo pero mete validation logic.)

  5. **¿Qué hace el sistema con TransportWindows / Cargos publicados antes de que esto exista?** Probablemente nada — backend no tiene producción todavía. Pero si llegan a haber datos seed, hay que decidir si se geocodifican retroactivamente o se descartan.

  Una vez que tengamos esto claro, lo natural es: **3 US (no una)** — picker (Carrier), picker (Shipper), radio. El mapa en el detalle de Shipment + los deep-links a Google Maps caben dentro de una cuarta US chica o se reparten como AC de las US de Shipment detail que ya existen / hay que crear. Y eso ya nos da una conversación honesta sobre qué de todo esto cabe en lo que queda del Sprint 3 para Tomás.
  ```,
  h1-level: 4,
  label-prefix: "cc2811-",
)

== Intercambio 8

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/handoff in english`
  ```,
  h1-level: 4,
  label-prefix: "cc2812-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Handoff written: `/tmp/handoff-sprint3-tomas-gmaps-mvp.md`.

  Key points it carries forward:
  - **Discards** the previous handoff's "Carrier draws a Recorrido polyline" framing and the mid-session US48 + 3-issue split — both were wrong.
  - **Reframes** Tomás's work as 4 small GMaps MVP slices (address picker × 2 actors, pickup radius, Shipment-detail map + Google Maps deep-links). US13 and US21 explicitly out of MVP.
  - **Holds the 5 open product questions** that block US drafting (radius anchor, Shipment-screen ownership, radius editability, AR-validation layer, seed data).
  - Suggests `grill-with-docs` → `user-stories` → `gdsi-sdlc:issues:triage` as the next-session skill chain.
  - Flags that backlog-us.typ needs to demote US13/US21 to a later release as part of this work, and that the radius glossary term lands before any code identifier.
  ```,
  h1-level: 4,
  label-prefix: "cc2813-",
)
