# REF-BE-00001: Migrar Api::AuthController a Devise + devise-jwt (login/logout/me con JWT); mantener register custom

| Field | Value |
|-------|-------|
| **Tag** | REF-BE-00001 |
| **Title** | Migrar Api::AuthController a Devise + devise-jwt (login/logout/me con JWT); mantener register custom |
| **Priority** | P1 |
| **Status** | READY |
| **Created** | 2026-05-11 |
| **Updated** | 2026-05-11 |
| **Author** | Claude Code |
| **Depends On** | None. Coordina con frontend (`AuthContext.tsx` + `apiFetch`) y MSW handlers — incluido como Tarea 8 dentro de este plan. |
| **Decision Doc** | N/A — alternativa seleccionada durante triage ("devise-jwt + JTI Matcher + localStorage"). |
| **Selected Approach** | Devise + `devise-jwt` (JTI Matcher revocation); `Api::SessionsController < Devise::SessionsController` con respond_with JSON; `register` queda custom en `Api::AuthController`; `/api/auth/csrf` eliminado entero; FE guarda JWT en `localStorage` y manda `Authorization: Bearer ...`. |

---

## 1. Problem Statement

`backend/app/controllers/api/auth_controller.rb` (88 líneas) implementa login/logout a mano y expone `GET /api/auth/csrf` para bootstrap del token. El comentario en líneas 4-8 documenta una decisión deliberada de NO heredar de `Devise::SessionsController` por considerar sus defaults "demasiado HTML-centric". Esa decisión queda invertida.

La motivación principal del issue (REF-BE-00001 — P1 security) es **reducir superficie de auth custom**. La mejor mitigación contra bugs de auth hand-rolled es delegar a una librería mainstream con auditorías. Para una API Rails `api_only` (ADR-002), el patrón nativo es **JWT stateless** sobre Devise + warden-jwt_auth (gema `devise-jwt`). Esto va más lejos que "heredar de Devise::SessionsController" porque también:

- **Elimina el vector CSRF entero** del API path. Sin cookies de sesión no hay CSRF. El endpoint `/api/auth/csrf`, el `protect_from_forgery`, el `ActionController::Cookies` y la `RequestForgeryProtection` salen de `Api::BaseController`. Esto borra ~30% de la superficie auth-relevant de un solo golpe.
- **Sin session storage** en cada request — el JWT trae `user_id` + `jti` embebidos. Validación = 1 lookup a `users` para confirmar `jti`. Stateless.
- **Habilita mobile/PWA** sin re-tocar la auth (ADR-001 dejó la decisión mobile abierta).

`register` queda fuera de scope porque tiene side-effect dominio-específico (`attach_role!` crea `Carrier` o `Shipper` en transacción) que `Devise::RegistrationsController#create` no modela limpiamente. `sign_in(user)` al final del register dispara el dispatcher de devise-jwt y la respuesta incluye `Authorization: Bearer <jwt>` automáticamente. Mantenerlo custom es más legible.

Estado actual verificado en el worktree:

- Devise 5.0.3 + Warden 1.2.9 instalados. `devise-jwt` NO instalado.
- `Api::BaseController = ActionController::API` + `ActionController::Cookies` + `RequestForgeryProtection` + `Devise::Controllers::Helpers` + Pundit + Pagy + error envelope + `authenticate_user!` JSON.
- Rutas: `devise_for :users, skip: :all` + bloque manual `namespace :api { post 'auth/login', delete 'auth/logout', get 'auth/csrf', post 'auth/register', get 'auth/me' }`.
- `User` con `:database_authenticatable, :registerable, :validatable`. Sin `:jwt_authenticatable`, sin `jti`.
- Specs rswag en `backend/spec/requests/api/auth_spec.rb` (212 líneas, 11 ejemplos, contrato pinneado).
- FE `frontend/src/auth/AuthContext.tsx` (~115 líneas): `fetchCsrf` → `apiFetch` con `csrfToken` header → `register`/`login`/`logout`. MSW handlers en `frontend/src/test/mocks/handlers.ts` mockean los 5 endpoints.
- Rack::Attack throttle sobre POST `/api/auth/login` se mantiene.
- Locales `en.yml`/`es.yml` solo cubren `password_complexity`. Resto de strings hardcoded.

## 2. Solution Design

### 2.1 Layout final

