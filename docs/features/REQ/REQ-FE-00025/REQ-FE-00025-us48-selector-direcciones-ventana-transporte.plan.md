# REQ-FE-00025: Selector de Direcciones — Ventana de Transporte (US48 — `<AddressPicker />`)

| Field | Value |
|-------|-------|
| **Tag** | REQ-FE-00025 |
| **Title** | Selector de Direcciones — Ventana de Transporte (US48 — picker FE compartido) |
| **Priority** | P1 |
| **Status** | READY |
| **Created** | 2026-05-24 |
| **Sprint** | 4 |
| **Author** | Claude Code |
| **Depends On** | **Hard:** [[REQ-BE-00036]] (columnas + permits + serializer). **Coordinación:** Fernando — Google Places API key en `frontend/.env`. |
| **Decision Doc** | N/A — decisiones cerradas inline en `.gdsi-sdlc/issues/Backlog/REQ-FE-00025-...issue.md`. |
| **Selected Approach** | Single PR — nuevo `<AddressPicker />` reusable bajo `frontend/src/components/`, integración en los forms de US9 (publicar) y US33 (editar), copy via objeto `*Content.ts` (no hay i18n library todavía — convención prototype-stage), validación cliente (yup/zod si ya hay form lib, o sino guard manual), trunca lat/lng a 6 decimales en cliente, fallback a estado `service_unavailable` si la JS API no carga. Dep nueva: `@react-google-maps/api`. Vitest + Playwright cubren los estados. |

---

## 1. Problem Statement

El issue body (Backlog) contiene el spec completo, AC, y decisiones cerradas — leerlo primero. Este plan es el "cómo".

Estado al arrancar:
- Frontend stack: React 19 + Deno + Vite + TypeScript, dev en `:5173` via `deno task dev`.
- **No hay librería i18n instalada** — el repo usa archivos `*Content.ts` (e.g. `landingContent.ts`, `carrierContent.ts`, `authContent.ts`) como bundle de copy prototype-stage. CLAUDE.md y la memoria persistente confirman esto. ➜ Las "claves i18n" mencionadas en el issue body se materializan como entradas en el `*Content.ts` correspondiente (e.g. `carrierContent.ts` ya cubre el flow Carrier; agregar entradas o un módulo nuevo `addressPickerContent.ts` si crece).
- **No hay packages de Google Maps instalados** en `frontend/package.json` — ni `@react-google-maps/api`, ni `@googlemaps/js-api-loader`. Hay que añadir uno.
- **No hay `VITE_GOOGLE_MAPS_API_KEY`** en `frontend/.env*` — se añade `frontend/.env.example` con la variable (sin valor) y se coordina con Fernando.
- Form de US9 (publicar ventana) — existe en el Carrier flow (confirmar path exacto: probablemente `frontend/src/pages/carrier/TransportWindowForm.tsx` o equivalente). US33 (editar ventana) usa el mismo form en modo edit.
- Design system: hay `frontend/src/components/ui/` (primitives). El `<AddressPicker />` debe componer esos primitives (Input, Label, ErrorMessage) — no estilizar from scratch.
- Vitest + Playwright configurados — `frontend/vitest.config.ts`, `frontend/playwright.config.ts`. Cobertura ≥80%.

## 2. Solution Design

### 2.1 Estrategia — componente compartido, API estable, fallback robusto

El `<AddressPicker />` es el load-bearing FE del bloque GMaps. Diseñarlo con la API que [[REQ-FE-00026]] / [[REQ-FE-00027]] van a montar sin tocar. Tres principios de diseño:

1. **API mínima y estable** — props chicos (`name`, `label`, `value`, `onChange`, `error?`, `disabled?`). El estado interno (suggesting/confirmed/error/unconfirmed) es opaco; el padre sólo ve `value` y `onChange`.
2. **Fallback a `service_unavailable`** — si la JS API no carga (sin key, network, quota), el componente entra en un estado degradado donde el input está disabled y muestra el mensaje neutral. **El resto del form sigue funcional.**
3. **Trunca lat/lng a 6 decimales en cliente** — `Number(value.toFixed(6))`. Defensa en profundidad: el backend valida igual.

Orden mecánico:

