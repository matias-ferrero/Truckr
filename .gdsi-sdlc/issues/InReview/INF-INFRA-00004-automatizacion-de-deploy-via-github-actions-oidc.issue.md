---
tag: INF-INFRA-00004
title: Automatización de deploy vía GitHub Actions con OIDC (infra-plan, infra-apply, backend-deploy, frontend-deploy)
priority: P2
status: in_review
plan: docs/features/INF/INF-INFRA-00004/INF-INFRA-00004-automatizacion-de-deploy-via-github-actions-oidc.plan.md
created: '2026-05-19'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/pull/143
author: Claude Code
github_issue: 202
github_repo: tcorzo/fiuba-gestion-tp
labels:
- INF
- INFRA
- ci
- P2
---

## Summary

Reemplazar el deploy hand-rolled de Truckr® (operador corre `terraform apply` desde su laptop, `kamal deploy` con SSH directo a la EC2, `deno task build && aws s3 sync` manual) por cuatro workflows de GitHub Actions que asumen el rol OIDC ya provisionado en `INF-INFRA-00003` (`module.github_oidc`): `infra-plan.yml`, `infra-apply.yml`, `backend-deploy.yml` y `frontend-deploy.yml`. El entorno `production` se scaffoldea en este issue para que `infra-apply.yml` lo trate como un job gateado por reviewer required.

## Problem Statement

