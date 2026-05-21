# INF-GEN-00003: team-performance — throughput por User Stories vía ledger por sprint

| Field | Value |
|-------|-------|
| **Tag** | INF-GEN-00003 |
| **Title** | team-performance: medir throughput por User Stories completadas vía ledger por sprint |
| **Priority** | P2 |
| **Status** | READY |
| **Created** | 2026-05-20 |
| **Updated** | 2026-05-20 |
| **Author** | Claude Code |
| **Depends On** | — |
| **Decision Doc** | N/A — diseño resuelto en una sesión `/grill-me`; las 8 decisiones están registradas en el cuerpo del issue |
| **Selected Approach** | N/A |

---

## 1. Problem Statement

El CLI `team-performance` cuenta issues de GitHub cerradas como `COMPLETED` para medir throughput. Las issues tienen una dispersión de tamaño demasiado grande — una corrección de una línea y una feature fullstack cuentan ambas como "1" — lo que vuelve la muestra ruidosa y la proyección por bootstrap poco confiable. Se reemplaza la unidad por **User Stories completadas por sprint**, alimentadas desde un **ledger manual por sprint**. La dependencia de `gh` se elimina por completo.

El diseño fue resuelto en una sesión de grilling; las 8 decisiones de diseño están en el cuerpo del issue `INF-GEN-00003`.

---

## 2. Solution Design

El tool deja de hablar con GitHub. Lee `docs/sprints/sprint-NN.md` (un archivo por sprint, frontmatter YAML + cuerpo libre de retro), computa throughput en US/sprint, lead time en sprints y WIP, y emite la misma proyección por bootstrap (inversa + directa) y el reporte Typst.

### 2.1 Formato del ledger (`docs/sprints/sprint-01.md`)

```yaml
---
sprint: 1
phase: development          # el tool sólo cuenta archivos que matchean --phase
status: closed              # closed = contado; in_progress = ignorado
window: 2026-05-07 → 2026-05-13
in_progress_user_stories: [US7]
completed_user_stories: [US1, US2, US14]
---
## Retro
- ...
## Notas por US
- US1: ...
```

El tool lee **sólo el frontmatter**; el cuerpo es valor humano y se ignora.

### 2.2 Modelo de WIP y lead time (Modelo X — sólo arrastre)

- `in_progress_user_stories` = US trabajadas pero **no terminadas** ese sprint. Nunca se solapa con `completed_user_stories` en el mismo archivo.
- WIP-al-cierre del sprint N = `len(in_progress_user_stories)` del archivo N.
- Lead time de una US = `completion_sprint − first_seen_sprint`, donde `first_seen_sprint` es el primer sprint en que la US apareció en `in_progress` o `completed` (0 si arranca y termina en el mismo sprint).

### 2.3 Arquitectura nueva

```
ledger_source.py  →  Sprint[]  →  metrics.py     →  AggregateStats
                                  projection.py  →  Projection
                          →  render/{json,text} →  stdout/stderr
                          →  Typst template (en SKILL.md) → PDF
```

`github_source.py` y `sprints.py` (bucketeo por fecha) desaparecen: el archivo de sprint ya declara su número, su ventana y sus US.

### Key Components

- **`ledger_source.py`** (nuevo) — descubre `sprint-*.md` en `--sprints-dir`, parsea frontmatter YAML, valida y devuelve `tuple[Sprint, ...]` ordenado por `index`, filtrado por `--phase` y `status: closed`.
- **`us_catalog.py`** (nuevo, chico) — parsea los headers `== USnn:` de `backlog-us.typ` y devuelve el set de US-ids válidos, para validar el ledger contra typos.
- **`models.py`** — `Sprint` reformado; `Issue`, `Breakdown`, `ScopeGrowthStats`, `CycleTimePercentiles` eliminados; `LeadTimePercentiles` agregado.
- **`metrics.py`** — throughput en US, `lead_time_sprints`, WIP; sin `created_per_sprint` ni `closed_excluded`.
- **`projection.py`** — `bootstrap_inverse` / `bootstrap_forward` sin `created_throughput`; código de scope-growth borrado.
- **`config.py` / `cli.py`** — nueva superficie de flags; schema v3.
- **Dependencia nueva**: `pyyaml` (parseo de frontmatter; los archivos son YAML y conviene soportar listas en bloque además de inline).

---

## 3. Implementation Tasks

