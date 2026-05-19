---
tag: REQ-BE-00024
title: Aceptación de CargoOffer por el transportista con cascada sibling-reject
priority: P1
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/104
author: Claude Code
github_issue: 104
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtCf0
github_repo: tcorzo/fiuba-gestion-tp
labels:
- REQ
- BE
- FE
- carrier
- cargo-offer-state
- mvp
- us12
---

## Rename memo

Body refreshed 2026-05-19 — Quote→CargoOffer rename + Cargo lifecycle adjustment. Source of truth: `docs/05-appendices/glossary.md`, `domain-model.md` § 3.

## Summary

El Carrier acepta un `CargoOffer` en estado `pending`. La aceptación es el pivote transaccional de US12: en una sola DB transaction se promueve el `CargoOffer` ganador a `accepted`, se reserva su `TransportWindow`, se cierra el `Cargo` padre, y se rechazan en cascada todos los `CargoOffer` hermanos liberando sus Windows de nuevo al marketplace. Cubre US12 fullstack.

## Problem Statement

US12 es el pivote de la transacción: hasta que el Carrier acepte, no hay viaje. Aceptar un `CargoOffer` no es una transición aislada — debe cascar consistentemente sobre el `Cargo` padre, el `TransportWindow` del ganador, y todos los `CargoOffer` hermanos pendientes (y sus Windows). Estado parcial es inaceptable: si algún paso falla, rollback total.

## Expected Behavior

### Backend

- `POST /api/carriers/me/cargo-offers/:id/accept` — solo el Carrier dueño del `CargoOffer` puede aceptar; solo si `CargoOffer.status == pending` y no expiró (ver `INF-BE-00006`).
- Companion: `POST /api/carriers/me/cargo-offers/:id/reject` (rechazo voluntario sin cascada — solo flipea el `CargoOffer` y devuelve su Window a `open`).
- Falla con `409 Conflict` si el `CargoOffer` ya fue `accepted` / `rejected` / `expired`, o si su `Cargo` padre ya no está `open`.
- Notifica al Shipper dueño del `Cargo`: email con link a `/cargos/:id/pay` (consumido por `REQ-BE-00007`).
- El `Cargo` aceptado (vía su `Shipment` derivado) aparece en `GET /api/carriers/me/shipments` (default view: in-progress shipments) para el Carrier ganador.
- Los Shippers cuyos `CargoOffer` fueron rechazados en cascada reciben notificación (reusa pipeline de `INF-BE-00005`).

### Frontend

- Botón "Aceptar" en la bandeja (`REQ-FE-00017`) confirma con modal antes de disparar.
- Tras aceptar: feedback de éxito + el `CargoOffer` desaparece de "pending" y el `Shipment` aparece en la vista por default de shipments en curso.
- Listado `/carrier/shipments` (default view: in-progress; status filtering via query param `?status=in_transit|delivered|cancelled|disputed`). Placeholder evolutivo para US18/US19/US21.
- Todas las rutas y código en inglés; copy UI via i18n keys.

## Technical Notes

**Cascada en una sola DB transaction** (envuelve todo en `ActiveRecord::Base.transaction`):

1. `winner.with_lock { ... }` sobre el `CargoOffer` ganador para evitar race con `CargoOfferExpirationJob` (`INF-BE-00006`) que también muta `pending → expired`.
2. Re-validar dentro del lock: `winner.status == 'pending'` y `winner.cargo.status == 'open'`. Si no, abortar con 409.
3. Aplicar transiciones en orden:
   - `winner.status: pending → accepted` (set `accepted_at`).
   - `winner.transport_window.status: pending_offer → reserved`.
   - `winner.cargo.status: open → accepted` (sin estado intermedio `offered`).
   - Para cada sibling `CargoOffer` con `cargo_id == winner.cargo_id` y `status == 'pending'`:
     - `sibling.status: pending → rejected`.
     - `sibling.transport_window.status: pending_offer → open` (vuelve al marketplace inmediatamente, visible para otros Shippers en el siguiente fetch).
4. Crear el `Shipment` asociado al `Cargo` aceptado (o disparar el flujo existente).
5. Encolar notificaciones (email a Shipper ganador con link de pago; emails a Shippers de siblings rechazados) — fuera del lock pero dentro de la tx via `after_commit`.

**Invariante:** si cualquier paso falla, la tx hace rollback completo — ningún `CargoOffer`, `Cargo` ni `TransportWindow` queda en estado mixto. No se permite "compensación a mano" post-failure.

**SQLite:** la tx + `with_lock` (que en SQLite degrada a `BEGIN IMMEDIATE` / row-level via app) es suficiente; no usar `EXCLUDE` constraints ni features Postgres.

**Diagrama de estados afectado:** `CargoOffer` (`pending → accepted | rejected`), `Cargo` (`open → accepted`), `TransportWindow` (`pending_offer → reserved | open`). Ver `domain-model.md` § 3.

## Related

- US fuente: US12.
- Padres: `REQ-BE-00021` (Marketplace), `REQ-FE-00017` (inbox de CargoOffers), `INF-BE-00005` (mailer).
- Cross-link FSM: `INF-BE-00006` (`CargoOfferExpirationJob` — el otro path que devuelve `TransportWindow` a `open` cuando expira un `CargoOffer` no aceptado a las 48h; comparte la invariante de "Window vuelve a `open` en la misma tx").
- Hijos: `REQ-BE-00007` (pago tras aceptación), US18 (mark picked up), US19 (mark delivered).

## Acceptance Criteria

- [ ] `POST /api/carriers/me/cargo-offers/:id/accept` con request specs: happy path, ya aceptado (409), expirado (409), no-owner (403), `Cargo` padre no `open` (409).
- [ ] **Cascada sibling-reject en una sola DB transaction**, en este orden exacto:
  1. Winner `CargoOffer`: `pending → accepted`.
  2. Winner `TransportWindow`: `pending_offer → reserved`.
  3. Winner `Cargo`: `open → accepted`.
  4. Cada sibling `CargoOffer` `pending` del mismo `Cargo`: `pending → rejected`.
  5. Cada `TransportWindow` de sibling rechazado: `pending_offer → open` (visible al marketplace).
  6. Se crea el `Shipment` asociado.
- [ ] Si cualquier paso falla, **rollback total** — spec que fuerza un fallo en paso 4 y verifica que winner y Cargo no quedan promovidos.
- [ ] `winner.with_lock` previene race con `CargoOfferExpirationJob` (spec concurrente: job intenta expirar mientras accept está in-flight).
- [ ] Notificación email al Shipper ganador con link de pago.
- [ ] Notificación email a Shippers de siblings rechazados.
- [ ] `GET /api/carriers/me/shipments` lista el `Shipment` derivado del `Cargo` aceptado (default view: in-progress; soporta `?status=in_transit|delivered|cancelled|disputed`).
- [ ] Frontend: botón "Aceptar" con confirmación; copy via i18n keys.
- [ ] Pantalla `/carrier/shipments` placeholder (status como query param, no como route segment).
- [ ] E2E: Shipper A crea `CargoOffer` contra Window W1, Shipper B crea `CargoOffer` contra Window W2 sobre el mismo `Cargo` → Carrier acepta el de A → Shipper A recibe email con link, Shipper B recibe rechazo, Window W2 vuelve a aparecer en marketplace.
