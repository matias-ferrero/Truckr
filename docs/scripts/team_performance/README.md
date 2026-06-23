# team_performance

User-Story throughput metrics and bootstrap projection for the
`fiuba-gestion-tp` repo. Reads a hand-maintained **per-sprint ledger**
(`docs/progress-reports/sprint-NN.md`), computes throughput in User Stories per sprint,
lead time in sprints, and (optionally) bootstraps a probability of meeting a
target.

We don't estimate. We measure throughput, then project backwards. The unit is
the **User Story**, not the GitHub issue — issues vary too much in size.

## Install (dev)

```sh
uv sync --extra dev
```

This puts the `team-performance` entrypoint in the `.venv`.

## The sprint ledger

One Markdown file per sprint under `docs/progress-reports/`, named `sprint-NN.md`. The
tool reads only the frontmatter; the body is free-form retro notes.

```yaml
---
sprint: 1
phase: development          # development | documentation
status: closed              # closed = counted; in_progress = skipped
window: 2026-05-07 -> 2026-05-13
in_progress_user_stories: [US7]
completed_user_stories: [US1, US2, US14]
---
## Retro
- ...
```

- `completed_user_stories` — USs *finished* (all acceptance criteria met) this sprint.
- `in_progress_user_stories` — USs worked but **not** finished; carry-over WIP only.
  Never list a US in both lists of the same file.
- Only `status: closed` files matching `--phase` feed the throughput sample.

Ledger US ids are validated against `backlog-us.typ` by default; an unknown id
is a fatal data error. Pass `--no-us-validation` to skip that check while the
backlog artifact is behind the ledger.

## Run

```sh
# Stats only (no projection)
uv run team-performance --format text

# Stats + projection (want to complete 20 more USs, 5 sprints left)
uv run team-performance \
    --target-user-stories 20 \
    --remaining-sprints 5 \
    --format both

# Reconstruction — what the report read at the end of sprint 3 (single input)
uv run team-performance --as-of-sprint 3 --no-us-validation --format both

# Module form (no entrypoint needed)
python -m team_performance --help
```

## Reconstruction mode (`--as-of-sprint`)

Replays the ledger **as of** a past sprint to reconstruct the report it would
have produced then — "what was our chance of success back then?". Everything is
derived from `N`, so the operator types one number (bare `--as-of-sprint` =
latest closed sprint):

| Derived | From |
|---|---|
| History window (sprints `1..N`) | the ledger, truncated at `N` |
| Target (remaining MVP) | `MVP — Release 1` section of `backlog-us.typ` − MVP completed through `N` |
| Horizon (`6 − N`) | `--total-dev-sprints` (default 6; Sprint 7 is artifact-polish) |
| Velocity | MVP-tagged completions per sprint only |

Cannot be combined with `--target-user-stories` / `--remaining-sprints` (those
*are* the derived values). `--as-of-sprint 1` has no forecast (< 2 closed
sprints). When the MVP is already burned down by `N`, the report is flagged
`already_complete` and skips the projection. The MVP scope is measured against
**today's** backlog, not the scope as it stood at sprint `N`. See
[ADR 0001](../../adr/0001-team-performance-reconstruction-derives-scope.md).

## Output formats

| `--format` | Stdout       | Stderr (rich tables) |
|------------|--------------|----------------------|
| `json`     | JSON payload | logs only            |
| `text`     | (empty)      | tables               |
| `both`     | JSON payload | tables               |

`text` and `both` write to **stderr** so the JSON on stdout stays pipeable.

## JSON schema (v4)

> **v4** adds a `reconstruction` block (non-null only in `--as-of-sprint` mode)
> and, in that mode, scopes `sprints[].completed_*` and throughput to MVP-tagged
> User Stories. The `projection.target_user_stories` / `forward.remaining_sprints`
> are the *derived* values. Manual mode (no `--as-of-sprint`) is otherwise
> unchanged from v3.

```jsonc
// reconstruction (null unless --as-of-sprint was given):
"reconstruction": {
  "as_of_sprint": 3,
  "history_from": 1, "history_to": 3,
  "total_dev_sprints": 6,
  "mvp_total": 50, "mvp_completed_through": 26,
  "derived_target_user_stories": 24,   // mvp_total - mvp_completed_through
  "derived_remaining_sprints": 3,      // total_dev_sprints - as_of_sprint; null if <= 0
  "already_complete": false,
  "velocity_scope": "mvp",
  "scope_yardstick": "current"
}
```

### Base schema

```jsonc
{
  "schema_version": "3",
  "generated_at": "2026-05-28T12:00:00+00:00",
  "config_snapshot": { /* effective config (CLI > env > defaults) */ },
  "sprints": [
    {
      "index": 1,
      "phase": "development",
      "window_start": "2026-05-07",
      "window_end": "2026-05-13",
      "completed_count": 3,
      "completed_user_stories": ["US1", "US2", "US14"],
      "wip_at_end": 1,
      "in_progress_user_stories": ["US7"]
    }
  ],
  "aggregate": {
    "throughput":        { "mean": 2.5, "median": 2.5, "stdev": 0.71, "min": 2, "max": 3 },
    "lead_time_sprints": { "p50": 0.0, "p75": 1.0, "p90": 1.0 },
    "sample_size_sprints": 2
  },
  "projection": {
    "target_user_stories": 20,
    "method": "bootstrap_throughput",
    "bootstrap_samples": 10000,
    "sprints_to_target": { "p50": 8, "p85": 11, "p95": 13, "p99": 15,
                           "did_not_finish_pct": 0.0, "cap_sprints": 100 },
    "forward": { "remaining_sprints": 5, "p_meet_or_exceed_target": 0.42,
                 "total_projected_p10": 10, "total_projected_p50": 13,
                 "total_projected_p90": 17 }
  }
}
```

Every metric is paired with a `_meaning` companion field (es-AR).
`schema_version` is bumped on every breaking JSON change.

## Exit codes

| Code | Meaning                                                                |
|------|------------------------------------------------------------------------|
| 0    | Success                                                                |
| 2    | Usage error (bad/missing flag)                                         |
| 3    | Data-source error (ledger missing, unparseable, or failed validation)  |
| 4    | Insufficient sample for projection (< 2 closed sprints) — observed metrics still emitted |

## Configuration layering

Resolved per setting in this order (first match wins):

1. CLI flag (`--sprints-dir`)
2. Env var (`TEAM_PERF_SPRINTS_DIR`)
3. Built-in default (`docs/progress-reports`)

`NO_COLOR` is honoured for the rich output (also `--no-color`).

## Development

```sh
just team-performance-test    # pytest + coverage
just team-performance-lint    # ruff check + ruff format --check + mypy --strict
```

Tests run against ledger fixtures under `tests/fixtures/`; no network.
