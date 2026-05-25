# REQ-FE-00027: Definir Radio de Recogida — input numérico + círculo arrastrable (US50)

| Field | Value |
|-------|-------|
| **Tag** | REQ-FE-00027 |
| **Title** | Definir Radio de Recogida — input numérico + círculo arrastrable (US50) |
| **Priority** | P1 |
| **Status** | READY |
| **Created** | 2026-05-24 |
| **Sprint** | 4 |
| **Author** | Claude Code |
| **Depends On** | **Hard:** [[REQ-FE-00025]] (pin de origen desde `<AddressPicker />`). [[REQ-BE-00037]] (columna `pickup_radius_km` + validación + serializer). |
| **Decision Doc** | N/A — decisiones cerradas inline en el issue body. |
| **Selected Approach** | Single PR — nuevo `<PickupRadiusControl />` (input numérico 1–200 + `<GoogleMap />` con `<Circle editable draggable={false}>` centrado en el pin). Two-way binding con flag anti-loop. Integración en el form de US9 (publicar) y US33 (editar). Sin advertencia FE al achicar el radio (decisión cerrada — no es retroactivo). |

---

## 1. Problem Statement

El issue body (Backlog) tiene el spec completo. Issue es no-trivial sólo por la sincronización bidireccional input ↔ círculo.

Estado al arrancar:
- [[REQ-FE-00025]] entrega `<AddressPicker />` con el pin de origen ya capturado en el state del form.
- [[REQ-BE-00037]] entrega `pickup_radius_km` (INTEGER, 1–200, default 10) en `TransportWindow` y lo expone vía serializer.
- `@react-google-maps/api` instalado por [[REQ-FE-00025]] — provee `<GoogleMap />` + `<Circle />`.

## 2. Solution Design

### 2.1 Estrategia — un componente compuesto, two-way binding sin loops

`<PickupRadiusControl />` agrupa input + mapa minimal + círculo. Recibe la posición del pin de origen como prop (controlled — el form padre tiene el state). Tres principios:

1. **Centro locked al pin** — `<Circle draggable={false}>` + ignorar cualquier `center_changed`.
2. **Flag anti-loop** — al setear desde el input, marcar `isApplyingInput=true` y re-bajarlo en el próximo tick; el handler de `radius_changed` chequea el flag antes de emitir `onChange`.
3. **Si no hay pin → placeholder** — el input se deshabilita; el mapa muestra un mensaje con copy del `*Content.ts`.

Orden mecánico:

1. Crear `frontend/src/components/PickupRadiusControl/` con `index.tsx`, `PickupRadiusControl.test.tsx`, `pickupRadiusContent.ts`.
2. Implementar el control (input + GoogleMap + Circle + binding bidireccional).
3. Integrar en el form de US9/US33 — debajo del `<AddressPicker />` de origen.
4. Estado del form: agregar `pickupRadiusKm: number` (default 10, prepoblado del backend en edit).
5. Submit: incluir `pickup_radius_km` en el payload POST/PATCH.
6. Vitest + Playwright.
7. `/critique` → `/polish` → `/audit` + lint + coverage + e2e.

### 2.2 API del componente

```ts
export interface PickupRadiusControlProps {
  origin: { lat: number; lng: number } | null;
  value: number;                              // 1–200, integer
  onChange: (value: number) => void;
  label: string;
  placeholderWhenNoOrigin: string;            // copy from form's *Content.ts
  error?: string;
  disabled?: boolean;
}
```

### 2.3 Sincronización bidireccional sin loops

```tsx
const isApplyingInputRef = useRef(false);
const circleRef = useRef<google.maps.Circle | null>(null);

// input → circle
function handleInputChange(e) {
  const km = clampInteger(Number(e.target.value), 1, 200);
  isApplyingInputRef.current = true;
  circleRef.current?.setRadius(km * 1000);
  // reset flag in next tick so circle's radius_changed listener sees it cleanly
  queueMicrotask(() => { isApplyingInputRef.current = false; });
  onChange(km);
}

// circle → input
function handleRadiusChanged() {
  if (isApplyingInputRef.current) return;       // ignore — we caused this
  const meters = circleRef.current?.getRadius() ?? value * 1000;
  const km = Math.round(meters / 1000);
  if (km !== value) onChange(clampInteger(km, 1, 200));
}
```

