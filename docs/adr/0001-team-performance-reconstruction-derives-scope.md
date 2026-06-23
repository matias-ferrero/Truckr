# team-performance reconstruction mode derives its target, horizon, and scope

**Status:** accepted

## Context

The `team-performance` CLI was built for one question — "given a target the operator
types in, what are our odds?" — and it deliberately refused to guess the target,
the horizon, or what "the backlog" means. That refusal is documented and was the
right call for the forward question: a stale auto-count would emit a confident,
wrong forecast.

We then needed a *second* mode: reconstruct, sprint by sprint, what the
performance report **would have read at the end of sprint N** ("what was our
chance of success back then?"). The operator wants to run it once per past
sprint with a single input — the sprint number — and get five comparable
snapshots, not re-type three flags per run.

## Decision

In reconstruction mode (`--as-of-sprint N`) the CLI derives everything from `N`:

- **History window** — only ledger sprints `1…N` feed the sample (the rest is hindsight and is dropped).
- **Target** — the *remaining* MVP: the User Stories in the `MVP — Release 1` section of `docs/artifacts/backlog-us.typ` (today's definition) minus the MVP USs completed through sprint `N`. It shrinks sprint over sprint.
- **Horizon** — `total_dev_sprints − N`, with `total_dev_sprints = 6` (Sprint 7 is artifact-polish, not development — see `CALENDAR.md`).
- **Velocity** — throughput counts only MVP-tagged completions, so the numerator matches the MVP target denominator.

This **reverses**, for this mode only, the tool's documented "never auto-count"
stance. The forward mode (`--target-user-stories` / `--remaining-sprints`) is
unchanged and still requires explicit input.

## Why this is safe here when it wasn't before

The objection to auto-counting was "stale tags → silently-wrong forecast." Three
things neutralise it in reconstruction mode: the scope is a **fixed, terminal
MVP** (the project will not move beyond it, so the target set is stable, not a
moving planning decision); the **ledger is the trusted point-in-time record** the
whole tool already relies on; and the derivation is **transparent** — the JSON
emits `mvp_total`, `mvp_completed_through`, and the derived target/horizon so the
rendered report shows its own arithmetic. The scope is measured against *today's*
MVP definition, not the definition as it stood at sprint N (recovering historical
scope would need git archaeology for a negligible fidelity gain on an academic
report); the report prints this caveat.

## Consequences

- The five reconstructed reports tell a burndown story: a falling target chased by observed MVP velocity.
- The `--as-of-sprint 1` report has **no forecast** — the bootstrap needs ≥ 2 closed sprints — and renders retrospective-only.
- If the `MVP — Release 1` section and the per-US `*Release:* MVP` tags disagree, the section wins and the tool logs a warning (an integrity check on backlog drift).
- JSON schema bumped to **v4** (adds the `reconstruction` block; throughput is MVP-scoped in this mode).
