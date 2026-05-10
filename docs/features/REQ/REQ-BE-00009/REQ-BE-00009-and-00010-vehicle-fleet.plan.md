# REQ-BE-00009 + REQ-BE-00010: Vehicle registration & multi-vehicle fleet (US14)

| Field | Value |
|-------|-------|
| **Tag** | REQ-BE-00009, REQ-BE-00010 |
| **Title** | Registro de vehículo + soporte multi-vehículo (flota) por transportista |
| **Priority** | P1 (00009) / P3 (00010) — joint to ship as one PR |
| **Status** | READY |
| **Created** | 2026-05-10 |
| **Updated** | 2026-05-10 |
| **Author** | Claude Code |
| **Depends On** | **REQ-BE-00023** (Auth fullstack — must merge first to provide `Api::BaseController` + `current_carrier` helper). Builds on `REQ-BE-00005` domain model and `REQ-BE-00020` Identity migrations. |
| **Decision Doc** | N/A — joint PR is the design decision; rationale captured below. |
| **Selected Approach** | Land 00009's domain (columns + ActiveStorage + form) and 00010's evolution (multi-vehicle list + `vehicle_id` on `TransportWindow`) in **one PR** with **squashed migrations** so the staging conflict between 00009's `unique index on carrier_id` and 00010's "drop the unique index" never materialises. |

---

## 1. Problem Statement

US14 ("registrar mi vehículo / mi flota") fue partido en dos issues:

- **REQ-BE-00009** — registración 1 carrier ↔ 1 vehículo, datos básicos (modelo, año, dimensiones, fotos), pantalla `/transportista/vehiculo`. Pide explícitamente `unique index on carrier_id`.
- **REQ-BE-00010** — levantar la restricción 1:1, lista `/transportista/vehiculos`, selector de vehículo al publicar `TransportWindow`.

Estado actual del repo (worktree `feat/vehicle-fleet-crud` sobre `origin/main`):

- `backend/app/models/vehicle.rb` ya existe con `plate`, `capacity_kg`, `vehicle_type`, `gps_enabled`, `belongs_to :carrier`.
- `backend/db/migrate/20260509120004_create_vehicles.rb` NO tiene `unique index on carrier_id`. Sólo `add_index :vehicles, :plate, unique: true`.
- `backend/app/models/carrier.rb` declara `has_many :vehicles` y `has_many :transport_windows, through: :vehicles` — **ya asume multi-vehicle**.
- `backend/app/models/transport_window.rb` y su migración `20260509120005_create_transport_windows.rb` ya tienen `t.references :vehicle, null: false, foreign_key: { to_table: :vehicles, on_delete: :cascade }` y guard `no_vehicle_overlap`. **`vehicle_id` ya está**.
- `Gemfile` tiene `image_processing ~> 1.2`, ActiveStorage cargado en `application.rb`, `storage.yml` con `local`/`test` Disk service. Pundit / Alba / Oj / Pagy / rswag **no instalados todavía**; rswag llega con la PR de auth.
- Frontend: `App.tsx` es una landing estática; no hay router, no hay rutas autenticadas, `api.ts` sólo exporta `API_BASE_URL`.

El issue 00009 fue redactado asumiendo el caso 1:1 como punto de partida. Como el código **ya** modela multi-vehicle correctamente y vamos a entregar 00010 inmediatamente después, **agregar y luego remover el unique index es churn puro** y deja la rama intermedia rota para terceros. La solución es consolidar.

---

## 2. Solution Design

### 2.1 Approach — joint PR, squashed migrations

El PR ejecuta 00009 y 00010 en una sola secuencia lineal:

1. **Backend**: agregar columnas faltantes a `vehicles` (00009) **sin** introducir el unique index en `carrier_id` (saltado); aprovechar la misma migración para confirmar que `transport_windows.vehicle_id` ya cumple el requisito de 00010. Dos migraciones nuevas como máximo (una para columnas de Vehicle, otra opcional si hay que tocar índices). ActiveStorage attachments via modelo (no requieren migración propia salvo `bin/rails active_storage:install` si no corrió).
2. **Modelo Vehicle**: agregar atributos, `has_many_attached :photos`, validaciones (year, dimensions, plate, max 5 photos), `before_save` para `volume_cm3`, mantener `vehicle_type` y `capacity_kg` por compat (ver §2.3 abajo).
3. **API**: namespace `/api`, `Api::BaseController` (provee `current_carrier`, error envelope, `Pundit::Authorization`, `Pagy::Backend`); `Api::Carriers::VehiclesController` con index/show/create/update/destroy; `Api::Carriers::MeController#vehicles` ó `nested under /api/carriers/me/vehicles`. `VehiclePolicy` keyed en `record.carrier == user&.carrier`. `VehicleResource` (Alba+Oj) con attribute selection y `has_many :photos`. Pagy headers para listas.
4. **OpenAPI**: rswag request specs por endpoint, `swagger.yaml` regenerado.
5. **Frontend**: introducir `react-router-dom@6`, sacar el render estático de `App.tsx` a una landing route, agregar layout `RequireAuth` (lee `current_user` del context que provee la PR de auth — si todavía no está, mock `useCurrentCarrier()` y dejar `// TODO: wire to /api/auth/me` en un único punto). Páginas:
   - `/transportista/vehiculo` — single-vehicle form (00009). Si el carrier tiene 0 vehículos: form de creación; si tiene exactamente 1: form de edición pre-rellenado. Si tiene N>1: redirect a `/transportista/vehiculos`.
   - `/transportista/vehiculos` — fleet list (00010). Tabla/cards con CTA "Agregar vehículo" → ruta `/transportista/vehiculo/nuevo`; cada card tiene "editar" y "eliminar".
6. **Drag-drop uploader**: `react-dropzone` para fotos, preview thumbnails con object URLs, `multipart/form-data` POST. Up to 5 photos per vehicle (server enforces; client warns).
7. **Tests**: RSpec model + policy + request specs (rswag-doubled); Vitest para form + list components; Playwright happy-path E2E (login fixture → crear → listar → eliminar).
8. **Impeccable skill**: invocar `frontend/.agents/skills/impeccable` durante implementación de las dos pantallas para que el resultado cumpla el north-star de `.impeccable.md` (trust before flourish, accessible by default, fast-feeling UI).

