# INF-GEN-00001: Sin estimaciones — CLI tool de proyección por throughput

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
| **Selected Approach** | Paquete Python tipado + pytest + rich + entrypoint instalable. |

---

## 1. Problem Statement

El equipo decidió **no estimar** issues individuales y, en su lugar, medir **throughput real** (issues cerrados por sprint) durante los sprints 1–2 y proyectar al revés: dado N sprints restantes, ¿qué probabilidad hay de cerrar X issues? Esto requiere una herramienta determinística y reproducible que:

- Lea las issues reales del repo (fuente de verdad: GitHub Issues — único origen con `closed_at` confiable).
- Calcule throughput por sprint y estadísticas descriptivas **a nivel equipo** (sin desagregar por persona).
- Genere una proyección inversa basada en bootstrap del throughput histórico (no Monte Carlo clásico sobre estimaciones).
- Emita salida tanto **estructurada (JSON)** como **legible para humanos** (tabla con `rich`), con la misma estructura semántica.

Este plan cubre **únicamente** la herramienta `team_performance`. La definición de cadencia de sprint, las dos primeras corridas de medición y el rework de artifacts (estimaciones-out) son trabajos paralelos, fuera del alcance de este issue de implementación.

---

## 2. Solution Design

### 2.1 Estándares industriales adoptados

| Aspecto | Elección | Por qué |
|---------|----------|---------|
| **Estructura** | Paquete Python (`team_performance/`) en `docs/scripts/`, con `__main__.py` y entrypoint instalable. | Single file no escala con tests + tipos; un paquete permite `python -m team_performance`, imports limpios y mypy por módulo. |
| **Build backend** | `hatchling` declarado en `pyproject.toml`. | Estándar moderno de empaquetado Python (PEP 517/660); `uv` lo soporta nativamente. |
| **Entrypoint** | `[project.scripts] team-performance = "team_performance.cli:main"`. | `uv run team-performance …` y `pip install -e .` lo dejan en el `PATH`. |
| **CLI** | `argparse` (stdlib) con grupos de flags + `--help` curado. | Cero dependencias extra; suficiente para una sola subherramienta. Si en el futuro aparecen subcomandos, se migra a `argparse` subparsers (no a `click`/`typer`). |
| **Tipado** | Python 3.14 + sintaxis moderna (`list[X]`, `X \| None`, `Self`, dataclasses con `slots=True, frozen=True`). | Repo ya pinea `>=3.14` en `pyproject.toml`. No usar `typing.List`/`Optional`. No usar `from __future__ import annotations` (innecesario). |
| **Type checker** | `mypy --strict` (config en `pyproject.toml`). | Estándar de facto. `pyright` quedaría como alternativa si surge fricción. |
| **Linter / formatter** | `ruff` (formato + lint). | Estándar de facto 2025; reemplaza `black + isort + flake8`. Config en `pyproject.toml`. |
| **Tests** | `pytest` + `pytest-cov`. Tests en `team_performance/tests/`. | Estándar de facto. `unittest` quedaría OK pero pytest da mejores fixtures, parametrización y output. |
| **Salida humana** | `rich` para tablas y formato terminal. | Estándar de facto para CLIs Python modernos. Degrada bien en pipes (auto-detecta TTY). |
| **Logging** | `logging` (stdlib) con `RichHandler`; flags `--verbose` / `--quiet`. | Logs van a stderr; data va a stdout. Convención POSIX. |
| **Exit codes** | `0` ok, `2` error de uso, `3` error de datos/red, `4` muestra insuficiente para proyección. | Convención POSIX (`2` = misuse, `>2` = errores específicos del programa). Documentados en `--help`. |
| **Config** | CLI > env vars (`TEAM_PERF_*`) > `[tool.team_performance]` en `pyproject.toml` > defaults. | Layering estándar (12-factor adaptado para CLI). |
| **Determinismo** | `--seed` explícito (default `42`). Salida JSON byte-idéntica para misma data + seed. | Reproducibilidad. |
| **Versionado de salida** | `schema_version: "1"` en el JSON. | Permite evolucionar el schema sin romper consumidores. |
| **Errores** | Excepciones tipadas (`TeamPerfError` raíz; `DataSourceError`, `InsufficientDataError`, `ConfigError`). `main()` las atrapa y mapea a exit code. | Separa "fallo de programa" de "fallo de invocación". |

