# INF-FE-00005: Framework de notificaciones web en tiempo real (scaffold)

| Field | Value |
|-------|-------|
| **Tag** | INF-FE-00005 |
| **Title** | Framework de notificaciones web en tiempo real (scaffold) |
| **Priority** | P2 |
| **Status** | READY |
| **Created** | 2026-05-22 |
| **Updated** | 2026-05-22 |
| **Author** | Claude Code |
| **Depends On** | None bloqueante. Overlapa con `#202` / `INF-INFRA-00004` (Kamal proxy WS upgrade) — no bloqueante en local. PR #194 mergeado o no — independiente. |
| **Decision Doc** | N/A — decisiones de transporte y delivery semantic ya cerradas en [ADR-013](../../../01-technical-vision/technical-vision.md#adr-013--in-app-notifications-best-effort-live-delivery-no-offline-queue). |
| **Selected Approach** | Action Cable + Solid Cable, best-effort live delivery, sin offline queue (ADR-013). |
| **GitHub Issue** | [#217](https://github.com/tcorzo/fiuba-gestion-tp/issues/217) |

---

## 1. Problem Statement

Hoy las features que necesitan refrescar la UI ante cambios de estado se apoyan en eventos custom de `window` (`truckr:carrier-quote-updated` de PR #194) y/o polling manual. Ese patrón no escala a multi-pestaña, no propaga eventos originados en background jobs ni en otros usuarios, y obliga a duplicar lógica en cada feature.

Sprints siguientes introducen flujos en los que el backend necesita empujar eventos al frontend (oferta recibida, pago confirmado, cambio de estado de envío, payout liberado, reseña recibida). Antes de cablear cada uno por separado, este sprint fija de una sola vez **el transporte (Action Cable + Solid Cable), el contrato del publisher, y los primitivos de UI**, sin tocar ninguna feature de negocio.

El sprint 3 entrega exclusivamente la infraestructura + un evento de prueba `:ping` end-to-end. Los consumers reales son issues separados en sprints 4+.

---

## 2. Solution Design

Implementación 1:1 de **ADR-013**. No se re-discuten decisiones de transporte ni de delivery semantic.

### 2.1 Contrato externo (lo que las futuras features ven)

```ruby
Notifications::Publisher.publish(user_id:, type:, payload:)
```

- `type` ∈ whitelist cerrado `Notifications::Type` (Ruby module con constantes). Sprint 3 registra una sola constante: `:ping`.
- `payload` Hash JSON-serializable. Server inyecta `emitted_at` ISO-8601.
- Síncrono — el publisher resuelve `User.find(user_id)` y llama `NotificationsChannel.broadcast_to(user, message)`. Refactor a `BroadcastJob.perform_later` es one-class change cuando aparezca el primer caller en hot path; **no** se hace en este sprint.
- Best-effort live delivery. Si el destinatario no está conectado al WS, el broadcast se pierde. No hay tabla `notifications`, no hay `id` server-side, no hay offline queue. Cada futura feature que emita notificaciones debe además exponer un path REST/poll para reconstruir estado al recargar (ADR-013).

### 2.2 Transporte

- **Backend**: Action Cable + `solid_cable` gem en `development` + `production`; adapter `test` standard de Rails en `test` (necesario para `have_broadcasted_to`).
- **Backplane**: tabla `solid_cable_messages` en la primary DB SQLite (consistente con [política SQLite-forever en CLAUDE.md](../../../../CLAUDE.md#database-policy-utmost-importance)). `config.solid_cable.connects_to = { database: { writing: :primary } }`.
- **Fallback documentado**: si Solid Cable rompe bajo concurrencia WAL/single-writer durante implementación, se cae a `async` adapter (in-process). Es aceptable: deploy es **un solo contenedor Kamal**. **No** se introduce Redis ni pub/sub externo.

### 2.3 Auth WS

JWT en query string (`wss://…/cable?token=<jwt>`). Browsers no permiten headers custom en `new WebSocket(url)` y la app usa `devise-jwt` sin cookies (ADR-011). `ApplicationCable::Connection#connect` decodifica con `Warden::JWTAuth::UserDecoder` (mismo decoder que ya valida el `Authorization: Bearer` del REST). `token` se filtra de logs vía `config.filter_parameters`.

### 2.4 Stream naming

`stream_for current_user` (NOT `stream_from "user:#{id}"`). Patrón idiomático de Rails: stream name auto-derivado del `GlobalID` del User, scoped a la clase del channel (`notifications:<gid>`). Evita colisiones con futuros `PresenceChannel`, `LiveChatChannel`, etc.

### 2.5 Endpoint dev de prueba

`POST /api/dev/notifications/ping` — gated vía **route constraint** (`constraints -> { Rails.env.development? || Rails.env.test? }`), no vía `before_action` (más seguro: la ruta literalmente no existe en prod). Establece la convención `/api/dev/*` como home de endpoints debug futuros. Auth Bearer JWT; broadcastea al `current_user`; body opcional `{ message }`; 204 OK, 401 sin JWT.

### 2.6 Frontend

- Cliente `@rails/actioncable` via `frontend/deno.json` `imports` (mismo patrón que el resto de deps `npm:`).
- `NotificationsProvider` (React context) abre la conexión post-login, mantiene la suscripción, la cierra en logout. Hook `useNotifications()` → `{ notifications, dismiss, clear }`.
- `NotificationsToast` y `NotificationsBadge` primitivos. **Copy via `landingContent.ts`** (carve-out de CLAUDE.md como prototype-stage i18n bundle). Registry `Record<NotificationType, (payload) => { title, body }>` lee de `landingContent.notifications[type]`. **No** se instala `react-i18next`, `react-intl` u otra lib i18n — esa es una decisión separada con su propio INF-FE + ADR.
- Reconexión automática agarra el JWT vigente del store de auth (no cacheado). Si refresh del JWT falla en la reconexión → degradar a "disconnected" silenciosamente (no infinite-reconnect loop).
- UX details (toast position, motion, stack depth, auto-dismiss timing, layout del badge panel) **deferidos al quality gate** (`/critique` → `/polish` → `/audit`) contra los tokens de DESIGN.md y el badge del header de PR #194. **No** se fijan en esta issue.

### 2.7 Glossary

Se agregan en el **mismo PR** de implementación (convención repo "glossary first"):

- `Notificación` — `— (transient, not persisted)` — evento empujado por el BE al FE de un usuario en tiempo real vía Action Cable. Historial session-only en el cliente.
- `Tipo de notificación` — `— (Ruby module: Notifications::Type)` — discriminador cerrado del payload. Whitelist Ruby compartido entre BE emisor y FE registry.

Términos **rechazados** (no agregar): `Notification Channel`, `Notifications Provider`.

---

## 3. Implementation Tasks

Secuenciado por dependencia. BE foundation primero (no depende del FE); FE foundation arranca recién cuando el endpoint dev existe para integrar e2e.

| #   | Task                                                              | Status  | Files                                                                                                                                            |
| --- | ----------------------------------------------------------------- | ------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1   | Crear branch `feature/INF-FE-00005-notifications-framework`       | Pending | —                                                                                                                                                |
| 2   | Agregar `gem "solid_cable"` y `bundle install`                    | Pending | `backend/Gemfile`, `backend/Gemfile.lock`                                                                                                        |
| 3   | `bin/rails solid_cable:install` + commit migration + schema       | Pending | `backend/db/migrate/*_create_solid_cable_messages.rb`, `backend/db/schema.rb`                                                                    |
| 4   | Crear `cable.yml` (solid_cable en dev+prod, test adapter en test) | Pending | `backend/config/cable.yml`                                                                                                                       |
| 5   | Wire Solid Cable a primary DB + filtrar `token` en logs           | Pending | `backend/config/application.rb` (o `config/environments/*.rb`)                                                                                   |
| 6   | Implementar `ApplicationCable::Connection` con JWT-from-query     | Pending | `backend/app/channels/application_cable/connection.rb`, `backend/app/channels/application_cable/channel.rb`                                      |
| 7   | Implementar `NotificationsChannel` con `stream_for current_user`  | Pending | `backend/app/channels/notifications_channel.rb`                                                                                                  |
| 8   | Crear módulo `Notifications::Type` (whitelist cerrado)            | Pending | `backend/app/services/notifications/type.rb`                                                                                                     |
| 9   | Crear `Notifications::Publisher` + `UnknownTypeError`             | Pending | `backend/app/services/notifications/publisher.rb`, `backend/app/services/notifications/unknown_type_error.rb`                                    |
| 10  | Ruta + controller `POST /api/dev/notifications/ping`              | Pending | `backend/config/routes.rb`, `backend/app/controllers/api/dev/notifications_controller.rb`                                                        |
| 11  | RSpec: channel spec (subscribe / reject anon / broadcasted)       | Pending | `backend/spec/channels/application_cable/connection_spec.rb`, `backend/spec/channels/notifications_channel_spec.rb`                              |
| 12  | RSpec: service spec (Publisher whitelist, payload coercion)       | Pending | `backend/spec/services/notifications/publisher_spec.rb`                                                                                          |
| 13  | RSpec: request spec ping endpoint (204 dev/test, 401 sin JWT)     | Pending | `backend/spec/requests/api/dev/notifications_spec.rb`                                                                                            |
| 14  | Agregar `@rails/actioncable` a `frontend/deno.json` `imports`     | Pending | `frontend/deno.json`                                                                                                                             |
| 15  | Extender `landingContent.ts` con `notifications.ping`             | Pending | `frontend/src/landingContent.ts`                                                                                                                 |
| 16  | `NotificationsProvider` + `useNotifications` hook                 | Pending | `frontend/src/components/notifications/NotificationsProvider.tsx`                                                                                |
| 17  | `notificationsRegistry` (typed registry)                          | Pending | `frontend/src/components/notifications/notificationsRegistry.ts`                                                                                 |
| 18  | `NotificationsToast` primitivo                                    | Pending | `frontend/src/components/notifications/NotificationsToast.tsx`                                                                                   |
| 19  | `NotificationsBadge` primitivo (reusa estilo PR #194 header)      | Pending | `frontend/src/components/notifications/NotificationsBadge.tsx`                                                                                   |
| 20  | Wire `NotificationsProvider` al app shell donde vive auth state   | Pending | `frontend/src/App.tsx` (o equivalente)                                                                                                           |
| 21  | Vitest: provider + badge + toast + hook                           | Pending | `frontend/src/components/notifications/NotificationsProvider.test.tsx`, `NotificationsBadge.test.tsx`, `NotificationsToast.test.tsx`             |
| 22  | Playwright e2e: login → ping → toast aparece                      | Pending | `frontend/tests-e2e/notifications.spec.ts`                                                                                                       |
| 23  | Glossary: agregar `Notificación` + `Tipo de notificación`         | Pending | `docs/05-appendices/glossary.md`                                                                                                                 |
| 24  | Pre-PR quality gate: `/critique` → `/polish` → `/audit`           | Pending | `frontend/src/components/notifications/*`                                                                                                        |
| 25  | `just lint`, `just frontend-test-coverage`, `just frontend-test-e2e`, `just backend-test` (todo verde) | Pending | —                                                                       |
| 26  | Abrir PR: título conventional sin `[TAG]`, body con `Tracks #217`, `gh pr create --assignee @me` | Pending | —                                                                                                 |

---

## 4. Code Changes

### 4.1 File: `backend/Gemfile`

**Purpose**: Añadir el adapter Solid Cable. Va junto a los otros adapters Solid (cache, queue) que ya están en el Gemfile.

```ruby
# Use the database-backed adapters for Rails.cache, Active Job, and Action Cable
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"
```

### 4.2 File: `backend/config/cable.yml` (nuevo — el scaffold no tiene cable.yml)

**Purpose**: Action Cable adapter por env. Dev/prod usan Solid Cable sobre la primary DB. Test usa el adapter `test` (Rails default in-memory, requerido por `ActionCable::TestHelper#have_broadcasted_to`).

```yaml
development:
  adapter: solid_cable
  connects_to:
    database:
      writing: primary
  polling_interval: 0.1.seconds
  message_retention: 1.day

test:
  adapter: test

production:
  adapter: solid_cable
  connects_to:
    database:
      writing: primary
  polling_interval: 0.1.seconds
  message_retention: 1.day
```

> ⚠️ `bin/rails solid_cable:install` instala la migración pero **no escribe `cable.yml`** en proyectos preexistentes — escribirlo manualmente.

### 4.3 File: `backend/config/application.rb` (modificar)

**Purpose**: Filtrar `token` de logs (no leakear el JWT que viaja en el query string del WS) y wire Solid Cable explícito a primary DB.

```ruby
# Dentro de class Application < Rails::Application
config.filter_parameters << :token
# config.solid_cable.connects_to declarado en cable.yml; no hace falta override acá
```

### 4.4 File: `backend/app/channels/application_cable/channel.rb` (nuevo si no existe)

**Purpose**: Base channel class (los generadores de Rails 8 la dejan vacía).

```ruby
module ApplicationCable
  class Channel < ActionCable::Channel::Base
  end
end
```

### 4.5 File: `backend/app/channels/application_cable/connection.rb` (nuevo)

**Purpose**: Autentica al usuario en `#connect` leyendo el JWT del query string. Rechaza si está ausente, inválido, revocado o expirado. Reusa `Warden::JWTAuth::UserDecoder` — mismo decoder que valida el REST API.

```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      token = request.params[:token]
      reject_unauthorized_connection if token.blank?

      user, _payload = Warden::JWTAuth::UserDecoder.new.call(token, :user, nil)
      user || reject_unauthorized_connection
    rescue Warden::JWTAuth::Errors::NilUser,
           JWT::DecodeError,
           JWT::ExpiredSignature => _e
      reject_unauthorized_connection
    end
  end
end
```

### 4.6 File: `backend/app/channels/notifications_channel.rb` (nuevo)

**Purpose**: Suscribe al user autenticado a su stream personal usando el patrón idiomático `stream_for current_user` (no `stream_from "user:#{id}"`). Stream name auto-scoped al GlobalID del User dentro del namespace del channel.

```ruby
class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_for current_user
  end
end
```

### 4.7 File: `backend/app/services/notifications/type.rb` (nuevo)

**Purpose**: Whitelist cerrado de tipos. Cada futura feature agrega su constante en su PR.

```ruby
module Notifications
  module Type
    PING = :ping

    ALL = [PING].freeze

    def self.registered?(type)
      ALL.include?(type)
    end
  end
end
```

### 4.8 File: `backend/app/services/notifications/unknown_type_error.rb` (nuevo)

```ruby
module Notifications
  class UnknownTypeError < StandardError; end
end
```

### 4.9 File: `backend/app/services/notifications/publisher.rb` (nuevo)

**Purpose**: Único punto de entrada para emitir notificaciones. Valida `user_id`, `type` (whitelist), `payload` (Hash). Inyecta `emitted_at` server-side. Llama `NotificationsChannel.broadcast_to(user, message)`.

```ruby
module Notifications
  class Publisher
    def self.publish(user_id:, type:, payload:)
      unless Notifications::Type.registered?(type)
        raise Notifications::UnknownTypeError, "Unknown notification type: #{type.inspect}"
      end

      raise ArgumentError, "payload must be a Hash" unless payload.is_a?(Hash)

      user = User.find(user_id)
      message = {
        type: type.to_s,
        payload: payload.as_json,
        emitted_at: Time.current.iso8601
      }

      NotificationsChannel.broadcast_to(user, message)
    end
  end
end
```

### 4.10 File: `backend/config/routes.rb` (modificar)

**Purpose**: Agregar la ruta dev gated. Convención `/api/dev/*` como home de endpoints debug futuros.

```ruby
# Dentro de `namespace :api do … end`, al lado de las otras rutas:
constraints -> { Rails.env.development? || Rails.env.test? } do
  namespace :dev do
    post "notifications/ping", to: "notifications#ping"
  end
end
```

Resultante: `POST /api/dev/notifications/ping`.

### 4.11 File: `backend/app/controllers/api/dev/notifications_controller.rb` (nuevo)

**Purpose**: Endpoint dev para confirmar el roundtrip del framework. Requiere JWT (mismo Devise+JWT que el resto del API). 204 success, 401 sin JWT válido. Body opcional `{ message }`.

```ruby
module Api
  module Dev
    class NotificationsController < ApplicationController
      before_action :authenticate_user!

      def ping
        Notifications::Publisher.publish(
          user_id: current_user.id,
          type: Notifications::Type::PING,
          payload: {
            message: params[:message].presence,
            at: Time.current.iso8601
          }
        )

        head :no_content
      end
    end
  end
end
```

> Verificar el nombre del `before_action` contra `ApplicationController` actual (`authenticate_user!` es el default de Devise; el repo puede tener un wrapper custom — Fer: chequear `backend/app/controllers/api/auth_controller.rb` u otro request spec antes de copiar).

### 4.12 File: `backend/spec/channels/application_cable/connection_spec.rb` (nuevo)

**Purpose**: Conexión exitosa con JWT válido; rechazo sin token; rechazo con token inválido/expirado. Usa `Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first` para mintear el token (mismo patrón que `backend/spec/requests/api/auth_spec.rb`).

```ruby
require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:user) { create(:user) }
  let(:token) { Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first }

  it "accepts a connection with a valid JWT in the query string" do
    connect "/cable?token=#{token}"
    expect(connection.current_user).to eq(user)
  end

  it "rejects a connection with no token" do
    expect { connect "/cable" }.to have_rejected_connection
  end

  it "rejects a connection with an invalid token" do
    expect { connect "/cable?token=invalid" }.to have_rejected_connection
  end
end
```

### 4.13 File: `backend/spec/channels/notifications_channel_spec.rb` (nuevo)

```ruby
require "rails_helper"

RSpec.describe NotificationsChannel, type: :channel do
  let(:user) { create(:user) }

  before { stub_connection current_user: user }

  it "subscribes the user to their personal stream" do
    subscribe
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_for(user)
  end

  it "broadcasts a message to the user via the publisher" do
    expect {
      Notifications::Publisher.publish(
        user_id: user.id, type: :ping, payload: { message: "hi" }
      )
    }.to have_broadcasted_to(user).from_channel(NotificationsChannel)
  end
end
```

### 4.14 File: `backend/spec/services/notifications/publisher_spec.rb` (nuevo)

Casos a cubrir:
- `:ping` registrado broadcastea correctamente.
- Type fuera del whitelist → `Notifications::UnknownTypeError`.
- Payload no-Hash → `ArgumentError`.
- Payload con symbols/AR coercion → `as_json` aplicado, salida JSON-clean.
- `emitted_at` ISO-8601 presente en el mensaje broadcasteado.

### 4.15 File: `backend/spec/requests/api/dev/notifications_spec.rb` (nuevo)

Casos:
- `POST /api/dev/notifications/ping` con JWT → 204, broadcastea al `current_user`.
- Sin Authorization header → 401.
- En env production, la ruta no existe (404) — verificar via `Rails.application.routes.recognize_path` o un test con `RAILS_ENV=production` stub.

### 4.16 File: `frontend/deno.json` (modificar)

**Purpose**: Declarar `@rails/actioncable` siguiendo el patrón existente `npm:<pkg>@<ver>`.

```jsonc
"imports": {
  // … existing …
  "@rails/actioncable": "npm:@rails/actioncable@8.0.0"
}
```

### 4.17 File: `frontend/src/landingContent.ts` (modificar)

**Purpose**: Extender el bundle tipado existente con la entrada `notifications`. Esto **es** el path locked de i18n para este sprint (carve-out de CLAUDE.md).

```ts
// Agregar al objeto exportado, tipado en su union:
notifications: {
  ping: {
    title: "Ping recibido",
    body: "El framework de notificaciones está funcionando."
  }
  // futuros tipos se agregan acá tipados (ej: shipmentStateChanged, paymentConfirmed, …)
}
```

### 4.18 File: `frontend/src/components/notifications/notificationsRegistry.ts` (nuevo)

**Purpose**: Mapeo cerrado `NotificationType → (payload) => { title, body }`. Cada feature futura registra su entry acá en el PR que la introduce.

```ts
import { landingContent } from "../../landingContent";

export type NotificationType = "ping";

export interface NotificationView {
  title: string;
  body: string;
}

type Renderer = (payload: unknown) => NotificationView;

export const notificationsRegistry: Record<NotificationType, Renderer> = {
  ping: (_payload) => ({
    title: landingContent.notifications.ping.title,
    body: landingContent.notifications.ping.body
  })
};
```

### 4.19 File: `frontend/src/components/notifications/NotificationsProvider.tsx` (nuevo)

**Purpose**: React context. Abre el consumer en login, mantiene la suscripción, la cierra en logout. Expone `useNotifications()` → `{ notifications, dismiss, clear }`. La URL del cable se construye dinámicamente con el JWT vigente del store de auth (no cacheado).

Detalles a respetar durante implementación:
- Si el `createConsumer` recibe 401 en el upgrade → re-fetch del token → reintentar **una vez**. Si el retry también falla → degradar a "disconnected" silenciosamente (no infinite loop). Caso cubierto como test explícito (Task #21).
- Notifications array session-only, capped a un límite razonable (ej. 50) — no persistencia.

### 4.20 File: `frontend/src/components/notifications/NotificationsToast.tsx` (nuevo)

**Purpose**: Toast primitivo. Lee del registry, no hardcodea copy.

> UX defaults (posición, motion, auto-dismiss, stack depth) **deferidos al quality gate** — Task #24.

### 4.21 File: `frontend/src/components/notifications/NotificationsBadge.tsx` (nuevo)

**Purpose**: Badge con contador de no-leídas + panel del historial de la sesión. **Reusa el patrón visual del header badge de PR #194** — no inventar estilo nuevo.

### 4.22 File: `frontend/tests-e2e/notifications.spec.ts` (nuevo)

**Purpose**: Playwright e2e — login → llamar `POST /api/dev/notifications/ping` desde la página → assertar que el toast aparece.

### 4.23 File: `docs/05-appendices/glossary.md` (modificar)

Agregar las dos entradas locked (Sección "Decisión de transporte y delivery semantic" del issue):
- `Notificación` — `— (transient, not persisted)`
- `Tipo de notificación` — `— (Ruby module: Notifications::Type)`

---

## 5. Testing

### Unit Tests (RSpec — backend)

- `ApplicationCable::Connection`:
  - Conexión con JWT válido → `current_user` resuelto.
  - Sin token → `have_rejected_connection`.
  - Token inválido / expirado / revocado → `have_rejected_connection`.
- `NotificationsChannel`:
  - Subscribe autenticado → stream confirmado, `have_stream_for(user)`.
  - `Notifications::Publisher.publish` con el user → `have_broadcasted_to(user).from_channel(NotificationsChannel)`.
- `Notifications::Publisher`:
  - Type whitelisted → broadcastea.
  - Type no whitelisted → `Notifications::UnknownTypeError`.
  - Payload no-Hash → `ArgumentError`.
  - `emitted_at` ISO-8601 inyectado server-side (no del caller).
  - `payload.as_json` aplicado a inputs con symbols/AR objects.

### Request Tests (RSpec — backend)

- `POST /api/dev/notifications/ping`:
  - Con JWT en dev/test → 204, broadcastea al `current_user`.
  - Sin Authorization → 401.
  - Body opcional `{ message }` → presente en el payload broadcasteado.
  - En production, la ruta no existe (verificar via routes recognition stub).

### Vitest (frontend)

- `NotificationsProvider`:
  - Abre subscription post-login (mock del consumer).
  - Cierra subscription en logout.
  - Recibir un mensaje agrega al array de notifications.
  - 401 en upgrade → re-fetch token → reintenta una vez. Segundo fallo → estado "disconnected", no loop.
- `NotificationsBadge`: contador refleja la cantidad de no-leídas; click abre el panel.
- `NotificationsToast`: render con título + body del registry.
- `notificationsRegistry`: cada `NotificationType` mapea a una entry válida de `landingContent.notifications`.
- `useNotifications` hook: contrato `{ notifications, dismiss, clear }`.

### E2E (Playwright)

- `notifications.spec.ts`: login → `POST /api/dev/notifications/ping` (via `request.post` desde la página o un click en un dev-tools button) → assertar toast visible con título + body del registry.

### Quality gate (CLAUDE.md § Pre-PR UI quality gate)

- `/critique` → `/polish` → `/audit` sobre `NotificationsToast` y `NotificationsBadge`.
- `just lint` (incl. stylelint design-system enforcement).
- `just frontend-test-coverage` — debe pasar el threshold 80% (configurado en `frontend/vitest.config.ts`).
- `just frontend-test-e2e`.
- `just backend-test`.
- `just build-artifacts` no es estrictamente necesario (esta issue no toca `docs/artifacts/`), pero `just lint` corre `typstyle` igual — ejecutarlo.

---

## 6. Acceptance Criteria

Sourced 1:1 del issue (no se re-derivan):

- [ ] La aplicación expone una conexión Action Cable autenticada por usuario.
- [ ] Existe un servicio `Notifications::Publisher` que toda futura feature usará para emitir notificaciones — los consumidores no llaman a `ActionCable.server.broadcast` directamente.
- [ ] `POST /api/dev/notifications/ping` permite emitir un evento de prueba (Bearer JWT). Gated vía route constraint; **no existe** en production (404 routing-level, no `before_action`). Body opcional `{ message }`. 204 éxito, 401 sin JWT válido.
- [ ] El frontend abre la suscripción al canal personal al iniciar sesión y la cierra al cerrar sesión.
- [ ] `NotificationsToast` renderiza notificaciones leyendo copy desde entries tipados en `frontend/src/landingContent.ts` — NO literales hardcoded. **No** se instala librería i18n real en este sprint.
- [ ] `NotificationsBadge` muestra contador de no-leídas y permite consultar el historial reciente de la sesión.
- [ ] Implementación según **ADR-013**: Action Cable + Solid Cable, best-effort live, sin tabla `notifications`, sin offline queue.
- [ ] No se cablea ninguna feature concreta en este sprint.
- [ ] Auth WS = JWT en query string (`?token=...`), decodificado con `Warden::JWTAuth::UserDecoder` en `ApplicationCable::Connection#connect`; rechazos para ausente/inválido/revocado/expirado. `token` filtrado de logs.
- [ ] Reconexión automática usa el JWT vigente del store de auth (no cacheado); degrada limpiamente si el refresh falla (no infinite loop).
- [ ] Tests cubren: suscripción autenticada exitosa, rechazo anónimo, emisión vía publisher, recepción en el frontend (mockeado).
- [ ] Identifiers, routes, params en inglés; copy de UI vía `landingContent.ts`; error messages BE vía `I18n.t(...)` — nunca strings hardcoded (CLAUDE.md § Language policy).
- [ ] `docs/05-appendices/glossary.md` actualizado con `Notificación` + `Tipo de notificación` en el mismo PR (convención "glossary first").
- [ ] Pre-PR quality gate (CLAUDE.md) ejecutado: `/critique` → `/polish` → `/audit` + `just lint` + `just frontend-test-coverage` (80%) + `just frontend-test-e2e` + `just backend-test`.

---

## 7. Files Summary

### New Files

| File | Description |
|------|-------------|
| `backend/config/cable.yml` | Action Cable adapter per env (solid_cable en dev+prod, test en test). |
| `backend/db/migrate/*_create_solid_cable_messages.rb` | Migración generada por `solid_cable:install`. |
| `backend/app/channels/application_cable/connection.rb` | JWT-from-query auth en `#connect`. |
| `backend/app/channels/application_cable/channel.rb` | Base channel (si no existe ya). |
| `backend/app/channels/notifications_channel.rb` | `stream_for current_user`. |
| `backend/app/services/notifications/type.rb` | Whitelist cerrado de tipos. |
| `backend/app/services/notifications/unknown_type_error.rb` | Excepción del publisher. |
| `backend/app/services/notifications/publisher.rb` | Único entry-point para emitir. |
| `backend/app/controllers/api/dev/notifications_controller.rb` | `POST /api/dev/notifications/ping`. |
| `backend/spec/channels/application_cable/connection_spec.rb` | JWT auth tests. |
| `backend/spec/channels/notifications_channel_spec.rb` | Subscribe + broadcast tests. |
| `backend/spec/services/notifications/publisher_spec.rb` | Whitelist + payload tests. |
| `backend/spec/requests/api/dev/notifications_spec.rb` | Endpoint dev tests. |
| `frontend/src/components/notifications/NotificationsProvider.tsx` | Context + lifecycle. |
| `frontend/src/components/notifications/notificationsRegistry.ts` | Typed type→view registry. |
| `frontend/src/components/notifications/NotificationsToast.tsx` | Toast primitivo. |
| `frontend/src/components/notifications/NotificationsBadge.tsx` | Badge + panel del historial. |
| `frontend/src/components/notifications/NotificationsProvider.test.tsx` | Vitest. |
| `frontend/src/components/notifications/NotificationsToast.test.tsx` | Vitest. |
| `frontend/src/components/notifications/NotificationsBadge.test.tsx` | Vitest. |
| `frontend/tests-e2e/notifications.spec.ts` | Playwright e2e. |

### Modified Files

| File | Changes |
|------|---------|
| `backend/Gemfile` | Agregar `gem "solid_cable"`. |
| `backend/Gemfile.lock` | Resolved por `bundle install`. |
| `backend/db/schema.rb` | Tabla `solid_cable_messages`. |
| `backend/config/application.rb` | `config.filter_parameters << :token`. |
| `backend/config/routes.rb` | Namespace `dev` gated por route constraint con `POST notifications/ping`. |
| `frontend/deno.json` | Agregar `@rails/actioncable` a `imports`. |
| `frontend/src/landingContent.ts` | Agregar `notifications.ping.{title, body}` tipado. |
| `frontend/src/App.tsx` (o equivalente) | Wire `NotificationsProvider` al app shell donde vive auth state. |
| `docs/05-appendices/glossary.md` | Agregar `Notificación` + `Tipo de notificación`. |
| `docs/features/ISSUES-INDEX.md` | Linkear este plan en la columna `Plan` de la row INF-FE-00005. |
| `.gdsi-sdlc/issues/Ready/INF-FE-00005-framework-notificaciones-web-scaffold.issue.md` | Frontmatter: agregar `plan: <path relativo a este archivo>`. |

---

## 8. Risks & Verify-During-Implementation

Decisiones de scope ya cerradas; estos son riesgos de **ejecución** que deben verificarse durante el desarrollo, no replantearse arquitectónicamente.

1. **Solid Cable sobre SQLite + WAL/single-writer**: la concurrencia del MVP es baja, pero monitor durante implementación. Fallback locked: `async` adapter (in-process). Smoke test sugerido: broadcastear 50 mensajes a un mismo user en loop ajustado y verificar que ninguno se pierde y no rompe WAL. Documentado en ADR-013 — **no** se promueve a Redis ni a Postgres bajo ninguna circunstancia.
2. **`bin/rails solid_cable:install` no escribe `cable.yml`** en proyectos preexistentes (`cable.yml` no existe en el scaffold actual — sólo `solid_cable:install` añade migración + initializer). Escribirlo manualmente per Section 4.2.
3. **WS auth retry loop**: si el JWT refresh **también** falla en la reconexión, el FE debe degradar silenciosamente a "disconnected" — no infinite-reconnect. Caso cubierto como test explícito en Vitest (Task #21).
4. **Devise+JWT test helpers**: el patrón canónico para mintear tokens en specs es `Warden::JWTAuth::UserEncoder.new.call(user, :user, nil).first` (ver `backend/spec/requests/api/auth_spec.rb`). Reusar en el channel spec.
5. **Kamal proxy WS upgrade**: out of scope acá (cae en `#202` / `INF-INFRA-00004`). Local dev con `bin/rails server` funciona out-of-the-box; prod necesitará proxy config cuando aterrice `#202`. No bloquea este PR.
6. **`authenticate_user!` en `Api::Dev::NotificationsController`**: verificar contra el `ApplicationController` actual / patrón de los controllers existentes (`backend/app/controllers/api/auth_controller.rb`, `backend/app/controllers/api/sessions_controller.rb`). Si la app usa un wrapper custom (`authenticate_api_user!`, etc.), usar ese.

---

## 9. Out of Scope (referencia rápida)

Locked en el issue + ADR-013. No re-discutir en el PR; cualquier item acá triggerea **otro** issue separado:

- Persistencia de notificaciones en una tabla `notifications`. Historial es session-only en el FE.
- "Marcar como leída" server-side.
- Offline queue / store-and-forward.
- Migrar `truckr:carrier-quote-updated` (PR #194) al nuevo framework → REF-FE separado post-merge.
- Instalar librería i18n real (`react-i18next`, `react-intl`, etc.) → INF-FE separado con ADR propio.
- Wire de cualquier feature de negocio (oferta recibida, pago confirmado, cambio de estado) → REQ-BE/FE separados sprints 4+.
- Redis / pub/sub externo / WS service separado → forbidden por ADR-013 + CLAUDE.md SQLite-forever policy.
- ADR aparte por esta issue: ADR-013 ya cubre la decisión.

---

## 10. PR Opening (Fer's execution step)

Locked en CLAUDE.md + user memory:

- **Branch**: `feature/INF-FE-00005-notifications-framework`.
- **Commits**: prefijo conventional (`feat(notifications): …`, `chore(notifications): …`). El histórico interno de la rama es libre — la subject del squash es la del título del PR.
- **PR title**: conventional al inicio, **sin** prefijo `[INF-FE-00005]` (squash-merge → release-please).
  - Ejemplo: `feat(notifications): web realtime framework scaffold (Action Cable + Solid Cable)`.
- **PR body**:
  - `Tracks #217` (no `Closes` — el issue se cierra manualmente cuando se mergee y se validen los AC, per convención del handoff de triage).
  - Sección "Decisiones lockeadas" referenciando ADR-013.
  - Checklist de AC (sección 6 acá copiada).
  - Notas de UX defaults resueltos durante `/critique` → `/polish` → `/audit`.
- **`gh pr create --assignee @me`** (user memory).

---

## Tracking

- Issue file: [`.gdsi-sdlc/issues/Ready/INF-FE-00005-framework-notificaciones-web-scaffold.issue.md`](../../../../.gdsi-sdlc/issues/Ready/INF-FE-00005-framework-notificaciones-web-scaffold.issue.md)
- GitHub issue: [#217](https://github.com/tcorzo/fiuba-gestion-tp/issues/217)
- ADR-013: [`docs/01-technical-vision/technical-vision.md`](../../../01-technical-vision/technical-vision.md#adr-013--in-app-notifications-best-effort-live-delivery-no-offline-queue)
