---
tag: INF-INFRA-00003
title: Infraestructura base en AWS con Terraform
priority: P2
status: ready
created: '2026-05-10'
source: manual
source_url: ''
author: Claude Code
decision_doc: docs/features/INF/INF-INFRA-00003/INF-INFRA-00003-research-decision.md
plan: docs/features/INF/INF-INFRA-00003/INF-INFRA-00003-infraestructura-base-aws-terraform.plan.md
labels:
- INF
- INFRA
- terraform
- aws
---

## Summary

Provisionar la infraestructura base de Truckr® en AWS usando Terraform, incluyendo los recursos mínimos necesarios para alojar el backend Rails y el frontend React de forma reproducible y versionada.

## Problem Statement

El proyecto no cuenta con infraestructura en la nube definida como código. Para poder desplegar la aplicación (backend Rails + frontend React/Deno) en un entorno real se necesita una base de infraestructura reproducible y versionada con Terraform.

## Expected Behavior

Ejecutar `terraform apply` desde el directorio `infra/` debe aprovisionar todos los recursos AWS necesarios para correr la aplicación en un entorno funcional (staging o producción).

## Current Behavior

No existe directorio `infra/` ni configuración de Terraform. El proyecto corre únicamente en local.

## Reproduction Steps

N/A — es una nueva funcionalidad, no un bug.

## Impact

Bloquea cualquier despliegue real de la aplicación. Afecta a todo el equipo y a la capacidad de hacer demos con datos reales.

## Technical Notes

- Scope mínimo sugerido (ajustable en la fase de planning):
  - **VPC** con subnets públicas y privadas, Internet Gateway, NAT Gateway
  - **RDS PostgreSQL** (instancia pequeña, Multi-AZ opcional)
  - **ECS Fargate** o **EC2** para el backend Rails (Dockerfile a crear)
  - **S3 + CloudFront** para assets estáticos del frontend
  - **ECR** para imágenes Docker
  - **IAM roles** con privilegio mínimo
  - **Secrets Manager** para credenciales (DB, Rails master key)
  - **Route53** (opcional) si se dispone de dominio
- Estado de Terraform en **S3 + DynamoDB** (backend remoto) para colaboración en equipo
- Usar variables y workspaces para separar `staging` de `production`
- Seguir convención de directorios: `infra/modules/` para módulos reutilizables, `infra/envs/staging/` e `infra/envs/production/` para configuraciones por entorno

## Related

- `backend/` — app Rails a desplegar
- `frontend/` — app React/Deno a desplegar como assets estáticos
- INF-INFRA-00001 — Mover workflows de CI (puede necesitar paso de `terraform plan` en CI)
- INF-INFRA-00002 — Frontend CI (CloudFront invalidation post-deploy)

## Acceptance Criteria

- [ ] Existe directorio `infra/` con estructura de módulos y entornos
- [ ] `terraform init && terraform plan` se ejecuta sin errores en entorno limpio
- [ ] Recursos mínimos definidos: VPC, subnets, RDS, cómputo (ECS Fargate o EC2), S3, ECR, IAM
- [ ] Estado remoto configurado en S3 + DynamoDB
- [ ] Variables de entorno y secretos gestionados vía Secrets Manager (no hardcodeados)
- [ ] README en `infra/` con instrucciones de bootstrap (permisos AWS necesarios, pasos de primer `apply`)
- [ ] El pipeline de CI valida `terraform fmt` y `terraform validate` en cada PR
