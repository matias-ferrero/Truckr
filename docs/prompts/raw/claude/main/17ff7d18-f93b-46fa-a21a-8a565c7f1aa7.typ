#import "@preview/cmarker:0.1.8"

= Fix conventional commits in squash merge PRs

_2026-05-09 19:09 UTC — rama `feature/REQ-BE-00022-implementar-contexto-fulfilment` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/clear`
  ```,
  h1-level: 4,
  label-prefix: "cc172-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  pull request squash merge commits are landing WITHOUT conventional commits, this is preventing new releases to include the correct changelog nor generate at all via release-please
  ```,
  h1-level: 4,
  label-prefix: "cc173-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Found it. Root cause: PR squash titles get the `[REQ-XX-NNNNN]` issue tag prepended BEFORE the conventional commit type, so release-please's parser skips them entirely.

  Examples from `git log`:
  - `[REQ-BE-00020] feat(identity): ... (#133)` ← invalid
  - `[REQ-DOC-00002] feat(docs): ... (#77)` ← invalid
  - `[INF-BE-00003] feat(backend): ... (#73)` ← invalid
  - `[INF-FE-00002] chore(frontend): ... (#66)` ← invalid

  release-please needs `type(scope): subject` at position 0. The bracketed prefix breaks the parse silently → no changelog entry → no version bump.

  Let me find where this prefix gets added so I can fix the source.
  ```,
  h1-level: 4,
  label-prefix: "cc174-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Root cause confirmed.

  `gdsi-sdlc:issues:implement` skill (`SKILL.md:270`) templates PR title as `[$TAG] $TITLE`. release-please's conventional-commits parser requires `type(scope): subject` at position 0, so the bracketed prefix makes it skip those commits entirely. Squash merge keeps that title verbatim → no parse → no changelog → no version bump.

  Affected merged PRs since `0.1.10` (last release): `#73`, `#74`, `#77`, `#81`, `#133`, `#134`, `#135` — all silently dropped.

  ## Plan

  **Forward fix** (autonomous, low-risk):
  1. Add `.github/workflows/pr-title.yml` using `amannn/action-semantic-pull-request` to **block** non-conventional PR titles at PR-time. Defense at the right layer.
  2. Add CLAUDE.md note: PR titles must start with conventional type; TAG goes in body via `Closes #N` (already there), not in subject.
  3. Save a feedback memory so I don't repeat the bracket-prefix mistake.

  **Backward fix** (needs your call): The 7 missed PRs aren't in any changelog. Options:
  ```,
  h1-level: 4,
  label-prefix: "cc175-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Wrong branch. The forward-fix changes are unrelated to the Fulfilment feature branch I'm on — moving them to a dedicated branch off main.
  ```,
  h1-level: 4,
  label-prefix: "cc176-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Forward-fix is up: **PR #136 — https://github.com/tcorzo/fiuba-gestion-tp/pull/136**

  Restored to `feature/REQ-BE-00022-...` so your in-flight work is untouched. The backfill (force a `0.2.0` release covering #73, #74, #77, #81, #133, #134, #135) needs to land on `main` and is destructive enough that I want explicit sign-off before doing it.

  Plan I'd execute on your "go":

  1. Wait for #136 (or the backfill itself) to land first so the new lint protects subsequent work.
  2. From `main`, create branch `chore/release-please-recovery-0.2.0`.
  3. Add 7 empty commits, one per missed PR, with proper conventional subjects re-stating each merge — e.g. `feat(identity): User, Carrier, Shipper, Vehicle models + migrations (recover #133)`. This gives release-please real conventional commits to parse, so the changelog body is correct.
  4. Add a final empty commit `chore: trigger release` with `Release-As: 0.2.0` in the body to force the version.
  5. Open a PR; on merge, release-please cuts `0.2.0` with the full backfilled changelog, and the artifacts/prompts PDFs get attached.

  Two judgment calls in there:
  - **Empty commits on main** (7+1) clutter history but are the canonical release-please recovery pattern. Alternatives: a single empty commit with hand-written CHANGELOG.md edits — but release-please will likely overwrite or duplicate sections.
  - **0.2.0 vs 0.1.11**: you already chose 0.2.0; sticking with that.

  Say the word and I'll proceed once #136 is merged.
  ```,
  h1-level: 4,
  label-prefix: "cc177-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  go
  ```,
  h1-level: 4,
  label-prefix: "cc178-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  #136 already merged (`d4d25fb`). The lint is live. Also re-checked the gap and found 2 more broken commits I missed earlier: **#63** (`Bootstrap backend, frontend, docs and AI harness`, no type) and **#66** (`[INF-FE-00002] chore(frontend): harden .gitignore`, bracket-prefixed). Total broken: 9.

  Let me check if there's an open release-please PR before I proceed.
  ```,
  h1-level: 4,
  label-prefix: "cc179-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Re-checked the data and updated the gap analysis:

  - **#136 already merged.** Lint workflow live.
  - **Only 3 commits are broken in the unreleased range** (since `0.1.10`): `#133`, `#134`, `#135`.
  - **#63, #66, #73, #74, #77, #81** technically shipped under `0.1.10`'s tag but were silently omitted from its changelog because of the same parsing failure. They deserve credit in the next release notes.
  - No release-please PR currently open in the repo.

  Total backfill: 9 PRs. Executing.
  ```,
  h1-level: 4,
  label-prefix: "cc180-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Done. Both PRs are up:

  - **PR #136 (merged)** — forward fix: PR-title lint workflow + CLAUDE.md doc.
  - **PR #137 (open)** — https://github.com/tcorzo/fiuba-gestion-tp/pull/137 — recovery: 9 conventional-commit recoveries + `Release-As: 0.2.0` forcing commit.

  **Critical for #137: merge with "Rebase and merge", not squash.** Squash collapses the 10 commits into one and undoes the whole point. The PR description leads with that warning. If repo settings force squash-only, you'll need to flip the merge strategy temporarily on Settings → General → Pull Requests.

  After rebase-merging #137, release-please will automatically open a `chore(main): release 0.2.0` PR with a properly populated changelog. Merging that one normally cuts the v0.2.0 release with the PDFs attached.

  Restored your working branch to `feature/REQ-BE-00022-implementar-contexto-fulfilment`. Memory saved so I won't repeat the bracket-prefix mistake on future PRs in this repo.
  ```,
  h1-level: 4,
  label-prefix: "cc181-",
)

== Intercambio 4

=== Prompt

#cmarker.render(
  ```
  Run amannn/action-semantic-pull-request@v5
    with:
      types: feat
    fix
    docs
    chore
    ci
    refactor
    test
    perf
    build
    style
    revert

      requireScope: false
      subjectPattern: ^(?![A-Z]).+$
      subjectPatternError: The subject "{subject}" must start with a lowercase letter.
    Reference issues in the PR body via "Closes #N", not in the title.

      wip: true
      githubBaseUrl: https://api.github.com
    env:
      GITHUB_TOKEN: ***
  Error: Resource not accessible by integration


  https://github.com/tcorzo/fiuba-gestion-tp/actions/runs/25609804159/job/75177939371?pr=137
  ```,
  h1-level: 4,
  label-prefix: "cc182-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  `pull_request_target` is the issue. With that event, the GITHUB_TOKEN runs with the base branch's perms but in some repo configs (default workflow permission set to "Read repository contents and packages permissions only" in Settings → Actions → General) the action gets denied even with `pull-requests: read` declared.

  Two paths:

  1. **Switch the trigger to `pull_request`** — simpler, works for same-repo PRs (which is everything here), no repo-settings change needed.
  2. **Loosen repo Actions permissions** — Settings → Actions → General → "Read and write permissions". Repo-wide blast radius, not ideal.

  Going with #1. Quick fix PR.
  ```,
  h1-level: 4,
  label-prefix: "cc183-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Fix opened: **PR #138 — https://github.com/tcorzo/fiuba-gestion-tp/pull/138**

  After merging #138, re-trigger PR #137's lint by editing its title (e.g. add then remove a trailing space, or just close/reopen). With `pull_request` instead of `pull_request_target`, the action will get the perms it needs.

  Sequence to land:
  1. Merge #138 (squash-merge fine — single conventional commit).
  2. Edit/reopen #137 to re-run the lint; it should pass now.
  3. Rebase-merge #137 (do NOT squash — preserve all 10 commits).
  4. release-please opens the v0.2.0 release PR; merge that normally.
  ```,
  h1-level: 4,
  label-prefix: "cc184-",
)

