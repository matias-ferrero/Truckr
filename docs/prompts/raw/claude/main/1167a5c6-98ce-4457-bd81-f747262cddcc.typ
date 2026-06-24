#import "@preview/cmarker:0.1.8"

= Check Imagick deployment status in staging

_2026-06-22 21:34 UTC — rama `feature/backend-google-maps-api-key` — claude-opus-4-8_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  is imagick deployed in staging?
  ```,
  h1-level: 4,
  label-prefix: "cc148-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  I'll check the backend deploy config and Dockerfile for ImageMagick.
  ```,
  h1-level: 4,
  label-prefix: "cc149-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Yes. Let me confirm line 19 is in the final runtime image (not just the build stage).
  ```,
  h1-level: 4,
  label-prefix: "cc150-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Yes — ImageMagick is in the staging image.

  It's installed in the Dockerfile's `base` stage (`backend/Dockerfile:19`), and the final runtime stage is built `FROM base` (line 61), so `imagemagick` carries into the image that Kamal ships to staging. It's also added to the throwaway `build` stage (line 35) for gem compilation, but the line 19 install is what matters for runtime.

  It's actually wired up as the Active Storage variant processor too: `config/application.rb:60` sets `config.active_storage.variant_processor = :mini_magick` (with `image_processing` in the Gemfile), deliberately choosing ImageMagick over the Rails 8 default of libvips. So image variants in staging go through ImageMagick.
  ```,
  h1-level: 4,
  label-prefix: "cc151-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  fix frontend, not rendering vehicle image correctly Acceso a la red local detectado: sitio de nivel superior “https://d1ln6zq4mn5erj.cloudfront.net/”, iniciador “https://d1ln6zq4mn5erj.cloudfront.net/”, accediendo al destino “https://localhost:3000/rails/active_storage/representations/redirect/eyJfcmFpbHMiOnsiZGF0YSI6MywicHVyIjoiYmxvYl9pZCJ9fQ==--5332ac547ebbbb3363ab4a09b67227b6ffe9690d/eyJfcmFpbHMiOnsiZGF0YSI6eyJmb3JtYXQiOiJqcGciLCJyZXNpemVfdG9fZmlsbCI6WzYwMCw0MDBdfSwicHVyIjoidmFyaWF0aW9uIn19--1aa9b1a0b8e01c234990ac31ab233fef8444e07b/Kangoo%205%20a.jpg” (127.0.0.1:3000) vía https. Contexto seguro: True, solicitud de acción: (null)
  ```,
  h1-level: 4,
  label-prefix: "cc152-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Let me investigate how vehicle images are served and rendered.
  ```,
  h1-level: 4,
  label-prefix: "cc153-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  The root cause is backend-side (`localhost:3000` is baked into the absolute image URLs), but the most robust fix is to have the backend emit **relative** paths and let the frontend resolve them against its already-correct `API_BASE_URL`. That decouples image rendering from backend host/port config entirely — which is exactly the "fix it on the frontend" angle, and it fixes dev too.

  Let me read the key files.
  ```,
  h1-level: 4,
  label-prefix: "cc154-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Let me check the deploy/env config and existing tests so the fix doesn't break anything.
  ```,
  h1-level: 4,
  label-prefix: "cc155-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  No specs assert the URL host, so making paths relative is safe. Now let me look at the frontend render sites and the vehicles API type.
  ```,
  h1-level: 4,
  label-prefix: "cc156-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  I have the full picture. The fix:

  - **Backend** (`vehicle.rb`): emit **backend-relative** paths (`polymorphic_path`) instead of absolute `url_for` — no host/port baked in, so `localhost:3000` can never leak.
  - **Frontend** (`api.ts` + 3 img sites): resolve those relative paths against `API_BASE_URL` (which is already correctly set to the staging backend at build time). Absolute URLs pass through untouched, so it's backward-compatible.

  Let me make the edits.
  ```,
  h1-level: 4,
  label-prefix: "cc157-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  The backend edit was reverted — the model keeps returning absolute `url_for` URLs. That signals you want this fixed purely on the frontend (matching your "fix frontend" ask). I'll adapt: instead of resolving relative paths, `mediaUrl` will **re-host** the URL — keep the Active Storage path but swap the (wrong `localhost:3000`) origin for the SPA's configured `API_BASE_URL`. This handles both absolute and relative values uniformly.
  ```,
  h1-level: 4,
  label-prefix: "cc158-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now apply `mediaUrl` at the three `Imagen` sites. Let me read each render context.
  ```,
  h1-level: 4,
  label-prefix: "cc159-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now let me check the imports in each file and apply the edits.
  ```,
  h1-level: 4,
  label-prefix: "cc160-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now I'll add the `mediaUrl` import and apply it at each site.
  ```,
  h1-level: 4,
  label-prefix: "cc161-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now let me add tests for `mediaUrl` and verify types/lint pass. Let me check for an existing api test file.
  ```,
  h1-level: 4,
  label-prefix: "cc162-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  I'll add a focused unit test for `mediaUrl`.
  ```,
  h1-level: 4,
  label-prefix: "cc163-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  The `URL.host` setter retains an existing port when the new value has none — a known quirk. I'll rebuild from `base.origin` + the parsed path instead, which sidesteps it.
  ```,
  h1-level: 4,
  label-prefix: "cc164-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  All 4 pass. Now let me verify the existing vehicle page tests still pass and typecheck/lint is clean.
  ```,
  h1-level: 4,
  label-prefix: "cc165-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Build + typecheck pass. Let me confirm there are no other photo-render sites I missed.
  ```,
  h1-level: 4,
  label-prefix: "cc166-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  All three render sites now route through `mediaUrl`, and no others exist. Done.

  ## What was wrong

  The deployed SPA (CloudFront) rendered vehicle `Imagen` tags with `src="https://localhost:3000/rails/active_storage/representations/..."`. The backend (`Vehicle#photo_variants`) serializes Active Storage URLs with `url_for`, which produces **absolute** URLs using whatever `default_url_options` resolves to at boot — `localhost:3000` outside a request context (`config/initializers/default_url_options.rb:8`). The frontend rendered that host verbatim, and the browser blocked it as a local-network access.

  ## The fix (frontend-only)

  A new `mediaUrl()` helper in `frontend/src/api.ts` re-hosts any backend media reference onto the SPA's already-correct `API_BASE_URL` (resolved from SSM at build time): it keeps the path/query and swaps the origin. Applied at all three vehicle-image sites:

  - `src/pages/carrier/VehicleForm.tsx:399`
  - `src/pages/carrier/VehicleList.tsx:195`
  - `src/pages/public/CarrierDetail.tsx:386`

  It's defensive — absolute URLs (wrong host), backend-relative paths, and `data:`/empty values all handled, and it's a no-op in dev where the bases already match. One subtlety handled: rebuilt from `base.origin` rather than mutating `URL.host`, because the host setter retains a stale `:3000` port.

  ## Verification

  - New `src/api.test.ts` — 4 cases (re-host absolute, resolve relative, preserve query, pass through data/empty): pass.
  - Existing VehicleList / VehicleForm / CarrierDetail tests (26): pass.
  - `deno task build` (tsc typecheck + Vite build): clean.

  ## Notes

  - I left `backend/app/models/vehicle.rb` on `url_for` since that revert looked intentional. The frontend fix fully resolves the rendered-image bug on its own.
  - Latent, unrelated: `production.rb` sets the mailer host to `example.com`, so **email** links (not images) would also be wrong in deploys unless `APP_HOST` is injected. Out of scope here — flag it if you want it addressed.
  ```,
  h1-level: 4,
  label-prefix: "cc167-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  commit and push to a new branch
  ```,
  h1-level: 4,
  label-prefix: "cc168-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  The backend `polymorphic_path` change is actually in the working tree — the earlier "revert" reminder was a stale snapshot. So the real state is coherent: backend emits **relative** paths, frontend `mediaUrl` resolves them against `API_BASE_URL`. But my frontend comment still says the backend emits absolute URLs, which is now inaccurate. Let me reconcile it before committing.
  ```,
  h1-level: 4,
  label-prefix: "cc169-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Let me verify the backend `polymorphic_path` change actually works (it's the riskiest assumption) by running the vehicle specs, and re-run the frontend tests.
  ```,
  h1-level: 4,
  label-prefix: "cc170-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Backend specs pass — `polymorphic_path` works. Now the frontend tests plus CSS lint (no CSS changed, but the gate runs it on the branch), then commit to a new branch.
  ```,
  h1-level: 4,
  label-prefix: "cc171-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now create the branch off `main`, commit, and push.
  ```,
  h1-level: 4,
  label-prefix: "cc172-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Done. Committed and pushed to a new branch off `main`.

  - **Branch:** `fix/vehicle-image-host-rehost` (tracking `origin/main`)
  - **Commit:** `fix(vehicles): serve vehicle photos from the API origin, not localhost:3000`
  - Pre-commit hooks passed; backend vehicle specs (54) and the affected frontend tests (30) are green.

  GitHub printed the PR-create link:
  https://github.com/tcorzo/fiuba-gestion-tp/pull/new/fix/vehicle-image-host-rehost

  Want me to open the PR? If so, note the CLAUDE.md gate — a frontend-touching PR expects `/critique` → `/polish` → `/audit` plus `just frontend-test-coverage` and `just frontend-test-e2e` to be run first. This change is logic-only (no new UI/markup beyond swapping `src` values), so the visual skills add little here, but I can run the coverage/e2e gates before opening if you'd like.
  ```,
  h1-level: 4,
  label-prefix: "cc173-",
)

== Intercambio 4

=== Prompt

#cmarker.render(
  ```
  open the PR
  ```,
  h1-level: 4,
  label-prefix: "cc174-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  PR opened: https://github.com/tcorzo/fiuba-gestion-tp/pull/363

  Title is a conventional `fix(...)` so release-please will parse it for a patch bump. Body explains the problem/fix, lists the test evidence, and flags the unrelated mailer-host follow-up. CI will now run the full gate on the PR.
  ```,
  h1-level: 4,
  label-prefix: "cc175-",
)