| # | Task | Status | Files |
|---|------|--------|-------|
| 1 | Reformar `models.py`: `Sprint` US-id-based; agregar `LeadTimePercentiles`; borrar `Issue`, `Breakdown`, `ScopeGrowthStats`, `CycleTimePercentiles` | Pending | `models.py` |
| 2 | Nuevo `us_catalog.py`: parsear `== USnn:` de `backlog-us.typ` → set de US-ids | Pending | `us_catalog.py` (nuevo) |
| 3 | Nuevo `ledger_source.py`: descubrir + parsear frontmatter + validar → `tuple[Sprint, ...]` | Pending | `ledger_source.py` (nuevo) |
| 4 | `metrics.py`: throughput en US, `lead_time_sprints`, WIP; quitar `created`/`closed_excluded` | Pending | `metrics.py` |
| 5 | `projection.py`: quitar `created_throughput` y scope-growth; renombrar `target_issues`→`target_user_stories` | Pending | `projection.py` |
| 6 | `config.py`: nuevos flags, quitar `repo`/`gh`/fechas/`scope_growth`/`target_issues` | Pending | `config.py` |
| 7 | `cli.py`: cablear `ledger_source`; quitar imports muertos; `SCHEMA_VERSION = "3"` | Pending | `cli.py` |
| 8 | `render/json_renderer.py`: schema v3 con `_meaning` actualizado a es-AR | Pending | `render/json_renderer.py` |
| 9 | `render/text_renderer.py`: tablas para el schema nuevo | Pending | `render/text_renderer.py` |
| 10 | Borrar `github_source.py`, `sprints.py` y sus tests + fixture `sample_issues.json` | Pending | (deletions) |
| 11 | Reescribir tests; nuevas fixtures `tests/fixtures/sprints/*.md` | Pending | `tests/*` |
| 12 | Backfill: escribir `docs/sprints/sprint-01.md` y `sprint-02.md` (US-lists provistas por el equipo) | Pending | `docs/sprints/*` (nuevos) |
| 13 | Reescribir la plantilla Typst en `SKILL.md` (lead time en sprints; sin columna `Excl.` ni scope-growth) | Pending | `.claude/skills/team-performance/SKILL.md` |
| 14 | Actualizar `README.md` del tool, sección "Canonical inputs" de `CALENDAR.md`, limpiar `[tool.team_performance]` de `pyproject.toml`; agregar `pyyaml` a deps | Pending | `README.md`, `CALENDAR.md`, `pyproject.toml` |

---

## 4. Code Changes

### 4.1 `docs/scripts/team_performance/models.py`

```python
@dataclass(frozen=True, slots=True)
class Sprint:
    index: int
    phase: str
    status: str               # "closed" | "in_progress"
    window_start: date
    window_end: date
    completed: tuple[str, ...]    # US ids, p.ej. ("US1", "US2")
    in_progress: tuple[str, ...]  # US ids — WIP de arrastre

@dataclass(frozen=True, slots=True)
class LeadTimePercentiles:        # reemplaza CycleTimePercentiles
    p50: float
    p75: float
    p90: float
```

`AggregateStats` pasa a `throughput | None`, `lead_time_sprints: LeadTimePercentiles | None`, `sample_size_sprints`. Se borran `created_per_sprint` y `closed_excluded_total`. `Projection.target_issues` → `target_user_stories`; se borran `scope_growth_enabled` y `scope_growth`. `Issue` y `Breakdown` se eliminan.

### 4.2 `docs/scripts/team_performance/ledger_source.py` (nuevo)

```python
def load_sprints(sprints_dir: Path, *, phase: str, us_catalog: frozenset[str] | None) -> tuple[Sprint, ...]:
    """Lee docs/sprints/sprint-*.md, parsea frontmatter, valida, devuelve sprints closed del phase pedido."""
    # 1. glob sprint-*.md; split en '---' para aislar el frontmatter; yaml.safe_load
    # 2. construir Sprint por archivo (window: split en '→'/'->' → 2 dates)
    # 3. filtrar phase == phase y status == "closed"; ordenar por index
    # 4. validar (DataSourceError ante cualquier violación → exit 3):
    #    - índices contiguos desde 1, sin duplicados
    #    - una US no aparece en 'completed' de dos archivos
    #    - una US no está en ambas listas del mismo archivo
    #    - una US no está en 'in_progress' de un sprint posterior a su completado
    #    - si us_catalog: toda US-id existe en el catálogo (guarda typos)
    #    - todos los sprints comparten el mismo phase
```

