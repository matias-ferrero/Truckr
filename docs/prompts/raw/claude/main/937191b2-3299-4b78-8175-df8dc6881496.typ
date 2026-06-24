#import "@preview/cmarker:0.1.8"

= Add Google Maps API key to backend environment

_2026-06-20 01:50 UTC — rama `main` — claude-opus-4-8_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  add GOOGLE_MAPS_API_KEY=[REDACTED_SECRET] to backend env var in production and staging
  ```,
  h1-level: 4,
  label-prefix: "cc818-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  I'll look at how the backend manages environment variables/secrets for deployment.
  ```,
  h1-level: 4,
  label-prefix: "cc819-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  The secret pattern is clear: SSM Parameter Store → `.kamal/secrets` (fetch) → `deploy.yml` `env.secret`. Let me check the CI workflow and any infra/terraform that declares these SSM params.
  ```,
  h1-level: 4,
  label-prefix: "cc820-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Let me see how the SSM module is wired into each env and how secret values flow through infra-apply.
  ```,
  h1-level: 4,
  label-prefix: "cc821-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  The `google_maps_api_key` SSM parameter **already exists** in staging's terraform (line 97-101) with the exact value you provided — currently consumed by the frontend build. So the infra side is done; I just need to wire it into the **backend** container. Let me confirm production has the same SSM param and check how the frontend fetches it for style consistency.
  ```,
  h1-level: 4,
  label-prefix: "cc822-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Both envs already have the SSM param (plain `String`, fetched without `--with-decryption`). The infra is done — I only need to wire it into the backend container via two files: `.kamal/secrets` (fetch) and `deploy.yml` (`env.secret`).
  ```,
  h1-level: 4,
  label-prefix: "cc823-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  I need to Read `.kamal/secrets` before editing it (I'd only seen it via `cat`).
  ```,
  h1-level: 4,
  label-prefix: "cc824-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Both files are wired. Let me verify the final state of both edits.
  ```,
  h1-level: 4,
  label-prefix: "cc825-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Done. `GOOGLE_MAPS_API_KEY` is now injected into the backend container in both staging and production.

  ## What I found

  The SSM parameter `/truckr/{staging,production}/google_maps_api_key` **already existed** in Terraform (`infra/envs/*/main.tf`) with the exact value you gave — it was minted for the frontend build (`VITE_GOOGLE_MAPS_API_KEY`). So no new infra/secret value was needed; the key just wasn't reaching the Rails container.

  ## Changes (2 files)

  1. **`backend/.kamal/secrets`** — added a fetch line that reads the existing SSM param into `GOOGLE_MAPS_API_KEY` at deploy time. It's a plain `String` (public-by-design, referrer-restricted), so no `--with-decryption`, matching how `frontend-deploy.yml` reads the same param.
  2. **`backend/config/deploy.yml`** — listed `GOOGLE_MAPS_API_KEY` under `env.secret` so Kamal passes it into the container.

  Both envs are covered automatically: `.kamal/secrets` interpolates `${TRUCKR_ENV}`, which the deploy workflow sets to `staging` (push to main) or `production` (release). No plaintext key lands in the repo.

  ## To apply it
  - **Staging:** merge to `main` (CI `backend-deploy.yml` redeploys staging — note it triggers on `backend/**` changes, which this is).
  - **Production:** publish a release, or run the `backend-deploy` workflow manually with `env: production`.

  One note: this exposes the **same** key the SPA already ships publicly. If the backend will call server-side Google APIs (Geocoding/Distance Matrix), that traffic isn't HTTP-referrer-constrained, so you may eventually want a separate server-restricted key in a SecureString param — but that's a follow-up, not needed for what you asked.

  Want me to commit this on a branch?
  ```,
  h1-level: 4,
  label-prefix: "cc826-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  commit this on a branch
  ```,
  h1-level: 4,
  label-prefix: "cc827-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Committed on `feature/backend-google-maps-api-key` (`b0cb5025`). Pre-commit hooks passed.

  Want me to push and open a PR? Heads up: the PR will trigger the full backend CI (RSpec) since it touches `backend/**`, and merging to `main` will redeploy staging automatically.
  ```,
  h1-level: 4,
  label-prefix: "cc828-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  push and open a PR
  ```,
  h1-level: 4,
  label-prefix: "cc829-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  PR opened: **https://github.com/tcorzo/fiuba-gestion-tp/pull/356**

  - Branch `feature/backend-google-maps-api-key` pushed.
  - Title starts with a conventional type (`feat(backend):`) so release-please will pick it up as a minor bump.
  - Reminder: merging to `main` auto-redeploys **staging**; production gets the key on the next release (or a manual `backend-deploy` run with `env: production`).
  ```,
  h1-level: 4,
  label-prefix: "cc830-",
)

== Intercambio 4

=== Prompt

#cmarker.render(
  ```
  do i need to config anything manually?
  ```,
  h1-level: 4,
  label-prefix: "cc831-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Good question — let me verify the GitHub Actions IAM role can already read the new param (the deploy fetches it via `aws ssm get-parameter`).
  ```,
  h1-level: 4,
  label-prefix: "cc832-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  The GHA deploy role attaches `AdministratorAccess` (`github_oidc/main.tf:97`), so it can already read the new param — no IAM change. Let me confirm the SSM param has actually been applied to AWS (not just declared in Terraform), since that determines whether you need to do anything.
  ```,
  h1-level: 4,
  label-prefix: "cc833-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  The param was merged 13 days ago (#323) and the frontend deploy has been consuming it since, so it's applied. Let me confirm it actually exists in AWS for both envs to be certain.
  ```,
  h1-level: 4,
  label-prefix: "cc834-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  No manual config needed. I verified the whole chain:

  - **SSM params exist in AWS** — confirmed live for both `staging` and `production` (`/truckr/<env>/google_maps_api_key` = your key). They were applied 13 days ago via #323 for the frontend, so there's nothing to `put-parameter`.
  - **IAM is covered** — the GitHub Actions deploy role attaches `AdministratorAccess` (`github_oidc/main.tf:97`), so it can already `ssm:GetParameter` the new key. No Terraform/infra change.

  So the only thing required is **merging PR #356**. After that:

  - **Staging:** deploys automatically on merge to `main` (touches `backend/**`).
  - **Production:** picks up the key on the next release, or run the `backend-deploy` workflow manually with `env: production`.

  After a deploy, you can confirm inside the container with:
  ```sh
  cd backend && bundle exec kamal app exec 'printenv GOOGLE_MAPS_API_KEY'
  ```

  One caveat unchanged from before: this is the SPA's public, referrer-restricted key. If the backend starts making server-side Google API calls, those aren't referrer-constrained — at that point you'd want a separate server-restricted key. Not needed to ship this.
  ````,
  h1-level: 4,
  label-prefix: "cc835-",
)

