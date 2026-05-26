# Truckr® — Infraestructura AWS con Terraform

Provisiona los entornos AWS (`staging`, `production`). Topología fijada por `CLAUDE.md § "Database policy"`:
- **Backend Rails** en EC2 + Docker, desplegado con **Kamal** (SQLite en volumen Docker)
- **Frontend React** en S3 + CloudFront
- **TLS** automático vía kamal-proxy + Let's Encrypt sobre un hostname `<eip>.sslip.io`
- **Secretos** en SSM Parameter Store, pulled por Kamal en deploy time
- **Estado Terraform** en S3 + DynamoDB (bucket sufijado con Account ID, compartido por todos los entornos)

Este README cubre el **primer bootstrap** (provisionar la infraestructura de un entorno por primera vez). Las operaciones día-2 (deploy con CD, rollback, rotación de secretos, backup/restore de SQLite, tear-down, break-glass manual) viven en [`docs/05-appendices/deployment-runbook.md`](../docs/05-appendices/deployment-runbook.md).

## Prerrequisitos

- AWS CLI configurado (`aws configure` o `AWS_PROFILE=fiuba`) con permisos suficientes para crear los recursos abajo listados
- Terraform y `gh` (instalados via mise: `mise install`)
- Un key pair SSH creado en la región objetivo para el operador que va a hacer break-glass: `aws ec2 create-key-pair --key-name truckr-<env>-<initials>`

## Bootstrap (una sola vez por cuenta)

Solo para la PRIMERA vez que provisionás la infraestructura en una cuenta AWS. Si ya está provisionada (chequear si el bucket `truckr-tfstate-<account-id>` existe), saltar al paso "Agregar un entorno".

### 1. Estado remoto

```sh
./infra/bootstrap.sh sa-east-1
```

Crea el bucket S3 `truckr-tfstate-<account-id>` y la tabla DynamoDB de lock. El script imprime el nombre del bucket — guardarlo para el paso siguiente.

### 2. GitHub Environments + secrets/variables

```sh
./infra/bootstrap-environments.sh
```

Crea idempotentemente:
- GitHub Environments `staging` y `production` (sin required reviewers — proyecto académico de un solo operador).
- Repo variable `TFSTATE_BUCKET` (no sensible).
- Repo secret `GHA_ROLE_ARN` (leído de `terraform output -raw github_actions_role_arn`).

Si `terraform output` aún no está disponible (porque ningún entorno se aplicó todavía), el script imprime los comandos manuales y vos los ejecutás después del primer `terraform apply` exitoso.

Por separado, setear `SSH_CIDR` (no se puede derivar automáticamente, depende de la IP del operador):

```sh
gh secret set SSH_CIDR --body "$(curl -s ifconfig.me)/32" --repo tcorzo/fiuba-gestion-tp
```

## Agregar un entorno

Por cada entorno (`staging`, `production`, futuros): el primer apply debe correr desde la laptop del operador. Los applies subsiguientes los hace `infra-apply.yml` automáticamente.

### 1. Backend config

```sh
cp infra/envs/<env>/backend.hcl.example infra/envs/<env>/backend.hcl
# Editar backend.hcl: reemplazar <YOUR_ACCOUNT_ID> con el ID real
```

`backend.hcl` está gitignored — nunca commitear.

### 2. Variables del entorno

```sh
cp infra/envs/<env>/terraform.tfvars.example infra/envs/<env>/terraform.tfvars
# Editar con los valores reales
```

| Variable | Descripción |
|----------|-------------|
| `aws_region` | Región AWS (ej. `sa-east-1`) |
| `key_pair_name` | Key pair SSH (ej. `truckr-<env>-<initials>`) |
| `ssh_cidr` | CIDR autorizado a SSH (ej. `"1.2.3.4/32"`). En `production`, port 22 es break-glass únicamente — CI usa SSM transport. |
| `rails_master_key` | Contenido de `backend/config/master.key`. Solo se lee en el primer apply (lifecycle `ignore_changes` en el módulo SSM). Para rotar después, usar el flujo del runbook. |
| `github_org` | Organización/usuario de GitHub (ej. `tcorzo`) |
| `github_repo` | Nombre del repositorio (ej. `fiuba-gestion-tp`) |

### 3. Init + plan + apply

```sh
AWS_PROFILE=fiuba terraform -chdir=infra/envs/<env> init -backend-config=backend.hcl
AWS_PROFILE=fiuba terraform -chdir=infra/envs/<env> plan
AWS_PROFILE=fiuba terraform -chdir=infra/envs/<env> apply
```

Después del primer apply exitoso del entorno `staging` (que crea `module.github_oidc`), correr `infra/bootstrap-environments.sh` de nuevo para poblar `GHA_ROLE_ARN` si no estaba.

### 4. Seed del `rails_master_key` SSM

Por defecto Terraform mete un placeholder para que el primer apply pase la validación de SSM SecureString (`length >= 1`). Reemplazar con la key real antes del primer deploy:

```sh
AWS_PROFILE=fiuba aws ssm put-parameter --overwrite \
  --name /truckr/<env>/rails_master_key \
  --value "$(cat backend/config/master.key)" \
  --type SecureString
```

Lifecycle `ignore_changes = [value]` evita que Terraform lo revierta en futuros applies.

### 5. Primer deploy (vía workflow_dispatch)

```sh
gh workflow run backend-deploy.yml --field env=<env>
gh workflow run frontend-deploy.yml --field env=<env>
```

Detalle del primer deploy + cómo verifica que todo arrancó: ver runbook.

## Estructura

```
infra/
├── bootstrap.sh                  # state backend (S3 + DynamoDB)
├── bootstrap-environments.sh     # GitHub Environments + repo secrets/variables
├── modules/
│   ├── vpc/                      # VPC, subnet pública, IGW, security group
│   ├── ecr/                      # repositorio Docker compartido (truckr-backend, account-scoped)
│   ├── ssm/                      # parámetro SSM /truckr/<env>/rails_master_key (lifecycle ignore_changes)
│   ├── ec2/                      # instancia + EIP + IAM + user_data + DLM snapshots (ami ignore_changes)
│   ├── s3_frontend/              # bucket S3 + CloudFront + OAC
│   └── github_oidc/              # OIDC provider (account-scoped) + IAM role per env + ReadOnly+Admin policies
└── envs/
    ├── staging/                  # crea ECR + OIDC provider (account-global)
    └── production/               # referencia ECR + OIDC provider via data sources
```

## Tear-down

Ver runbook (orden importa: workflows desactivados antes de `terraform destroy`, y el state backend no se destruye automáticamente).