### 2.2 Key Design Decisions

#### Decisión A — Skip the `unique index on carrier_id` from 00009

- **Decisión**: nunca lo agregamos. El PR final no lo introduce ni lo quita.
- **Rationale**: el código actual de `Carrier`/`TransportWindow` ya asume `has_many :vehicles`. Ponerlo y sacarlo en el mismo PR genera dos migraciones que se cancelan (commit churn, riesgo de orden de aplicación, falsos conflictos en `schema.rb`). El AC "1 vehículo máx por carrier" del 00009 se reinterpreta como "el flujo single-vehicle de UI no asume más de uno" (ya se cumple con `/transportista/vehiculo`).
- **Trade-off**: si el reviewer quiere ver explícitamente la restricción de 00009 antes de levantarla, el commit log no lo va a mostrar. Lo documentamos en este plan y en la PR description.

#### Decisión B — `capacity_kg` (integer, existing) vs `max_load_kg` (decimal, new)

- **Decisión**: **renombrar** `capacity_kg` → `max_load_kg` y **cambiar el tipo** a `decimal(10,2)` en una sola migración (`rename_column` + `change_column`). Mantener el comportamiento de validación (`> 0`).
- **Rationale**: el modelo solo tiene una semántica de "capacidad de carga"; mantener dos columnas (una decimal nueva + una integer vieja) es deuda inmediata. La migración tipo `change_column` requiere SQLite copy-table-and-rebuild — Rails 8.1 lo maneja transparente vía `change_table` + `up`/`down` reversibles. Como no hay datos productivos (greenfield), drop+re-add es aceptable; preferimos rename+change para preservar `t.references` semantics si la columna se usara en otro lado (no se usa).
- **Trade-off**: si alguien tiene una rama con `capacity_kg` referenciado, va a romper. Mitigación: este es greenfield; no hay otras ramas activas usando ese atributo.
- **Backout**: la migración es reversible.

#### Decisión C — Volume computed in `before_save`

- `volume_cm3` se computa como `length_cm * width_cm * height_cm` en un callback. Se persiste para evitar recomputarlo en queries y filtros futuros (ej. "vehículos con volumen ≥ X"). Si alguna dimensión es `nil`, `volume_cm3 = nil`.
- Alternativa rechazada: virtual attribute. Justificación: queremos indexarlo eventualmente y exponerlo serializado.

#### Decisión D — Photos as `has_many_attached`, max 5, with variants

- `has_many_attached :photos`. Validation custom: `photos.size <= 5` y content_type whitelist (`image/jpeg`, `image/png`, `image/webp`).
- Variants definidos como named variants en el modelo: `:thumbnail` 200×200 (cover), `:card` 600×400 (cover), `:full` 1200×800 (resize_to_limit). Usamos `image_processing` (ya en Gemfile) con libvips si está disponible (Rails 8.1 default), fallback a MiniMagick.
- URLs serializadas via `Rails.application.routes.url_helpers.url_for(photo.variant(:card).processed)` dentro del `VehicleResource`. Disk service para dev; S3 es un INF issue separado (citado en §6 fuera-de-scope).

#### Decisión E — `transport_windows.vehicle_id` already exists → 00010 work reduces

- La migración inicial de `TransportWindow` ya tiene `t.references :vehicle, null: false, foreign_key: { ... on_delete: :cascade }`. **No hay nada que migrar para 00010 a nivel DB**. El AC "agregar `vehicle_id` a `transport_windows`" está resuelto a priori.
- 00010 entonces se reduce a: (a) endpoints CRUD de lista (no solo singular), (b) UI de fleet list, (c) UI de selector de vehículo en el wizard de TransportWindow (cuya pantalla aún no existe — el selector se entrega como **componente reutilizable** `<VehicleSelect />` que la futura `REQ-FE-00016` consumirá; documentamos el contrato), (d) tests del segundo vehículo.
- Backfill: empty backfill — no hay filas en `transport_windows` en greenfield. Documentamos el `null: false` ya presente como suficiente.

#### Decisión F — Pundit, Alba+Oj, Pagy as foundational additions in this PR

- Estos tres son **prerequisitos** para 00009/00010 pero no se introdujeron antes. Los agregamos en este PR como changes de Gemfile + initializers + concern en `Api::BaseController`. El PR de auth (REQ-BE-00023) también los necesita; quien mergee primero los aporta. Si auth mergea antes (esperado), aquí sólo verificamos que existan.
- **rswag**: viene con auth. Si no llega, lo agregamos defensivamente; sus generators no impactan código de runtime.

#### Decisión G — Routing strategy on the frontend

- Adoptamos `react-router-dom@6` ahora. La alternativa "conditional rendering en `App.tsx`" no escala: REQ-BE-00023 (auth) trae al menos 3 rutas (`/registro`, `/login`, `/`), 00009/00010 trae 2 más (`/transportista/vehiculo`, `/transportista/vehiculos`), y la roadmap inmediata trae más (US10 bandeja, US9 publish window). Hacer el switch ahora evita un refactor en el siguiente PR.
- Estructura propuesta: `frontend/src/App.tsx` se reduce a `<RouterProvider router={router}/>`; `frontend/src/router.tsx` declara las rutas; el contenido actual de la landing se mueve a `frontend/src/pages/Landing.tsx` (intacto). Coordinación con `INF-FE-00003` (routing scaffold separate issue): si éste mergea antes, aprovechamos su scaffold; si no, el de aquí lo cumple.

### 2.3 Out of Scope