```
backend/
├── Gemfile                                      # + gem "devise-jwt", "~> 0.12"
├── app/
│   ├── controllers/api/
│   │   ├── base_controller.rb                   # sin CSRF, sin cookies
│   │   ├── sessions_controller.rb               # NEW: < Devise::SessionsController
│   │   ├── devise_failure_app.rb                # NEW: 401 envelope JSON
│   │   └── auth_controller.rb                   # reducido: register + me
│   └── models/user.rb                           # + :jwt_authenticatable + JTIMatcher
├── config/
│   ├── credentials.yml.enc                      # + devise_jwt_secret_key
│   ├── initializers/devise.rb                   # + jwt block, failure_app
│   ├── routes.rb                                # -auth/csrf
│   └── locales/{en,es}.yml                      # + errors.*
└── db/migrate/
    └── YYYY...add_jti_to_users.rb               # NEW

frontend/
└── src/
    ├── auth/
    │   ├── AuthContext.tsx                      # localStorage, no CSRF
    │   └── apiFetch.ts                          # Authorization: Bearer
    └── test/mocks/handlers.ts                   # JWT en response header
```

### 2.2 Estrategia JWT

| Decisión | Valor | Por qué |
|----------|-------|---------|
| Gema | `devise-jwt ~> 0.12` | Capa fina sobre warden-jwt_auth; integrada nativamente con Devise. |
| Algoritmo | HS256 (default) | Symmetric, suficiente para un solo backend; no hay multi-issuer. |
| Secret | `Rails.application.credentials.devise_jwt_secret_key` | Generado en migration setup (`rails credentials:edit`); fallback a `secret_key_base` en test. |
| Expiración | 24 horas | Coursework, sin refresh tokens. Re-login una vez por día. |
| Revocación | **JTI Matcher** | Columna `jti :string NOT NULL UNIQUE` en `users`. Logout rota el `jti` → tokens previos inválidos. SQLite-friendly. Single-device-effective (aceptado). |
| Dispatch | `POST /api/auth/login`, `POST /api/auth/register` | El middleware de devise-jwt setea el header `Authorization` en responses de estos paths cuando `sign_in` se llama. |
| Revocation | `DELETE /api/auth/logout` | Middleware corre `User.revoke_jwt(payload, user)` que rota el `jti`. |
| Storage FE | `localStorage["truckr.jwt"]` | Survive page reload. XSS-exfiltrable — riesgo aceptado para coursework. |
| Transporte | Header `Authorization: Bearer <jwt>` | Standard. Sin cookies. Sin CSRF. |

### 2.3 Routing

`devise_for :users` se mantiene con `skip: :all`. Sessions van al subclass; los paths externos `/api/auth/login` y `/api/auth/logout` se preservan (FE y rack-attack ven URLs idénticas):

```ruby
namespace :api do
  post   "auth/register", to: "auth#register"     # sin cambio
  post   "auth/login",    to: "sessions#create"   # antes: auth#login
  delete "auth/logout",   to: "sessions#destroy"  # antes: auth#logout
  get    "auth/me",       to: "auth#me"           # sin cambio
  # GET /api/auth/csrf — ELIMINADO
  # ... resto del namespace sin cambios
end
```

### 2.4 Configuración devise-jwt

```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  # ... existente ...

  config.warden do |manager|
    manager.failure_app = Api::DeviseFailureApp
  end
  config.navigational_formats = []

  config.jwt do |jwt|
    jwt.secret = Rails.application.credentials.devise_jwt_secret_key.presence ||
                 Rails.application.secret_key_base
    jwt.dispatch_requests = [
      ["POST",   %r{^/api/auth/login$}],
      ["POST",   %r{^/api/auth/register$}]
    ]
    jwt.revocation_requests = [
      ["DELETE", %r{^/api/auth/logout$}]
    ]
    jwt.expiration_time = 24.hours.to_i
  end
end
```

**Cómo funciona el dispatch:** el middleware `Warden::JWTAuth::Middleware` inspecciona cada response. Si el path matchea `dispatch_requests` Y el request resultó en un `sign_in` (Warden), agrega `Authorization: Bearer <jwt>` al response header. Esto significa que `Api::AuthController#register` no necesita generar el JWT manualmente — basta con `sign_in(user)` al final del flow.

