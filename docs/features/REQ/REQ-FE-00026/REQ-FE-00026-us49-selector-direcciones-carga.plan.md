# REQ-FE-00026: Selector de Direcciones — Carga (US49 — reuso del `<AddressPicker />`)

| Field | Value |
|-------|-------|
| **Tag** | REQ-FE-00026 |
| **Title** | Selector de Direcciones — Carga (US49 — reuso del picker compartido) |
| **Priority** | P1 |
| **Status** | READY |
| **Created** | 2026-05-24 |
| **Sprint** | 4 |
| **Author** | Claude Code |
| **Depends On** | **Hard:** [[REQ-FE-00025]] (entrega el `<AddressPicker />`). [[REQ-BE-00036]] (columnas `pickup_*`/`delivery_*` + permits + serializer). **Coordinación blanda:** [[REQ-FE-00028]] (US51 `<ShipmentMap />` reusado opcionalmente como preview). |
| **Decision Doc** | N/A — decisiones cerradas inline en el issue body. |
| **Selected Approach** | Single PR — montar dos `<AddressPicker />` en el form de US27 (publicar carga) y US47 (editar), persistir las cuatro coords, agregar un mini-preview con dos pines. **Para el preview, ship-the-minimal-thing**: si [[REQ-FE-00028]] todavía no aterrizó, preview estático inline (dos `<Marker />` sobre un `<GoogleMap />` minimal con `fitBounds`); si ya está, importar `<ShipmentMap />`. TODO inline para unificar si el orden se invierte. |

---

## 1. Problem Statement

El issue body (Backlog) tiene el spec completo. Issue por construcción trivial: montaje del componente compartido.

Estado al arrancar:
- [[REQ-FE-00025]] entrega `<AddressPicker />` con API estable.
- [[REQ-BE-00036]] entrega columnas `pickup_lat`/`pickup_lng`/`delivery_lat`/`delivery_lng` NOT NULL en `cargos`, permits en `CargosController`, atributos en `CargoResource`.
- Form de US27 (publicar carga) existe en el Shipper flow (confirmar path en implementación). Form de US47 (editar) usa el mismo en modo edit.
- Mapa preview de AC5 — si [[REQ-FE-00028]] no aterrizó, se construye uno minimal local; sino, se importa el `<ShipmentMap />`.

## 2. Solution Design

### 2.1 Estrategia — copy/paste guiado, sin duplicar el picker

Patrón paralelo al PR de [[REQ-FE-00025]] sobre el form de US27/US47:

1. Importar `<AddressPicker />` desde `frontend/src/components/AddressPicker/`.
2. Reemplazar inputs de texto libre de `pickup_address` / `delivery_address` por dos `<AddressPicker />`.
3. Estado del form: `pickup: AddressPickerValue | null`, `delivery: AddressPickerValue | null` (en vez de strings sueltos).
4. Submit:
   - `pickup === null` o `delivery === null` → bloquea (las cuatro coords son obligatorias, decisión cerrada).
   - Payload POST: `{ pickup_address: pickup.text, pickup_lat, pickup_lng, delivery_address: delivery.text, delivery_lat, delivery_lng, ...resto }`.
5. Modo edit (US47): prepoblar los pickers con el detalle del cargo.
6. Preview del mapa (AC5):
   - **Si [[REQ-FE-00028]] mergeó antes**: `import { ShipmentMap } from '@/components/ShipmentMap'; <ShipmentMap origin={pickup} destination={delivery} />` debajo de los pickers.
   - **Si [[REQ-FE-00028]] todavía no**: inline minimal:
     ```tsx
     <GoogleMap mapContainerStyle={{ height: 240 }} onLoad={fitBoundsTo([pickup, delivery])}>
       {pickup && <Marker position={pickup} label="P" />}
       {delivery && <Marker position={delivery} label="D" />}
     </GoogleMap>
     ```
     Con un `TODO(REQ-FE-00028): reemplazar por <ShipmentMap />` inline. **Decisión en implementación** según el state of the world ese día.
7. Vitest del form (mock del picker como en su PR base) + Playwright del golden path.
8. `/critique` → `/polish` → `/audit` + `just lint` + `just frontend-test-coverage` (≥80%) + `just frontend-test-e2e`.

### 2.2 Diferencias vs. US48

- Persiste 4 coords (no 3) — todas obligatorias (sin XOR, sin "destino opcional").
- Agrega el mini-preview (AC5) — US48 no tenía ese requerimiento explícito.
- Targets diferentes: forms del Shipper, no del Carrier.

### 2.3 Copy

Reutilizar `shipperContent.ts` (o el `*Content.ts` análogo del Shipper flow). Labels de los pickers: «Dirección de retiro» y «Dirección de entrega» (es-AR).

Si la preview requiere mensaje fallback (`service_unavailable` del mapa), reutilizar la copy que el `<ShipmentMap />` ya tiene (cuando esté) o agregar entradas locales al `shipperContent.ts`.

### 2.4 Contrato API (con BE)

POST `/api/cargos` payload incluye las cuatro coords planas:

```json
{
  "cargo": {
    "pickup_address": "Av. Corrientes 1234, CABA",
    "pickup_lat": -34.603722,
    "pickup_lng": -58.381592,
    "delivery_address": "Bv. Oroño 500, Rosario",
    "delivery_lat": -32.946820,
    "delivery_lng": -60.639317,
    "weight_kg": 1200,
    ...
  }
}
```