| Item | Reason |
|------|--------|
| S3 / minio adapter para ActiveStorage | INF issue separado. |
| `VehicleSelect` integrado dentro de un wizard de `TransportWindow` | Pertenece a REQ-FE-00016 (US9). Aquí sólo entregamos el componente como standalone reusable + tests. |
| Galería de vehículos en perfil público de carrier (US6) | REQ-FE-00014. Aquí sólo exponemos el endpoint público `GET /api/carriers/:id/vehicles`. |
| Soft-delete de Vehicle | Decisión C en REQ-BE-00005 plan: hard-delete por default. Vehicle va con `dependent: :destroy`. El guard `before_destroy :ensure_no_active_commitments` (ya existe en el modelo) impide eliminar si hay quotes vivas. |
| GPS / IoT integration de `gps_enabled` | Sólo es un boolean por ahora, sin lógica asociada. |
| Pagination cursor-based | Pagy offset alcanza para MVP. |
| AdminUser ↔ Vehicle | ActiveAdmin auto-genera read-only resource si lo declaramos; lo agregamos en INF-BE-00003 si no está cubierto allí. Fuera de scope aquí. |

---

## 3. Implementation Tasks

Cada tarea anota a qué issue corresponde. Marcadas `[A]` para 00009 (registro), `[B]` para 00010 (flota), `[A+B]` para work compartido.

### 3.1 Backend — gems & infrastructure  `[A+B]`

1. **Gemfile**: agregar (o verificar que la PR de auth ya agregó):
   ```ruby
   gem "pundit", "~> 2.4"
   gem "alba",   "~> 3.5"
   gem "oj",     "~> 3.16"
   gem "pagy",   "~> 9.0"
   group :development, :test do
     gem "rswag-specs", "~> 2.13"
   end
   gem "rswag-api", "~> 2.13"
   gem "rswag-ui", "~> 2.13"
   ```
2. **`config/initializers/alba.rb`**: `Alba.backend = :oj` y `Alba.inflector = :active_support`.
3. **`config/initializers/pagy.rb`**: `require "pagy/extras/headers"`, `Pagy::DEFAULT[:items] = 20`, `Pagy::DEFAULT[:max_items] = 100`.
4. **`config/initializers/pundit.rb`**: vacío salvo `# require "pundit"` para asegurar autoload (en práctica innecesario; documentado).
5. **`config/initializers/rswag_api.rb` / `rswag_ui.rb`**: generated via `rails g rswag:install`. Coordinar con auth PR para no duplicar.
6. **`app/controllers/api/base_controller.rb`** (nueva, si no existe ya por auth):
   ```ruby
   class Api::BaseController < ActionController::API
     include Pundit::Authorization
     include Pagy::Backend

     before_action :authenticate_user!  # provided by auth PR
     rescue_from Pundit::NotAuthorizedError, with: :forbidden
     rescue_from ActiveRecord::RecordNotFound, with: :not_found
     rescue_from ActiveRecord::RecordInvalid, with: :unprocessable

     after_action { pagy_headers_merge(@pagy) if @pagy }

     def current_carrier = current_user&.carrier

     private

     def forbidden(_e)     = render(json: { error: "forbidden" }, status: :forbidden)
     def not_found(_e)     = render(json: { error: "not_found" }, status: :not_found)
     def unprocessable(e)  = render(json: { error: "validation_failed", details: e.record.errors }, status: :unprocessable_entity)
   end
   ```

### 3.2 Backend — migrations  `[A+B]`

7. **Migration `xxxxxxxxxxxxxx_extend_vehicles_for_registration.rb`** `[A]`:
   - `rename_column :vehicles, :capacity_kg, :max_load_kg`
   - `change_column :vehicles, :max_load_kg, :decimal, precision: 10, scale: 2, null: false, default: 0`
   - `add_column :vehicles, :make, :string, null: false, default: ""`
   - `add_column :vehicles, :model, :string, null: false, default: ""`
   - `add_column :vehicles, :year, :integer`
   - `add_column :vehicles, :length_cm, :integer`
   - `add_column :vehicles, :width_cm, :integer`
   - `add_column :vehicles, :height_cm, :integer`
   - `add_column :vehicles, :volume_cm3, :bigint`
   - `add_column :vehicles, :description, :text`
   - `add_index  :vehicles, :carrier_id` *(non-unique; supports `me/vehicles` listing)*

   Reversible. Defaults `""` / `0` solo para satisfacer `null: false` durante el rename (no hay rows).
8. **NO MIGRATION** for unique-index-on-carrier-id (00009 AC dropped — see Decisión A).
9. **NO MIGRATION** for `transport_windows.vehicle_id` (already present — see Decisión E).

### 3.3 Backend — model layer  `[A+B]`

10. **`app/models/vehicle.rb`** `[A]`:
    - `has_many_attached :photos` con `service: :local` (default).
    - `validates :make, :model, presence: true, length: { maximum: 64 }`.
    - `validates :year, numericality: { only_integer: true, greater_than: 1980, less_than_or_equal_to: ->(v) { Date.current.year + 1 } }, allow_nil: false` (form pide year).
    - `validates :max_load_kg, numericality: { greater_than: 0 }`.
    - `validates :length_cm, :width_cm, :height_cm, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true` (opcional para MVP).
    - `validate :photos_count_within_limit` (≤ 5).
    - `validate :photos_content_type` (jpeg/png/webp).
    - `before_save :compute_volume_cm3`.
    - Update `ransackable_attributes` to include new columns.
    - Variants helper: `def photo_variants(photo)` returning `{ thumbnail:, card:, full: }` URLs.
11. **`app/models/carrier.rb`** `[B]` — sin cambios (ya tiene `has_many :vehicles`). Confirmar.
12. **`app/policies/application_policy.rb`** `[A+B]` — boilerplate Pundit (si no llega de la auth PR).
13. **`app/policies/vehicle_policy.rb`** `[A+B]`:
    ```ruby
    class VehiclePolicy < ApplicationPolicy
      def index?   = true                       # public for /api/carriers/:id/vehicles
      def show?    = true
      def create?  = user&.carrier.present? && record.carrier == user.carrier
      def update?  = create?
      def destroy? = create?

      class Scope < Scope
        def resolve
          # /me/vehicles → carrier_scope; public listings → all (controller picks)
          scope.where(carrier_id: user.carrier.id) if user&.carrier
        end
      end
    end
    ```
