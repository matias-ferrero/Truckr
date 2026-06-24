#import "@preview/cmarker:0.1.8"

= Understand encrypted credentials file

_2026-05-25 14:43 UTC — rama `feature/INF-INFRA-00004-phase3-infra-apply-with-environments` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  what is @backend/config/credentials.yml.enc used for?
  ```,
  h1-level: 4,
  label-prefix: "cc478-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  `backend/config/credentials.yml.enc` is Rails' **encrypted credentials store** — a Rails-native way to keep secrets (API keys, third-party tokens, the `secret_key_base`, etc.) in the repo without exposing them in plaintext.

  How it works:
  - The file is AES-128-GCM encrypted. The plaintext is YAML.
  - Decryption requires the **master key**, kept out of git in `backend/config/master.key` (gitignored) or in the `RAILS_MASTER_KEY` env var.
  - At boot, Rails decrypts it and exposes values via `Rails.application.credentials.some_key`.
  - Edit with `EDITOR=... bin/rails credentials:edit` — never hand-edit the `.enc` file (you'd corrupt the ciphertext, as the blob you just read shows).

  In this repo it's the scaffolded default from `rails new`. Since the backend hasn't started real development yet, it likely just holds the auto-generated `secret_key_base` and nothing app-specific. As features land (e.g. external APIs, mailer creds), they'd go here rather than into `.env`-style files.
  ```,
  h1-level: 4,
  label-prefix: "cc479-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  what is SSH_CIDR? What is it used for? And how do I set it up?
  ```,
  h1-level: 4,
  label-prefix: "cc480-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  ## What `SSH_CIDR` is

  It's a GitHub Actions **repo secret** holding a single CIDR block (e.g. `[REDACTED_IP]/32`) that's passed into Terraform as `TF_VAR_ssh_cidr`. Terraform plugs it into the EC2 security group's port-22 ingress rule at `infra/modules/vpc/main.tf:65`:

  ```hcl
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_cidr]
  }
  ```

  ## What it's used for

  It **locks down SSH access to the EC2 instance to a single IP** — your operator workstation. Without it, you'd either expose port 22 to `0.0.0.0/0` (anyone on the internet can hammer the SSH daemon) or have no SSH access at all. With it, only traffic from that CIDR can even reach sshd.

  The workflows (`.github/workflows/infra-plan.yml:43`, `.github/workflows/infra-apply.yml:43,124`) fall back to `[REDACTED_IP]/32` if the secret isn't set — that's a TEST-NET-1 address (RFC 5737), i.e. an intentionally unroutable placeholder. So a missing secret = no real SSH access, which is safer than a permissive default but means you can't actually SSH in until you set it.

  ## How to set it up

  The bootstrap script tells you exactly what to do (`infra/bootstrap-environments.sh:96`):

  ```sh
  gh secret set SSH_CIDR --body "$(curl -s ifconfig.me)/32" --repo FernandoYu/fiuba-gestion-tp
  ```

  That fetches your current public IP, appends `/32` (single host), and stores it as a repo-level secret. After that, the next `infra-apply` run will rebuild the security group with your IP in the allow-list.

  Notes:
  - It's a **repo secret**, not an environment secret — same value for staging and production (both stacks read the same `TF_VAR_ssh_cidr`).
  - If your ISP rotates your IP (home connection, mobile tether), re-run the command to refresh it, then re-apply.
  - Use `/32` for a single IP. If you want a small office range, use `/24` etc. — but keep it as narrow as possible.
  - Don't set it to `0.0.0.0/0`. That defeats the purpose.
  ````,
  h1-level: 4,
  label-prefix: "cc481-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  curl -s ifconfig.me returns ipv6 is it correct?
  ```,
  h1-level: 4,
  label-prefix: "cc482-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  No — that will break the apply. AWS security group rules split IPv4 and IPv6 into two different attributes: `cidr_blocks` (IPv4 only) and `ipv6_cidr_blocks` (IPv6 only). The module only wires the IPv4 one (`infra/modules/vpc/main.tf:65`), so feeding it an IPv6 address like `2001:db8::1/128` will fail Terraform validation.

  You want your **IPv4** public address. Force curl to use IPv4:

  ```sh
  curl -4 -s ifconfig.me
  # or, equivalents that only answer over v4:
  curl -s https://api.ipify.org
  curl -s https://ipv4.icanhazip.com
  ```

  Then set the secret:

  ```sh
  gh secret set SSH_CIDR --body "$(curl -4 -s ifconfig.me)/32" --repo FernandoYu/fiuba-gestion-tp
  ```

  Why `ifconfig.me` gave you IPv6: the hostname has both A and AAAA records, and your network prefers IPv6, so curl connected over v6 and the service echoed back the v6 address it saw. `-4` pins the connection to IPv4 so the echoed address is your v4 one.

  Sanity check before storing — it should look like `[REDACTED_IP]`, four dotted decimals, not a colon-separated hex string.

  Sidebar: if you genuinely only have an IPv6 public address (some mobile/CGNAT setups), the module would need a small change to also expose `ipv6_cidr_blocks` on the SSH ingress rule. But that's rare for a dev workstation — most home/office connections still have a working v4 public IP even when v6 is preferred.
  ````,
  h1-level: 4,
  label-prefix: "cc483-",
)

