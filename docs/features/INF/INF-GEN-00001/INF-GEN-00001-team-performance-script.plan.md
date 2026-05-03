# INF-GEN-00001: Sin estimaciones — Script de proyección por throughput

| Field | Value |
|-------|-------|
| **Tag** | INF-GEN-00001 |
| **Title** | Sin estimaciones: Proyecciones basadas en Throughput |
| **Priority** | P2 |
| **Status** | READY |
| **Created** | 2026-05-03 |
| **Updated** | 2026-05-03 |
| **Author** | Claude Code |
| **Depends On** | — |
| **Decision Doc** | N/A |
| **Selected Approach** | N/A — alcance ya delimitado por el usuario (script único, datos agregados de equipo) |

---

## 1. Problem Statement

El equipo decidió **no estimar** issues individuales y, en su lugar, medir **throughput real** (issues cerrados por sprint) durante los sprints 1–2 y proyectar al revés: dado N sprints restantes, ¿qué probabilidad hay de cerrar X issues? Esto requiere una herramienta determinística y reproducible que:

- Lea las issues reales del repo (fuente de verdad: GitHub Issues — único origen con `closed_at` confiable).
- Calcule throughput por sprint y estadísticas descriptivas **a nivel equipo** (sin desagregar por persona).
- Genere una proyección inversa basada en bootstrap del throughput histórico (no Monte Carlo clásico sobre estimaciones).
- Emita salida **estructurada** (JSON) y un resumen de tabla legible para sumar al deliverable académico.

Este plan cubre **únicamente** el script (`docs/scripts/team_performance.py`). La definición de cadencia de sprint, las dos primeras corridas de medición y el rework de artifacts (estimaciones-out) son trabajos paralelos, fuera del alcance de este issue de implementación.

---

## 2. Solution Design

### 2.1 Fuente de datos

**GitHub Issues vía `gh` CLI** (`gh issue list --state all --json ...`). Razones:

- Es el único lugar con `closedAt` por issue. Los `.issue.md` locales solo tienen `created` y `last_synced` — insuficiente.
- `gh` ya está provisionado por `mise.toml`; cero deps nuevas.
- Filtra ruido (ya excluye PRs por defecto).
- El bidirectional-sync de `.gdsi-sdlc/` garantiza que el set local y el remoto coinciden.

Campos consumidos por issue: `number, title, state, createdAt, closedAt, labels, milestone`.

> Asignaciones (`assignees`) **se ignoran deliberadamente**: el principio del issue es "team performance, no individual basis".

### 2.2 Definición de sprint

Sprint = ventana de N días consecutivos a partir de una fecha ancla, sin gaps. Configurable por CLI:

- `--sprint-start YYYY-MM-DD` — fecha de inicio del Sprint 1 (default: leído de `pyproject.toml [tool.team_performance]` si existe; fallback: la fecha de creación del primer issue cerrado).
- `--sprint-length-days N` — default 14.
- `--as-of YYYY-MM-DD` — corte para sprints "completos" (default: hoy).

Un issue pertenece al sprint en cuya ventana cae su `closedAt`. Issues abiertos no cuentan para throughput pero sí para WIP.

### 2.3 Métricas calculadas (todas a nivel equipo)

**Por sprint:**

| Métrica | Definición |
|---------|------------|
| `closed_count` | issues con `closedAt` en la ventana |
| `created_count` | issues con `createdAt` en la ventana |
| `wip_at_end` | issues abiertos al final del sprint |
| `breakdown.by_prefix` | `{REQ, FIX, INF, DOC, …}` → count |
| `breakdown.by_scope` | `{BE, FE, INFRA, DOC, GEN}` → count |
| `breakdown.by_priority` | `{P0..P3, unset}` → count |

**Agregadas (sobre sprints completos, excluye el sprint en curso):**

| Métrica | Definición |
|---------|------------|
| `throughput.mean` / `median` / `stdev` / `min` / `max` | sobre `closed_count` |
| `cycle_time_days.p50` / `p75` / `p90` | `closedAt - createdAt`, en días, sobre issues cerrados |
| `sample_size_sprints` | nº de sprints completos en la muestra |

**Proyección inversa (bootstrap sobre throughput histórico):**

Dado un objetivo de `--target-issues X` y `--remaining-sprints N`:

1. Tomar la lista observada `T = [t_1, t_2, …, t_k]` (closed_count por sprint completo).
2. Resamplear con reemplazo `B = 10_000` muestras de tamaño N.
3. Sumar cada muestra; calcular fracción de muestras donde `sum >= X`.
4. Reportar `P(close >= X in N sprints) = …` y los percentiles `p10/p50/p90` del total proyectado.