14. **`app/resources/vehicle_resource.rb`** `[A]`:
    ```ruby
    class VehicleResource
      include Alba::Resource
      attributes :id, :make, :model, :year, :plate, :vehicle_type,
                 :max_load_kg, :length_cm, :width_cm, :height_cm,
                 :volume_cm3, :gps_enabled, :description,
                 :created_at, :updated_at
      attribute :photos do |v|
        v.photos.map { |p| { id: p.id, **v.photo_variants(p) } }
      end
      # Slim variant for collection listings:
      ROOT_KEY = :vehicle
      def self.list = with({ except: %i[length_cm width_cm height_cm description] })
    end
    ```

### 3.4 Backend — controllers & routes  `[A+B]`

15. **`config/routes.rb`** `[A+B]`:
    ```ruby
    namespace :api do
      resources :carriers, only: [] do
        resources :vehicles, only: [:index, :show], controller: "carriers/vehicles"
        scope module: "carriers" do
          collection do
            get :me, to: "me#show"  # placeholder for auth PR
          end
        end
      end
      scope "/carriers/me", module: "carriers/me" do
        resources :vehicles, only: [:index, :create, :show, :update, :destroy]
      end
    end
    mount Rswag::Api::Engine  => "/api-docs"
    mount Rswag::Ui::Engine   => "/api-docs"
    ```
    *(Adjust nesting to match auth PR conventions if they differ.)*
16. **`app/controllers/api/carriers/vehicles_controller.rb`** `[A+B]` — public read endpoints:
    ```ruby
    class Api::Carriers::VehiclesController < Api::BaseController
      skip_before_action :authenticate_user!, only: %i[index show]

      def index
        carrier = Carrier.find(params[:carrier_id])
        @pagy, vehicles = pagy(carrier.vehicles)
        render json: VehicleResource.list.new(vehicles).serialize
      end

      def show
        vehicle = Vehicle.find(params[:id])
        authorize vehicle, :show?
        render json: VehicleResource.new(vehicle).serialize
      end
    end
    ```
17. **`app/controllers/api/carriers/me/vehicles_controller.rb`** `[A+B]` — authenticated CRUD:
    ```ruby
    class Api::Carriers::Me::VehiclesController < Api::BaseController
      def index
        @pagy, vehicles = pagy(policy_scope(Vehicle))
        render json: VehicleResource.list.new(vehicles).serialize
      end

      def create
        vehicle = current_carrier.vehicles.build(vehicle_params)
        authorize vehicle
        vehicle.save!
        render json: VehicleResource.new(vehicle).serialize, status: :created
      end

      def update
        vehicle = current_carrier.vehicles.find(params[:id])
        authorize vehicle
        vehicle.update!(vehicle_params)
        render json: VehicleResource.new(vehicle).serialize
      end

      def destroy
        vehicle = current_carrier.vehicles.find(params[:id])
        authorize vehicle
        vehicle.destroy!
        head :no_content
      end

      private

      def vehicle_params
        params.require(:vehicle).permit(
          :make, :model, :year, :plate, :vehicle_type, :max_load_kg,
          :length_cm, :width_cm, :height_cm, :description, :gps_enabled,
          photos: []
        )
      end
    end
    ```

### 3.5 Backend — OpenAPI specs (rswag)  `[A+B]`

18. **`spec/swagger_helper.rb`** — schemas `Vehicle`, `VehicleSlim`, `Photo`, `Pagination`, `ErrorEnvelope`. Coordinate with auth PR's helper.
19. **`spec/requests/api/carriers/vehicles_spec.rb`** `[A]` — `index`, `show` con rswag DSL.
20. **`spec/requests/api/carriers/me/vehicles_spec.rb`** `[A+B]` — full CRUD con rswag, multipart for `create` (photos), pagination assertion en `index` (`X-Page`, `X-Total` headers), unauthorized scenarios (403 / 401), validation errors (422 envelope shape).
21. **`rake rswag:specs:swaggerize`** y commit del `swagger.yaml` resultante.

### 3.6 Frontend — routing scaffold & API client  `[A+B]`

22. **`frontend/deno.json`**: agregar `react-router-dom@^6.26`, `react-dropzone@^14.2`, `clsx@^2.1`. Mantener imports map.
23. **`frontend/src/main.tsx`**: envolver `<App />` con `<RouterProvider router={router}/>`.
24. **`frontend/src/router.tsx`** (nuevo) — declara rutas:
    ```ts
    import { createBrowserRouter } from "react-router-dom";
    import Landing from "./pages/Landing";
    import VehicleForm from "./pages/transportista/VehicleForm";
    import VehicleList from "./pages/transportista/VehicleList";
    import RequireCarrier from "./auth/RequireCarrier";

    export const router = createBrowserRouter([
      { path: "/", element: <Landing /> },
      {
        path: "/transportista",
        element: <RequireCarrier />,
        children: [
          { path: "vehiculo", element: <VehicleForm /> },
          { path: "vehiculo/nuevo", element: <VehicleForm mode="new" /> },
          { path: "vehiculos", element: <VehicleList /> },
        ],
      },
    ]);
    ```
25. **`frontend/src/pages/Landing.tsx`** — extraer el contenido actual de `App.tsx`. `App.tsx` queda como wrapper.
26. **`frontend/src/auth/RequireCarrier.tsx`** — `<Outlet/>` si `useCurrentCarrier()` resolves; redirect a `/login` si no. Provider stub si la auth PR no mergeó todavía: lee `localStorage.token` y llama `GET /api/auth/me`. Marcar con `// TODO(REQ-BE-00023): replace with shared AuthContext from auth PR`.
27. **`frontend/src/api/vehicles.ts`** — typed client:
    ```ts
    export type Vehicle = { id: number; make: string; model: string; year: number; plate: string; max_load_kg: string; ... };
    export const listMyVehicles = async (page = 1) => fetch(`${API_BASE_URL}/api/carriers/me/vehicles?page=${page}`, { credentials: "include" }).then(handle);
    export const createVehicle = async (form: FormData) => fetch(`${API_BASE_URL}/api/carriers/me/vehicles`, { method: "POST", body: form, credentials: "include" }).then(handle);
    export const updateVehicle = async (id: number, form: FormData) => ...;
    export const deleteVehicle = async (id: number) => ...;
    ```

