---
tag: REQ-FE-00015
title: Ofertar retiro de un producto al transportista — wizard de creación de oferta
priority: P1
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/121
author: Claude Code
github_issue: 121
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtDI4
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:29:35.275597+00:00Z
labels:
- REQ
- FE
- BE
- offer
- mvp
- us7
---

## Summary

Permitir al cliente crear una oferta de retiro contra un transportista específico: dirección retiro/entrega, fecha, descripción, peso, volumen, valor declarado. Genera una `CargoOffer` y un `Quote` `pending` esperando aceptación. Cubre US7 fullstack.

## Problem Statement

Sin esta pantalla no hay forma de iniciar el flujo end-to-end. US7 es la entrada concreta del Shipper a la transacción.

## Expected Behavior

### Backend
- `POST /api/quotes` — body: `{ carrier_id, transport_window_id, pickup_address, delivery_address, pickup_date, cargo_description, weight_kg, volume_cm3, declared_value_cents }`. Crea `CargoOffer` + `Quote` (status `pending`).
- Notifica al transportista (in-app + email) — usa `INF-BE-00005`.
- Validaciones: carrier/window válidos, weight/volume dentro de capacidad del vehículo, fecha de retiro futura.

### Frontend
- Ruta `/carriers/:id/ofertar`.
- Wizard de 3-4 pasos (UX clara): direcciones, datos del cargo, fecha + valor declarado, confirmación.
- Validaciones por paso; "Volver" disponible.
- Confirmación final navega a una pantalla de "Esperando respuesta del transportista" con polling/refresh para detectar cuando se acepta.

## Related

- US fuente: US7.
- Padres: `REQ-BE-00021` (Marketplace), `REQ-BE-00023` (auth — el shipper debe estar logueado), `REQ-FE-00014` (US6 Detalles, entry point).
- Hijos: US12 (aceptación) → `REQ-BE-00007` (pago).

## Acceptance Criteria

- [ ] `POST /api/quotes` con request specs (happy + invalid carrier + cargo > capacidad).
- [ ] Notificación al transportista enviada por mailer.
- [ ] Wizard frontend con validaciones por paso.
- [ ] E2E: crear oferta, ver confirmación, ver estado pending.
- [ ] Solo Shippers logueados pueden crear ofertas (autorización).
