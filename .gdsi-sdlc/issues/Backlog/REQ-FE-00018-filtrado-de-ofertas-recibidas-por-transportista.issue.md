---
tag: REQ-FE-00018
title: Filtrado de ofertas de carga en bandeja del transportista
priority: P2
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/124
author: Claude Code
github_issue: 124
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtDQA
github_repo: tcorzo/fiuba-gestion-tp
labels:
- REQ
- FE
- BE
- carrier
- cargo-offer-inbox
- filters
- mvp
- us11
---

## Summary

Filtros server-side + UI sobre la bandeja de `CargoOffer` del transportista (`REQ-FE-00017`): por `status`, rango de precio, rango de fecha de salida de la `TransportWindow`, región del `Cargo` asociado, y `transport_window_id` (eje primario para Carriers con múltiples `TransportWindow`s activas). Cubre US11 fullstack.

## Problem Statement

Un transportista activo con muchas `CargoOffer` recibidas (bids de `Shipper`s contra sus `TransportWindow`s) no escala revisando una lista plana. US11 prescribe los filtros como AC para acotar la bandeja sin perder estado al recargar o compartir el link.

## Expected Behavior

### Backend
- `GET /api/carriers/me/cargo-offers` extiende query params (set de 5 dimensiones, locked 2026-05-19):
  - `status` — uno de `pending | accepted | rejected | expired` (multi-valor permitido como CSV).
  - `price_min_cents`, `price_max_cents` — filtran sobre `CargoOffer.price_amount_cents`.
  - `departure_date_from`, `departure_date_to` — filtran sobre `TransportWindow.departure_at` de la ventana del Carrier sobre la cual se publicó el `CargoOffer`.
  - `region` — filtra sobre la región de la `TransportWindow` del Carrier (texto normalizado vía `I18n.transliterate`, match case/diacritic-insensitive). Modelo: el Carrier filtra por *sus* regiones de oferta, no por origen/destino del `Cargo`.
  - `transport_window_id` — FK a `TransportWindow`. **Eje primario para Carriers con múltiples Windows activas**: permite acotar la bandeja a las ofertas recibidas contra una Window específica (p. ej. "ver solo ofertas sobre mi Window CABA→Rosario del 2026-06-10"). Sin este filtro, un Carrier con N Windows ve una bandeja mezclada e ilegible.
- Whitelist server-side: params no reconocidos se ignoran silenciosamente. Combinables (AND). Omitir el param resetea esa dimensión.
- **Dimensiones explícitamente NO incluidas** (drop locked 2026-05-19): `pickup_zone`, `weight`, `volume`. Capacidad y geo ya están gateadas upstream en la creación del `CargoOffer` por `vehicle.max_load_kg` + `pickup_radius_km` — re-filtrar en la bandeja es ruido sin valor.
- Paginación y orden existentes de `REQ-FE-00017` se preservan junto con los filtros.

### Frontend
- Drawer/sidebar de filtros sobre la bandeja, con controles para las 5 dimensiones: status multiselect, price range, departure date range, region (texto/autocomplete), y `transport_window_id` (selector poblado con las Windows activas del Carrier — eje primario, idealmente sticky/destacado).
- Chips de filtros activos arriba del listado, cada chip removible individualmente.
- Botón "Limpiar todos".
- Estado de filtros sincronizado a la URL (`?status=pending&departure_date_from=...&region=...&transport_window_id=...`) para que sea compartible y sobreviva al refresh / back-forward.
- Todo el copy via i18n keys (sin literales hardcoded). Rutas en inglés (`/carrier/cargo-offers`).

## Related

- US fuente: US11.
- Padre: `REQ-FE-00017` (bandeja base).
- Domain: `docs/05-appendices/glossary.md`, `docs/01-domain-model/domain-model.md` § 3 (`Cargo`, `CargoOffer`, `TransportWindow`).

## Acceptance Criteria

- [ ] `GET /api/carriers/me/cargo-offers` acepta exactamente: `status`, `price_min_cents`, `price_max_cents`, `departure_date_from`, `departure_date_to`, `region`, `transport_window_id` — con whitelist server-side.
- [ ] Filtros son combinables (AND) y omitir un param lo resetea.
- [ ] `status` acepta solo valores del enum `pending|accepted|rejected|expired`; valores inválidos devuelven 422 con error i18n-key.
- [ ] `transport_window_id` valida ownership: si la Window no pertenece al Carrier autenticado, devuelve 403/404 (no leak de IDs ajenos). Spec cubre el caso.
- [ ] Params **rechazados/no soportados** (verificable por test): `pickup_zone`, `weight`, `volume` — el server los ignora silenciosamente (whitelist) y no aparecen en la UI ni en la documentación de query params.
- [ ] UI: drawer de filtros + chips de filtros activos + botón "Limpiar todos", todo via i18n keys. Selector de `transport_window_id` poblado con las Windows del Carrier.
- [ ] Estado de filtros reflejado en la URL y restaurado al recargar / abrir el link.
- [ ] E2E (Playwright): Carrier con 2 Windows activas filtra por `transport_window_id` + `status=pending`, verifica que la lista se reduce a las ofertas de esa Window y que la URL contiene ambos query params.

## Rename memo

Body refreshed 2026-05-19 — Quote→CargoOffer rename. Endpoint `/api/carriers/me/quotes` → `/api/carriers/me/cargo-offers`. Filter dimensions reanchored a `CargoOffer.price_amount_cents`, `TransportWindow.departure_at` y `Cargo.{origin,destination}_region` bajo el modelo nuevo (Shipper bid = `CargoOffer`; publicación = `Cargo`). Source of truth: `docs/05-appendices/glossary.md` + `docs/01-domain-model/domain-model.md` § 3.

## Origin

Generado desde US11 en la USM; companion de `REQ-FE-00017`.
