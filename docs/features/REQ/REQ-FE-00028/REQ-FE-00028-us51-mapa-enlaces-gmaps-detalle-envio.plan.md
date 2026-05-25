# REQ-FE-00028: Mapa y Enlaces a Google Maps en Detalle de Envío (US51 — FE-only)

| Field | Value |
|-------|-------|
| **Tag** | REQ-FE-00028 |
| **Title** | Mapa y Enlaces a Google Maps en Detalle de Envío (US51 — FE-only) |
| **Priority** | P2 |
| **Status** | READY |
| **Created** | 2026-05-24 |
| **Sprint** | 4 |
| **Author** | Claude Code |
| **Depends On** | **Hard:** [[REQ-FE-00024]] (Sprint 3 — deja anclado el `<section id="shipment-tracking-map">`). [[REQ-BE-00036]] (`ShipmentResource` detail emite cargo `pickup_*` + `delivery_*`). **Suave:** [[REQ-FE-00025]] / [[REQ-FE-00026]] (los pines existen en los modelos para que el serializer los emita). |
| **Decision Doc** | N/A — decisiones cerradas inline en el issue body. |
| **Selected Approach** | Single PR — dos componentes reusables (`<ShipmentMap />` + `<OpenInGmapsButton />`) + integración en el slot reservado de US39. FE-only — la URL deep-link es string parametrizado, sin endpoint nuevo. Validación crítica al planning: confirmar que `ShipmentResource` detail (REQ-BE-00035 + REQ-BE-00036) ya emite las coords; si no, sumarlas al PR de REQ-BE-00036. |

---

## 1. Problem Statement

El issue body (Backlog) tiene el spec completo. Issue FE-only por construcción (deep-link es URL parametrizada).

Estado al arrancar:
- **`<section id="shipment-tracking-map">` no existe todavía** — [[REQ-FE-00024]] (US39) lo deja anclado cuando se implemente (Sprint 3, en flight, plan-grade en issue body). Este PR depende de que aterrice primero. Confirmar el path exacto del componente de detalle cuando US39 mergee.
- **`ShipmentResource` detail no emite cargo coords todavía** — recon confirmó que REQ-BE-00035 NO incluye `pickup_lat/lng` / `delivery_lat/lng` en el bloque `cargo`. [[REQ-BE-00036]] AC8 los suma. **Verificación crítica al implementación**: leer el JSON real de `GET /api/shipments/:id` y validar que los campos están. Si faltan, escalar al autor de [[REQ-BE-00036]] o sumarlos directamente en un PR pair.
- `@react-google-maps/api` instalado por [[REQ-FE-00025]] — provee `<GoogleMap />` + `<Marker />`.
- No hay endpoint nuevo necesario.

## 2. Solution Design

### 2.1 Estrategia — dos componentes reusables, montaje no invasivo

`<ShipmentMap />` y `<OpenInGmapsButton />` se entregan como pieces aislados, testables independientemente, montados en el slot existente de US39 sin reescribir su estructura.

Orden mecánico:

1. **Verificar payload de `GET /api/shipments/:id`** — leer el JSON real (curl o spec request); confirmar que el bloque `cargo` incluye `pickup_lat`, `pickup_lng`, `delivery_lat`, `delivery_lng`. Si no, **STOP — flag al autor de [[REQ-BE-00036]] y sumar las coords en su PR** (no abrir nuevo issue BE per handoff). Sin esto, US51 no tiene de dónde sacar los pines.
2. `<ShipmentMap />` en `frontend/src/components/ShipmentMap/`.
3. `<OpenInGmapsButton />` en `frontend/src/components/OpenInGmapsButton/`.
4. Reemplazar contenido del `<section id="shipment-tracking-map">` por el mapa + dos botones (origen + destino).
5. Vitest + Playwright.
6. `/critique` → `/polish` → `/audit` + lint + coverage + e2e.

### 2.2 `<ShipmentMap />` API

```ts
export interface ShipmentMapProps {
  origin: { lat: number; lng: number; label?: string } | null;
  destination: { lat: number; lng: number; label?: string } | null;
  height?: number;  // default 300
}

export function ShipmentMap(props: ShipmentMapProps): JSX.Element;
```

Comportamiento:
- Si `origin === null || destination === null` → render `<MapUnavailable />` con copy `shipmentMapContent.unavailable`.
- Si la JS API falla (`useJsApiLoader.loadError` o key missing) → render `<MapServiceUnavailable />` con copy `shipmentMapContent.service_unavailable`. Los botones de deep-link siguen rendereando aparte (no dependen del map load).
- Si ambos disponibles → `<GoogleMap>` con dos `<Marker>` y `fitBounds([origin, destination], { padding: 64 })` en `onLoad`.
- Pin de origen verde (`icon: { ... }`), destino rojo. Usar URLs de iconos estándar de Google (`http://maps.google.com/mapfiles/ms/icons/green-dot.png` y `red-dot.png`) o un asset del DS.
- Sólo zoom + pan estándar (no dibujado, no edit).