### 2.2 Estructura del paquete

```
docs/scripts/team_performance/
├── README.md                       # Uso, ejemplos, esquema JSON, exit codes
├── pyproject.toml                  # (NO — la config va al pyproject.toml raíz)
├── __init__.py                     # __version__ = "0.1.0", re-exports públicos
├── __main__.py                     # `python -m team_performance` → cli.main()
├── cli.py                          # argparse + main() + exit code mapping
├── config.py                       # AppConfig dataclass + load_config() (CLI/env/pyproject layering)
├── errors.py                       # Excepciones tipadas
├── logging_setup.py                # configure_logging(verbosity) con RichHandler
├── models.py                       # Issue, Sprint, AggregateStats, Projection, Report (dataclasses, frozen)
├── github_source.py                # fetch_issues() — wrapper sobre `gh` CLI; parseo + validación
├── sprints.py                      # assign_to_sprints(), sprint_windows()
├── metrics.py                      # compute_aggregate(), cycle_time_percentiles()
├── projection.py                   # bootstrap_projection() — empírico, semilla fija
├── render/
│   ├── __init__.py
│   ├── json_renderer.py            # render_json(report) -> str
│   └── text_renderer.py            # render_text(report, console) -> None  (rich.Table)
└── tests/
    ├── __init__.py
    ├── conftest.py                 # Fixtures: sample_issues, fixed_clock
    ├── fixtures/
    │   └── sample_issues.json      # Output ejemplificado de `gh issue list --json …`
    ├── test_cli.py                 # CLI smoke + exit codes (subprocess + capsys)
    ├── test_config.py              # Layering CLI/env/pyproject
    ├── test_github_source.py       # Parser sobre fixture JSON; mock de subprocess.run
    ├── test_sprints.py
    ├── test_metrics.py
    ├── test_projection.py
    └── test_renderers.py
```

> **Nota**: El paquete vive bajo `docs/scripts/` para mantener el espíritu de "scripts académicos" del repo, pero se declara en el `pyproject.toml` raíz como un paquete real (build backend hatchling), no como un script suelto. Esto le da `python -m`, entrypoint y tests por igual.

### 2.3 `pyproject.toml` raíz — cambios

```toml
[project]
name = "fiuba-gestion-tp"
version = "0.1.0"
requires-python = ">=3.14"
dependencies = [
  "python-dotenv>=1.2.2",
  "pandas>=3.0.1",
  "openpyxl>=3.1.5",
  "rich>=13.7",                    # NEW
]

[project.optional-dependencies]
dev = [
  "pytest>=8.3",
  "pytest-cov>=5.0",
  "mypy>=1.13",
  "ruff>=0.7",
]

[project.scripts]
team-performance = "team_performance.cli:main"

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.hatch.build.targets.wheel]
packages = ["docs/scripts/team_performance"]

[tool.pytest.ini_options]
testpaths = ["docs/scripts/team_performance/tests"]
addopts = "-ra --strict-markers --strict-config"
pythonpath = ["docs/scripts"]

[tool.mypy]
strict = true
python_version = "3.14"
files = ["docs/scripts/team_performance"]
warn_unused_configs = true
warn_redundant_casts = true
warn_unused_ignores = true
disallow_untyped_defs = true
no_implicit_optional = true

[tool.ruff]
line-length = 100
target-version = "py314"

[tool.ruff.lint]
select = ["E", "F", "I", "B", "UP", "N", "SIM", "RUF"]

[tool.team_performance]
# Defaults reales del proyecto. Pueden overridearse por CLI / env.
repo = "tcorzo/fiuba-gestion-tp"
sprint_length_days = 14
# sprint_start = "2026-04-21"     # descomentar cuando el equipo lo defina
```

### 2.4 Modelo de datos (dataclasses tipadas)

