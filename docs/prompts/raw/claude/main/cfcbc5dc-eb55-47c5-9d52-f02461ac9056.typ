#import "@preview/cmarker:0.1.8"

= Check sprint progress and team status

_2026-05-24 15:28 UTC — rama `main` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  How's the team doing with this sprint's work?
  ```,
  h1-level: 4,
  label-prefix: "cc2248-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Sprint 3 status (window 2026-05-21 → 2026-05-27, today 05-24 → day 4 of 7).

  **Nothing feature-related merged yet this sprint.** Only chore/triage PRs landed (sprint plan, issue triage). The 6 committed work items are all still in flight or unstarted:

  | Dev | Commitment | Status | Risk |
  |---|---|---|---|
  | **Franco** | US10+US12 carryover | PR #194 **closed** (conflicting after Cargo/CargoOffer rename); replaced by **PR #221 OPEN**, no reviews yet | On track, but blocking Brian |
  | **Lucas** | US32 vehicle soft-delete | **PR #220 DRAFT** by Copilot agent — not finalized | On track |
  | **Brian** | US8 payment (mock) | No PR. Issue #213 still in `Ready/`. Blocked on Franco's #221 | At risk — 3 days left, depends on #221 review/merge |
  | **Mati** | FIX-BE-00001 destination nullable | No PR. Issue #211 still in `Ready/`. Was day-1 candidate | At risk — independent work, no excuse |
  | **Fernando** | INF-INFRA-00004 (OIDC deploy) + INF-FE-00005 (notif scaffold) | Both open, no impl PRs | At high risk — 2 items, neither started |
  | **Tomás** | GMaps "marcar Recorrido" US | US not yet written (per Sprint 3 plan TODO) | Not committed firmly |

  **Headline:** Mid-sprint with 0 of 6 commitments merged. Franco's rebase (#221) is the dependency unlock for Brian's US8 — that's the critical path. Mati and Fernando have the most slip risk: independent work that hasn't started.

  Project board reflects this: only 2 items in "In review" (#104, #123 — both Franco's, moved by your PR #224 today). Everything else for sprint 3 sits in `Ready/` on disk but hasn't transitioned to "In progress" on the board.
  ```,
  h1-level: 4,
  label-prefix: "cc2249-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/write-a-skill for quick PM (me) sprint status. /grill-with-docs for additional sprint info/stats that I could use`
  ```,
  h1-level: 4,
  label-prefix: "cc2250-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Quick grilling before I draft. Picked the questions where your answer materially changes the skill shape.
  ```,
  h1-level: 4,
  label-prefix: "cc2251-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Drafting `/home/[user]/.claude/skills/sprint-status/SKILL.md`.
  ```,
  h1-level: 4,
  label-prefix: "cc2252-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Skill written. One file, ~70 lines, no scripts (everything is a one-liner against `gh` + `ctx_execute`/jq, and codifying that as a script would just duplicate the prompt).

  **Path:** `/home/[user]/.claude/skills/sprint-status/SKILL.md`

  **Trigger phrases** baked into the description: "how's the sprint going", "sprint status", "where are we", "team progress", or `/sprint-status`.

  **Two things to sanity-check before relying on it:**

  1. The skill assumes `SPRINT-N-PLAN.md` lives under `docs/features/` (matches `SPRINT-1-PLAN.md` and the WIP `SPRINT-3-PLAN.md` in PR #219). If you ever move the sprint plans (e.g. into `docs/sprints/` alongside the closing notes), update the *Inputs* section.
  2. The CI-surfacing rule will spam `gh pr checks` once per open sprint PR — fine for 6-dev sprints, but if a sprint ever has >15 open PRs across commitments, consider gating that step behind a confirmation.

  Want me to test-run the skill now against sprint 3 to see if it produces the same output I gave you above, or leave it for next time?
  ```,
  h1-level: 4,
  label-prefix: "cc2253-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  open a pr with the changes
  ```,
  h1-level: 4,
  label-prefix: "cc2254-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Hold up — the skill I wrote lives at `~/.claude/skills/sprint-status/SKILL.md`, which is **outside the repo**. There's nothing in `/home/[user]/fiuba/fiuba-gestion-tp` to PR right now (project git status is the same as session start: only the pre-existing untracked `.claude/worktrees/` and `seed_state.py`).

  Three ways to read your request:

  1. **Vendor the skill into the project repo** — copy it to `.claude/skills/sprint-status/SKILL.md` so the rest of the team gets it when they pull. PR-able.
  2. **Vendor it into a separate dotfiles/skills repo** — if you have one, tell me the path.
  3. **You meant the skill file as-is in `~/.claude/`** — that's a personal install, no PR needed (and no remote to push to).

  My guess is #1 since the description is already FIUBA-Truckr-specific ("Quick PM sprint status for the FIUBA GDSI Truckr repo") — making it portable across the team makes sense. Confirm and I'll copy it over, branch + PR with a `chore:` title.
  ```,
  h1-level: 4,
  label-prefix: "cc2255-",
)

== Intercambio 4

=== Prompt

#cmarker.render(
  ```
  #1
  ```,
  h1-level: 4,
  label-prefix: "cc2256-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  PR opened: **https://github.com/tcorzo/fiuba-gestion-tp/pull/225**

  Title: `chore(skills): add sprint-status skill for quick PM snapshots`. Assigned to you. The `gh` warning about uncommitted changes refers to the pre-existing untracked files (`.claude/worktrees/`, `.gdsi-sdlc/automation/scripts/seed_state.py`) that were there at session start — left them alone, not part of this work.
  ```,
  h1-level: 4,
  label-prefix: "cc2257-",
)