### 2.5 `Api::SessionsController`

```ruby
# backend/app/controllers/api/sessions_controller.rb
module Api
  # Sessions via Devise + devise-jwt. Login dispatches a JWT in the
  # `Authorization` response header; logout revokes it via JTI rotation.
  # See ADR-011.
  class SessionsController < Devise::SessionsController
    respond_to :json
    skip_before_action :verify_signed_out_user, raise: false

    def respond_with(resource, _opts = {})
      render json: MeResource.new(resource).serialize, status: :ok
    end

    def respond_to_on_destroy
      head :no_content
    end
  end
end
```

Notas:
- `skip_before_action :verify_signed_out_user` evita el redirect HTML default de Devise cuando logout corre sin sesión activa (en JWT-land "sin sesión" significa "sin Bearer header" — Warden ya devuelve 401 vía FailureApp antes de llegar al controller).
- No se overridean `create` ni `destroy`. El flow upstream queda intacto; solo cambian los hooks de respuesta.

### 2.6 `Api::DeviseFailureApp`

```ruby
# backend/app/controllers/api/devise_failure_app.rb
module Api
  class DeviseFailureApp < Devise::FailureApp
    def respond
      self.status = 401
      self.content_type = "application/json"
      code = i18n_message == :invalid ? "invalid_credentials" : "unauthorized"
      self.response_body = {
        error: {
          code: code,
          message: I18n.t("errors.#{code}")
        }
      }.to_json
    end
  end
end
```

Cubre tres flujos:
- Login con credenciales malas → `:invalid` → `invalid_credentials`.
- Request a endpoint protegido sin/con JWT inválido o revocado → `:unauthenticated` (o `:expired`) → `unauthorized`.
- Request a endpoint protegido con JWT bien-formado pero usuario no encontrado → mismo path → `unauthorized`.

### 2.7 `User` model + migración

**Migración** (`db/migrate/YYYYMMDDHHMMSS_add_jti_to_users.rb`):

```ruby
class AddJtiToUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :jti, :string
    User.reset_column_information
    User.where(jti: nil).find_each do |u|
      u.update_columns(jti: SecureRandom.uuid)
    end
    change_column_null :users, :jti, false
    add_index :users, :jti, unique: true
  end

  def down
    remove_index :users, :jti
    remove_column :users, :jti
  end
end
```

SQLite-friendly: backfill por row con SecureRandom.uuid (no `gen_random_uuid()`).

**Modelo** (`backend/app/models/user.rb`):

```diff
 class User < ApplicationRecord
+  include Devise::JWT::RevocationStrategies::JTIMatcher
+
   devise :database_authenticatable, :registerable, :validatable,
+         :jwt_authenticatable,
+         jwt_revocation_strategy: self,
          password_length: 8..128

   # ... resto sin cambios ...
+
+  before_create :set_jti
+
+  private
+
+  def set_jti
+    self.jti ||= SecureRandom.uuid
+  end
end
```

`JTIMatcher` define los class methods `jwt_revoked?(payload, user)` (compara `payload["jti"]` contra `user.jti`) y `revoke_jwt(payload, user)` (rota `user.jti = SecureRandom.uuid; user.save!`).

### 2.8 `Api::BaseController` sin CSRF/cookies

```diff
   class BaseController < ActionController::API
-    include ActionController::Cookies
-    include ActionController::RequestForgeryProtection
     include Devise::Controllers::Helpers
     include Pundit::Authorization
     include Pagy::Method
-
-    self.allow_forgery_protection = false if Rails.env.test?
-
-    protect_from_forgery with: :exception

     rescue_from Pundit::NotAuthorizedError, with: :forbidden
     # ... etc
```

`authenticate_user!`: la versión actual seguía siendo un wrapper sobre `current_user`. Mantiene el mismo shape — Warden con `:jwt_authenticatable` puebla `current_user` cuando el Bearer header está presente y el JWT es válido. Sin token → `current_user` es `nil` → nuestro `authenticate_user!` devuelve el envelope 401. Pero **para que Warden corra la strategy JWT incluso cuando no hay sesión**, hay que llamarlo explícitamente, NO confiar en que `current_user` la dispare:

```ruby
def authenticate_user!
  warden.authenticate!(scope: :user) and return if request.headers["Authorization"].present?
  return if current_user

  render json: { error: { code: "unauthorized", message: I18n.t("errors.unauthorized") } },
         status: :unauthorized
end
```

