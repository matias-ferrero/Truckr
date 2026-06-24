#import "@preview/cmarker:0.1.8"

= Check frontend environment variables in staging and production

_2026-06-07 04:00 UTC — rama `main` — claude-opus-4-8_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  what env vars are set for the frontend in staging and production?
  ```,
  h1-level: 4,
  label-prefix: "cc801-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  I'll search the repo for frontend env var configuration in staging/production.
  ```,
  h1-level: 4,
  label-prefix: "cc802-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Here's what the frontend gets in staging and production.

  ## Deployed frontend env vars

  Only **one** `VITE_*` variable is actually injected into staging/production builds:

  | Variable | Staging | Production | Local dev |
  |---|---|---|---|
  | `VITE_API_BASE_URL` | `https://<app_host>` (from SSM `/truckr/staging/api_base_url`) | `https://<app_host>` (from SSM `/truckr/production/api_base_url`) | `http://localhost:3000` |

  How it flows:
  - Defined in Terraform as an SSM parameter — `infra/envs/staging/main.tf:86-90` and `infra/envs/production/main.tf:98-102` (`value = "https://${module.ec2.app_host}"`).
  - Resolved at build time in `.github/workflows/frontend-deploy.yml` (`aws ssm get-parameter ... api_base_url` → `$GITHUB_ENV`), then `deno task build` inlines it via Vite.
  - Read in `frontend/src/api.ts:11-12`: `import.meta.env.VITE_API_BASE_URL ?? defaultApiBase()`.

  ## Not deployed (dev-only)

  - **`VITE_GOOGLE_MAPS_API_KEY`** — present in `frontend/.env` for local dev only. **No SSM parameter, no build-time injection in either environment.** In staging/prod the `AddressPicker` / `RadiusControl` / `CargoMapPreview` components fall back to a degraded "service unavailable" state (`?? ""` in `AddressPicker/index.tsx:65`). Worth flagging if maps are expected to work in deployed environments.

  ## Build-only (not exposed to browser)

  `TRUCKR_ENV`, `AWS_REGION` (`sa-east-1`), `FRONTEND_BUCKET`, `CFD_ID` — CI orchestration vars, not bundled.

  There are **no `.env.staging` / `.env.production` files**; everything deployed flows through SSM at CI build time.

  ---

  Noted on the AWS CLI — I'll use `--profile fiuba` (or `AWS_PROFILE=fiuba`) for any `aws` commands. I didn't run any this turn (the answer came from reading the Terraform/workflow source), but I'll apply it going forward. Want me to save that as a preference so it persists across sessions?
  ```,
  h1-level: 4,
  label-prefix: "cc803-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  VITE_GOOGLE_MAPS_API_KEY=[REDACTED_SECRET] add this env var for prod and stg
  ```,
  h1-level: 4,
  label-prefix: "cc804-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Let me look at the actual files before making changes.
  ```,
  h1-level: 4,
  label-prefix: "cc805-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  `frontend/.env` is gitignored (key lives there locally); the deployed value must flow through the SSM → CI-build pattern the repo already uses for `VITE_API_BASE_URL`. I'll add an SSM parameter in both Terraform env files and resolve it in the deploy workflow.

  One thing worth being explicit about: a `VITE_*` var is **inlined into the client bundle**, so this Google Maps key will be publicly visible in the deployed JS regardless of how we store it. That's expected for browser Maps keys — the real protection is HTTP-referrer + API restrictions in the Google Cloud Console, not secrecy. So I'm storing it as a plain `String` SSM param (consistent with `api_base_url`) rather than a `SecureString`, since SecureString would add `--with-decryption` complexity for a value that's public by design.

  Let me make the edits.
  ```,
  h1-level: 4,
  label-prefix: "cc806-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now the deploy workflow — resolve the new param from SSM and pass it into the build env:
  ```,
  h1-level: 4,
  label-prefix: "cc807-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Let me verify the CI's OIDC role can read the new param (the IAM policy may scope SSM reads to a specific path):
  ```,
  h1-level: 4,
  label-prefix: "cc808-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  No explicit `ssm:GetParameter` grant — let me read the full OIDC policy to see how the existing param reads are authorized:
  ```,
  h1-level: 4,
  label-prefix: "cc809-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  The role has `AdministratorAccess` + `ReadOnlyAccess` attached (lines 82–98), so `ssm:GetParameter` on the new param is already covered — no IAM change needed.

  Let me run `terraform fmt` to keep the HCL formatting consistent:
  ```,
  h1-level: 4,
  label-prefix: "cc810-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  All three edits are in place and the HCL formatting is clean. Let me confirm the tracked `.env.example` already documents the var (it's the template devs copy):
  ```,
  h1-level: 4,
  label-prefix: "cc811-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Done. `VITE_GOOGLE_MAPS_API_KEY` is now wired into staging and production through the same SSM → CI-build path as `VITE_API_BASE_URL`.

  ## Changes

  **`infra/envs/staging/main.tf`** and **`infra/envs/production/main.tf`** — added an SSM parameter (`/truckr/<env>/google_maps_api_key`) holding the key, with a comment noting why it's a plain `String` (public-by-design client key).

  **`.github/workflows/frontend-deploy.yml`** — the "Resolve infra from SSM" step now reads that param and exports `VITE_GOOGLE_MAPS_API_KEY` into `$GITHUB_ENV` before `deno task build`, so Vite inlines it into the bundle.

  No IAM change needed — the CI OIDC role already has `AdministratorAccess`/`ReadOnlyAccess`, which cover `ssm:GetParameter`. `.env.example` already documents the var, so nothing to add there.

  ## How it reaches each environment

  The SSM params are created by `terraform apply`, not by a normal frontend deploy. So the rollout is:

  1. **infra-apply** must run against each env to mint the new `google_maps_api_key` param. The `frontend-deploy` workflow already gates on in-progress `infra-apply` (the "Wait for in-progress infra-apply" step), so a combined push won't race into `ParameterNotFound`.
  2. Once the param exists, the next frontend deploy picks it up: push to `main` (paths `frontend/**`) → staging; a published release → production; or `workflow_dispatch` to target either.

  ## Worth flagging

  - The key is committed to the repo in the two `main.tf` files now. That's acceptable for a browser Maps key (it's already exposed in the client bundle), **but only if the key is locked down in the Google Cloud Console** with HTTP-referrer restrictions matching your CloudFront domains + the Maps APIs you actually use. If it's currently unrestricted, anyone can lift it from the deployed JS and rack up your quota. Worth confirming before this ships to production.
  - This is an infra + CI change (no `frontend/` source touched), so per CLAUDE.md it doesn't trip the frontend UI quality gate. The relevant validation is `terraform plan` via `infra-plan` on the PR.

  Want me to open a PR for this (branch + conventional-commit title), or are you handling the commit?

  I didn't need the AWS CLI this turn — everything was code/config edits — but I'll use `--profile fiuba` when I do.
  ```,
  h1-level: 4,
  label-prefix: "cc812-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  open a PR for this
  ```,
  h1-level: 4,
  label-prefix: "cc813-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  PR opened: **https://github.com/tcorzo/fiuba-gestion-tp/pull/323**

  - **Branch:** `feature/frontend-maps-key-staging-prod` (off `main`)
  - **Title:** `feat(infra): provision VITE_GOOGLE_MAPS_API_KEY for staging and production` — conventional-commit prefix, no bracket TAG, so release-please will parse it cleanly.
  - **Commit:** passed pre-commit hooks (typstyle/stylelint skipped — no matching files).

  The PR body calls out the referrer-restriction caveat and the `infra-apply`-before-deploy ordering. Next step is whoever reviews should glance at the `infra-plan` output to confirm the two new SSM params are the only adds. Want me to remember to use `--profile fiuba`-style AWS context as a persistent preference, or leave it per-session?
  ```,
  h1-level: 4,
  label-prefix: "cc814-",
)

== Intercambio 4

=== Prompt

#cmarker.render(
  ```
  remember to use --profile fiuba for aws in this repo
  ```,
  h1-level: 4,
  label-prefix: "cc815-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  I'll save that as a persistent preference.
  ```,
  h1-level: 4,
  label-prefix: "cc816-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Saved. From now on I'll use `--profile fiuba` (or `AWS_PROFILE=fiuba`) for any local `aws` CLI command in this repo, and it'll persist across sessions via the memory index.
  ```,
  h1-level: 4,
  label-prefix: "cc817-",
)
