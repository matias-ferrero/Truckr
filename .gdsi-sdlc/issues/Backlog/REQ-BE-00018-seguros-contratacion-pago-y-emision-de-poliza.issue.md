---
tag: REQ-BE-00018
title: Seguros — contratación, pago integrado y emisión de póliza
priority: P3
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/98
author: Claude Code
github_issue: 98
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtCUI
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:25:02.110009+00:00Z
labels:
- REQ
- BE
- FE
- insurance
- post-mvp
- us25
---

## Summary

Permitir al cliente contratar una cobertura de seguro al confirmar la oferta. La prima se suma al pago vía Mercado Pago, y al confirmarse el pago se emite la póliza (PDF + número). Tercera rebanada de US25.

## Problem Statement

WBS § 4.3 (Contratación) + § 4.4 (Gestión de Pólizas). Sin esta pieza, la cotización del issue anterior es decorativa.

Decisiones:
- ¿La prima se cobra en el mismo Payment que el viaje, o aparte? (decisión: mismo Payment, con `line_items` que distingue carrier-fee vs insurance-premium).
- ¿Quién es el beneficiario? (el `Shipper`).
- ¿Dónde se almacena la póliza? (PDF en ActiveStorage; URL devuelta al cliente).

## Expected Behavior

- Al "Contratar" desde la cotización, el frontend incluye `coverage_id` en el request de pago (`REQ-BE-00007`).
- Backend extiende el flujo de checkout: si hay `coverage_id`, suma la prima al monto del Payment y guarda `insurance_quote_id` en el Payment.
- Al confirmarse el pago (webhook MP), un job `IssueInsurancePolicyJob` llama a `InsuranceClient.contract(...)`, recibe `external_policy_id`, genera un PDF con los datos clave, lo persiste vía ActiveStorage y notifica al cliente con un link de descarga.
- Pantalla `/seguros/mis-polizas` lista las pólizas del cliente (modelo `InsurancePolicy`) con estado, link de descarga, viaje asociado.

## Technical Notes

- **Idempotencia**: `IssueInsurancePolicyJob` no debe emitir dos pólizas para el mismo Payment. Lock en `Payment` o check de existencia de `InsurancePolicy.payment_id`.
- **PDF**: usar `prawn` o `wicked_pdf`. Template básico con datos de cobertura, beneficiario, viaje, número de póliza.
- **Notificación**: email transaccional con el PDF adjunto + link de descarga; Solid Queue.
- **Modelo `InsurancePolicy`**: `shipper_id`, `shipment_id`, `payment_id`, `coverage_id`, `external_policy_id`, `status`, `issued_at`, `expires_at`, ActiveStorage attachment.

## Related

- US fuente: US25.
- Padre: `REQ-BE-00016`, `REQ-BE-00017`.
- Hermano: `REQ-BE-00019`.
- Dependiente: `REQ-BE-00007` (flujo de checkout MP).

## Acceptance Criteria

- [ ] Modelo `InsurancePolicy` con migración + ActiveStorage attachment.
- [ ] Flujo de checkout extendido para incluir prima de seguro.
- [ ] `IssueInsurancePolicyJob` idempotente, dispara contract + PDF + email.
- [ ] Pantalla `/seguros/mis-polizas` con listado + descarga.
- [ ] Tests cubren happy path + idempotencia + cliente sin seguro (no se emite póliza).
