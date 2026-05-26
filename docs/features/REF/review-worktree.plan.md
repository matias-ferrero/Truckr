# Plan: `just review` — quick eval of an agent's worktree

## Goal

Boot an agent's worktree (under `.claude/worktrees/<name>`) into a 3-pane kitty layout for manual UI/behavior review, with zero "did you remember to migrate / install / open the browser" friction.

## Invocation

```sh
just review <worktree-name>   # explicit
just review                   # fzf-pick from .claude/worktrees/*
```

If no arg AND `fzf` not installed → print the list of worktrees and exit non-zero.

## Recipe behavior (in order)

1. **Resolve** `WT=$(pwd)/.claude/worktrees/<name>`. Exit if missing.
2. **Anchor banner** — print to originating shell:
   ```
   Reviewing <branch>  →  http://localhost:5173
   ```
   then `git -C $WT diff main...HEAD --stat`.
3. **Deps (always, idempotent):**
   - `cd $WT/backend && bundle install`
   - `cd $WT/frontend && deno install` (or whatever `frontend-install` already does)
4. **DB prep:**
   - If `$WT/backend/storage/development.sqlite3` exists → `bin/rails db:migrate`
   - Else → `bin/rails db:prepare && bin/rails db:seed`
5. **Spawn kitty** with a generated session file (heredoc → `mktemp`):
   - Layout: `splits` — left column 50%, right column 50%; left column stacked 50/50.
   - Pane top-left: `cd $WT/backend && exec bin/dev`  *(Rails on :3000)*
   - Pane bottom-left: `cd $WT/frontend && exec deno task dev -- --open`  *(Vite on :5173, auto-opens browser)*
   - Pane right: `cd $WT && exec $SHELL`  *(free shell for `rails c`, `git log -p`, curl)*
   - Launched via `kitty --detach --session $tmp` so recipe exits immediately.
6. **Cleanup** = user closes the kitty OS window → SIGHUP kills all three panes' processes via the window's process group.

## Decisions locked (from grill-me)

| # | Decision | Choice |
|---|---|---|
| 1 | Eval mode | Manual UI/behavior check (boot the app) |
| 2 | Stack scope | Always boot both Rails + Vite |
| 3 | Ports | Default 3000/5173 — assume no main-repo servers running |
| 4 | DB prep | `db:prepare`+`db:seed` on fresh DB; `db:migrate` on existing |
| 5 | Layout | Kitty session file, 3 panes (backend, frontend, free shell) |
| 6 | Worktree selection | Positional arg, fzf fallback when no arg |
| 7 | Lifecycle | Recipe detaches and exits; closing the kitty window kills servers |
| 8a | Frontend deps | Always install |
| 8b | Backend deps | Always `bundle install` |
| 8c | Browser open | Via Vite `--open` flag |
| 9a | Anchor banner | Yes — branch name + URL |
| 9b | Tail dev.log in pane 3 | No — plain shell |
| 9c | Auto-`git pull` | No — worktree-as-is |
| 9d | Print diff stat | Yes |

## Implementation notes for the writer

- Most of the logic is shell, not just-DSL. Put the body in `script/review-worktree.sh`, have the justfile recipe just `exec` it. Easier to test, easier to read.
- The kitty session file format:
  ```
  layout splits
  launch --location=hsplit --cwd=<WT>/backend bin/dev
  launch --location=vsplit --cwd=<WT>/frontend deno task dev -- --open
  launch --location=hsplit --cwd=<WT> $SHELL
  ```
  (Adjust split directions to land on the desired layout.)
- Pre-flight: verify `kitty`, `deno`, `bundle`, `bin/rails` are all on PATH. Fail with a clear message naming the missing one.
- Optional follow-up (don't build now): `just review-kill` doing `pkill -f "rails server.*$WT"` for orphan recovery.

## Out of scope (intentionally)

- Concurrent reviews of multiple worktrees (Q3 chose A — fixed default ports).
- Code-diff review in the layout (Q1 chose C — UI only; diff stat in the banner is the concession).
- Static gates (lint/test) — those are CI's job and run on push anyway.
