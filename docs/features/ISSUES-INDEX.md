# Issues Index

This file tracks all issues managed by gdsi-sdlc. For execution order and parallelization see [`DEPENDENCY-GRAPH.md`](DEPENDENCY-GRAPH.md).

## Active Issues

| TAG | Title | S | Scope | Created | Plan |
|-----|-------|---|-------|---------|------|
| INF-GEN-00002 | Bootstrap backend, frontend, docs y AI harness | DONE | GEN | 2026-05-03 | PR #63 |
| INF-BE-00003 | Agregar ActiveAdmin al backend | DONE | BE | 2026-05-03 | PR #73 |
| INF-INFRA-00001 | Mover workflows de CI a la raíz del repo con filtros por paths | DONE | INFRA | 2026-05-03 | - |
| INF-INFRA-00002 | Agregar workflow de Frontend CI (Vitest + vite build + Playwright) | DONE | INFRA | 2026-05-03 | - |
| INF-INFRA-00004 | Automatización de deploy vía GitHub Actions con OIDC (infra-plan, infra-apply, backend-deploy, frontend-deploy) | DONE | INFRA | 2026-05-19 | [plan](INF/INF-INFRA-00004/INF-INFRA-00004-automatizacion-de-deploy-via-github-actions-oidc.plan.md) · [#202](https://github.com/tcorzo/fiuba-gestion-tp/issues/202) |
| INF-FE-00002 | Actualizar frontend/.gitignore a estándares industriales (incluir .vite/ y env files) | DONE | FE | 2026-05-03 | PR #66 |
| REQ-BE-00005 | Diseñar modelo de dominio inicial (Identity bounded context primero) | IR | BE | 2026-05-03 | [plan](REQ/REQ-BE-00005/REQ-BE-00005-disenar-modelo-de-dominio-inicial.plan.md) |
| REQ-DOC-00002 | Crear artefacto de riesgos con metodología, registro y cobertura por categorías | DONE | DOC | 2026-04-18 | PR #77 |
| INF-GEN-00001 | Sin estimaciones: Proyecciones basadas en Throughput | DONE | GEN | 2026-04-18 | PR #81 |
| REQ-FE-00006 | Búsqueda de ventanas de transporte por zona origen/destino y rango de fechas (split US4) | DONE | FE | 2026-05-03 | - |
| REQ-BE-00009 | Registro de vehículo — datos básicos + fotos (split US14) | DONE | BE | 2026-05-03 | PR #144 |
| REQ-BE-00010 | Soporte multi-vehículo (flota) por transportista (split US14) | DONE | BE | 2026-05-03 | PR #144 |
| REQ-BE-00020 | Implementar contexto Identity — migraciones + modelos AR (foundation) | DONE | BE | 2026-05-03 | PR #133 |
| REQ-BE-00021 | Implementar contexto Marketplace — TransportWindow, CargoOffer, Quote (foundation) [^1] | DONE | BE | 2026-05-03 | PR #134 |
| REQ-BE-00022 | Implementar contexto Fulfilment — Shipment + state machine, TrackingEvent, Route (foundation) | DONE | BE | 2026-05-03 | PR #135 |
| REQ-BE-00023 | Auth fullstack — registro, login, sesiones + pantallas (foundation, US1+US2) | DONE | BE | 2026-05-03 | PR #145 |
| INF-BE-00001 | Reestructurar WBS por funcionalidades (no por pantallas/usuarios) | RDY | BE | 2026-04-18 | [plan](INF/INF-BE-00001/INF-BE-00001-reestructurar-wbs.plan.md) |
| REQ-FE-00012 | Modificar perfil de usuario (US3) | DONE | FE | 2026-05-03 | - |
| REQ-FE-00014 | Página de detalle de transportista — perfil público + CTA ofertar (US6) | DONE | FE | 2026-05-03 | - |
| REQ-FE-00015 | Ofertar carga contra ventana del transportista — wizard de creación de CargoOffer (US7) | DONE | FE | 2026-05-03 | PR #193 |
| REQ-FE-00016 | Publicar ventana de transporte — TransportWindow CRUD (US9) | DONE | FE | 2026-05-03 | [plan](REQ/REQ-FE-00016/REQ-FE-00016-transport-window-crud.plan.md) |
| INF-FE-00005 | Framework de notificaciones web en tiempo real (scaffold) | READY | FE | 2026-05-22 | [plan](INF/INF-FE-00005/INF-FE-00005-framework-notificaciones-web-scaffold.plan.md) · [#217](https://github.com/tcorzo/fiuba-gestion-tp/issues/217) |
| REQ-FE-00017 | Bandeja de ofertas recibidas por el transportista (US10) | NEW | FE | 2026-05-03 | - |
| REQ-BE-00024 | Aceptación de CargoOffer por el transportista con cascada sibling-reject (US12) | NEW | BE | 2026-05-03 | - |
| REQ-FE-00021 | Dashboard post-login + navegación global (Sprint 1 UX glue) | DONE | FE | 2026-05-10 | - |
| REF-BE-00001 | Migrar Api::AuthController a Devise + devise-jwt (login/logout/me con JWT); mantener register custom | DONE | BE | 2026-05-11 | [plan](REF/REF-BE-00001/REF-BE-00001-migrar-sessions-auth-a-herencia-devise.plan.md) |
| REF-BE-00002 | Rename Quote → CargoOffer y CargoOffer → Cargo en el backend (modelos, tablas, AA, specs, seeds) | DONE | BE | 2026-05-19 | [plan](REF/REF-BE-00002/REF-BE-00002-rename-quote-cargooffer-y-cargooffer-cargo-en-backend.plan.md) |
| REQ-BE-00032 | Cargo fullstack — modelo, endpoints, FSM + "Mis cargas" UI (US27) | DONE | BE | 2026-05-19 | [plan](REQ/REQ-BE-00032/REQ-BE-00032-cargo-fullstack-us27.plan.md) |
| REQ-BE-00033 | US8 — Realizar pago del expedidor sobre CargoOffer aceptado (gateway mock) | RDY | BE | 2026-05-22 | [plan](REQ/REQ-BE-00033/REQ-BE-00033-us8-realizar-pago-expedidor.plan.md) |
| INF-GEN-00003 | team-performance: medir throughput por User Stories completadas vía ledger por sprint | DONE | GEN | 2026-05-20 | [#207](https://github.com/tcorzo/fiuba-gestion-tp/pull/207) |
| FIX-BE-00001 | Permitir destino nullable en TransportWindow (US4/US5 rework) | RDY | BE | 2026-05-22 | [plan](FIX/FIX-BE-00001/FIX-BE-00001-permitir-destino-nullable-en-transport-window.plan.md) |
| REQ-BE-00034 | Baja de vehículo por el transportista (soft delete, ADR-009) (US32) | RDY | BE | 2026-05-22 | [plan](REQ/REQ-BE-00034/REQ-BE-00034-us32-baja-de-vehiculo-soft-delete.plan.md) |
| REQ-BE-00035 | Endpoints de índice y detalle de Envíos (Carrier / Shipper / detalle) (US17 + US39) | IR | BE | 2026-05-24 | [plan](REQ/REQ-BE-00035/REQ-BE-00035-envios-index-endpoints.plan.md) |
| REQ-FE-00022 | Listado de Envíos del Transportista (US17 — vista Carrier) | NEW | FE | 2026-05-24 | - |
| REQ-FE-00023 | Listado de Envíos del Expedidor (US17 — vista Shipper) | NEW | FE | 2026-05-24 | - |
| REQ-FE-00024 | Detalles de Envío (US39 — pantalla compartida con acciones contextuales por rol) | RDY | FE | 2026-05-24 | - |
| REQ-FE-00025 | Selector de Direcciones — Ventana de Transporte (US48 — picker FE compartido) | RDY | FE | 2026-05-24 | [plan](REQ/REQ-FE-00025/REQ-FE-00025-us48-selector-direcciones-ventana-transporte.plan.md) |
| REQ-FE-00026 | Selector de Direcciones — Carga (US49 — reuso del picker compartido) | RDY | FE | 2026-05-24 | [plan](REQ/REQ-FE-00026/REQ-FE-00026-us49-selector-direcciones-carga.plan.md) |
| REQ-FE-00027 | Definir Radio de Recogida — input numérico + círculo arrastrable (US50) | RDY | FE | 2026-05-24 | [plan](REQ/REQ-FE-00027/REQ-FE-00027-us50-definir-radio-de-recogida.plan.md) |
| REQ-FE-00028 | Mapa y Enlaces a Google Maps en Detalle de Envío (US51 — FE-only) | RDY | FE | 2026-05-24 | [plan](REQ/REQ-FE-00028/REQ-FE-00028-us51-mapa-enlaces-gmaps-detalle-envio.plan.md) |
| REQ-BE-00036 | Migraciones y validaciones de lat/lng para TransportWindow y Cargo (US48 + US49) | RDY | BE | 2026-05-24 | [plan](REQ/REQ-BE-00036/REQ-BE-00036-us48-us49-lat-lng-migrations.plan.md) |
| REQ-BE-00037 | pickup_radius_km column + Haversine matcher en el US5 scope (US50) | RDY | BE | 2026-05-24 | [plan](REQ/REQ-BE-00037/REQ-BE-00037-us50-pickup-radius-haversine-matcher.plan.md) |

## Legend

**Status (S):**
- `NEW` - In Backlog, not yet planned
- `RDY` - Ready for implementation
- `IP` - In Progress
- `IR` - In Review
- `DONE` - Completed

**Prefixes:** REQ (feature), FIX (bug), DOC, TST, REF, INF, REL

**Scopes:** DOC, BE, FE, INFRA, GEN

[^1]: Título original conservado (issue ya `DONE`). Vocabulario obsoleto tras el rename del 2026-05-19: `Quote` → `CargoOffer` y `CargoOffer` → `Cargo`. Ver [`docs/05-appendices/glossary.md`](../05-appendices/glossary.md) y el refactor de código `REF-BE-00002`.