== Intercambio 5

=== Prompt

#cmarker.render(
  ```
  why was the frontend requesting vehicle photos from localhost?
  ```,
  h1-level: 4,
  label-prefix: "cc176-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  Because the `localhost:3000` was baked into the image URL by the **backend**, not chosen by the frontend. The frontend just rendered whatever string the API gave it.

  Here's the chain:

  **1. The backend builds an absolute URL with a hardcoded host.**
  `Vehicle#photo_variants` generated photo URLs with `url_for(photo.variant(...))`. `url_for` produces a *fully-qualified* URL — it needs a host, and it gets it from `Rails.application.routes.default_url_options`.

  **2. That host defaults to `localhost:3000`.**
  In `config/initializers/default_url_options.rb`:
  ```ruby
  host = ENV.fetch("APP_HOST", "localhost")
  port = ENV.fetch("PORT", "3000").to_i
  ```
  `APP_HOST` wasn't set in the staging container, so it fell back to `localhost`, port `3000`.

  **3. There's a subtlety: this runs *outside* a web request.**
  Normally, when Rails generates URLs *inside* a controller, it can infer the host from the incoming request's `Host` header. But these photo URLs are built in a **serializer** (`VehicleResource` → `photo_variants`), which has no request context. So it can't infer anything — it falls back entirely to `default_url_options`, i.e. `localhost:3000`. That's why even the correct staging request produced a `localhost` URL.

  **4. The backend then hands that string to the frontend in JSON:**
  ```json
  { "photos": [{ "card": "https://localhost:3000/rails/active_storage/representations/redirect/..." }] }
  ```

  **5. The frontend renders it verbatim.**
  `Imagen` — no transformation. The SPA's own API client (`API_BASE_URL`) was correctly pointed at the staging backend, but that only governs *fetch calls the frontend makes itself*. It never touched the absolute URLs embedded inside response bodies. So the `Imagen` pointed at `localhost:3000`, the user's browser resolved that to *their own machine*, found nothing (or got blocked as local-network access), and the image failed.

  So "the frontend was requesting from localhost" is really "the backend told the frontend to request from localhost." The fix attacks both halves: the backend now emits a host-less relative path, and the frontend resolves it against the API origin it already knows.
  ````,
  h1-level: 4,
  label-prefix: "cc177-",
)

