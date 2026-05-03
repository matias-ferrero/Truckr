# INF-BE-00003: Agregar ActiveAdmin al backend

| Field | Value |
|-------|-------|
| **Tag** | INF-BE-00003 |
| **Title** | Agregar ActiveAdmin al backend |
| **Priority** | P2 |
| **Status** | READY |
| **Created** | 2026-05-03 |
| **Updated** | 2026-05-03 |
| **Author** | Claude Code |
| **Depends On** | INF-GEN-00002 (backend ya scaffoldeado — ya cerrado) |
| **Decision Doc** | N/A |
| **Selected Approach** | N/A — single clear approach prescribed by the issue |

---

## 1. Problem Statement

El backend Rails 8.1 está scaffoldeado pero no expone superficie de administración. A medida que aparezcan los primeros modelos del dominio (transportistas, clientes, viajes, pagos), el equipo necesita CRUD de soporte para QA/demos/MVP sin construir un backoffice propio. ActiveAdmin cubre el caso con configuración mínima.

Sub-objetivos:

- Instalar ActiveAdmin + Devise compatibles con Rails 8.1.
- Aislar `AdminUser` (no es la auth de usuarios end-user; esa decisión queda fuera de scope).
- Garantizar que los assets de AA funcionan bajo Propshaft (asset pipeline default de Rails 8).
- Seed de admin parametrizable por env, sin hardcodear credenciales.
- Smoke test RSpec de `/admin`.
- Documentación en `backend/README.md`.

---

## 2. Solution Design

Instalar ActiveAdmin 3.x (versión que soporta Rails 8.1 — verificar `>= 3.2` al instalar) usando los generadores oficiales y aceptar Devise como dependencia transitiva. El generador deja la mayoría del boilerplate; el plan se centra en:

1. **Gemfile**: agregar `gem "activeadmin"` y `gem "devise"` (Devise se hace explícito para fijar versión compatible y porque AA depende de él). `sassc-rails` o `cssbundling-rails` solo se agregan **si** la instalación los requiere — Rails 8 con Propshaft puede servir los assets pre-compilados de AA sin Sprockets. Verificar al correr el generador y, si fuera necesario, documentar el shim.
2. **Generadores Rails**:
   - `rails g devise:install`
   - `rails g active_admin:install AdminUser` (genera modelo `AdminUser`, migraciones, `config/initializers/active_admin.rb`, `config/initializers/devise.rb`, monta `/admin`, crea `app/admin/admin_users.rb` y `app/admin/dashboard.rb`).
3. **Migraciones**: ejecutar `db:migrate` para crear `admin_users` y `active_admin_comments` en SQLite.
4. **Seed parametrizable**: ampliar `db/seeds.rb` para crear el admin inicial leyendo `SEED_ADMIN_EMAIL` / `SEED_ADMIN_PASSWORD`. En `development`/`test` aplicar fallback (`admin@example.com` / `password`); en `production` requerir las env vars y abortar si faltan. Idempotente (`find_or_create_by!`).
5. **Compatibilidad Propshaft**: AA 3.2+ ya envía sus CSS/JS con la gem. Si el generador agrega `import_active_admin` en `app/assets/stylesheets/active_admin.scss` y requiere Sprockets, optar por una de:
   - (a) Agregar `gem "sprockets-rails"` solo para los assets de AA si Propshaft no resuelve — **opción de fallback**, documentada.
   - (b) Aceptar la configuración default de AA con Propshaft si funciona out-of-the-box.

   El path de instalación se decide al correr el generador y verificar `/admin` en dev.
6. **Hosts permitidos**: agregar `localhost:3000` y, si hace falta para flujos detrás del frontend, declarar hosts en `config/environments/development.rb`. Default Rails 8 ya admite `*.local`. CSRF queda con la default de Rails (Devise se integra con `protect_from_forgery`).
7. **RSpec smoke**: nuevo `spec/requests/admin_spec.rb` con dos casos:
   - `GET /admin` redirige (302) o responde 200 si ya autenticado.
   - Login con `AdminUser` válido (creado en factory/`let!`) entra al dashboard.
8. **Docs**: agregar sección "Admin panel" en `backend/README.md` con: cómo correr seed, env vars, dónde registrar resources.

### Key Components

