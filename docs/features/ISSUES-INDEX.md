# Issues Index

This file tracks all issues managed by gdsi-sdlc. For execution order and parallelization see [`DEPENDENCY-GRAPH.md`](DEPENDENCY-GRAPH.md).

## Active Issues

| TAG | Title | S | Scope | Created | Plan |
|-----|-------|---|-------|---------|------|
| INF-GEN-00002 | Bootstrap backend, frontend, docs y AI harness | DONE | GEN | 2026-05-03 | PR #63 |
| INF-BE-00003 | Agregar ActiveAdmin al backend | DONE | BE | 2026-05-03 | PR #73 |
| INF-INFRA-00001 | Mover workflows de CI a la raíz del repo con filtros por paths | NEW | INFRA | 2026-05-03 | - |
| INF-INFRA-00002 | Agregar workflow de Frontend CI (Vitest + vite build + Playwright) | NEW | INFRA | 2026-05-03 | - |
| INF-FE-00002 | Actualizar frontend/.gitignore a estándares industriales (incluir .vite/ y env files) | DONE | FE | 2026-05-03 | PR #66 |
| REQ-BE-00005 | Diseñar modelo de dominio inicial (Identity bounded context primero) | IR | BE | 2026-05-03 | [plan](REQ/REQ-BE-00005/REQ-BE-00005-disenar-modelo-de-dominio-inicial.plan.md) |
| REQ-DOC-00002 | Crear artefacto de riesgos con metodología, registro y cobertura por categorías | DONE | DOC | 2026-04-18 | PR #77 |
| INF-GEN-00001 | Sin estimaciones: Proyecciones basadas en Throughput | DONE | GEN | 2026-04-18 | PR #81 |
| REQ-FE-00006 | Búsqueda de ventanas de transporte por zona origen/destino y rango de fechas (split US4) | NEW | FE | 2026-05-03 | - |
| REQ-FE-00007 | Paginado de resultados de búsqueda de ventanas de transporte (split US4) | NEW | FE | 2026-05-03 | - |
| REQ-FE-00008 | Ordenamiento de resultados de búsqueda de ventanas de transporte (split US4) | NEW | FE | 2026-05-03 | - |
| REQ-BE-00006 | Integración con Mercado Pago — checkout (cliente paga reserva) (split US8) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00007 | Flujo de pago del expedidor al aceptar la oferta (post-aceptación del transportista) (split US8) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00008 | Revelar datos de contacto del Carrier al Shipper tras pago confirmado (split US8) | NEW | BE | 2026-05-03 | - |
| REQ-FE-00009 | Integración con Google Maps SDK (split US13) | NEW | FE | 2026-05-03 | - |
| REQ-FE-00010 | Navegación en vivo — ruta + posición GPS (split US13) | NEW | FE | 2026-05-03 | - |
| REQ-FE-00011 | ETA + distancia + reroute on deviation (split US13) | NEW | FE | 2026-05-03 | - |
| REQ-BE-00009 | Registro de vehículo — datos básicos + fotos (split US14) | DONE | BE | 2026-05-03 | PR #144 |
| REQ-BE-00010 | Soporte multi-vehículo (flota) por transportista (split US14) | DONE | BE | 2026-05-03 | PR #144 |
| REQ-BE-00011 | Payout vía Mercado Pago al transportista tras confirmación de entrega (split US15) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00012 | Historial y detalle de pagos recibidos por el transportista (split US15) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00013 | Reseñas — modelo + creación de reseña post-viaje (split US20) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00014 | Reseñas — listado y promedio en perfil del transportista (split US20) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00015 | Reseñas — enforcement "una reseña por viaje" (split US20) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00016 | Seguros — integración con proveedor (split US25) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00017 | Seguros — cotización por valor y distancia (split US25) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00018 | Seguros — contratación, pago y emisión de póliza (split US25) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00019 | Seguros — declaración y seguimiento de siniestros (split US25) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00020 | Implementar contexto Identity — migraciones + modelos AR (foundation) | DONE | BE | 2026-05-03 | PR #133 |
| REQ-BE-00021 | Implementar contexto Marketplace — TransportWindow, CargoOffer, Quote (foundation) [^1] | DONE | BE | 2026-05-03 | PR #134 |
| REQ-BE-00022 | Implementar contexto Fulfilment — Shipment + state machine, TrackingEvent, Route (foundation) | DONE | BE | 2026-05-03 | PR #135 |
| REQ-BE-00023 | Auth fullstack — registro, login, sesiones + pantallas (foundation, US1+US2) | DONE | BE | 2026-05-03 | PR #145 |
| INF-BE-00001 | Reestructurar WBS por funcionalidades (no por pantallas/usuarios) | RDY | BE | 2026-04-18 | [plan](INF/INF-BE-00001/INF-BE-00001-reestructurar-wbs.plan.md) |
| INF-BE-00004 | API error envelope estándar + base controller helpers (foundation) | NEW | BE | 2026-05-03 | - |
| INF-BE-00005 | ActionMailer + Solid Queue — scaffolding de emails transaccionales (foundation) | NEW | BE | 2026-05-03 | - |
| INF-FE-00003 | Routing (React Router) + split de App.tsx en estructura por feature (foundation) | NEW | FE | 2026-05-03 | - |
| REQ-FE-00012 | Modificar perfil de usuario (US3) | NEW | FE | 2026-05-03 | - |
| REQ-FE-00013 | Filtrado multi-criterio en búsqueda de ventanas de transporte (US5) | NEW | FE | 2026-05-03 | - |
| REQ-FE-00014 | Página de detalle de transportista — perfil público + CTA ofertar (US6) | NEW | FE | 2026-05-03 | - |
| REQ-FE-00015 | Ofertar carga contra ventana del transportista — wizard de creación de CargoOffer (US7) | IR | FE | 2026-05-03 | PR #193 |
| REQ-FE-00016 | Publicar ventana de transporte — TransportWindow CRUD (US9) | IR | FE | 2026-05-03 | [plan](REQ/REQ-FE-00016/REQ-FE-00016-transport-window-crud.plan.md) |
| REQ-FE-00017 | Bandeja de ofertas recibidas por el transportista (US10) | NEW | FE | 2026-05-03 | - |
| REQ-FE-00018 | Filtrado de ofertas de carga en bandeja del transportista (US11) | NEW | FE | 2026-05-03 | - |
| REQ-BE-00024 | Aceptación de CargoOffer por el transportista con cascada sibling-reject (US12) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00025 | Cambiar contraseña (US16) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00026 | Marcar producto como retirado — Shipment → in_transit (US18) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00027 | Marcar producto como entregado — Shipment → delivered + dispara payout (US19) | NEW | BE | 2026-05-03 | - |
| REQ-FE-00019 | Tracking de envío en tiempo real (US21) | NEW | FE | 2026-05-03 | - |
| REQ-BE-00028 | Verificación de cuenta por email (US22) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00029 | Editar y eliminar reseña (US26) | NEW | BE | 2026-05-03 | - |
| REQ-FE-00020 | Historial de viajes — cliente y transportista, con detalle y reseñas (US17) | NEW | FE | 2026-05-03 | - |
| REQ-BE-00030 | Viajes compuestos — multi-pickup/multi-delivery (US23) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00031 | Encadenado de pedidos — rutas secuenciales (US24) | NEW | BE | 2026-05-03 | - |
| REQ-FE-00021 | Dashboard post-login + navegación global (Sprint 1 UX glue) | NEW | FE | 2026-05-10 | - |
| REF-BE-00001 | Migrar Api::AuthController a Devise + devise-jwt (login/logout/me con JWT); mantener register custom | RDY | BE | 2026-05-11 | [plan](REF/REF-BE-00001/REF-BE-00001-migrar-sessions-auth-a-herencia-devise.plan.md) |
| REF-BE-00002 | Rename Quote → CargoOffer y CargoOffer → Cargo en el backend (modelos, tablas, AA, specs, seeds) | IR | BE | 2026-05-19 | [plan](REF/REF-BE-00002/REF-BE-00002-rename-quote-cargooffer-y-cargooffer-cargo-en-backend.plan.md) |
| REQ-BE-00032 | Cargo fullstack — modelo, endpoints, FSM + "Mis cargas" UI (US27) | IR | BE | 2026-05-19 | [plan](REQ/REQ-BE-00032/REQ-BE-00032-cargo-fullstack-us27.plan.md) |
| INF-BE-00006 | CargoOfferExpirationJob — auto-expira `pending` a las 48 h y flipea Window a `open` (mismo tx) | NEW | BE | 2026-05-19 | [#200](https://github.com/tcorzo/fiuba-gestion-tp/issues/200) |

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
