# Deployment runbook — Truckr®

Day-2 operations for the AWS environments (`staging`, `production`) provisioned by `infra/envs/`. First-bootstrap steps live in [`infra/README.md`](../../infra/README.md); this file owns recurring operations.

**Routine deploys are automatic via GitHub Actions** (workflows under `<repo-root>/.github/workflows/`):

| Workflow | Staging trigger | Production trigger |
|---|---|---|
| `infra-apply.yml` | push to `main` (paths `infra/**`) | push to `main` (paths `infra/**`) |
| `backend-deploy.yml` | push to `main` (paths `backend/**`) | release published by release-please |
| `frontend-deploy.yml` | push to `main` (paths `frontend/**`) | release published by release-please |

All three workflows authenticate to AWS via OIDC (no long-lived `AWS_ACCESS_KEY_ID` in repo secrets) and read infrastructure addresses from SSM Parameter Store. Operator follow-ups below cover state changes the workflows can't make themselves (key pair creation, secret rotation, manual recovery).

| Component | Where |
|---|---|
| Backend (Rails) | EC2 `t3.micro`, image from `truckr-backend` ECR repo, deployed with Kamal |
| Frontend (React) | S3 bucket fronted by CloudFront (OAC) |
| Data | SQLite on Docker volume `truckr_storage`; daily EBS snapshots via DLM |
| Secrets | SSM Parameter Store under `/truckr/staging/`, fetched by Kamal at deploy time |
| TLS | kamal-proxy + Let's Encrypt on `<eip>.sslip.io` (autorenews) |

---

## Prereqs (per operator)

1. **AWS CLI** configured with credentials that allow:
   - `ssm:GetParameter` + `kms:Decrypt` on `/truckr/staging/*`
   - `ecr:GetAuthorizationToken`, `ecr:BatchGetImage`, `ecr:PutImage`
   - `ec2:DescribeInstances`, `ssm:StartSession` on the staging instance
2. **EC2 keypair** uploaded to AWS as `truckr-staging-<initials>`; private key in `~/.ssh/`. Add your pubkey via console or `aws ec2 import-key-pair`. Re-run `terraform apply -var key_pair_name=...` if changing.
3. **`AWS_REGION`** env var set to the staging region (defaults to `sa-east-1`).
4. **mise**: `mise install` provides `terraform`, `deno`, `ruby`. Kamal is a Ruby gem installed via the backend Gemfile.

---

## First deploy of a new env (after `terraform apply`)

The CD workflows assume both the AWS infrastructure (Phase 3 `infra-apply.yml`) and the prerequisite SSM parameters exist. When bootstrapping a brand-new env (beyond the current `staging` + `production`):