```python
# models.py
from dataclasses import dataclass, field
from datetime import datetime

@dataclass(frozen=True, slots=True)
class Issue:
    number: int
    title: str
    state: str                      # "open" | "closed"
    created_at: datetime            # tz-aware UTC
    closed_at: datetime | None
    labels: tuple[str, ...]

@dataclass(frozen=True, slots=True)
class Sprint:
    index: int                      # 1-based
    start: datetime
    end: datetime                   # exclusive
    closed: tuple[Issue, ...]
    created: tuple[Issue, ...]
    wip_at_end: int

@dataclass(frozen=True, slots=True)
class Breakdown:
    by_prefix: dict[str, int]
    by_scope: dict[str, int]
    by_priority: dict[str, int]

@dataclass(frozen=True, slots=True)
class ThroughputStats:
    mean: float
    median: float
    stdev: float | None             # None si n < 2
    min: int
    max: int

@dataclass(frozen=True, slots=True)
class CycleTimePercentiles:
    p50: float
    p75: float
    p90: float

@dataclass(frozen=True, slots=True)
class AggregateStats:
    throughput: ThroughputStats | None
    cycle_time_days: CycleTimePercentiles | None
    sample_size_sprints: int

@dataclass(frozen=True, slots=True)
class Projection:
    target_issues: int
    remaining_sprints: int
    p_meet_or_exceed_target: float
    total_projected_p10: int
    total_projected_p50: int
    total_projected_p90: int
    method: str = "bootstrap_throughput"
    bootstrap_samples: int = 10_000

@dataclass(frozen=True, slots=True)
class Report:
    schema_version: str
    generated_at: datetime
    config_snapshot: dict[str, object]
    sprints: tuple[Sprint, ...]
    aggregate: AggregateStats
    projection: Projection | None   # None si insufficient sample o no se pidió
```

### 2.5 Capas y flujos

```
cli.main()
  ├── load_config(argv, env, pyproject)        # config.py
  ├── configure_logging(verbosity)             # logging_setup.py
  ├── github_source.fetch_issues(repo, limit)  # subprocess.run(["gh", ...])
  ├── sprints.assign_to_sprints(...)
  ├── metrics.compute_aggregate(...)
  ├── projection.bootstrap_projection(...) [opcional]
  ├── render_json(report)  ─→ stdout          # default
  └── render_text(report)  ─→ stderr (rich)   # cuando --format=text|both
```

### 2.6 CLI — superficie completa

```
team-performance [OPTIONS]

Data source:
  --repo OWNER/REPO            (default: pyproject [tool.team_performance].repo)
  --gh-bin PATH                (default: "gh"; útil si no está en PATH)

Sprint definition:
  --sprint-start YYYY-MM-DD    Fecha de inicio del Sprint 1 (required if no default)
  --sprint-length-days N       (default: 14)
  --as-of YYYY-MM-DD           Corte de "sprints completos" (default: hoy UTC)

Projection (opcional, omite la sección si no se pasa --target-issues):
  --target-issues X            Issues a alcanzar
  --remaining-sprints N        Horizonte de sprints futuros
  --bootstrap-samples N        (default: 10000)
  --seed N                     (default: 42)

Output:
  --format {json,text,both}    (default: json)
  --no-color                   Desactiva color en salida humana (también respeta NO_COLOR)
  -v / --verbose               Logs DEBUG a stderr
  -q / --quiet                 Solo errores
  --version                    Imprime versión y exit 0

Exit codes:
  0   ok
  2   uso inválido (argparse)
  3   error de fuente de datos (gh no instalado, repo inválido, JSON malformado)
  4   muestra insuficiente para proyección (< 2 sprints completos) Y --target-issues fue pedido
```

### 2.7 Salida humana (rich)

Tres tablas en orden:

1. **Sprints completos** — columnas: `#`, `Window`, `Closed`, `Created`, `WIP@end`, `Top scope`, `Top prefix`.
2. **Aggregate** — `Throughput (mean / median / stdev / min / max)` + `Cycle time (p50 / p75 / p90)` + `Sample size`.
3. **Projection** (si aplica) — `Target`, `Horizon`, `P(≥ target)`, `Projected total p10/p50/p90`, `Method`.

