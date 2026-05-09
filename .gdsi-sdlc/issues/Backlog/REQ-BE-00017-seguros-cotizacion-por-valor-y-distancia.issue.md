---
tag: REQ-BE-00017
title: Seguros — cotización por valor declarado y distancia del viaje
priority: P3
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/97
author: Claude Code
github_issue: 97
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtCSk
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:24:49.082481+00:00Z
labels:
- REQ
- BE
- FE
- insurance
- post-mvp
- us25
---

## Summary

Calcular una cotización de seguro al cliente cuando confirma una oferta, basada en el **valor declarado** del producto y la **distancia** estimada del viaje. Segunda rebanada de US25.

## Problem Statement

WBS § 4.2 define tres componentes de cotización: cálculo por valor, cálculo por distancia, visualización. La cotización dispara el flujo de venta de seguros: si nunca se le muestra al cliente, no hay venta. Aislar este issue del de contratación permite iterar sobre la lógica de pricing sin tocar el flujo transaccional.

## Expected Behavior

- En el flujo de creación de oferta (US7), aparece un nuevo paso: "¿Querés contratar un seguro?". El cliente declara el valor del producto (input numérico).
- Endpoint `POST /api/insurance/quote` recibe `value`, `origin_zone`, `destination_zone` y devuelve `[{ coverage_id, name, description, premium }, ...]` — una entry por cobertura.
- Frontend muestra las coberturas como cards comparativas con CTA "Contratar".
- La cotización vence después de N minutos (default 15min) — si el cliente vuelve después, se recalcula.
- Si el cliente declina el seguro, se sigue el flujo de pago normal sin friction extra.

## Technical Notes

- **Distancia**: por ahora se estima usando Directions API (Google Maps) o un proxy server-side. Si la API key es solo del frontend (`REQ-FE-00009`), considerar habilitar una key separada para BE. Documentar.
- **TTL de la cotización**: persistir `InsuranceQuote` con `expires_at`; al expirar, no se puede contratar (forzar recotización).
- **Frontend**: integrarlo en el wizard de oferta sin romper el caso "sin seguro" (el default no debe cambiar).

## Related

- US fuente: US25.
- Padre: `REQ-BE-00016`.
- Hermanos: `REQ-BE-00018`, `REQ-BE-00019`.
- Consumidor: US7 (Ofertar Retiro).

## Acceptance Criteria

- [ ] Modelo `InsuranceQuote` con `expires_at`, vinculado a `Quote` o `Shipper`.
- [ ] `POST /api/insurance/quote` retorna lista de coberturas con primas calculadas.
- [ ] UI integra el paso en el wizard de oferta (US7).
- [ ] TTL de cotización aplicado.
- [ ] El happy path "sin seguro" no se ve afectado.
- [ ] Tests cubren cálculo correcto + expiración.