Variantes: usar `useEffect` para reactivar `circleRef.current?.setRadius(value * 1000)` cuando `value` cambia por causas externas (prepoblación en edit). Mismo flag.

### 2.4 Lock del centro

```tsx
<Circle
  center={origin}
  radius={value * 1000}
  editable
  draggable={false}                              // ← locked
  onLoad={c => { circleRef.current = c; }}
  onRadiusChanged={handleRadiusChanged}
  options={{ fillOpacity: 0.15, strokeWeight: 2 }}
/>
```

`useEffect` adicional para resetear `circle.setCenter(origin)` si por algún motivo (drag accidental) el centro se mueve.

### 2.5 Mapa minimal

`<GoogleMap />` zoom inicial razonable (`zoom: 11` para CABA-scale; `fitBounds` con el círculo si querés ser fancy). `mapContainerStyle={{ height: 240 }}` o equivalente del DS. Sin marcador adicional — el círculo ya muestra el centro.

Cuando `origin === null`: render condicional del placeholder, NO renderizar el mapa (evita un load innecesario de la JS API).

### 2.6 Copy

`frontend/src/components/PickupRadiusControl/pickupRadiusContent.ts`:

```ts
export const pickupRadiusContent = {
  label: 'Radio de recogida (km)',
  placeholder: 'Ej. 10',
  placeholderWhenNoOrigin: 'Seleccioná el origen para definir el radio',
  error: {
    out_of_range: 'El radio debe estar entre 1 y 200 km.',
  },
} as const;
```

El consumidor (form de US9) puede sobreescribir vía props si necesita; default razonable.

### 2.7 Integración en el form

- Añadir `pickup_radius_km: number` al estado (default `10`).
- Renderizar `<PickupRadiusControl origin={form.origin && { lat: form.origin.lat, lng: form.origin.lng }} value={form.pickup_radius_km} onChange={v => setForm({...form, pickup_radius_km: v})} ... />`.
- Submit: incluir `pickup_radius_km` en el payload (alineado con el contrato BE en [[REQ-BE-00037]]).
- Edit (US33): prepoblar `pickup_radius_km` desde el detalle de la ventana. **Sin advertencia** al achicar — decisión cerrada.

### 2.8 Validación client-side

`<input type="number" min={1} max={200} step={1}>` ya frena lo más grueso. Adicionalmente, en el submit del form, verificar `Number.isInteger(value) && value >= 1 && value <= 200`; si no, error inline con `pickupRadiusContent.error.out_of_range`.

## 3. Implementation Tasks

| # | Task | Layer | Files |
|---|------|-------|-------|
| 1 | Componente `<PickupRadiusControl />` | Component | `frontend/src/components/PickupRadiusControl/index.tsx` |
| 2 | Copy del componente | Content | `frontend/src/components/PickupRadiusControl/pickupRadiusContent.ts` |
| 3 | Vitest specs (sync bidir, placeholder, edge cases) | Spec | `frontend/src/components/PickupRadiusControl/PickupRadiusControl.test.tsx` |
| 4 | Integración en el form de US9/US33 | Page/Form | `frontend/src/pages/carrier/TransportWindowForm.tsx` (TBD) |
| 5 | Payload submit incluye `pickup_radius_km` | Page/Form | idem |
| 6 | Playwright spec (publicar custom radius + edit) | Spec | `frontend/tests/e2e/transport-window-radius.spec.ts` |
| 7 | `/critique` → `/polish` → `/audit` (especialmente importante por sync) | UI gate | findings inline o en PR body |
| 8 | `just lint` + `just frontend-test-coverage` + `just frontend-test-e2e` | Pre-PR | — |

## 4. Test Strategy

Listado en el issue body. Notas implementación:

