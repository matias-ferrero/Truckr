---
tag: INF-FE-00005
title: Framework de notificaciones web en tiempo real (scaffold)
priority: P2
status: ready
created: '2026-05-22'
source: manual
author: Claude Code
github_issue: 217
github_repo: tcorzo/fiuba-gestion-tp
plan: ../../../docs/features/INF/INF-FE-00005/INF-FE-00005-framework-notificaciones-web-scaffold.plan.md
labels:
- INF
- BE
- FE
- mvp
- notifications
- realtime
---

## Summary

Scaffolding de un framework de notificaciones web en tiempo real (BE + FE) que permita, en sprints posteriores, empujar al usuario eventos como cambios de estado de envío, confirmaciones de pago y nuevas ofertas, sin que cada feature reinvente su propia cañería. Este sprint entrega únicamente la infraestructura y un evento `ping` de prueba; no se cablea a ninguna feature de negocio concreta.

## Problem Statement

Hoy las features que necesitan refrescar la UI ante cambios de estado se apoyan en eventos custom de `window` (ver PR #194, `truckr:carrier-quote-updated`) y/o polling manual. Ese patrón no escala a multi-pestaña, no propaga eventos originados en background jobs ni en otros usuarios, y obliga a duplicar lógica en cada feature.

Próximos sprints introducen flujos en los que el backend necesita empujar eventos al frontend (oferta recibida por el transportista, pago confirmado al expedidor, cambio de estado de viaje, payout liberado, reseña recibida, etc.). Antes de cablear cada uno por separado, conviene fijar el transporte y el contrato genérico una sola vez.

## Decisión de transporte y delivery semantic

**Locked en [ADR-013](../../../docs/01-technical-vision/technical-vision.md#adr-013--in-app-notifications-best-effort-live-delivery-no-offline-queue)** — Action Cable + Solid Cable, best-effort live delivery, sin offline queue, sin tabla `notifications`. Esta issue **implementa** ADR-013; no lo re-discute. Alternativas evaluadas se documentan acá por trazabilidad de sprint, no como decisión abierta.

| Alternativa | Pros | Contras | Decisión |
|---|---|---|---|
| **Action Cable + Solid Cable** (default Rails 8) | Built-in en Rails 8, bidireccional, soporte de canales con suscripción autenticada, cliente oficial `@rails/actioncable`. Solid Cable usa la DB como backplane → consistente con la política "SQLite + Kamal + un solo contenedor". | Requiere upgrade de WebSocket en el proxy; Solid Cable sobre SQLite hay que verificar bajo carga (WAL + single-writer). | ✅ **Elegido**. |
| SSE (`ActionController::Live`) | Más simple, sin upgrade WS, fácil de proxyar. | Unidireccional, una conexión HTTP por tab, reconexión manual, sin canales nativos. | Rechazada por menor flexibilidad a futuro. |
| Polling cada N segundos | Cero infraestructura nueva. | UX laggy, costo de CPU/DB constante, no real-time. | Rechazada. |

**Fallback documentado**: si Solid Cable resulta problemático sobre SQLite, se cae a `async` adapter (in-memory, single-process). Esto es aceptable dado que el deploy es **un solo contenedor Kamal**; el producto es coursework académico y no se va a multi-proceso. **No** se introduce Redis ni ningún pub/sub externo: violaría la política de "sin infra externa más allá de SQLite + Kamal".

## Expected Behavior

### Backend (Rails)

1. **`ApplicationCable::Connection`** (`backend/app/channels/application_cable/connection.rb`): autentica al usuario en `#connect` leyendo el **JWT desde el query string** (`wss://…/cable?token=<jwt>`). Decodifica con `Warden::JWTAuth::UserDecoder` (mismo path que ya valida los `Authorization: Bearer` del REST API). Rechaza la conexión si el token falta, está revocado, expiró, o no resuelve a un `User`. Filtrar `token` en `config.filter_parameters` para que no aparezca en logs.
2. **`NotificationsChannel`** (`backend/app/channels/notifications_channel.rb`): suscribe al usuario autenticado a su propio stream usando el patrón idiomático de Rails `stream_for current_user` (stream name auto-derivado del `GlobalID` del User, scoped a la clase del channel — `notifications:<gid>`). Esto evita colisiones con futuros channels per-user (`PresenceChannel`, `LiveChatChannel`, etc.) que también querrían namespacing por usuario. Rechaza suscripciones anónimas (corta en `Connection#connect` — no debería llegar acá).
3. **`Notifications::Publisher`** service (`backend/app/services/notifications/publisher.rb`): único punto de entrada que el resto del código usa para emitir notificaciones. Las futuras features **no** llaman a `ActionCable.server.broadcast` directamente — pasan por el publisher para que el transporte sea intercambiable.

   **Firma:**
   ```ruby
   Notifications::Publisher.publish(user_id:, type:, payload:)
   ```

   **Contrato:**
   - `user_id` (Integer, requerido): destinatario único. No hay fan-out a múltiples usuarios en este sprint.
   - `type` (Symbol, requerido): debe pertenecer al **whitelist cerrado** en `Notifications::Type` (módulo con constantes — `Notifications::Type::PING`, etc.). El publisher levanta `Notifications::UnknownTypeError` si el `type` no está registrado. Sprint 3 ship con un único tipo: `:ping`. Cada feature futura agrega su constante acá en su PR.
   - `payload` (Hash, requerido): debe ser JSON-serializable. El publisher valida que sea un Hash y llama `payload.as_json` antes de broadcastear (no AR objects, no symbols-only keys que rompan en el cliente). Levanta `ArgumentError` si no es un Hash.

   **Emisión:**
   - **Síncrono**: el publisher resuelve `user = User.find(user_id)` y llama `NotificationsChannel.broadcast_to(user, message)` (pattern idiomático de Rails — scope al GlobalID del User dentro del namespace del channel, evita colisiones con futuros channels per-user). **No** hay `BroadcastJob.perform_later` en este sprint — es una refactorización trivial (one-class change) cuando aparezca el primer caller en hot path. La firma externa del publisher sigue siendo `publish(user_id:, ...)`: el caller no sabe ni le importa que internamente se cargue el User.
   - El mensaje broadcasteado es `{ type: <string>, payload: <hash>, emitted_at: <iso8601 server-time> }`. **`emitted_at` lo inyecta el publisher**, nunca el caller (clock authority en server).
   - **No** se persiste la notificación: no hay tabla `notifications`, no hay `id` server-side. Si el frontend necesita dedup, genera client-side IDs al recibir.
4. **Endpoint de prueba** `POST /api/dev/notifications/ping`:
   - **Gate**: route constraint en `config/routes.rb` — `constraints -> { Rails.env.development? || Rails.env.test? } do ... end`. La ruta literalmente **no existe** en production (no aparece en `rails routes`), no se llega al controller. 404 en prod via routing standard. Esto es más seguro que un `before_action` (no hay risk de bypass por herencia).
   - **Establece la convención `/api/dev/*`** como home canónico de endpoints debug futuros (`force-expire offers`, `replay job`, etc.) — single grep target para "qué rutas dev existen".
   - **Auth**: requiere `Authorization: Bearer <jwt>` válido (mismo Devise+JWT que el resto del API). Broadcastea al `current_user`.
   - **Body opcional**: acepta `{ message: <string> }` (strong-params); default `{}` si ausente. Permite que el dev confirme el roundtrip del payload contra el FE registry sin tener que editar código.
   - **Mensaje broadcasteado**: `{ type: "ping", payload: { message: <string|null>, at: <iso8601> }, emitted_at: <iso8601> }`. El `emitted_at` lo inyecta el `Notifications::Publisher` (server clock), como cualquier otro caller.
   - **Response**: `204 No Content` en éxito, `401` sin JWT válido.
5. **Solid Cable + `cable.yml`**: el scaffold no tiene Action Cable configurado (no existe `backend/config/cable.yml`, no está el gem `solid_cable`). Esta issue debe:
   - Agregar `gem "solid_cable"` al `Gemfile`.
   - Crear `backend/config/cable.yml` con **`solid_cable` adapter en `development` y `production`**, y el **adapter `test` standard de Rails en `test`** (necesario para que `have_broadcasted_to` y `ActionCable::TestHelper` funcionen — el adapter `test` captura broadcasts in-memory para inspección).
   - Correr `bin/rails solid_cable:install` para generar y aplicar la migración de la tabla `solid_cable_messages`; commitear `db/schema.rb` actualizado.
   - Configurar `config.solid_cable.connects_to = { database: { writing: :primary } }` (usa la DB primaria; no se introduce una DB separada para cable — consistente con la política SQLite-only).
   - Fallback a `async` documentado arriba si Solid Cable resulta problemático sobre SQLite (decisión a tomar durante implementación si aparecen issues, no en este sprint).
6. **Tests** (RSpec):
   - Channel spec: subscribe exitoso autenticado, rechazo anónimo, broadcast recibido vía `have_broadcasted_to`.
   - Request spec: `POST /api/dev/notifications/ping` en dev/test responde 204 y broadcastea; en production responde 404.
   - Service spec: `Notifications::Publisher.publish` valida `user_id`, `type` (whitelist), `payload` (Hash).

### Frontend (React + Deno)

1. **Cliente `@rails/actioncable`** declarado en `frontend/deno.json` (o equivalente al patrón existente de deps npm).
2. **`NotificationsProvider`** (`frontend/src/components/notifications/NotificationsProvider.tsx`): React context que abre la conexión al iniciar sesión, mantiene la suscripción activa al canal personal, y la cierra al cerrar sesión. Expone un hook `useNotifications()` que retorna `{ notifications, dismiss, clear }`.
3. **`NotificationsToast`** primitivo: toast en una esquina que aparece ante un evento entrante. **Copy NO hardcodeado en JSX** — se extiende el patrón existente `frontend/src/landingContent.ts` (carve-out de CLAUDE.md como "prototype-stage i18n bundle hasta que aterrice una librería i18n real"). Estructura sugerida:

   ```ts
   // landingContent.ts
   notifications: {
       ping: { title: string; body: string };
       // futuros tipos se agregan acá tipados
   }
   ```

   Un registry `Record<NotificationType, (payload: unknown) => { title: string; body: string }>` mapea cada `type` recibido a una función que lee de `landingContent.notifications[type]` y formatea el payload (interpolación simple). En sprint 3 el registry sólo registra `ping`; cada feature futura registra el suyo en el PR que la introduce.

   **No** se instala una librería i18n real (`react-i18next`, `react-intl`, etc.) en esta issue — esa es una decisión separada que merece su propio `INF-FE` con ADR (lazy-loading, fallback chain, namespace structure). Cuando aterrice, el bundle se convierte en la semilla del archivo de traducciones; el costo de migración es "renombrar keys + cambiar call site", trivial.
4. **`NotificationsBadge`** primitivo: contador de no-leídas, click abre un panel con el historial de la sesión actual. Patrón consistente con el badge de ofertas pendientes del header (PR #194).
5. **Reconexión + auth refresh**: el cliente Action Cable maneja reconexión automática. La URL del cable se construye dinámicamente con el JWT actual desde el store de auth (no hardcoded en el `createConsumer` inicial). Tras un refresh del JWT, la próxima reconexión debe agarrar el token nuevo — verificar que un 401 en el upgrade fuerza al provider a re-fetchear el token y reconectar (no entrar en loop infinito si el refresh también falla → degradar a "disconnected" silenciosamente y dejar que el usuario re-logueé).
6. **Tests**:
   - Vitest: provider (mockeando la subscription), badge counts, toast render, hook `useNotifications`.
   - Playwright e2e: login → trigger `POST /api/dev/notifications/ping` → ver toast aparecer.
7. **DESIGN.md fit + UX details deferred a `/critique`**: esta issue **no fija** posición, motion, stack depth, auto-dismiss timing del toast, ni layout del panel del badge. Esas decisiones se resuelven durante implementación vía el quality gate de CLAUDE.md (`/critique` → `/polish` → `/audit`) contra los tokens existentes de DESIGN.md y el patrón del header badge de PR #194. Cualquier cambio futuro de UX en estos primitivos pasa por DESIGN.md, **no** vuelve a esta issue.

### Glossary

Las entradas en `docs/05-appendices/glossary.md` se agregan **en el mismo PR** de implementación (no en otro PR posterior — la convención del repo es "glossary first"):

- **`Notificación`** — `— (transient, not persisted)` — evento empujado por el backend al frontend de un usuario en tiempo real vía Action Cable. Historial session-only en el cliente.
- **`Tipo de notificación`** — `— (Ruby module: Notifications::Type)` — discriminador cerrado del payload. Whitelist Ruby compartido entre BE emisor y FE registry.

Términos rechazados explícitamente (no agregar al glossary):
- `Notification Channel` — colisión con el primitivo Action Cable; futuras "channels" (email/push/sms) podrían reciclar el término.
- `Notifications Provider` — implementación interna del frontend; no es vocabulario de dominio (mismo criterio que `AuthProvider`, `RouterProvider`).

## Semántica de entrega (importante para futuros consumidores)

**Las notificaciones son best-effort live delivery, exclusivamente.**

- Si el usuario destinatario **no tiene WebSocket abierto** en el momento del `publish`, el broadcast se pierde en el aire — Solid Cable no hace store-and-forward.
- **No hay offline queue.** Cuando el usuario reconecta, **no recibe** las notificaciones emitidas durante su desconexión.
- **No hay vista de "notificaciones perdidas"** ni endpoint para reclamar el historial server-side. El historial sólo existe en el cliente, sólo durante la sesión.

**Implicación para sprint 4+ (cada consumer feature debe respetar):**

- El framework de notificaciones es un **acelerador de UX**, no una fuente de verdad. Cada feature que emita notificaciones **debe** además exponer un path REST/poll para que el cliente reconstruya el mismo estado al recargar o al reconectar.
- Ejemplo: "notificar al shipper cuando se confirma el pago" — si el shipper estaba con la tab cerrada, debe poder ver el estado "pago confirmado" al volver a abrir la app vía un `GET /api/payments/:id` regular. La notificación push no es el canal canónico, es el atajo en vivo.
- Quien quiera semántica de entrega garantizada (ack flow, retry, persistencia, "marcar como leída" server-side) debe escribir **otro** issue / framework — éste no lo provee y no se va a extender en esa dirección sin un nuevo ADR.

## Out of Scope (explícito)

- No se cablea ninguna feature de negocio (cambios de estado de envío, pago confirmado, oferta recibida). Cada uno es un REQ-BE/FE separado en sprints posteriores.
- No hay persistencia de notificaciones en una tabla `notifications`: el historial es **session-only** en el frontend.
- No hay `notifications_read_at` ni "marcar como leída" del lado server.
- **No hay offline queue ni store-and-forward.** Si el usuario está desconectado en el momento del `publish`, la notificación se pierde (best-effort live delivery). Ver "Semántica de entrega" arriba.
- No se introduce Redis, ni pub/sub externo, ni un servicio WebSocket separado.
- No se escribe un ADR aparte: la decisión de transporte vive en el body de este issue. Si la discusión escala a debate arquitectónico real, se promueve a ADR.
- No se instala una librería i18n real (`react-i18next`, etc.) en este sprint — es una decisión separada con su propio `INF-FE` y ADR cuando aterrice. Se extiende el patrón `landingContent.ts` (carve-out de CLAUDE.md).
- **No** se migra el evento custom `truckr:carrier-quote-updated` (introducido en PR #194) al nuevo framework. Esa migración se triagea como un `REF-FE` separado **después** de que tanto este issue como PR #194 estén mergeados — pre-filar ahora rota el spec si PR #194 cambia (especialmente con la rebase de REF-BE-00002 pendiente).

## Technical Notes

- **SQLite + Solid Cable**: Solid Cable usa la DB para pub/sub. Verificar bajo concurrencia baja del MVP que no rompe WAL ni el single-writer. Si rompe → fallback a `async` (documentado arriba).
- **Kamal + proxy**: el proxy debe permitir upgrade WS al contenedor de Rails. Overlapa con el trabajo de deploy de `#202` (OIDC); flagged como dependencia, no como bloqueante.
- **Auth WS = JWT en query string** (decisión locked, ver Expected Behavior BE #1). Browsers no permiten custom headers en `new WebSocket(url)`, así que el patrón cookie-de-Devise no aplica acá — la app usa `devise-jwt` (ADR-011) sin sesión de cookies. El JWT viaja como `?token=<jwt>` y `ApplicationCable::Connection#connect` lo decodifica con `Warden::JWTAuth::UserDecoder`. **Filtrar `token` en `Rails.application.config.filter_parameters`** para no leakearlo en logs.
- **PR title**: tipo conventional al inicio, **sin** prefijo `[INF-FE-00005]`. El TAG va en el body con `Tracks #<issue-number>`.

## Related

- **ADR-013** (`docs/01-technical-vision/technical-vision.md`) — In-app notifications best-effort live delivery. Contrato de delivery y transporte que esta issue implementa.
- **ADR-011** — Devise + devise-jwt. La auth del WS reusa el mismo decoder.
- **ADR-002** — Rails 8 API + SQLite. Solid Cable usa la primary DB.
- PR #194 — patrón de eventos custom `truckr:carrier-quote-updated` y badge del header de ofertas pendientes. Este framework eventualmente subsume esos eventos custom (vía un REF-FE separado, post-merge — ver Out of Scope).
- `#202` / `INF-INFRA-00004` — automation de deploy con OIDC, afecta la config del proxy (upgrade headers WS). No es bloqueante.
- `CLAUDE.md` — language policy, database policy (SQLite forever), pre-PR quality gate.
- `docs/05-appendices/glossary.md` — terms source-of-truth. Esta issue agrega `Notificación` y `Tipo de notificación`.

## Acceptance Criteria

- [ ] La aplicación expone una conexión Action Cable autenticada por usuario.
- [ ] Existe un servicio `Notifications::Publisher` que toda futura feature usará para emitir notificaciones — los consumidores no llaman a `ActionCable.server.broadcast` directamente.
- [ ] Un endpoint de desarrollo `POST /api/dev/notifications/ping` permite emitir un evento de prueba al usuario autenticado (Bearer JWT). La ruta está gated vía route constraint en `routes.rb` y **no existe** en production (404 routing-level, no `before_action`). Acepta body opcional `{ message }`. Responde 204 en éxito, 401 sin JWT válido.
- [ ] El frontend abre la suscripción al canal personal del usuario al iniciar sesión y la cierra al cerrar sesión.
- [ ] Un componente `NotificationsToast` renderiza notificaciones entrantes leyendo el copy desde entries tipados en `frontend/src/landingContent.ts` (extensión del bundle existente — **NO** literales hardcoded en JSX). No se instala una librería i18n real en este sprint.
- [ ] Un componente `NotificationsBadge` muestra el contador de notificaciones no leídas y permite consultar el historial reciente de la sesión.
- [ ] La elección de transporte y la semántica de delivery se implementan según **ADR-013** (`docs/01-technical-vision/technical-vision.md`): Action Cable + Solid Cable, best-effort live, sin tabla `notifications`, sin offline queue.
- [ ] No se cablea ninguna feature concreta (cambios de estado de envío, confirmación de pago, oferta recibida) en este sprint — eso se hace en issues separados posteriores.
- [ ] La autenticación del WebSocket usa el JWT pasado por query string (`?token=...`), decodificado con `Warden::JWTAuth::UserDecoder` en `ApplicationCable::Connection#connect`; conexiones sin token o con token inválido/revocado/expirado son rechazadas. El parámetro `token` está filtrado de logs.
- [ ] La reconexión automática usa el JWT vigente del store de auth (no uno cacheado al iniciar la sesión) y degrada limpiamente si el refresh del token falla.
- [ ] Los tests cubren: suscripción autenticada exitosa, rechazo de suscripción anónima, emisión vía publisher y recepción en el frontend (mockeado).
- [ ] Identifiers, routes, params en inglés; copy de UI vía `landingContent.ts` (no hardcoded JSX); error messages del backend vía `I18n.t(...)` (config/locales) — nunca strings hardcoded.
