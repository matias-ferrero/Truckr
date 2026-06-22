#import "@preview/cmarker:0.1.8"

= Understand bootstrap-environments.sh script

_2026-05-25 15:34 UTC — rama `feature/INF-INFRA-00004-phase3-infra-apply-with-environments` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  what does infra/bootstrap-environments.sh do?
  ```,
  h1-level: 4,
  label-prefix: "cc2941-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Idempotent bootstrap for INF-INFRA-00004 CD. Targets `$REPO` (default `tcorzo/fiuba-gestion-tp`).

  Actions:
  - **Envs**: `PUT /environments/staging` (no reviewers, no wait); `PUT /environments/production` with required reviewer = repo owner (resolved via `users/$OWNER` → id).
  - **Var `TFSTATE_BUCKET`**: if unset, `awk`-parses `bucket "…"` from `infra/envs/staging/backend.hcl`, sets via `gh variable set`. Warns if file missing.
  - **Secret `GHA_ROLE_ARN`**: if unset, reads `terraform -chdir=infra/envs/staging output -raw github_actions_role_arn`, sets via `gh secret set`. Warns w/ manual command on failure.
  - **Skips `SSH_CIDR`**: only prints a reminder (operator must `gh secret set SSH_CIDR --body "$(curl -s ifconfig.me)/32"`); fallback in CI is TEST-NET-1 which causes drift.

  Each step guarded by `gh … list | grep -q` so re-runs are safe. `set -euo pipefail` aborts on first failure.
  ```,
  h1-level: 4,
  label-prefix: "cc2942-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  run it against the repo
  ```,
  h1-level: 4,
  label-prefix: "cc2943-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Different error — `wait_timer` protection rule itself isn't supported on this plan. Let me check repo visibility, then drop `wait_timer` (0 is the default anyway).
  ```,
  h1-level: 4,
  label-prefix: "cc2944-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Blocked — private repo on Free plan does not support **any** Environment protection rules (wait_timer or required reviewers). The script's whole point for `production` is the required-reviewer gate, which is unavailable here.
  ```,
  h1-level: 4,
  label-prefix: "cc2945-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  What would you like to clarify? My current read: the repo is private on Free, so neither `wait_timer` nor required reviewers can be set via the Environments API — the script can't enforce a production gate as-is. Happy to expand on any of those options (e.g. what "drop protection rules" actually leaves you with for prod, or how visibility/billing changes affect OIDC trust policy) before deciding.
  ```,
  h1-level: 4,
  label-prefix: "cc2946-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  What are the protection rules?
  ```,
  h1-level: 4,
  label-prefix: "cc2947-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  GitHub Environment **protection rules** are gates the platform enforces on a workflow job that targets an `environment:` before that job starts running. There are four:

  | Rule | What it does | Used in your script |
  |---|---|---|
  | **Required reviewers** | Job pauses in a "Waiting" state until one of up to 6 listed users/teams clicks **Approve** in the Actions UI. No approval → job never runs. | ✅ Production (reviewer = repo owner = you) |
  | **Wait timer** | Job sleeps for N minutes (0–43200) after being triggered, before starting. Lets you cancel a bad deploy in a window. Your script sets `0` (off) explicitly. | ⚠️ Set to 0 on both — but even setting 0 trips the "billing plan doesn't support protection rules" error on private+Free |
  | **Deployment branches** | Restricts which branches/tags can deploy to the env (e.g. only `main` → production). | ❌ Not set |
  | **Custom rules** | Third-party gates (Datadog, ServiceNow, etc. via GitHub Apps). | ❌ Not set |

  Two related env features that are **NOT protection rules** and work on any plan:
  - **Environment secrets / variables** — scoped to the env name. `apply` job pulling `GHA_ROLE_ARN` only when `environment: production` is set.
  - **OIDC subject claim** — the JWT GitHub mints includes `environment:production`, so your AWS IAM trust policy can require it. This is the real security boundary; protection rules are convenience on top.

  **The practical impact for you:** on private + Free, you can still create the `staging` and `production` envs (option 1) and they'll still scope OIDC and secrets — you just lose the "click Approve before prod deploys" UX. The deploy still has to be triggered from `main`, run by someone with write access, and assume an IAM role whose trust policy pins `environment:production`. The protection rule was belt-and-suspenders on top of that.
  ```,
  h1-level: 4,
  label-prefix: "cc2948-",
)

== Intercambio 4

=== Prompt

#cmarker.render(
  ```
  drop protection rules and re-run
  ```,
  h1-level: 4,
  label-prefix: "cc2949-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Bootstrap complete on `tcorzo/fiuba-gestion-tp`.

  **State now:**
  - Envs `staging` and `production` exist, `protection_rules: []` (private+Free plan limitation — production has no platform-level approval gate; rely on branch protection on `main` + IAM trust policy pinning `environment:production`).
  - Repo var `TFSTATE_BUCKET=truckr-tfstate-000946353046` ✅
  - Repo secrets `GHA_ROLE_ARN`, `SSH_CIDR` ✅

  **Script changes** (`infra/bootstrap-environments.sh`):
  - Dropped `wait_timer=0` and `reviewers[]` from both env PUTs (unsupported on private+Free).
  - Added inline NOTE explaining why protection rules are absent and what enforces production safety instead.
  ```,
  h1-level: 4,
  label-prefix: "cc2950-",
)
