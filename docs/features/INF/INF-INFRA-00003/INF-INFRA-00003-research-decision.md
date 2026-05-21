# INF-INFRA-00003: Alternatives Analysis — Infraestructura base en AWS con Terraform

| Field | Value |
|-------|-------|
| **Tag** | INF-INFRA-00003 |
| **Title** | Infraestructura base en AWS con Terraform |
| **Status** | PLANNED |
| **Selected** | Alternative 4: EC2 + Kamal + módulos custom mínimos |
| **Decision Date** | 2026-05-10 (Alt 1) → revisada 2026-05-12 (Alt 4) |
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

### Alternative 4: EC2 + Kamal + módulos custom mínimos

**Approach:** Misma topología que Alt 1 (una EC2 con Docker, frontend en S3 + CloudFront, módulos Terraform custom), pero el deploy del backend lo orquesta **Kamal** en lugar de un `docker compose up` invocado desde `user_data.sh`. Kamal corre desde la máquina del operador (en este PR) y desde GitHub Actions vía OIDC + SSM session-manager más adelante (INF-INFRA-00004). Kamal-proxy termina TLS automáticamente con Let's Encrypt sobre un hostname `<eip>.sslip.io`.

**Key design decisions:**
- `user_data.sh` se reduce a "instalar Docker + dejar la SSM agent registrada"; toda la lógica de pull/run/health vive en Kamal
- EIP estática asociada a la instancia para que el hostname sslip.io no cambie en stop/start y los certificados de Let's Encrypt sobrevivan reinicios
- Secretos siguen en SSM Parameter Store, pero los pull los hace el operador (vía `.kamal/secrets`) en lugar de la instancia — la IAM role de EC2 ya no necesita `ssm:GetParameter` ni permisos de pull de ECR
- SQLite en volumen Docker `truckr_storage` con DLM tomando snapshots diarios
- `config.assume_ssl = true` + `config.force_ssl = true` en Rails (kamal-proxy termina TLS y forwardea HTTP plano)

**Pros:**
- Cumple `CLAUDE.md § "Database policy" (UTMOST importance)` línea 29: *"Deploy is Kamal + single container with SQLite on the local volume"*
- TLS gratis y automático vía kamal-proxy + Let's Encrypt — no hace falta ALB ($20/mes) ni CloudFront-frontea-EC2 (complejo)
- Rolling deploys + rollback nativo (`kamal deploy`, `kamal rollback`)
- Mismos costos que Alt 1 (~$15-30/mes)
- Tightening de IAM en la instancia: ya no necesita acceso a SSM ni a ECR — Kamal inyecta credenciales por SSH
- El despliegue desde laptop hoy y desde CI mañana (INF-INFRA-00004) usan el mismo flujo

**Cons:**
- Cada operador necesita configurar AWS CLI + un keypair EC2 — más onboarding que Alt 2/3
- El deploy requiere conectividad SSH al box (puerto 22 abierto a CIDRs del equipo en este PR; mitigado por SSM-as-transport en INF-INFRA-00004)
- Falla si la EIP cambia (mitigado: la EIP es resource Terraform, no se reasigna salvo `terraform destroy`)
- sslip.io es funcional pero feo en demos — comprar un dominio real es trabajo aparte (INF-INFRA-00005)

**Effort:** S
**Risk:** Low

---

## Comparison

| Criteria | Alt 1: EC2 + Compose | Alt 2: Fargate + community | Alt 3: Fargate + custom | Alt 4: EC2 + Kamal |
|----------|----------------------|---------------------------|-------------------------|--------------------|
| Complejidad | Baja | Media | Alta | Baja |
| Riesgo | Bajo | Medio | Alto | Bajo |
| Esfuerzo | S | L | XL | S |
| Costo mensual (est.) | ~$15-30 | ~$60-100 | ~$60-100 | ~$15-30 |
| Mantenibilidad | Alta | Media | Media | Alta |
| Alineación con codebase | Alta | Media | Alta | Alta |
| Alineación con Database policy | ❌ (viola línea 29) | ❌ | ❌ | ✅ |
| TLS gratis | ❌ (requiere CloudFront/ALB extra) | ✅ (ALB + ACM) | ✅ | ✅ (Let's Encrypt) |
| Rolling deploy / rollback | ❌ (script manual) | ✅ | ✅ | ✅ (kamal deploy/rollback) |
| Valor pedagógico | Medio | Alto | Muy alto | Medio-Alto |
| Representatividad prod | Baja | Alta | Alta | Media |

---

## Recommendation

**Recomendado: Alternative 4 — EC2 + Kamal + módulos custom mínimos**

Después de la decisión documentada en `CLAUDE.md § "Database policy" (UTMOST importance)` el 2026-05-11 (que fija SQLite + Kamal como infraestructura permanente), Alt 4 es la única alternativa que no requiere amendar esa política. Mantiene la simpleza y el costo bajo de Alt 1, agrega TLS gratis vía Let's Encrypt + kamal-proxy, y prepara el camino para automatización en CI (INF-INFRA-00004) sin pivotes adicionales.

Alt 2 sigue siendo la mejor opción "representativa de producción real" para un portfolio, pero su costo (~$60-100/mes) y su contradicción con la Database policy lo descartan para este proyecto. Alt 3 sufre del mismo problema con mayor esfuerzo. Alt 1 fue la selección original cuando la política aún permitía cualquier deployer containerizado, pero el endurecimiento de la política la deja fuera.

---

## Decision

**Selected:** Alternative 4 — EC2 + Kamal + módulos custom mínimos
**Rationale:** `CLAUDE.md § "Database policy"` línea 29 — *"Deploy is Kamal + single container with SQLite on the local volume"* — es una directiva marcada UTMOST importance. Cualquier alternativa que no use Kamal requiere amendarla con justificación equivalente; ninguna de Alt 1/2/3 ofrece beneficios suficientes para hacerlo. Alt 4 también resuelve gratis el problema de TLS (Let's Encrypt vía kamal-proxy) que en Alt 1 quedaba como deuda pendiente, y deja el roadmap a INF-INFRA-00004 (CI deploy via OIDC + SSM session-manager) sin pivotes intermedios.

**Decisión previa (2026-05-10):** Alt 1 fue seleccionada antes del endurecimiento de la Database policy. Se reemplaza por Alt 4 el 2026-05-12 tras code review en PR #143.