Tamaño: `height: 300` desktop, `aspect-ratio` o `min-height` para mobile. Usar primitives del DS.

### 2.3 `<OpenInGmapsButton />` API

```ts
export interface OpenInGmapsButtonProps {
  destination: { lat: number; lng: number };
  label: string;             // resolved copy: "Abrir origen en Google Maps" or "Abrir destino..."
  ariaLabel?: string;
}

export function OpenInGmapsButton(props: OpenInGmapsButtonProps): JSX.Element;
```

Implementación:

```tsx
function buildGmapsUrl({ lat, lng }: { lat: number; lng: number }): string {
  // truncate to 6 decimals (defense in depth — DB is DECIMAL(9,6))
  const truncate = (n: number) => Number(n.toFixed(6));
  return `https://www.google.com/maps/dir/?api=1&destination=${truncate(lat)},${truncate(lng)}`;
}

export function OpenInGmapsButton({ destination, label, ariaLabel }: OpenInGmapsButtonProps) {
  return (
    <a
      href={buildGmapsUrl(destination)}
      target="_blank"
      rel="noopener noreferrer"
      aria-label={ariaLabel ?? label}
      className={dsButtonClasses}
    >
      {label}
    </a>
  );
}
```

Mobile deep-link: NO custom UA detection. La URL `https://www.google.com/maps/dir/?api=1&destination=...` la abren Android e iOS en la app nativa si está instalada (sino, navegador). Decisión cerrada — más portable.

### 2.4 Reemplazo del slot

Cuando US39 ([[REQ-FE-00024]]) aterrice, dejará algo así (estimado — confirmar en implementación):

```tsx
<section id="shipment-tracking-map" aria-labelledby="map-heading">
  <h2 id="map-heading">{content.tracking.title}</h2>
  <p>{content.tracking.placeholder}</p>  {/* ← se va */}
</section>
```

US51 lo reemplaza por:

```tsx
<section id="shipment-tracking-map" aria-labelledby="map-heading">
  <h2 id="map-heading">{content.tracking.title}</h2>
  <ShipmentMap
    origin={{ lat: shipment.cargo.pickup_lat, lng: shipment.cargo.pickup_lng, label: shipment.cargo.pickup_address }}
    destination={{ lat: shipment.cargo.delivery_lat, lng: shipment.cargo.delivery_lng, label: shipment.cargo.delivery_address }}
  />
  <div className={dsButtonRowClasses}>
    <OpenInGmapsButton
      destination={{ lat: shipment.cargo.pickup_lat, lng: shipment.cargo.pickup_lng }}
      label={content.tracking.openOriginInGmaps}
    />
    <OpenInGmapsButton
      destination={{ lat: shipment.cargo.delivery_lat, lng: shipment.cargo.delivery_lng }}
      label={content.tracking.openDestinationInGmaps}
    />
  </div>
</section>
```

**No re-anchear la sección.** Decisión cerrada.

### 2.5 Visibilidad por estado del envío

El mapa + botones se renderizan en todos los estados (`accepted` / `in_transit` / `delivered` / `cancelled`). Los datos no cambian con el estado — viven en el `Cargo`, no en el `Shipment`. Spec de Vitest cubre los 4 estados.

### 2.6 Copy

`frontend/src/components/ShipmentMap/shipmentMapContent.ts`:

```ts
export const shipmentMapContent = {
  unavailable: 'Mapa no disponible — falta información de ubicación.',
  service_unavailable: 'No pudimos cargar el mapa. Probá recargar la página.',
} as const;
```

Copy del slot del detalle (botones, heading) — agregar a `carrierContent.ts` y/o `shipperContent.ts` (o el `*Content.ts` que use el detalle de envío de US39).

## 3. Implementation Tasks

| # | Task | Layer | Files |
|---|------|-------|-------|
| 0 | **Verificar** `GET /api/shipments/:id` emite cargo coords; coordinar con [[REQ-BE-00036]] si faltan | Verification | — |
| 1 | `<ShipmentMap />` + content | Component | `frontend/src/components/ShipmentMap/{index,shipmentMapContent}.tsx`/`.ts` |
| 2 | `<OpenInGmapsButton />` + tests | Component | `frontend/src/components/OpenInGmapsButton/{index,test}.tsx` |
| 3 | Vitest del `<ShipmentMap />` (estados + service_unavailable + unavailable) | Spec | `frontend/src/components/ShipmentMap/ShipmentMap.test.tsx` |
| 4 | Integración en el componente de detalle de envío de US39 | Page | `frontend/src/pages/<carrier\|shipper>/ShipmentDetail.tsx` (TBD post US39) |
| 5 | Copy para labels de botones / heading en el `*Content.ts` correspondiente | Content | `frontend/src/<carrier\|shipper>Content.ts` |
| 6 | Vitest del slot (4 estados, hrefs, defensive null) | Spec | `frontend/src/pages/.../ShipmentDetail.test.tsx` |
| 7 | Playwright spec (golden path: abrir detalle, ver mapa, verificar hrefs) | Spec | `frontend/tests/e2e/shipment-detail-map.spec.ts` |
| 8 | `/critique` → `/polish` → `/audit` | UI gate | findings inline o en PR body |
| 9 | `just lint` + `just frontend-test-coverage` + `just frontend-test-e2e` | Pre-PR | — |