### 3.7 Frontend — single-vehicle form `/transportista/vehiculo`  `[A]`

28. **`frontend/src/pages/transportista/VehicleForm.tsx`** — controlled form + `<PhotoUploader />` (drag-drop with `react-dropzone`).
    - Fields: marca, modelo, año, patente, tipo (select), capacidad de carga (kg), largo/ancho/alto (cm), GPS (toggle), descripción (textarea).
    - Live volume preview as user types dimensions.
    - Plate format hint (es-AR: `AA123BB` o `AAA123`); regex client-side, soft warning if fails.
    - Photo grid: thumbnails of selected files, click-to-remove, "+ Agregar" tile, max 5 enforced (CTA disabled at limit).
    - Submit: `multipart/form-data`. Optimistic toast on success, redirect to `/transportista/vehiculos` (00010 lo gobierna; en flujo single-vehicle, redirect a la misma página en modo "view").
    - **Invocar skill `frontend/.agents/skills/impeccable`** durante implementación de esta pantalla y de `VehicleList`. Cumplir north-star (focus states, reduced-motion, ARIA labels en uploader).
29. **`frontend/src/pages/transportista/PhotoUploader.tsx`** (componente reusable) — encapsula `react-dropzone`, manage previews via `URL.createObjectURL`, revoke on unmount.

### 3.8 Frontend — fleet list `/transportista/vehiculos`  `[B]`

30. **`frontend/src/pages/transportista/VehicleList.tsx`**:
    - Header: "Mi flota", CTA primario `<Link to="/transportista/vehiculo/nuevo">Agregar vehículo</Link>`.
    - Grid de cards: foto principal + marca/modelo/año + patente + capacidad. Acciones: "Editar" → `/transportista/vehiculo?id=X`, "Eliminar" (confirm dialog).
    - Empty state: ilustración + CTA. Loading state: skeletons. Error state: retry button.
    - Pagination: leer header `X-Total`, render simple "Página N de M".
31. **`frontend/src/components/VehicleSelect.tsx`** `[B]` — dropdown standalone, fetches `/me/vehicles?items=100`, autoselects único si N=1, exposed prop API for futura `TransportWindowForm` (REQ-FE-00016). No se monta en runtime aún; sólo se exporta y se testea unitariamente.

### 3.9 Tests  `[A+B]`

32. **Backend RSpec**:
    - `spec/models/vehicle_spec.rb` — validations (year, dims, plate format, photos count, content_type), `before_save :compute_volume_cm3` calc, `before_destroy` guard with active quotes.
    - `spec/policies/vehicle_policy_spec.rb` — matrix: anonymous, other_carrier, owner_carrier, shipper.
    - `spec/requests/api/carriers/vehicles_spec.rb` (rswag) — public reads.
    - `spec/requests/api/carriers/me/vehicles_spec.rb` (rswag) — full CRUD + multipart photos + pagination headers + 401/403/422 envelopes + multi-vehicle scenarios (`[B]`: create second vehicle, list returns both, delete one leaves other).
33. **Frontend Vitest**:
    - `VehicleForm.test.tsx` — render, submit happy path with mocked `createVehicle`, photo limit enforcement, plate format warning.
    - `VehicleList.test.tsx` — empty / single / many states, delete flow, pagination.
    - `PhotoUploader.test.tsx` — drop accept/reject, max 5 enforcement, removal.
    - `VehicleSelect.test.tsx` `[B]` — auto-select with N=1, manual select with N>1, loading/error states.
34. **Playwright E2E** `frontend/e2e/transportista-vehicle.spec.ts`:
    - Login fixture (uses auth API route from REQ-BE-00023; marked `test.skip` until auth PR merges).
    - Create vehicle → assert appears in `/transportista/vehiculos` → delete → assert empty state.
    - Verify drag-drop uploader receives a sample image.
35. CI: ensure `bin/rspec`, `deno task test`, `deno task test:e2e` run green. Frontend CI workflow may need to be added (`INF-INFRA-00002`); coordinate.

### 3.10 Issue management & ISSUES-INDEX  `[A+B]`

36. Update `.gdsi-sdlc/issues/Backlog/REQ-BE-00009-...issue.md` frontmatter: `status: ready`, `plan: docs/features/REQ/REQ-BE-00009/REQ-BE-00009-and-00010-vehicle-fleet.plan.md`. `git mv` to `Ready/`.
37. Update `.gdsi-sdlc/issues/Backlog/REQ-BE-00010-...issue.md` frontmatter: `status: ready`, `plan: docs/features/REQ/REQ-BE-00010/REQ-BE-00010-fleet-support.plan.md`. `git mv` to `Ready/`.
38. Stub plan at `docs/features/REQ/REQ-BE-00010/REQ-BE-00010-fleet-support.plan.md` pointing to the joint plan.
39. Update `docs/features/ISSUES-INDEX.md`: REQ-BE-00009 row → `RDY` + plan link to joint; REQ-BE-00010 row → `RDY` + plan link to stub.

---

## 4. Code Changes (key snippets per file)

### 4.1 New file: `backend/db/migrate/<TS>_extend_vehicles_for_registration.rb`  `[A]`

```ruby
class ExtendVehiclesForRegistration < ActiveRecord::Migration[8.1]
  def change
    rename_column :vehicles, :capacity_kg, :max_load_kg
    change_column :vehicles, :max_load_kg, :decimal, precision: 10, scale: 2, null: false, default: 0

    add_column :vehicles, :make,        :string,  null: false, default: ""
    add_column :vehicles, :model,       :string,  null: false, default: ""
    add_column :vehicles, :year,        :integer
    add_column :vehicles, :length_cm,   :integer
    add_column :vehicles, :width_cm,    :integer
    add_column :vehicles, :height_cm,   :integer
    add_column :vehicles, :volume_cm3,  :bigint
    add_column :vehicles, :description, :text

    add_index :vehicles, :carrier_id
  end
end
```

