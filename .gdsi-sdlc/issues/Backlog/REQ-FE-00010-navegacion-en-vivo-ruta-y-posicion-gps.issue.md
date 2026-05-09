---
tag: REQ-FE-00010
title: Navegación en vivo — ruta + posición GPS del transportista en el mapa
priority: P1
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/116
author: Claude Code
github_issue: 116
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtC8k
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:28:33.844586+00:00Z
labels:
- REQ
- FE
- maps
- gps
- mvp
- us13
---

## Summary

Sobre el componente `<Map>` (issue padre `REQ-FE-00009`), dibujar la ruta hacia el siguiente destino y la posición actual del transportista en tiempo real. Esta es la rebanada **dinámica** de US13: ruta + posición. ETA y reroute viven en `REQ-FE-00011`.

## Problem Statement

US13 prescribe "se muestra la ruta hacia el siguiente destino" y "se puede ver el recorrido en tiempo real por GPS". Ambas son actualizaciones del mapa, pero diferentes en frecuencia y fuente: la ruta se calcula una vez (Directions API), la posición GPS llega del Geolocation API del navegador con frecuencia ~1 Hz.

## Expected Behavior

- Pantalla `/trips/:id/navigate` (transportista en viaje activo).
- Al montar, la pantalla:
  - Llama a Directions API con `origin = posición actual` y `destination = dirección del siguiente waypoint` (retiro o entrega del `Shipment`).
  - Renderiza la ruta (polyline) sobre el `<Map>`.
  - Suscribe a `navigator.geolocation.watchPosition` para actualizar un marker de "yo" en cada update.
- Marker animado (smooth) entre updates de GPS para evitar saltos.
- Botón de stop + permission flow (qué hacer si el usuario niega permission de geolocation).
- Privacidad: la posición se reporta al backend (`POST /api/trips/:id/locations`) para que el cliente la vea (US21 tracking). Frecuencia configurable (default 30s para no quemar batería).

## Technical Notes

- **Directions API**: se factura por request. Cachear la ruta una vez, recalcular solo si reroute (en `REQ-FE-00011`).
- **Battery**: `watchPosition` con `enableHighAccuracy: true` consume batería rápido. Documentar como tradeoff conocido para MVP.
- **Backend ingestion**: el endpoint `POST /api/trips/:id/locations` puede ser un issue separado de BE (`TrackingEvent` model — cubierto por `REQ-BE-00005`). Este issue **asume que existe**; si no existe todavía, el frontend mantiene la posición localmente y se sincroniza cuando el endpoint esté.
- **Permission UX**: si el usuario niega geolocation, mostrar pantalla de "Activá la ubicación" con instrucciones por navegador.

## Related

- US fuente: US13.
- Padre: `REQ-FE-00009` (SDK Maps).
- Hermano: `REQ-FE-00011` (ETA + reroute).
- Consumidor: US21 tracking lee la posición del Trip que este issue persiste.

## Acceptance Criteria

- [ ] Pantalla `/trips/:id/navigate` renderiza mapa con ruta calculada hacia el siguiente waypoint.
- [ ] Marker de "yo" se actualiza en tiempo real con la posición del navigator.
- [ ] Permission flow gracefulmente cubre denegación + revocación.
- [ ] Posición se envía al backend a `POST /api/trips/:id/locations` (o se queda en cola si el endpoint no responde).
- [ ] Frecuencia de upload configurable (default 30s).
- [ ] Test: feature spec con geolocation mockeada.
