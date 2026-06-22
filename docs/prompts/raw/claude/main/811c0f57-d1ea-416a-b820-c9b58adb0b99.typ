#import "@preview/cmarker:0.1.8"

= Adapt worktree audit workflow for project

_2026-05-13 00:18 UTC — rama `main` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  copy the workflow from @~/work/Justfile  for auditing specific worktrees and adapt it to work against @.claude/worktrees/ for this specific project
  ```,
  h1-level: 4,
  label-prefix: "cc1407-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Adapting the audit workflow to this project. Worktrees are flat (`.claude/worktrees/<name>/`), each contains both `backend/` (Rails, port 3000 via `bin/dev`) and `frontend/` (Deno+Vite, port 5173). No paired sibling stacks, no sidekiq.
  ```,
  h1-level: 4,
  label-prefix: "cc1408-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Added audit recipes to `justfile`. Recipes are `audit-` prefixed to avoid collision with existing build recipes.

  **Adaptations from `~/work/Justfile`:**
  - Dropped repo dimension — single project, tab title is `audit:truckr:<wt>`.
  - Dropped paired-stack logic — each worktree has both `backend/` + `frontend/` in one tree.
  - Stack panes: `bin/dev` in `backend/` (port 3000), `deno task dev` in `frontend/` (port 5173), shell at root. Layout `tall` (3 panes, not 4).
  - No sidekiq pane (project doesn't use it).
  - `audit-ports` checks 3000/5173 instead of 3000-3003/8080.
  - Flat worktree dir (`.claude/worktrees/<wt>/`) instead of nested `<repo>/<issue>/`.

  **Recipes:** `audit-doctor`, `audit <wt>`, `audit-code <wt>`, `audit-servers <wt>`, `audit-down <wt>`, `audit-restart <wt>`, `audit-list`, `audit-ports`.

  Run `just audit-doctor` first, then e.g. `just audit pr-164`.
  ```,
  h1-level: 4,
  label-prefix: "cc1409-",
)