Esto **no** es Monte Carlo clásico (no se asume distribución sobre estimaciones por issue); es bootstrap empírico del throughput observado, que es exactamente lo que pide el issue.

> Si `sample_size_sprints < 2`, la proyección se omite con un mensaje explícito ("insufficient data — at least 2 completed sprints required"); el script igualmente imprime las métricas observadas.

### 2.4 Salida

Dos modos, controlados por `--format`:

- `--format json` (default) — un único objeto JSON a stdout (script-friendly, parseable, comiteable como snapshot).
- `--format text` — tabla Markdown legible (para pegar en docs / commit messages).
- `--format both` — primero `text` a stderr, luego `json` a stdout (permite redirigir el JSON sin perder el resumen).

Esquema JSON (estable, versionado en `schema_version`):

```json
{
  "schema_version": "1",
  "generated_at": "2026-05-03T12:00:00Z",
  "config": { "sprint_start": "...", "sprint_length_days": 14, "as_of": "..." },
  "sprints": [
    { "index": 1, "start": "...", "end": "...", "closed_count": 3, "created_count": 4, "wip_at_end": 5,
      "breakdown": { "by_prefix": {...}, "by_scope": {...}, "by_priority": {...} } }
  ],
  "aggregate": {
    "throughput": { "mean": 3.5, "median": 3, "stdev": 1.2, "min": 2, "max": 6 },
    "cycle_time_days": { "p50": 4.0, "p75": 7.5, "p90": 12.0 },
    "sample_size_sprints": 4
  },
  "projection": {
    "target_issues": 20,
    "remaining_sprints": 5,
    "p_meet_or_exceed_target": 0.62,
    "total_projected": { "p10": 12, "p50": 18, "p90": 26 },
    "method": "bootstrap_throughput",
    "bootstrap_samples": 10000
  }
}
```

### 2.5 Determinismo

- `--seed N` (default 42) — fija la semilla del bootstrap. Output reproducible byte-a-byte para una misma data.
- `gh` se llama con `--limit 1000` (más que suficiente; el repo tiene <30 issues).

### 2.6 Dependencias

Solo stdlib + lo ya declarado:

- `subprocess` + `json` para `gh`.
- `statistics` (stdlib) para mean/median/stdev/percentiles.
- `random.Random(seed)` para bootstrap.
- **No usar pandas** (overkill para <100 issues; mantener el script trivialmente leíble y sin warm-up). `pyproject.toml` queda intacto.

### 2.7 Estructura del módulo

Single file, organizado por funciones puras + un `main()` con `argparse`. No clases, no abstracciones tempranas:

```
def fetch_issues(repo: str, limit: int) -> list[dict]: ...
def assign_to_sprints(issues, start, length_days, as_of) -> list[Sprint]: ...
def compute_aggregate(sprints) -> dict: ...
def project(throughput_history, target, n_sprints, samples, seed) -> dict: ...
def render_text(report) -> str: ...
def render_json(report) -> str: ...
def main(argv) -> int: ...
```

`Sprint` puede ser un `@dataclass` simple. Tests directos sobre las funciones puras.

---

## 3. Implementation Tasks

| # | Task | Status | Files |
|---|------|--------|-------|
| 1 | Crear `team_performance.py` con `fetch_issues` (subprocess `gh`) + parsing | Pending | `docs/scripts/team_performance.py` |
| 2 | Implementar `assign_to_sprints` y `Sprint` dataclass | Pending | `docs/scripts/team_performance.py` |
| 3 | Implementar `compute_aggregate` (throughput + cycle time percentiles) | Pending | `docs/scripts/team_performance.py` |
| 4 | Implementar `project` (bootstrap empírico, reproducible vía `seed`) | Pending | `docs/scripts/team_performance.py` |
| 5 | Implementar `render_text` (tabla Markdown) y `render_json` (estable) | Pending | `docs/scripts/team_performance.py` |
| 6 | `main()` + `argparse` con todos los flags listados en §2 | Pending | `docs/scripts/team_performance.py` |
| 7 | Receta `just team-performance` que invoca el script con defaults del repo | Pending | `justfile` |
| 8 | README breve (uso + ejemplo de salida) | Pending | `docs/scripts/README.md` o sección en `docs/scripts/team_performance.py` docstring |
| 9 | Tests unitarios stdlib `unittest` para funciones puras | Pending | `docs/scripts/test_team_performance.py` |

---

## 4. Code Changes

### 4.1 `docs/scripts/team_performance.py` (nuevo)

**Propósito**: script único, ejecutable como `python3 docs/scripts/team_performance.py [opts]`.

Esqueleto:

```python
"""Team performance metrics & throughput-based projection for fiuba-gestion-tp.

Reads issues from GitHub via `gh` CLI, computes per-sprint throughput at the
team level (no individual breakdown), and produces an empirical bootstrap
projection of remaining-sprint completion probability.

Usage:
    python3 docs/scripts/team_performance.py \\
        --repo tcorzo/fiuba-gestion-tp \\
        --sprint-start 2026-04-21 --sprint-length-days 14 \\
        --target-issues 20 --remaining-sprints 5 \\
        --format both

Outputs JSON to stdout; a Markdown summary to stderr when --format=both.
"""
from __future__ import annotations
import argparse, json, statistics, subprocess, sys
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta, timezone
from random import Random

# ... see §2 for the full design.
```

### 4.2 `docs/scripts/test_team_performance.py` (nuevo)

**Propósito**: cubre las funciones puras (no toca `gh`).

Casos mínimos:

- `assign_to_sprints` con un set sintético de 8 issues distribuidos en 3 ventanas → cada uno cae en su ventana correcta; issues abiertos se cuentan en `wip_at_end` del sprint correspondiente.
- `compute_aggregate` con throughput `[2, 3, 5, 4]` → mean=3.5, median=3.5, max=5.
- `project` con throughput `[3, 3, 3]`, target=15, n_sprints=5, seed=42 → `p_meet_or_exceed_target == 1.0` (siempre 15) y `p50 == 15`.
- `project` con throughput `[0, 0, 0]`, target=1 → `p_meet_or_exceed_target == 0.0`.
- `render_json` produce JSON válido y respeta `schema_version`.

### 4.3 `justfile` — receta

```just
team-performance *ARGS:
    python3 {{ root }}/scripts/team_performance.py --repo {{ github_repo }} {{ ARGS }}
```

(Si no existe la variable `github_repo` en `justfile`, se hardcodea `tcorzo/fiuba-gestion-tp` o se lee desde `.gdsi-sdlc/config.json` con `jq`.)

### 4.4 `docs/scripts/README.md` (nuevo, opcional)

Una página: invocación, flags, ejemplo de salida JSON y de salida Markdown, referencia al issue.

---

## 5. Testing

### Unit Tests (stdlib `unittest`)

- `assign_to_sprints` — 3 sprints sintéticos, asserts sobre conteo y breakdown.
- `compute_aggregate` — verifica mean/median/stdev/percentiles y manejo de `sample_size_sprints == 0` (devuelve `None` en cada métrica, no lanza).
- `project` — determinístico con `seed=42`; tres escenarios: throughput constante, throughput cero, throughput variable.
- `render_json` — `json.loads(render_json(report))` no lanza, contiene `schema_version`.

### Integration Test (manual, no en CI por ahora)

- Ejecutar contra el repo real con `--sprint-start 2026-04-21 --sprint-length-days 14`. Validar que el conteo de sprint 1 + 2 cuadra con un conteo manual de issues con `closedAt` en cada ventana (`gh issue list --state closed --json number,closedAt`).

### No Tests For

- La invocación de `gh` (mockear subprocess es ruido — el comando es estable y la integración manual lo cubre).

---

## 6. Acceptance Criteria

- [ ] `python3 docs/scripts/team_performance.py --help` imprime ayuda con todos los flags de §2.
- [ ] El script ejecutado contra el repo real produce un JSON válido con `schema_version: "1"`.
- [ ] Las métricas de equipo nunca están desagregadas por `assignee` (el campo no aparece en la salida).
- [ ] La proyección es **reproducible**: dos corridas con el mismo `--seed` y el mismo set de issues producen JSON byte-idéntico.
- [ ] La proyección se omite con un mensaje claro cuando `sample_size_sprints < 2`.
- [ ] `python3 -m unittest docs/scripts/test_team_performance.py` pasa con 100% verde.
- [ ] `--format text` produce una tabla Markdown que se puede pegar tal cual en un commit / artifact.
- [ ] La receta `just team-performance` corre el script con la config del repo.

---

## 7. Files Summary

### New Files
| File | Description |
|------|-------------|
| `docs/scripts/team_performance.py` | Script principal — fetch + sprint binning + agregados + bootstrap + render. |
| `docs/scripts/test_team_performance.py` | Unit tests stdlib `unittest` para funciones puras. |
| `docs/scripts/README.md` | (Opcional) Uso y ejemplo de salida. |

### Modified Files
| File | Changes |
|------|---------|
| `justfile` | Nueva receta `team-performance *ARGS`. |

### Out of Scope
- Reescritura de `wbs.typ` / `usm.typ` para remover estimaciones (issue paralelo).
- Definir cadencia de sprint del equipo (decisión del equipo, no del script).
- CI workflow que corra el script en cada PR (puede venir en un follow-up `INF-INFRA-*` si surge la necesidad).
- Análisis individual o por asignado — explícitamente excluido por el principio del issue.