Alternativa más limpia: dejar que `Devise::Controllers::Helpers#authenticate_user!` corra (delega a Warden directamente). Pero esa versión hace render HTML por default. Vamos con el patrón anterior, que es compatible con FailureApp.

### 2.9 `Api::AuthController` reducido

```ruby
module Api
  # Custom endpoints that don't fit Devise's controller flow:
  # - `register`: User + role-attach (Carrier|Shipper) in a transaction.
  # - `me`: returns the current authenticated user.
  #
  # Sessions (login/logout) are handled by Api::SessionsController via
  # Devise + devise-jwt. See ADR-011.
  class AuthController < BaseController
    before_action :authenticate_user!, only: :me

    def register
      role = params[:role].to_s
      unless %w[carrier shipper].include?(role)
        return render json: {
          error: { code: "unprocessable", details: { role: [ I18n.t("errors.messages.invalid") ] } }
        }, status: :unprocessable_entity
      end

      user = nil
      ActiveRecord::Base.transaction do
        user = User.create!(
          email: register_params[:email],
          password: register_params[:password],
          full_name: register_params[:name]
        )
        attach_role!(user, role)
      end
      sign_in(user)  # ← dispara el devise-jwt dispatcher → Authorization header
      render json: MeResource.new(user).serialize, status: :created
    end

    def me
      render json: MeResource.new(current_user).serialize
    end

    private

    def register_params
      params.permit(:email, :password, :name)
    end

    def attach_role!(user, role)
      case role
      when "carrier" then user.create_carrier!
      when "shipper" then user.create_shipper!
      end
    end
  end
end
```

Eliminado: `csrf`, `login`, `logout`, `skip_before_action :verify_authenticity_token`, comentario obsoleto.

### 2.10 i18n cleanup (in-scope, opportunistic)

Locales `backend/config/locales/{en,es}.yml`:

```yaml
es:
  errors:
    unauthorized: "Autenticación requerida"
    invalid_credentials: "Email o contraseña inválidos"
    forbidden: "Acceso denegado"
    not_found: "Recurso no encontrado"
    carrier_role_required: "Se requiere rol de transportista"
    rate_limited: "Demasiados intentos. Intentá en 15 minutos."
```

Strings hardcoded migradas en `BaseController` (`authenticate_user!`, `require_carrier!`, `forbidden`, `not_found`) y `Api::DeviseFailureApp`. `Rack::Attack` queda fuera (corre fuera del request lifecycle — no acceso fácil a I18n; se trackea follow-up).

### 2.11 Frontend

`frontend/src/auth/apiFetch.ts` (asumiendo archivo existente; si vive en otro path, mismo principio):

```diff
-export async function apiFetch<T>(path: string, opts: ApiOpts = {}): Promise<T> {
+const JWT_KEY = "truckr.jwt";
+export function getJwt(): string | null { return localStorage.getItem(JWT_KEY); }
+export function setJwt(j: string | null) {
+  if (j) localStorage.setItem(JWT_KEY, j);
+  else   localStorage.removeItem(JWT_KEY);
+}
+
+export async function apiFetch<T>(path: string, opts: ApiOpts = {}): Promise<T> {
   const headers: Record<string, string> = {
     "Content-Type": "application/json",
     ...opts.headers,
   };
-  if (opts.csrfToken) headers["X-CSRF-Token"] = opts.csrfToken;
+  const jwt = getJwt();
+  if (jwt) headers["Authorization"] = `Bearer ${jwt}`;

   const res = await fetch(`${API_BASE_URL}${path}`, { ...opts, headers });
+  // Capture JWT from response (login/register dispatch)
+  const auth = res.headers.get("Authorization");
+  if (auth?.startsWith("Bearer ")) setJwt(auth.slice("Bearer ".length));
+
   // ... resto del manejo de errores
}
```

`frontend/src/auth/AuthContext.tsx`:

