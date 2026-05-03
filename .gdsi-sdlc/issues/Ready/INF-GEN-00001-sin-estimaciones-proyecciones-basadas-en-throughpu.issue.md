---
tag: INF-GEN-00001
title: 'Sin estimaciones: Proyecciones basadas en Throughput'
priority: P2
status: ready
plan: docs/features/INF/INF-GEN-00001/INF-GEN-00001-team-performance-script.plan.md
created: '2026-04-18'
source: github
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/51
author: ''
github_issue: 51
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-03T12:54:04.039412+00:00Z
labels:
- correction
- next step
- INF
- GEN
assignees:
- tcorzo
---

## Estrategia
- NO hacer proyecciones de Montecarlo "clásicas"
- Basarse en throughput (issues/sprint)

## Estrategia
1. **Sprint 1 y 2**: Ejecutar SIN estimaciones
   - Solo medir: **cuántas US completamos por sprint**
2. **Proyección inversa**:
   - Calcular throughput promedio (issues/sprint)
   - Proyectar al revés: Con N sprints fijos, ¿qué probabilidad de completar X issues?
   - "Script que extrapolamos en el tiempo" — medir el throughput y proyectar

## Priorización
- Leer horizontalmente el USM
- Empezar por US críticas (especialmente Login)
- Luego el resto en orden de importancia

## Notas
- Primero datos reales (sprints 1-2), luego proyectamos
- Transparencia: mostrar datos, no estimaciones arbitrarias