Tras el merge de `INF-INFRA-00003` (PR #143), la infraestructura base existe pero todo el día-2 sigue siendo manual:

- **Terraform** corre desde la laptop del operador con credenciales largas (`~/.aws/credentials`); no hay `terraform plan` automático en PR ni `terraform apply` automático en `main`.
- **Backend deploy** requiere `kamal deploy` desde la laptop, lo cual asume llaves SSH long-lived al box y que el operador tenga `kamal` instalado vía `mise`.
- **Frontend deploy** es `deno task build && aws s3 sync dist/ s3://… && aws cloudfront create-invalidation --paths "/*"` a mano.
- **Producción no existe en infra/**: `infra/envs/staging/` es el único entorno; cualquier promoción a `production` requiere crear el environment desde cero, lo que reabre la puerta a drift entre entornos.
- **Auth a AWS sin OIDC en consumo**: el módulo `github_oidc` ya existe y emite `github_actions_role_arn`, pero ningún workflow lo asume todavía. El secreto `GHA_ROLE_ARN` ni siquiera está poblado en el repo. La promesa de "no `AWS_ACCESS_KEY_ID` largo en secrets" no se materializa hasta que se conecten los workflows.

El roadmap original quedó documentado en `PR #143` (sección *"Next Milestone — full GitHub Actions deployment automation"*). Este issue lo cierra.

## Expected Behavior

### 4 workflows nuevos en `<repo-root>/.github/workflows/`

1. **`infra-plan.yml`**
   - Disparado por `pull_request` con `paths: ["infra/**", ".github/workflows/infra-plan.yml"]`.
   - Asume el rol OIDC vía `aws-actions/configure-aws-credentials@v4` con `role-to-assume: ${{ secrets.GHA_ROLE_ARN }}`, `aws-region: sa-east-1`.
   - Corre `terraform init -backend-config=backend.hcl` + `terraform plan -out=tfplan` en `infra/envs/staging/`.
   - Postea el diff resumido del plan como comentario en el PR (vía `actions/github-script` o `dflook/terraform-github-actions@v2`). Re-comments en pushes adicionales (no spam: edita el comentario existente).
   - **No corre `apply`.** Falla loud si `terraform plan` detecta cambios destructivos no esperados (drift entre state y main).
   - Mismo job se reusa para `infra/envs/production/` cuando el path cambia, posteando ambos diffs en el comentario.

2. **`infra-apply.yml`**
   - Disparado por `push` a `main` con `paths: ["infra/**"]`.
   - Job `apply-staging`: corre `terraform apply -auto-approve` en `infra/envs/staging/`.
   - Job `apply-production`: depende de `apply-staging`, declara `environment: production` (GitHub Environment con required reviewers configurado vía UI o `gh api`).
   - Cada job sube el `tfplan` como artifact con retención de 30 días.

3. **`backend-deploy.yml`**
   - Disparado por `push` a `main` con `paths: ["backend/**", ".github/workflows/backend-deploy.yml"]` y por `workflow_dispatch` (manual con input `environment: staging|production`).
   - Steps:
     1. Asumir OIDC role.
     2. `aws ecr get-login-password ... | docker login` contra el ECR del entorno.
     3. `docker build -t $ECR_URL/truckr-backend:${{ github.sha }} backend/`.
     4. `docker push` con tag `${{ github.sha }}` Y `latest` (Kamal lee `latest` por default).
     5. Setear `RAILS_MASTER_KEY` vía `aws ssm get-parameter --name /truckr/<env>/rails_master_key --with-decryption` y exportarlo a `KAMAL_REGISTRY_PASSWORD` / al entorno de Kamal.
     6. Correr `kamal deploy` con `ssh.proxy_command` apuntado a SSM Session Manager (no abrir puerto 22 a runners de GitHub):

        ```yaml
        # backend/config/deploy.yml fragmento
        ssh:
          proxy_command: aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters portNumber=%p
        ```

     7. Smoke check: `curl --fail https://<eip>.sslip.io/up` (Kamal espera el up healthcheck igual; este es el doble check post-deploy).
   - Job para `production` gateado por GitHub Environment (mismo patrón que `infra-apply.yml`).

4. **`frontend-deploy.yml`**
   - Disparado por `push` a `main` con `paths: ["frontend/**", ".github/workflows/frontend-deploy.yml"]` y por `workflow_dispatch`.
   - Steps:
     1. Asumir OIDC role.
     2. Activar deno via `jdx/mise-action@v2` (mismo patrón que `INF-INFRA-00002`).
     3. `cd frontend && deno task build`.
     4. `aws s3 sync frontend/dist/ s3://<bucket-del-env>/ --delete --cache-control max-age=31536000,public --exclude index.html` (assets cacheables eterno por hash de vite).
     5. `aws s3 cp frontend/dist/index.html s3://<bucket>/index.html --cache-control no-cache,no-store,must-revalidate` (HTML siempre fresco).
     6. `aws cloudfront create-invalidation --distribution-id $CFD_ID --paths "/index.html"` (no `/*` porque assets nuevos tienen hash distinto).
   - Asset bucket / distribution ID se leen de SSM (`/truckr/<env>/frontend_bucket`, `/truckr/<env>/cloudfront_distribution_id`) que se exportan como outputs de Terraform y se publican en SSM por el módulo `s3_frontend`.

### Cambios en `infra/`

- **Nuevo**: `infra/envs/production/` espejando `infra/envs/staging/` con sus propios `backend.hcl.example`, `terraform.tfvars.example`, instancia de los mismos módulos. Solo varían: `project_env = "production"`, instance type (sugerido `t3.small`), retention de DLM (sugerido 30 días vs 7 en staging), tag `Environment=production`.
- **`module.github_oidc`** debe extenderse para emitir un trust policy `StringLike` que incluya `repo:tcorzo/fiuba-gestion-tp:environment:production` y `repo:…:environment:staging` además del current `repo:…:*`. Si el rol seguirá siendo único: agregar `aws ssm:PutParameter` al policy de `infra-apply.yml` para que terraform pueda escribir outputs en SSM al levantar el frontend bucket / distribution ID.
- **Output nuevo** desde `infra/envs/staging/outputs.tf` y `…/production/outputs.tf`:

  ```hcl
  output "github_actions_role_arn" { value = module.github_oidc.role_arn }
  output "ecr_repository_url"      { value = module.ecr.repository_url }
  output "ec2_instance_id"         { value = module.ec2.instance_id }
  output "frontend_bucket"         { value = module.s3_frontend.bucket_name }
  output "cloudfront_distribution_id" { value = module.s3_frontend.distribution_id }
  ```

  Los últimos cuatro se publican en SSM (`aws_ssm_parameter` con `tier = "Standard"`, `type = "String"`) bajo `/truckr/<env>/` para que los workflows los lean en vez de hardcodearlos.

### Cambios en `backend/`

- **`backend/config/deploy.yml`**: añadir `ssh.proxy_command` con AWS SSM Session Manager. Mantener `host` apuntando al `aws_instance.app.id` (no IP), porque SSM se conecta por instance ID. Documentar en el runbook que el host ahora se lee de SSM (`terraform output ec2_instance_id` poblado por `infra-apply.yml`).
- **`backend/.kamal/secrets`**: ya está usando `aws ssm get-parameter` en INF-INFRA-00003 — verificar que el CLI esté disponible en los runners de Ubuntu (`ubuntu-latest` ya lo trae preinstalado).

### Secrets / configuración en el repo

- Secret nuevo `GHA_ROLE_ARN` poblado a mano una vez tras el primer `terraform apply` de este issue: `terraform output -raw github_actions_role_arn | gh secret set GHA_ROLE_ARN`.
- GitHub Environments creados vía `gh api` (idempotente):
  - `staging` — sin required reviewers, sin wait timer.
  - `production` — required reviewers (al menos el repo owner), wait timer 0.
- Branch protection sobre `main` actualizada para marcar `infra-plan / plan-staging`, `infra-plan / plan-production`, `Backend CI`, `Frontend CI` como required checks.

## Current Behavior

- `<repo-root>/.github/workflows/` contiene `release-please.yml`, `backend-ci.yml`, `frontend-ci.yml`, `infra-ci.yml` (este último solo corre `terraform fmt -check` + `terraform validate`, no `plan` ni `apply`).
- No existe `infra/envs/production/`.
- `module.github_oidc` provisiona el rol pero ningún workflow lo asume.
- Operador deploy-ea desde laptop con `kamal deploy` + `aws s3 sync` directo.

## Reproduction Steps

1. Cambiar una línea de `infra/modules/ec2/main.tf` (p.ej. agregar un tag) y abrir un PR.
2. Observar checks del PR: `infra-ci / fmt-validate` corre, pero **no aparece** ningún `terraform plan` ni preview del diff. El reviewer no tiene contexto para aprobar.
3. Mergear el PR a `main`. Nada se aplica automáticamente. El operador descubre la diferencia cuando algo se rompe.
4. Idem para `backend/`: push a `main` no dispara redeploy.

## Impact

- **Velocidad de deploy**: 5-10 min de overhead por release manual (config de Kamal local, `aws sso login`, `kamal deploy`, validar smoke).
- **Riesgo de drift**: cualquier developer que aplique Terraform desde su laptop sin pull reciente puede sobreescribir estado. El lock de DynamoDB protege contra concurrencia, no contra "olvidé `git pull`".
- **Auditoría**: deploys manuales no quedan registrados en Actions log; no hay correlación entre commit y deploy time.
- **Onboarding**: un nuevo colaborador debe instalar `terraform`, `kamal`, `aws-cli`, `mise`, y configurar SSO antes de poder hacer nada. Con OIDC y workflows, alcanza con tener permisos al repo.
- **Security**: largos `AWS_ACCESS_KEY_ID` en `~/.aws/credentials` del operador son el principal vector de compromiso. OIDC los elimina del todo.
- **Producción nunca se podrá levantar** sin este issue: no hay `infra/envs/production/`, no hay ambiente gateado, no hay workflow que lo opere.

## Technical Notes

### Auth — OIDC trust policy detail

El módulo `github_oidc` (provisionado en INF-INFRA-00003) ya tiene un trust con `StringLike` `repo:tcorzo/fiuba-gestion-tp:*`. Esto cubre PRs y branches, pero **incluye también el trust de PRs de forks**, lo cual es un riesgo si alguien forkea el repo y abre un PR malicioso que dispara `infra-plan.yml` y lee secretos del state. Tightening recomendado para este issue:

```hcl
condition {
  test     = "StringLike"
  variable = "token.actions.githubusercontent.com:sub"
  values = [
    "repo:tcorzo/fiuba-gestion-tp:ref:refs/heads/main",
    "repo:tcorzo/fiuba-gestion-tp:environment:staging",
    "repo:tcorzo/fiuba-gestion-tp:environment:production",
    "repo:tcorzo/fiuba-gestion-tp:pull_request"  # decidir si dejarlo o no para infra-plan
  ]
}
```

Decisión a tomar en implementación: ¿`infra-plan.yml` puede correr sobre PRs de forks? Recomendación: **no**, usar `pull_request_target` con cuidado o restringir a colaboradores con `if: github.event.pull_request.head.repo.full_name == github.repository`.

### `kamal deploy` desde GHA — desafío del SSH key

Kamal autentica al host por SSH. Hoy se usa la SSH key del operador. En CI hay dos opciones:

1. **Generar una key dedicada para CI** + agregarla a `~/.ssh/authorized_keys` del usuario `ubuntu` en la EC2 (vía Terraform `aws_key_pair` o user_data). Llave privada se guarda como repo secret y se inyecta en runtime con `webfactory/ssh-agent@v0.9.0`.
2. **SSM Session Manager como ssh.proxy_command** (recomendado, ya prepped). Kamal corre `ssh ubuntu@<instance_id>` pero la conexión SSH viaja por el túnel SSM en vez de TCP/22 directo. No hace falta abrir SG inbound a runners de GitHub (cuyo CIDR es enorme y cambiante). Sigue necesitando una key — pero la key puede ser **generada efímera por job** y agregada al instance via `aws ec2-instance-connect send-ssh-public-key` (push de 60s TTL) en vez de persistente.

**Decisión propuesta**: opción 2 con `ec2-instance-connect`. Beneficio: zero llaves persistentes en CI.

### Per-env separation — workspaces vs directorios

`INF-INFRA-00003` eligió directorios (`infra/envs/staging/`). Continuar con ese patrón para `production/`. **No introducir `terraform workspace`** — Hashicorp lo recomienda solo para "small differences" y los entornos van a divergir (instance type, DLM retention, dominio, secrets path).

### Costo de la automatización

- GHA minutos: estimado <5 min/deploy × ~3 deploys/semana × 4 workflows ≈ 60 min/semana. Bien dentro del free tier (2000 min/mes en repos públicos).
- AWS: cero costo adicional. SSM Session Manager + EC2 Instance Connect + OIDC son gratis.

### Workflows que NO se tocan en este issue

- `backend-ci.yml`, `frontend-ci.yml`, `infra-ci.yml` (validación), `release-please.yml`. Siguen siendo CI; los nuevos workflows son CD.

### Toolchain

- `terraform` y `kamal` ambos pinados en `mise.toml` (terraform ya está; verificar que kamal esté). Workflows usan `jdx/mise-action@v2` para activar versions consistentes con dev local.

### Documentación a actualizar

- `docs/05-appendices/deployment-runbook.md`: secciones "Rolling deploy" y "Rollback" se reescriben para describir el flujo CI en vez del manual. Mantener una sección "Break-glass: deploy manual" al final para emergencias.
- `infra/README.md`: removible la sección de `aws sso login` + `terraform apply` manual.
- `docs/onboarding/`: nueva entrada explicando el modelo OIDC y cómo aprobar deploys de producción.

## Origin

Manual — roadmap explícito en el primer code review de PR #143 (`feat(infra): add base AWS infrastructure with Terraform`), sección *"Next Milestone — full GitHub Actions deployment automation"*. La rama de INF-INFRA-00003 ya provisionó el módulo `github_oidc` específicamente para que este issue pueda asumir el rol sin chicken-and-egg.

## Related

- **Depende de**: `INF-INFRA-00003` (PR #143) — el módulo `github_oidc`, el ECR, el SSM Parameter Store, el bucket de frontend, la EC2 con SSM agent deben existir antes de que los workflows puedan asumir el rol y operar. Si #143 no mergea, este issue no arranca.
- **Hermano**: `INF-INFRA-00001` (CI workflow patterns con filtros por paths) y `INF-INFRA-00002` (Frontend CI) — ambos establecen las convenciones (`paths:`, `concurrency`, `jdx/mise-action@v2`) que estos workflows reusan.
- **Documentos**:
  - `docs/05-appendices/deployment-runbook.md` (recién creado en #143) — se reescribe en este issue.
  - `infra/modules/github_oidc/main.tf` — el trust policy a tightening.
  - `backend/config/deploy.yml` — agregar `ssh.proxy_command`.
- **Paths nuevos**:
  - `<repo-root>/.github/workflows/{infra-plan,infra-apply,backend-deploy,frontend-deploy}.yml`
  - `infra/envs/production/` (mirror de `staging/`)
- **Paths modificados**:
  - `infra/modules/github_oidc/main.tf`, `infra/envs/staging/outputs.tf`, `infra/envs/staging/main.tf` (publicar outputs a SSM), `backend/config/deploy.yml`, `docs/05-appendices/deployment-runbook.md`, `infra/README.md`.

## Acceptance Criteria

- [ ] `<repo-root>/.github/workflows/infra-plan.yml` existe, corre `terraform plan` en `infra/envs/staging/` y `infra/envs/production/` en PRs que tocan `infra/**`, y postea el diff como comentario único (editado en pushes adicionales).
- [ ] `<repo-root>/.github/workflows/infra-apply.yml` existe, corre `terraform apply -auto-approve` en `staging` automáticamente y en `production` gateado por GitHub Environment con required reviewer.
- [ ] `<repo-root>/.github/workflows/backend-deploy.yml` existe, builda y pushea a ECR, y ejecuta `kamal deploy` usando `ssh.proxy_command` vía SSM Session Manager (sin puerto 22 abierto a internet).
- [ ] `<repo-root>/.github/workflows/frontend-deploy.yml` existe, builda con `deno task build`, sincea a S3 y crea invalidación de CloudFront limitada a `/index.html`.
- [ ] Todos los workflows usan OIDC (`aws-actions/configure-aws-credentials@v4` con `role-to-assume`); ningún `AWS_ACCESS_KEY_ID` largo aparece en `gh secret list`.
- [ ] `infra/envs/production/` existe espejando `staging/` con valores propios (instance type, DLM retention, project_env).
- [ ] `module.github_oidc` trust policy tightening: explícitamente limita a `ref:refs/heads/main`, `environment:staging`, `environment:production`. Decisión sobre PRs documentada en el plan (no se aceptan PRs de forks por default).
- [ ] Outputs de Terraform `frontend_bucket`, `cloudfront_distribution_id`, `ecr_repository_url`, `ec2_instance_id` se publican como `aws_ssm_parameter` bajo `/truckr/<env>/` para que los workflows los lean (no hardcodear IDs en YAML).
- [ ] Secret `GHA_ROLE_ARN` poblado en el repo tras primer `terraform apply` (paso manual una vez; documentado en el runbook).
- [ ] GitHub Environments `staging` (sin reviewers) y `production` (con required reviewer = repo owner) creados vía `gh api` y commiteados como script idempotente en `infra/bootstrap-environments.sh` o equivalente.
- [ ] `docs/05-appendices/deployment-runbook.md` actualizado: flujo CD reemplaza el manual; sección "Break-glass: deploy manual" preservada al final.
- [ ] `infra/README.md` simplificado: bootstrap inicial únicamente (el día-2 vive en el runbook).
- [ ] Smoke verificado en un PR de prueba sobre `infra/`: aparece comentario con `terraform plan` diff; al mergear, `apply-staging` corre solo; `apply-production` queda esperando aprobación.
- [ ] Smoke verificado en un PR sobre `backend/`: redeploy automático completo end-to-end en staging; `curl https://<eip>.sslip.io/up` devuelve 200.
- [ ] Smoke verificado en un PR sobre `frontend/`: build → S3 sync → CloudFront invalidation; `curl https://<cf-domain>/` sirve el HTML nuevo en <60s.
- [ ] Branch protection sobre `main` actualizada: `infra-plan / plan-staging`, `infra-plan / plan-production`, `Backend CI`, `Frontend CI` como required checks.
- [ ] Conventional Commits respetados: `ci(deploy): add GHA deployment automation (infra + backend + frontend)` o split en PRs por workflow si el cambio es grande.

---
**TAG:** INF-INFRA-00004 | **Priority:** P2 | **Scope:** INFRA