### 4.2 Modified: `backend/app/models/vehicle.rb`  `[A]`

```ruby
class Vehicle < ApplicationRecord
  VEHICLE_TYPES = %w[van truck_small truck_large semi_trailer].freeze
  PHOTO_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  MAX_PHOTOS = 5

  belongs_to :carrier
  has_many   :transport_windows, dependent: :restrict_with_error
  has_many_attached :photos

  before_save   :compute_volume_cm3
  before_destroy :ensure_no_active_commitments

  validates :plate, presence: true, uniqueness: { case_sensitive: false }, length: { in: 6..8 }
  validates :make, :model, presence: true, length: { maximum: 64 }
  validates :year,
            numericality: { only_integer: true, greater_than: 1980,
                            less_than_or_equal_to: ->(_v) { Date.current.year + 1 } }
  validates :max_load_kg, numericality: { greater_than: 0 }
  validates :vehicle_type, inclusion: { in: VEHICLE_TYPES }
  validates :length_cm, :width_cm, :height_cm,
            numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validate  :photos_within_limit
  validate  :photos_have_allowed_content_type

  def photo_variants(photo)
    {
      thumbnail: Rails.application.routes.url_helpers.url_for(photo.variant(resize_to_fill: [200, 200]).processed),
      card:      Rails.application.routes.url_helpers.url_for(photo.variant(resize_to_fill: [600, 400]).processed),
      full:      Rails.application.routes.url_helpers.url_for(photo.variant(resize_to_limit: [1200, 800]).processed),
    }
  end

  def self.ransackable_attributes(_ = nil)
    %w[id carrier_id plate make model year vehicle_type max_load_kg
       length_cm width_cm height_cm volume_cm3 gps_enabled created_at updated_at]
  end
  def self.ransackable_associations(_ = nil) = %w[carrier transport_windows]

  private

  def compute_volume_cm3
    self.volume_cm3 = if [length_cm, width_cm, height_cm].all?(&:present?)
                        length_cm * width_cm * height_cm
                      end
  end

  def photos_within_limit
    errors.add(:photos, "max #{MAX_PHOTOS}") if photos.attached? && photos.size > MAX_PHOTOS
  end

  def photos_have_allowed_content_type
    return unless photos.attached?
    photos.each do |p|
      next if PHOTO_CONTENT_TYPES.include?(p.content_type)
      errors.add(:photos, "invalid content_type #{p.content_type}")
    end
  end

  def ensure_no_active_commitments
    return unless defined?(Quote) && defined?(TransportWindow)
    has_live_quote = Quote.joins(:transport_window)
                          .where(transport_windows: { vehicle_id: id })
                          .where.not(status: %w[expired cancelled])
                          .exists?
    throw(:abort) if has_live_quote
  end
end
```

### 4.3 New: `backend/app/policies/vehicle_policy.rb`  `[A+B]`

(See snippet in §3.3.13.)

### 4.4 New: `backend/app/resources/vehicle_resource.rb`  `[A]`

(See snippet in §3.3.14.)

### 4.5 New: `backend/app/controllers/api/base_controller.rb`  `[A+B]`

(See snippet in §3.1.6 — gated on auth PR not having created it.)

### 4.6 New: `backend/app/controllers/api/carriers/vehicles_controller.rb`  `[A+B]`

(See snippet in §3.4.16.)

### 4.7 New: `backend/app/controllers/api/carriers/me/vehicles_controller.rb`  `[A+B]`

(See snippet in §3.4.17.)

### 4.8 Modified: `backend/config/routes.rb`  `[A+B]`

(See snippet in §3.4.15.)

### 4.9 Modified: `backend/Gemfile`  `[A+B]`

(See gem list in §3.1.1.)

### 4.10 New initializers: `alba.rb`, `pagy.rb`  `[A+B]`

```ruby
# config/initializers/alba.rb
require "alba"
require "oj"
Alba.backend = :oj
Alba.inflector = :active_support
```

```ruby
# config/initializers/pagy.rb
require "pagy/extras/headers"
Pagy::DEFAULT[:items]     = 20
Pagy::DEFAULT[:max_items] = 100
```

### 4.11 New rswag specs (skeleton)  `[A+B]`

```ruby
# spec/requests/api/carriers/me/vehicles_spec.rb
require "swagger_helper"

RSpec.describe "/api/carriers/me/vehicles", type: :request do
  path "/api/carriers/me/vehicles" do
    get("list my vehicles") do
      tags "Vehicles"
      produces "application/json"
      security [bearer_auth: []]
      parameter name: :page, in: :query, type: :integer, required: false

      response(200, "successful") do
        schema "$ref" => "#/components/schemas/VehicleListResponse"
        run_test! { expect(response.headers["X-Total"]).to be_present }
      end
      response(401, "unauthorized") { run_test! }
    end

    post("create vehicle") do
      consumes "multipart/form-data"
      parameter name: :vehicle, in: :formData, schema: { "$ref" => "#/components/schemas/VehicleCreate" }
      response(201, "created") { run_test! }
      response(422, "validation failed") { run_test! }
    end
  end
  # ... show / update / destroy
end
```

### 4.12 Frontend: `frontend/src/router.tsx`, `pages/transportista/VehicleForm.tsx`, `VehicleList.tsx`, `PhotoUploader.tsx`, `components/VehicleSelect.tsx`, `api/vehicles.ts`, `auth/RequireCarrier.tsx`

(Architecture in §3.6–§3.8; bodies generated during implementation under impeccable skill.)

### 4.13 Modified: `.gdsi-sdlc/issues/Ready/REQ-BE-00009-registro-de-vehiculo-datos-y-fotos.issue.md`  `[A]`

```diff
 ---
 tag: REQ-BE-00009
 ...
-status: backlog
+status: ready
 ...
+plan: docs/features/REQ/REQ-BE-00009/REQ-BE-00009-and-00010-vehicle-fleet.plan.md
 ---
```

### 4.14 Modified: `.gdsi-sdlc/issues/Ready/REQ-BE-00010-soporte-multi-vehiculo-flota-por-transportista.issue.md`  `[B]`