Detección de TTY automática (rich): en pipe sale como ASCII plano sin color. Respeta `NO_COLOR`.

### 2.8 Determinismo y reproducibilidad

- Bootstrap usa `random.Random(seed)` (instancia local, **no** el RNG global).
- El JSON serializa keys en orden estable (dataclasses → dict ordenado por definición de campo, dicts internos con `sort_keys=True`).
- `generated_at` se omite del payload usado para asserts byte-idénticos en tests (un fixture `fixed_clock` lo congela).

### 2.9 Errores y validación

- `gh` no instalado → `DataSourceError("gh CLI not found in PATH")` → exit 3.
- `gh auth status` falla → mensaje accionable; exit 3.
- `--sprint-start` futuro vs `--as-of` → `ConfigError`; exit 2.
- `--target-issues` sin `--remaining-sprints` (o viceversa) → `ConfigError`; exit 2.
- `--target-issues` pedido pero `< 2` sprints completos → `InsufficientDataError`; exit 4. Las métricas observadas se imprimen igual antes de salir.

---

## 3. Implementation Tasks

| # | Task | Status | Files |
|---|------|--------|-------|
| 1 | Actualizar `pyproject.toml` raíz: build-system hatchling, dev-deps, scripts entry, mypy/ruff/pytest config | Pending | `pyproject.toml` |
| 2 | Esqueleto del paquete + `__init__.py` + `__main__.py` | Pending | `docs/scripts/team_performance/{__init__,__main__}.py` |
| 3 | `models.py` — dataclasses tipadas (frozen, slots) | Pending | `docs/scripts/team_performance/models.py` |
| 4 | `errors.py` — jerarquía de excepciones | Pending | `docs/scripts/team_performance/errors.py` |
| 5 | `config.py` — AppConfig + layering CLI/env/pyproject | Pending | `docs/scripts/team_performance/config.py` |
| 6 | `logging_setup.py` — RichHandler + niveles | Pending | `docs/scripts/team_performance/logging_setup.py` |
| 7 | `github_source.py` — wrapper `gh` con timeout + parseo | Pending | `docs/scripts/team_performance/github_source.py` |
| 8 | `sprints.py` — `assign_to_sprints()` puro | Pending | `docs/scripts/team_performance/sprints.py` |
| 9 | `metrics.py` — agregados + percentiles | Pending | `docs/scripts/team_performance/metrics.py` |
| 10 | `projection.py` — bootstrap reproducible | Pending | `docs/scripts/team_performance/projection.py` |
| 11 | `render/json_renderer.py` — JSON estable con `schema_version` | Pending | `docs/scripts/team_performance/render/json_renderer.py` |
| 12 | `render/text_renderer.py` — tablas `rich` | Pending | `docs/scripts/team_performance/render/text_renderer.py` |
| 13 | `cli.py` — argparse, wiring, error→exit-code mapping | Pending | `docs/scripts/team_performance/cli.py` |
| 14 | Suite de tests pytest (cobertura ≥ 90 % en módulos puros) | Pending | `docs/scripts/team_performance/tests/**` |
| 15 | Fixture `tests/fixtures/sample_issues.json` (output realista de `gh`) | Pending | `docs/scripts/team_performance/tests/fixtures/sample_issues.json` |
| 16 | `README.md` del paquete | Pending | `docs/scripts/team_performance/README.md` |
| 17 | Recetas en `justfile`: `team-performance`, `team-performance-test`, `team-performance-lint` | Pending | `justfile` |
| 18 | Pasada final `mypy --strict` + `ruff check` + `pytest` verde | Pending | — |

---

## 4. Code Changes

### 4.1 `pyproject.toml` (modificado)

Ver §2.3 — patch completo. Cambios clave: build-system hatchling, dep `rich`, optional-dep `dev`, `[project.scripts]`, configs `mypy`/`ruff`/`pytest`, sección `[tool.team_performance]`.