Verificar en implementación que `pickup_address` / `delivery_address` siguen como strings (no se renombran a `pickup_zone`); la columna existente queda como texto de display. Si se renombra, ese cambio vive en [[REQ-BE-00036]] o en un fix BE separado — NO acá.

## 3. Implementation Tasks

| # | Task | Layer | Files |
|---|------|-------|-------|
| 1 | Importar `<AddressPicker />` en el form de Cargo | Page/Form | `frontend/src/pages/shipper/CargoForm.tsx` (path TBD) |
| 2 | Estado del form: dos `AddressPickerValue \| null` | Page/Form | idem |
| 3 | Submit con las 4 coords planas | Page/Form | idem |
| 4 | Preview del mapa (import `<ShipmentMap />` o inline minimal) | Page/Form | idem + posible nuevo helper |
| 5 | Copy en `shipperContent.ts` | Content | `frontend/src/shipperContent.ts` |
| 6 | Vitest del form (mock del picker; cubre submit con 4 coords; bloqueo si falta alguna) | Spec | `frontend/src/pages/shipper/CargoForm.test.tsx` (path TBD) |
| 7 | Vitest del preview (dos pines con coords correctas; degrada si una de las dos falta) | Spec | idem |
| 8 | Playwright spec golden path (publicar) | Spec | `frontend/tests/e2e/cargo-publish.spec.ts` |
| 9 | Playwright spec edit | Spec | `frontend/tests/e2e/cargo-edit.spec.ts` |
| 10 | `/critique` → `/polish` → `/audit` | UI gate | findings inline o en PR body |
| 11 | `just lint` + `just frontend-test-coverage` + `just frontend-test-e2e` | Pre-PR | — |

## 4. Test Strategy

Listado en el issue body. Notas:

- Mock del picker — exportar un mock helper desde `frontend/src/components/AddressPicker/__mocks__/` (o `vi.mock` inline). Permite testear el form sin tocar Google Places.
- Preview: si va minimal inline, probar `fitBounds` con coords stub. Si va `<ShipmentMap />`, dependencias de ese componente lo cubren.
- E2E: Playwright stub para `maps.googleapis.com/**` (mismo patrón que [[REQ-FE-00025]]).

`just frontend-test-coverage` mantiene 80%.

## 5. Risks & Decision Points

- **Orden con [[REQ-FE-00025]]** — este PR no puede mergear primero. Recomendación: el plan asume `<AddressPicker />` ya mergeado a `main`. Si necesitás avanzar antes del merge, branchear desde la branch de [[REQ-FE-00025]] y rebasear al merge.
- **Orden con [[REQ-FE-00028]] para el preview** — **Decision needed from user**: ¿es OK shippear un preview minimal inline acá y dejar el TODO de unificación a [[REQ-FE-00028]]? Recomendación: sí, porque hace este issue independiente del orden (sino se bloquea hasta US51, que tiene su propia cola de dependencias y agrega cycle-risk). El TODO inline es barato de cumplir cuando US51 aterrice.
- **Path del form de US27** — TBD. Confirmar en implementación con `grep -r "CargoForm\|cargo_create\|publishCargo" frontend/src/`.
- **`pickup_address` vs `pickup_zone`** — el form persiste `pickup_address` (string). El frontend NO inventa columnas nuevas. Si el backend renombra, ese cambio es responsabilidad de [[REQ-BE-00036]] y se comunica al frontend antes del PR.
- **Sin i18n library** — copy va en `shipperContent.ts`. Mismo TODO migracional que [[REQ-FE-00025]].

## 6. Out of Scope

- Cualquier cambio al componente `<AddressPicker />` mismo — si emerge un requerimiento (e.g. types adicionales), extender el componente en [[REQ-FE-00025]] o un PR separado.
- BE: ya cubierto por [[REQ-BE-00036]].

## 7. Acceptance Criteria

Re-lectura del issue body Backlog AC1–AC9. Verificación local antes del PR:

- [ ] AC1–AC3 — Vitest + e2e demuestran captura de las 4 coords.
- [ ] AC4 — Payload 422 verificado en e2e cuando una coord falta.
- [ ] AC5 — Preview con dos pines renderiza; mensaje fallback si una de las coords es null (caso defensivo).
- [ ] AC6 — `grep` no devuelve literales en español dentro de JSX.
- [ ] AC7 — `grep -r "AddressPicker\|google\.maps\.places" frontend/src/pages/shipper/` referencia el componente compartido — cero implementación duplicada del picker.
- [ ] AC8 — `just frontend-test-coverage` ≥ 80%.
- [ ] AC9 — `just frontend-test-e2e` golden path verde.

## 8. Related

- Issue body: `.gdsi-sdlc/issues/Backlog/REQ-FE-00026-us49-selector-direcciones-carga.issue.md`.
- US49: `docs/artifacts/backlog-us.typ:709-727`.
- Glossary: «Carga».
- BE companion: [[REQ-BE-00036]].
- FE dep: [[REQ-FE-00025]].
- Preview compartido (opcional): [[REQ-FE-00028]].
