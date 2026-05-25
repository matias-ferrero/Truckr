---
tag: REQ-FE-00028
title: Mapa y Enlaces a Google Maps en Detalle de Envío (US51 — FE-only)
priority: P2
status: ready
created: '2026-05-24'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/242
author: Claude Code
github_issue: 242
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgtr4BA
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-24T23:55:56.934439+00:00Z
labels:
- REQ
- FE
- fulfilment
- carrier
- shipper
- mvp
- us51
- gmaps
sprint: 4
assignee: tcorzo
plan: docs/features/REQ/REQ-FE-00028/REQ-FE-00028-us51-mapa-enlaces-gmaps-detalle-envio.plan.md
---

## Summary

Reemplaza la sección reservada del componente de detalle de envío (US39, [[REQ-FE-00024]]) — anclada en `<section id="shipment-tracking-map">` — por un **mapa estático** con dos pines (origen verde, destino rojo) + dos **botones de deep-link** a Google Maps («Abrir origen en Google Maps» / «Abrir destino en Google Maps»). Issue FE-only: el deep-link es una URL estática, no necesita endpoint nuevo. Los pines vienen de [[REQ-FE-00025]] / [[REQ-FE-00026]] vía los modelos `TransportWindow` y `Cargo` que el envío referencia transitivamente.

Entrega también dos componentes reusables: `<ShipmentMap />` (el mapa de dos pines) y `<OpenInGmapsButton />` (el botón con la URL deep-link), pensados para montarse en otras pantallas en el futuro (ej. preview del detalle de oferta) sin retrabajo.

## Problem Statement

US39 deja la sección reservada con copy «Se mostrará el mapa cuando esté disponible» — funcional pero no útil. US51 cierra ese hueco. La motivación clave es práctica: el Carrier necesita orientarse antes de salir y navegar al pickup con la app nativa de Google Maps sin re-tipear la dirección. El Shipper quiere validar visualmente que el envío va a donde debe ir.

US51 es FE-only por construcción: la URL deep-link `https://www.google.com/maps/dir/?api=1&destination=<lat>,<lng>` es un string parametrizado por las coordenadas que ya están en el payload de US39 (vía [[REQ-BE-00035]] que devuelve el detalle completo del Shipment, transitivamente con los pines de `TransportWindow` y `Cargo`). No necesitamos endpoints nuevos.

## Expected Behavior

### Reemplazo de la sección reservada en US39

- El componente de US39 ya ancló la sección con `<section id="shipment-tracking-map">` (decisión cerrada en [[REQ-FE-00024]]). US51 reemplaza el contenido placeholder por el mapa + botones.
- Si por alguna razón los pines no están disponibles (caso defensivo — no debería pasar porque US48/US49 los hacen `NOT NULL`), la sección muestra un mensaje neutral con clave i18n `shipment.detail.map.unavailable` y no rompe el resto del detalle.

### `<ShipmentMap />` component

- Mapa estático con dos pines: origen (verde) y destino (rojo).
- Centro y zoom calculados automáticamente para mostrar ambos pines (`map.fitBounds(bounds)` con un padding razonable).
- Interactividad: solo zoom + pan estándar de Google Maps (no edición, no marcadores adicionales, no dibujado).
- Props: `origin: { lat, lng, label? }`, `destination: { lat, lng, label? }`.
- Tamaño: razonable para mostrarse dentro del detalle de envío (ancho fluido, alto fijo ~300px en desktop, ajustado en mobile).
- Si Google Maps JS API falla / no carga, fallback con clave i18n `shipment.detail.map.service_unavailable` (sin crashear el detalle entero).

### `<OpenInGmapsButton />` component

- Props: `destination: { lat, lng }`, `label` (clave i18n: «Abrir origen en Google Maps» o «Abrir destino en Google Maps» según contexto).
- Genera URL: `https://www.google.com/maps/dir/?api=1&destination=${lat},${lng}` (truncadas a 6 decimales).
- Renderiza como `<a href={url} target="_blank" rel="noopener noreferrer">` con styling de botón del design system.
- En mobile (user-agent detection ligera — opcional pero deseable), preferir el esquema `comgooglemaps://` o `maps://` para abrir la app nativa, con fallback a la URL web.
- Accesibilidad: `aria-label` explícito con destino para screen readers.

