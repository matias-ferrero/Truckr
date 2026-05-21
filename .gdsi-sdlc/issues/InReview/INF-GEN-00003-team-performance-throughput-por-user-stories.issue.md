---
tag: INF-GEN-00003
title: 'team-performance: medir throughput por User Stories completadas vía ledger por sprint'
priority: P2
status: in_review
created: '2026-05-20'
plan: docs/features/INF/INF-GEN-00003/INF-GEN-00003-team-performance-us-ledger.plan.md
pr: https://github.com/tcorzo/fiuba-gestion-tp/pull/207
source: manual
author: Claude Code
labels:
- INF
- GEN
- team-performance
- tooling
---

## Summary

Refactor del CLI `team-performance` (`docs/scripts/team_performance/`) para que mida el throughput en **User Stories completadas por sprint** en lugar de **issues de GitHub cerradas**. La fuente de datos pasa a ser un **ledger manual por sprint** (`docs/sprints/sprint-NN.md`); se elimina por completo la dependencia de `gh`. Sucesor de `INF-GEN-00001` (el script original).

## Problem Statement

El throughput actual cuenta issues de GitHub cerradas como `COMPLETED`. Las issues tienen una dispersión de tamaño demasiado grande — una corrección de una línea y una feature fullstack cuentan ambas como "1" — lo que vuelve la muestra de throughput ruidosa y la proyección por bootstrap poco confiable. Las User Stories son una unidad de medida más homogénea y, además, tienen un denominador fijo (las ~35 US del backlog), lo que hace que "porcentaje del backlog" sea una métrica con sentido.

No existe hoy un registro estructurado de qué US se completaron en cada sprint. El conjunto completo de US vive en `docs/artifacts/backlog-us.typ` como documento legible (sin checkboxes ni fechas), y los checkboxes de criterios de aceptación de los archivos `.issue.md` no se mantienen (issues en `Done/` conservan sus AC sin tildar). Por lo tanto, "US completada" no es derivable de los datos actuales y requiere un ledger mantenido a mano.

## Expected Behavior

El CLI lee un directorio de archivos-por-sprint, computa el throughput en US/sprint y emite la misma proyección por bootstrap (inversa + directa) y el reporte Typst, ahora expresados en User Stories.

### Decisiones de diseño (resueltas en sesión de grilling)

1. **Unidad** — User Stories completadas, no issues.
2. **Señal de "completada"** — un ledger por sprint mantenido a mano; nada se infiere de GitHub.
3. **Fuente de datos** — el ledger es la **única** fuente. Se borran `github_source.py`, el modelo `Issue` y la dependencia de `gh`.
4. **Forma del ledger** — un archivo por sprint, `docs/sprints/sprint-NN.md`, con frontmatter YAML + cuerpo libre de retro.
5. **Métricas de tiempo** — se conservan vía un campo `in_progress_user_stories`.
6. **Modelo de WIP** — sólo arrastre: `in_progress` = US trabajadas pero no terminadas; nunca se solapa con `completed` en el mismo archivo. WIP-al-cierre = esa lista; lead time = sprint de completado − primer sprint en que apareció.
7. **Target** — flag explícito `--target-user-stories N` por corrida.
8. **Rollout** — se escriben a mano `sprint-01.md` (y `sprint-02.md`) como backfill.

### Formato del archivo de sprint (`docs/sprints/sprint-01.md`)

```yaml
---
sprint: 1
phase: development          # el tool sólo cuenta archivos que matchean --phase
status: closed              # closed = contado; in_progress = ignorado
window: 2026-05-07 → 2026-05-13
in_progress_user_stories: [US7]
completed_user_stories: [US1, US2, US14]
---
## Retro / ## Notas por US   (cuerpo libre; el tool ignora el cuerpo)
```

### Superficie de CLI

- **Se eliminan**: `--repo`, `--scope-growth`, `--sprint-start`, `--sprint-length-days`, `--as-of` (las ventanas vienen de los archivos; `status` reemplaza a `as-of`).
- **Se agregan**: `--sprints-dir` (default `docs/sprints/`), `--target-user-stories` (reemplaza a `--target-issues`), `--phase` (default `development`).
- **Se conservan**: `--remaining-sprints`, `--bootstrap-samples`, `--seed`, `--format`, `--output`.

## Current Behavior

`github_source.py` trae issues vía `gh issue list --json`; `sprints.py` las bucketea en ventanas de fecha por `closedAt`; `metrics.py` deriva throughput **y** cycle-time; el modelo de scope-growth muestrea issues `created` por sprint. Todo el flujo depende de `gh` y del mapeo issue→US, que es exactamente el origen del ruido de tamaño.

## Technical Notes