1. Agregar `@react-google-maps/api` a `frontend/deno.json` (o `package.json` según convención del repo — confirmar al inspeccionar).
2. Agregar `VITE_GOOGLE_MAPS_API_KEY` a `frontend/.env.example` + entry en el README de frontend o en `frontend/.env.local` (gitignored).
3. Crear `frontend/src/components/AddressPicker/` con `index.tsx`, `AddressPicker.test.tsx`, `addressPickerContent.ts` (copy).
4. Wirear el `LoadScript` / `useJsApiLoader` (singleton — un solo loader por app; si no hay un provider de Google Maps ya, crearlo en un wrapper de la app o usar `useJsApiLoader` que es idempotente).
5. Implementar el state machine interno (`idle | suggesting | confirmed | unconfirmed | service_unavailable`).
6. Integrar en el form de US9 (publicar ventana de transporte) — reemplazar los inputs de texto libre de origen y destino por dos `<AddressPicker />`.
7. Probar la prepoblación en US33 (mismo form, modo edit).
8. Vitest specs (mock de la JS API via `msw` o stub directo del módulo).
9. Playwright spec del golden path (route stub para la JS API en CI).
10. `/critique` → `/polish` → `/audit` (impeccable) sobre los archivos nuevos.
11. `just lint` + `just frontend-test-coverage` (≥80%) + `just frontend-test-e2e`.

### 2.2 API del componente

```ts
// frontend/src/components/AddressPicker/AddressPicker.tsx

export interface AddressPickerValue {
  text: string;
  lat: number;  // 6-decimal precision
  lng: number;
}

export interface AddressPickerProps {
  name: string;                              // form field name (origin / destination / pickup / delivery)
  label: string;                             // resolved copy from *Content.ts (NOT a t() key)
  value: AddressPickerValue | null;
  onChange: (value: AddressPickerValue | null) => void;
  error?: string;                            // resolved copy; component shows it inline if set
  disabled?: boolean;
  placeholder?: string;                      // optional override
}

export function AddressPicker(props: AddressPickerProps): JSX.Element;
```

- **`value: null`** = no hay sugerencia confirmada todavía (idle o suggesting).
- **`value: { text, lat, lng }`** = confirmed.
- **`error`** = el padre puede inyectar errores propios (e.g. desde el form library). El componente añade su propio error de `unconfirmed` cuando aplique (combina ambos: el del padre y el suyo, separados por newline o `;`).

### 2.3 State machine interno

```
       ┌─────────┐  user types        ┌────────────┐
       │  idle   │ ─────────────────▶ │ suggesting │
       └─────────┘                    └─────┬──────┘
            ▲                               │ user selects + confirms
            │                               ▼
            │                          ┌────────────┐
            │ clears input             │ confirmed  │
            └──────────────────────────┴────────────┘
                                          │ submit while typing (no select)
                                          ▼
                                     ┌──────────────┐
                                     │ unconfirmed  │  → emite error in component
                                     └──────────────┘

  ┌────────────────────────┐
  │  service_unavailable   │  ← cuando useJsApiLoader.loadError o key missing
  └────────────────────────┘
```

### 2.4 Manejo de la JS API

`@react-google-maps/api` provee `useJsApiLoader` (singleton-safe). Usar:

```tsx
const { isLoaded, loadError } = useJsApiLoader({
  googleMapsApiKey: import.meta.env.VITE_GOOGLE_MAPS_API_KEY ?? '',
  libraries: ['places'],
});

if (loadError || !import.meta.env.VITE_GOOGLE_MAPS_API_KEY) {
  return <ServiceUnavailableFallback message={content.error.service_unavailable} />;
}
if (!isLoaded) return <Skeleton ... />;

return (
  <Autocomplete
    onLoad={ac => setAutocomplete(ac)}
    onPlaceChanged={handlePlaceChanged}
    options={{ componentRestrictions: { country: 'ar' }, fields: ['formatted_address', 'geometry'] }}
  >
    <input ... />
  </Autocomplete>
);
```

`handlePlaceChanged` captura `place.formatted_address` + `place.geometry.location.lat()` + `.lng()`, trunca a 6 decimales, emite `onChange({ text, lat, lng })`.

### 2.5 Copy (sin librería i18n)

Crear `frontend/src/components/AddressPicker/addressPickerContent.ts`:

