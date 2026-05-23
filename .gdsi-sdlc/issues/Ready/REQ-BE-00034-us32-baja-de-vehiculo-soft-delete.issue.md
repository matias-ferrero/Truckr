---
tag: REQ-BE-00034
title: Baja de vehículo por el transportista (soft delete, ADR-009) (US32)
priority: P2
status: ready
created: '2026-05-22'
source: manual
author: Claude Code
github_issue: 215
github_repo: tcorzo/fiuba-gestion-tp
plan: docs/features/REQ/REQ-BE-00034/REQ-BE-00034-us32-baja-de-vehiculo-soft-delete.plan.md
labels:
- REQ
- BE
- FE
- carrier
- mvp
- us32
---

## Summary

El Carrier puede dar de baja un vehículo de su flota desde "Mi Flota". La baja se implementa como **soft delete hand-rolled** siguiendo el patrón ya establecido por **ADR-009** y aplicado en `Shipment`, `Payment`, `ArcaInvoice`: columna `discarded_at` + `default_scope { where(discarded_at: nil) }` + scopes `discarded` / `with_discarded` + método de instancia `discard!`. El registro no se borra de la base. Esto preserva la integridad de TransportWindows y el historial de viajes (US17 — vía `Shipment → CargoOffer → TransportWindow → Vehicle`). Cubre US32 fullstack (BE + FE en un único PR).

## Problem Statement

El transportista necesita retirar vehículos de su catálogo activo (vendidos, dados de baja, no operativos) sin romper la trazabilidad histórica. Una eliminación dura (`DELETE FROM vehicles`) rompería referencias en TransportWindows publicadas y en el historial de viajes que llega al vehículo vía la cadena `Shipment → CargoOffer → TransportWindow → Vehicle`. Se necesita un mecanismo de baja lógica que:

- Oculte el vehículo del listado activo y de los selectores al publicar nuevas ventanas.
- Conserve los datos para que el historial de viajes y las asociaciones `belongs_to :vehicle` (hoy solo en `TransportWindow`) sigan resolviendo al vehículo correcto.
- Rechace la baja si el vehículo tiene compromisos activos (ventanas de transporte activas o viajes en curso).

**Decisión del producto (corregida 2026-05-22):** se sigue el patrón hand-rolled de **ADR-009** (mismo que `Shipment`, `Payment`, `ArcaInvoice`). NO se introduce el gem `jhawthorn/discard` en este issue — la migración a un gem dedicado para todos los modelos soft-deleted del repo es un esfuerzo separado, fuera de scope de US32 (lo lidera el dueño del repo). Razonamiento: hoy el repo tiene una única convención de soft-delete documentada (ADR-009); introducir el gem solo para `Vehicle` crearía dos patrones paralelos hasta que la migración repo-wide aterrice. Mejor mantener la coherencia hasta entonces.

**Decisión documental (incluida en este PR):** `Vehicle` **no estaba** en la lista de soft-delete original de ADR-009 (`docs/01-technical-vision/technical-vision.md:106-115` lo nombra explícitamente como hard-delete junto a Carrier, Shipper, TransportWindow, etc). Este issue **amenda ADR-009** para promover `Vehicle` a la lista de soft-delete porque US32 exige preservar la referencia histórica del vehículo desde `Shipment → CargoOffer → TransportWindow → Vehicle`. La razón se amplía: "soft-delete para entidades audit-bearing **o** referenciadas por el historial de viajes". La addenda se escribe en el mismo PR de Lucas (~15 líneas de Markdown + tres updates en comentarios de `.puml`).

**Nombre de columna canónico:** `discarded_at` (no `deleted_at`). La addenda de ADR-009 también canoniza esto: el wording original `deleted_at` queda como histórico; el código corriente (`Shipment`, `Payment`, `ArcaInvoice`) ya usa `discarded_at` y la nueva columna en `vehicles` sigue la convención del código, no la del wording original del ADR.

## Expected Behavior

