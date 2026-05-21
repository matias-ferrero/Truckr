# Truckr® — Infraestructura AWS con Terraform

Provisiona el entorno de staging en AWS. Topología fijada por `CLAUDE.md § "Database policy"`:
- **Backend Rails** en EC2 `t3.micro` + Docker, desplegado con **Kamal** (SQLite en volumen Docker)
- **Frontend React** en S3 + CloudFront
- **TLS** automático vía kamal-proxy + Let's Encrypt sobre un hostname `<eip>.sslip.io`
- **Secretos** en SSM Parameter Store, pulled por Kamal en deploy time
- **Estado Terraform** en S3 + DynamoDB (bucket sufijado con Account ID)

Este README cubre el **primer bootstrap** (provisionar la infraestructura). Las operaciones día-2 (deploy con Kamal, rollback, rotación de secretos, backup/restore de SQLite, tear-down) viven en [`docs/05-appendices/deployment-runbook.md`](../docs/05-appendices/deployment-runbook.md).

## Prerrequisitos

- AWS CLI configurado (`aws configure`) con permisos suficientes para crear los recursos abajo listados
- Terraform (instalado via mise: `mise install`)
- Un key pair SSH creado en la región objetivo: `aws ec2 create-key-pair --key-name truckr-staging-<initials>`

## Bootstrap (una sola vez)

### 1. Estado remoto

```sh
./infra/bootstrap.sh sa-east-1
```

Crea el bucket S3 `truckr-tfstate-<account-id>` y la tabla DynamoDB de lock. El script imprime el nombre del bucket — guardarlo para el paso siguiente.

### 2. Backend config

```sh
cp infra/envs/staging/backend.hcl.example infra/envs/staging/backend.hcl
# Editar backend.hcl: reemplazar <YOUR_ACCOUNT_ID> con el ID real
```

`backend.hcl` está gitignored — nunca commitear.

### 3. Variables del entorno

```sh
cp infra/envs/staging/terraform.tfvars.example infra/envs/staging/terraform.tfvars
# Editar con los valores reales
```

| Variable | Descripción |
|----------|-------------|
| `aws_region` | Región AWS (ej. `sa-east-1`) |
| `key_pair_name` | Nombre del key pair SSH creado en el paso anterior |
| `ssh_cidr` | CIDR autorizado a SSH (ej. `"1.2.3.4/32"` — la IP del operador) |
| `rails_master_key` | Contenido de `backend/config/master.key` (semilla inicial del SecureString) |
| `github_org` | Organización/usuario de GitHub (ej. `tcorzo`) |
| `github_repo` | Nombre del repositorio (ej. `fiuba-gestion-tp`) |

### 4. Init + plan + apply

```sh
terraform -chdir=infra/envs/staging init -backend-config=backend.hcl
terraform -chdir=infra/envs/staging plan
terraform -chdir=infra/envs/staging apply
```

### 5. Capturar outputs para Kamal

```sh
cd infra/envs/staging
terraform output app_host                # → backend/config/deploy.yml proxy.host + servers.web
terraform output ecr_repository_url      # → backend/config/deploy.yml registry.server
terraform output github_actions_role_arn # → GitHub repo secret GHA_ROLE_ARN (INF-INFRA-00004)
```

Pegar `app_host` y `ecr_repository_url` en `backend/config/deploy.yml` reemplazando los placeholders `REPLACE_WITH_*`. El runbook tiene el `sed` listo.

### 6. Primer deploy

```sh
cd backend
bundle exec kamal setup
curl -fsS https://$(terraform -chdir=../infra/envs/staging output -raw app_host)/up
```

Kamal instala lo que falte en el box, arranca kamal-proxy, hace push de la imagen, y Let's Encrypt emite el certificado. Detalle en el runbook.

## Estructura

```
infra/
├── bootstrap.sh              # script de bootstrap del state backend (correr una vez)
├── modules/
│   ├── vpc/                  # VPC, subnet pública, IGW, security group
│   ├── ecr/                  # repositorio de imágenes Docker (truckr-backend)
│   ├── ssm/                  # parámetro SSM /truckr/staging/rails_master_key
│   ├── ec2/                  # instancia + EIP + IAM + user_data + DLM snapshots
│   ├── s3_frontend/          # bucket S3 + CloudFront + OAC
│   └── github_oidc/          # OIDC provider + IAM role para GHA (consumido en INF-INFRA-00004)
└── envs/
    └── staging/              # un único entorno por ahora
```

## Tear-down

Ver runbook (orden importa: `kamal app remove` antes de `terraform destroy`, y el state backend no se destruye automáticamente).
