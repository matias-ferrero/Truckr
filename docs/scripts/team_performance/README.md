# team_performance

Throughput-based team performance metrics and bootstrap projection for the
`fiuba-gestion-tp` repo. Reads issues from GitHub via `gh issue list --json …`,
bins them into sprint windows, computes throughput / cycle-time stats, and
(optionally) bootstraps a probability of meeting a target.

We don't estimate. We measure throughput, then project backwards.

## Install (dev)

```sh
uv sync --extra dev
```

This puts the `team-performance` entrypoint in the `.venv`.

## Run

```sh
# Stats only (no projection)
uv run team-performance --sprint-start 2026-04-21 --format text

# Stats + projection (5 more sprints, want to close 20 more issues)
uv run team-performance \
    --sprint-start 2026-04-21 \
    --target-issues 20 \
    --remaining-sprints 5 \
    --format both

# Module form (no entrypoint needed)
python -m team_performance --help
```

## Output formats

| `--format` | Stdout       | Stderr (rich tables) |
|------------|--------------|----------------------|
| `json`     | JSON payload | logs only            |
| `text`     | (empty)      | tables               |
| `both`     | JSON payload | tables               |

`text` and `both` write to **stderr** so the JSON on stdout stays pipeable.

## JSON schema (v1)

```jsonc
{
  "schema_version": "1",
  "generated_at": "2026-05-19T12:00:00+00:00",
  "config_snapshot": { /* effective config (CLI > env > pyproject > defaults) */ },
  "sprints": [
    {
      "index": 1,
      "start": "2026-04-21T00:00:00+00:00",
      "end":   "2026-05-05T00:00:00+00:00",
      "closed_count": 3,
      "created_count": 4,
      "wip_at_end": 2,
      "closed_numbers": [101, 102, 103]
    }
  ],
  "aggregate": {
    "throughput":      { "mean": 2.5, "median": 2.5, "stdev": 0.71, "min": 2, "max": 3 },
    "cycle_time_days": { "p50": 7.0, "p75": 9.5, "p90": 11.0 },
    "sample_size_sprints": 2
  },
  "projection": {
    "target_issues": 20,
    "remaining_sprints": 5,
    "p_meet_or_exceed_target": 0.42,
    "total_projected_p10": 10,
    "total_projected_p50": 13,
    "total_projected_p90": 17,
    "method": "bootstrap_throughput",
    "bootstrap_samples": 10000
  }
}
```

`schema_version` is bumped on every breaking JSON change.

## Exit codes

| Code | Meaning                                  |
|------|------------------------------------------|
| 0    | Success                                  |
| 2    | Usage error (bad/missing flag)           |
| 3    | Data-source error (gh missing, JSON bad) |
| 4    | Insufficient sample for projection (< 2 completed sprints) — observed metrics still emitted |

## Configuration layering

Resolved per setting in this order (first match wins):

1. CLI flag (`--repo`)
2. Env var (`TEAM_PERF_REPO`)
3. `pyproject.toml → [tool.team_performance].repo`
4. Built-in default

`NO_COLOR` is honoured for the rich output (also `--no-color`).

## Development

```sh
just team-performance-test    # pytest + coverage
just team-performance-lint    # ruff check + ruff format --check + mypy --strict
```

Tests run against a fake `gh` runner (see `tests/conftest.py`); no network.