```ts
export const addressPickerContent = {
  error: {
    unconfirmed: 'Confirmá una sugerencia del listado.',
    service_unavailable: 'Servicio de direcciones no disponible. Reintentá en un rato.',
  },
  defaultPlaceholder: 'Ingresá una dirección argentina',
} as const;
```

El consumidor del componente (form de US9 / US33) provee `label` y opcionalmente `placeholder` desde su propio `*Content.ts` (e.g. `carrierContent.ts` ya existente). El picker no inventa labels — los recibe.

### 2.6 Integración en el form de US9 / US33

Confirmar el archivo exacto en implementación (probablemente `frontend/src/pages/carrier/TransportWindowForm.tsx` o componente análogo). Cambios:

- Reemplazar inputs de texto libre de origen y destino por dos `<AddressPicker />`.
- Estado del form: agregar `origin: AddressPickerValue | null` y `destination: AddressPickerValue | null` (en vez de `originZone: string`).
- Submit:
  - `origin === null` → bloquea con copy del form (no del picker), inyectada via `error` prop.
  - `destination !== null && (destination.lat == null || destination.lng == null)` → bloquea (caso unconfirmed).
  - `destination === null` → válido (destino opcional en US9 + FIX-BE-00001).
- Payload POST: aplanar a `{ origin_zone: text, origin_lat, origin_lng, destination_zone, destination_lat, destination_lng }`. Contrato confirmado con [[REQ-BE-00036]] — columnas planas snake_case.
- En modo edit (US33), prepoblar los pickers desde el detalle de la ventana (`{ text: window.origin_zone, lat: window.origin_lat, lng: window.origin_lng }`).

Nota sobre `origin_zone`: con US48, `origin_zone` ya no es un input libre del Carrier; es el `formatted_address` de Google Places. Conservar la columna como string-de-display; el filtro de US5 ya no la usa para matching (usa lat/lng).

### 2.7 Form library

Verificar en implementación qué form library usa el form actual (react-hook-form, formik, manual). Si manual, mantener manual; si react-hook-form, registrar los pickers con `Controller`. **No introducir una nueva form lib en este PR** — out of scope.

## 3. Implementation Tasks

| # | Task | Layer | Files |
|---|------|-------|-------|
| 1 | Agregar dep `@react-google-maps/api` | Deps | `frontend/deno.json` (o `package.json`) |
| 2 | `VITE_GOOGLE_MAPS_API_KEY` en `.env.example` | Config | `frontend/.env.example` |
| 3 | Componente `<AddressPicker />` | Component | `frontend/src/components/AddressPicker/index.tsx` |
| 4 | Copy del componente | Content | `frontend/src/components/AddressPicker/addressPickerContent.ts` |
| 5 | Vitest specs del componente | Spec | `frontend/src/components/AddressPicker/AddressPicker.test.tsx` |
| 6 | Integrar en form de US9 (publicar) y US33 (editar) | Page/Form | `frontend/src/pages/carrier/TransportWindowForm.tsx` (path TBD) |
| 7 | Copy del form (labels específicos) en el `*Content.ts` correspondiente | Content | `frontend/src/carrierContent.ts` o equivalente |
| 8 | Playwright spec golden path (publicar) | Spec | `frontend/tests/e2e/transport-window-publish.spec.ts` |
| 9 | Playwright spec edit | Spec | `frontend/tests/e2e/transport-window-edit.spec.ts` |
| 10 | `/critique` → `/polish` → `/audit` | UI gate | findings inline o en PR body |
| 11 | `just lint` + `just frontend-test-coverage` + `just frontend-test-e2e` | Pre-PR | — |

## 4. Test Strategy

Lista detallada en el issue body (`### Tests requeridos`). Notas de implementación:

- **Mock de Google Places JS API en Vitest** — stub el módulo `@react-google-maps/api`:
  ```ts
  vi.mock('@react-google-maps/api', () => ({
    useJsApiLoader: () => ({ isLoaded: true, loadError: null }),
    Autocomplete: ({ children, onPlaceChanged, onLoad }) => { /* expose helper to trigger */ },
  }));
  ```
- **Mock en Playwright** — `page.route('**/maps.googleapis.com/**', route => route.fulfill({ body: ... }))` para evitar llamadas reales en CI; verificar que en local con la key real funciona también (sanity-check manual antes del PR).
- **Tests por estado** — render condicional por flag de `useJsApiLoader` (mock cambia entre tests).
- **Test de truncado a 6 decimales** — emit con `-34.6037229876` → `onChange` recibe `-34.603723`.
- **Test de unconfirmed** — usuario tipea pero no selecciona; submit del form → guard del padre bloquea.