### 4.3 `docs/scripts/team_performance/metrics.py`

```python
def throughput_stats(sprints) -> ThroughputStats | None:
    return _stats_from_counts([len(s.completed) for s in sprints])

def lead_time_sprints(sprints) -> LeadTimePercentiles | None:
    first_seen: dict[str, int] = {}
    for s in sprints:                       # sprints ordenados por index
        for us in (*s.in_progress, *s.completed):
            first_seen.setdefault(us, s.index)
    leads = [s.index - first_seen[us] for s in sprints for us in s.completed]
    # percentiles p50/p75/p90 sobre `leads` (None si vacío)

def wip_at_end(sprint) -> int:
    return len(sprint.in_progress)
```

### 4.4 `docs/scripts/team_performance/projection.py`

Quitar el parámetro `created_throughput` de `bootstrap_inverse` y `bootstrap_forward` y el bloque split-Monte-Carlo. Renombrar el kwarg `target_issues` → `target_user_stories`. La lógica de muestreo y los modelos `SprintsToTarget` / `ForwardOutcome` no cambian.

### 4.5 `docs/scripts/team_performance/cli.py` + `config.py`

`SCHEMA_VERSION = "3"`. Flags finales:

- **Agregar**: `--sprints-dir` (default `docs/sprints/`), `--phase` (default `development`), `--backlog-us` (default `docs/artifacts/backlog-us.typ`), `--target-user-stories`.
- **Conservar**: `--remaining-sprints`, `--bootstrap-samples`, `--seed`, `--format`, `--no-color`, `-v/-q`, `--version`.
- **Quitar**: `--repo`, `--gh-bin`, `--sprint-start`, `--sprint-length-days`, `--as-of`, `--scope-growth`, `--target-issues`.

`_build_report` deja de llamar a `fetch_issues`/`assign_to_sprints` y llama a `load_sprints`. `AppConfig` pierde `repo/gh_bin/sprint_start/sprint_length_days/as_of/scope_growth/target_issues` y gana `sprints_dir/phase/backlog_us/target_user_stories`. La regla "`--remaining-sprints` requiere target" se mantiene (contra `--target-user-stories`).

### 4.6 Schema JSON v3 (`render/json_renderer.py`)

Por sprint: `index`, `phase`, `window_start`, `window_end`, `completed_count`, `completed_user_stories`, `wip_at_end`, `in_progress_user_stories`. `aggregate`: `throughput` (US/sprint), `lead_time_sprints` (p50/p75/p90), `sample_size_sprints`. `projection`: `target_user_stories`, `method: "bootstrap_throughput"`, `sprints_to_target`, `forward`. Se eliminan `closed_excluded*`, `created*`, `scope_growth*`. Se conservan los campos `_meaning` companion (es-AR), actualizados de "issues" a "User Stories".

---

## 5. Testing

### Unit Tests

- `test_ledger_source.py` (nuevo) — parseo de frontmatter; cada regla de validación dispara `DataSourceError`; filtrado por `phase` y `status`; orden por índice.
- `test_us_catalog.py` (nuevo) — extrae US-ids de un `backlog-us.typ` de muestra.
- `test_metrics.py` — throughput en US; `lead_time_sprints` (incluido el caso lead=0 mismo-sprint y el de arrastre); WIP.
- `test_projection.py` — quitar los casos de scope-growth; el bootstrap sigue siendo determinista con seed.
- `test_config.py` — flags nuevos; `--remaining-sprints` sin `--target-user-stories` → exit 2.
- `test_renderers.py` — schema v3 byte-idéntico con `include_generated_at=False`.
- Borrar `test_github_source.py` y `test_sprints.py`.

### Integration Tests

- `test_cli.py` — end-to-end contra `tests/fixtures/sprints/` (reemplaza `sample_issues.json`): stats-only; con proyección inversa; con proyección directa; muestra insuficiente (<2 closed) → exit 4; ledger inválido → exit 3.

### Manual

- `just team-performance --sprints-dir docs/sprints --target-user-stories N --remaining-sprints M --format both` y compilar el reporte Typst con `typst compile --root docs`.

---

## 6. Acceptance Criteria