```diff
-    const fetchCsrf = useCallback(async () => { ... }, []);
-    const [csrfToken, setCsrfToken] = useState<string | null>(null);
-
     useEffect(() => {
         (async () => {
+            if (!getJwt()) { setLoading(false); return; }
             try {
                 const meRes = await apiFetch<Me>("/api/auth/me");
                 setMe(meRes);
             } catch (e) {
-                // ...
+                setJwt(null);  // 401 → clean stale token
+                setMe(null);
             }
+            setLoading(false);
         })();
     }, []);

-    const ensureCsrf = useCallback(async () => { ... }, [csrfToken, fetchCsrf]);
-
     const register = useCallback(async (payload) => {
-        const token = await ensureCsrf();
-        const next = await apiFetch<Me>("/api/auth/register", { method: "POST", body, csrfToken: token });
+        const next = await apiFetch<Me>("/api/auth/register", { method: "POST", body });
+        // apiFetch ya guardó el JWT del header Authorization de respuesta
         setMe(next);
     }, []);

     const logout = useCallback(async () => {
-        const token = await ensureCsrf();
-        await apiFetch<void>("/api/auth/logout", { method: "DELETE", csrfToken: token });
+        await apiFetch<void>("/api/auth/logout", { method: "DELETE" });
+        setJwt(null);
         setMe(null);
     }, []);
```

`frontend/src/test/mocks/handlers.ts`:

```diff
-    http.get(`${API}/api/auth/csrf`, () =>
-        HttpResponse.json({ csrf_token: "test-csrf-token" })
-    ),
     http.get(`${API}/api/auth/me`, () =>
         HttpResponse.json(/* ... */)
     ),
     http.post(`${API}/api/auth/login`, async ({ request }) => {
-        return HttpResponse.json(/* Me shape */);
+        return HttpResponse.json(/* Me shape */, {
+            headers: { "Authorization": "Bearer test-jwt-token" }
+        });
     }),
     http.post(`${API}/api/auth/register`, async ({ request }) => {
-        return HttpResponse.json(/* Me shape */);
+        return HttpResponse.json(/* Me shape */, {
+            headers: { "Authorization": "Bearer test-jwt-token" }
+        });
     }),
     http.delete(`${API}/api/auth/logout`, () => new HttpResponse(null, { status: 204 })),
```

### 2.12 ADR-011

`docs/01-technical-vision/adr-011-auth-via-devise-jwt.md` — documenta:
- Contexto: decisión previa de no-Devise en `auth_controller.rb`.
- Trade-off considerado y rechazado: cookie-session inheritance (cookie-based CSRF Double-Submit).
- Decisión: devise-jwt + JTI Matcher.
- Trade-offs aceptados: localStorage XSS exposure (coursework, sin PII real); single-device logout (no multi-device en scope).
- Consecuencias: borra superficie CSRF entera; habilita mobile/PWA sin re-trabajo.

## 3. Implementation Tasks

| # | Task | Status | Files |
|---|------|--------|-------|
| 1 | ADR-011 documentando la decisión devise-jwt + JTI Matcher | Pending | `docs/01-technical-vision/adr-011-auth-via-devise-jwt.md` |
| 2 | Agregar gema `devise-jwt`, generar credential `devise_jwt_secret_key`, configurar `Devise.setup` (failure_app + jwt block) | Pending | `backend/Gemfile`, `backend/Gemfile.lock`, `backend/config/credentials.yml.enc`, `backend/config/initializers/devise.rb` |
| 3 | Migración `add_jti_to_users` + actualizar `User` model (`:jwt_authenticatable`, JTIMatcher include, `before_create :set_jti`) | Pending | `backend/db/migrate/YYYY..._add_jti_to_users.rb`, `backend/db/schema.rb`, `backend/app/models/user.rb` |
| 4 | i18n bundle (`errors.*` en `en.yml` + `es.yml`) | Pending | `backend/config/locales/{en,es}.yml` |
| 5 | `Api::SessionsController` + `Api::DeviseFailureApp` + routes update + drop CSRF en `Api::BaseController` | Pending | `backend/app/controllers/api/sessions_controller.rb`, `backend/app/controllers/api/devise_failure_app.rb`, `backend/config/routes.rb`, `backend/app/controllers/api/base_controller.rb` |
| 6 | Reducir `Api::AuthController` (drop csrf/login/logout); ajustar `authenticate_user!` para correr `warden.authenticate!` con scope `:user`; literales → `I18n.t` | Pending | `backend/app/controllers/api/auth_controller.rb`, `backend/app/controllers/api/base_controller.rb` |
| 7 | Specs RSpec: split `auth_spec.rb` → `sessions_spec.rb` (rswag); cubrir login/logout/revocation/email-not-found; model spec para `User#jti` | Pending | `backend/spec/requests/api/sessions_spec.rb` (new), `backend/spec/requests/api/auth_spec.rb` (reducido), `backend/spec/models/user_spec.rb` (extender) |
| 8 | Frontend: `apiFetch` lee/escribe JWT (`localStorage["truckr.jwt"]`); `AuthContext` sin CSRF; MSW handlers emiten header `Authorization` | Pending | `frontend/src/auth/apiFetch.ts` (o equivalente), `frontend/src/auth/AuthContext.tsx`, `frontend/src/test/mocks/handlers.ts`, tests Vitest afectados |
| 9 | Playwright E2E: register → home → logout → login → home → reload → still logged → logout → reload → anon | Pending | `frontend/e2e/auth.spec.ts` (nuevo o extiende `smoke.spec.ts`) |
| 10 | CI verification: brakeman + bundler-audit + rubocop + rspec + vitest + playwright | Pending | — |