### 4.2 `docs/scripts/team_performance/__init__.py` (nuevo)

```python
"""Team performance metrics & throughput-based projection."""
__version__ = "0.1.0"
```

### 4.3 `docs/scripts/team_performance/__main__.py` (nuevo)

```python
import sys
from team_performance.cli import main
sys.exit(main())
```

### 4.4 `docs/scripts/team_performance/cli.py` (nuevo)

Esqueleto:

```python
import argparse, logging, sys
from team_performance import __version__
from team_performance.config import load_config
from team_performance.errors import TeamPerfError, ConfigError, DataSourceError, InsufficientDataError
from team_performance.logging_setup import configure_logging
# ...

EXIT_OK = 0
EXIT_USAGE = 2
EXIT_DATA = 3
EXIT_INSUFFICIENT_SAMPLE = 4

def build_parser() -> argparse.ArgumentParser: ...
def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        cfg = load_config(args)
        configure_logging(cfg.verbosity)
        # fetch → bin → aggregate → project → render
        return EXIT_OK
    except ConfigError as e:
        parser.error(str(e))     # exits 2
    except DataSourceError as e:
        logging.error("data source: %s", e); return EXIT_DATA
    except InsufficientDataError as e:
        logging.warning("insufficient sample: %s", e); return EXIT_INSUFFICIENT_SAMPLE
    except TeamPerfError as e:
        logging.error("%s", e); return EXIT_DATA
```

### 4.5 `docs/scripts/team_performance/github_source.py` (nuevo)

`subprocess.run` con timeout, captura de stderr, parseo JSON con validación campo a campo, conversión a `Issue` dataclass. **No** mockeable a través de monkeypatching del módulo: expone `fetch_issues(repo, limit, *, gh_bin="gh", runner=subprocess.run)` para que los tests inyecten un fake runner.

### 4.6 `docs/scripts/team_performance/projection.py` (nuevo)

```python
from random import Random
from team_performance.models import Projection

def bootstrap_projection(
    throughput: list[int],
    *,
    target_issues: int,
    remaining_sprints: int,
    samples: int = 10_000,
    seed: int = 42,
) -> Projection:
    if len(throughput) < 2:
        raise InsufficientDataError(...)
    rng = Random(seed)
    totals = [
        sum(rng.choice(throughput) for _ in range(remaining_sprints))
        for _ in range(samples)
    ]
    totals.sort()
    p_hit = sum(1 for t in totals if t >= target_issues) / samples
    return Projection(
        target_issues=target_issues,
        remaining_sprints=remaining_sprints,
        p_meet_or_exceed_target=p_hit,
        total_projected_p10=totals[int(0.10 * samples)],
        total_projected_p50=totals[int(0.50 * samples)],
        total_projected_p90=totals[int(0.90 * samples)],
        bootstrap_samples=samples,
    )
```

### 4.7 `docs/scripts/team_performance/render/text_renderer.py` (nuevo)

Tres tablas con `rich.table.Table`. Console se inyecta para tests (`render_text(report, console=Console(file=io.StringIO(), force_terminal=False))`).

### 4.8 `docs/scripts/team_performance/tests/conftest.py` (nuevo)

Fixtures:
- `sample_issues_json` — lee `fixtures/sample_issues.json`.
- `frozen_now` — `datetime(2026, 5, 3, 12, 0, tzinfo=UTC)`.
- `fake_gh_runner` — devuelve un `subprocess.CompletedProcess` con el JSON del fixture.

### 4.9 `docs/scripts/team_performance/README.md` (nuevo)

Estructura:

```markdown
# team_performance

Throughput-based team performance metrics and bootstrap projection
for the fiuba-gestion-tp repo.

## Install (dev)
    uv sync --all-extras

## Run
    uv run team-performance --sprint-start 2026-04-21 --target-issues 20 --remaining-sprints 5
    # or
    python -m team_performance --format text

## Output formats
- `json` (default) — stable, versioned schema; stdout
- `text` — rich tables; stderr
- `both` — text on stderr, json on stdout (script-friendly)

## JSON schema
(versioned via `schema_version`; documented field-by-field)

## Exit codes
0 ok / 2 usage / 3 data source / 4 insufficient sample

## Configuration layering
CLI > env (TEAM_PERF_*) > pyproject.toml [tool.team_performance] > defaults

## Development
- `just team-performance-test`  (pytest --cov)
- `just team-performance-lint`  (ruff + mypy)
```