- **Módulos** — borrar `github_source.py` y `sprints.py` (ya no hace falta bucketear por fecha: el archivo de sprint ya declara sus US). Nuevo `ledger_source.py` que parsea + valida los archivos. `Sprint` pasa a `index / window_start / window_end / completed / in_progress` (tuplas de US-ids). `projection.py` conserva `bootstrap_inverse` / `bootstrap_forward` sin cambios de lógica; se borra el código de scope-growth y el parámetro `created_throughput`.
- **Lead time** — se mide en sprints enteros: `completion_sprint − first_seen_sprint` (0 si arranca y termina en el mismo sprint). Reemplaza a `cycle_time_days`.
- **WIP** — WIP-al-cierre del sprint N = `len(in_progress_user_stories)` del archivo N.
- **Schema v3** (JSON) — `completed_count`, `completed_user_stories`, `wip_at_end`; `cycle_time_days` → `lead_time_sprints`; `target_issues` → `target_user_stories`; se eliminan `closed_excluded*`, `created*`, `scope_growth*`. Claves JSON en inglés `snake_case`.
- **Validación** (exit 3) — los US-ids deben existir en `backlog-us.typ` (guarda contra typos); ningún US `completed` dos veces; ningún US en ambas listas del mismo archivo; ningún US `in_progress` en un sprint posterior a su completado; números de sprint contiguos desde 1; un único `phase` por corrida. Sigue exigiendo ≥2 archivos `status: closed` o `projection: null` (exit 4).
- **Reporte Typst** — se reescribe para el schema nuevo: la tarjeta de cycle-time pasa a "lead time (sprints)"; se elimina la columna `Excl.` y la sección de scope-growth. Salida sigue en es-AR.
- **Docs a actualizar** — `.claude/skills/team-performance/SKILL.md`, el `README.md` del tool, y la sección "Canonical inputs" de `CALENDAR.md`. El setting `[tool.team_performance].repo` de `pyproject.toml` queda muerto.

### Riesgos asumidos

- **Throughput grumoso** — las US grandes abarcan varios sprints, así que muchos sprints marcan 0 US completadas; la distribución se vuelve dispersa y los intervalos de proyección se ensanchan.
- **Muestra chica** — la fase de desarrollo son 7 sprints; p95/p99 sobre ≤7 puntos son esencialmente "el máximo repetido".
- **Lead time grueso** — medido en sprints enteros, p50/p75/p90 a menudo serán iguales (0/1/2).
- **Huecos silenciosos** — un sprint sin archivo parece simplemente "fin de fase"; la verificación de contigüidad sólo detecta el hueco si existe un archivo posterior.
- **Cambio de alcance de la métrica** — el trabajo de infra/docs (`INF-*`, la mitad de las issues) desaparece de la métrica; el reporte pasa a ser "throughput de producto", no "throughput de equipo".

## Related

- Predecesor: `INF-GEN-00001` — script `team-performance` original (throughput basado en issues).
- Skill: `.claude/skills/team-performance/SKILL.md`.
- Código del tool: `docs/scripts/team_performance/`.
- Fuente de US: `docs/artifacts/backlog-us.typ` (35 US, US1–US38 con huecos).
- Calendario de sprints: `CALENDAR.md` (dev = Sprint 1–7, semanal Jue→Mié).

## Acceptance Criteria

- [ ] Formato del ledger `docs/sprints/sprint-NN.md` definido y documentado (frontmatter: `sprint`, `phase`, `status`, `window`, `in_progress_user_stories`, `completed_user_stories`).
- [ ] Nuevo `ledger_source.py` parsea los archivos de sprint y devuelve `tuple[Sprint, ...]`.
- [ ] `github_source.py`, el modelo `Issue` y `sprints.py` eliminados; sin dependencia de `gh`.
- [ ] Modelo `Sprint` reformado a `index / window_start / window_end / completed / in_progress`.
- [ ] `metrics.py` computa throughput en US/sprint, lead time en sprints y WIP-al-cierre; sin `created_per_sprint` ni `closed_excluded`.
- [ ] `projection.py` sin scope-growth ni `created_throughput`; bootstrap inverso + directo intactos.
- [ ] CLI: flags `--sprints-dir`, `--target-user-stories`, `--phase` agregados; `--repo`, `--scope-growth`, `--sprint-start`, `--sprint-length-days`, `--as-of` eliminados.
- [ ] Schema JSON v3 con las claves renombradas; renderers JSON + texto actualizados.
- [ ] Plantilla del reporte Typst reescrita (lead time en sprints, sin columna `Excl.`, sin sección de scope-growth); compila con `--root docs`.
- [ ] Reglas de validación implementadas con los exit codes correctos (3 = validación, 4 = muestra insuficiente).
- [ ] Backfill: `sprint-01.md` (y `sprint-02.md`) escritos a mano.
- [ ] `SKILL.md`, `README.md` del tool y sección "Canonical inputs" de `CALENDAR.md` actualizados.
- [ ] Tests actualizados; `just team-performance-test` y `just team-performance-lint` pasan.
- [ ] Identifiers en inglés; copy del reporte y del CLI en es-AR.
