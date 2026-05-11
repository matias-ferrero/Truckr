# INF-INFRA-00003: Infraestructura base en AWS con Terraform

| Field | Value |
|-------|-------|
| **Tag** | INF-INFRA-00003 |
| **Title** | Infraestructura base en AWS con Terraform |
| **Priority** | P2 |
| **Status** | READY |
| **Created** | 2026-05-10 |
| **Updated** | 2026-05-10 |
| **Author** | Claude Code |
| **Depends On** | — |
| **Decision Doc** | [INF-INFRA-00003-research-decision.md](INF-INFRA-00003-research-decision.md) |
| **Selected Approach** | Alternative 1: EC2 + Docker Compose + módulos custom mínimos |

---

## 1. Problem Statement

El proyecto no tiene infraestructura en la nube definida como código. Para desplegar Truckr® en un entorno real se necesita una base Terraform reproducible y versionada. Se usa la opción de menor costo y complejidad: una EC2 corriendo Docker Compose para el backend Rails (que ya usa SQLite, evitando el costo de RDS), con el frontend React servido desde S3 + CloudFront.

---

## 2. Solution Design

Una instancia EC2 `t3.micro` (free-tier eligible) corre el backend Rails via Docker Compose. La base de datos SQLite se persiste en un volumen EBS adjunto. El frontend se compila con `deno task build` y se sube a S3, expuesto via CloudFront. Los secretos (Rails master key) se almacenan en SSM Parameter Store. Terraform usa módulos custom mínimos con estado remoto en S3 + DynamoDB lock.

### Estructura de directorios

```
infra/
├── README.md                  # instrucciones de bootstrap y variables
├── modules/
│   ├── vpc/                   # VPC, subnet pública, IGW, route table, SG
│   ├── ecr/                   # repositorio ECR para la imagen del backend
│   ├── ec2/                   # instancia, IAM role, key pair, user_data
│   ├── ssm/                   # parámetros en SSM Parameter Store
│   └── s3_frontend/           # bucket S3 + CloudFront distribution (OAC)
└── envs/
    └── staging/
        ├── backend.tf          # remote state S3 + DynamoDB
        ├── versions.tf         # required_providers aws ~> 5.0
        ├── main.tf             # wiring de módulos
        ├── variables.tf        # variables del entorno
        └── terraform.tfvars.example
```

### Flujo de deploy (manual, primera iteración)

1. Bootstrap manual: crear bucket S3 + tabla DynamoDB para el state (una sola vez).
2. `terraform -chdir=infra/envs/staging init && apply` — crea VPC, EC2, ECR, S3, CloudFront.
3. `docker build` en `backend/` → `docker push` al ECR.
4. SSH a EC2 → `docker compose -f docker-compose.prod.yml pull && up -d`.
5. `deno task build` en `frontend/` → `aws s3 sync dist/ s3://<bucket>/` → CloudFront invalidation.

---

## 3. Implementation Tasks

| # | Task | Status | Files |
|---|------|--------|-------|
| 1 | Bootstrap script + README con instrucciones | Pending | `infra/README.md`, `infra/bootstrap.sh` |
| 2 | `versions.tf` y `backend.tf` para staging | Pending | `infra/envs/staging/versions.tf`, `infra/envs/staging/backend.tf` |
| 3 | Módulo `vpc`: VPC, subnet pública, IGW, route table, security group EC2 | Pending | `infra/modules/vpc/main.tf`, `variables.tf`, `outputs.tf` |
| 4 | Módulo `ecr`: repositorio Docker + lifecycle policy | Pending | `infra/modules/ecr/main.tf`, `variables.tf`, `outputs.tf` |
| 5 | Módulo `ssm`: parámetro `RAILS_MASTER_KEY` (SecureString) | Pending | `infra/modules/ssm/main.tf`, `variables.tf`, `outputs.tf` |
| 6 | Módulo `ec2`: instancia, IAM role/instance profile, user_data | Pending | `infra/modules/ec2/main.tf`, `user_data.sh`, `variables.tf`, `outputs.tf` |
| 7 | Módulo `s3_frontend`: bucket + OAC + CloudFront distribution | Pending | `infra/modules/s3_frontend/main.tf`, `variables.tf`, `outputs.tf` |
| 8 | Wiring en `infra/envs/staging/main.tf` + variables + tfvars.example | Pending | `infra/envs/staging/main.tf`, `variables.tf`, `terraform.tfvars.example` |
| 9 | `backend/docker-compose.prod.yml` | Pending | `backend/docker-compose.prod.yml` |
| 10 | CI: job `infra-validate` (fmt + validate) en PRs que tocan `infra/` | Pending | `.github/workflows/infra-ci.yml` |