### 4.10 `justfile` (modificado)

```just
team-performance *ARGS:
    uv run team-performance {{ ARGS }}

team-performance-test:
    uv run pytest docs/scripts/team_performance --cov=team_performance --cov-report=term-missing

team-performance-lint:
    uv run ruff check docs/scripts/team_performance
    uv run ruff format --check docs/scripts/team_performance
    uv run mypy docs/scripts/team_performance
```

---

## 5. Testing

### Unit tests (pytest)

Por módulo, con cobertura objetivo ≥ 90 % en `sprints`, `metrics`, `projection`, `renderers`, `config`, `github_source` (parseo).

- **`test_sprints.py`**: 3 sprints sintéticos con 8 issues; asserts sobre `closed`, `created`, `wip_at_end`. Casos: issues exactamente en el borde de la ventana (inclusivo en `start`, exclusivo en `end`).
- **`test_metrics.py`**: throughput `[2,3,5,4]` → mean=3.5, median=3.5, max=5; n=1 → `stdev is None`; n=0 → `AggregateStats` con todos los campos en `None` y `sample_size_sprints=0`.
- **`test_projection.py`**:
  - throughput `[3,3,3]`, target=15, n=5, seed=42 → `p_meet_or_exceed_target == 1.0`, `p50 == 15`.
  - throughput `[0,0,0]`, target=1 → `p == 0.0`.
  - throughput `[1,5]`, seed=42 vs seed=42 → mismo resultado byte-idéntico.
  - throughput `[1,5]`, seed=1 vs seed=2 → resultados distintos (smoke test del seeding).
  - throughput `[3]` → lanza `InsufficientDataError`.
- **`test_renderers.py`**:
  - `render_json` produce JSON parseable; `schema_version == "1"`; orden de keys estable entre invocaciones.
  - `render_text` con `Console(file=io.StringIO(), force_terminal=False)` produce output sin códigos ANSI; contiene los headers esperados.
- **`test_config.py`**: layering — CLI gana sobre env, env gana sobre pyproject, pyproject gana sobre defaults; valores inválidos → `ConfigError`.
- **`test_github_source.py`**: con `fake_gh_runner` retornando el fixture, `fetch_issues` parsea correctamente N issues; runner que devuelve `returncode=1` → `DataSourceError`; runner que devuelve JSON malformado → `DataSourceError`.
- **`test_cli.py`**:
  - `main(["--help"])` exit 0 (capsys).
  - `main(["--version"])` imprime versión y exit 0.
  - `main(["--target-issues", "5"])` sin `--remaining-sprints` → exit 2.
  - Run end-to-end con `fake_gh_runner` inyectado → exit 0, JSON en stdout válido.

### Quality gates (CI-ready, manual por ahora)

```sh
just team-performance-lint    # ruff + mypy strict, cero warnings
just team-performance-test    # pytest, cobertura ≥ 90 %
```

### Integration test (manual)

Ejecutar `uv run team-performance --sprint-start <fecha real> --format both` contra el repo real; comparar el conteo del Sprint 1/2 con `gh issue list --state closed --json number,closedAt,title --jq '...'` a mano.

---

## 6. Acceptance Criteria