### Layout en el detalle

- Mapa en la sección reservada.
- Debajo (o al costado, según el layout responsive), dos botones lado a lado — origen primero, destino segundo. En mobile, stack vertical.
- Los componentes son visibles en **cualquier estado del envío** (`accepted` / `in_transit` / `delivered` / `cancelled`); los datos de origen y destino no cambian con el estado.

## Acceptance Criteria

> AC1–AC6 son textuales de US51 (`docs/artifacts/backlog-us.typ:749-786`). AC7–AC10 son garantías técnicas adicionales.

- [ ] **AC1** — En la pantalla de detalle de envío (US39), reemplaza la sección reservada «Se mostrará el mapa cuando esté disponible» por un mapa estático con dos pines: origen (verde) y destino (rojo), centrado para mostrar ambos.
- [ ] **AC2** — Debajo (o al costado) del mapa, dos botones bien diferenciados: «Abrir origen en Google Maps» y «Abrir destino en Google Maps». Cada botón dispara la URL deep-link `https://www.google.com/maps/dir/?api=1&destination=<lat>,<lng>` con las coordenadas correspondientes, en una nueva pestaña / la app nativa según el dispositivo.
- [ ] **AC3** — Si los pines no están disponibles (caso defensivo), la sección muestra un mensaje neutral con clave i18n y no rompe el resto del detalle.
- [ ] **AC4** — El mapa y los botones son visibles en cualquier estado del envío; los datos de origen y destino no cambian con el estado.
- [ ] **AC5** — Toda la copy (labels de pines, texto de botones, mensaje defensivo) se resuelve por clave i18n.
- [ ] **AC6** — Los componentes `<ShipmentMap />` y `<OpenInGmapsButton />` se entregan como piezas reusables y testeadas (Vitest + 1 spec Playwright cubriendo el golden path).
- [ ] **AC7** — La sección se monta en el `<section id="shipment-tracking-map">` que [[REQ-FE-00024]] ya dejó anclado — sin reescribir la estructura del detalle.
- [ ] **AC8** — La URL deep-link usa coordenadas truncadas a 6 decimales (alineado con `DECIMAL(9,6)`).
- [ ] **AC9** — Si Google Maps JS API falla (sin key, network, quota), el mapa degrada al mensaje `service_unavailable` con clave i18n; los botones de deep-link **siguen funcionando** (no dependen de la JS API, solo de la URL).
- [ ] **AC10** — Cobertura Vitest ≥ 80%; Playwright cubre el golden path (Carrier abre detalle, ve mapa con dos pines, clickea «Abrir origen», verifica el href).

### Tests requeridos

- [ ] Vitest — `<ShipmentMap />` renderiza dos `<Marker />` con las coordenadas correctas; `fitBounds` se llama con el rectángulo correcto.
- [ ] Vitest — `<ShipmentMap />` muestra `service_unavailable` cuando Google Maps API no carga.
- [ ] Vitest — `<ShipmentMap />` muestra `unavailable` cuando `origin` o `destination` son null/undefined.
- [ ] Vitest — `<OpenInGmapsButton />` genera la URL correcta; `target="_blank"`; `rel="noopener noreferrer"`.
- [ ] Vitest — la sección renderiza en estados `accepted` / `in_transit` / `delivered` / `cancelled` sin variar.
- [ ] Playwright e2e — Carrier abre `/carrier/shipments/:id`, espera a que el mapa se renderice, verifica que los dos botones tienen los hrefs esperados con las coordenadas del fixture.

## Technical Notes

**FE-only por construcción** — no hay endpoint nuevo. Los pines llegan en el payload de US39 (`GET /api/shipments/:id` de [[REQ-BE-00035]]) transitivamente desde `TransportWindow` (origin) y `Cargo` (delivery). Si querés el contrato exacto, leer la sección "shape esperado" de [[REQ-BE-00035]] y confirmar que ya emite `origin_lat` / `origin_lng` y `delivery_lat` / `delivery_lng` en el shipment serializer. Si no, **es trivial agregar** y se hace en el mismo PR que [[REQ-BE-00035]] está planeando — no se justifica un nuevo issue BE.