== Intercambio 5

=== Prompt

#cmarker.render(
  ```
  merge the PR
  ```,
  h1-level: 4,
  label-prefix: "cc836-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Let me check the PR's CI status before merging.
  ```,
  h1-level: 4,
  label-prefix: "cc837-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  All checks pass (lint, scan_js, scan_ruby, test). State is `BLOCKED` though — likely a required review. Let me attempt the squash merge.
  ```,
  h1-level: 4,
  label-prefix: "cc838-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Branch protection is blocking the merge — it requires an approving review (all CI checks themselves passed). I can't satisfy a required review myself. Two options:
  ```,
  h1-level: 4,
  label-prefix: "cc839-",
)

== Intercambio 6

=== Prompt

#cmarker.render(
  ```
  [Request interrupted by user for tool use]
  ```,
  h1-level: 4,
  label-prefix: "cc840-",
)

== Intercambio 7

=== Prompt

#cmarker.render(
  ```
  i merged it manually, but how is the value set in ssm?
  ```,
  h1-level: 4,
  label-prefix: "cc841-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  The value is set **declaratively in Terraform** — it's a literal string in the SSM module's resource, applied by the `infra-apply` workflow. Here's the full picture:

  In `infra/envs/staging/main.tf` (and identically in `production/main.tf`):

  ```hcl
  resource "aws_ssm_parameter" "google_maps_api_key" {
    name  = "/${local.project}/${local.env}/google_maps_api_key"
    type  = "String"   # not SecureString — public-by-design SPA key, no KMS
    value = "AIzaSyDeiqlsSlKze0BR6SsdGlPGpLh_fqDb2NY"
  }
  ```

  So the chain is:
  1. The key is **hardcoded in the Terraform resource** (added in #323, merged 2026-06-07).
  2. `terraform apply` (via the `infra-apply` GitHub workflow) writes that literal into Parameter Store at `/truckr/<env>/google_maps_api_key`.
  3. Deploys read it back out: the frontend build as `VITE_GOOGLE_MAPS_API_KEY`, and now — after your merge — the backend container as `GOOGLE_MAPS_API_KEY` via `.kamal/secrets`.

  **Important contrast with `rails_master_key`:** that one carries a `lifecycle { ignore_changes = [value] }` block, so Terraform bootstraps it once and then stops managing the value (it's rotated out-of-band via `aws ssm put-parameter --overwrite`). The maps key has **no such block** — Terraform fully owns its value.

  Practical consequence: to **change** the maps key, edit the literal in both `infra/envs/{staging,production}/main.tf` and re-apply. Don't `aws ssm put-parameter --overwrite` it directly — without `ignore_changes`, the next `terraform apply` would just revert it back to the hardcoded value and show a drift diff in the meantime.

  One note since it's a `String` (not `SecureString`): the value is stored unencrypted and visible to anyone with `ssm:GetParameter` — which is fine for this referrer-restricted public SPA key, but if you ever add a server-restricted backend key, that one should be a `SecureString`.
  ````,
  h1-level: 4,
  label-prefix: "cc842-",
)

== Intercambio 8

=== Prompt

#cmarker.render(
  ```
  wait, if the value is set in main.tf then it is public...
  ```,
  h1-level: 4,
  label-prefix: "cc843-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Yes — it's public, and it always was. Let me be precise about what that does and doesn't mean.

  **For a Google Maps *JS* API key, public is the normal state.** Vite inlines `VITE_*` vars straight into the client bundle, so this key ships in plain text in the SPA's JavaScript — anyone can open devtools and read it off your production site. So whether or not it's also in `main.tf` in git changes nothing about its exposure: the browser already hands it to every visitor. That's why the Terraform comment marks it `String`, not `SecureString` — secrecy was never the protection mechanism.

  **The actual protection for a browser key is in the Google Cloud Console, not secrecy:**
  - **HTTP-referrer restrictions** — the key only works when the request comes from your domains (your CloudFront/SPA origins).
  - **API restrictions** — the key is limited to just the Maps APIs you use (e.g. Maps JavaScript API, not billing-heavy ones).
  - **Quotas / budget alerts** — cap the blast radius if someone scrapes it and hammers it.

  If those three are set, a leaked-by-design browser key is fine. **Worth checking right now** that they're actually configured on this key in the console — that's the thing that matters, not the git visibility.

  **The real wrinkle is the change you just shipped.** You now also inject this same key into the *backend*. Server-side Google API calls (Geocoding, Distance Matrix, etc.) **do not send an HTTP-referrer header**, so the referrer restriction that protects the browser key gives the backend *zero* protection. If the backend ever calls a Google API with this key, anyone who scraped it from your SPA could make the same server-side calls against your billing.

  So the honest takeaway:
  - If the backend only needs the key to **hand it back to the browser** (or does nothing referrer-sensitive), reusing the public key is harmless.
  - If the backend makes **server-side Google API calls**, it should use a **separate key** that is *application-restricted by server IP* (not referrer), stored as a `SecureString` in SSM, and locked to only the server-side APIs it needs.

  Do you know yet which case the backend is — passing it to the browser, or calling Google APIs server-side? That determines whether you're done or whether we should mint a second, properly-restricted key.
  ```,
  h1-level: 4,
  label-prefix: "cc844-",
)