1. **Terraform apply** the new env directory (`infra/envs/<new-env>/`) — creates EC2, EIP, ECR, S3 + CloudFront, IAM role, and the 5 output SSM parameters. See `infra/README.md`.
2. **Seed the `rails_master_key` SSM parameter** with the real `backend/config/master.key` (terraform's apply leaves it as the placeholder string):
   ```sh
   AWS_PROFILE=fiuba aws ssm put-parameter --overwrite \
     --name /truckr/<new-env>/rails_master_key \
     --value "$(cat backend/config/master.key)" \
     --type SecureString
   ```
   Lifecycle `ignore_changes = [value]` keeps future terraform applies from reverting it.
3. **(Optional) Seed admin credentials** if you want `rails db:seed` to bootstrap an admin user:
   ```sh
   aws ssm put-parameter --name /truckr/<new-env>/seed_admin_email --type SecureString --value <email>
   aws ssm put-parameter --name /truckr/<new-env>/seed_admin_password --type SecureString --value <password>
   ```
   `.kamal/secrets` tolerates these being absent; the backend just won't seed.
4. **Trigger the first backend deploy** via `gh workflow run backend-deploy.yml --field env=<new-env>` (or wait for a tag/push that fires the workflow). The first deploy:
   - Builds image, pushes to shared ECR with a SHA tag.
   - Pushes ephemeral SSH key via `ec2-instance-connect` (60s TTL).
   - SSHes through SSM Session Manager to the EC2.
   - Boots `kamal-proxy`, claims a Let's Encrypt cert via HTTP-01 on the EIP-derived sslip.io hostname.
   - Smoke-checks `/up`.
5. **Trigger the first frontend deploy** via `gh workflow run frontend-deploy.yml --field env=<new-env>`. First deploy populates the S3 bucket; subsequent runs sync diffs.

---

## Routine deploys

There's no operator action for normal release flow — everything is CD-driven:

| Change | What happens |
|---|---|
| Merge feature PR with `backend/**` changes | `backend-deploy.yml` fires on push to `main` → deploys staging only. Smoke test on `https://<app_host>/up`. |
| Merge feature PR with `frontend/**` changes | `frontend-deploy.yml` fires → builds with `deno task build`, syncs to S3, invalidates `/index.html` on CloudFront. |
| Merge release-please's Release PR | release-please-action tags `vX.Y.Z` + publishes the GitHub Release → both `backend-deploy.yml` and `frontend-deploy.yml` fire on `release: published` and deploy production. |
| Merge feature PR with `infra/**` changes | `infra-apply.yml` runs `terraform apply` against staging first, then production. |

Watch progress in the Actions tab. The workflows post sticky comments on `infra-plan` PRs (PR review) and fail-fast with `::error::` annotations if something's off.

---

## Rollback

### Backend rollback (Kamal-based)

Kamal pins each deploy to a Docker image tagged with the git SHA. To roll back to a previous SHA:

1. List recent image tags:
   ```sh
   AWS_PROFILE=fiuba aws ecr describe-images \
     --repository-name truckr-backend \
     --query 'sort_by(imageDetails,&imagePushedAt)[-10:].[imagePushedAt,imageTags[0]]' \
     --output table
   ```
2. Trigger a manual deploy pinning that SHA via Kamal from the laptop (the CD workflow doesn't support arbitrary-SHA dispatch yet — see Break-glass below for the operator commands).

### Frontend rollback

Two options:

1. **Revert the offending commit on `main`** → frontend-deploy fires again with the reverted state. Slow but auditable.
2. **Manual re-sync from a previous build artifact** (Break-glass section below).

There's no fancy versioning on the S3 bucket — `--delete` on `aws s3 sync` prunes old hashed assets. Don't enable bucket versioning lightly: it'd accumulate cost over time.

### Infrastructure rollback

`infra-apply.yml` has a refuse-on-destroy guard, but if a non-destructive change is bad: revert the offending commit on `main` and let CI re-apply the previous state. Terraform state stays consistent because every change goes through the workflow.

---

## SQLite backup / restore

**Backup** is automatic: DLM takes a crash-consistent snapshot of the EBS root volume daily at 03:00 UTC, retaining the last 7. See `infra/modules/ec2/main.tf` → `aws_dlm_lifecycle_policy.ebs_snapshots`.

**Restore from snapshot:**

1. Identify the target snapshot: `aws ec2 describe-snapshots --filters Name=tag:Name,Values=truckr-staging-app`
2. Stop the box: `aws ec2 stop-instances --instance-ids <id>`
3. Detach the existing volume: `aws ec2 detach-volume --volume-id <vol-id>`
4. Create a new volume from the snapshot: `aws ec2 create-volume --snapshot-id snap-... --availability-zone <az>`
5. Attach it to the instance at `/dev/sda1`: `aws ec2 attach-volume --instance-id <id> --volume-id <new-vol> --device /dev/sda1`
6. Start the box: `aws ec2 start-instances --instance-ids <id>`
7. `kamal app boot` to re-attach Kamal to the running container.

**Ad-hoc dump** (e.g. before a risky migration):

```sh
bundle exec kamal app exec "sqlite3 /rails/storage/production.sqlite3 '.backup /rails/storage/manual-$(date +%F).sqlite3'"
aws s3 cp ... # optional offsite copy via kamal accessory or scp
```

---

## Secret rotation (`RAILS_MASTER_KEY`)

1. Generate / commit the new key locally: `cd backend && bundle exec rails credentials:edit` saves a fresh value if you regenerate `config/master.key`. Or generate via `openssl rand -hex 32`.
2. Push to SSM for the env you're rotating:
   ```sh
   AWS_PROFILE=fiuba aws ssm put-parameter --overwrite \
     --name /truckr/<env>/rails_master_key \
     --value "$(cat backend/config/master.key)" \
     --type SecureString
   ```
   The Phase 2 lifecycle `ignore_changes = [value]` on this resource means subsequent `terraform apply` runs won't revert it.
3. Trigger a redeploy so containers boot with the new key:
   - **Staging**: any push to `main` touching `backend/**`, or `gh workflow run backend-deploy.yml --field env=staging`.
   - **Production**: cut a release (release-please) or `gh workflow run backend-deploy.yml --field env=production`.
4. Verify: `curl -fsS https://<app_host>/up` and check workflow logs (or `bundle exec kamal app logs --grep "credentials"` from the laptop) for decryption errors.

Frontend deploys do not consume the master key — no FE redeploy needed.

---

## CORS allow-list update

`backend/config/initializers/cors.rb` reads `FRONTEND_ORIGIN` (comma-separated) at boot. Update via Kamal env:

```sh
bundle exec kamal env push \
  FRONTEND_ORIGIN="https://<cloudfront-domain>,https://$APP_HOST"
bundle exec kamal app boot
```

The CloudFront domain comes from `terraform output cloudfront_domain`.

---

## DNS / TLS

`<eip>.sslip.io` resolves any IP-shaped subdomain back to that IP, so no DNS provisioning is needed. The EIP is a Terraform resource — it survives stop/start but **not** `terraform destroy`. If the EIP is ever released, Let's Encrypt's HTTP-01 challenges for the old hostname fail and the cert can't renew; redeploying re-provisions a cert for the new hostname.

To swap to a real domain later (deferred to `INF-INFRA-00005`):

1. Add a Route53 hosted zone + A record pointing at the EIP.
2. Update `backend/config/deploy.yml` `proxy.host` to the real hostname.
3. `bundle exec kamal proxy reboot` — kamal-proxy provisions a fresh cert for the new hostname.

---

## `user_data.sh` changes

The EC2 instance has `lifecycle { ignore_changes = [user_data] }`. Changing the script does **not** affect already-running instances. To roll the bootstrap:

```sh
cd infra/envs/staging
terraform taint module.ec2.aws_instance.app
terraform apply
```

This destroys + recreates the instance. **Before doing this, take a manual EBS snapshot** — DLM's daily snapshot may be up to 24h stale, and re-creation wipes the volume.

---

## Smoke checks

| Layer | Command |
|---|---|
| Backend health | `curl -fsS https://$APP_HOST/up` (expect HTTP 200) |
| Backend TLS | `curl -fsS https://$APP_HOST/ -I` (expect `Server: kamal-proxy`, valid LE cert) |
| Frontend (CloudFront) | `curl -fsS https://$(terraform output -raw cloudfront_domain)/index.html -I` |
| Frontend (S3 sync diff) | `aws s3 sync frontend/dist/ s3://$(terraform output -raw frontend_bucket_name)/ --dryrun` |

---

## Tear-down ordering

```sh
# 1. App-level (Kamal): remove containers + proxy state from the box
cd backend
bundle exec kamal app remove
bundle exec kamal proxy remove

# 2. Infra (Terraform)
cd ../infra/envs/staging
terraform destroy
```

**Not destroyed by `terraform destroy`:** the remote-state S3 bucket (`truckr-tfstate-<account-id>`) and the DynamoDB lock table. These are managed by `infra/bootstrap.sh`; deleting them requires manual `aws s3 rb` + `aws dynamodb delete-table` if you want a clean slate.

CloudFront distributions take ~15 min to fully delete; `terraform destroy` blocks until the disable+delete chain completes.

---

## Break-glass: manual deploy

When CD is unavailable (GitHub down, OIDC misconfigured, urgent rollback, etc.), every CD step also runs from an operator's laptop. The Kamal config and `.kamal/secrets` use ERB / pass-through env vars so the laptop and CI paths share the same source of truth.

### Backend (Kamal)

```sh
# 1. Set the env-picking var. Defaults to staging if unset.
export TRUCKR_ENV=staging          # or production
export AWS_REGION=sa-east-1
export AWS_PROFILE=fiuba           # or whichever profile points at the account

# 2. Resolve infra IDs from SSM (matches what backend-deploy.yml does).
#    Staging deploys can skip this — the deploy.yml ERB fallback is the
#    staging hostname. Production needs these set explicitly.
export EC2_INSTANCE_ID=$(aws ssm get-parameter --name "/truckr/${TRUCKR_ENV}/ec2_instance_id" --query Parameter.Value --output text)
export APP_HOST=$(aws ssm get-parameter --name "/truckr/${TRUCKR_ENV}/app_host" --query Parameter.Value --output text)
export ECR_REGISTRY_URL=$(aws ssm get-parameter --name "/truckr/${TRUCKR_ENV}/ecr_repository_url" --query Parameter.Value --output text | sed 's|/[^/]*$||')

# 3. (Optional) Use SSM Session Manager as SSH transport (mirrors CI).
#    Needs the session-manager-plugin installed locally.
#    Without it, kamal uses direct SSH via the SG ingress rule on port 22.
export KAMAL_SSH_PROXY_COMMAND='aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p'

# 4. Roll-forward / re-deploy current main
cd backend
bundle exec kamal deploy

# 4a. Or roll-back to a specific previous SHA
bundle exec kamal app versions     # list available image tags
bundle exec kamal rollback <sha>

# 5. Smoke
curl -fsS "https://${APP_HOST}/up"
```

### Frontend

```sh
export TRUCKR_ENV=staging          # or production
export AWS_REGION=sa-east-1
export AWS_PROFILE=fiuba

cd frontend
deno task build

FRONTEND_BUCKET=$(aws ssm get-parameter --name "/truckr/${TRUCKR_ENV}/frontend_bucket" --query Parameter.Value --output text)
CFD_ID=$(aws ssm get-parameter --name "/truckr/${TRUCKR_ENV}/cloudfront_distribution_id" --query Parameter.Value --output text)

aws s3 sync dist/ "s3://${FRONTEND_BUCKET}/" --delete \
  --cache-control "max-age=31536000,public" --exclude index.html
aws s3 cp dist/index.html "s3://${FRONTEND_BUCKET}/index.html" \
  --cache-control "no-cache,no-store,must-revalidate"
aws cloudfront create-invalidation --distribution-id "$CFD_ID" --paths "/index.html"
```

### Infrastructure

For one-off targeted operations the workflow's destroy-guard would block (or AWS-side imports/state-mv):

```sh
AWS_PROFILE=fiuba terraform -chdir=infra/envs/${TRUCKR_ENV} plan   # always plan first
AWS_PROFILE=fiuba terraform -chdir=infra/envs/${TRUCKR_ENV} apply \
  -target=<module.something>                                       # targeted only when intentional
```

Avoid non-targeted `terraform apply` from a laptop — the workflow is the source of truth for non-targeted changes. Targeted applies are fine for the occasional surgical fix (e.g. the AdministratorAccess attachment in Phase 3 hotfix #251).