```diff
 ---
 tag: REQ-BE-00010
 ...
-status: backlog
+status: ready
 ...
+plan: docs/features/REQ/REQ-BE-00010/REQ-BE-00010-fleet-support.plan.md
 ---
```

### 4.15 New: `docs/features/REQ/REQ-BE-00010/REQ-BE-00010-fleet-support.plan.md`  `[B]`

Stub redirecting to the joint plan.

### 4.16 Modified: `docs/features/ISSUES-INDEX.md`  `[A+B]`

```diff
-| REQ-BE-00009 | Registro de vehículo — datos básicos + fotos (split US14) | NEW | BE | 2026-05-03 | - |
-| REQ-BE-00010 | Soporte multi-vehículo (flota) por transportista (split US14) | NEW | BE | 2026-05-03 | - |
+| REQ-BE-00009 | Registro de vehículo — datos básicos + fotos (split US14) | RDY | BE | 2026-05-03 | [plan](REQ/REQ-BE-00009/REQ-BE-00009-and-00010-vehicle-fleet.plan.md) |
+| REQ-BE-00010 | Soporte multi-vehículo (flota) por transportista (split US14) | RDY | BE | 2026-05-03 | [plan](REQ/REQ-BE-00010/REQ-BE-00010-fleet-support.plan.md) |
```

---

## 5. Testing

### 5.1 Backend

- `bin/rspec spec/models/vehicle_spec.rb spec/policies/vehicle_policy_spec.rb` — green.
- `bin/rspec spec/requests/api/carriers/...` — green.
- `bin/rake rswag:specs:swaggerize` — emits/updates `swagger.yaml`; commit the diff.
- `bin/brakeman` — no new warnings.
- `bin/rubocop` — green.

### 5.2 Frontend

- `deno task test` — Vitest suites green; coverage ≥ 80% for the new files.
- `deno task test:e2e` — Playwright happy path green (skipped if auth fixture not yet wired; un-skip once auth PR merges).
- Lighthouse spot-check on `/transportista/vehiculo` and `/transportista/vehiculos` — accessibility ≥ 95.

### 5.3 Manual

- Run `bin/dev` (backend) + `deno task dev` (frontend), browse to `/transportista/vehiculo`, create vehicle with 3 photos, refresh, edit, delete. Repeat with second vehicle to validate fleet flow.
- Verify pagination at 25 vehicles seeded.
- Verify Pundit denial: log in as a different carrier and try to mutate someone else's vehicle.

---

## 6. Acceptance Criteria

Combined from both issues. Re-grouping into a single checklist; `[A]`/`[B]` tag origin.

- [ ] `[A]` Modelo `Vehicle` con migración aplicada (columnas nuevas: `make, model, year, max_load_kg, length_cm, width_cm, height_cm, volume_cm3, description`).
- [ ] `[A]` Endpoints `POST/PATCH/GET` implementados con request specs (rswag).
- [ ] `[A]` ActiveStorage configurado, hasta 5 fotos por vehículo, validation enforced.
- [ ] `[A]` Pantalla `/transportista/vehiculo` con form + uploader drag-drop + previews.
- [ ] `[A]` Validaciones de datos (year > 1980 ≤ year+1, dimensions > 0, plate length 6-8, content_type whitelist).
- [ ] `[A→skipped, justified]` `unique index on carrier_id` — **NOT applied**, see Decisión A. Documentar en PR description.
- [ ] `[A+B]` Identifiers en inglés (es-AR sólo en copy de UI).
- [ ] `[A]` Test: feature spec del happy path (crear, ver, editar) — Vitest + Playwright.
- [ ] `[B]` Migración: `vehicle_id` ya presente en `transport_windows` (verificado, sin migration adicional). Drop de unique-index 1:1 — N/A (nunca se aplicó).
- [ ] `[B]` Endpoints CRUD funcionan con N > 1 (create second vehicle test green).
- [ ] `[B]` Pantalla `/transportista/vehiculos` listado + agregar + eliminar.
- [ ] `[B]` Componente `<VehicleSelect/>` reusable, autocompleta cuando N=1, exporta API para wizard de TransportWindow (futuro REQ-FE-00016).
- [ ] `[B]` Caso 1-vehículo sin regresión (single-vehicle E2E pasa).
- [ ] `[B]` Endpoint público `GET /api/carriers/:id/vehicles` retorna galería (consumido por US6/REQ-FE-00014 cuando llegue).
- [ ] `[B]` Tests cubren creación de un segundo vehículo y la asignación a una window via `<VehicleSelect/>`.
- [ ] `[A+B]` Pundit policies correctas (owner-only mutate; public read).
- [ ] `[A+B]` Alba+Oj serialization, slim list variant, full detail variant.
- [ ] `[A+B]` Pagy headers presentes en `index` (`X-Total`, `X-Page`, `X-Per-Page`, `Link`).
- [ ] `[A+B]` `swagger.yaml` regenerado y commiteado.
- [ ] `[A+B]` Impeccable skill invocada para las pantallas; resultado cumple WCAG 2.2 AA.
- [ ] `[A+B]` Conventional Commit titles, no `[TAG]` brackets en PR title.
- [ ] `[A+B]` PR rebased on top of REQ-BE-00023 (auth) before merge.

---

## 7. Files Summary

### New Files