== Intercambio 6

=== Prompt

#cmarker.render(
  ```
  so shouldnt the solution be adding APP_HOST and PORT env vars to staging and production>
  ```,
  h1-level: 4,
  label-prefix: "cc178-",
)

== Intercambio 7

=== Prompt

#cmarker.render(
  ```
  so shouldnt the solution be adding APP_HOST and PORT env vars to staging and production?
  ```,
  h1-level: 4,
  label-prefix: "cc179-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  It would *work*, but it's more fragile than "just add two env vars," and it leaves the backend owning a fact it shouldn't. Let me be concrete about why, because the gotchas are real.

  ## Setting `APP_HOST`/`PORT` alone wouldn't actually produce a clean URL

  Look at what the initializer does with them:

  ```ruby
  host = ENV.fetch("APP_HOST", "localhost")
  port = ENV.fetch("PORT", "3000").to_i
  Rails.application.routes.default_url_options = { host: host, port: port }
  ```

  Two traps:

  1. **The port is *always* appended.** There's no "omit port for 80/443" logic. So even if you set `APP_HOST=api.staging.example.com` and leave `PORT` unset, it falls back to `3000` and you get `https://api.staging.example.com:3000/rails/...` — still wrong. The container actually runs behind Thruster on port 80, so the real-world `PORT` doesn't match the externally-visible port anyway. To get a clean host you'd have to *also* change the initializer to drop the port for standard ports.

  2. **No scheme.** `default_url_options` here has no `:protocol`, so `url_for` defaults to `http://`. Behind CloudFront/TLS you want `https://`. Another thing to wire (force_ssl or an explicit protocol).

  So the env-var route is really "set `APP_HOST` **and** fix the initializer to omit the port **and** force https." That's three correct moving parts versus removing the problem.

  ## The deeper reason: who should know the backend's public host?

  The frontend *already* knows where its backend lives — `API_BASE_URL`, resolved from SSM at build time. The env-var approach duplicates that knowledge into a second place (`APP_HOST`) that has to be kept in sync and can drift. The relative-path approach keeps a single source of truth: the backend emits host-less paths, and the one component that knows the backend origin resolves them. It's also automatically correct in dev and in the parallel-worktree setup (random ports), where a baked-in `APP_HOST:PORT` would be wrong.

  ## But you're not wrong — `APP_HOST` *is* still needed

  For URLs that genuinely can't be relative because they're consumed outside the app: **email links**. `production.rb` currently sets the mailer host to `example.com`, so password-reset / notification emails in staging/prod are broken in exactly the way the photos were. That one *does* need a correct `APP_HOST` (and the port/scheme handling fixed), because there's no frontend to re-host a link inside an email.

  So the right split is:
  - **Image URLs** → relative + frontend-resolve (what the PR does). Removes the failure mode instead of configuring around it.
  - **`APP_HOST` + initializer port/scheme fix** → still worth doing, but for the *mailer*, which I flagged as a follow-up.

  If you'd prefer the env-var route for the images too, I can do it — but it's a code change to the initializer, not just an infra tweak, and it couples image URLs to a correctly-maintained backend host forever. Want me to set up the `APP_HOST` fix for the mailer as a separate change?
  ````,
  h1-level: 4,
  label-prefix: "cc180-",
)

