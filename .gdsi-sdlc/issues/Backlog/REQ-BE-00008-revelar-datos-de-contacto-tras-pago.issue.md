---
tag: REQ-BE-00008
title: Revelar datos de contacto del Carrier al Shipper tras pago confirmado
priority: P2
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/84
author: Claude Code
github_issue: 84
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrs6vU
github_repo: tcorzo/fiuba-gestion-tp
labels:
- BE
- FE
- REQ
- payments
- mvp
- us8
- privacy
- cargo-offer
---

## Summary

Una vez que el pago de un `CargoOffer` se confirma, el `Shipper` (dueño del `Cargo` asociado) recibe los datos de contacto del `Carrier` (teléfono, nombre completo) para coordinar el retiro. Antes del pago, los datos están ocultos. Split fino de US8 que cubre la regla de privacidad del marketplace: sin pago no hay puente directo entre las partes.

## Problem Statement

US8 exige como AC: "se brindan datos de contacto del Carrier". Esa regla protege al marketplace (evita que las partes negocien fuera de la plataforma una vez que se conocen). Implementarla requiere control en endpoint y en UI: el `GET /api/cargo-offers/:id` debe revelar los datos de contacto **solo si** existe un `Payment.status == approved` asociado a ese `CargoOffer`, y **solo al** `Shipper` dueño del `Cargo` que ese `CargoOffer` referencia.

## Expected Behavior

- `Carrier` tiene los atributos `contact_phone` (E.164) y `contact_name` (puede diferir del nombre de display).
- Endpoint `GET /api/cargo-offers/:id` devuelve `carrier.contact_phone` y `carrier.contact_name` **solo si** se cumplen las tres condiciones a la vez:
  1. Existe un `Payment` con `status == approved` cuyo `payments.cargo_offer_id` apunta a este `CargoOffer`.
  2. El `CargoOffer` pertenece (vía `cargo_id`) a un `Cargo` cuyo dueño es el usuario autenticado actuando como `Shipper`.
  3. El usuario autenticado es ese `Shipper` (no otro Shipper, no un Carrier de paso).
- Si falla cualquiera de las tres, los campos vuelven `null` (no se devuelve 403 para no filtrar existencia del pago a terceros — devolver el recurso sin los campos sensibles).
- Mirror simétrico: el `Carrier` aceptado ve los datos de contacto del `Shipper` bajo el mismo predicado de pago aprobado.
- Frontend: la pantalla post-pago muestra una card destacada con los datos de contacto + CTAs `tel:` y `https://wa.me/...`.

## Technical Notes

- **Serializer condicional**: no exponer `contact_phone` / `contact_name` en el serializer base de `Carrier`. Usar un view-model que reciba el `current_user` y el `CargoOffer` y decida.
- **Predicado de autorización** (centralizado en un policy / query object, no inline en el controller):
  `CargoOffer.payment_approved? && cargo_offer.cargo.shipper_id == current_user.shipper.id`.
- **FK**: `payments.cargo_offer_id` (no `quote_id` — terminología pre-2026-05-19 prohibida).
- **Tests**: cubrir los cuatro caminos: (a) Shipper dueño + pago aprobado → campos visibles; (b) Shipper dueño + pago pendiente → `null`; (c) otro Shipper + pago aprobado → `null`; (d) usuario no autenticado → 401.
- **Privacidad**: documentar la regla en `docs/05-appendices/glossary.md` (entrada nueva `Datos de contacto post-pago`) o un `privacy.md` dedicado. Es regla de negocio crítica del marketplace.

## Acceptance Criteria

- [ ] `Carrier` tiene `contact_phone` (E.164) y `contact_name`.
- [ ] `GET /api/cargo-offers/:id` expone `carrier.contact_phone` y `carrier.contact_name` solo cuando: (1) `Payment.status == approved` con `payments.cargo_offer_id` == este `CargoOffer`, (2) el `CargoOffer` referencia un `Cargo` del `Shipper` autenticado, (3) el solicitante ES ese `Shipper`.
- [ ] Mirror simétrico para el `Carrier` viendo los datos del `Shipper` post-pago.
- [ ] UI post-pago muestra los datos con CTAs `tel:` y `https://wa.me/...`.
- [ ] Tests cubren los cuatro caminos del predicado de autorización (dueño+aprobado, dueño+pendiente, no-dueño+aprobado, no autenticado).
- [ ] Regla de privacidad documentada en glosario o `privacy.md`.
- [ ] Ningún identificador en código/rutas/columnas usa `quote` / `cotización`.

## Related

- US fuente: US8 ("Brindar Datos de contacto del Carrier").
- `REQ-BE-00006` — checkout Mercado Pago (genera el `Payment` cuyo estado este endpoint chequea).
- `REQ-BE-00007` — flujo de confirmación del pago y transición a `approved` (precondición de esta historia).
- `REQ-BE-00024` — US12 acceptance flow (define cuándo un `CargoOffer` queda asociado a un `Cargo` aceptado, prerequisito del predicado de autorización).

## Rename memo

Body refreshed 2026-05-19 — Quote→CargoOffer rename. Source of truth: `docs/05-appendices/glossary.md`, `domain-model.md` § 3.