---

## 4. Code Changes

### 4.1 `infra/envs/staging/backend.tf`

**Purpose**: Estado remoto compartido con lock para evitar apply concurrentes.

```hcl
terraform {
  backend "s3" {
    bucket         = "truckr-tfstate"
    key            = "staging/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "truckr-tfstate-lock"
    encrypt        = true
  }
}
```

### 4.2 `infra/envs/staging/versions.tf`

```hcl
terraform {
  required_version = "~> 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}
```

### 4.3 `infra/modules/vpc/main.tf` (fragmento)

**Purpose**: Red mínima con una subnet pública, IGW y security group para la EC2.

```hcl
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  tags = { Name = "${var.project}-${var.env}-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "this" { vpc_id = aws_vpc.this.id }

resource "aws_route_table" "public" { vpc_id = aws_vpc.this.id }
resource "aws_route" "default" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ec2" {
  vpc_id = aws_vpc.this.id
  ingress { from_port = 80;  to_port = 80;  protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 443; to_port = 443; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 22;  to_port = 22;  protocol = "tcp"; cidr_blocks = [var.ssh_cidr] }
  egress  { from_port = 0;   to_port = 0;   protocol = "-1";  cidr_blocks = ["0.0.0.0/0"] }
}
```

### 4.4 `infra/modules/ec2/user_data.sh`

**Purpose**: Provisiona la EC2 en el primer boot: instala Docker, autentica en ECR, arranca Compose.

```bash
#!/bin/bash
set -euo pipefail

apt-get update -y
apt-get install -y docker.io docker-compose-plugin awscli

systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# Auth ECR
aws ecr get-login-password --region ${aws_region} | \
  docker login --username AWS --password-stdin ${ecr_url}

# Fetch secret from SSM
RAILS_MASTER_KEY=$(aws ssm get-parameter \
  --name "/truckr/${env}/rails_master_key" \
  --with-decryption \
  --query Parameter.Value \
  --output text)
export RAILS_MASTER_KEY

# Deploy
mkdir -p /opt/truckr
cat > /opt/truckr/docker-compose.prod.yml << 'COMPOSE'
${docker_compose_content}
COMPOSE

cd /opt/truckr
ECR_URL=${ecr_url} RAILS_MASTER_KEY=$RAILS_MASTER_KEY \
  docker compose -f docker-compose.prod.yml pull
ECR_URL=${ecr_url} RAILS_MASTER_KEY=$RAILS_MASTER_KEY \
  docker compose -f docker-compose.prod.yml up -d
```

### 4.5 `backend/docker-compose.prod.yml`

**Purpose**: Compose de producción; SQLite persiste en volumen EBS montado en `/rails/storage`.

```yaml
services:
  web:
    image: "${ECR_URL}/truckr-backend:latest"
    ports:
      - "80:80"
    environment:
      RAILS_ENV: production
      RAILS_MASTER_KEY: "${RAILS_MASTER_KEY}"
    volumes:
      - db_data:/rails/storage
    restart: unless-stopped

volumes:
  db_data:
```

### 4.6 `infra/modules/ec2/main.tf` (IAM fragment)

**Purpose**: IAM role que permite a la EC2 leer ECR y SSM sin credenciales hardcodeadas.

```hcl
resource "aws_iam_role" "ec2" {
  name = "${var.project}-${var.env}-ec2"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ec2_ssm_ecr" {
  role = aws_iam_role.ec2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = "arn:aws:ssm:${var.aws_region}:*:parameter/truckr/${var.env}/*"
      },
      {
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken", "ecr:BatchGetImage",
                    "ecr:GetDownloadUrlForLayer"]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project}-${var.env}-ec2"
  role = aws_iam_role.ec2.name
}
```

### 4.7 `.github/workflows/infra-ci.yml`

**Purpose**: Valida formato y sintaxis de Terraform en cualquier PR que modifique `infra/`.

```yaml
name: Infra CI
on:
  pull_request:
    paths:
      - 'infra/**'

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "~1.9"
      - name: fmt check
        run: terraform fmt -check -recursive infra/
      - name: validate
        run: |
          cd infra/envs/staging
          terraform init -backend=false
          terraform validate
```

