---
tag: REQ-FE-00014
title: Página de detalle de transportista (perfil público + CTA ofertar)
priority: P1
status: done
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/120
author: Claude Code
github_issue: 120
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtDFw
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:29:23.149226+00:00Z
labels:
- REQ
- FE
- BE
- carrier-profile
- mvp
- us6
---

## Summary

Página pública del transportista que muestra fotos del camión, descripción, zonas, costo estimado para el viaje buscado, reseñas (cuando existan), y CTA "Ofertar retiro". Cubre US6 fullstack.

## Problem Statement

Tras la búsqueda (US4), el cliente necesita un lugar donde decidir si contratar al transportista. Sin esta pantalla, los resultados son cards sin profundidad.

## Expected Behavior

### Backend
- `GET /api/carriers/:id` devuelve: datos básicos del Carrier, sus `Vehicle`s con fotos (URLs públicas via ActiveStorage), `TransportWindow`s activas, `rating_avg` + `reviews_count` (cuando existan, pueden ser null por ahora).
- `GET /api/carriers/:id/cargo_estimate?cargo_id=X` o con params (`origin`, `destination`, `weight`, `volume`) devuelve `{ estimated_amount_cents, currency, breakdown }`.

### Frontend
- Ruta `/carriers/:id`.
- Hero con nombre del transportista + average rating (estrellas).
- Galería de fotos del/los vehículo(s).
- Descripción + zonas servidas + precio/km.
- Si vino de una búsqueda con context (`origin`, `destination`, `weight`, `volume`), muestra el costo estimado destacado.
- CTA "Ofertar retiro" navega a `/carriers/:id/ofertar` (US7).
- Sección "Reseñas" placeholder (se completa en `REQ-BE-00014`).

## Related

- US fuente: US6.
- Padres: `REQ-BE-00020` (Carrier), `REQ-BE-00009` (Vehicle), `REQ-BE-00021` (TransportWindow), `REQ-FE-00006` (search → entry point).
- Hijos: `REQ-FE-00015` (US7 oferta).

## Acceptance Criteria

- [ ] `GET /api/carriers/:id` con request spec; expone vehicles + windows + rating fields.
- [ ] `GET /api/carriers/:id/cargo_estimate` con cálculo determinístico documentado.
- [ ] Página `/carriers/:id` con hero, galería, descripción, costo estimado, CTA.
- [ ] Sin auth requirement (pantalla pública).
- [ ] E2E: navegar desde búsqueda, ver detalle, click en CTA dispara navegación a oferta.
