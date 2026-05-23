---
tag: INF-INFRA-00003
title: Infraestructura base en AWS con Terraform
priority: P2
status: done
created: '2026-05-10'
source: manual
source_url: ''
author: Claude Code
last_synced: 2026-05-11T22:37:55.720804+00:00Z
github_issue: 141
labels:
- INF
decision_doc: docs/features/INF/INF-INFRA-00003/INF-INFRA-00003-research-decision.md
plan: docs/features/INF/INF-INFRA-00003/INF-INFRA-00003-infraestructura-base-aws-terraform.plan.md
---

## Summary

Provisionar la infraestructura base de Truckr® en AWS usando Terraform, incluyendo los recursos mínimos necesarios para alojar el backend Rails y el frontend React de forma reproducible y versionada.

## Problem Statement

El proyecto no cuenta con infraestructura en la nube definida como código. Para poder desplegar la aplicación (backend Rails + frontend React/Deno) en un entorno real se necesita una base de infraestructura reproducible y versionada con Terraform.

## Expected Behavior

Ejecutar `terraform apply` desde el directorio `infra/` debe aprovisionar todos los recursos AWS necesarios para correr la aplicación en un entorno funcional (staging o producción).

## Current Behavior

No existe directorio `infra/` ni configuración de Terraform. El proyecto corre únicamente en local.

## Technical Notes

- Scope mínimo (ajustado tras la decisión Alt 4 en `research-decision.md`):
  - **VPC** con subnet pública, Internet Gateway (sin NAT — staging solo necesita conectividad saliente desde la pública)
  - **EC2** + Docker + Kamal para el backend Rails (no ECS, no Compose-en-user-data)
  - **EIP** asociada a la instancia para hostname estable en sslip.io
  - **S3 + CloudFront** para assets estáticos del frontend
  - **ECR** para imágenes Docker (Kamal hace push desde la laptop del operador)
  - **IAM roles** con privilegio mínimo — `AmazonSSMManagedInstanceCore` en la instancia, no permisos directos a SSM Parameter Store ni a ECR (Kamal inyecta credenciales por SSH)
  - **SSM Parameter Store** como source-of-truth de `RAILS_MASTER_KEY` (no Secrets Manager — funcionalmente equivalente, ~10× más barato)
  - **DLM** para snapshots diarios del volumen EBS (backup SQLite)
- Estado de Terraform en **S3 + DynamoDB** (backend remoto), bucket sufijado con Account ID para evitar colisión global
- Directorios separados (`infra/envs/staging/`, futuro `infra/envs/production/`) — no workspaces
- **RDS deliberadamente excluido** por `CLAUDE.md § "Database policy"` línea 29 (SQLite permanente, no managed-Postgres)
- **Secrets Manager reemplazado por SSM Parameter Store** por costo — la AC original decía "Secrets Manager" antes de la decisión Alt 4
- **Compose-en-user-data considerado y rechazado** por el mismo § "Database policy" línea 29 (Kamal es el deployer fijado por política)

## Acceptance Criteria

- [x] Existe directorio `infra/` con estructura de módulos y entornos
- [x] `terraform init && terraform validate` se ejecuta sin errores (verificado local; no hay credenciales AWS en CI)
- [x] Recursos mínimos definidos: VPC, subnet, EC2 + EIP, S3 + CloudFront, ECR, IAM, SSM, DLM
- [x] Estado remoto configurado en S3 + DynamoDB con lock
- [x] Secretos gestionados vía SSM Parameter Store (no hardcodeados; pulled por Kamal en deploy time)
- [x] README en `infra/` con instrucciones de bootstrap + runbook de día-2 en `docs/05-appendices/deployment-runbook.md`
- [x] CI valida `terraform fmt` y `terraform validate` en cada PR

---
**TAG:** INF-INFRA-00003 | **Priority:** P2 | **Scope:** INFRA