== Intercambio 4

=== Prompt

#cmarker.render(
  ```
  ~/Documents/gdsi-1c2026/fiuba-gestion-tp feature/INF-INFRA-00004… *2                                                                                                              fernando-yu@fyu-laptop 󰌠 3.13.3
  ❯ bash infra/bootstrap-environments.sh
  ==> Targeting repository: tcorzo/fiuba-gestion-tp
  ==> Ensuring environment 'staging' exists (no reviewers, no wait timer)
  gh: Not Found (HTTP 404)
  FAILED to create/update staging environment
  ```,
  h1-level: 4,
  label-prefix: "cc484-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  The 404 isn't "repo doesn't exist" — your remote *is* `tcorzo/fiuba-gestion-tp` and that's what the script defaults to. GitHub's API returns **404 for permission-denied** on the environments endpoint (it hides existence from non-admins rather than returning 403).

  So the real cause: the `gh`-authenticated user doesn't have **admin** rights on `tcorzo/fiuba-gestion-tp`. Creating environments requires admin scope on the repo, not just write/push.

  Verify:

  ```sh
  gh auth status
  gh api repos/tcorzo/fiuba-gestion-tp --jq '.permissions'
  ```

  You'll likely see `admin: false`. Two ways forward:

  **1. Ask `tcorzo` (the repo owner) to either:**
  - Grant you the **Admin** role on the repo (Settings → Collaborators), or
  - Run the bootstrap script themselves. They only need to do it once — it's idempotent and sets up the environments/secrets organization-wide for the repo.

  **2. If you only want to test against your own fork** while waiting:

  ```sh
  gh repo fork tcorzo/fiuba-gestion-tp --clone=false   # if not forked yet
  REPO=FernandoYu/fiuba-gestion-tp bash infra/bootstrap-environments.sh
  ```

  The script honors `REPO=…` as an override (`infra/bootstrap-environments.sh:24`). But note: your fork's CI won't have the same AWS role trust policy, so `infra-apply` against the fork would need its own `GHA_ROLE_ARN` wired up too — not just a script run.

  **Recommendation:** since this is a course team repo and the environments/secrets need to live on the canonical `tcorzo/...` repo for everyone's CI to work, the right move is to ask `tcorzo` to either promote you to admin or run the script. Don't try to work around it on your fork.
  ````,
  h1-level: 4,
  label-prefix: "cc485-",
)

== Intercambio 5

=== Prompt