== Intercambio 9

=== Prompt

#cmarker.render(
  ```
  the backend calls google apis server-side
  ```,
  h1-level: 4,
  label-prefix: "cc845-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  That changes things — reusing the public, referrer-restricted key for server-side calls is a real exposure: a scraped key works against your billing with no referrer to stop it. The fix is a **separate, IP-restricted key** for the backend. Let me ground this in your actual setup first.
  ```,
  h1-level: 4,
  label-prefix: "cc846-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  Confirmed the exposure is real. `distance_service.rb:12` reads `ENV["GOOGLE_MAPS_API_KEY"]` and calls the **Routes API** server-side (`routes.googleapis.com/directions/v2:computeRoutes`, line 8) with an `X-Goog-Api-Key` header — no referrer involved.

  This also means your **current state is already broken or already exploitable**, one or the other:
  - If the public SPA key *is* referrer-restricted → these server-side Routes calls get rejected by Google (no referrer header), and `fetch_km` silently returns `nil` (errors are swallowed at line 48). The distance feature isn't actually working in staging/prod.
  - If the calls *are* succeeding → the SPA key has **no application restriction**, i.e. it's a fully unrestricted key sitting in your public JS bundle. Anyone can lift it and bill Routes/Maps to your account.

  Either way, the fix is the same: a **separate, IP-restricted key** for the backend.

  ## The plan

  **Two server EC2 egress IPs** (from SSM `app_host`):
  - staging → `[REDACTED_IP]`
  - production → `[REDACTED_IP]`

  **Step 1 — create the backend key(s) in Google Cloud Console** *(only you can do this — I have no console/gcloud access here):*
  - Create a new API key per environment (cleanest for blast-radius isolation; or one key restricted to both IPs if you'd rather manage one).
  - **Application restriction → IP addresses** → that env's IP above. *Not* HTTP referrers.
  - **API restriction → Routes API** only (that's the single API `distance_service.rb` uses).
  - Leave the existing public SPA key exactly as-is for the frontend.

  **Step 2 — store as SecureString SSM params** (I can run these once you paste the key values, using `--profile fiuba`):
  ```
  /truckr/staging/google_maps_server_api_key     (SecureString)
  /truckr/production/google_maps_server_api_key  (SecureString)
  ```

  **Step 3 — rewire the backend to read the new param** (I'll do this): point `.kamal/secrets`'s `GOOGLE_MAPS_API_KEY` line at `google_maps_server_api_key` with `--with-decryption`. The container env var name stays `GOOGLE_MAPS_API_KEY`, so **no code change** to `distance_service.rb`. `deploy.yml` stays as-is.

  **Sequencing matters:** the SSM params must exist *before* that wiring deploys — `.kamal/secrets` has no `|| echo ""` fallback on this line, so a missing param hard-fails the Kamal deploy. So: create key → put SSM params → then merge the rewire.

  One open question on how to track the new secret param in Terraform:
  ````,
  h1-level: 4,
  label-prefix: "cc847-",
)

== Intercambio 10

=== Prompt

#cmarker.render(
  ```
  [Request interrupted by user for tool use]
  ```,
  h1-level: 4,
  label-prefix: "cc848-",
)
