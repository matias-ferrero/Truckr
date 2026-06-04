---
name: sprint-planning
description: Produce the next sprint plan (docs/features/SPRINT-N-PLAN.md) for the FIUBA GDSI Truckr repo, plus its closure stub (docs/sprints/sprint-NN.md), mirroring the structure of the prior sprint plans. Use when the user (PM) asks to "plan the next sprint", "do sprint planning", "write the sprint N plan", or runs /sprint-planning.
---

# Sprint planning

Writes the next `docs/features/SPRINT-N-PLAN.md` for `tcorzo/fiuba-gestion-tp` in **Spanish (es-AR)** — planning docs are a language-policy carve-out. The plan is a per-developer commitment doc: who owns what, dependencies, deferred work, Definition of Done, risks. Mirror the most recent `SPRINT-(N-1)-PLAN.md` exactly; see [TEMPLATE.md](TEMPLATE.md) for the skeleton.

Companion skill: `/sprint-status` reads this file mid-sprint. Keep the *Compromisos por integrante* and *Ventana* lines parseable (don't reshape those tables).

## Inputs (auto-detect, then confirm with the PM)

1. **N** — highest existing `docs/features/SPRINT-N-PLAN.md` + 1.
2. **Ventana** — weekly cadence **jueves → miércoles**. Derive from the prior plan's window + 7 days unless the user gives dates. Confirm.
3. **Equipo (6)** — Brian `@bcespedes`, Fernando `@FernandoYu`, Franco `@FrancoRicciardo`, Lucas `@LucasDondo`, Matías `@matias-ferrero`, Tomás `@tcorzo`. PM/SM: Tomás. (Team size is 6 — never write "equipo de 2".)
4. **Goal + commitments** — this is the real planning conversation. Source candidate work from the board and the prior sprint's carryovers (below), then **ask the PM** what the sprint commits to. Do not invent commitments from the tracker alone.

## Data collection (one batched ctx call — never raw Bash for this)

Use `mcp__plugin_context-mode_context-mode__ctx_batch_execute`:

- Read the prior plan: `cat docs/features/SPRINT-$((N-1))-PLAN.md` (structure to mirror).
- Read the prior closure: `cat docs/sprints/sprint-0$((N-1)).md` (what's still in progress = carryover candidates).
- `gh project item-list 7 --owner tcorzo --limit 200 --format json` — board state.
- `gh pr list --state open --limit 40 --json number,title,author,headRefName,isDraft,reviewDecision` — open PRs = carryover / in-flight.
- `ls .gdsi-sdlc/issues/{Backlog,Ready,InProgress,InReview}/` — live issue files.
- `cat docs/artifacts/cronograma.typ` — planned cadence (flag drift; don't silently follow it — it's often stale).

Then derive the carryover and candidate lists with `ctx_execute`; don't paste raw JSON into context.

## Workflow

1. Collect inputs above. Identify **carryovers** (open PRs + in-progress USs from the prior closure) — these are NOT new work and get their own section.
2. Draft the goal (`## Objetivo del sprint`) as a bold blockquote + one narrative paragraph. Run it past the PM.
3. Fill *Compromisos por integrante*: one row per `(dev, TAG (gh #), trabajo, tipo, carryover)`. Aim ~1 stream/dev; a dev may hold 2 if one is small or a carryover. Use TAGs from `.gdsi-sdlc/config.json` prefixes (`REQ`, `FIX`, `INF`, …) + scope (`BE`/`FE`/`INFRA`/…). Local-only issues (no GH #) → mark `(local)`.
4. Fill the remaining sections from [TEMPLATE.md](TEMPLATE.md): Carryovers, Dependencias, Fuera de alcance, Definition of Done (stable 6-item boilerplate — copy verbatim), Riesgos, Referencias, Mapping at a glance.
5. Write the plan to `docs/features/SPRINT-N-PLAN.md` and the closure stub to `docs/sprints/sprint-NN.md` (zero-padded, e.g. `sprint-05.md`) with `status: planned`, the window, empty `completed_user_stories: []`, and "_A completar por el equipo._" placeholders.
6. Review the draft with the PM before opening a PR.

## Hard rules (this repo)

- **Spanish prose is fine here** (planning carve-out), but any code/route/model/TAG referenced stays English. UI/error text referenced must be i18n keys, never literals.
- **SQLite forever.** When describing deferred work, never frame it as "fase 1 → luego Postgres / cuando migremos". Deferred = new work in a future sprint, or a final limitation. No RDS/PostGIS/`citext`/`unaccent`/EXCLUDE planning.
- **No invented timeframes.** Every date traces to the window or an explicit PM input.
- **Mid-sprint changes** are recorded as `> **Enmienda <YYYY-MM-DD> (día X de 7).** …` blockquotes near the top — don't rewrite history, append an amendment.

## PR conventions

- Title: `docs(planning): add sprint N plan` — conventional type first, **no `[TAG]` bracket prefix** (breaks release-please). TAG/`Closes #N` go in the body.
- Branch: `feature/sprint-N-plan` (or similar).
- `gh pr create --assignee @me`.
- This is a planning-doc change → quality gate is just `just build-artifacts` (if it touches compiled `docs/`) + `just lint`. SPRINT plans are plain markdown under `docs/features/`, not compiled Typst, so usually only `just lint`.