#cmarker.render(
  ```
  what are github environments?
  ```,
  h1-level: 4,
  label-prefix: "cc486-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  **GitHub Environments** are a per-repo deployment-target abstraction inside GitHub Actions. Each environment is a named bucket (`staging`, `production`, `qa`, etc.) that bundles three things:

  1. **Protection rules** — gates that must pass before a job referencing the environment runs:
     - **Required reviewers**: up to 6 users/teams must click "Approve" before the job starts. The job sits in a `waiting` state in the Actions UI until then.
     - **Wait timer**: forced delay (0–43 200 min) between approval and execution.
     - **Deployment branches**: restrict which branches/tags can deploy to this environment (e.g. only `main` can deploy to `production`).
  2. **Environment-scoped secrets and variables** — shadowing repo-level ones. A job that declares `environment: production` sees the `production` secrets; the same job with `environment: staging` sees the `staging` ones. Lets you keep distinct DB URLs, role ARNs, etc. without juggling prefixes.
  3. **Deployment history** — every run that used the environment shows up under the repo's "Environments" sidebar with its commit, actor, and status. You get a real audit trail of "what shipped where, when, approved by whom."

  ## How a job opts in

  ```yaml
  jobs:
    deploy-prod:
      runs-on: ubuntu-latest
      environment: production           # ← the gate
      steps:
        - run: ./deploy.sh
  ```

  When that job is queued, Actions checks the `production` environment's protection rules. If reviewers are required, the job pauses; reviewers get a notification and approve/reject in the UI. If the branch isn't allowed, the job fails immediately.

  ## How this repo uses them (concrete)

  `infra/bootstrap-environments.sh` provisions two environments via the GitHub API:

  - **`staging`** — no reviewers, no wait timer. `infra-apply` on `staging` runs straight through. (`infra/bootstrap-environments.sh:32-36`)
  - **`production`** — required reviewer = repo owner (`tcorzo`). Every production apply pauses until the owner clicks Approve. (`infra/bootstrap-environments.sh:38-45`)

  The `.github/workflows/infra-apply.yml` workflow has two jobs that declare `environment: staging` and `environment: production`. Same Terraform code, same OIDC role pattern — the environment just adds the manual gate on prod.

  ## Why this matters for IaC specifically

  Without environments, `terraform apply` against production would run on merge with no human in the loop — a bad PR or compromised CI token could rewrite real infrastructure in seconds. The required-reviewer gate makes destructive changes a deliberate, attributable action. The deployment history then gives you a record of every prod apply that you can point at when something breaks.

  ## Things people get wrong

  - **Required reviewers can't approve their own job by default** unless you flip "Allow administrators to bypass configured protection rules" or add other reviewers. A single-maintainer repo where the owner is the only reviewer can deadlock — be aware.
  - **Environment secrets > repo secrets** in scope, not in priority — if both exist with the same name, the environment one wins for that job. Use this intentionally; don't accidentally shadow.
  - **Free tier**: protection rules (reviewers, wait timer, branch restrictions) require **public repos** or a **paid plan** on private repos. On private free repos you get the environment + scoped secrets but not the gates.
  - They're scoped to a **repo**, not an org. No way to share environment definitions across repos — you re-create them per repo (which is exactly what the bootstrap script does).
  ````,
  h1-level: 4,
  label-prefix: "cc487-",
)

== Intercambio 6

=== Prompt

#cmarker.render(
  ```
  what if i want to allow 2 ips
  ```,
  h1-level: 4,
  label-prefix: "cc488-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  The current setup only allows **one** CIDR — the variable is typed `string`, not `list(string)`:

  ```hcl
  # infra/modules/vpc/variables.tf:24
  variable "ssh_cidr" {
    type        = string
  }

  # infra/modules/vpc/main.tf:65
  cidr_blocks = [var.ssh_cidr]
  ```

  So allowing two IPs needs a small code change. You have three options, ordered by how clean they are.

  ## Option 1 — change the var to a list (recommended)

  Make the module accept a list, then pass it from the secret as a comma-separated string and split it.

  ```hcl
  # infra/modules/vpc/variables.tf
  variable "ssh_cidr" {
    type        = list(string)
    description = "CIDR blocks allowed to SSH into the EC2 instance"
  }

  # infra/modules/vpc/main.tf
  cidr_blocks = var.ssh_cidr
  ```

  Then in **each env's** `main.tf` (`infra/envs/staging/main.tf`, `infra/envs/production/main.tf`) split the incoming string:

  ```hcl
  ssh_cidr = [for c in split(",", var.ssh_cidr) : trimspace(c)]
  ```

  Keep the env-level `variable "ssh_cidr"` typed as `string` (so `TF_VAR_ssh_cidr` still receives a plain CSV), and only the module sees the list. That keeps the GHA secret a simple string.

  Set the secret:

  ```sh
  gh secret set SSH_CIDR \
    --body "[REDACTED_IP]/32,[REDACTED_IP]/32" \
    --repo tcorzo/fiuba-gestion-tp
  ```

  ## Option 2 — single covering CIDR

  If by luck both IPs sit in the same small prefix (rare for two unrelated home/office connections), use one wider CIDR. Two arbitrary residential IPs almost never fit, so don't pick a /16 just to cover both — that opens SSH to ~65k hosts. Skip this unless the IPs are genuinely adjacent.

  ## Option 3 — two separate ingress rules

  Leave `ssh_cidr` alone, add a second variable `ssh_cidr_2`, and duplicate the ingress block. Quick but ugly — you pay for it the moment you need a third IP. Don't.

  ## Recommendation

  Go with **Option 1**. It's a ~5-line change, the GHA secret stays a single string, and it scales to N IPs without further code changes. If you want, I can make the edit — say the word and I'll do `variables.tf` + `main.tf` in the module and both env stacks.

  Caveat: the module currently has zero tests, so the only verification path is `terraform plan` against staging. Run that locally (or via the `infra-plan` PR workflow) after the change and confirm the SG diff shows two rules instead of one.
  ````,
  h1-level: 4,
  label-prefix: "cc489-",
)

== Intercambio 7

=== Prompt

