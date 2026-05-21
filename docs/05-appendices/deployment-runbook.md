# Deployment runbook — Truckr® staging

Day-2 operations for the AWS staging environment provisioned by `infra/envs/staging/`. First-bootstrap steps live in [`infra/README.md`](../../infra/README.md); this file owns recurring operations.

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

## First deploy (after `terraform apply`)

After `terraform apply` succeeds:

```sh
# 1. Read the outputs Kamal needs
cd infra/envs/staging
APP_HOST=$(terraform output -raw app_host)              # e.g. ip-54-210-15-77.sslip.io
ECR_URL=$(terraform output -raw ecr_repository_url)
EIP=$(terraform output -raw ec2_public_ip)

# 2. Patch backend/config/deploy.yml — replace the three REPLACE_WITH_* placeholders
#    with $APP_HOST (servers.web + proxy.host) and $ECR_URL (registry.server).
#    See "Editing deploy.yml" below for the sed one-liner.

# 3. Run kamal setup (installs Docker if missing, boots kamal-proxy, deploys first version)
cd ../../../backend
bundle exec kamal setup
```

`kamal setup` does: SSH connectivity check → install Docker on the box (idempotent; user_data already did this) → boot kamal-proxy → push image to ECR → pull on the box → start the container → register with the proxy → Let's Encrypt issues the cert (HTTP-01 challenge to `$APP_HOST`).

Smoke test: `curl -fsS https://$APP_HOST/up` should return 200.

### Editing `deploy.yml` after `terraform apply`

The three `REPLACE_WITH_*` placeholders are intentionally non-templated. The fastest patch:

```sh
sed -i \
  -e "s|REPLACE_WITH_app_host_OUTPUT|$APP_HOST|g" \
  -e "s|REPLACE_WITH_ecr_repository_url_OUTPUT|$ECR_URL|g" \
  backend/config/deploy.yml
```

The EIP and ECR URL are stable across redeploys, so you only do this once per environment.

---

## Rolling deploy

```sh
cd backend
bundle exec kamal deploy
curl -fsS https://$APP_HOST/up
```

Kamal builds the image locally (amd64), pushes to ECR, pulls on the box, swaps containers via kamal-proxy with zero downtime, and prunes the old container. Average time on `t3.micro`: ~90s.

---

## Rollback

```sh
bundle exec kamal app versions          # list tags
bundle exec kamal rollback <prev-sha>    # roll back to a previous image
```

Image tags are content-hashed by Kamal. If the bad version was deployed via `kamal deploy`, the previous tag is still in ECR (lifecycle policy: keep last 10).

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

1. Generate new key: `cd backend && bundle exec rails credentials:edit` saves a fresh value if you regenerate `config/master.key`. Or generate via `openssl rand -hex 32`.
2. Update SSM: `aws ssm put-parameter --name /truckr/staging/rails_master_key --value '<new>' --type SecureString --overwrite`
3. Redeploy: `bundle exec kamal deploy` (every operator's `.kamal/secrets` will pull the new value from SSM on next deploy)
4. Verify: `curl -fsS https://$APP_HOST/up` and check `bundle exec kamal app logs --grep "credentials"` for decryption errors.

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
