# INF-INFRA-00003: Alternatives Analysis — Infraestructura base en AWS con Terraform

| Field | Value |
|-------|-------|
| **Tag** | INF-INFRA-00003 |
| **Title** | Infraestructura base en AWS con Terraform |
| **Status** | PLANNED |
| **Selected** | Alternative 1: EC2 + Docker Compose + módulos custom mínimos |
| **Decision Date** | 2026-05-10 |
| **Author** | Claude Code |
| **Created** | 2026-05-10 |

---

## Context

Truckr® necesita pasar de correr exclusivamente en local a tener una infraestructura en la nube reproducible y versionada. Hay tres dimensiones de decisión que se intersectan:

1. **Cómputo**: ¿cómo se corre el backend Rails?
2. **Módulos Terraform**: ¿community modules o custom?
3. **Gestión de entornos**: workspaces vs directorios separados

Dado que se trata de un proyecto de cursada (FIUBA GDSI), el costo y la velocidad de implementación son tan relevantes como el valor pedagógico de cada opción. Las alternativas a continuación representan puntos del espectro simplicidad ↔ realismo industrial.

---

## Alternatives

### Alternative 1: EC2 + Docker Compose + módulos custom mínimos

**Approach:** Una única instancia EC2 (t3.micro/t3.small) corre el backend Rails y un Nginx reverse proxy con Docker Compose. El frontend se sirve desde S3 + CloudFront. Terraform se escribe en módulos simples propios sin dependencias de la comunidad.

**Key design decisions:**
- Docker Compose maneja la orquestación en lugar de ECS (sin overhead de task definitions, service discovery, etc.)
- Un solo estado Terraform por entorno (un directorio `infra/envs/staging/`, un directorio `infra/envs/production/`)
- RDS PostgreSQL `db.t3.micro` (free tier eligible)
- Secrets via AWS Secrets Manager o SSM Parameter Store

**Pros:**
- Costo mínimo (t3.micro + db.t3.micro están en free tier o son muy baratos)
- Arquitectura fácil de entender y depurar para cualquier miembro del equipo
- Despliegue rápido: `docker compose pull && docker compose up -d`
- No depende de abstracciones de ECS que complican el debugging
- Los módulos custom son cortos y legibles (buen material de estudio)

**Cons:**
- No escala horizontalmente sin trabajo adicional
- Un único punto de falla a nivel EC2 (mitigable con Auto Scaling Group pero aumenta complejidad)
- Menos representativo de arquitecturas de producción reales
- Actualizaciones de la app requieren SSH o un script de deploy (no rolling update nativo)

**Effort:** S  
**Risk:** Low

---

### Alternative 2: ECS Fargate + terraform-aws-modules (community modules)

**Approach:** El backend Rails corre como un servicio ECS Fargate (serverless containers). Se usan los módulos oficiales de la comunidad Terraform (`terraform-aws-modules/vpc/aws`, `terraform-aws-modules/ecs/aws`, `terraform-aws-modules/rds/aws`) para reducir el boilerplate. El frontend en S3 + CloudFront.

**Key design decisions:**
- ECS Fargate elimina la gestión de instancias EC2 subyacentes
- Los módulos de la comunidad abstraen cientos de líneas de configuración repetitiva
- Application Load Balancer (ALB) como punto de entrada HTTP/HTTPS
- ECR para almacenar imágenes Docker del backend
- Workspaces Terraform (`terraform workspace select staging`) para separar entornos

**Pros:**
- Arquitectura representativa de proyectos reales en AWS
- Rolling deployments nativos via ECS (sin downtime)
- Alta disponibilidad multi-AZ sin esfuerzo adicional
- Los community modules están probados y bien documentados
- Fácil de escalar (ajustar `desired_count` y `cpu`/`memory`)

**Cons:**
- Costo significativamente mayor que EC2 (Fargate se cobra por vCPU/hora + memoria/hora; ALB ~$20/mes)
- Mayor complejidad cognitiva: task definitions, execution roles, service discovery, target groups
- Los community modules abstraen detalles que pueden ser difíciles de debuggear
- Requiere más tiempo de implementación inicial
- Workspaces comparten el mismo state backend, lo que puede generar confusión

**Effort:** L  
**Risk:** Medium

---

### Alternative 3: ECS Fargate + módulos custom

**Approach:** Igual que Alt 2 en cuanto a arquitectura (ECS Fargate, ALB, RDS), pero todos los módulos Terraform se escriben desde cero en `infra/modules/`. Directorios separados (`infra/envs/staging/`, `infra/envs/production/`) con su propio state backend en S3.

**Key design decisions:**
- Módulos custom para VPC, ECS Service, RDS, ALB, ECR, IAM
- State separado por entorno (no workspaces) — más explícito, menos propenso a errores
- Cada módulo expone solo las variables necesarias para el proyecto, sin opciones genéricas

**Pros:**
- Control total sobre la configuración, sin sorpresas de módulos externos
- State separado por entorno es más seguro (un `apply` en staging no puede afectar production)
- Alto valor pedagógico: se entiende exactamente qué recurso se crea
- Los módulos son ligeros y específicos al proyecto

**Cons:**
- Esfuerzo de implementación más alto que Alt 2 (hay que escribir lo que los community modules ya resuelven)
- Mismo costo que Alt 2 (ECS Fargate + ALB)
- Mayor riesgo de bugs en la configuración de módulos (permisos IAM, security groups, etc.)
- Más código a mantener

**Effort:** XL  
**Risk:** High

---

## Comparison

| Criteria | Alt 1: EC2 + Compose | Alt 2: Fargate + community | Alt 3: Fargate + custom |
|----------|----------------------|---------------------------|-------------------------|
| Complejidad | Baja | Media | Alta |
| Riesgo | Bajo | Medio | Alto |
| Esfuerzo | S | L | XL |
| Costo mensual (est.) | ~$15-30 | ~$60-100 | ~$60-100 |
| Mantenibilidad | Alta | Media | Media |
| Alineación con codebase | Alta | Media | Alta |
| Valor pedagógico | Medio | Alto | Muy alto |
| Representatividad prod | Baja | Alta | Alta |

---

## Recommendation

**Recomendado: Alternative 2 — ECS Fargate + terraform-aws-modules**

Para un proyecto de cursada que también sirve como portfolio, Alt 2 ofrece el mejor balance entre esfuerzo y representatividad. Los community modules absorben el boilerplate más tedioso (security groups de RDS, IAM execution roles de ECS) y dejan el foco en la arquitectura. El costo es manejable para un entorno de staging de corta duración, y la arquitectura resultante es directamente transferible a proyectos reales. Alt 1 es válida si el presupuesto es una restricción dura; Alt 3 tiene valor pedagógico mayor pero un costo de tiempo desproporcionado para el alcance de la cursada.

---

## Decision

**Selected:** Alternative 1 — EC2 + Docker Compose + módulos custom mínimos  
**Rationale:** Para el alcance de un proyecto de cursada, el menor costo y la menor complejidad operativa son prioritarios. EC2 + Docker Compose es suficiente para hacer demos reales y aprender IaC con Terraform sin incurrir en los costos de ECS Fargate + ALB.