- **Mock de `google.maps.Circle`** — stub el módulo `@react-google-maps/api`:
  ```ts
  const mockCircle = { setRadius: vi.fn(), getRadius: vi.fn().mockReturnValue(10000), setCenter: vi.fn() };
  ```
- **Sync test** — disparar `change` del input → `mockCircle.setRadius` recibe `value * 1000`. Disparar `onRadiusChanged` (handler) con `mockCircle.getRadius` devolviendo `25000` → `onChange` recibe `25`.
- **Anti-loop** — disparar input change, luego `onRadiusChanged` en el mismo tick → `onChange` se llama una sola vez (la del input).
- **Placeholder** — render con `origin={null}` → mapa no renderiza, input disabled, mensaje visible.
- **Edge cases input** — `0` no acepta (clamp a 1), `201` clamp a 200, `12.5` redondea o rechaza (decidir en implementación; recomendación: clamp via `Math.round`).
- **E2E** — publicar ventana con radio 25, verificar POST con `pickup_radius_km: 25`. Editar via US33, cambiar a 50, verificar PATCH.

`just frontend-test-coverage` mantiene 80%.

## 5. Risks & Decision Points

- **Orden con [[REQ-FE-00025]] + [[REQ-BE-00037]]** — este PR no aporta valor end-to-end hasta que ambos estén mergeados. Hasta entonces, el componente existe pero el form no lo monta o el submit no persiste. Recomendación: mergear en el orden BE-00036 → (FE-00025, BE-00037) → este. Si se invierte, branchear y rebasear.
- **`google.maps.Circle` editable UX** — los handles default de Google son chicos en mobile. **Decision needed from user**: ¿aceptable o querés un wrapper custom (e.g. handle más grande, color de marca)? Recomendación: aceptable para MVP; revisar en `/polish` post-implementation. Si rechaza, abrir issue cosmético separado.
- **Sin advertencia al achicar el radio** — decisión cerrada. Si el reviewer pide friction («mostrá cuántas offers pending van a quedar fuera de alcance»), bouncearlo al issue body que tiene esta decisión documentada.
- **Comportamiento en mobile** — el círculo arrastrable en touch puede ser hostil. Verificar en `/audit` (a11y + responsive). Si el touch no funciona bien, fallback al input numérico es suficiente (el círculo es visual feedback, no único control).
- **Costo de cargar la JS API en el form** — el `<AddressPicker />` ya cargó la API (singleton). El `<GoogleMap />` reusa el mismo loader. Verificar en un test que no se trigger un segundo load.

## 6. Out of Scope

- Geolocalización en vivo del Carrier.
- Cualquier callback retroactivo sobre offers existentes (decisión cerrada — vive en BE side).
- Modificar el `<AddressPicker />`.

## 7. Acceptance Criteria

Re-lectura del issue body Backlog AC1–AC10. Verificación local antes del PR:

- [ ] AC1 — `<input type="number" min={1} max={200} step={1} defaultValue={10}>` ✓.
- [ ] AC2 — Vitest sync bidir + Playwright drag → input update.
- [ ] AC3 — Playwright: payload 422 si fuera de rango.
- [ ] AC4 — E2E cubre US33 prepoblation.
- [ ] AC5 — Garantía BE (no spec FE).
- [ ] AC6 — `grep` no devuelve literales en español dentro de JSX (sólo `*Content.ts`).
- [ ] AC7 — Spec del placeholder cuando no hay pin.
- [ ] AC8 — Sync sin loops verificado en spec.
- [ ] AC9 — `just frontend-test-coverage` ≥ 80%.
- [ ] AC10 — `just frontend-test-e2e` golden path verde.

## 8. Related

- Issue body: `.gdsi-sdlc/issues/Backlog/REQ-FE-00027-us50-definir-radio-de-recogida.issue.md`.
- US50: `docs/artifacts/backlog-us.typ:729-747`.
- Glossary: «Radio de recogida».
- FE dep: [[REQ-FE-00025]].
- BE companion: [[REQ-BE-00037]].
- US33: `docs/artifacts/backlog-us.typ` — buscar US33.