== Intercambio 5

=== Prompt

#cmarker.render(
  ```
  1s
  Run amannn/action-semantic-pull-request@v5
    with:
      types: feat
    fix
    docs
    chore
    ci
    refactor
    test
    perf
    build
    style
    revert

      requireScope: false
      subjectPattern: ^(?![A-Z]).+$
      subjectPatternError: The subject "{subject}" must start with a lowercase letter.
    Reference issues in the PR body via "Closes #N", not in the title.

      wip: true
      githubBaseUrl: https://api.github.com
    env:
      GITHUB_TOKEN: ***
  Error: Resource not accessible by integration
  Run amannn/action-semantic-pull-request@v5
    with:
      types: feat
    fix
    docs
    chore
    ci
    refactor
    test
    perf
    build
    style
    revert

      requireScope: false
      subjectPattern: ^(?![A-Z]).+$
      subjectPatternError: The subject "{subject}" must start with a lowercase letter.
    Reference issues in the PR body via "Closes #N", not in the title.

      wip: true
      githubBaseUrl: https://api.github.com
    env:
      GITHUB_TOKEN: ***
  Error: Resource not accessible by integration


  https://github.com/tcorzo/fiuba-gestion-tp/actions/runs/25609804159/job/75177939371?pr=137
  ```,
  h1-level: 4,
  label-prefix: "cc185-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Real cause is clearer now. Even with `pull-requests: read` granted (visible in token-perms log), the action still 403s — likely an internal API call the action makes that needs more than `pull-requests`. The repo has `default_workflow_permissions: "read"` (read-all), but my `permissions:` block in the workflow OVERRIDES that to just two scopes.

  Cleanest fix: skip the third-party action entirely. The PR title is in the event payload — no API call needed, no permissions to worry about. Replacing with a tiny inline `actions/github-script` check.
  ```,
  h1-level: 4,
  label-prefix: "cc186-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  `pull_request` run on `192b968e` → **success** ✅. The inline script approach works. The `pull_request_target` runs still fail because they use the BASE branch's workflow (main still has the old action-based version) — those will fix themselves once #138 merges.

  Let me check the latest two pending runs.
  ```,
  h1-level: 4,
  label-prefix: "cc187-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Confirmed pattern:

  - `pull_request` on the new commit: **success ×2** ✅
  - `pull_request_target` on the new commit: **failure ×2** ← uses main's old workflow (still has the broken action), will resolve once #138 merges.

  #138 is ready. Sequence:

  1. **Merge #138** (squash-merge, conventional title — will pass its own lint).
  2. Edit PR #137's title (add+remove a trailing space) to re-trigger; will pass.
  3. Rebase-merge #137 (NOT squash — must preserve all 10 commits).
  4. release-please opens the v0.2.0 release PR; merge that normally.

  Note: the `pull_request_target` workflow currently on `main` will keep failing until #138 lands. Once it's merged, both the existing pull_request_target trigger goes away (replaced by `pull_request`), and PR #137's lint will go green on next event.
  ```,
  h1-level: 4,
  label-prefix: "cc188-",
)
