# INF-INFRA-00004: Automatización de deploy vía GitHub Actions con OIDC

| Field | Value |
|-------|-------|
| **Tag** | INF-INFRA-00004 |
| **Title** | Automatización de deploy vía GitHub Actions con OIDC (infra-plan, infra-apply, backend-deploy, frontend-deploy) |
| **Priority** | P2 |
| **Status** | READY |
| **Created** | 2026-05-24 |
| **Updated** | 2026-05-24 |
| **Author** | Claude Code |
| **Depends On** | `INF-INFRA-00003` (PR #143, mergeado) — provisiona `module.github_oidc`, ECR, EC2 con SSM agent, S3 + CloudFront. |
| **Decision Doc** | N/A — el issue body fija las decisiones gruesas (OIDC obligatorio, dirs ≠ workspaces, SSM transport para Kamal, ec2-instance-connect para SSH efímero). Decisiones residuales se resuelven inline en §2. |
| **Selected Approach** | 4 workflows nuevos consumiendo el rol OIDC ya emitido; nuevo `infra/envs/production/`; tightening del trust policy; outputs de Terraform publicados a SSM. Implementación **en 5 PRs faseadas** (§3). |
| **GitHub Issue** | [#202](https://github.com/tcorzo/fiuba-gestion-tp/issues/202) |

---

## 1. Problem Statement

Tras el merge de INF-INFRA-00003 (PR #143), la infraestructura base de AWS existe (`module.vpc`, `ec2`, `ecr`, `s3_frontend`, `ssm`, `github_oidc`) y el rol OIDC `github_actions_role_arn` ya se emite como output de `infra/envs/staging/main.tf:86`. Sin embargo, **ningún workflow lo consume todavía**:

- `terraform apply` corre desde la laptop del operador con credenciales largas (`~/.aws/credentials`).
- `kamal deploy` corre desde la laptop con SSH directo al box (puerto 22 abierto al CIDR del operador).
- `deno task build && aws s3 sync && aws cloudfront create-invalidation` se hace a mano.
- `infra/envs/production/` no existe — solo staging.
- El trust policy del rol OIDC es `repo:tcorzo/fiuba-gestion-tp:*` (wildcard sobre cualquier ref, incluyendo PRs de forks).
- Los outputs de Terraform (`frontend_bucket_name`, `cloudfront_distribution_id`, `ec2_public_ip`, `ecr_repository_url`) viven solo en el state remoto; los workflows necesitarían `terraform output -raw` para leerlos en cada job, lo que cuesta init + S3 round-trip.

El roadmap de #143 cerró este issue como follow-up explícito ("Next Milestone — full GitHub Actions deployment automation"). Sin él, `production` no se puede levantar y todo el día-2 sigue manual.

---

## 2. Solution Design

Cuatro workflows nuevos en `.github/workflows/` que asumen el rol OIDC `${{ secrets.GHA_ROLE_ARN }}`. Cero `AWS_ACCESS_KEY_ID` largos en `gh secret list`. Workflows leen IDs de recursos desde SSM Parameter Store (no hardcoded en YAML), poblados por los outputs de Terraform.

### 2.1 Decisiones inline (resolución de open questions del issue)

| # | Open question (del issue) | Decisión | Por qué |
|---|---------------------------|----------|---------|
| D1 | ¿`infra-plan.yml` corre sobre PRs de forks? | **No.** Gate explícito `if: github.event.pull_request.head.repo.full_name == github.repository` en cada job del workflow. No usamos `pull_request_target` (riesgo de exfil de secrets en code execution de fork). | El proyecto es académico; nadie forkea legítimamente. El riesgo (cualquiera abre un PR malicioso que asume el rol OIDC y borra el state bucket) supera la utilidad. |
| D2 | ¿Transporte SSH para `kamal deploy` desde CI? | **SSM Session Manager como `ssh.proxy_command` + clave efímera vía `ec2-instance-connect:SendSSHPublicKey` (60s TTL).** | Cero llaves persistentes en GHA secrets; cero puerto 22 abierto a CIDRs cambiantes de runners; el módulo `ec2` ya tiene `AmazonSSMManagedInstanceCore` (`infra/modules/ec2/main.tf:30-33`). Requiere extender el inline policy del rol OIDC para incluir `ec2-instance-connect:SendSSHPublicKey` y `ssm:StartSession`. |
| D3 | ¿Per-env separation: workspaces vs dirs? | **Directorios** (`infra/envs/{staging,production}/`). | INF-INFRA-00003 ya eligió dirs; consistencia + los envs van a divergir (instance type, DLM retention, dominio). Hashicorp recomienda workspaces solo para "small differences". |
| D4 | ¿Un PR mega vs split por workflow? | **5 PRs faseadas** (§3). | El issue es grande y mezcla cambios de infra (alto blast radius) con cambios de CI (bajo). Una sola PR es irrevisable y arriesgada — un fallo en `backend-deploy` no debe forzar revertir `infra-plan`. |
| D5 | ¿Trust policy tightening retiene `pull_request` cláusula? | **No.** El sub claim explícito queda en `ref:refs/heads/main`, `environment:staging`, `environment:production`. `infra-plan.yml` corre con `permissions: id-token: write` pero gateado por `head.repo.full_name == github.repository`, y el sub claim de un PR es `pull_request` — para que sea válido tenemos que listarlo. **Lo dejamos**, pero solo para el repo (no forks por sub-claim format `repo:tcorzo/...:pull_request`). | Sin `pull_request` en la lista, `infra-plan.yml` no puede asumir el rol y se rompe el preview en PRs. |
| D6 | ¿Job de smoke check (`curl https://.../up`) bloquea el deploy o solo notifica? | **Bloquea**, con timeout 5min y 10 retries de 30s. | Si el smoke falla, el deploy está roto; mejor saberlo en el run que en el siguiente outage. |

### 2.2 Cuatro workflows nuevos

#### 2.2.1 `infra-plan.yml`

- **Trigger:** `pull_request` (types `[opened, synchronize, reopened, ready_for_review]`) con `paths: ["infra/**", ".github/workflows/infra-plan.yml"]`.
- **Permissions:** `id-token: write` (OIDC), `contents: read`, `pull-requests: write` (post comment).
- **Concurrency:** `infra-plan-${{ github.ref }}` con `cancel-in-progress: true`.
- **Gate de fork:** `if: github.event.pull_request.head.repo.full_name == github.repository` en cada job.
- **Jobs:** matrix `env: [staging, production]`. Cada job:
  1. `actions/checkout@v4`
  2. `jdx/mise-action@v4` (consistencia con `frontend-ci.yml`) para activar `terraform`
  3. `aws-actions/configure-aws-credentials@v4` con `role-to-assume: ${{ secrets.GHA_ROLE_ARN }}`, `aws-region: sa-east-1`
  4. `terraform -chdir=infra/envs/${{ matrix.env }} init -backend-config=backend.hcl`
  5. `terraform -chdir=infra/envs/${{ matrix.env }} plan -out=tfplan -no-color > plan.txt 2>&1`
  6. Si el exit code es 1 (error real, no diff), falla loud. Si es 0 (no changes) o 2 (changes detected), continúa.
  7. **Comentario único** en el PR via `actions/github-script@v7` — busca un comentario existente con marker `<!-- INFRA-PLAN-COMMENT -->` y lo edita; si no existe, lo crea. Cuerpo: ambos `plan.txt` (staging + production) en `<details>` colapsado, con resumen "X to add, Y to change, Z to destroy".
- **`backend.hcl` en CI:** los workflows asumen que `backend.hcl` existe en el repo. Hoy está gitignored (contiene `bucket = "truckr-tfstate-000946353046"` — el account ID). **Solución:** materializar `backend.hcl` en CI desde una env var `TFSTATE_BUCKET` que se setea como repo variable (no secret — el bucket name no es sensible, la access control vive en IAM). Alternativa rechazada: commitear `backend.hcl`; el account ID en el repo público es un signal de bajo valor para atacantes pero ensucia el discovery.

#### 2.2.2 `infra-apply.yml`

- **Trigger:** `push` a `main` con `paths: ["infra/**"]` y `workflow_dispatch` con input `env: [staging, production]`.
- **Permissions:** `id-token: write`, `contents: read`.
- **Concurrency:** `infra-apply-${{ matrix.env }}` con `cancel-in-progress: false` (no cancelar un apply en marcha).
- **Jobs en serie:**
  - `apply-staging`: corre `terraform apply -auto-approve` en `infra/envs/staging/`. Sube `tfplan` como artifact (retention 30 días).
  - `apply-production`: `needs: apply-staging`. Declara `environment: production` para gating con required reviewer en GitHub Environments. Mismo flujo.
- Después de cada apply, un step `Publish outputs to SSM` que toma los outputs de Terraform y los publica como `aws_ssm_parameter` (ver §2.4) — esto se hace dentro de Terraform mismo, no como step CI extra.

#### 2.2.3 `backend-deploy.yml`

- **Trigger:** `push` a `main` con `paths: ["backend/**", ".github/workflows/backend-deploy.yml"]` y `workflow_dispatch` (input `env`).
- **Permissions:** `id-token: write`, `contents: read`.
- **Concurrency:** `backend-deploy-${{ matrix.env }}` con `cancel-in-progress: false`.
- **Jobs:** matrix `env: [staging]` por default; `production` solo en `workflow_dispatch` o cuando `apply-production` completó OK (esto lo modelamos vía GitHub Environment gating, no via `needs`).
- **Steps:**
  1. `actions/checkout@v4`
  2. `jdx/mise-action@v4` (activa `ruby 3.4`, `terraform`)
  3. `bundle install --gemfile=backend/Gemfile` (Kamal es gem)
  4. `aws-actions/configure-aws-credentials@v4` con OIDC
  5. Resolver IDs desde SSM:
     ```bash
     export ECR_URL=$(aws ssm get-parameter --name /truckr/${{ matrix.env }}/ecr_repository_url --query Parameter.Value --output text)
     export EC2_INSTANCE_ID=$(aws ssm get-parameter --name /truckr/${{ matrix.env }}/ec2_instance_id --query Parameter.Value --output text)
     export APP_HOST=$(aws ssm get-parameter --name /truckr/${{ matrix.env }}/app_host --query Parameter.Value --output text)
     ```
  6. Setear vars que `backend/.kamal/secrets` espera: `AWS_REGION=sa-east-1`, `TRUCKR_ENV=${{ matrix.env }}`. Modificar `secrets` para que el path SSM sea `/truckr/${TRUCKR_ENV}/...` en vez de hardcoded `staging` (§2.5).
  7. Push de clave efímera al EC2 via `ec2-instance-connect`:
     ```bash
     ssh-keygen -t ed25519 -f /tmp/ci_deploy_key -N ""
     aws ec2-instance-connect send-ssh-public-key \
       --instance-id "$EC2_INSTANCE_ID" \
       --availability-zone "$(aws ec2 describe-instances --instance-ids "$EC2_INSTANCE_ID" --query 'Reservations[0].Instances[0].Placement.AvailabilityZone' --output text)" \
       --instance-os-user ubuntu \
       --ssh-public-key file:///tmp/ci_deploy_key.pub
     ```
     La clave dura 60s en `authorized_keys`. Kamal arranca dentro de ese window.
  8. Configurar SSH proxy para que Kamal use SSM como transporte:
     ```yaml
     # En backend/config/deploy.yml (cambio permanente, §2.6)
     ssh:
       user: ubuntu
       proxy_command: aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p
     ```
     Con `proxy_command`, Kamal hace `ssh ubuntu@<instance-id>` y SSH tunela por SSM en vez de TCP/22.
  9. `cd backend && bundle exec kamal deploy --skip-push=false`
  10. Smoke check con retry:
      ```bash
      for i in {1..10}; do
        if curl --fail --silent --max-time 5 "https://${APP_HOST}/up"; then exit 0; fi
        sleep 30
      done
      exit 1
      ```

#### 2.2.4 `frontend-deploy.yml`

- **Trigger:** `push` a `main` con `paths: ["frontend/**", ".github/workflows/frontend-deploy.yml"]` y `workflow_dispatch`.
- **Permissions:** `id-token: write`, `contents: read`.
- **Concurrency:** `frontend-deploy-${{ matrix.env }}` con `cancel-in-progress: false`.
- **Steps:**
  1. `actions/checkout@v4`
  2. `jdx/mise-action@v4` (activa `deno`, `node`)
  3. `cd frontend && deno task build`
  4. `aws-actions/configure-aws-credentials@v4` OIDC
  5. Resolver IDs desde SSM:
     ```bash
     export FRONTEND_BUCKET=$(aws ssm get-parameter --name /truckr/${{ matrix.env }}/frontend_bucket --query Parameter.Value --output text)
     export CFD_ID=$(aws ssm get-parameter --name /truckr/${{ matrix.env }}/cloudfront_distribution_id --query Parameter.Value --output text)
     ```
  6. Sync assets (cacheables eterno por hash de Vite):
     ```bash
     aws s3 sync frontend/dist/ "s3://${FRONTEND_BUCKET}/" \
       --delete --cache-control max-age=31536000,public --exclude index.html
     ```
  7. Subir HTML con no-cache (fresh siempre):
     ```bash
     aws s3 cp frontend/dist/index.html "s3://${FRONTEND_BUCKET}/index.html" \
       --cache-control no-cache,no-store,must-revalidate
     ```
  8. Invalidación CloudFront limitada a `/index.html` (los assets nuevos tienen hash distinto, no necesitan invalidación):
     ```bash
     INVALIDATION_ID=$(aws cloudfront create-invalidation \
       --distribution-id "$CFD_ID" --paths "/index.html" \
       --query 'Invalidation.Id' --output text)
     aws cloudfront wait invalidation-completed \
       --distribution-id "$CFD_ID" --id "$INVALIDATION_ID"
     ```

### 2.3 Production environment (`infra/envs/production/`)

Mirror de `staging/` con los siguientes deltas:

| Variable | Staging | Production | Por qué |
|----------|---------|------------|---------|
| `project_env` | `staging` | `production` | Tags y namespacing. |
| `instance_type` | `t3.micro` (default) | `t3.small` (override) | Headroom de RAM para producción real. |
| `ami_id` | null (último Ubuntu 22.04) | null (igual) | Consistencia. |
| ECR lifecycle: `image_count_to_keep` | `5` (default) | `10` | Rollback window más largo. |
| `key_pair_name` | `truckr-staging-fy` | `truckr-production-fy` | Llave SSH distinta por env (sigue siendo break-glass; CI usa ec2-instance-connect). |

Archivos:
- `infra/envs/production/main.tf` — espejo de staging con `env = "production"` y los overrides arriba.
- `infra/envs/production/versions.tf`, `variables.tf`, `backend.hcl.example`, `terraform.tfvars.example` — copias verbatim.
- `infra/envs/production/backend.hcl` — gitignored, contiene el mismo `bucket = "truckr-tfstate-<account-id>"` (state compartido, key distinto por env).

### 2.4 Outputs Terraform → SSM Parameters

Hoy los outputs de `infra/envs/staging/main.tf:61-89` viven solo en el state. Los workflows necesitan leerlos sin correr `terraform init/output` (lento + requiere permisos al state bucket).

**Solución:** dentro de cada env, agregar recursos `aws_ssm_parameter` que publican los outputs relevantes bajo `/truckr/<env>/...`:

```hcl
# infra/envs/staging/main.tf — append
resource "aws_ssm_parameter" "ecr_repository_url" {
  name  = "/${var.project}/${var.env}/ecr_repository_url"
  type  = "String"
  value = module.ecr.repository_url
}

resource "aws_ssm_parameter" "ec2_instance_id" {
  name  = "/${var.project}/${var.env}/ec2_instance_id"
  type  = "String"
  value = module.ec2.instance_id   # nuevo output del módulo ec2
}

resource "aws_ssm_parameter" "app_host" {
  name  = "/${var.project}/${var.env}/app_host"
  type  = "String"
  value = module.ec2.app_host
}

resource "aws_ssm_parameter" "frontend_bucket" {
  name  = "/${var.project}/${var.env}/frontend_bucket"
  type  = "String"
  value = module.s3_frontend.bucket_name
}

resource "aws_ssm_parameter" "cloudfront_distribution_id" {
  name  = "/${var.project}/${var.env}/cloudfront_distribution_id"
  type  = "String"
  value = module.s3_frontend.cloudfront_distribution_id
}
```

**Cambio en `infra/modules/ec2/outputs.tf`:** agregar `output "instance_id" { value = aws_instance.app.id }` — hoy emite `public_ip` y `app_host` pero no `instance_id`.

### 2.5 Cambios en `backend/.kamal/secrets`

Hoy el archivo hardcodea `/truckr/staging/...`. Para soportar production, parametrizar:

```bash
# backend/.kamal/secrets
TRUCKR_ENV=${TRUCKR_ENV:-staging}
AWS_REGION=${AWS_REGION:-sa-east-1}
KAMAL_REGISTRY_PASSWORD=$(aws ecr get-login-password --region "$AWS_REGION")
RAILS_MASTER_KEY=$(aws ssm get-parameter --name "/truckr/${TRUCKR_ENV}/rails_master_key" --with-decryption --query Parameter.Value --output text --region "$AWS_REGION")
SEED_ADMIN_EMAIL=$(aws ssm get-parameter --name "/truckr/${TRUCKR_ENV}/seed_admin_email" --with-decryption --query Parameter.Value --output text --region "$AWS_REGION")
SEED_ADMIN_PASSWORD=$(aws ssm get-parameter --name "/truckr/${TRUCKR_ENV}/seed_admin_password" --with-decryption --query Parameter.Value --output text --region "$AWS_REGION")
```

Default `staging` para no romper el flujo manual del operador hoy.

### 2.6 Cambios en `backend/config/deploy.yml`

Agregar `ssh.proxy_command` para que Kamal use SSM como transporte. El `host` también cambia: hoy es `ip-18-228-83-21.sslip.io`; con SSM proxy debe ser el `instance_id` (la connection viaja por SSM no por DNS):

```yaml
# backend/config/deploy.yml — fragmento
servers:
  web:
    - <%= ENV.fetch('EC2_INSTANCE_ID', 'ip-18-228-83-21.sslip.io') %>

proxy:
  ssl: true
  host: <%= ENV.fetch('APP_HOST', 'ip-18-228-83-21.sslip.io') %>
  app_port: 80

ssh:
  user: ubuntu
  proxy_command: aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p
```

**Compatibilidad con deploy manual desde laptop:** el ERB fallback a los valores actuales mantiene el flujo `kamal deploy` desde la laptop funcionando sin setear `EC2_INSTANCE_ID`. Para producción / staging real, el workflow setea los envs antes de invocar Kamal.

> Kamal soporta ERB en `deploy.yml` desde 1.5. Verificar que la versión actualmente en `Gemfile.lock` lo soporte; si no, pinear `kamal >= 1.5`.

### 2.7 Tightening del trust policy OIDC (`infra/modules/github_oidc/main.tf`)

Cambiar `StringLike` por una lista explícita:

```hcl
condition {
  test     = "StringLike"
  variable = "token.actions.githubusercontent.com:sub"
  values = [
    "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main",
    "repo:${var.github_org}/${var.github_repo}:environment:staging",
    "repo:${var.github_org}/${var.github_repo}:environment:production",
    "repo:${var.github_org}/${var.github_repo}:pull_request",
  ]
}
```

Cobertura: pushes a `main` (apply, deploys), jobs gateados por `environment:` (production approvals), y PRs (infra-plan). El gate `head.repo.full_name == github.repository` en infra-plan filtra forks aunque el sub-claim genérico `pull_request` los acepte a nivel IAM.

**Extensión al inline policy** para el flujo de Kamal:

```hcl
# Nuevo statement en module.github_oidc/main.tf
{
  Sid    = "EC2InstanceConnect"
  Effect = "Allow"
  Action = ["ec2-instance-connect:SendSSHPublicKey"]
  Resource = "arn:aws:ec2:*:*:instance/*"
  Condition = {
    StringEquals = {
      "aws:ResourceTag/Project" = var.project
    }
  }
},
{
  Sid    = "SSMSession"
  Effect = "Allow"
  Action = [
    "ssm:StartSession",
    "ssm:TerminateSession",
    "ssm:DescribeSessions",
    "ssm:GetConnectionStatus",
  ]
  Resource = [
    "arn:aws:ec2:*:*:instance/*",
    "arn:aws:ssm:*::document/AWS-StartSSHSession",
  ]
  Condition = {
    StringEquals = {
      "aws:ResourceTag/Project" = var.project
    }
  }
},
{
  Sid    = "EC2DescribeForSSH"
  Effect = "Allow"
  Action = ["ec2:DescribeInstances"]
  Resource = "*"   # describe-instances no soporta resource-level
}
```

### 2.8 GitHub Environments + secret + branch protection (bootstrap script)

Idempotente, commiteado en `infra/bootstrap-environments.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
OWNER=tcorzo
REPO=fiuba-gestion-tp

# Crear ambientes
gh api -X PUT "repos/$OWNER/$REPO/environments/staging" --silent
gh api -X PUT "repos/$OWNER/$REPO/environments/production" \
  -f wait_timer=0 \
  -F reviewers='[{"type":"User","id":'"$(gh api users/$OWNER --jq .id)"'}]' \
  --silent

# Poblar secret GHA_ROLE_ARN
ROLE_ARN=$(terraform -chdir=infra/envs/staging output -raw github_actions_role_arn)
gh secret set GHA_ROLE_ARN --body "$ROLE_ARN" --repo "$OWNER/$REPO"

# Repo variable TFSTATE_BUCKET (no es secret)
TFSTATE_BUCKET=$(awk -F'"' '/^bucket/{print $2}' infra/envs/staging/backend.hcl)
gh variable set TFSTATE_BUCKET --body "$TFSTATE_BUCKET" --repo "$OWNER/$REPO"

echo "Bootstrap complete. Required checks ahora deben actualizarse manualmente en Settings → Branches → main:"
echo "  - infra-plan / plan-staging"
echo "  - infra-plan / plan-production"
echo "  - Backend CI / test"
echo "  - Frontend CI / unit, build, e2e"
```

Branch protection se setea via UI (gh api también soporta `PUT repos/.../branches/main/protection` pero es frágil con el formato exacto de required_status_checks; UI es preferible para una sola vez).

### 2.9 Out of scope (no en este issue)

- **Migrar `infra-ci.yml` actual** (terraform fmt + validate) — sigue como está; `infra-plan.yml` lo complementa.
- **Backend / frontend CI workflows** — no se tocan.
- **WSS upgrade del kamal-proxy para Action Cable** (Notif INF-FE-00005) — ese tracking vive en `#202` también según el issue de INF-FE-00005, pero no es bloqueante de este PR y se aborda como follow-up separado si surge.
- **Deploy de DB seeds en production** — el `backend-deploy.yml` no corre `db:seed`. Eso queda para un job manual `workflow_dispatch`.

---

## 3. Implementation Tasks (Phased — 5 PRs)

Cada fase = 1 PR. Cada PR puede mergear independientemente y queda CI verde por sí solo. Orden estricto: una fase no arranca hasta que la anterior mergeó.

### Phase 1 — `infra-plan.yml` (read-only, lowest risk)

| # | Task | Status | Files |
|---|------|--------|-------|
| 1.1 | Crear `.github/workflows/infra-plan.yml` con matrix staging only (production aún no existe) | Pending | `.github/workflows/infra-plan.yml` |
| 1.2 | Setear repo variable `TFSTATE_BUCKET` manualmente vía `gh variable set` (paso operador, no en código) | Pending | — |
| 1.3 | Setear repo secret `GHA_ROLE_ARN` manualmente (`terraform output -raw github_actions_role_arn \| gh secret set GHA_ROLE_ARN`) | Pending | — |
| 1.4 | Smoke test: abrir un PR de prueba con un cambio trivial a `infra/envs/staging/main.tf` (ej. agregar un tag); verificar que el workflow corre, postea comentario con plan diff, y el comentario se edita en pushes adicionales (no se duplica) | Pending | — |
| 1.5 | Revertir el cambio de prueba antes de mergear | Pending | — |

**Conventional commit title:** `ci(deploy): add infra-plan workflow with PR comment (OIDC)`

### Phase 2 — Production env + outputs to SSM + OIDC tightening

| # | Task | Status | Files |
|---|------|--------|-------|
| 2.1 | Agregar `infra/envs/production/main.tf` (espejo de staging) | Pending | `infra/envs/production/main.tf` |
| 2.2 | Agregar `infra/envs/production/{versions.tf, variables.tf, backend.hcl.example, terraform.tfvars.example}` | Pending | 4 archivos en `infra/envs/production/` |
| 2.3 | Extender `module.ec2/outputs.tf` con `instance_id` | Pending | `infra/modules/ec2/outputs.tf` |
| 2.4 | Agregar resources `aws_ssm_parameter` para outputs en ambos envs | Pending | `infra/envs/staging/main.tf`, `infra/envs/production/main.tf` |
| 2.5 | Tightening del trust policy: cambiar `StringLike` `*` por lista explícita de subs | Pending | `infra/modules/github_oidc/main.tf` |
| 2.6 | Extender inline policy del rol OIDC con `ec2-instance-connect:SendSSHPublicKey`, `ssm:StartSession`, `ec2:DescribeInstances` | Pending | `infra/modules/github_oidc/main.tf` |
| 2.7 | Actualizar matrix de `infra-plan.yml` para incluir `production` | Pending | `.github/workflows/infra-plan.yml` |
| 2.8 | Smoke: bootstrap manual del state de production (`bootstrap.sh` ya crea el bucket compartido); crear `terraform.tfvars` + `backend.hcl` para production en la laptop del operador; correr `terraform apply` en staging primero (re-aplicar trust policy y SSM params), luego correr `terraform apply` en production por primera vez | Pending | — (operador) |

**Conventional commit title:** `ci(deploy): add production env, OIDC tightening, and Terraform→SSM outputs`

### Phase 3 — `infra-apply.yml` (gated by GitHub Environments)

| # | Task | Status | Files |
|---|------|--------|-------|
| 3.1 | Crear `.github/workflows/infra-apply.yml` con jobs `apply-staging` + `apply-production` (este último con `environment: production`) | Pending | `.github/workflows/infra-apply.yml` |
| 3.2 | Crear `infra/bootstrap-environments.sh` para crear GitHub Environments idempotentemente | Pending | `infra/bootstrap-environments.sh` |
| 3.3 | Correr `bash infra/bootstrap-environments.sh` (paso operador único) | Pending | — |
| 3.4 | Smoke: hacer un cambio trivial en `infra/envs/staging/main.tf` y mergear el PR; verificar que `apply-staging` corre solo y `apply-production` queda esperando aprobación | Pending | — |
| 3.5 | Aprobar el job de production en GitHub Actions UI; verificar que corre OK | Pending | — |

**Conventional commit title:** `ci(deploy): add infra-apply workflow with GitHub Environments gating`

### Phase 4 — `backend-deploy.yml` (Kamal vía SSM transport)

| # | Task | Status | Files |
|---|------|--------|-------|
| 4.1 | Modificar `backend/config/deploy.yml` para usar `<%= ENV.fetch(...) %>` en `servers.web`, `proxy.host`, y agregar `ssh.proxy_command` | Pending | `backend/config/deploy.yml` |
| 4.2 | Modificar `backend/.kamal/secrets` para parametrizar el path SSM con `${TRUCKR_ENV}` | Pending | `backend/.kamal/secrets` |
| 4.3 | Verificar la versión de `kamal` en `backend/Gemfile.lock` — debe ser `>= 1.5` para ERB en `deploy.yml`. Si no, bumpear en `Gemfile` | Pending | `backend/Gemfile`, `backend/Gemfile.lock` |
| 4.4 | Crear `.github/workflows/backend-deploy.yml` con ec2-instance-connect + SSM proxy + Kamal | Pending | `.github/workflows/backend-deploy.yml` |
| 4.5 | Verificar localmente: setear `TRUCKR_ENV=staging` y correr `kamal deploy` desde la laptop, asegurar que el flujo manual sigue funcionando con los nuevos defaults ERB | Pending | — |
| 4.6 | Smoke: hacer un cambio trivial en `backend/` y mergear; verificar que `backend-deploy.yml` ejecuta end-to-end en staging y el smoke check de `/up` pasa | Pending | — |

**Conventional commit title:** `ci(deploy): add backend-deploy workflow with Kamal via SSM transport`

### Phase 5 — `frontend-deploy.yml` + runbook rewrite

| # | Task | Status | Files |
|---|------|--------|-------|
| 5.1 | Crear `.github/workflows/frontend-deploy.yml` con build + s3 sync + CloudFront invalidation | Pending | `.github/workflows/frontend-deploy.yml` |
| 5.2 | Reescribir `docs/05-appendices/deployment-runbook.md`: reemplazar secciones "Rolling deploy" y "Rollback" con el flujo CD; agregar sección final "Break-glass: deploy manual" preservando los comandos manuales actuales | Pending | `docs/05-appendices/deployment-runbook.md` |
| 5.3 | Simplificar `infra/README.md`: bootstrap inicial solamente, remover día-2 (que ahora vive en el runbook) | Pending | `infra/README.md` |
| 5.4 | Smoke: cambio trivial en `frontend/` (e.g. una palabra en `landingContent.ts`) y mergear; verificar build → S3 sync → CloudFront invalidation completa; `curl https://<cf-domain>/` devuelve el HTML nuevo en <60s | Pending | — |
| 5.5 | Actualizar branch protection en Settings → Branches → main para incluir `infra-plan / plan-staging`, `infra-plan / plan-production`, `Backend CI / test`, `Frontend CI / build`, `Frontend CI / unit` como required checks | Pending | — (operador, UI) |

**Conventional commit title:** `ci(deploy): add frontend-deploy workflow and rewrite deployment runbook`

---

## 4. Code Changes (selected highlights)

### 4.1 `.github/workflows/infra-plan.yml` (Phase 1)

**Purpose**: read-only Terraform plan en PRs, posteando el diff como comentario único editado en cada push.

```yaml
name: Infra plan
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
    paths:
      - 'infra/**'
      - '.github/workflows/infra-plan.yml'

permissions:
  id-token: write
  contents: read
  pull-requests: write

concurrency:
  group: infra-plan-${{ github.ref }}
  cancel-in-progress: true

jobs:
  plan:
    if: github.event.pull_request.head.repo.full_name == github.repository
    runs-on: ubuntu-latest
    strategy:
      fail-fast: false
      matrix:
        env: [staging, production]
    steps:
      - uses: actions/checkout@v4
      - uses: jdx/mise-action@v4
        with:
          experimental: true
      - name: Configure AWS credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.GHA_ROLE_ARN }}
          aws-region: sa-east-1
      - name: Materialize backend.hcl
        run: |
          echo 'bucket = "${{ vars.TFSTATE_BUCKET }}"' > infra/envs/${{ matrix.env }}/backend.hcl
          echo 'key    = "${{ matrix.env }}/terraform.tfstate"' >> infra/envs/${{ matrix.env }}/backend.hcl
          echo 'region = "sa-east-1"' >> infra/envs/${{ matrix.env }}/backend.hcl
          echo 'dynamodb_table = "truckr-tfstate-lock"' >> infra/envs/${{ matrix.env }}/backend.hcl
      - name: Terraform init
        run: terraform -chdir=infra/envs/${{ matrix.env }} init -backend-config=backend.hcl
      - name: Terraform plan
        id: plan
        continue-on-error: true
        run: |
          set +e
          terraform -chdir=infra/envs/${{ matrix.env }} plan -no-color -out=tfplan > plan.txt 2>&1
          EXIT=$?
          echo "exit=$EXIT" >> $GITHUB_OUTPUT
          # Truncate to 60KB to fit GitHub comment limit (per env)
          head -c 60000 plan.txt > plan_truncated.txt
          mv plan_truncated.txt plan.txt
          exit 0
      - name: Upload plan artifact
        if: steps.plan.outputs.exit != '1'
        uses: actions/upload-artifact@v4
        with:
          name: tfplan-${{ matrix.env }}
          path: infra/envs/${{ matrix.env }}/tfplan
          retention-days: 30
      - name: Post/update PR comment
        if: always()
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const env = '${{ matrix.env }}';
            const plan = fs.readFileSync('plan.txt', 'utf8');
            const marker = `<!-- INFRA-PLAN-COMMENT-${env} -->`;
            const body = `${marker}\n## Terraform plan — \`${env}\`\n\n<details><summary>Show plan</summary>\n\n\`\`\`\n${plan}\n\`\`\`\n</details>`;
            const { data: comments } = await github.rest.issues.listComments({
              owner: context.repo.owner, repo: context.repo.repo, issue_number: context.issue.number
            });
            const existing = comments.find(c => c.body && c.body.includes(marker));
            if (existing) {
              await github.rest.issues.updateComment({ owner: context.repo.owner, repo: context.repo.repo, comment_id: existing.id, body });
            } else {
              await github.rest.issues.createComment({ owner: context.repo.owner, repo: context.repo.repo, issue_number: context.issue.number, body });
            }
      - name: Fail on plan error
        if: steps.plan.outputs.exit == '1'
        run: exit 1
```

**Note Phase 1 carve-out:** la matriz arranca solo con `staging` en Phase 1 PR. Production se agrega cuando Phase 2 mergea (`infra/envs/production/` existe).

### 4.2 `backend/config/deploy.yml` cambio (Phase 4)

**Purpose**: agregar `ssh.proxy_command` para SSM transport sin romper deploy manual desde laptop.

```yaml
servers:
  web:
    - <%= ENV.fetch('EC2_INSTANCE_ID', 'ip-18-228-83-21.sslip.io') %>

proxy:
  ssl: true
  host: <%= ENV.fetch('APP_HOST', 'ip-18-228-83-21.sslip.io') %>
  app_port: 80

# … resto sin cambios …

ssh:
  user: ubuntu
  proxy_command: aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p
```

> El operador local debe tener `session-manager-plugin` instalado (`brew install --cask session-manager-plugin` o equivalente). Documentar en el runbook break-glass.

### 4.3 `infra/modules/github_oidc/main.tf` — trust policy + permisos SSH (Phase 2)

**Purpose**: tightening del trust policy y permisos para `ec2-instance-connect:SendSSHPublicKey` + `ssm:StartSession`.

Reemplazar el bloque `Condition` actual con la lista explícita de subs, y agregar 3 statements nuevos al inline policy según §2.7.

---

## 5. Testing

### Unit / static
- **`terraform validate` + `terraform fmt -check`** en `infra/envs/production/` — corre como parte de `infra-ci.yml` existente, no requiere cambio.
- **`actionlint`** sobre los 4 workflows nuevos antes de pushear. Instalable vía `mise` o `brew install actionlint`. Captura typos en `paths:`, secrets refs malformados, `if:` expressions.
- **`yamllint`** opcional sobre los workflows.

### Integration smoke tests (manuales por phase, descritos en cada Phase §3)

Cada Phase incluye su propio smoke test al final, designed para fallar fast si algo está roto antes de marcar la phase como `Done`.

### CI integration tests
- **`backend-ci.yml`** y **`frontend-ci.yml`** siguen corriendo; el cambio a `backend/config/deploy.yml` no afecta los specs (Kamal solo se invoca en deploy, no en CI).
- **`infra-ci.yml`** debe seguir verde — `terraform validate` sobre staging Y production después de Phase 2.

### Rollback plan
- **Phase 1 rollback:** revertir el commit del workflow. Sin impacto en producción (era read-only).
- **Phase 2 rollback:** `terraform apply -target=...` del trust policy a la versión previa; los SSM params nuevos pueden quedar (no rompen nada si los lee algo no-existente). Revertir el commit del módulo OIDC.
- **Phase 3 rollback:** deshabilitar el workflow renombrándolo a `.disabled` o vía `gh workflow disable`. Apply manual sigue funcionando.
- **Phase 4 rollback:** revertir `backend/config/deploy.yml` y `.kamal/secrets`. El deploy manual desde laptop debe seguir funcionando porque agregamos ERB fallback.
- **Phase 5 rollback:** `gh workflow disable frontend-deploy.yml`. Sync manual sigue funcionando.

---

## 6. Acceptance Criteria

Mismo set que el issue body, con tracking por phase para granularidad:

- [ ] **(Phase 1)** `.github/workflows/infra-plan.yml` existe, corre `terraform plan` en `staging` (production en Phase 2), postea diff como comentario único editado en pushes.
- [ ] **(Phase 2)** `infra/envs/production/` existe espejando `staging` con `t3.small` + `image_count_to_keep=10`.
- [ ] **(Phase 2)** `module.github_oidc` trust policy limita explícitamente a `ref:refs/heads/main`, `environment:staging`, `environment:production`, `pull_request`. PRs de forks rechazados por `head.repo.full_name == github.repository` en infra-plan.
- [ ] **(Phase 2)** Outputs `frontend_bucket`, `cloudfront_distribution_id`, `ecr_repository_url`, `ec2_instance_id`, `app_host` publicados como `aws_ssm_parameter` bajo `/truckr/<env>/`.
- [ ] **(Phase 2)** Inline policy del rol OIDC incluye `ec2-instance-connect:SendSSHPublicKey`, `ssm:StartSession`, `ec2:DescribeInstances`.
- [ ] **(Phase 3)** `.github/workflows/infra-apply.yml` existe, applica staging automáticamente y production gateado por GitHub Environment `production` con reviewer.
- [ ] **(Phase 3)** `infra/bootstrap-environments.sh` crea ambientes y popula `GHA_ROLE_ARN` + `TFSTATE_BUCKET` idempotentemente.
- [ ] **(Phase 4)** `.github/workflows/backend-deploy.yml` builda + pushea a ECR + `kamal deploy` via `ssh.proxy_command` con SSM Session Manager.
- [ ] **(Phase 4)** Ningún `AWS_ACCESS_KEY_ID` largo en `gh secret list` (verificación: `gh secret list --repo tcorzo/fiuba-gestion-tp` solo muestra `GHA_ROLE_ARN`).
- [ ] **(Phase 4)** SSH key efímera vía `ec2-instance-connect send-ssh-public-key` (60s TTL); puerto 22 SG inbound NO abierto a CIDRs de GitHub.
- [ ] **(Phase 4)** Deploy manual desde laptop sigue funcionando (validación de regresión en el flujo del operador).
- [ ] **(Phase 5)** `.github/workflows/frontend-deploy.yml` builda con `deno task build`, sincea S3, invalida CloudFront limitada a `/index.html`.
- [ ] **(Phase 5)** `docs/05-appendices/deployment-runbook.md` actualizado: flujo CD reemplaza manual; sección "Break-glass: deploy manual" preservada al final.
- [ ] **(Phase 5)** `infra/README.md` simplificado a bootstrap inicial.
- [ ] **(Phase 5)** Branch protection en `main` requiere `infra-plan / plan-staging`, `infra-plan / plan-production`, `Backend CI / test`, `Frontend CI / build`, `Frontend CI / unit`.
- [ ] **(Phase 5)** Smoke en `frontend/`: build → S3 sync → CloudFront invalidation completa; HTML nuevo servido en <60s.
- [ ] Conventional Commits respetados en cada phase (`ci(deploy): ...`).

---

## 7. Files Summary

### New Files

| File | Phase | Description |
|------|-------|-------------|
| `.github/workflows/infra-plan.yml` | 1 | Terraform plan en PRs con PR comment. |
| `infra/envs/production/main.tf` | 2 | Mirror de staging con overrides de production. |
| `infra/envs/production/versions.tf` | 2 | Copia verbatim de staging. |
| `infra/envs/production/variables.tf` | 2 | Copia verbatim de staging. |
| `infra/envs/production/backend.hcl.example` | 2 | Template del state config. |
| `infra/envs/production/terraform.tfvars.example` | 2 | Template de variables. |
| `.github/workflows/infra-apply.yml` | 3 | Apply staging + production gateado. |
| `infra/bootstrap-environments.sh` | 3 | Crea GitHub Environments + GHA_ROLE_ARN secret. |
| `.github/workflows/backend-deploy.yml` | 4 | Kamal deploy via SSM transport. |
| `.github/workflows/frontend-deploy.yml` | 5 | Build + S3 sync + CloudFront invalidate. |

### Modified Files

| File | Phase | Changes |
|------|-------|---------|
| `infra/modules/ec2/outputs.tf` | 2 | Agregar `output "instance_id"`. |
| `infra/envs/staging/main.tf` | 2 | Agregar `aws_ssm_parameter` resources para los 5 outputs. |
| `infra/modules/github_oidc/main.tf` | 2 | Trust policy explícito; 3 statements nuevos en inline policy. |
| `backend/config/deploy.yml` | 4 | ERB en `servers.web` + `proxy.host`; agregar `ssh.proxy_command`. |
| `backend/.kamal/secrets` | 4 | Parametrizar path SSM con `${TRUCKR_ENV}`. |
| `backend/Gemfile` / `Gemfile.lock` | 4 | Solo si kamal actual < 1.5 (verificar primero). |
| `docs/05-appendices/deployment-runbook.md` | 5 | Reescribir Rolling deploy + Rollback; agregar Break-glass. |
| `infra/README.md` | 5 | Simplificar a bootstrap inicial. |

### Files NOT modified (explicitly out of scope)

- `.github/workflows/infra-ci.yml` (sigue como `fmt + validate`).
- `.github/workflows/backend-ci.yml`, `frontend-ci.yml`, `release-please.yml`, `pr-title.yml`.
- Cualquier archivo en `infra/modules/{vpc,ecr,ssm,ec2,s3_frontend}/` excepto `ec2/outputs.tf`.
- `mise.toml` (terraform y deno ya pineados; aws-cli viene con `ubuntu-latest`).
