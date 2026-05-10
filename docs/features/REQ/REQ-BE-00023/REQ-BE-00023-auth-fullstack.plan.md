# REQ-BE-00023: Auth fullstack — registro, login, sesiones + pantallas

| Field | Value |
|-------|-------|
| **TAG** | REQ-BE-00023 |
| **Title** | Auth fullstack — registro, login, sesiones + pantallas |
| **Priority** | P0 |
| **Status** | Ready |
| **Issue file** | `.gdsi-sdlc/issues/Ready/REQ-BE-00023-auth-fullstack-registro-login-sesiones-y-pantallas.issue.md` |
| **GitHub Issue** | [#103](https://github.com/tcorzo/fiuba-gestion-tp/issues/103) |
| **Branch** | `feat/auth-devise-pundit` |
| **Worktree** | `/tmp/wt/auth` |
| **Conventional commit** | `feat(auth): implement registration, login, session and auth UI` |
| **PR title** | `feat(auth): implement registration, login, sessions and auth UI` |
| **Labels** | REQ, BE, FE, auth, foundation, mvp |
| **US source** | US1 (Registrarse), US2 (Login) |
| **Depends on** | `REQ-BE-00020` (Identity models — done) |
| **Blocks** | US3, US16, US22, all `/me/*` endpoints |

---

## 1. Problem Statement

El repo declara "no auth yet" pero la mayoría de los endpoints planificados (carriers/me, payouts, reseñas, ofertas, etc.) asumen `current_user`. `User` ya existe (`backend/app/models/user.rb`) con `has_secure_password` y `password_digest`, pero falta toda la cadena: endpoints, rate limit, CSRF, CORS con `credentials`, helpers `current_carrier` / `current_shipper`, OpenAPI publicado, y las pantallas `/registro` y `/login` con header session-aware.

Este issue cierra la brecha completa **fullstack** y deja un sistema usable end-to-end: alguien se registra como Shipper, Carrier o ambos, se loguea, navega y cierra sesión.

**Restricciones duras** (dictadas por el cliente, no negociables):

- Devise con módulos mínimos: `:database_authenticatable, :registerable, :validatable`. **Sin** `:confirmable`, `:recoverable`, `:trackable`, `:lockable`, `:timeoutable`, `:omniauthable`. Sin `:rememberable` (no hay caso de uso de "recordarme" en US1/US2 — se decide explícitamente NO incluirlo).
- **Pundit** para autorización (harness diseñado ahora aunque la mayoría de los endpoints de auth sean públicos).
- **Alba + Oj** para serialización JSON.
- **rswag** para OpenAPI auto-generado a partir de los request specs.
- **Session-cookie auth** (no JWT). Cookie `httpOnly` + `SameSite=Lax`. CSRF vía `GET /api/auth/csrf` + header `X-CSRF-Token` en POSTs.
- **rack-attack** para rate-limit en login (5 intentos / 15min por IP).
- **Password rules**: ≥8 chars, ≥1 upper, ≥1 lower, ≥1 digit. Server-side via Devise + custom validator; mirror client-side.
- Identifiers en inglés. UI copy en español (es-AR).
- **Pagy**: NO se incluye en este PR. `/me` no devuelve colecciones paginadas. Pagy queda para REQ-BE-00009/10.
- Email verification y password recovery están **fuera de alcance** (US22 / `REQ-BE-00025`).

---

## 2. Solution Design

### 2.1 Approach (resumen ejecutivo)

1. **Migrar `User` de `has_secure_password` a Devise**: rename `password_digest` → `encrypted_password`, agregar índice. Mantener `User` como modelo de dominio separado de `AdminUser` (ADR-008 + Decisión D de REQ-BE-00005).
2. **API namespace separado**: dado que `ApplicationController < ActionController::Base` (forzado por ActiveAdmin + Propshaft), crear `Api::BaseController < ActionController::API` con `Devise::Controllers::Helpers`, `ActionController::Cookies`, `ActionController::RequestForgeryProtection`, `Pundit::Authorization`. Toda la API vive bajo `/api/*` en su propia jerarquía.
3. **Auth controller manual** (NO los `Devise::SessionsController`/`RegistrationsController` defaults — son demasiado HTML-céntricos y no encajan con el contrato JSON del frontend). 5 acciones: `register`, `login`, `logout`, `me`, `csrf`.
4. **Pundit harness preinstalado**: `ApplicationPolicy` + `Api::BaseController` con `include Pundit::Authorization`. Auth controller no autoriza nada (es público), pero el harness queda para REQ-BE-00009/10.
5. **Alba resources**: `UserResource`, `CarrierResource`, `ShipperResource`, `MeResource` (compone los anteriores). Backend Oj configurado en initializer.
6. **rswag**: cada request spec describe su contrato OpenAPI; `rake rswag:specs:swaggerize` regenera `swagger/v1/swagger.yaml`. Mount `/api-docs` en routes (solo dev/test).
7. **rack-attack initializer**: throttle `/api/auth/login` por IP a 5 req / 15 min.
8. **Frontend**: nuevo módulo `src/auth/` con `AuthContext`, `apiClient` (CSRF-aware fetch wrapper), pantallas `RegisterPage` / `LoginPage`, `Header` con widget de sesión, ruteo via React Router (mínimo, sin esperar a INF-FE-00003 — se hace `BrowserRouter` inline para no introducir dependencia adicional).
9. **Tests**: rspec request specs (también swagger sources), rspec model specs (Devise validations + custom validator), Vitest specs (forms + context), Playwright e2e (register → me → logout).
10. **CI**: nuevo job `swagger-check` que corre `rake rswag:specs:swaggerize` y verifica con `git diff --exit-code swagger/` que el yaml no quedó desactualizado.

### 2.2 Key Design Decisions

#### Decisión A — Devise SIN `:rememberable`

Module `:rememberable` sólo aporta valor si querés persistir sesión más allá del lifetime de la cookie de sesión. La cookie de Rails ya es persistente por default (no es session-only); el frontend la guarda y la mandamos con `credentials: 'include'`. Agregar `:rememberable` exigiría una columna extra (`remember_created_at`) y un cookie adicional sin beneficio para US1/US2. **Decisión: omitirlo.** Si en el futuro se requiere "Recordarme" como UX, se reabre.

#### Decisión B — Migración `password_digest` → `encrypted_password`

El user model existe con `has_secure_password` y la columna `password_digest`. Devise espera `encrypted_password`. Dos opciones:

- **A**: rename column + agregar `null: false, default: ""`.
- **B**: dejar `password_digest`, override `Devise::Models::DatabaseAuthenticatable#encrypted_password` para mapear.

**Decisión: A (rename).** Los hashes BCrypt de `has_secure_password` y los de Devise son **compatibles** (ambos son bcrypt strings empezando con `$2a$`), así que los datos existentes (si los hubiera — no hay, la BD está vacía) seguirían funcionando. Renombrar es la opción ortodoxa, evita override exótico, y es lo que rspec/devise espera por convención.

#### Decisión C — `ApplicationController` queda intocado, todo cuelga de `Api::BaseController`

`ApplicationController < ActionController::Base` por exigencia de ActiveAdmin (necesita Base para los layouts). No tocamos la jerarquía. La nueva controller chain es:

```
Api::BaseController            < ActionController::API
  + ActionController::Cookies
  + ActionController::RequestForgeryProtection
  + Devise::Controllers::Helpers
  + Pundit::Authorization
  + Api::ErrorHandling (concern)
```

Los helpers `current_user`, `current_carrier`, `current_shipper`, `authenticate_user!` viven en `Api::BaseController` o concerns incluidos por él. **NO se exponen en `ApplicationController`** (no hace falta — la API es la única consumer). El AC del issue dice "ApplicationController expone current_user…", pero el sentido real es "el base controller de la API expone…". Esto se documenta en el commit message para evitar ambigüedad.

#### Decisión D — Roles en el body del registro vs creación post-registro

El body del register acepta `role: "carrier"|"shipper"|"both"`. La acción crea `User` + el `Carrier`/`Shipper` correspondiente atómicamente (transacción). **No** se introduce un endpoint separado "elegir rol después" (US3 cubre eso). Si `role` viene inválido o ausente → 422.

#### Decisión E — CSRF para fetch cross-origin con cookies

Rails CSRF protection + cookie auth + cross-origin (5173 ↔ 3000) requiere que el frontend obtenga el token y lo mande en `X-CSRF-Token`. Flujo:

1. FE: `GET /api/auth/csrf` → response body `{ "csrf_token": "abc..." }`. Misma cookie de sesión se setea (Rails generate token tied to session).
2. FE: cualquier POST/PUT/DELETE incluye `X-CSRF-Token: abc...` + cookie de sesión. `protect_from_forgery with: :null_session` NO se usa (queremos protección real).
3. `Api::BaseController` declara `protect_from_forgery with: :exception` y omite CSRF check **solo** para `csrf` action (chicken-and-egg): `skip_before_action :verify_authenticity_token, only: :csrf`.

#### Decisión F — rswag specs separadas de los request specs "normales"

rswag exige una DSL específica (`path '...'`, `response '200', '...'`) que ensucia los specs si se mezcla con assertions normales. **Decisión: ambos en el mismo spec file** (más mantenible — single source of truth). El estilo rswag es lo suficientemente descriptivo. Ejemplo: `spec/requests/api/auth_spec.rb` usa `path '/api/auth/login' do ... post 'login' do ...`. CI step `rake rswag:specs:swaggerize` regenera `swagger/v1/swagger.yaml` y `git diff --exit-code` falla si drift.

#### Decisión G — Frontend routing

Issue espera rutas `/registro`, `/login`. El proyecto **no** tiene React Router instalado (`App.tsx` es un landing único). Opciones:

- **A**: agregar React Router (dependencia nueva).
- **B**: esperar a INF-FE-00003 que es exactamente esto.
- **C**: hacer un mini-router custom basado en `useState` + `window.history`.

**Decisión: A.** REQ-BE-00023 es P0 y bloquea TODO; INF-FE-00003 está NEW (no planeado). Agregamos `react-router-dom@6` ahora; cuando INF-FE-00003 entre, ya está instalado y solo se reorganiza. Riesgo: doble trabajo si INF-FE-00003 cambia el patrón. **Mitigación**: estructura `src/auth/` y `src/routes.tsx` ya orientadas a feature folders.

#### Decisión H — Solid Cache como session store

Rails 8 default es cookie-store (todo el state en la cookie firmada). Para session-cookie API auth, esto **funciona** sin DB lookups. Solid Cache se usa para **otros** caches (rate-limit counters de rack-attack). **Decisión**: dejar el session store en `:cookie_store` (default), usar Solid Cache **solo** como cache backend para rack-attack. Más simple, menos puntos de falla. El issue menciona "Solid Cache as session store" pero técnicamente eso requiere `cache_store`-backed session, lo cual es overkill. Documentamos la desviación en el commit.

### 2.3 Out of Scope (deliberado)

- Email verification (US22, `REQ-BE-00028`).
- Password recovery / forgot password (no hay issue todavía — futuro).
- Cambiar contraseña (`REQ-BE-00025`, US16).
- Modificar perfil (`REQ-FE-00012`, US3).
- Welcome email (depende de `INF-BE-00005` mailer scaffolding — se deja `TODO` en el comentario del controller).
- 2FA, OAuth, magic links.
- "Remember me" cookie (Decisión A).
- Endpoints `/me/*` específicos (carriers/me/profile, etc.).
- Polish visual avanzado (impeccable critique/polish skill — se aplican principios pero no la pasada exhaustiva).
- Pagy (Decisión: no necesario en este PR).

---

## 3. Implementation Tasks

| # | Task | Files (key) | Output | Notes |
|---|------|-------------|--------|-------|
| 1 | Add gems to Gemfile | `backend/Gemfile` | bundle install OK | pundit, alba, oj, rswag-api, rswag-specs, rswag-ui, rack-attack |
| 2 | Generate Devise config (skip if exists) | `backend/config/initializers/devise.rb` | already exists | no-op except verify mailer_sender |
| 3 | Migration: rename `password_digest` → `encrypted_password` | `backend/db/migrate/<ts>_rename_password_digest_on_users.rb` | new file | rename + ensure null:false default:"" |
| 4 | Update `User` model: replace `has_secure_password` with Devise `:database_authenticatable, :registerable, :validatable` + custom password complexity validator | `backend/app/models/user.rb`, `backend/app/validators/password_complexity_validator.rb` | model swap | keep canonicalise_email, ransackable, has_one :carrier/:shipper |
| 5 | Create `Api::BaseController` with Cookies, RequestForgeryProtection, Devise helpers, Pundit, error handling | `backend/app/controllers/api/base_controller.rb` | new file | `current_carrier`, `current_shipper`, `authenticate_user!` |
| 6 | Create `Api::Auth::SessionsController` (login/logout/me/csrf) | `backend/app/controllers/api/auth_controller.rb` | new file | single flat controller per issue spec |
| 7 | Create `Api::Auth::RegistrationsController` (register only) | combined into `auth_controller.rb` | same file | `register` action |
| 8 | Routes: mount `/api/auth/*` + `/api-docs` (dev/test) | `backend/config/routes.rb` | edited | scope :api, devise_scope, rswag mount |
| 9 | CORS config: support credentials, include 5173 | `backend/config/initializers/cors.rb` | new (file is empty currently) | rack-cors gem already? check Gemfile |
| 10 | Pundit base policy | `backend/app/policies/application_policy.rb` | new file | scaffolds Pundit harness for future issues |
| 11 | Alba + Oj initializer | `backend/config/initializers/alba.rb` | new file | `Alba.backend = :oj` |
| 12 | Alba resources | `backend/app/resources/{user,carrier,shipper,me}_resource.rb` | new files | UserResource, CarrierResource, ShipperResource, MeResource |
| 13 | Rack-attack initializer: throttle login | `backend/config/initializers/rack_attack.rb` | new file | 5 req / 15min per IP on POST /api/auth/login |
| 14 | rswag setup: install task + swagger_helper + mount | `backend/spec/swagger_helper.rb`, `backend/Rakefile` (already), `backend/config/routes.rb` | new + edited | output `backend/swagger/v1/swagger.yaml` |
| 15 | Request specs (rswag style) | `backend/spec/requests/api/auth_spec.rb` | new file | covers register/login/logout/me/csrf + AC ≥80% |
| 16 | Model specs | `backend/spec/models/user_spec.rb` (new), `backend/spec/validators/password_complexity_validator_spec.rb` | new files | password rules + Devise validations |
| 17 | Resource specs | `backend/spec/resources/me_resource_spec.rb` | new file | smoke: serializes user with both carrier+shipper |
| 18 | CI: add swagger drift check step | `.github/workflows/backend-ci.yml` (or whatever exists) | edited or new | `rake rswag:specs:swaggerize && git diff --exit-code swagger/` |
| 19 | FE: install react-router-dom + add types | `frontend/deno.json` | edited | npm:react-router-dom@6.x |
| 20 | FE: API client with CSRF helper | `frontend/src/api.ts`, `frontend/src/auth/apiClient.ts` | edited + new | `apiFetch()` wrapper auto-attaches X-CSRF-Token |
| 21 | FE: AuthContext + provider + hook | `frontend/src/auth/AuthContext.tsx`, `frontend/src/auth/useCurrentUser.ts` | new files | initial poll to /me, login/logout/register methods |
| 22 | FE: RegisterPage component | `frontend/src/auth/RegisterPage.tsx`, `frontend/src/auth/RegisterPage.module.css` | new files | impeccable principles applied |
| 23 | FE: LoginPage component | `frontend/src/auth/LoginPage.tsx`, `frontend/src/auth/LoginPage.module.css` | new files | impeccable principles applied |
| 24 | FE: Header with session widget | `frontend/src/components/Header.tsx`, `frontend/src/components/Header.module.css` | new files | shows email + logout when auth, CTA when not |
| 25 | FE: routes wiring + main.tsx update | `frontend/src/main.tsx`, `frontend/src/routes.tsx`, `frontend/src/App.tsx` | edited + new | BrowserRouter, /registro, /login, /, fallback |
| 26 | FE tests: RegisterPage + LoginPage + Header (Vitest) | `frontend/src/auth/RegisterPage.test.tsx`, `frontend/src/auth/LoginPage.test.tsx`, `frontend/src/components/Header.test.tsx` | new files | MSW handlers for /api/auth/* |
| 27 | FE: MSW handlers for auth | `frontend/src/test/mocks/handlers.ts` | edited | mock /api/auth/{csrf,register,login,logout,me} |
| 28 | FE E2E (Playwright): register → me → logout | `frontend/e2e/auth.spec.ts` | new file | also extends smoke.spec.ts if applicable |
| 29 | Update issue file frontmatter + move to Ready | `.gdsi-sdlc/issues/Backlog/...` → `Ready/` | git mv | + add `plan:` and `status: ready` |
| 30 | Update ISSUES-INDEX.md | `docs/features/ISSUES-INDEX.md` | edited | row REQ-BE-00023 → status RDY + plan link |
| 31 | Optional: short ADR for cookie-session vs JWT | `docs/03-architecture-diagrams/adr/ADR-009-session-cookie-auth.md` | new file (optional) | only if reviewer pushes — issue says "if not exists" |

---

## 4. Code Changes

### 4.1 New file: `backend/Gemfile` (additions)

Add to the existing Gemfile (do not duplicate `devise`, already present):

```ruby
# Authorization (Pundit)
gem "pundit"

# Serialization
gem "alba"
gem "oj"

# OpenAPI generation from request specs
gem "rswag-api"
gem "rswag-ui"

# Rate limiting
gem "rack-attack"

group :development, :test do
  gem "rswag-specs"
end

# CORS (verify if already present; project may have rack-cors)
gem "rack-cors"
```

After edit: `cd backend && bundle install`. If `rack-cors` is already in Gemfile, skip its line.

### 4.2 New migration: `backend/db/migrate/<TIMESTAMP>_rename_password_digest_on_users.rb`

Use `Time.now.strftime("%Y%m%d%H%M%S")` for timestamp prefix. Suggested numeric pattern matching existing migrations: e.g. `20260510120000_rename_password_digest_on_users.rb`.

```ruby
# frozen_string_literal: true

class RenamePasswordDigestOnUsers < ActiveRecord::Migration[8.1]
  def up
    rename_column :users, :password_digest, :encrypted_password
    change_column_null :users, :encrypted_password, false, ""
    change_column_default :users, :encrypted_password, ""
  end

  def down
    change_column_default :users, :encrypted_password, nil
    rename_column :users, :encrypted_password, :password_digest
  end
end
```

Run: `bin/rails db:migrate db:rollback db:migrate` to verify reversibility.

### 4.3 Modified file: `backend/app/models/user.rb`

Replace `has_secure_password` with Devise. Keep all other behavior.

```ruby
# frozen_string_literal: true

# User — auth account. (header comment preserved)
class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :validatable

  has_one :carrier, dependent: :destroy
  has_one :shipper, dependent: :destroy

  before_validation :canonicalise_email

  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  # Devise's :validatable already enforces presence + 6+ chars; we override with our stricter rules.
  validates :password,
            password_complexity: true,
            length: { minimum: 8 },
            if: -> { new_record? || password.present? }

  scope :carriers, -> { joins(:carrier).distinct }
  scope :shippers, -> { joins(:shipper).distinct }

  def carrier? = carrier.present?
  def shipper? = shipper.present?

  def self.ransackable_attributes(_auth_object = nil)
    %w[id email full_name phone verified_at created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[carrier shipper]
  end

  private

  def canonicalise_email
    self.email = email.to_s.strip.downcase.presence
  end
end
```

### 4.4 New file: `backend/app/validators/password_complexity_validator.rb`

```ruby
# frozen_string_literal: true

# Enforces ≥1 uppercase, ≥1 lowercase, ≥1 digit. Length ≥8 handled separately.
class PasswordComplexityValidator < ActiveModel::EachValidator
  RULES = {
    upper: /[A-Z]/,
    lower: /[a-z]/,
    digit: /\d/
  }.freeze

  MESSAGES = {
    upper: "debe contener al menos una mayúscula",
    lower: "debe contener al menos una minúscula",
    digit: "debe contener al menos un dígito"
  }.freeze

  def validate_each(record, attribute, value)
    return if value.blank?

    RULES.each do |key, regex|
      record.errors.add(attribute, MESSAGES[key]) unless value.match?(regex)
    end
  end
end
```

### 4.5 New file: `backend/app/controllers/api/base_controller.rb`

```ruby
# frozen_string_literal: true

module Api
  class BaseController < ActionController::API
    include ActionController::Cookies
    include ActionController::RequestForgeryProtection
    include Devise::Controllers::Helpers
    include Pundit::Authorization

    protect_from_forgery with: :exception

    rescue_from Pundit::NotAuthorizedError, with: :forbidden
    rescue_from ActiveRecord::RecordNotFound, with: :not_found
    rescue_from ActiveRecord::RecordInvalid, with: :unprocessable

    # Helpers (current_user comes from Devise::Controllers::Helpers).
    def current_carrier = current_user&.carrier
    def current_shipper = current_user&.shipper

    def authenticate_user!
      return if current_user

      render json: { error: { code: "unauthorized", message: "Autenticación requerida" } },
             status: :unauthorized
    end

    private

    def forbidden(_e)
      render json: { error: { code: "forbidden", message: "Acceso denegado" } }, status: :forbidden
    end

    def not_found(_e)
      render json: { error: { code: "not_found", message: "Recurso no encontrado" } }, status: :not_found
    end

    def unprocessable(e)
      render json: { error: { code: "unprocessable", details: e.record.errors.as_json } },
             status: :unprocessable_entity
    end
  end
end
```

### 4.6 New file: `backend/app/controllers/api/auth_controller.rb`

```ruby
# frozen_string_literal: true

module Api
  class AuthController < BaseController
    skip_before_action :verify_authenticity_token, only: :csrf
    before_action :authenticate_user!, only: :me

    # GET /api/auth/csrf — bootstraps a session and returns the CSRF token.
    def csrf
      render json: { csrf_token: form_authenticity_token }
    end

    # POST /api/auth/register
    # body: { email, password, name, role: "carrier"|"shipper"|"both" }
    def register
      ActiveRecord::Base.transaction do
        @user = User.create!(register_params.slice(:email, :password, :full_name))
        attach_role!(@user, register_params[:role])
        sign_in(@user)
      end
      render json: MeResource.new(@user).serialize, status: :created
    end

    # POST /api/auth/login — body: { email, password }
    def login
      user = User.find_for_authentication(email: login_params[:email].to_s.downcase.strip)

      if user&.valid_password?(login_params[:password])
        sign_in(user)
        render json: MeResource.new(user).serialize
      else
        render json: { error: { code: "invalid_credentials", message: "Email o contraseña inválidos" } },
               status: :unauthorized
      end
    end

    # DELETE /api/auth/logout
    def logout
      sign_out(current_user) if current_user
      reset_session
      head :no_content
    end

    # GET /api/auth/me
    def me
      render json: MeResource.new(current_user).serialize
    end

    private

    def register_params
      params.permit(:email, :password, :role).merge(full_name: params[:name])
    end

    def login_params
      params.permit(:email, :password)
    end

    def attach_role!(user, role)
      case role.to_s
      when "carrier" then user.create_carrier!
      when "shipper" then user.create_shipper!
      when "both"
        user.create_carrier!
        user.create_shipper!
      else
        raise ActiveRecord::RecordInvalid.new(user).tap { |e| user.errors.add(:role, "es inválido") }
      end
    end
  end
end
```

### 4.7 Modified file: `backend/config/routes.rb`

```ruby
Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  # Devise mount for the domain User — mostly to satisfy Devise's helper expectations.
  # We ship our own controllers, so skip all default devise routes.
  devise_for :users, skip: :all

  namespace :api do
    get   "auth/csrf",     to: "auth#csrf"
    post  "auth/register", to: "auth#register"
    post  "auth/login",    to: "auth#login"
    delete "auth/logout",  to: "auth#logout"
    get   "auth/me",       to: "auth#me"
  end

  # OpenAPI docs (dev/test only)
  if Rails.env.development? || Rails.env.test?
    mount Rswag::Ui::Engine  => "/api-docs"
    mount Rswag::Api::Engine => "/api-docs"
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
```

### 4.8 Modified file: `backend/config/initializers/cors.rb`

Currently empty. Replace with:

```ruby
# frozen_string_literal: true

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins ENV.fetch("FRONTEND_ORIGIN", "http://localhost:5173")

    resource "/api/*",
             headers: :any,
             methods: %i[get post put patch delete options head],
             credentials: true,
             expose: %w[X-CSRF-Token]
  end
end
```

(Verify `rack-cors` gem present after step 4.1.)

### 4.9 New file: `backend/config/initializers/alba.rb`

```ruby
# frozen_string_literal: true

require "alba"
require "oj"

Alba.backend = :oj
Alba.inflector = :active_support
```

### 4.10 New file: `backend/config/initializers/rack_attack.rb`

```ruby
# frozen_string_literal: true

class Rack::Attack
  ### Throttle login attempts: 5 per 15 minutes per IP.
  throttle("login/ip", limit: 5, period: 15.minutes) do |req|
    req.ip if req.path == "/api/auth/login" && req.post?
  end

  self.throttled_responder = lambda do |_env|
    [
      429,
      { "content-type" => "application/json" },
      [{ error: { code: "rate_limited", message: "Demasiados intentos. Intentá en 15 minutos." } }.to_json]
    ]
  end
end

Rails.application.config.middleware.use Rack::Attack
```

### 4.11 New file: `backend/app/policies/application_policy.rb`

```ruby
# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?  = false
  def show?   = false
  def create? = false
  def new?    = create?
  def update? = false
  def edit?   = update?
  def destroy? = false

  class Scope
    attr_reader :user, :scope
    def initialize(user, scope) = (@user = user; @scope = scope)
    def resolve = scope.none
  end
end
```

### 4.12 New files: Alba resources (`backend/app/resources/`)

`backend/app/resources/user_resource.rb`:

```ruby
class UserResource
  include Alba::Resource
  attributes :id, :email, :full_name, :phone, :verified_at, :created_at
end
```

`backend/app/resources/carrier_resource.rb`:

```ruby
class CarrierResource
  include Alba::Resource
  attributes :id, :legal_name, :tax_id, :base_city, :province, :rating_avg, :completed_shipments
end
```

`backend/app/resources/shipper_resource.rb`:

```ruby
class ShipperResource
  include Alba::Resource
  attributes :id, :company_name, :tax_id, :billing_address
end
```

`backend/app/resources/me_resource.rb`:

```ruby
class MeResource
  include Alba::Resource
  attributes :id, :email, :full_name, :phone, :verified_at
  attribute :roles do |user|
    %w[carrier shipper].select { |r| user.public_send("#{r}?") }
  end
  one :carrier, resource: CarrierResource
  one :shipper, resource: ShipperResource
end
```

### 4.13 New file: `backend/spec/swagger_helper.rb` (rswag scaffolding)

```ruby
# frozen_string_literal: true

require "rails_helper"

RSpec.configure do |config|
  config.openapi_root = Rails.root.join("swagger").to_s
  config.openapi_format = :yaml

  config.openapi_specs = {
    "v1/swagger.yaml" => {
      openapi: "3.0.3",
      info: { title: "Truckr API", version: "v1" },
      paths: {},
      servers: [{ url: "http://localhost:3000" }],
      components: {
        securitySchemes: {
          cookie_auth: { type: :apiKey, in: :cookie, name: "_truckr_session" }
        }
      }
    }
  }
end
```

### 4.14 New file: `backend/spec/requests/api/auth_spec.rb`

Full rswag-style spec covering:

- `path "/api/auth/csrf"` → GET 200, body has `csrf_token`
- `path "/api/auth/register"` → POST 201 (success carrier/shipper/both), 422 (invalid email, weak password, missing role, duplicate email)
- `path "/api/auth/login"` → POST 200 (success), 401 (wrong password / unknown email), 429 (after 5 fails — verify rack-attack)
- `path "/api/auth/logout"` → DELETE 204
- `path "/api/auth/me"` → GET 200 (authenticated, with carrier+shipper), 401 (no session)

Pseudocode skeleton:

```ruby
require "swagger_helper"

RSpec.describe "Api::Auth", type: :request do
  path "/api/auth/csrf" do
    get "Returns CSRF token + sets session cookie" do
      tags "Auth"; produces "application/json"
      response "200", "ok" do
        run_test! { |response| expect(JSON.parse(response.body)).to have_key("csrf_token") }
      end
    end
  end
  # ...register, login, logout, me path blocks following rswag DSL...
end
```

### 4.15 Frontend changes

#### 4.15.1 `frontend/deno.json` (edit)

Add to `imports`:

```json
"react-router-dom": "npm:react-router-dom@6.26.2"
```

#### 4.15.2 `frontend/src/api.ts` (edit) — extend with apiClient

Append to existing file:

```ts
type ApiOpts = { method?: string; body?: unknown; csrfToken?: string };

export async function apiFetch<T>(path: string, opts: ApiOpts = {}): Promise<T> {
  const headers: Record<string, string> = { "Content-Type": "application/json" };
  if (opts.csrfToken) headers["X-CSRF-Token"] = opts.csrfToken;

  const res = await fetch(`${API_BASE_URL}${path}`, {
    method: opts.method ?? "GET",
    credentials: "include",
    headers,
    body: opts.body ? JSON.stringify(opts.body) : undefined,
  });

  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new ApiError(res.status, err?.error?.message ?? "Error", err?.error?.code);
  }
  if (res.status === 204) return undefined as T;
  return res.json();
}

export class ApiError extends Error {
  constructor(public status: number, message: string, public code?: string) {
    super(message);
  }
}
```

#### 4.15.3 `frontend/src/auth/AuthContext.tsx` (new)

```tsx
import { createContext, useEffect, useState, type ReactNode } from "react";
import { apiFetch, ApiError } from "../api";

export type Role = "carrier" | "shipper";
export type Me = { id: number; email: string; full_name?: string; roles: Role[]; carrier?: unknown; shipper?: unknown };

type AuthState = {
  me: Me | null;
  loading: boolean;
  csrfToken: string | null;
  register: (input: { email: string; password: string; name: string; role: "carrier" | "shipper" | "both" }) => Promise<void>;
  login: (input: { email: string; password: string }) => Promise<void>;
  logout: () => Promise<void>;
};

export const AuthContext = createContext<AuthState | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [me, setMe] = useState<Me | null>(null);
  const [loading, setLoading] = useState(true);
  const [csrfToken, setCsrfToken] = useState<string | null>(null);

  useEffect(() => {
    (async () => {
      try {
        const csrf = await apiFetch<{ csrf_token: string }>("/api/auth/csrf");
        setCsrfToken(csrf.csrf_token);
        const me = await apiFetch<Me>("/api/auth/me");
        setMe(me);
      } catch (e) {
        if (!(e instanceof ApiError) || e.status !== 401) console.error(e);
      } finally {
        setLoading(false);
      }
    })();
  }, []);

  const refreshCsrf = async () => {
    const r = await apiFetch<{ csrf_token: string }>("/api/auth/csrf");
    setCsrfToken(r.csrf_token);
    return r.csrf_token;
  };

  const register: AuthState["register"] = async (body) => {
    const token = csrfToken ?? (await refreshCsrf());
    const me = await apiFetch<Me>("/api/auth/register", { method: "POST", body, csrfToken: token });
    setMe(me);
  };

  const login: AuthState["login"] = async (body) => {
    const token = csrfToken ?? (await refreshCsrf());
    const me = await apiFetch<Me>("/api/auth/login", { method: "POST", body, csrfToken: token });
    setMe(me);
  };

  const logout = async () => {
    const token = csrfToken ?? (await refreshCsrf());
    await apiFetch<void>("/api/auth/logout", { method: "DELETE", csrfToken: token });
    setMe(null);
  };

  return (
    <AuthContext.Provider value={{ me, loading, csrfToken, register, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}
```

`frontend/src/auth/useCurrentUser.ts`:

```ts
import { useContext } from "react";
import { AuthContext } from "./AuthContext";

export function useCurrentUser() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useCurrentUser must be inside <AuthProvider>");
  return ctx;
}
```

#### 4.15.4 `frontend/src/auth/RegisterPage.tsx`, `LoginPage.tsx`

Implementer MUST invoke the **impeccable skill** (`frontend/.agents/skills/impeccable/`) for visual decisions before writing markup. Required pillars from `.impeccable.md`:

- Spanish-first copy (es-AR), warm/clear/human voice.
- Trust-forward forms: clear labels above inputs, inline errors, calm surfaces.
- Modular type scale; cap line length at 65–75ch.
- ARIA: `aria-invalid`, `aria-describedby`, label-for on every input.

Form fields:

**RegisterPage**: `email`, `password`, `passwordConfirm`, `name`, `role` (radio: Cliente / Transportista / Ambos). Client-side validations mirror server (≥8/upper/lower/digit + match). On submit → call `register()` from context → redirect to `/`.

**LoginPage**: `email`, `password`. On submit → `login()` → redirect to `/`. Show inline error from `ApiError`.

#### 4.15.5 `frontend/src/components/Header.tsx` (new)

Shows brand + nav. Right side conditional:

- If `loading`: skeleton placeholder.
- If `me`: shows email + "Salir" button → `logout()` → navigate to `/login`.
- If `!me`: "Iniciar sesión" + "Crear cuenta" links.

#### 4.15.6 `frontend/src/routes.tsx` (new) + `main.tsx` (edit) + `App.tsx` (edit)

```tsx
// routes.tsx
import { BrowserRouter, Route, Routes } from "react-router-dom";
import App from "./App";
import { AuthProvider } from "./auth/AuthContext";
import { LoginPage } from "./auth/LoginPage";
import { RegisterPage } from "./auth/RegisterPage";
import { Header } from "./components/Header";

export function AppRoutes() {
  return (
    <BrowserRouter>
      <AuthProvider>
        <Header />
        <Routes>
          <Route path="/" element={<App />} />
          <Route path="/login" element={<LoginPage />} />
          <Route path="/registro" element={<RegisterPage />} />
        </Routes>
      </AuthProvider>
    </BrowserRouter>
  );
}
```

`main.tsx` swaps `<App />` for `<AppRoutes />`.

#### 4.15.7 MSW handlers — `frontend/src/test/mocks/handlers.ts`

```ts
import { http, HttpResponse } from "msw";

export const handlers = [
  http.get("http://localhost:3000/api/auth/csrf", () => HttpResponse.json({ csrf_token: "test-token" })),
  http.get("http://localhost:3000/api/auth/me", () =>
    HttpResponse.json({ error: { code: "unauthorized" } }, { status: 401 })
  ),
  http.post("http://localhost:3000/api/auth/login", async ({ request }) => {
    const body = (await request.json()) as { email: string; password: string };
    if (body.password === "Password1") {
      return HttpResponse.json({ id: 1, email: body.email, roles: ["shipper"] });
    }
    return HttpResponse.json({ error: { code: "invalid_credentials" } }, { status: 401 });
  }),
  http.post("http://localhost:3000/api/auth/register", async ({ request }) => {
    const body = (await request.json()) as { email: string; role: string };
    return HttpResponse.json({ id: 1, email: body.email, roles: [body.role] }, { status: 201 });
  }),
  http.delete("http://localhost:3000/api/auth/logout", () => new HttpResponse(null, { status: 204 })),
];
```

(Note: project uses MSW v2 — verify version in `frontend/deno.json`. If different version, adjust import.)

#### 4.15.8 Vitest specs

- `frontend/src/auth/RegisterPage.test.tsx`: renders form, validates password rules client-side (4 sub-cases), submits and shows success.
- `frontend/src/auth/LoginPage.test.tsx`: renders, invalid creds show error, valid login.
- `frontend/src/components/Header.test.tsx`: shows correct CTA based on auth state.

#### 4.15.9 Playwright e2e — `frontend/e2e/auth.spec.ts`

```ts
import { expect, test } from "@playwright/test";

test("register → me → logout", async ({ page }) => {
  await page.goto("/registro");
  const email = `test-${Date.now()}@example.com`;
  await page.fill("#email", email);
  await page.fill("#password", "Password1");
  await page.fill("#passwordConfirm", "Password1");
  await page.fill("#name", "Test User");
  await page.check("#role-shipper");
  await page.click("button[type=submit]");

  await expect(page.getByText(email)).toBeVisible();

  await page.click("button:has-text('Salir')");
  await expect(page).toHaveURL(/\/login/);
});
```

### 4.16 CI: swagger drift check

Add a step (or new workflow) that runs:

```yaml
- name: Generate OpenAPI spec
  run: bundle exec rake rswag:specs:swaggerize
  working-directory: backend
- name: Verify swagger.yaml is up to date
  run: git diff --exit-code backend/swagger
```

### 4.17 Issue file frontmatter (modified)

`.gdsi-sdlc/issues/Backlog/REQ-BE-00023-...issue.md` → `Ready/`. Diff:

```diff
 ---
 tag: REQ-BE-00023
 title: Auth fullstack — registro, login, sesiones + pantallas en frontend
 priority: P0
-status: backlog
+status: ready
 created: '2026-05-03'
 source: manual
 source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/103
 author: Claude Code
+plan: docs/features/REQ/REQ-BE-00023/REQ-BE-00023-auth-fullstack.plan.md
 github_issue: 103
 ...
```

### 4.18 ISSUES-INDEX.md (modified)

Change line 40:

```diff
-| REQ-BE-00023 | Auth fullstack — registro, login, sesiones + pantallas (foundation, US1+US2) | NEW | BE | 2026-05-03 | - |
+| REQ-BE-00023 | Auth fullstack — registro, login, sesiones + pantallas (foundation, US1+US2) | RDY | BE | 2026-05-03 | [plan](REQ/REQ-BE-00023/REQ-BE-00023-auth-fullstack.plan.md) |
```

---

## 5. Testing

### 5.1 Backend

- `bin/rails db:migrate db:rollback db:migrate` — confirms migration reversibility.
- `bundle exec rspec spec/models/user_spec.rb` — Devise validations, password complexity (12 cases: empty, short, no-upper, no-lower, no-digit, just-letters, just-digits, valid-strong, etc.).
- `bundle exec rspec spec/validators/password_complexity_validator_spec.rb`.
- `bundle exec rspec spec/requests/api/auth_spec.rb` — full happy + sad paths. Coverage ≥80% on `app/controllers/api/auth_controller.rb` (verify with `simplecov`).
- `bundle exec rake rswag:specs:swaggerize` — generates `swagger/v1/swagger.yaml`. CI verifies no drift.
- Manual: `curl -c jar.txt http://localhost:3000/api/auth/csrf`, then `curl -b jar.txt -c jar.txt -H "X-CSRF-Token: <token>" -d '{"email":"a@b.c","password":"Password1","name":"A","role":"shipper"}' -H "Content-Type: application/json" http://localhost:3000/api/auth/register`.
- Rate-limit smoke: 6 consecutive bad logins → 6th returns 429.

### 5.2 Frontend

- `deno task test` — Vitest specs. Coverage ≥80% on `src/auth/*` and `src/components/Header.tsx`.
- `deno task e2e` — Playwright. The auth spec must pass against a live backend (CI brings up a Rails server step).
- Manual visual check: `/registro` and `/login` against impeccable principles (typography, breathing room, error states, calm surfaces).

### 5.3 Cross-cutting

- Open browser DevTools, register a user, verify cookie `_truckr_session` set with `HttpOnly; SameSite=Lax`.
- Verify `OPTIONS /api/auth/login` preflight responds with `Access-Control-Allow-Credentials: true` and `Access-Control-Allow-Origin: http://localhost:5173`.

---

## 6. Acceptance Criteria

Mapped 1-to-1 to issue ACs:

- [ ] **AC1** — Endpoints `/api/auth/{register,login,logout,me,csrf}` implementados con request specs (§4.6, §4.14).
- [ ] **AC2** — `Api::BaseController` expone `current_user`, `current_carrier`, `current_shipper`, `authenticate_user!` (§4.5). *Nota: el AC dice "ApplicationController"; la implementación lo pone en `Api::BaseController` por la coexistencia con ActiveAdmin (§Decisión C). Documentado en commit message.*
- [ ] **AC3** — Rate limiting de login funcional: 6º intento → 429 (§4.10, §5.1).
- [ ] **AC4** — Pantallas `/registro` y `/login` implementadas y conectadas al BE (§4.15.4, §4.15.6).
- [ ] **AC5** — Header con estado de sesión + logout en cualquier ruta (§4.15.5, montado en `routes.tsx`).
- [ ] **AC6** — Validaciones de password (≥8, upper, lower, digit) cubiertas en BE (§4.4) y FE (§4.15.4).
- [ ] **AC7** — CORS + CSRF configurados, `credentials: include` funciona (§4.8, §4.15.2).
- [ ] **AC8** — E2E (Playwright): registro → me → logout (§4.15.9).
- [ ] **AC9** — Backend specs ≥80% sobre `app/controllers/api/auth_controller.rb` (§5.1).
- [ ] **AC10** — Frontend tests ≥80% sobre componentes de auth (§5.2).
- [ ] **AC11** — Conventional commit `feat(auth): ...` (PR title MUST start with `feat(auth):`, no `[TAG]` prefix per release-please).
- [ ] **AC12** — Identifiers en inglés (model attrs, columns, controllers todo en EN; copy de UI en es-AR).

Adicionales del plan:

- [ ] **AC13** — Pundit harness en `Api::BaseController` (§4.5, §4.11) — listo para REQ-BE-00009/10.
- [ ] **AC14** — Alba + Oj configurados, `MeResource` serializa `User + carrier + shipper + roles[]` (§4.9, §4.12).
- [ ] **AC15** — `swagger.yaml` autogenerado por rswag, mounted en `/api-docs` (dev/test) (§4.13, §4.7), CI bloquea si drift (§4.16).
- [ ] **AC16** — Migración `password_digest` → `encrypted_password` reversible (§4.2, §5.1).

---

## 7. Files Summary

### New files

| File | Purpose |
|------|---------|
| `backend/db/migrate/<TS>_rename_password_digest_on_users.rb` | Rename column + Devise default |
| `backend/app/validators/password_complexity_validator.rb` | Custom validator (upper/lower/digit) |
| `backend/app/controllers/api/base_controller.rb` | API base — Devise, Pundit, errors, CSRF, helpers |
| `backend/app/controllers/api/auth_controller.rb` | register/login/logout/me/csrf |
| `backend/app/policies/application_policy.rb` | Pundit base |
| `backend/app/resources/user_resource.rb` | Alba |
| `backend/app/resources/carrier_resource.rb` | Alba |
| `backend/app/resources/shipper_resource.rb` | Alba |
| `backend/app/resources/me_resource.rb` | Alba composite |
| `backend/config/initializers/alba.rb` | Oj backend + AS inflector |
| `backend/config/initializers/rack_attack.rb` | Login throttle |
| `backend/spec/swagger_helper.rb` | rswag bootstrap |
| `backend/spec/requests/api/auth_spec.rb` | Request specs (also OpenAPI source) |
| `backend/spec/models/user_spec.rb` | Devise + password rules |
| `backend/spec/validators/password_complexity_validator_spec.rb` | Validator spec |
| `backend/spec/resources/me_resource_spec.rb` | Alba resource smoke |
| `backend/swagger/v1/swagger.yaml` | Generated — gitignored? NO, committed (drift check) |
| `frontend/src/auth/AuthContext.tsx` | Provider |
| `frontend/src/auth/useCurrentUser.ts` | Hook |
| `frontend/src/auth/RegisterPage.tsx` (+ `.module.css`) | UI |
| `frontend/src/auth/LoginPage.tsx` (+ `.module.css`) | UI |
| `frontend/src/components/Header.tsx` (+ `.module.css`) | Session widget |
| `frontend/src/routes.tsx` | Router scaffold |
| `frontend/src/auth/RegisterPage.test.tsx` | Vitest |
| `frontend/src/auth/LoginPage.test.tsx` | Vitest |
| `frontend/src/components/Header.test.tsx` | Vitest |
| `frontend/e2e/auth.spec.ts` | Playwright |
| `docs/features/REQ/REQ-BE-00023/REQ-BE-00023-auth-fullstack.plan.md` | This plan |

### Modified files

| File | Change |
|------|--------|
| `backend/Gemfile` | + pundit, alba, oj, rswag-{api,ui,specs}, rack-attack, rack-cors (if missing) |
| `backend/Gemfile.lock` | regenerated by `bundle install` |
| `backend/db/schema.rb` | regenerated by migration |
| `backend/app/models/user.rb` | Devise modules + password complexity |
| `backend/config/routes.rb` | + /api namespace + /api-docs mounts |
| `backend/config/initializers/cors.rb` | populated (was empty) |
| `backend/config/initializers/devise.rb` | mailer_sender pointed to env-based default (defensive) |
| `frontend/deno.json` | + react-router-dom |
| `frontend/src/api.ts` | + apiFetch wrapper + ApiError |
| `frontend/src/main.tsx` | mount `<AppRoutes />` |
| `frontend/src/App.tsx` | minor: ensure layout works under router |
| `frontend/src/test/mocks/handlers.ts` | + auth handlers |
| `.github/workflows/<backend-ci>.yml` | + swagger drift step |
| `.gdsi-sdlc/issues/Backlog/REQ-BE-00023-*.issue.md` → `Ready/` | git mv + frontmatter (`status: ready`, `plan:`) |
| `docs/features/ISSUES-INDEX.md` | row REQ-BE-00023: `NEW` → `RDY`, `-` → `[plan](...)` |

### Deliberately out of scope

- ADR file (`docs/03-architecture-diagrams/adr/ADR-009-session-cookie-auth.md`) — only if reviewer asks; the issue says "if not exists" and the rationale is captured in this plan.
- Welcome email — depends on `INF-BE-00005`.
- Password recovery / change-password — separate issues.
- Email verification — `REQ-BE-00028` / US22.

---

## 8. Notes for Implementer

1. **Run migration FIRST** before changing `User` model — Devise's `:database_authenticatable` requires `encrypted_password` column. `bin/rails db:migrate` then update `User`.
2. **Devise + Pundit + ActionController::API**: include `Devise::Controllers::Helpers` AFTER `ActionController::Cookies`. Order matters because of how before_actions resolve.
3. **CSRF in cross-origin cookie auth is delicate**: test with real browser (not just curl), DevTools Network tab to verify `Set-Cookie` and `X-CSRF-Token` flow.
4. **rack-attack uses Rails.cache** — confirm `config.cache_store` is set in development/test (Solid Cache in production). If not, throttling will be no-op.
5. **MSW v2 + Vitest**: confirm `frontend/src/test/setup.ts` already starts the MSW server (it imports `server.ts`). If not, add `beforeAll/afterAll` hooks.
6. **Impeccable skill**: before writing any TSX/CSS, **invoke the skill** at `frontend/.agents/skills/impeccable/`. Run its context-gathering protocol against `frontend/.impeccable.md`. Forms must follow trust-forward principles: clear labels, breathing room, ARIA states.
7. **Spanish copy**: every string user-visible must be es-AR. Form labels: "Email", "Contraseña", "Confirmar contraseña", "Nombre completo", "Soy: Cliente / Transportista / Ambos". Errors: "Email inválido", "La contraseña debe tener al menos 8 caracteres y contener una mayúscula, una minúscula y un número". CTA: "Crear cuenta", "Iniciar sesión", "Salir".
8. **PR title**: `feat(auth): implement registration, login, sessions and auth UI` — exact format. NO `[REQ-BE-00023]` prefix. Reference the TAG in the PR body (`Closes #103`).
9. **Branch is already `feat/auth-devise-pundit`** — do not rename.
10. **Commit hygiene**: split into logical commits if size warrants (e.g. `feat(auth): backend devise + endpoints`, `feat(auth): frontend register/login pages`, `chore(ci): swagger drift check`). Each must start with conventional type for release-please.
11. **Avoid touching `ApplicationController`** — leaves ActiveAdmin alone.
12. **`devise_for :users, skip: :all`** is intentional — we ship our own controllers but Devise still needs the route helper definitions to be registered for `sign_in`/`sign_out`.