### Backend

- **Migración** — `add_column :vehicles, :discarded_at, :datetime` + `add_index :vehicles, :discarded_at`. SQLite-clean (columna plana + B-tree). Mismo shape que `shipments.discarded_at` ya existente.
- **`Vehicle` model — patrón hand-rolled ADR-009** (copia textual del bloque ya presente en `Shipment`):

  ```ruby
  # ── Soft-delete (ADR-009) ─────────────────────────────────────────────
  default_scope { where(discarded_at: nil) }
  scope :discarded,      -> { unscope(where: :discarded_at).where.not(discarded_at: nil) }
  scope :with_discarded, -> { unscope(where: :discarded_at) }

  class NotDiscardable < StandardError; end

  # No-bang: returns true / false. Rails-idiomatic match para controllers
  # que necesitan diferenciar "el usuario hizo algo mal" de "rompió la DB".
  def discard
    return false unless can_be_discarded? # popula self.errors con AC3/AC4
    update(discarded_at: Time.current)
  end

  # Bang: raise on guard failure. Útil para specs / ActiveAdmin / scripts.
  def discard!
    raise NotDiscardable, errors.full_messages.join("; ") unless can_be_discarded?
    update!(discarded_at: Time.current)
  end
  ```

  El `before_destroy :ensure_no_active_commitments` actual (`vehicle.rb:18,89-97`) queda obsoleto como camino productivo (hard delete deja de ser el camino). Mover la lógica de guarda al predicado `can_be_discarded?` que ambos métodos consultan antes de aplicar. El `before_destroy` puede mantenerse como red de seguridad para el path admin de hard-delete (no se borra) o eliminarse — ver pregunta abierta.

- **`DELETE /api/carriers/me/vehicles/:id`** — Pundit-gated al Carrier dueño. Llama `vehicle.discard` (no bang). Si retorna `true` → `head :no_content`. Si retorna `false` → render 422 con `vehicle.errors` (i18n-keyed). NO usar `discard!` acá — el caso "compromisos pendientes" es un error de usuario recuperable, no una excepción.
- **Guarda de ventanas activas (AC3)** — dentro del check `can_be_discarded?`: `vehicle.transport_windows.active.exists?` (el scope `active = where(active: true)` ya existe en `transport_window.rb:20`). Si hay alguna: `errors.add(:base, :has_active_windows)` y `return false`.
- **Guarda de compromisos pendientes (AC4)** — el check existente `ensure_no_active_commitments` (`vehicle.rb:89-97`) ya bloquea hard-delete sobre cualquier `CargoOffer` no terminal (`pending / accepted / paid`) en cualquiera de las ventanas del vehículo. La guarda equivalente para discard **mantiene esa estrictez** (no la afloja a "solo Shipment en curso"): bloquea si existe **(a)** un `Shipment` `accepted` o `in_transit` (`Shipment.in_progress`, definido en `shipment.rb:67`) en alguna ventana del vehículo **O** **(b)** un `CargoOffer` con `status NOT IN ('expired', 'cancelled')` en alguna ventana del vehículo. En la práctica (b) es estrictamente más amplio que (a) — un Shipment en `accepted` implica el `CargoOffer` correspondiente está en `paid` (no terminal) — así que basta con un check al estilo del actual:

  ```ruby
  CargoOffer.joins(:transport_window)
            .where(transport_windows: { vehicle_id: id })
            .where.not(status: %w[expired cancelled])
            .exists?
  ```

  Razón para no aflojar: un `CargoOffer` `pending` representa una promesa pendiente al Shipper. Descartar el vehículo lo deja zombie hasta que `CargoOfferExpirationJob` lo expire (≤48h). Mejor bloquear ahí y obligar al Carrier a rechazar / esperar a que expiren las ofertas antes de descartar. Mantiene el contrato del marketplace coherente.

  La clave de error i18n correspondiente es **`has_pending_commitments`** (más amplio que `has_active_shipments`).