== Intercambio 8

=== Prompt

#cmarker.render(
  ```
  check in aws fiuba profile, the backend url and port for both staging and production and add those env vars to backend
  ```,
  h1-level: 4,
  label-prefix: "cc181-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  I'll query AWS SSM (which the frontend deploy already reads `api_base_url` from) using the `fiuba` profile.
  ```,
  h1-level: 4,
  label-prefix: "cc182-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  `app_host` already exists in SSM for both envs (HTTPS, no port → standard 443, so `PORT` should *not* be 3000). Now let me see how `GOOGLE_MAPS_API_KEY` was injected so I replicate the pattern for `APP_HOST`.
  ```,
  h1-level: 4,
  label-prefix: "cc183-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Clear pattern. `APP_HOST` differs per env, so it must come from the SSM `app_host` param via the secret channel (same as the maps key), not a literal in `clear`. Let me read both files fully.
  ```,
  h1-level: 4,
  label-prefix: "cc184-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  `APP_HOST` is already resolved by CI and used for `proxy.host` (deploy.yml:18) — but it's **not** injected into the Rails container env, which is why the initializer never sees it. Both env URLs are HTTPS with no explicit port (→ 443), so I also need the scheme right, not just the host. Let me check exactly what the deploy workflow exports before I wire it.
  ```,
  h1-level: 4,
  label-prefix: "cc185-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  CI already exports `APP_HOST` to the deploy env (line 125), so I can pass it into the container the same way `FRONTEND_ORIGIN` is (deploy.yml:39). But the URLs are HTTPS on the implicit 443 port — so just adding `APP_HOST` would still yield `http://host:3000`. I need the scheme and port handled too. Let me check `production.rb` for `force_ssl`/mailer host before deciding the exact knobs.
  ```,
  h1-level: 4,
  label-prefix: "cc186-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now I have everything. Key facts:
  - CI already exports `APP_HOST` to the deploy env (backend-deploy.yml:125) but never injects it into the container.
  - `production.rb` has `force_ssl = true` / `assume_ssl = true`, so I can derive the `https` scheme from `force_ssl` instead of inventing a protocol env var.
  - The URLs are HTTPS on implicit 443 → the port must be **omitted** for canonical URLs (`https://host`, not `https://host:443`).
  - The mailer host is still `example.com` (production.rb:62) — same bug class.

  Let me check for any specs that assert on URL hosts or the initializer before editing.
  ```,
  h1-level: 4,
  label-prefix: "cc187-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  No specs depend on it — low risk. Let me create a new branch off `main` (separate concern from the image-rendering PR #363) and make the three changes.
  ```,
  h1-level: 4,
  label-prefix: "cc188-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now let me verify the initializer produces correct URLs in production mode. I'll boot Rails with the deployed env vars and check actual URL generation, then run lint and the deploy-config render.
  ```,
  h1-level: 4,
  label-prefix: "cc189-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  `default_url_options` is now `{host: "ip-18-228-83-21.sslip.io", protocol: "https"}` — correct host, https scheme, **no port**. Mailer matches. Let me confirm dev behavior is preserved (localhost:3000) and that a real URL helper renders cleanly.
  ```,
  h1-level: 4,
  label-prefix: "cc190-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Dev fallback preserved (`localhost:3000`), prod renders `https://ip-18-228-83-21.sslip.io/up`. Now lint + the full backend suite (the gate, since this touches `backend/`).
  ```,
  h1-level: 4,
  label-prefix: "cc191-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Full backend suite green (827 examples, 0 failures). Let me sanity-check that the `deploy.yml` ERB still renders to valid YAML (e.g. when `APP_HOST` is unset on a laptop, mirroring how `FRONTEND_ORIGIN` already behaves).
  ```,
  h1-level: 4,
  label-prefix: "cc192-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Renders valid YAML; in CI `APP_HOST` is always set (resolved at backend-deploy.yml:116), so the container gets the real value. Everything checks out. Let me commit and push.
  ```,
  h1-level: 4,
  label-prefix: "cc193-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Done. Opened **PR #364**: https://github.com/tcorzo/fiuba-gestion-tp/pull/364

  ## What I found in AWS (SSM, `fiuba` profile)

  Both environments already had `app_host` and `api_base_url` parameters:

  | Env | host | URL | port |
  |---|---|---|---|
  | staging | `ip-18-228-83-21.sslip.io` | `https://ip-18-228-83-21.sslip.io` | 443 (implicit https) |
  | production | `ip-18-229-228-145.sslip.io` | `https://ip-18-229-228-145.sslip.io` | 443 (implicit https) |

  The key discovery: `APP_HOST` was *already* resolved by CI — but only for Kamal's `proxy.host`. It was never injected into the **container env** that Rails reads, which is exactly why `default_url_options` fell back to `localhost:3000`.

  ## What I added to the backend

  1. **`deploy.yml`** — injected `APP_HOST` into `env.clear` (ERB passthrough, same pattern as `FRONTEND_ORIGIN`).
  2. **`default_url_options.rb`** — hardened it: scheme from `force_ssl` (→ `https` in prod), and the port **omitted** for standard 443/80. This matters because just setting `APP_HOST` would otherwise have produced `http://host:3000` — the exact fragility I flagged earlier.
  3. **`production.rb`** — pointed the mailer host at `APP_HOST` instead of `example.com`.

  On the **port**: there's no separate port env var because the deployed port is 443 (implicit in https) — pinning it would yield non-canonical `https://host:443`. If you specifically want an explicit `APP_PORT` wired, the initializer already honors it; just say so.

  ## Verified
  - Prod: `default_url_options = {host: <app_host>, protocol: "https"}`, `up_url` → `https://<host>/up`.
  - Dev unchanged: `http://localhost:3000`.
  - Rubocop clean, full RSpec suite green (827 examples, 0 failures), `deploy.yml` ERB renders valid YAML.

  This is a separate PR from #363 (image rendering) since it fixes `default_url_options` for **all** absolute URLs — most importantly mailer links, which the SPA can't re-host. The two are complementary.
  ```,
  h1-level: 4,
  label-prefix: "cc194-",
)

== Intercambio 9

=== Prompt

#cmarker.render(
  ```
  what does polymorphic_path do?
  ```,
  h1-level: 4,
  label-prefix: "cc195-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  `polymorphic_path` is a Rails URL helper that takes a **record (or array of records)** and figures out the route for it by inspecting its class — rather than you naming the route explicitly. It returns a **relative path** (`/things/5`); its sibling `polymorphic_url` returns the **absolute** version (`https://host/things/5`).

  ## The basic idea

  ```ruby
  polymorphic_path(@article)        # => "/articles/5"   (calls article_path(@article))
  polymorphic_path([@blog, @post])  # => "/blogs/2/posts/9"
  polymorphic_path(Article)         # => "/articles"     (the index)
  ```

  It dispatches on type: given an `Article` it calls `article_path`, given a `User` it calls `user_path`, etc. That's the "polymorphic" part — one helper, many record types. `url_for(record)` actually delegates to `polymorphic_url(record)` under the hood, which is why `url_for(@article)` and `polymorphic_path`/`polymorphic_url` are close cousins.

  ## How it applies to the Active Storage change

  This is the subtle bit. A `photo.variant(...)` isn't a normal ActiveRecord model with a `*_path` helper. Active Storage registers its routes using Rails' `resolve` directive in its engine, roughly:

  ```ruby
  resolve("ActiveStorage::Variant") { |variant, options| route_for(:rails_representation, variant, options) }
  resolve("ActiveStorage::Blob")    { |blob, options|    route_for(:rails_blob, blob, options) }
  ```

  `resolve` tells the polymorphic routing system: "when someone asks for the path/URL of *this* class, build it *this* way." So `polymorphic_path(variant)` knows to produce the Active Storage representation route:

  ```
  /rails/active_storage/representations/redirect/<signed_blob_id>/<variation_key>/<filename>
  ```

  ## Why I used it instead of `url_for`

  The two produce the same route, but differ in one decisive way:

  | Helper | Output | Needs a host? |
  |---|---|---|
  | `url_for(variant)` → `polymorphic_url` | `https://localhost:3000/rails/active_storage/...` | **Yes** — pulls host from `default_url_options` |
  | `polymorphic_path(variant)` | `/rails/active_storage/...` | **No** — path only |

  The old code used `url_for`, which forces an absolute URL and therefore has to invent a host. Outside a web request (in a serializer) that host came from `default_url_options` → `localhost:3000`, which is exactly the bug. `polymorphic_path` sidesteps the whole question: it emits just the path, no host, and the frontend's `mediaUrl` prepends the correct origin.

  So the swap was essentially "give me the same route, but **relative**" — and `polymorphic_path` is the path-returning counterpart of the `url_for`/`polymorphic_url` that was already being used.
  ````,
  h1-level: 4,
  label-prefix: "cc196-",
)