**Coordenadas vienen de qué exactamente** — un `Shipment` se origina al aceptar un `CargoOffer` (US12), que linkea un `Cargo` (carga) con una `TransportWindow` (ventana). El **origen del envío** es el `pickup` del Cargo (donde retira el Carrier), el **destino del envío** es el `delivery` del Cargo (donde entrega). Las coordenadas del Cargo (`pickup_lat` / `pickup_lng` / `delivery_lat` / `delivery_lng`) son las que se renderizan, no las del `TransportWindow`. Verificar con el plan de [[REQ-BE-00035]] que el serializer las incluye.

**Google Maps JS API key** — misma key que [[REQ-FE-00025]] (US48) — coordinar con Fernando para que esté en `frontend/.env`. Si la key no está, el componente degrada al `service_unavailable` pero los botones siguen funcionales (los deep-links no requieren la JS API).

**Mobile deep-link** — el esquema `comgooglemaps://` solo funciona si Google Maps app está instalada; usar feature-detection ligera (verificar UA) o simplemente dejar el `https://www.google.com/maps/...` que Android e iOS interpretan automáticamente como "abrir en app nativa si está instalada, sino navegador". El segundo enfoque es más portable y es lo que sugiere el AC2 ("nueva pestaña / la app nativa según el dispositivo").

**No re-anchear la sección** — US39 ya dejó `<section id="shipment-tracking-map">` listo (decisión cerrada en triage 2026-05-24). US51 reemplaza el contenido, no la estructura. No mover el ancla, no renombrarla.

**SQLite-forever** — irrelevante para este issue (FE-only, no toca DB).

**Lenguaje** — claves i18n en inglés, valores en español. Sin literales españoles en JSX.

**Design system / lint** — botones via primitives del DS; sin raw hex; sin gradient-text.

## Related

- US51 en `docs/artifacts/backlog-us.typ:749-786`.
- Glossary: «Ventana de transporte» y «Carga» (`docs/05-appendices/glossary.md`) — confirman que los pines existen como `DECIMAL(9,6)`.
- Dependencia hard: [[REQ-FE-00024]] (US39 — debe estar mergeado, ancla la sección).
- Dependencia hard upstream: [[REQ-FE-00025]] + [[REQ-FE-00026]] (los pines existen en los modelos).
- Dependencia hard BE: [[REQ-BE-00035]] (el serializer del shipment debe incluir las coordenadas — verificar y, si no, sumarle al PR).
- Cliente potencial del `<ShipmentMap />`: preview de detalle de oferta (futuro, no hay issue todavía).

## Notas de implementación para el assignee

- **PR title format** — conventional prefix obligatorio (`feat(fulfilment): ...`), sin `[REQ-FE-00028]` bracket.
- **`gh pr create --assignee @me`**.
- **No tocar `.gdsi-sdlc/config.json`.**
- **Bloqueado por [[REQ-FE-00024]]** (Sprint 3) — necesitás el ancla `<section id="shipment-tracking-map">` mergeado.
- **Bloqueado por [[REQ-FE-00025]] + [[REQ-FE-00026]]** — los pines tienen que existir en los modelos para que el serializer los emita.
- **Verificar [[REQ-BE-00035]] serializer** — si no emite las coordenadas, agregarlas al payload en el mismo sprint (PR pequeño, no justifica nuevo issue BE).
- **Pre-PR UI quality gate** (CLAUDE.md): `/critique` → `/polish` → `/audit`. Luego `just lint`, `just frontend-test-coverage` (80%), `just frontend-test-e2e`.

## Decisiones cerradas en triage (2026-05-24)

| Tema | Decisión |
|---|---|
| Scope | FE-only. URL deep-link es string parametrizado, sin endpoint nuevo. |
| Mapa interactivo | No. Estático + zoom/pan estándar. Sin edición ni dibujo. |
| Visibilidad por estado | Visible en todos los estados (`accepted` / `in_transit` / `delivered` / `cancelled`). |
| Ancla del slot | `<section id="shipment-tracking-map">` (definido en [[REQ-FE-00024]]). |
| Components reusables | `<ShipmentMap />` y `<OpenInGmapsButton />`. |
| Mobile deep-link | URL estándar `https://www.google.com/maps/...` — Android/iOS la abren en app nativa si está instalada. |