- **Endpoint de publicar ventana** — donde el Carrier crea una nueva `TransportWindow`, el selector / FK validation rechaza vehículos descartados (AC6). El default scope cubre el read, pero se agrega validación explícita por si llega un id descartado por la API.
- **Lecturas históricas (AC5)** — el historial debe resolver al vehículo aunque esté descartado. Camino canónico (no hay shortcut `belongs_to :vehicle` en `Shipment`):

  ```
  Shipment → CargoOffer → TransportWindow → Vehicle
  ```

  El único `belongs_to :vehicle` real está en `TransportWindow` (`backend/app/models/transport_window.rb:6`). Fix concreto: declararlo como `belongs_to :vehicle, -> { unscope(where: :discarded_at) }, inverse_of: :transport_windows` para que el lookup transitivo del historial siga resolviendo al vehículo descartado. **No** agregar un `belongs_to :vehicle` shortcut en `Shipment` — eso denormaliza el camino y es una decisión de dominio aparte (requeriría su propio ADR).

  Otros puntos que tocan el default scope y necesitan revisarse:
  - El finder de ActiveAdmin para `Vehicle` (default scope se aplica → admin pierde los descartados; usar `Vehicle.with_discarded` o `unscope` en el resource).
  - Cualquier otro `belongs_to :vehicle` futuro (hoy solo `TransportWindow`) hereda la misma necesidad.
- **Restore — fuera de alcance en este sprint.** El dato es restaurable (la columna `discarded_at` es escribible vía `rails console`), pero **NO se cablea la acción `undiscard` en el resource ActiveAdmin** ni se expone UI de "deshacer" al Carrier. Wiring de la UI admin queda como follow-up (triage separado). Para la ventana donde el restore aún no exista UI: la operación correctiva manual es `Vehicle.with_discarded.find(id).update!(discarded_at: nil)` desde consola.
- **i18n** — todos los mensajes de error (`has_active_windows`, `has_pending_commitments`, `unauthorized`, `vehicle_not_found`, `vehicle_must_be_kept_when_active`) pasan por `config/locales/*.yml`. Nunca literales hardcodeados.

### Frontend