- [ ] `uv run team-performance --help` imprime ayuda con todos los flags y exit codes documentados.
- [ ] `uv run team-performance --version` imprime `0.1.0` y exit 0.
- [ ] Ejecutado contra el repo real, produce JSON válido con `schema_version: "1"` en stdout.
- [ ] `--format text` produce tablas legibles (`rich`), sin ANSI cuando no hay TTY o hay `NO_COLOR`.
- [ ] `--format both` envía texto a stderr y JSON a stdout (redirigible independientemente).
- [ ] Las métricas nunca aparecen desagregadas por `assignee`.
- [ ] La proyección es **byte-idéntica** entre dos corridas con mismo `--seed` y misma data (excluyendo `generated_at`).
- [ ] Insufficient sample → exit code 4 con mensaje accionable; las métricas observadas se imprimen igual.
- [ ] `just team-performance-test` pasa con cobertura ≥ 90 % en módulos puros.
- [ ] `just team-performance-lint` pasa: `ruff check` + `ruff format --check` + `mypy --strict` cero errores.
- [ ] El paquete es instalable: `uv sync --all-extras` provisiona el entrypoint `team-performance` en el venv.
- [ ] `README.md` del paquete documenta uso, esquema JSON, exit codes y layering de configuración.

---

## 7. Files Summary

### New Files
| File | Description |
|------|-------------|
| `docs/scripts/team_performance/__init__.py` | `__version__` + re-exports públicos. |
| `docs/scripts/team_performance/__main__.py` | `python -m team_performance` entry. |
| `docs/scripts/team_performance/cli.py` | argparse + main() + error→exit mapping. |
| `docs/scripts/team_performance/config.py` | `AppConfig` + layering CLI/env/pyproject. |
| `docs/scripts/team_performance/errors.py` | Excepciones tipadas. |
| `docs/scripts/team_performance/logging_setup.py` | `configure_logging(verbosity)` con `RichHandler`. |
| `docs/scripts/team_performance/models.py` | Dataclasses tipadas (frozen, slots). |
| `docs/scripts/team_performance/github_source.py` | Wrapper `gh` CLI + parseo + validación. |
| `docs/scripts/team_performance/sprints.py` | Asignación de issues a ventanas de sprint. |
| `docs/scripts/team_performance/metrics.py` | Throughput + cycle-time percentiles. |
| `docs/scripts/team_performance/projection.py` | Bootstrap empírico, reproducible. |
| `docs/scripts/team_performance/render/__init__.py` | — |
| `docs/scripts/team_performance/render/json_renderer.py` | JSON estable con `schema_version`. |
| `docs/scripts/team_performance/render/text_renderer.py` | Tablas `rich`. |
| `docs/scripts/team_performance/tests/__init__.py` | — |
| `docs/scripts/team_performance/tests/conftest.py` | Fixtures: sample_issues, fake_gh_runner, frozen_now. |
| `docs/scripts/team_performance/tests/fixtures/sample_issues.json` | Output realista de `gh issue list --json …`. |
| `docs/scripts/team_performance/tests/test_cli.py` | Smoke + exit codes. |
| `docs/scripts/team_performance/tests/test_config.py` | Layering. |
| `docs/scripts/team_performance/tests/test_github_source.py` | Parser sobre fixture. |
| `docs/scripts/team_performance/tests/test_sprints.py` | — |
| `docs/scripts/team_performance/tests/test_metrics.py` | — |
| `docs/scripts/team_performance/tests/test_projection.py` | — |
| `docs/scripts/team_performance/tests/test_renderers.py` | — |
| `docs/scripts/team_performance/README.md` | Uso + JSON schema + exit codes + dev workflow. |

### Modified Files
| File | Changes |
|------|---------|
| `pyproject.toml` | Build-system hatchling, dep `rich`, optional-dep `dev` (pytest, mypy, ruff, pytest-cov), `[project.scripts]`, `[tool.{mypy,ruff,pytest,team_performance}]`. |
| `justfile` | Recetas `team-performance`, `team-performance-test`, `team-performance-lint`. |

### Out of Scope
- Reescritura de `wbs.typ` / `usm.typ` para remover estimaciones (issue paralelo).
- Definir cadencia de sprint del equipo (decisión del equipo, no del tool).
- CI workflow que corra lint+test del tool en cada PR (follow-up `INF-INFRA-*`).
- Análisis individual o por asignado — explícitamente excluido.
- Sub-comandos (`team-performance projection …` / `team-performance metrics …`) — la superficie actual cabe en un solo comando con flags.