Orden: 1 puede ir en paralelo con todo. 2 → 3 → 5 (paralelizable con 4) → 6 → 7 → 8 → 9 → 10.

## 4. Code Changes

(Ver Sección 2 para diffs detallados. Resumen punteado de los archivos clave abajo.)

### 4.1 `backend/Gemfile` (MODIFIED)

```diff
 gem "devise", ">= 5.0.3"
+gem "devise-jwt", "~> 0.12"
```

### 4.2 `backend/app/models/user.rb`, `backend/app/controllers/api/{sessions,devise_failure_app,base,auth}_controller.rb`, `backend/config/{initializers/devise.rb,routes.rb,locales/{en,es}.yml}`, migration

Diffs detallados en §2.4–§2.10.

### 4.3 Frontend `apiFetch.ts`, `AuthContext.tsx`, `test/mocks/handlers.ts`

Diffs detallados en §2.11.

### 4.4 ADR-011

Skeleton en §2.12.

## 5. Testing

### Backend (RSpec)

**`spec/requests/api/sessions_spec.rb` (NEW, rswag)**

- `POST /api/auth/login` con credenciales válidas → 200 + body `MeResource` + header de respuesta `Authorization: Bearer <jwt>` (assert format JWT: `header.payload.signature`).
- `POST /api/auth/login` con password inválida → 401 + envelope `{ error: { code: "invalid_credentials" } }`.
- `POST /api/auth/login` con email inexistente → 401 + mismo envelope (sin user enumeration).
- `DELETE /api/auth/logout` con JWT válido → 204. Después: re-usar el MISMO JWT en `GET /api/auth/me` → 401 (revocado por JTI rotation).
- `DELETE /api/auth/logout` sin JWT → 401 (FailureApp).
- `DELETE /api/auth/logout` con JWT inválido (firma mala) → 401.
- Rate-limit: 6 logins fallidos con misma IP → 429 (test movido desde `auth_spec.rb`).

**`spec/requests/api/auth_spec.rb` (REDUCIDO)**

- Mantener todos los branches de register (válido carrier, válido shipper, password débil, email inválido, role inválido, role faltante, email duplicado). Agregar assertion: response de register exitoso incluye header `Authorization: Bearer <jwt>`.
- Mantener `GET /api/auth/me` (200 autenticado + 401 anónimo).
- Eliminar: bloque CSRF entero, bloques de login/logout.

**`spec/models/user_spec.rb` (EXTENDER)**

```ruby
describe "JWT JTI Matcher (devise-jwt)" do
  it "assigns a jti on create" do
    user = create(:user)
    expect(user.jti).to be_present
    expect(user.jti).to match(/\A[0-9a-f-]{36}\z/)
  end

  it "rotates jti on revoke_jwt" do
    user = create(:user)
    original = user.jti
    User.revoke_jwt({ "jti" => original }, user)
    expect(user.reload.jti).not_to eq(original)
  end

  it "considers tokens with the current jti as not revoked" do
    user = create(:user)
    expect(User.jwt_revoked?({ "jti" => user.jti }, user)).to be false
  end

  it "considers tokens with a stale jti as revoked" do
    user = create(:user)
    expect(User.jwt_revoked?({ "jti" => "stale-jti" }, user)).to be true
  end
end
```

