#import "@preview/cmarker:0.1.8"

= Disable GitHub Copilot PR reviews

_2026-05-12 01:38 UTC — rama `feat/dashboard` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  Why is github copilot reviewing each PR? I want that disabled
  ```,
  h1-level: 4,
  label-prefix: "cc2032-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  No CODEOWNERS, no ruleset rule requiring Copilot. The reviews come from the repo-level **"Automatic Copilot code review"** setting, which isn't exposed by a stable REST endpoint — flip it in the UI.

  **Disable here:**
  `https://github.com/tcorzo/fiuba-gestion-tp/settings/copilot/code_review`

  Toggle off **"Automatic Copilot code review"** (and remove `copilot-pull-request-reviewer` from any auto-assign list if shown). Takes effect on the next PR.

  If it persists after that, check:
  - `https://github.com/settings/copilot/features` — your personal Copilot "code review" toggle
  - Org-level policy if this repo is ever moved under an org

  Repo state is otherwise clean — no CODEOWNERS, no ruleset requires Copilot, no workflow invokes it.
  ```,
  h1-level: 4,
  label-prefix: "cc2033-",
)
