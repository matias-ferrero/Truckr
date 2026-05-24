---
tag: REQ-FE-00017
title: Bandeja de ofertas recibidas por el transportista
priority: P1
status: in_review
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/123
author: Claude Code
github_issue: 123
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtDN8
github_repo: tcorzo/fiuba-gestion-tp
labels:
- REQ
- FE
- BE
- carrier
- cargo-offer-inbox
- mvp
- us10
---

## Summary

Listado para el transportista de las ofertas de carga (`CargoOffer`s `pending`) recibidas contra sus `TransportWindow`s, con detalle expandible y CTA para aceptar. Cubre US10 fullstack.

## Problem Statement

Sin esta bandeja, las `CargoOffer`s creadas por el shipper contra las `TransportWindow`s del carrier quedan invisibles desde el lado Carrier. Es la contraparte de US7 (creación de la `CargoOffer`).

## Expected Behavior

### Backend

- `GET /api/carriers/me/cargo-offers?status=pending&page=1` — paginado.
- Cada item del response es una `CargoOffer` con todos sus datos inline (la `CargoOffer` ahora carga tanto la relación a la `TransportWindow` como el precio — no hay entidad `Quote` separada).
- Campos por item:
  - Datos del `Cargo` vinculado: origen, destino, peso, volumen, valor declarado, fecha de retiro.
  - Datos del `Shipper`: nombre (el contacto solo post-pago, según `REQ-BE-00008`).
  - Datos de la `CargoOffer`: `price_amount_cents` (enteros, ARS), `status` (`pending` / `accepted` / `rejected` / `expired`), `expires_at` (TTL 48h via `INF-BE-00006`), referencia a la `TransportWindow` apuntada.
- Solo el carrier dueño de la `TransportWindow` recibe la `CargoOffer` en su inbox (autorización).

### Frontend

- Ruta `/carrier/cargo-offers` (inglés; UI text via claves i18n).
- Listado tipo "inbox": cards con resumen (origen → destino, ventana, monto formateado en ARS desde `price_amount_cents`, `expires_at`).
- Expandable: detalles completos del `Cargo` + del `Shipper` + de la `TransportWindow` apuntada.
- CTA "Aceptar" en cada card (la lógica de aceptación vive en `REQ-BE-00024` / US12 — `POST /api/carriers/me/cargo-offers/:id/accept`; este issue solo conecta el botón).
- Indicador de nuevas `CargoOffer`s en el header (badge con count de `pending`).

## Related

- US fuente: US10.
- Padres: `REQ-BE-00021` (Marketplace), `REQ-BE-00023` (auth).
- Hijos: US12 (aceptación) — el botón llama al endpoint definido en ese issue.
- Contraparte shipper: US7 (`POST /api/cargos/:id/offers`).

## Origin

Body refreshed 2026-05-19 — Quote→CargoOffer rename. El modelo de dos entidades (CargoOffer + Quote) se colapsó en una sola: hoy la `CargoOffer` lleva tanto la relación contra la `TransportWindow` como el precio. La entidad pre-rename `CargoOffer` (publicación de carga) pasó a llamarse `Cargo`. Source of truth: `docs/05-appendices/glossary.md` + `docs/01-domain/domain-model.md` § 3. FKs renombrados: `quote_id` → `cargo_offer_id`.

## Acceptance Criteria

- [ ] `GET /api/carriers/me/cargo-offers` con paginación y filtros por `status` (`pending` por default).
- [ ] Cada row del response es una `CargoOffer` única con `price_amount_cents`, `status`, `expires_at`, datos del `Cargo` vinculado y nombre del `Shipper`.
- [ ] Pantalla `/carrier/cargo-offers` con listado + expand.
- [ ] Precio renderizado a ARS desde `price_amount_cents` (entero cents).
- [ ] Badge de count en header con `CargoOffer`s `pending` del carrier autenticado.
- [ ] E2E: shipper crea `CargoOffer` contra una `TransportWindow` del carrier, carrier la ve en su inbox.
- [ ] Solo el carrier dueño de la `TransportWindow` ve las `CargoOffer`s asociadas (autorización).
- [ ] Sin literales en JSX — UI text vía claves i18n; rutas en inglés.