### Frontend (Vitest)

- `AuthContext.test.tsx` (extender): después de login, `getJwt()` devuelve el token; después de logout, devuelve `null`. Sin token, `GET /api/auth/me` no se llama al boot.
- `apiFetch.test.ts` (NEW si no existe): envía `Authorization: Bearer <jwt>` cuando hay token; captura `Authorization` de la response y lo persiste.

### E2E (Playwright)

`frontend/e2e/auth.spec.ts`:

1. Register flow: POST → page redirects to authenticated home. `localStorage["truckr.jwt"]` está presente.
2. Logout flow: click logout → redirige a anon home. `localStorage["truckr.jwt"]` está vacío.
3. Login flow: ingresa credenciales del paso 1 → authenticated home.
4. Persistence: reload page → sigue logueado (JWT en localStorage, `/api/auth/me` 200).
5. Logout + reload: tras logout, reload → anon home (token cleared).

### Verificación final (Tarea 10)

```sh
cd backend && bin/brakeman --no-pager --quiet -w 1
cd backend && bin/bundler-audit check --update
cd backend && bin/rubocop
cd backend && bundle exec rspec
cd frontend && deno task test:run
cd frontend && deno task test:coverage   # ≥80% en src/
cd frontend && deno task test:e2e
```

Cero regresiones de contrato: el FE corriendo contra Rails real completa register → login → reload → logout sin tocar `/api/auth/csrf` ni cookies de sesión.

## 6. Acceptance Criteria

Mapeo 1-a-1 con los criterios del issue:

- [ ] `gem "devise-jwt", "~> 0.12"` en `Gemfile`. `Gemfile.lock` commiteado.
- [ ] Migración aplica `jti :string NOT NULL UNIQUE` en `users` (backfill SQLite-safe).
- [ ] `User` incluye `:jwt_authenticatable` + `Devise::JWT::RevocationStrategies::JTIMatcher` + `before_create :set_jti`.
- [ ] `Devise.setup` define `config.jwt`: secret, expiration_time=24h, dispatch_requests `[POST /api/auth/login, POST /api/auth/register]`, revocation_requests `[DELETE /api/auth/logout]`.
- [ ] `Api::SessionsController < Devise::SessionsController` con `respond_with` y `respond_to_on_destroy` JSON.
- [ ] `Api::AuthController` reducido a `register` + `me`. Register respuesta incluye `Authorization: Bearer <jwt>` (verificado en spec).
- [ ] `Api::BaseController` SIN `protect_from_forgery`, SIN `ActionController::Cookies`, SIN `RequestForgeryProtection`. `authenticate_user!` corre `warden.authenticate!(:user)` cuando hay header `Authorization`, devuelve envelope 401 si falla.
- [ ] Ruta `GET /api/auth/csrf` eliminada. Método `Api::AuthController#csrf` eliminado.
- [ ] `Api::DeviseFailureApp < Devise::FailureApp` configurado en `devise.rb` vía `manager.failure_app`. Emite envelope 401 JSON con `code: "invalid_credentials"` (login) o `"unauthorized"` (todo lo demás).
- [ ] Strings hardcoded migradas a `I18n.t("errors.*")`. Locales `en.yml` y `es.yml` actualizados con `errors.{unauthorized,invalid_credentials,forbidden,not_found,carrier_role_required,rate_limited}`.
- [ ] `spec/requests/api/sessions_spec.rb` cubre: login OK + header Authorization, login email inexistente 401, login password inválida 401, logout 204, JWT revocado tras logout (re-uso → 401), logout sin JWT 401, rate-limit 429.
- [ ] `spec/requests/api/auth_spec.rb` reducido: register branches + me. Register OK asserta header `Authorization` en respuesta.
- [ ] `spec/models/user_spec.rb` extiende cobertura de JTI: assign on create, rotate on revoke, jwt_revoked? truth table.
- [ ] Frontend `apiFetch` lee `localStorage["truckr.jwt"]` y manda `Authorization: Bearer <jwt>`; captura `Authorization` de response y lo persiste.
- [ ] `AuthContext.tsx` sin `fetchCsrf`/`ensureCsrf`/`csrfToken`. Logout limpia `localStorage`. Boot lee `localStorage` y hidrata `me` vía `/api/auth/me`; 401 limpia el storage.
- [ ] MSW handlers actualizados: sin `/api/auth/csrf`; login/register emiten header `Authorization`; me 401 si falta header.
- [ ] Playwright smoke E2E: register → reload → still logged → logout → reload → anon home (los 5 pasos del §5 Playwright).
- [ ] Brakeman + bundler-audit + rubocop + rspec + vitest + playwright chromium pasan en CI.
- [ ] ADR-011 escrita y mergeada en el mismo PR.
- [ ] Comentario obsoleto en `auth_controller.rb:4-8` reemplazado por nota corta apuntando a ADR-011 + `Api::SessionsController`.
- [ ] CI verde (backend-ci.yml + frontend-ci.yml).