### 4.8 `infra/bootstrap.sh`

**Purpose**: Crea los recursos de estado remoto una sola vez (se corre manualmente antes del primer `apply`).

```bash
#!/bin/bash
# Run once: aws configure first, then ./infra/bootstrap.sh
set -euo pipefail
REGION=${1:-us-east-1}
BUCKET="truckr-tfstate"
TABLE="truckr-tfstate-lock"

aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
  $([ "$REGION" != "us-east-1" ] && echo "--create-bucket-configuration LocationConstraint=$REGION")
aws s3api put-bucket-versioning --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket "$BUCKET" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

aws dynamodb create-table --table-name "$TABLE" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"

echo "Bootstrap complete. Now run: terraform -chdir=infra/envs/staging init"
```

---

## 5. Testing

### Validación estática (CI — automática en cada PR)
- `terraform fmt -check -recursive infra/` — sin diff de formato
- `terraform validate` con `-backend=false` — sin errores de sintaxis ni tipos

### Smoke test manual (post-`terraform apply`)
- `curl http://<EC2_PUBLIC_IP>/up` → `200 OK` (Rails health endpoint)
- `curl https://<CLOUDFRONT_DOMAIN>/` → landing page del frontend
- SSH a EC2: `docker compose -f /opt/truckr/docker-compose.prod.yml ps` → servicio `web` en estado `Up`
- Verificar que SQLite persiste tras `docker compose restart`

---

## 6. Acceptance Criteria

- [ ] `infra/` existe con la estructura de módulos y entornos descrita en §2
- [ ] `terraform init && terraform plan` se ejecuta sin errores con credenciales AWS válidas
- [ ] Recursos creados: VPC, subnet pública, IGW, SG, EC2 t3.micro, ECR repo, SSM parameter, S3 bucket, CloudFront distribution
- [ ] Estado remoto en S3 + DynamoDB (lock funciona con `terraform apply` concurrente)
- [ ] `RAILS_MASTER_KEY` leída desde SSM, no hardcodeada en ningún archivo versionado
- [ ] Backend Rails responde `GET /up → 200` desde la IP pública de EC2
- [ ] Frontend servido desde la URL de CloudFront
- [ ] CI valida `terraform fmt` y `terraform validate` en cada PR que toca `infra/`
- [ ] `infra/README.md` documenta: prerrequisitos (AWS CLI + permisos), bootstrap, primer apply, deploy manual

---

## 7. Files Summary

### New Files
| File | Description |
|------|-------------|
| `infra/README.md` | Instrucciones de bootstrap y uso |
| `infra/bootstrap.sh` | Script one-time para crear bucket S3 + tabla DynamoDB |
| `infra/envs/staging/backend.tf` | Remote state S3 + DynamoDB |
| `infra/envs/staging/versions.tf` | Provider AWS + versión Terraform |
| `infra/envs/staging/main.tf` | Wiring de módulos para staging |
| `infra/envs/staging/variables.tf` | Variables del entorno |
| `infra/envs/staging/terraform.tfvars.example` | Ejemplo de valores (sin secretos) |
| `infra/modules/vpc/main.tf` | VPC, subnet pública, IGW, route table, SG |
| `infra/modules/vpc/variables.tf` | |
| `infra/modules/vpc/outputs.tf` | |
| `infra/modules/ecr/main.tf` | Repositorio ECR + lifecycle policy |
| `infra/modules/ecr/variables.tf` | |
| `infra/modules/ecr/outputs.tf` | |
| `infra/modules/ssm/main.tf` | Parámetro SSM RAILS_MASTER_KEY |
| `infra/modules/ssm/variables.tf` | |
| `infra/modules/ssm/outputs.tf` | |
| `infra/modules/ec2/main.tf` | Instancia EC2, IAM role, instance profile |
| `infra/modules/ec2/user_data.sh` | Script de provisioning en primer boot |
| `infra/modules/ec2/variables.tf` | |
| `infra/modules/ec2/outputs.tf` | |
| `infra/modules/s3_frontend/main.tf` | Bucket S3 + CloudFront OAC distribution |
| `infra/modules/s3_frontend/variables.tf` | |
| `infra/modules/s3_frontend/outputs.tf` | |
| `backend/docker-compose.prod.yml` | Compose de producción (SQLite en volumen) |
| `.github/workflows/infra-ci.yml` | CI de validación Terraform |

### Modified Files
Ninguno — todo es código nuevo.
