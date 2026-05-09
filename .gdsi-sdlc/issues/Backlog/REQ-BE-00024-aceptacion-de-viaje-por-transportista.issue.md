---
tag: REQ-BE-00024
title: Aceptación de viaje por el transportista (transición Quote → accepted)
priority: P1
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/104
author: Claude Code
github_issue: 104
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtCf0
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:26:13.632753+00:00Z
labels:
- REQ
- BE
- FE
- carrier
- quote-state
- mvp
- us12
---

## Summary

El transportista acepta una oferta `pending`. La transición dispara: `Quote.status → accepted`, notificación al cliente con link de pago, estimación de fecha de entrega actualizada, oferta movida a "viajes activos" del carrier. Cubre US12 fullstack.

## Problem Statement

US12 es el pivote de la transacción: hasta que el carrier acepte, no hay viaje. AC: botón visible, notificación al cliente, estimación de entrega, sección "viajes activos".

## Expected Behavior

### Backend
- `POST /api/carriers/me/quotes/:id/accept` — solo el carrier dueño puede aceptar; solo si `Quote.status == pending` y no expiró.
- Transición atómica con lock: `Quote.status = accepted`, set `accepted_at`, calcular `estimated_delivery_at` (heurística simple basada en distancia + buffer).
- Notifica al cliente: email con link a `/quotes/:id/pay` (consumido por `REQ-BE-00007`).
- El Quote aceptado aparece en `GET /api/carriers/me/trips` (active trips listing).
- Falla con 409 si ya fue aceptado / cancelado / expirado.

### Frontend
- Botón "Aceptar" en la bandeja (`REQ-FE-00017`) confirma con modal antes de disparar.
- Tras aceptar: feedback de éxito + el Quote desaparece de "pending" y aparece en "viajes activos".
- Listado `/transportista/viajes-activos` (placeholder para US18/US19/US21 que evolucionan la pantalla).

## Related

- US fuente: US12.
- Padres: `REQ-BE-00021` (Marketplace), `REQ-FE-00017` (inbox), `INF-BE-00005` (mailer).
- Hijos: `REQ-BE-00007` (pago tras aceptación), US18 (mark picked up), US19 (mark delivered).

## Acceptance Criteria

- [ ] `POST /api/carriers/me/quotes/:id/accept` con request specs (happy + ya aceptado + expirado + no-owner).
- [ ] Transición atómica con lock; emite `TrackingEvent` (cuando exista `Shipment` — o en este issue se decide crear el Shipment al aceptar).
- [ ] Notificación email al cliente con link de pago.
- [ ] `GET /api/carriers/me/trips` lista viajes activos.
- [ ] Botón "Aceptar" en frontend con confirmación.
- [ ] Pantalla `/transportista/viajes-activos` placeholder.
- [ ] E2E: shipper crea oferta → carrier la acepta → shipper recibe email con link.