## 7. Files Summary

### New Files

| File | Description |
|------|-------------|
| `backend/db/migrate/YYYYMMDDHHMMSS_add_jti_to_users.rb` | Agrega `jti :string NOT NULL UNIQUE` a `users` con backfill. |
| `backend/app/controllers/api/sessions_controller.rb` | Devise sessions subclass, JSON respond_with. |
| `backend/app/controllers/api/devise_failure_app.rb` | FailureApp custom — envelope JSON 401. |
| `backend/spec/requests/api/sessions_spec.rb` | Request specs rswag para login/logout/revocation/rate-limit. |
| `backend/config/locales/devise.es.yml` | (Opcional, si la FailureApp acaba leyendo strings devise default.) |
| `docs/01-technical-vision/adr-011-auth-via-devise-jwt.md` | ADR documentando devise-jwt + JTI Matcher + localStorage. |
| `frontend/e2e/auth.spec.ts` (o extensión de `smoke.spec.ts`) | Smoke E2E completo: register → logout → login → reload persistence. |

### Modified Files

| File | Changes |
|------|---------|
| `backend/Gemfile` + `backend/Gemfile.lock` | Agrega `devise-jwt ~> 0.12`. |
| `backend/app/models/user.rb` | `:jwt_authenticatable` + JTIMatcher include + `before_create :set_jti`. |
| `backend/app/controllers/api/auth_controller.rb` | Drop `csrf`, `login`, `logout`. Conserva `register` + `me`. Comentario header reescrito. Literales → I18n. |
| `backend/app/controllers/api/base_controller.rb` | Drop `ActionController::Cookies`, `RequestForgeryProtection`, `protect_from_forgery`, `allow_forgery_protection = false`. `authenticate_user!` corre `warden.authenticate!`. Literales → I18n. |
| `backend/config/routes.rb` | Drop `auth/csrf`. `auth/login` y `auth/logout` apuntan a `sessions#create`/`destroy`. |
| `backend/config/initializers/devise.rb` | `config.warden.failure_app = Api::DeviseFailureApp`, `navigational_formats = []`, `config.jwt { ... }`. |
| `backend/config/credentials.yml.enc` | Nuevo key `devise_jwt_secret_key`. |
| `backend/config/locales/{en,es}.yml` | Claves `errors.*`. |
| `backend/spec/requests/api/auth_spec.rb` | Drop CSRF + login + logout blocks. Register OK asserta header `Authorization`. |
| `backend/spec/models/user_spec.rb` | Extender con cobertura JTI Matcher. |
| `frontend/src/auth/apiFetch.ts` (o equivalente) | `getJwt`/`setJwt` + `Authorization: Bearer` outbound + captura inbound. |
| `frontend/src/auth/AuthContext.tsx` | Drop CSRF entero. localStorage como source-of-truth del JWT. |
| `frontend/src/test/mocks/handlers.ts` | Drop handler CSRF. Login/register emiten `Authorization` header. |
| `docs/features/ISSUES-INDEX.md` | Título del row actualizado. |

### Removed (entirely)

| Item | Reason |
|------|--------|
| Ruta `GET /api/auth/csrf` | No hay CSRF en JWT-land. |
| Método `Api::AuthController#csrf` | Idem. |
| Métodos `Api::AuthController#login`, `#logout` | Movidos a `Api::SessionsController`. |
| `protect_from_forgery` + `ActionController::Cookies` en BaseController | Sin sesión-cookie no hay CSRF. |
| `frontend` `fetchCsrf`, `ensureCsrf`, state `csrfToken` | Sin CSRF. |
| MSW handler `/api/auth/csrf` | Idem. |