- `backend/Gemfile`, `backend/Gemfile.lock`
- `backend/config/initializers/active_admin.rb` (generado)
- `backend/config/initializers/devise.rb` (generado)
- `backend/config/routes.rb` (montaje de `/admin` y `devise_for :admin_users`)
- `backend/db/migrate/<ts>_devise_create_admin_users.rb` (generado)
- `backend/db/migrate/<ts>_create_active_admin_comments.rb` (generado)
- `backend/db/seeds.rb` (extendido)
- `backend/app/admin/admin_users.rb`, `app/admin/dashboard.rb` (generados)
- `backend/spec/requests/admin_spec.rb` (nuevo)
- `backend/README.md` (sección admin panel)

---

## 3. Implementation Tasks

| # | Task | Status | Files |
|---|------|--------|-------|
| 1 | Agregar `activeadmin` y `devise` al `Gemfile`, correr `bundle install` y verificar versión AA `>= 3.2` compatible Rails 8.1 | Pending | `backend/Gemfile`, `backend/Gemfile.lock` |
| 2 | Correr `rails g devise:install` y `rails g active_admin:install AdminUser`; revisar archivos generados | Pending | `backend/config/initializers/active_admin.rb`, `backend/config/initializers/devise.rb`, `backend/db/migrate/*`, `backend/app/admin/*`, `backend/config/routes.rb` |
| 3 | Ejecutar `db:migrate` y verificar que crea `admin_users` y `active_admin_comments` en SQLite | Pending | `backend/db/schema.rb` |
| 4 | Verificar `/admin` con `bin/rails server`; resolver shim de assets si Propshaft no sirve los CSS de AA | Pending | `backend/Gemfile` (si requiere `sprockets-rails`), `backend/app/assets/stylesheets/active_admin.scss` |
| 5 | Extender `db/seeds.rb` con admin parametrizable por `SEED_ADMIN_EMAIL`/`SEED_ADMIN_PASSWORD` (idempotente; fallback dev/test, abort en prod si faltan) | Pending | `backend/db/seeds.rb` |
| 6 | Crear smoke spec `spec/requests/admin_spec.rb` que verifica redirect 302 y login con `AdminUser` válido | Pending | `backend/spec/requests/admin_spec.rb`, `backend/spec/rails_helper.rb` (si se necesita helper Devise) |
| 7 | Documentar sección "Admin panel" en `backend/README.md` (env vars del seed, cómo registrar resources, URL del panel) | Pending | `backend/README.md` |
| 8 | Correr `bundle exec rspec` y `bin/rails db:seed` localmente; ejecutar `brakeman` y `bundler-audit` para no introducir regresiones de seguridad | Pending | — |

---

## 4. Code Changes

### 4.1 File: `backend/Gemfile`

**Purpose**: Agregar AA + Devise al stack.

```ruby
# ── Admin panel (ActiveAdmin + Devise) ──────────────────────────────────
gem "devise", "~> 4.9"
gem "activeadmin", ">= 3.2"
# Si Propshaft no sirve los assets de AA, descomentar:
# gem "sprockets-rails", require: "sprockets/railtie"
```

### 4.2 File: `backend/db/seeds.rb`

**Purpose**: Crear admin inicial idempotente, parametrizable por env, sin hardcodear credenciales en repo.

```ruby
admin_email    = ENV["SEED_ADMIN_EMAIL"]
admin_password = ENV["SEED_ADMIN_PASSWORD"]

if Rails.env.production?
  abort("SEED_ADMIN_EMAIL and SEED_ADMIN_PASSWORD must be set in production") if admin_email.blank? || admin_password.blank?
else
  admin_email    ||= "admin@example.com"
  admin_password ||= "password"
end

AdminUser.find_or_create_by!(email: admin_email) do |user|
  user.password              = admin_password
  user.password_confirmation = admin_password
end
```

### 4.3 File: `backend/spec/requests/admin_spec.rb` (new)

**Purpose**: Smoke test de `/admin` — redirect a login + login funcional.

```ruby
require "rails_helper"

RSpec.describe "Admin panel", type: :request do
  it "redirects unauthenticated requests to admin login" do
    get "/admin"
    expect(response).to have_http_status(:redirect)
    expect(response.location).to include("/admin/login")
  end

  context "with a valid AdminUser" do
    let!(:admin) { AdminUser.create!(email: "test-admin@example.com", password: "password", password_confirmation: "password") }

    it "lets the admin sign in and reach the dashboard" do
      post "/admin/login", params: {
        admin_user: { email: admin.email, password: "password" }
      }
      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Dashboard")
    end
  end
end
```

### 4.4 File: `backend/README.md`

**Purpose**: Documentar el panel admin.

````markdown
## Admin panel (ActiveAdmin)

The Rails app mounts an admin UI under `/admin` powered by ActiveAdmin + Devise.

