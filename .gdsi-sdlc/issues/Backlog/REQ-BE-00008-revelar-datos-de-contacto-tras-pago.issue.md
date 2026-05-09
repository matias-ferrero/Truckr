---
tag: REQ-BE-00008
title: Revelar datos de contacto del transportista al cliente tras pago confirmado
priority: P2
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/84
author: Claude Code
github_issue: 84
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrs6vU
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-09T13:35:40.077916+00:00Z
labels:
- BE
- FE
- REQ
- payments
- mvp
- us8
- privacy
---

## Summary

Una vez que el pago se confirma, el cliente recibe los datos de contacto del transportista (teléfono, nombre completo) para coordinar el retiro. Antes del pago, los datos están ocultos. Split fino de US8 que cubre la regla de privacidad/marketplace.

## Problem Statement

US8 menciona como AC: "se brindan datos de contacto del transportista". Esa regla protege al marketplace (sin pago, no hay puente directo entre las partes — evita que negocien fuera de la plataforma). Implementarla requiere control en endpoint y en UI: el `GET /api/shipments/:id` debe mostrar datos de contacto solo si `Payment.status == approved`.

## Expected Behavior

- `Carrier` tiene un atributo `contact_phone` (E.164) y `contact_name` (puede ser distinto del nombre de display).
- Endpoint `GET /api/shipments/:id` o `GET /api/quotes/:id` devuelve `carrier.contact_phone` y `carrier.contact_name` **solo si** existe un `Payment.status == approved` asociado al Quote.
- Mismo patrón para el viewpoint del transportista: ve los datos del cliente solo tras pago.
- En frontend, la pantalla post-pago muestra una card destacada con los datos de contacto + CTA "Llamar"/"WhatsApp" (link `tel:` y `https://wa.me/...`).

## Technical Notes

- **Serializer**: usar un view-model condicional. No exponer estos campos en el serializer base de `Carrier`.
- **Test**: cubrir el caso negativo (sin pago → 403 / null en los campos).
- **Privacy**: documentar en `docs/05-appendices/glossary.md` o un `privacy.md` que estos datos solo se exponen post-pago. Es regla de negocio crítica.

## Related

- US fuente: US8 ("Brindar Datos de contacto del Transportista").
- Hermanos: `REQ-BE-00006`, `REQ-BE-00007`.

## Acceptance Criteria

- [ ] `Carrier` tiene `contact_phone` y `contact_name`.
- [ ] Endpoint expone los campos solo cuando hay un `Payment.approved` asociado.
- [ ] Mirror simétrico para el carrier viendo los datos del shipper.
- [ ] UI muestra los datos con CTA llamar/WhatsApp post-pago.
- [ ] Test cubre los dos lados de la regla (con y sin pago).
- [ ] Regla documentada en glosario o `privacy.md`.
