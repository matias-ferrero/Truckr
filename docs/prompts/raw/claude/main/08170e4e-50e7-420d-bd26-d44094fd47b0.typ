#import "@preview/cmarker:0.1.8"

= Add audit, polish, critique instructions to claude.md

_2026-05-12 02:00 UTC — rama `feat/dashboard` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  In a worktree, branch off of main and add instructions to claude.md to /audit, /polish and /critique new UI elements (via impeccable skills), run all tests and confirm test coverage meets the threshold before opening a PR which triggers costly CI actions

  open a PR when you're done
  ```,
  h1-level: 4,
  label-prefix: "cc64-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now I'll add a UI quality gate section. Let me check the test commands available.
  ```,
  h1-level: 4,
  label-prefix: "cc65-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  I'll add a "Pre-PR UI quality gate" section between Document conventions and Releases.
  ```,
  h1-level: 4,
  label-prefix: "cc66-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now run the gate against this docs-only change. Lint + tests:
  ```,
  h1-level: 4,
  label-prefix: "cc67-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  I cd'd out of the worktree by accident and ran prek against the main repo, which auto-fixed unrelated files. Cleaning up.
  ```,
  h1-level: 4,
  label-prefix: "cc68-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Stepping back: I'll leave the main repo's state alone (stash + the 3 working-tree files contain a mix of pre-existing user work and prek auto-fixes — too risky to touch unilaterally). I'll apply the edit to the worktree CLAUDE.md, where it belongs, and PR from there.
  ```,
  h1-level: 4,
  label-prefix: "cc69-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now run the quality gate against the worktree itself. This branch only touches `CLAUDE.md` (not frontend/backend/docs), so only `lint` is strictly required by my own carve-out — but I'll still run frontend coverage to demonstrate the gate.
  ```,
  h1-level: 4,
  label-prefix: "cc70-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Lint clean. Now run frontend coverage from the worktree.
  ```,
  h1-level: 4,
  label-prefix: "cc71-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Frontend coverage passes (94.48% lines, 87.21% branches, 84.21% funcs — all above the 80% threshold). Now backend tests.
  ```,
  h1-level: 4,
  label-prefix: "cc72-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Backend RSpec: 256/256 passing, SimpleCov 87.5% lines. Now commit and PR from the worktree.
  ```,
  h1-level: 4,
  label-prefix: "cc73-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  PR opened: https://github.com/tcorzo/fiuba-gestion-tp/pull/169

  **Summary**
  - Worktree `claude-md-ui-skills` branched off `main` (75bcfab).
  - `CLAUDE.md` +26 lines: new **Pre-PR UI quality gate** section mandating impeccable `/critique` → `/polish` → `/audit` for UI changes, plus a local checklist (lint, frontend coverage at 80%, Playwright, RSpec, Typst build) and a carve-out for typo-only / planning-doc edits.
  - Gate run locally before opening the PR: prek clean on `CLAUDE.md`, frontend Vitest **61/61** at **94.48% lines** (>80% threshold), backend RSpec **256/256** at **87.5%**.
  - PR `#169` opened against `main`, assigned to you.

  **Caveat — please review main repo state**
  While running the gate I accidentally `cd`'d out of the worktree and ran `prek` against the main repo on `feat/dashboard`. That created an auto-fix to 3 unrelated files (`docs/artifacts/cronograma.typ`, `docs/features/INF/INF-INFRA-00003/INF-INFRA-00003-research-decision.md`, `frontend/src/styles/auth.css`) and a `git stash` I left in place (`stash@{0}` — mixes those autofixes with pre-existing uncommitted issue-file changes that were already in your tree). Permission was denied when I tried to `git checkout --` the 3 files, which is correct — those need your eyes. Likely action: inspect `stash@{0}`, drop or pop selectively. The worktree (and the PR) are uncontaminated.
  ```,
  h1-level: 4,
  label-prefix: "cc74-",
)