### First-time setup

```sh
just backend-migrate                                  # creates admin_users + active_admin_comments
SEED_ADMIN_EMAIL=admin@truckr.local \
SEED_ADMIN_PASSWORD=changeme \
just backend-console -e "load 'db/seeds.rb'"          # or: cd backend && bin/rails db:seed
just backend-dev                                      # http://localhost:3000/admin
```

In `development` / `test`, missing env vars fall back to `admin@example.com` / `password`. **In `production`, the seed aborts unless both env vars are set.**

### Registering new admin resources

Add a file under `backend/app/admin/<resource>.rb`:

```ruby
ActiveAdmin.register Trip do
  permit_params :origin, :destination, :status
end
```

Restart the server; the resource appears in the sidebar.
````

---

## 5. Testing

### Unit Tests

- N/A (no business logic added beyond seed; seed is exercised via integration).

### Integration / Request Tests (RSpec)

- `GET /admin` unauthenticated → 302 redirect to `/admin/login`.
- `POST /admin/login` with valid `AdminUser` → reaches dashboard (200, body contains "Dashboard").

### Manual Verification

- `just backend-migrate` runs cleanly, schema includes `admin_users` and `active_admin_comments`.
- `just backend-dev` boots; `http://localhost:3000/admin` redirects to login; seeded admin can log in.
- `bundle exec brakeman --no-pager` and `bundle exec bundler-audit` run clean (no new high-severity findings).

---

## 6. Acceptance Criteria

- [ ] `activeadmin` (`>= 3.2`) y `devise` agregados al `Gemfile` con versiones compatibles con Rails 8.1; `bundle install` corre limpio.
- [ ] `rails g active_admin:install AdminUser` ejecutado; archivos generados commiteados (initializers, migraciones, registros base).
- [ ] `bin/rails db:migrate` aplica las migraciones de `AdminUser` y `ActiveAdmin::Comment` sin errores.
- [ ] `db:seed` crea un admin inicial leyendo `SEED_ADMIN_EMAIL` / `SEED_ADMIN_PASSWORD`; documentado el fallback en dev/test y el abort en prod.
- [ ] `/admin` accesible vía `just backend-dev`, login funcional con el seed.
- [ ] Assets de ActiveAdmin se sirven correctamente bajo Propshaft (o shim documentado en README + Gemfile si se requiere `sprockets-rails`).
- [ ] `backend/README.md` actualizado con sección "Admin panel": cómo crear admin, dónde se registran nuevos resources.
- [ ] `spec/requests/admin_spec.rb` con redirect-a-login y login-flow pasa en `bundle exec rspec`.
- [ ] `bundle exec brakeman` y `bundle exec bundler-audit` no agregan findings high-severity nuevos.
- [ ] Conventional Commits respetados (`feat(backend): add ActiveAdmin admin panel` o equivalente).

---

## 7. Files Summary

### New Files

| File | Description |
|------|-------------|
| `backend/config/initializers/active_admin.rb` | Generated by `active_admin:install` — AA config (auth method, namespace, etc.) |
| `backend/config/initializers/devise.rb` | Generated by `devise:install` — Devise defaults |
| `backend/db/migrate/<ts>_devise_create_admin_users.rb` | Generated migration for `admin_users` table |
| `backend/db/migrate/<ts>_create_active_admin_comments.rb` | Generated migration for AA comments table |
| `backend/app/admin/admin_users.rb` | Generated — registers AdminUser in AA |
| `backend/app/admin/dashboard.rb` | Generated — AA dashboard |
| `backend/app/models/admin_user.rb` | Generated — AdminUser model with Devise modules |
| `backend/app/assets/stylesheets/active_admin.scss` | Generated — AA stylesheet entry point (only if AA generator emits it) |
| `backend/spec/requests/admin_spec.rb` | Smoke test for `/admin` |

### Modified Files

| File | Changes |
|------|---------|
| `backend/Gemfile` | Add `activeadmin`, `devise` (and optionally `sprockets-rails` as documented fallback) |
| `backend/Gemfile.lock` | Lockfile update from `bundle install` |
| `backend/config/routes.rb` | Generated insertions: `devise_for :admin_users` + `ActiveAdmin.routes(self)` (mounts `/admin`) |
| `backend/db/schema.rb` | Reflects new tables after `db:migrate` |
| `backend/db/seeds.rb` | Adds idempotent admin seed reading `SEED_ADMIN_EMAIL` / `SEED_ADMIN_PASSWORD` |
| `backend/README.md` | New "Admin panel" section |