## 4. Test Strategy

Listado completo en el issue body. Notas:

- **Vitest `<ShipmentMap />`** — mockear `useJsApiLoader` y `GoogleMap`/`Marker` para verificar props (positions, fitBounds llamada con el rectángulo correcto). Toggle `loadError` para `service_unavailable`. `origin=null` o `destination=null` → `unavailable`.
- **Vitest `<OpenInGmapsButton />`** — URL exacta esperada (con 6 decimales); `target="_blank"`; `rel="noopener noreferrer"`; `aria-label` set.
- **Vitest slot** — render del detalle en estados `accepted`/`in_transit`/`delivered`/`cancelled` no varía el mapa ni los botones.
- **Playwright** — abrir `/carrier/shipments/:id` con fixture; esperar mapa; `expect(page.locator('a[href*="/maps/dir/"]')).toHaveAttribute('href', ...)` para ambos botones.

`just frontend-test-coverage` ≥ 80%.

## 5. Risks & Decision Points

- **Dependencia hard de [[REQ-FE-00024]]** — sin US39 mergeado, el slot no existe. Este PR no puede mergear antes. Recomendación: bloquear este PR hasta US39 ✓ verde en `main`.
- **Dependencia hard del ShipmentResource emitiendo cargo coords** — verificación crítica al implementación. **Decision needed from user**: si las coords no están en el payload, ¿abrimos un PR pair con [[REQ-BE-00036]] para sumarlas o agregamos al PR de [[REQ-BE-00036]] mismo? Recomendación del handoff: fold-in en [[REQ-BE-00036]], no nuevo issue BE.
- **Pines del Cargo, no del TransportWindow** — clarificación importante: el origen del envío es el `pickup` del Cargo, NO el `origin` del TransportWindow. Una vez que el envío arranca, el Carrier va donde está la carga. Documentar en el PR body para evitar confusión.
- **Iconos verde/rojo** — usar URLs de Google Maps default es funcional pero no on-brand. **Decision needed from user**: ¿aceptable para MVP o querés assets custom del DS? Recomendación: default Google para MVP; polish post-aterrizaje si lo pide `/critique`.
- **Botones en mobile** — stack vertical confirmado en el issue body. `/audit` verifica focus + contrast + tappable area ≥ 44px.
- **Llamadas reales a Google en CI** — route stub para `maps.googleapis.com/**` en Playwright. Verificar con `--reporter=html` que no hay flakes.

## 6. Out of Scope

- Endpoint nuevo (FE-only).
- Live tracking del Carrier (post-MVP — US13/US21).
- Edición del mapa, dibujado, marcadores adicionales.
- Mover el ancla `<section id="shipment-tracking-map">`.

## 7. Acceptance Criteria

Re-lectura del issue body Backlog AC1–AC10. Verificación local antes del PR:

- [ ] AC1–AC2 — Vitest + e2e renderizan dos pines y dos botones con hrefs correctos.
- [ ] AC3 — Spec defensive cuando una coord es null.
- [ ] AC4 — Spec multi-estado.
- [ ] AC5 — `grep` no devuelve literales en español dentro del JSX (sólo `*Content.ts`).
- [ ] AC6 — Componentes documentados (TS types exportados).
- [ ] AC7 — `grep -n 'id="shipment-tracking-map"' frontend/src/` devuelve la sección — no fue movida ni renombrada.
- [ ] AC8 — Vitest assert: la URL tiene exactamente 6 decimales (`-34.603722` no `-34.6037229876`).
- [ ] AC9 — Spec demuestra que botones siguen funcionando con `loadError=true`.
- [ ] AC10 — `just frontend-test-coverage` ≥ 80%, `just frontend-test-e2e` verde.

## 8. Related

- Issue body: `.gdsi-sdlc/issues/Backlog/REQ-FE-00028-us51-mapa-enlaces-gmaps-detalle-envio.issue.md`.
- US51: `docs/artifacts/backlog-us.typ:749-786`.
- Glossary: «Ventana de transporte», «Carga».
- Dep hard FE: [[REQ-FE-00024]] (US39).
- Dep hard BE: [[REQ-BE-00036]] (`ShipmentResource` detail con cargo coords — verificar/fold-in).
- Dep upstream: [[REQ-FE-00025]] + [[REQ-FE-00026]] (los pines existen).
- Cliente potencial del `<ShipmentMap />`: preview de oferta (futuro).
