---
tag: REQ-FE-00011
title: ETA + distancia + reroute automático al desviarse de la ruta
priority: P2
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/117
author: Claude Code
github_issue: 117
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtC-w
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:28:45.756144+00:00Z
labels:
- REQ
- FE
- maps
- eta
- mvp
- us13
---

## Summary

Mostrar al transportista la **distancia restante** y **tiempo estimado de llegada (ETA)** al siguiente waypoint, y recalcular la ruta cuando se desvíe del trazado. Tercera y última rebanada de US13.

## Problem Statement

US13 prescribe: "se muestra la distancia y tiempo estimado de llegada", "la navegación se actualiza si el transportista se desvía de la ruta". Estas son operaciones derivadas de la ruta + posición, pero requieren lógica adicional (heurística de desviación, debounce de recálculo) que se aísla mejor en su propio issue.

## Expected Behavior

- Card flotante sobre el mapa con: distancia restante (km), ETA (minutos), nombre del próximo waypoint.
- Reroute trigger: si la posición actual está a más de `X` metros (default 100m) de la polyline durante más de `Y` segundos (default 15s), se recalcula la ruta automáticamente.
- Recalcular llama a Directions API con `origin = posición actual` y mismo destino. Replace de la polyline.
- Toast no-intrusivo: "Recalculando ruta…" durante el recálculo.
- ETA actualizado a partir de la respuesta de Directions API (`duration_in_traffic` cuando esté disponible).

## Technical Notes

- **Heurística de desviación**: distance-to-polyline. Algoritmo simple: punto más cercano a cada segmento de la polyline; si el mínimo > umbral, está fuera.
- **Debounce**: no recalcular en cada update de GPS (rate limit). Throttle a 1 cada 15s mínimo + cooldown post-reroute.
- **Costos**: cada reroute cuesta una request de Directions API. Documentar como costo conocido.
- **Edge cases**: cuando el GPS pierde fix (posición vieja), no triggear reroute; usar `position.coords.accuracy` como filtro.

## Related

- US fuente: US13.
- Padres: `REQ-FE-00009`, `REQ-FE-00010`.

## Acceptance Criteria

- [ ] Card visible con distancia + ETA + waypoint.
- [ ] ETA se actualiza al recibir nueva ruta o a intervalos regulares.
- [ ] Reroute automático cuando el transportista se desvía > umbral por > tiempo configurable.
- [ ] Toast de feedback durante el recálculo.
- [ ] Throttle/cooldown evita storms de requests a Directions API.
- [ ] Test: spec con posiciones simuladas que cubre happy path + reroute.