- [ ] Formato del ledger `docs/sprints/sprint-NN.md` definido y documentado.
- [ ] `ledger_source.py` parsea los archivos de sprint y devuelve `tuple[Sprint, ...]`.
- [ ] `github_source.py`, el modelo `Issue` y `sprints.py` eliminados; sin dependencia de `gh`.
- [ ] Modelo `Sprint` reformado a `index / phase / status / window_start / window_end / completed / in_progress`.
- [ ] `metrics.py` computa throughput en US/sprint, lead time en sprints y WIP-al-cierre.
- [ ] `projection.py` sin scope-growth ni `created_throughput`; bootstrap inverso + directo intactos.
- [ ] CLI: `--sprints-dir`, `--phase`, `--backlog-us`, `--target-user-stories` agregados; flags de GitHub/fechas/scope-growth eliminados.
- [ ] Schema JSON v3 con claves renombradas; renderers JSON + texto actualizados.
- [ ] Plantilla Typst reescrita (lead time en sprints, sin columna `Excl.`, sin scope-growth); compila con `--root docs`.
- [ ] Reglas de validación implementadas con exit codes correctos (2 usage, 3 data/validación, 4 muestra insuficiente).
- [ ] Backfill: `sprint-01.md` (y `sprint-02.md`) escritos.
- [ ] `SKILL.md`, `README.md` del tool y "Canonical inputs" de `CALENDAR.md` actualizados; `[tool.team_performance]` limpiado; `pyyaml` agregado a deps.
- [ ] Identifiers en inglés; copy del reporte y del CLI en es-AR.
- [ ] `just team-performance-test` y `just team-performance-lint` pasan.

---

## 7. Files Summary

### New Files

| File | Description |
|------|-------------|
| `docs/scripts/team_performance/ledger_source.py` | Descubre, parsea y valida los archivos de sprint |
| `docs/scripts/team_performance/us_catalog.py` | Extrae el set de US-ids válidos de `backlog-us.typ` |
| `docs/scripts/team_performance/tests/test_ledger_source.py` | Tests de parseo + validación del ledger |
| `docs/scripts/team_performance/tests/test_us_catalog.py` | Tests del parser del catálogo de US |
| `docs/scripts/team_performance/tests/fixtures/sprints/*.md` | Archivos de sprint de muestra para los tests |
| `docs/sprints/sprint-01.md`, `docs/sprints/sprint-02.md` | Backfill del ledger (US-lists provistas por el equipo) |

### Modified Files

| File | Changes |
|------|---------|
| `docs/scripts/team_performance/models.py` | `Sprint` reformado; `LeadTimePercentiles` nuevo; `Issue`/`Breakdown`/`ScopeGrowthStats`/`CycleTimePercentiles` borrados |
| `docs/scripts/team_performance/metrics.py` | Throughput en US, lead time en sprints, WIP |
| `docs/scripts/team_performance/projection.py` | Sin scope-growth ni `created_throughput` |
| `docs/scripts/team_performance/config.py` | Nueva superficie de configuración |
| `docs/scripts/team_performance/cli.py` | Cablea `ledger_source`; `SCHEMA_VERSION = "3"` |
| `docs/scripts/team_performance/render/json_renderer.py` | Schema v3 |
| `docs/scripts/team_performance/render/text_renderer.py` | Tablas para el schema nuevo |
| `docs/scripts/team_performance/errors.py` | Docstring de `DataSourceError` (ya no menciona `gh`) |
| `docs/scripts/team_performance/README.md` | Reescribir: fuente de datos, schema v3, ejemplos |
| `docs/scripts/team_performance/tests/{test_cli,test_config,test_metrics,test_projection,test_renderers}.py` | Adaptados al modelo de US |
| `.claude/skills/team-performance/SKILL.md` | Plantilla Typst + inputs + caveats reescritos |
| `CALENDAR.md` | Sección "Canonical inputs for team-performance" |
| `pyproject.toml` | Limpiar `[tool.team_performance]`; agregar `pyyaml` |

### Deleted Files

| File | Reason |
|------|--------|
| `docs/scripts/team_performance/github_source.py` | El ledger es la única fuente |
| `docs/scripts/team_performance/sprints.py` | El archivo de sprint ya declara su número/ventana/US |
| `docs/scripts/team_performance/tests/test_github_source.py` | Módulo eliminado |
| `docs/scripts/team_performance/tests/test_sprints.py` | Módulo eliminado |
| `docs/scripts/team_performance/tests/fixtures/sample_issues.json` | Reemplazado por fixtures de sprint |