- **"Mi flota"** (`/carrier/vehicles`) — cada fila tiene un CTA **"Dar de baja"** claramente identificado (canon UI; ver glosario `docs/05-appendices/glossary.md` fila `Vehicle`). NO usar "Eliminar" / "Retirar" / "Borrar".
- **Modal de confirmación** (AC2) — reusar el patrón de modal del flujo de aceptación (PR #194 / `QuoteInboxPage`). Título del modal: **"Dar de baja vehículo"**. Botón confirmar: **"Dar de baja"**. Botón cancelar: **"Cancelar"**. Copy via i18n keys, sin literales hardcodeados.
- **Error surface** — si el BE devuelve 422 con `has_active_windows` o `has_pending_commitments`, el UI muestra el mensaje localizado correcto y ofrece la siguiente acción: link a "Mis Ventanas" para desactivar primero (caso ventanas activas) o explicación + link a la bandeja de ofertas para gestionar las ofertas pendientes (caso compromisos pendientes).
- **Refresh** — en éxito, la fila desaparece del listado y se muestra toast de confirmación. Aliniar con el patrón event-driven de PR #194 (`truckr:carrier-quote-updated`): considerar `truckr:carrier-vehicle-updated`.
- **Historial de viajes** — verificar (o anotar como follow-up) que los viajes pasados que referencian al vehículo descartado siguen renderizando sus datos sin "vehículo eliminado" como placeholder.
- **Tests** — Vitest para el CTA + modal + estados de error. MSW handlers para el nuevo `DELETE`. Playwright e2e: (a) Carrier descarta un vehículo sin compromisos → la fila desaparece, (b) Carrier intenta descartar con ventana activa → modal de bloqueo con copy correcto.

## Technical Notes

**Patrón hand-rolled (ADR-009)** — mismo bloque de 5 líneas que `Shipment`, `Payment`, `ArcaInvoice`. No se introduce gem alguno; la migración repo-wide a `discard` gem se trackea aparte y fuera de scope de este issue.

**SQLite-clean** — todo el cambio es `datetime` column + B-tree index. Ni un solo Postgres-ism. Sin "Phase 2" notes (ver CLAUDE.md "Database policy").

**No hard delete (camino productivo)** — fuera de alcance. No agregar:
- Endpoint admin de `destroy_permanently`.
- `VehicleArchivedJob` que purgue después de N días.
- Cualquier path nuevo que dispare `DELETE FROM vehicles`.

**`Vehicle#destroy` sigue callable (decisión deliberada)** — la pregunta de "deshabilitar hard-delete del todo" fue evaluada en grilling (Q9, 2026-05-22) y rechazada. Razones:
- En la práctica el `dependent: :restrict_with_error` sobre `TransportWindow.has_many :cargo_offers` ya hace hard-delete imposible para cualquier vehículo con historial — los Vehicles "huérfanos" que sí se pueden destruir son los que nunca tuvieron ofertas, donde el data loss es nulo.
- ActiveAdmin necesita un escape hatch para casos genuinos (data de seed, vehículos de testing).
- El `before_destroy :ensure_no_active_commitments` actual queda como red de seguridad final.

Lucas: no agregar override `def destroy; raise ...` ni similar. Si en el futuro alguien cambia el `dependent:` sobre TransportWindow, revisitar.

**No denormalized flag** — no agregar `vehicle.active` boolean ni `vehicle.deleted` como duplicado de `discarded_at.nil?`. La fuente única es la columna `discarded_at` + el predicado `discarded?` (definirlo si no existe ya: `def discarded? = discarded_at.present?`).

**Cascada con TransportWindow — decisión tomada (2026-05-22): NO cascada.** Descartar un vehículo **no** deshabilita implícitamente sus TransportWindows. AC3 ya bloquea la baja si hay ventanas activas, así que el Carrier debe ocultar/dar de baja las ventanas activas *antes* del discard. Ventanas inactivas (`active: false`) sobreviven al discard apuntando al vehículo descartado (vía `belongs_to :vehicle, -> { unscope(where: :discarded_at) }`); su reactivación queda bloqueada por la invariante AC14. UX más clara, menos comportamiento implícito.

**`Vehicle.has_many :transport_windows, dependent: :destroy`** (`vehicle.rb:14`) — con soft delete este `dependent: :destroy` deja de dispararse por el camino productivo. Verificar que el comportamiento esperado al descartar un vehículo NO es destruir sus ventanas: solo el bloqueo del AC3 actúa sobre las ventanas activas, y las ventanas inactivas pueden quedarse referenciando al vehículo descartado sin problema (el `belongs_to :vehicle, -> { unscope(where: :discarded_at) }` las cubre).

## Related

- US fuente: **US32** (`docs/artifacts/backlog-us.typ:510-517`).
- Patrón de soft-delete: **ADR-009** (referenciado desde `backend/app/models/shipment.rb:42`). Mismo bloque ya en `Shipment`, `Payment`, `ArcaInvoice` (ver columna *Definition* del glosario para esos tres).
- Modelos:
  - `backend/app/models/vehicle.rb` — aplicar bloque ADR-009; mover guards al check pre-`discard!`.
  - `backend/app/models/transport_window.rb:6` — convertir `belongs_to :vehicle` en `belongs_to :vehicle, -> { unscope(where: :discarded_at) }, inverse_of: :transport_windows`. Scope `active` ya existe (`transport_window.rb:20`).
  - `backend/app/models/shipment.rb:67` — `scope :in_progress = where(status: %w[accepted in_transit])` ya existe; AC4 lo reusa.
  - ActiveAdmin `Vehicle` resource — usar `with_discarded` para ver todos.
- Glosario: agregar **"Soft delete (Vehicle)"** a la columna de `Vehicle` con el marker `"Soft-deleted (audit)"` (consistente con Shipment / Payment / ArcaInvoice).
- PR #194 — patrón de modal de confirmación + refresh event-driven; estados de Shipment vigentes (`accepted, in_transit, delivered, settled, cancelled, draft, offered`).
- Refactor cruzado: `REF-BE-00002` (Quote→CargoOffer, CargoOffer→Cargo) — ya está reflejado en `shipment.rb` (`belongs_to :cargo_offer`).
- Histórico: `REQ-FE-00020` (Historial de viajes — US17).
- Vecinos: `US34` (eliminar ventana de transporte), `US35` (ocultar ventana) — son las acciones que el Carrier debe ejecutar primero si hay ventanas activas bloqueando la baja.
- Política: [`CLAUDE.md`](../../../CLAUDE.md) — language policy (i18n), DB policy (SQLite forever), pre-PR UI quality gate.
- Convención UI: el glosario lista **"Mi flota"** como label canónico para el listado y **"Agregar vehículo"** como CTA de alta. Este issue canoniza el CTA de baja como **"Dar de baja"** y lo agrega al bloque "UI canon (es-AR)" de la fila `Vehicle` del glosario (ver AC13).

## Notas de implementación para el assignee

- **PR title format** — conventional commit prefix obligatorio (`feat(carrier): ...`), **sin** `[REQ-BE-00034]` bracket prefix. El TAG va en el body (`Closes #N`) y en el nombre de rama (`feature/REQ-BE-00034-...`). El check `.github/workflows/pr-title.yml` bloquea PRs con bracket prefix.
- **`gh pr create --assignee @me`**.
- **No tocar `.gdsi-sdlc/config.json`.**
- **Pre-PR UI quality gate** (CLAUDE.md): `/critique` → `/polish` → `/audit` sobre los cambios FE. El modal de confirmación destructiva es exactamente el tipo de UX que `/critique` y `/audit` deben revisar. Luego: `just lint`, `just frontend-test-coverage` (80% threshold), `just frontend-test-e2e`, `just backend-test`. CI es caro — reproducir local primero.

## Acceptance Criteria

> AC1–AC6 son textuales de US32 (`docs/artifacts/backlog-us.typ:511-517`). AC7–AC11 son las condiciones adicionales derivadas de la decisión de soft-delete. AC12–AC13 son las entregas documentales que viajan en el mismo PR.

- [ ] **AC1** — Desde la pantalla "Mi flota", cada entrada ofrece una acción **"Dar de baja"** claramente identificada. (US32 original dice "Eliminar"; este issue canoniza "Dar de baja" en glosario y supersede el wording original — ver AC13.)
- [ ] **AC2** — Antes de confirmar la baja, se muestra un diálogo de confirmación.
- [ ] **AC3** — Si el vehículo está asociado a una o más ventanas de transporte activas (US9), la baja se rechaza y se indica al usuario que debe primero dar de baja u ocultar dichas ventanas (US34, US35).
- [ ] **AC4** — Si el vehículo tiene **compromisos pendientes** en alguna de sus ventanas (Shipment en `accepted` / `in_transit`, o `CargoOffer` no terminal — es decir, `pending` / `accepted` / `paid`), la baja se rechaza y se explica el motivo. Mantiene la estrictez del actual `Vehicle#ensure_no_active_commitments` (`vehicle.rb:89-97`): un `CargoOffer` `pending` ya cuenta como compromiso porque hay un Shipper esperando respuesta del Carrier. Error key i18n: `has_pending_commitments`. (US32 wording original "viaje en curso" se interpreta acá en sentido amplio para no aflojar la garantía del marketplace; el wording UI cliente mantiene la frase corta "viaje en curso o oferta pendiente".)
- [ ] **AC5** — El vehículo dado de baja deja de aparecer en el listado activo del transportista, pero sus datos se conservan a efectos del historial de viajes (US17) — los viajes pasados siguen mostrando el vehículo que los realizó.
- [ ] **AC6** — El vehículo dado de baja deja de ser seleccionable al publicar nuevas ventanas de transporte.
- [ ] **AC7** — La eliminación se implementa como soft delete hand-rolled siguiendo ADR-009: columna `discarded_at`, `default_scope { where(discarded_at: nil) }`, scopes `discarded` / `with_discarded`. Métodos: **`discard`** (no-bang, retorna true/false, popula `errors` cuando falla por AC3/AC4 — usado por el controller del Carrier) y **`discard!`** (bang, raise `Vehicle::NotDiscardable` cuando fallan los guards, raise propio de `update!` si la DB falla — usado por specs / scripts / ActiveAdmin). Mismo shape de columna y scopes que `Shipment`, `Payment`, `ArcaInvoice`.
- [ ] **AC8** — El listado activo de vehículos del transportista no muestra vehículos dados de baja (lo cubre el `default_scope`).
- [ ] **AC9** — Los viajes y envíos pasados siguen mostrando los datos del vehículo aunque éste haya sido dado de baja. Concretamente: `TransportWindow#vehicle` se declara `belongs_to :vehicle, -> { unscope(where: :discarded_at) }`, y los accesos históricos vía `shipment.cargo_offer.transport_window.vehicle` siguen resolviendo. No se introduce un `belongs_to :vehicle` shortcut en `Shipment`.
- [ ] **AC10** — Mensajes de error y copy del diálogo de confirmación pasan por claves i18n; sin literales hardcodeados.
- [ ] **AC11** — La acción es reversible **a nivel de datos**: la columna `discarded_at` es escribible (`Vehicle.with_discarded.find(id).update!(discarded_at: nil)`). En este sprint **NO se cablea la acción `undiscard` en ActiveAdmin** ni se expone UI de "deshacer" al transportista. La UI admin de restore queda como follow-up (triage separado). El admin debe usar `rails console` mientras tanto.
- [ ] **AC12** — Addenda de **ADR-009** (`docs/01-technical-vision/technical-vision.md:106-115`) incluida en el mismo PR:
  - Mueve `Vehicle` de la lista de hard-delete a la de soft-delete, con razón documentada ("audit-bearing por referencia histórica vía `Shipment → CargoOffer → TransportWindow → Vehicle`").
  - Canoniza el nombre de columna como **`discarded_at`** (no `deleted_at`); deja una nota de que el wording original del ADR queda superseded.
  - Actualiza la tabla de soft-delete en `docs/02-high-level-design/domain-model.md` (alrededor de la línea 354).
  - Actualiza los comentarios en `docs/04-database-diagrams/erd-overview.puml`, `erd-fulfilment.puml`, `erd-marketplace.puml` y `docs/04-database-diagrams/README.md:25` para incluir `vehicles` en el set de tablas soft-deleted.
- [ ] **AC13** — Glosario (`docs/05-appendices/glossary.md`, fila `Vehicle`) — **ya actualizada en el PR de triage (REQ-BE-00034)**: marker "Soft-deleted (audit) since REQ-BE-00034" + "Dar de baja" canonizado en el bloque "UI canon (es-AR)". Lucas solo verifica que el wording del modal / CTA en código coincida con el glosario; no escribe el glosario.
- [ ] **AC14** — **Invariante de marketplace coherencia**: `TransportWindow` no permite `active == true` cuando su `Vehicle` está descartado. Implementación: validación a nivel modelo (`validate :vehicle_must_be_kept_when_active` en `transport_window.rb`) que dispara cuando `active && vehicle&.discarded?`. Cubre los dos paths que pueden establecer `active: true`:
  - **Create** (`POST /api/carriers/me/transport_windows`): ya cubierto indirectamente por el default scope (`current_carrier.vehicles.find` 404ea sobre id descartado), pero la validación deja la garantía explícita en el modelo en lugar de depender del controller.
  - **Update / reactivación** (`PATCH /api/carriers/me/transport_windows/:id` con `active: false → true`): el único path real que la nueva validación protege. Cierra el escenario "ventana inactiva → vehículo descartado → reactivar ventana → ventana activa apuntando a vehículo descartado, visible en marketplace".
  - Specs: (a) crear ventana sobre vehículo descartado falla (regresión de la cobertura existente), (b) PATCH active=true sobre ventana cuyo vehículo está descartado falla con error i18n-keyed (`window.errors[:base]` con clave `vehicle_must_be_kept_when_active`), (c) ventanas inactivas pueden seguir existiendo apuntando a vehículos descartados sin disparar la validación.

### Tests requeridos

- [ ] RSpec — happy path no-bang: `vehicle.discard` con vehículo sin compromisos → `true`; `vehicle.reload.discarded?` true.
- [ ] RSpec — happy path bang: `vehicle.discard!` no raise; mismo efecto.
- [ ] RSpec — guards no-bang: `vehicle.discard` con compromisos → `false`; `vehicle.errors[:base]` contiene la clave i18n correcta.
- [ ] RSpec — guards bang: `vehicle.discard!` con compromisos → raise `Vehicle::NotDiscardable`.
- [ ] RSpec — guarda AC3: descarte rechazado si hay `TransportWindow.active`.
- [ ] RSpec — guarda AC4: descarte rechazado si hay Shipment en curso (`accepted` / `in_transit`).
- [ ] RSpec — guarda AC4: descarte rechazado si hay `CargoOffer` no terminal (`pending` / `accepted` / `paid`) en alguna ventana (incluso si la ventana está `active: false`).
- [ ] RSpec — default scope: listado del Carrier no incluye vehículos descartados.
- [ ] RSpec — histórico: `shipment.cargo_offer.transport_window.vehicle` resuelve a un vehículo descartado (gracias al `unscope(where: :discarded_at)` en `TransportWindow#vehicle`).
- [ ] RSpec — ActiveAdmin: el resource lista vehículos descartados (vía `with_discarded`).
- [ ] Vitest — CTA "Eliminar" + modal + estados de error (422 con cada código i18n).
- [ ] Playwright e2e — happy path (descartar sin compromisos) + bloqueo (descartar con ventana activa).

## Decisiones cerradas en triage (2026-05-22)

Todas las preguntas abiertas que originalmente requerían input del PO fueron resueltas durante grilling:

1. ~~**Restore en admin**~~ — **OUT OF SCOPE en este sprint.** AC11 garantiza reversibilidad a nivel de datos vía `rails console`. La acción `undiscard` en ActiveAdmin se triagea como follow-up separado.
2. ~~**Vista de "Vehículos archivados" para el Carrier**~~ — **OUT OF SCOPE.** El listado del Carrier oculta los descartados (AC5/AC8); no se agrega pestaña / vista de archivados.
3. ~~**Estados de Shipment "en curso" (AC4)**~~ — Cerrado: scope `Shipment.in_progress` ya existe (`accepted + in_transit`). AC4 lo reusa y además extiende a `CargoOffer` no terminal (ver Q7 más arriba).
4. ~~**Cascada sobre TransportWindows**~~ — **NO cascada.** Descartar un vehículo no deshabilita implícitamente sus ventanas. AC3 bloquea cuando hay activas; AC14 bloquea la reactivación posterior. El Carrier gestiona las ventanas manualmente (US34 / US35).

## Follow-ups a triagear por separado

- **REQ-BE-NNNNN (TBD)** — Cablear acción `undiscard` en el resource ActiveAdmin para `Vehicle` (UI admin de restore). Bajo P3; alguien del equipo lo necesita la primera vez que un Carrier pida revertir una baja.
- **Migración repo-wide al gem `discard`** (no relacionada con este issue) — el dueño del repo la lidera por fuera. Incluiría retrofitear Vehicle al patrón gem cuando llegue.
