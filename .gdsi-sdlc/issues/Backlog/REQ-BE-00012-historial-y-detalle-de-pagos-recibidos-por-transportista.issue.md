---
tag: REQ-BE-00012
title: Historial y detalle de pagos recibidos por el transportista
priority: P2
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/92
author: Claude Code
github_issue: 92
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtCHA
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:23:50.321215+00:00Z
labels:
- REQ
- BE
- FE
- payments
- payout
- mvp
- us15
---

## Summary

Pantalla y endpoint para que el transportista (`Carrier`) vea su historial de pagos recibidos: monto, viaje asociado, fecha, estado. Incluye notificación cuando un payout falla. Segunda y última rebanada de US15.

## Problem Statement

US15 AC: "el transportista puede ver el detalle de cada pago recibido (monto, viaje asociado, fecha)" + "si hay algún problema con la transferencia, se notifica al transportista". El payout per se vive en `REQ-BE-00011`; este issue cubre el lado de **observabilidad** desde el carrier.

## Expected Behavior

- Endpoint `GET /api/carriers/me/payouts?page=1&per_page=20` con paginación.
- Respuesta: lista de payouts con `amount`, `currency`, `status`, `shipment_id`, `created_at`, `completed_at`, `mp_reference_url`.
- Pantalla `/transportista/pagos` con tabla + filtro por estado (pending / processed / failed) + link al detalle del viaje.
- Notificación in-app + email al carrier cuando un payout falla (`status == failed`). El cuerpo incluye el `Shipment` afectado y un CTA para contactar soporte.

## Technical Notes

- **Notificación**: ActionMailer + Solid Queue (consistente con `REQ-BE-00007`).
- **Filtros server-side**: por estado y por rango de fechas.
- **CSV export**: out of scope para MVP; nota para futuro.

## Related

- US fuente: US15.
- Padre: `REQ-BE-00011`.

## Acceptance Criteria

- [ ] Endpoint `GET /api/carriers/me/payouts` con paginación y filtros.
- [ ] Pantalla `/transportista/pagos` con tabla + filtro.
- [ ] Notificación email + in-app al carrier en payouts fallidos.
- [ ] Tests para los endpoints y para el dispatch de la notificación.
