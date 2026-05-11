---
tag: INF-INFRA-00003
title: Infraestructura base en AWS con Terraform
priority: P2
status: ready
created: '2026-05-10'
source: manual
source_url: ''
author: Claude Code
last_synced: 2026-05-11T22:37:55.720804+00:00Z
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

- Scope mínimo sugerido:
  - **VPC** con subnets públicas y privadas, Internet Gateway, NAT Gateway
  - **RDS PostgreSQL** (instancia pequeña)
  - **ECS Fargate** o **EC2** para el backend Rails
  - **S3 + CloudFront** para assets estáticos del frontend
  - **ECR** para imágenes Docker
  - **IAM roles** con privilegio mínimo
  - **Secrets Manager** para credenciales
- Estado de Terraform en **S3 + DynamoDB** (backend remoto)
- Workspaces para separar `staging` de `production`

## Acceptance Criteria

- [ ] Existe directorio `infra/` con estructura de módulos y entornos
- [ ] `terraform init && terraform plan` se ejecuta sin errores en entorno limpio
- [ ] Recursos mínimos definidos: VPC, subnets, RDS, cómputo, S3, ECR, IAM
- [ ] Estado remoto configurado en S3 + DynamoDB
- [ ] Secretos gestionados vía Secrets Manager
- [ ] README en `infra/` con instrucciones de bootstrap
- [ ] CI valida `terraform fmt` y `terraform validate` en cada PR

---
**TAG:** INF-INFRA-00003 | **Priority:** P2 | **Scope:** INFRA
