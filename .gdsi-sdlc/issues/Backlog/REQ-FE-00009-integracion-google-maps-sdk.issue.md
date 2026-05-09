---
tag: REQ-FE-00009
title: Integración con Google Maps SDK (provisión de API key, carga del SDK, mapa
  base)
priority: P1
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/115
author: Claude Code
github_issue: 115
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtC6E
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:28:21.753148+00:00Z
labels:
- REQ
- FE
- maps
- google-maps
- mvp
- us13
---

## Summary

Setup base de Google Maps en el frontend: gestión de API key, carga del SDK (con domain restrictions), componente reutilizable `<Map>` que renderiza un mapa centrado en una coordenada. Split de US13 que aísla la decisión de proveedor + autenticación + carga del SDK del resto del feature de navegación.

## Problem Statement

US13 ("Realizar Viaje — Navegación GPS") incluye Google Maps integration, ruta, GPS en tiempo real, ETA y reroute. Tratado como un único issue, la integración del SDK queda mezclada con cuestiones de UX y de actualización en tiempo real. El bloque de "instalar el SDK + manejar la API key + tener un componente `<Map>` mínimo" es self-contained y desbloquea otros features que también usan mapas (US21 tracking, US23 viajes compuestos, US24 encadenado).

## Expected Behavior

- Dependencia de Google Maps JavaScript API agregada (vía `@googlemaps/js-api-loader` o equivalente, importada por `deno.json`).
- API key gestionada vía variable de entorno `VITE_GOOGLE_MAPS_API_KEY`.
- Restricciones de la API key documentadas: HTTP referrers (localhost:5173 + dominio prod cuando exista), APIs habilitadas (Maps JavaScript API, Directions API, Geocoding API, Places API si aplica).
- Componente `<Map center={lat,lng} zoom={n}>` reutilizable en `frontend/src/components/Map.tsx`.
- Estado de carga (skeleton) y de error (sin API key, billing inactivo, etc.) cubiertos.
- README de la integración en `docs/05-appendices/google-maps.md` (cómo crear API key, cómo restringirla, cuál es la cuota mensual gratuita).

## Technical Notes

- **API key restriction**: nunca dejar la API key sin restricciones. La restricción por HTTP referrer es el mínimo (evita uso desde otros dominios). Para mobile/server se manejaría distinto (no aplica todavía).
- **Lazy load**: el SDK pesa varios KB; cargarlo solo en rutas que lo necesitan. `useEffect` con `js-api-loader` se encarga.
- **Strict CSP**: cuando se sume CSP al frontend, hay que abrir `*.googleapis.com`. Nota para el futuro.
- **Costos**: documentar el cap de uso del free tier ($200/mes) y plantear alertas. Salirse del free tier debería disparar un issue, no una factura.

## Related

- US fuente: US13.
- Hermanos: `REQ-FE-00010` (live route + GPS), `REQ-FE-00011` (ETA + reroute).
- Consumidores futuros: US21 (tracking), US23 (viajes compuestos), US24 (encadenado).

## Acceptance Criteria

- [ ] Dependencia agregada a `frontend/deno.json`.
- [ ] `VITE_GOOGLE_MAPS_API_KEY` documentada en `frontend/.env.example`.
- [ ] Componente `<Map>` renderiza un mapa centrado en una coordenada arbitraria.
- [ ] Estados de carga y error cubiertos con UX no-rota.
- [ ] `docs/05-appendices/google-maps.md` con instrucciones para crear y restringir la API key.
- [ ] Test: smoke que renderiza el componente sin romper (con la API key mockeada).
- [ ] La API key nunca queda hardcodeada en el repo.
