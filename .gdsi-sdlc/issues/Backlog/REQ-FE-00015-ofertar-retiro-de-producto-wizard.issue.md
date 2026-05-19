---
tag: REQ-FE-00015
title: Ofertar carga contra ventana del transportista — wizard de creación de CargoOffer
priority: P1
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/121
author: Claude Code
github_issue: 121
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtDI4
github_repo: tcorzo/fiuba-gestion-tp
last_synced:
labels:
- REQ
- FE
- BE
- cargo-offer
- mvp
- us7
---

## Summary

Permitir al Shipper crear una `CargoOffer` (oferta de carga) contra una `TransportWindow` específica de un Carrier, partiendo de un `Cargo` ya publicado por el Shipper. La creación de la `CargoOffer` (status `pending`) bloquea la Window destino (`open → pending_offer`) hasta que el Carrier acepte/rechace o expire (48h). Cubre US7 fullstack.

## Problem Statement / Current Behavior

Sin esta pantalla no hay forma de iniciar el flujo end-to-end. US7 es la entrada concreta del Shipper a la transacción: el Shipper llega desde el detalle de su propio `Cargo` (lista de matches con Windows disponibles) y elige una Window para ofertar. No existe un browse libre Carrier-first que inicie la oferta.

## Expected Behavior

### Backend
- `POST /api/cargos/:cargo_id/offers` — body: `{ transport_window_id, pickup_address, delivery_address, pickup_date, cargo_description, weight_kg, volume_cm3, declared_value_cents }`. Crea una `CargoOffer` (status `pending`) que referencia `cargo_id` + `transport_window_id`.
- Side effect transaccional: la Window destino pasa de `open` a `pending_offer` en la misma transacción. Si el Carrier rechaza o pasan 48h sin respuesta, la Window vuelve automáticamente a `open` (Window-locks-on-Offer, MVP).
- Notifica al Carrier (in-app + email) — usa `INF-BE-00005`.
- Validaciones: `cargo` pertenece al Shipper autenticado y está `open`; `transport_window` existe y está `open`; weight/volume dentro de capacidad del vehículo asociado a la Window; fecha de retiro futura y dentro del rango de la Window.

### Frontend
- Ruta `/shipper/cargos/:cargoId/offers/new?windowId=:windowId` (entrada vía CTA "Ofertar" sobre una `MatchCard` en `/shipper/cargos/:cargoId`).
- `/carriers/:id` permanece como perfil público del Carrier pero ya no inicia el flujo de oferta.
- Wizard de 3–4 pasos: direcciones, datos del cargo, fecha + valor declarado, confirmación.
- Validaciones por paso; "Volver" disponible; copy vía i18n keys (sin literales hardcoded; nunca "cotización"/"cotizar").
- Confirmación final navega a "Esperando respuesta del transportista" con polling/refresh para detectar aceptación/rechazo/expiración.

## Technical Notes

- Entidades (post-rename 2026-05-19): `CargoOffer` = bid del Shipper contra una Window (lifecycle `pending / accepted / rejected / expired`). `Cargo` = publicación del Shipper (lifecycle `open / accepted / cancelled`). FKs: `cargo_offer.cargo_id`, `cargo_offer.transport_window_id`.
- Window lifecycle: `open / pending_offer / reserved / closed`. El flip `open → pending_offer` y el flip de retorno (`pending_offer → open` en reject/expire) deben ocurrir en la misma DB tx que el cambio de status de la `CargoOffer`.
- Concurrencia: dos Shippers no pueden ofertar simultáneamente sobre la misma Window — resolver en application layer (SQLite, sin EXCLUDE).
- Todos los identificadores y rutas en inglés; UI strings vía i18n.

## Related

- US fuente: US7.
- Padres: `REQ-BE-00021` (Marketplace), `REQ-BE-00023` (auth — Shipper logueado), `REQ-FE-00014` (US6 detalle de Cargo + matches, entry point real).
- Hijos: US12 (aceptación del Carrier) → `REQ-BE-00007` (pago).

## Acceptance Criteria

- [ ] `POST /api/cargos/:cargo_id/offers` con request specs (happy + cargo ajeno al Shipper + window no `open` + cargo > capacidad del vehículo).
- [ ] Al crear la `CargoOffer`, la `TransportWindow` destino queda en `pending_offer` en la misma transacción.
- [ ] En reject del Carrier o expiración a 48h, la Window vuelve a `open` automáticamente (regression spec).
- [ ] Notificación al Carrier enviada por mailer.
- [ ] Wizard frontend con validaciones por paso, copy vía i18n keys.
- [ ] Entry point único: CTA "Ofertar" sobre una MatchCard dentro de `/shipper/cargos/:cargoId`; no se llega al wizard desde `/carriers/:id`.
- [ ] E2E: desde detalle de Cargo, elegir Window, completar wizard, ver confirmación, ver estado `pending` y Window en `pending_offer`.
- [ ] Solo Shippers logueados pueden crear ofertas (autorización).

## Origin

Issue manual creado el 2026-05-03 para cubrir US7 fullstack.

## Rename memo

Body refreshed 2026-05-19 to align with the Quote→CargoOffer / CargoOffer→Cargo rename. Source of truth: `docs/05-appendices/glossary.md` + `docs/02-high-level-design/domain-model.md` § 3.
