---
tag: REQ-BE-00019
title: Seguros — declaración y seguimiento de siniestros
priority: P3
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/99
author: Claude Code
github_issue: 99
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtCVw
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:25:15.515973+00:00Z
labels:
- REQ
- BE
- FE
- insurance
- claims
- post-mvp
- us25
---

## Summary

Permitir al cliente declarar un siniestro sobre una póliza activa y seguir su estado. Última rebanada de US25.

## Problem Statement

WBS § 4.5 (Gestión de Siniestros). US25 AC: "en caso de siniestro, el cliente puede iniciar un reclamo desde la plataforma". Es la cara visible del seguro cuando algo sale mal — sin esto, contratar el seguro pierde sentido en el upsell.

## Expected Behavior

- Modelo `InsuranceClaim`: `policy_id` (FK), `shipper_id` (FK), `description` (text), `status` (`open`, `under_review`, `approved`, `rejected`, `paid`), `external_claim_id`, ActiveStorage attachments (fotos, documentación), timestamps.
- Endpoint `POST /api/insurance/policies/:id/claims` para declarar. Solo el dueño de la póliza puede declarar.
- Endpoint `GET /api/insurance/claims/:id` para seguimiento; `GET /api/insurance/me/claims` para el listado.
- Pantalla `/seguros/poliza/:id/declarar` con form (descripción, fotos, ubicación).
- Estado refrescado periódicamente (sync con el proveedor vía `InsuranceClient.report_claim` / job de polling cada 1h).
- Notificaciones al cliente cuando cambia el estado.

## Technical Notes

- **Mock provider**: el mock de `REQ-BE-00016` debe simular transiciones de estado plausibles para demos.
- **Documentación de fotos**: ActiveStorage como `has_many_attached :evidence`.
- **Estado state machine**: `open → under_review → (approved|rejected) → paid` (si approved). Documentar en el modelo.
- **Privacidad**: claims son sensibles; evitar exponer datos en `GET /api/insurance/claims` listings cross-shipper.

## Related

- US fuente: US25.
- Padres: `REQ-BE-00016`, `REQ-BE-00017`, `REQ-BE-00018`.

## Acceptance Criteria

- [ ] Modelo `InsuranceClaim` con state machine + attachments.
- [ ] Endpoints de declaración + seguimiento.
- [ ] UI de declaración con uploader de evidencia.
- [ ] UI de listado + detalle.
- [ ] Job de polling de estado contra el proveedor.
- [ ] Notificaciones al cliente en cambios de estado.
- [ ] Tests: happy path declaración → review → approved → paid; cubrir autorización (otro shipper no puede ver mi claim).