| File | Description | Issue |
|------|-------------|-------|
| `docs/features/REQ/REQ-BE-00009/REQ-BE-00009-and-00010-vehicle-fleet.plan.md` | This joint plan. | A+B |
| `docs/features/REQ/REQ-BE-00010/REQ-BE-00010-fleet-support.plan.md` | Stub redirecting to joint plan. | B |
| `backend/db/migrate/<TS>_extend_vehicles_for_registration.rb` | Add 00009 columns; rename `capacity_kg` → `max_load_kg`. | A |
| `backend/app/policies/application_policy.rb` (if absent) | Pundit boilerplate. | A+B |
| `backend/app/policies/vehicle_policy.rb` | Owner-only mutate. | A+B |
| `backend/app/resources/vehicle_resource.rb` | Alba serializer with slim list variant. | A |
| `backend/app/controllers/api/base_controller.rb` (if absent) | API base with Pundit + Pagy + auth hook. | A+B |
| `backend/app/controllers/api/carriers/vehicles_controller.rb` | Public read endpoints. | A+B |
| `backend/app/controllers/api/carriers/me/vehicles_controller.rb` | Owner CRUD. | A+B |
| `backend/config/initializers/alba.rb` | Oj backend. | A+B |
| `backend/config/initializers/pagy.rb` | Headers extra, defaults. | A+B |
| `backend/spec/models/vehicle_spec.rb` | Model unit specs. | A |
| `backend/spec/policies/vehicle_policy_spec.rb` | Policy matrix. | A+B |
| `backend/spec/requests/api/carriers/vehicles_spec.rb` | rswag public specs. | A |
| `backend/spec/requests/api/carriers/me/vehicles_spec.rb` | rswag CRUD specs. | A+B |
| `frontend/src/router.tsx` | react-router setup. | A+B |
| `frontend/src/auth/RequireCarrier.tsx` | Auth guard wrapper. | A+B |
| `frontend/src/api/vehicles.ts` | Typed fetch client. | A+B |
| `frontend/src/pages/Landing.tsx` | Extracted from `App.tsx`. | A+B |
| `frontend/src/pages/transportista/VehicleForm.tsx` | Single-vehicle form (00009). | A |
| `frontend/src/pages/transportista/VehicleList.tsx` | Fleet list (00010). | B |
| `frontend/src/pages/transportista/PhotoUploader.tsx` | react-dropzone wrapper. | A |
| `frontend/src/components/VehicleSelect.tsx` | Reusable dropdown for window wizard. | B |
| `frontend/src/test/transportista/*.test.tsx` | Vitest suites. | A+B |
| `frontend/e2e/transportista-vehicle.spec.ts` | Playwright happy path. | A+B |

### Modified Files

| File | Change | Issue |
|------|--------|-------|
| `backend/app/models/vehicle.rb` | Add validations, `has_many_attached`, callbacks, variants helper. | A |
| `backend/Gemfile` | Add Pundit, Alba, Oj, Pagy, rswag (if absent). | A+B |
| `backend/config/routes.rb` | Add `/api/carriers/...` namespace + rswag mounts. | A+B |
| `backend/swagger.yaml` (generated) | Regenerate via `rake rswag:specs:swaggerize`. | A+B |
| `frontend/src/App.tsx` | Replace static landing with `<RouterProvider/>`. | A+B |
| `frontend/src/main.tsx` | Wrap App accordingly. | A+B |
| `frontend/deno.json` | Add `react-router-dom`, `react-dropzone`, `clsx`. | A+B |
| `.gdsi-sdlc/issues/Backlog/REQ-BE-00009-...issue.md` → `Ready/` | Frontmatter `status: ready` + `plan:`. | A |
| `.gdsi-sdlc/issues/Backlog/REQ-BE-00010-...issue.md` → `Ready/` | Frontmatter `status: ready` + `plan:`. | B |
| `docs/features/ISSUES-INDEX.md` | Update both rows: `NEW` → `RDY`, plan column. | A+B |

### Out of Scope (deliberate)

| File / topic | Reason |
|--------------|--------|
| `unique index on carrier_id` migration | Decisión A — never lands. |
| `transport_windows.vehicle_id` migration | Already present in initial migration. |
| S3 / minio storage | Separate INF issue. |
| Wiring `<VehicleSelect/>` into a TransportWindow form | REQ-FE-00016. |
| Public carrier profile page consuming `/api/carriers/:id/vehicles` | REQ-FE-00014. |
| AdminUser ↔ Vehicle ActiveAdmin resource | INF-BE-00003. |
| Real auth flow | REQ-BE-00023 (this PR rebases on top). |

---

## 8. Notes for Implementer

1. **Rebase discipline**: this PR depends on REQ-BE-00023 (auth) for `Api::BaseController` + `current_user`/`current_carrier`. Merge sequence: auth first, then rebase this branch onto auth's merged state, resolve any conflicts on `Gemfile`, `routes.rb`, initializers (likely no-ops since both PRs add the same gems).
2. **If auth merges late**: temporarily stub `current_user` via a `before_action :stub_current_user` that reads a header (`X-Stub-User-Id`) in development/test only; mark with `// TODO(REQ-BE-00023)`.
3. **Migration ordering**: place the new migration AFTER `20260509120005_create_transport_windows.rb` timestamp so the rename of `capacity_kg` doesn't trip a fresh `bin/rails db:setup`.
4. **`change_column` on SQLite**: Rails 8.1 handles via copy-table-and-rebuild; no manual `up`/`down` needed unless we cross-target Postgres in CI (currently SQLite only).
5. **Pundit `policy_scope` invocation**: in `Me::VehiclesController#index`, prefer `policy_scope(Vehicle)` over `current_carrier.vehicles` for consistency with the policy contract (the Scope returns the same set; explicit invocation makes the dependency on Pundit visible to readers and to specs).
6. **Photo variants**: avoid `.processed` in serializer hot path if unprocessed; consider `image_processing`'s `:track_variants` and a job-based pre-warm in a follow-up. For MVP synchronous is fine (small dev volume).
7. **Impeccable skill**: invoke once per page with a one-liner intent ("vehicle registration form" / "fleet list with delete"). Let it iterate; don't hand-roll the visuals.
8. **Branch & commits**: branch already `feat/vehicle-fleet-crud`. Commits follow Conventional Commits (`feat(vehicle): ...`, `feat(api): ...`, `chore(plan): ...`). PR title: `feat(vehicle): vehicle registration and fleet support` (no brackets, no tags). PR body: `Closes #85`, `Closes #89`. Assign to `@me` (`gh pr create --assignee @me ...`).
9. **No Spanish in identifiers** — `Vehicle` not `Camion`, `make/model/year` not `marca/modelo/anio`. UI copy is es-AR.
10. **CI**: this PR likely needs `INF-INFRA-00002` (frontend CI workflow) to mature. If E2E flakes in CI, mark `@flaky` and follow up.