Cobertura mínima: 80% en lines/functions/branches/statements (vitest config). Hard threshold del repo.

## 5. Risks & Decision Points

- **API key disponible** — Fernando (per memoria `project_team_github_logins`) maneja infra. Sin la key, el componente degrada a `service_unavailable` pero el e2e no puede pasar el golden path en CI. **Decision needed from user**: ¿bloqueamos el PR hasta que Fernando configure la key (e incluya el secret en GitHub Actions), o avanzamos con la key y un secret-stub-CI mientras se coordina? Recomendación: avanzar con el componente y el secret-stub en CI; pasar el e2e al backlog corto de Fernando cuando la key esté.
- **Path real del form de US9 / US33** — el recon no confirmó archivo. Inspeccionar en implementación (`grep -r "TransportWindow" frontend/src/pages/`). Si el form no existe todavía (greenfield), el PR es más grande que esperado — flag al usuario antes de arrancar.
- **Form library** — si no hay form lib y la complejidad sube, considerar `react-hook-form`. **Decision out of scope acá** — si emerge la necesidad, flag al usuario y abrir issue separado.
- **`@react-google-maps/api` vs `@googlemaps/js-api-loader`** — el primero da React components (Autocomplete, Map, Marker, Circle) wrappers; lo segundo es el loader pelado. El stack del repo no tiene ninguno; sugerir `@react-google-maps/api` porque cubre US48 + US50 + US51 con un solo paquete (Circle, Map, Marker incluidos). Confirm en implementación que la versión es compatible con React 19.
- **Singleton del loader** — múltiples `<AddressPicker />` montados a la vez (origen+destino en US9, pickup+delivery en US27) NO deben triggear múltiples loads. `useJsApiLoader` lo maneja, pero verificar en un test.
- **Sin i18n library** — la copy va en `*Content.ts`. Cuando aterrice la lib real (issue futuro, no MVP), migrar las claves. Documentar el TODO en el contenido nuevo.

## 6. Out of Scope

- Reverse geocoding server-side.
- Validación AR bounding-box server-side.
- Mapa preview con pin (lo aporta [[REQ-FE-00027]] / [[REQ-FE-00028]]).
- Migrar la base FE a una librería de i18n.

## 7. Acceptance Criteria

Re-lectura del issue body Backlog AC1–AC11. Verificación local antes del PR:

- [ ] AC1–AC3 — Vitest specs cubren los estados; e2e demuestra el form de US9 capturando lat/lng.
- [ ] AC4 — `[[REQ-BE-00036]]` mergeado (o coordinado el PR pair) — payload 422 verificado en e2e.
- [ ] AC5 — Vitest spec de `service_unavailable` — el resto del form sigue navegable.
- [ ] AC6 — `grep -r "[a-záéíóúñ]" frontend/src/components/AddressPicker/*.tsx` no devuelve literales en español dentro de JSX (sólo en `*Content.ts`).
- [ ] AC7 — API del componente documentada (TypeScript types exportados); listo para [[REQ-FE-00026]] / [[REQ-FE-00027]].
- [ ] AC8 — Edit de US33 prepoblar el picker — e2e cubre.
- [ ] AC9 — Spec de unconfirmed pasa.
- [ ] AC10 — `just frontend-test-coverage` no rompe el 80%.
- [ ] AC11 — `just frontend-test-e2e` golden path verde.

## 8. Related

- Issue body: `.gdsi-sdlc/issues/Backlog/REQ-FE-00025-us48-selector-direcciones-ventana-transporte.issue.md`.
- US48: `docs/artifacts/backlog-us.typ:688-707`.
- Glossary: `docs/05-appendices/glossary.md` — «Ventana de transporte», «Radio de recogida».
- CLAUDE.md «Language policy» (UI via `*Content.ts`, no hardcoded literals) + «Pre-PR UI quality gate».
- BE companion: [[REQ-BE-00036]].
- Consumidor del componente: [[REQ-FE-00026]] (US49), [[REQ-FE-00027]] (US50).
- Coordinación infra: Fernando (`project_team_github_logins`).
