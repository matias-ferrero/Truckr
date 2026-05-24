---
name: sprint-status
description: Quick PM sprint status for the FIUBA GDSI Truckr repo. Reads the current sprint plan + GitHub project + open PRs and prints a terse per-dev table with on-track/at-risk calls. Use when the user (PM) asks "how's the sprint going", "sprint status", "where are we", "team progress", or runs /sprint-status.
---

# Sprint status

Quick mid-sprint snapshot for the PM. Auto-detects the current sprint, classifies each commitment against days-remaining and PR review state, and surfaces the critical path. Inline output only — no file written.

## Inputs (auto-detected)

1. **Latest sprint plan** — highest-numbered `docs/features/SPRINT-N-PLAN.md`. Parse the *Compromisos por integrante* table → `(dev, TAG, gh#, work, carryover)`. Parse the *Ventana* line → `(start, end)`.
2. **Today** — `date +%F`. If today is outside `[start, end]`, report that and ask if the user wants a retrospective on the closed sprint or a look-ahead at the next one before continuing.
3. **GitHub project + PRs** — repo is `tcorzo/fiuba-gestion-tp`, project number 7 (read from `.gdsi-sdlc/config.json`).

If no `SPRINT-N-PLAN.md` exists yet, say so and stop. Don't invent commitments from the issue tracker.

## Data collection (one batched ctx call)

Use `mcp__plugin_context-mode_context-mode__ctx_batch_execute` with these commands — output is huge, never via raw Bash:

- `gh project item-list 7 --owner tcorzo --limit 200 --format json` — board state.
- `gh pr list --state open --limit 30 --json number,title,author,createdAt,updatedAt,isDraft,reviewDecision,mergeable,headRefName`.
- `gh pr list --state merged --limit 30 --search "merged:>=<sprint-start>" --json number,title,mergedAt,author` — what actually landed this sprint.
- For each gh# from the plan: `gh pr list --search "<gh#>" --state all --json number,state,isDraft,reviewDecision,mergeable,updatedAt` *(only if the issue has linked PRs on the board)*.
- For each open PR on a sprint commitment: `gh pr checks <N> --json bucket,name,state` — CI status, see below.

Then process with `mcp__plugin_context-mode_context-mode__ctx_execute` (shell/jq) to derive the table — don't paste raw JSON into context.

## Classification rules

For each commitment in the plan, compute `status` ∈ {merged, in review, in progress, not started}, `ci` ∈ {green, red, pending, n/a}, `risk` ∈ {on track, at risk, blocked}.

| Signal | Verdict |
|---|---|
| PR merged within sprint window | **merged** / on track |
| PR open, not draft, reviewed/approved, CI green | **in review** / on track |
| PR open and (draft OR CI red OR conflicting OR no reviewer activity in 48h) | **in review** / at risk |
| PR open but blocking dep PR not merged | **in progress** / blocked (note the dep gh#) |
| No PR, issue still in `Ready/` or `Backlog`, ≥ 50% of sprint elapsed | **not started** / at risk |
| No PR, issue still in `Ready/`, < 50% of sprint elapsed | **not started** / on track |

For carryover items, an extra rule: if the carryover PR was *closed* (e.g. force-replaced by a rebased PR), point at the new PR — don't report the closed one as a regression.

## CI surfacing

When an open PR shows red or pending checks, add a third line under the dev's row naming the failing check(s) — e.g. `CI: backend-rspec ✗`. Treat red CI as **at risk**, not blocked, unless the failure clearly blocks a dependent PR.

## Output shape (strict)

```
Sprint N status (day X of Y).

M of K commitments merged.

| Dev | Commit | Status | Risk |
|---|---|---|---|
| ... |

Critical path: <unlock PR> → <dependent commitment>.
Headline: <one sentence — what most needs the PM's attention right now>.
```

Sort the table by risk severity (blocked → at risk → on track → merged). Keep dev names short (first name). Link PRs as `PR #N`, issues as `#N`. No emojis. No closing pleasantries.

## When to push back

- If the user asks for the same status twice in one session, skip the data collection and diff against the prior call — only re-fetch if open PRs have updated since.
- If a commitment in the plan has no gh# and no issue, flag it once at the bottom (`Unbound: <dev> — <work>`) and move on. Don't fail.
- If the plan's *Equipo* line and the assignees on the board disagree, trust the plan.