#cmarker.render(
  ```
  How to provision the production key pair?

  ❯ 1. Create new key pair, save to ~/.ssh (recommended)
       Run `aws ec2 create-key-pair --key-name truckr-production-fy ...` via fiuba profile; save private key to ~/.ssh/truckr-production-fy.pem with 0600 perms. New 2048-bit RSA key, dedicated to prod EC2 break-glass.
    2. Reuse staging key pair
       Change apply-production's TF_VAR_key_pair_name to 'truckr-staging-fy'. Semantically off (one key for two envs) but works for academic scope. No new key to manage.
    3. Skip prod bootstrap; merge with apply-production removed for now
       Edit infra-apply.yml to drop the apply-production job; just merge apply-staging auto. Production stays manual-only until you decide to bootstrap it (with key pair) later.
    4. Type something.
  ──────────────────────────────────────────────────────────────────────────────────────────────────────
    5. Chat about this

  what is key pair? and what is it used for?
  ```,
  h1-level: 4,
  label-prefix: "cc490-",
)

=== Respuesta (Claude)

#cmarker.render(
  ````
  An **EC2 key pair** is an SSH credential AWS manages for you to authenticate into EC2 Linux instances. It's standard asymmetric crypto with an AWS-specific lifecycle.

  ## What it actually is

  Two halves of an SSH keypair:

  - **Public half** — AWS stores it. When you launch an instance and specify `key_name = "truckr-staging-fy"`, AWS injects that public key into `/home/[user]/.ssh/authorized_keys` (or `ubuntu`, depending on AMI) at first boot, via cloud-init.
  - **Private half** — a `.pem` file. AWS shows it to you **once**, when you create the key pair, and never again. You save it to `~/.ssh/`, `chmod 600`, and SSH with it:

  ```sh
  ssh -i ~/.ssh/truckr-staging-fy.pem ec2-user@<public-ip>
  ```

  That's it. There's no password fallback by default on these AMIs — the key is the only way in.

  ## What it's for in this stack

  Look at `infra/modules/vpc/main.tf:60-66` (the SSH ingress rule we discussed) and the EC2 resource in the same module — the instance is launched with `key_name = var.key_pair_name`. That's the linkage:

  - `SSH_CIDR` controls **who can reach** port 22 (network layer).
  - The key pair controls **who can authenticate** once they reach it (auth layer).

  Both must pass. If you set `SSH_CIDR` to your IP but lose the `.pem`, you can see the port open but can't log in — AWS doesn't store the private half, so the instance is effectively bricked from an SSH standpoint and you'd have to rebuild it.

  ## Why this product has one at all

  For this academic project, SSH is **break-glass access** — you don't log in to deploy (Kamal pushes containers over a separate channel), you log in only when something is on fire and you need to read logs / inspect the SQLite file / restart a service by hand. That's why the security model is "narrow IP allow-list + per-environment key pair."

  ## Why staging and production should have separate ones

  The option list you're being shown frames it correctly. The reason to **not** reuse the staging key for production:

  - **Blast radius if the private key leaks.** If `truckr-staging-fy.pem` ends up in a backup, a stolen laptop, or accidentally pushed to a repo, an attacker also gets prod with the same file. One key = one revocation surface; two keys = scoped damage.
  - **Revocation is per-instance.** "Rotating" a key pair in AWS means launching a new instance with the new key, or manually editing `authorized_keys` over the existing SSH session. If staging gets compromised, you want to rotate staging without forcing a prod outage at the same time.
  - **Audit clarity.** "Who SSH'd into prod?" is easier to reason about when prod has its own key and only the operators who need prod access hold the `.pem`.

  For coursework the practical risk is low, but option 1 in your prompt is the conventional answer and costs you about 30 seconds. Option 2 (reuse staging) works and you can defend it as "academic scope" — it's just sloppier hygiene.

  ## Mechanics of option 1, concretely

  ```sh
  aws --profile fiuba ec2 create-key-pair \
    --key-name truckr-production-fy \
    --key-type rsa \
    --key-format pem \
    --query 'KeyMaterial' \
    --output text > ~/.ssh/truckr-production-fy.pem

  chmod 600 ~/.ssh/truckr-production-fy.pem
  ```

  After that, set `TF_VAR_key_pair_name=truckr-production-fy` on the production apply job and Terraform will reference the existing AWS key pair by name when launching the instance. The `.pem` never leaves your machine — AWS doesn't need it, only you do when you actually SSH in.

  One thing to double-check: the AWS region. Key pairs are **regional**. If staging lives in `sa-east-1` and you create the prod key pair in `us-east-1`, Terraform will fail with "key pair not found" when launching the prod instance. Use the same `--region` (or default profile region) as your prod stack.
  ````,
  h1-level: 4,
  label-prefix: "cc491-",
)
