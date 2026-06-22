#import "@preview/cmarker:0.1.8"

= Review security concerns and analyze deployment workflow

_2026-05-10 15:04 UTC — rama `chore/sprint-1-plan` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/clear`
  ```,
  h1-level: 4,
  label-prefix: "cc2483-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/gdsi-sdlc:project:onboard full`
  ```,
  h1-level: 4,
  label-prefix: "cc2484-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  ## Project Onboarding Complete

  **Task Type**: full
  **Mode**: standard (onboarding docs found)
  **Documents Loaded**: README, 00-philosophy-and-architecture, 01-patterns-and-implementation, 02-coding-guidelines, 03-module-reference, 04-ai-harness, 05-testing-strategy, 06-roadmap, `.gdsi-sdlc/config.json`, CLAUDE.md (preloaded)

  ### Project Summary
  - **Name**: Truckr® — FIUBA GDSI capstone
  - **What**: Two-sided transportation marketplace (Argentina) connecting `Carrier` ↔ `Shipper`
  - **Stack**: Rails 8 API-only + Ruby 3.4 + SQLite + Solid* / React 18 + Vite + TS strict + Deno / Typst docs
  - **Architecture**: Monorepo, client/server, single-container, no microservices
  - **Phase**: planning → implementation transition; only `/up` + ActiveAdmin live, landing page static

  ### Key Rules I'll Follow
  - **Spanish for content, English for code/identifiers** — glossary at `docs/05-appendices/glossary.md` is source of truth
  - **Conventional Commit PR titles** (no `[TAG]` prefix — squash feeds release-please; TAG goes in body + branch)
  - **Model naming**: `Carrier`/`Shipper` (not `Cliente`/`Productor`); no denormalized role booleans on `User` (ADR-008 — relation-derived predicates)
  - **Issue lifecycle = file movement** under `.gdsi-sdlc/issues/{Backlog,Ready,InProgress,InReview,Done}/`
  - **`gh pr create --assignee @me`** every time
  - **Team size = 6**, RSpec exclusive on backend, Vitest+Playwright on frontend
  - **No `*.pdf` commits**, CORS allow-list never `"*"`, no business logic on `/up`

  ### Active Context
  - **Branch**: `chore/sprint-1-plan` — Sprint 1 plan committed; backlog `.issue.md` edits staged (REQ-FE-00006/07/08/13/16 retitled around "ventana de transporte")
  - **In review**: `REQ-BE-00005` (domain ADRs/ERDs) gates Tier 1; `INF-BE-00003` ActiveAdmin; `REQ-DOC-00002` risks; `REQ-FE-00002` cronograma; `INF-GEN-00001` throughput
  - **Next priority chain**: `REQ-BE-00005` → `00020` Identity → `00021` Marketplace → `00022` Fulfilment (just merged in `a531533`) → `00023` Auth fullstack
  - **Today**: 2026-05-10 — past 2026-05-03 triage milestone

  ### Ready to Help With
  Any work across backend (Rails/RSpec), frontend (React/design-skills/Vitest/Playwright), Typst docs/artifacts, issue triage/planning, AI skill authoring, release pipeline.

  Questions?
  ```,
  h1-level: 4,
  label-prefix: "cc2485-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/gdsi-sdlc:pr:review https://github.com/tcorzo/fiuba-gestion-tp/pull/143

  I can already tell most of this is hand-deployed which is fine for the moment. The next milestone is fully automating the deployment process via Github actions. Comment on that.`
  ```,
  h1-level: 4,
  label-prefix: "cc2486-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Got the CI failure. Let me look at the offending files and key modules without checking out (uncommitted local changes).
  ```,
  h1-level: 4,
  label-prefix: "cc2487-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Compiled review. Posting now — blocking CI failure means **REQUEST CHANGES**, no merge.
  ```,
  h1-level: 4,
  label-prefix: "cc2488-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Review posted on **PR #143** — verdict: **REQUEST CHANGES**.

  ### Posted
  - **Comment**: https://github.com/tcorzo/fiuba-gestion-tp/pull/143#issuecomment-4415615794
  - **Formal review**: REQUEST CHANGES submitted

  ### Blockers identified
  1. **CI failure** — `templatefile()` chokes on `${ECR_URL}` in `modules/ec2/user_data.sh:29` (inside the `<< 'COMPOSE'` heredoc). Single-quoted heredoc protects bash, not Terraform's interpolator. Fix: `$${ECR_URL}` so Terraform passes the literal through to shell, where `ECR_URL=...` is already exported on the docker-compose lines.
  2. **`.terraform.lock.hcl` gitignored** — should be committed per Hashicorp guidance (provider pinning).

  ### Non-blocking concerns flagged
  Hardcoded us-east-1 AMI; missing private subnets/NAT vs issue #141 spec; no EBS snapshot policy for SQLite; `ignore_changes = [user_data]` undocumented; global S3 bucket name `truckr-tfstate` could collide.

  ### Positives noted
  Remote state hardening (versioning + encryption + lock + PAB), CloudFront OAC with correct `AWS:SourceArn` bucket policy, SPA fallback (403/404 → /index.html), least-privilege EC2 IAM, conventional title, valid `Closes #141`.

  ### GHA deployment-automation milestone (per your ask)
  Sketched as the natural follow-up — `INF-INFRA-00004` should cover: (1) `terraform plan` PR-comment workflow, (2) `terraform apply` on main with prod environment gate, (3) backend deploy via ECR push + SSM `Send-Command` (no SSH), (4) frontend deploy via `s3 sync` + CloudFront invalidation, (5) **GitHub OIDC** role-assumption (no long-lived AWS keys in secrets), (6) per-env separation. Suggested two cheap additions to land now to unblock that follow-up: an OIDC IAM role module and the SSM doc the deploy role will use.

  No merge attempted (CI red). Local working-tree changes from sprint-1-plan branch were left untouched.
  ```,
  h1-level: 4,
  label-prefix: "cc2489-",
)

== Intercambio 4

=== Prompt

#cmarker.render(
  ```
  Edit your comment and elevate Concerns #3, #4, #6 and perform a security analysis on the deployment workflow. user_data.sh smells
  ```,
  h1-level: 4,
  label-prefix: "cc2490-",
)

== Intercambio 5

=== Prompt

#cmarker.render(
  ```
  Perform a security analysis on the deployment workflow. user_data.sh smells
  ```,
  h1-level: 4,
  label-prefix: "cc2491-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  ## Security analysis — `user_data.sh` deploy chain

  Going from "smells" to ranked findings. Most of the worst ones aren't in `user_data.sh` itself — they're in how it interacts with EC2 IMDS, ECR mutability, and Docker's secret model.

  ---

  ### CRITICAL

  **1. IMDSv1 enabled — full IAM credential theft from any SSRF**

  `modules/ec2/main.tf` defines no `metadata_options`. AWS default = IMDSv1 enabled. The instance role has `ssm:GetParameter` on `/${project}/${env}/*` and ECR pull. **Any** SSRF in Rails (image proxy, webhook, HTML preview, redirect follower) lets an attacker:

  ```
  GET http://169.254.169.254/latest/meta-data/iam/security-credentials/<role>
  → AccessKeyId / SecretAccessKey / Token
  → aws ssm get-parameter --name /truckr/staging/rails_master_key --with-decryption
  → decrypts every Rails encrypted credential, signs arbitrary session cookies, forges CSRF
  ```

  This is the single biggest risk. Fix:

  ```hcl
  resource "aws_instance" "app" {
    # ...
    metadata_options {
      http_tokens                 = "required"   # IMDSv2 only
      http_endpoint               = "enabled"
      http_put_response_hop_limit = 1            # blocks container→IMDS via docker bridge
    }
  }
  ```

  The `hop_limit = 1` is what blocks a compromised **container** from reaching IMDS through the docker0 bridge.

  ---

  ### HIGH

  **2. `RAILS_MASTER_KEY` ends up in container env — recoverable from anywhere on the box**

  Pattern in `user_data.sh`: shell var → docker compose `environment:` → container PID 1 environ. After boot the secret lives in:
  - `docker inspect truckr_web_1` (any user in the `docker` group)
  - `/proc/<container-pid>/environ` (any root process, any container escape)
  - Crash logs / `Rails.logger.info ENV.inspect` mistakes
  - `ps eww` for the rails process if it ever re-execs without scrubbing env

  Better: have Rails fetch from SSM at boot using the instance role. Drop `RAILS_MASTER_KEY` from the compose file entirely.

  ```ruby
  # config/application.rb
  require "aws-sdk-ssm"
  ENV["RAILS_MASTER_KEY"] ||= Aws::SSM::Client.new
    .get_parameter(name: "/truckr/#{Rails.env}/rails_master_key", with_decryption: true)
    .parameter.value
  ```

  If you must keep it in the compose layer, use Docker secrets (file mount), not `environment:`:

  ```yaml
  services:
    web:
      secrets: [rails_master_key]
      environment:
        RAILS_MASTER_KEY_FILE: /run/secrets/rails_master_key
  secrets:
    rails_master_key:
      file: /opt/truckr/secrets/rails_master_key  # 0400 root:root
  ```

  Rails reads `RAILS_MASTER_KEY_FILE` natively in 7.1+.

  **3. `:latest` tag on a `MUTABLE` ECR repo = supply-chain RCE**

  ```
  image: "${ECR_URL}/truckr-backend:latest"
  image_tag_mutability = "MUTABLE"
  ```

  Anyone with `ecr:PutImage` (today: any AWS console user, tomorrow: any GHA workflow with the deploy role) can push a malicious `:latest` and the next `docker compose pull` runs it as root on port 80. No rollback either.

  Fix:
  - `image_tag_mutability = "IMMUTABLE"` on the repo
  - Deploy by image digest: `image: "${ECR_URL}/truckr-backend@sha256:..."`
  - The GHA deploy workflow records the SHA from `docker push` output and templates it into the compose file

  **4. Container runs as root and binds host :80**

  `ports: - "80:80"` forces the entrypoint to bind a privileged port → container PID 1 is root (or has `CAP_NET_BIND_SERVICE`, which is morally equivalent for Rails). Any RCE in Rails → root in container → with default Docker, also one CVE away from root on the host.

  Fix:
  - Container listens on 3000, host nginx/Caddy fronts 80/443 with TLS, OR
  - ALB → EC2 :3000 (target group on 3000, SG only allows 3000 from ALB SG)
  - Either way, drop the `:80:80` mapping and add `user: "1000:1000"` to the compose service

  ---

  ### MEDIUM

  **5. ECR auth token expires in 12h — silent breakage**

  `aws ecr get-login-password | docker login` runs **once** in user_data. After 12h any `docker compose pull` (e.g., during an `up -d` after a manual restart, OOM kill, ASG replacement that re-runs nothing) fails 401. Install the credential helper:

  ```bash
  apt-get install -y amazon-ecr-credential-helper
  mkdir -p /root/.docker
  cat > /root/.docker/config.json <<'JSON'
  {"credHelpers": {"<account>.dkr.ecr.<region>.amazonaws.com": "ecr-login"}}
  JSON
  ```

  **6. `docker-compose-plugin` package isn't in Ubuntu apt — script won't install on stock 22.04/24.04**

  `apt-get install -y docker.io docker-compose-plugin` — `docker-compose-plugin` ships in **Docker's** apt repo, not Ubuntu's. The script will exit non-zero on first boot and the instance will be a brick with no app on it. Either add Docker's apt source first, or use the Docker convenience script and drop `docker.io`. Functional, but listed here because a half-bricked instance with an open SG and IAM role is a security posture too.

  **7. `apt-get install awscli` pulls v1 on Ubuntu — old TLS, IMDSv2 quirks**

  Ubuntu's `awscli` is pinned to a years-old v1. Use the official v2 zip from `awscli.amazonaws.com` (signature-checked) — or, better, drop awscli use entirely from user_data and have Rails do its own SSM lookup (see #2).

  **8. Single SSM SecureString uses default `alias/aws/ssm` KMS key**

  Anyone in the account with `kms:Decrypt` on the AWS-managed key can decrypt all SSM SecureStrings, even without `ssm:GetParameter` access. Use a customer-managed KMS key with a key policy that names only the EC2 role + the future deploy role + admins.

  **9. EBS root volume uses default KMS key**

  Same story — `encrypted = true` without `kms_key_id` uses `alias/aws/ebs`. CMK gives you revocation if the volume ever ends up somewhere it shouldn't. Also ensure SQLite database file lives on a **separate** encrypted EBS volume so it survives instance replacement.

  **10. No CloudTrail / no S3 access logs / no VPC flow logs**

  Forensic dead end. After an incident you can't answer "who pulled rails_master_key, when, from which IP." CloudTrail management events are free for 90 days — turn them on.

  ---

  ### LOW

  **11. No TLS** — only :80 published, no Let's Encrypt / ACM. Auth (when REQ-BE-00023 lands) shipping cookies over plain HTTP = trivial sniffing.
  **12. EC2 public IP + no ALB/WAF** — no L7 protection, no rate limiting. Fine for staging, plan for prod.
  **13. `bootstrap.sh` not idempotent** — second run errors on bucket-exists, easy to misread as "broken."
  **14. Hardcoded global S3 name `truckr-tfstate`** — collision risk with any other AWS account that grabbed it; suffix with `${ACCOUNT_ID}`.
  **15. `lifecycle { ignore_changes = [user_data] }`** — security implication is that if you patch `user_data.sh` (e.g., to fix #1, #5, #6, #7 above), Terraform won't replace the instance. You have to `terraform taint module.ec2.aws_instance.app` manually. Document this in `infra/README.md` or remove the lifecycle ignore.

  ---

  ### Recommended action

  This PR is already in REQUEST CHANGES for the CI failure. Three of these (1, 3, 4) are cheap to fix in the same PR and would materially shrink the blast radius:

  ```diff
  +  metadata_options {
  +    http_tokens                 = "required"
  +    http_put_response_hop_limit = 1
  +    http_endpoint               = "enabled"
  +  }
  ```

  ```diff
  - image_tag_mutability = "MUTABLE"
  + image_tag_mutability = "IMMUTABLE"
  ```

  ```diff
  -      - "80:80"
  +      - "127.0.0.1:3000:3000"   # plus a host-side reverse proxy, or ALB later
  ```

  The rest (especially #2 — moving the secret out of `environment:`) belong in a follow-up `INF-INFRA-0000X` security-hardening issue, ideally landed alongside the GHA deployment automation in `INF-INFRA-00004` so the OIDC role design and the secrets model are decided together.

  Want me to post this as a second PR comment, or hold it for the security-hardening follow-up issue?
  ````,
  h1-level: 4,
  label-prefix: "cc2492-",
)
