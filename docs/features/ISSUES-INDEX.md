# Issues Index

This file tracks all issues managed by gdsi-sdlc. For execution order and parallelization see [`DEPENDENCY-GRAPH.md`](DEPENDENCY-GRAPH.md).

## Active Issues

| TAG | Title | S | Scope | Created | Plan |
|-----|-------|---|-------|---------|------|
| INF-GEN-00002 | Bootstrap backend, frontend, docs y AI harness | DONE | GEN | 2026-05-03 | PR #63 |
| INF-BE-00003 | Agregar ActiveAdmin al backend | IR | BE | 2026-05-03 | [plan](INF/INF-BE-00003/INF-BE-00003-add-activeadmin.plan.md) |
| INF-INFRA-00001 | Mover workflows de CI a la raíz del repo con filtros por paths | NEW | INFRA | 2026-05-03 | - |
| INF-INFRA-00002 | Agregar workflow de Frontend CI (Vitest + vite build + Playwright) | NEW | INFRA | 2026-05-03 | - |
| INF-FE-00002 | Actualizar frontend/.gitignore a estándares industriales (incluir .vite/ y env files) | DONE | FE | 2026-05-03 | PR #66 |
| REQ-BE-00005 | Diseñar modelo de dominio inicial (Identity bounded context primero) | IR | BE | 2026-05-03 | [plan](REQ/REQ-BE-00005/REQ-BE-00005-disenar-modelo-de-dominio-inicial.plan.md) |
| REQ-DOC-00002 | Crear artefacto de riesgos con metodología, registro y cobertura por categorías | IR | DOC | 2026-04-18 | PR #77 |
| INF-GEN-00001 | Sin estimaciones: Proyecciones basadas en Throughput | IR | GEN | 2026-04-18 | [plan](INF/INF-GEN-00001/INF-GEN-00001-team-performance-script.plan.md) |
| REQ-FE-00006 | Búsqueda de transportistas por zona origen/destino y rango de fechas (split US4) | NEW | FE | 2026-05-03 | - |
| REQ-FE-00007 | Paginado de resultados de búsqueda de transportistas (split US4) | NEW | FE | 2026-05-03 | - |
| REQ-FE-00008 | Ordenamiento de resultados de búsqueda de transportistas (split US4) | NEW | FE | 2026-05-03 | - |
| REQ-BE-00006 | Integración con Mercado Pago — checkout (split US8) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00007 | Flujo de pago del cliente al aceptar la oferta (split US8) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00008 | Revelar datos de contacto del transportista al cliente tras pago confirmado (split US8) | NEW | BE | 2026-05-03 | - |
| REQ-FE-00009 | Integración con Google Maps SDK (split US13) | NEW | FE | 2026-05-03 | - |
| REQ-FE-00010 | Navegación en vivo — ruta + posición GPS (split US13) | NEW | FE | 2026-05-03 | - |
| REQ-FE-00011 | ETA + distancia + reroute on deviation (split US13) | NEW | FE | 2026-05-03 | - |
| REQ-BE-00009 | Registro de vehículo — datos básicos + fotos (split US14) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00010 | Soporte multi-vehículo (flota) por transportista (split US14) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00011 | Payout vía Mercado Pago al transportista tras confirmación de entrega (split US15) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00012 | Historial y detalle de pagos recibidos por el transportista (split US15) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00013 | Reseñas — modelo + creación de reseña post-viaje (split US20) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00014 | Reseñas — listado y promedio en perfil del transportista (split US20) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00015 | Reseñas — enforcement "una reseña por viaje" (split US20) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00016 | Seguros — integración con proveedor (split US25) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00017 | Seguros — cotización por valor y distancia (split US25) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00018 | Seguros — contratación, pago y emisión de póliza (split US25) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00019 | Seguros — declaración y seguimiento de siniestros (split US25) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00020 | Implementar contexto Identity — migraciones + modelos AR (foundation) | IR | BE | 2026-05-03 | [plan](REQ/REQ-BE-00020/REQ-BE-00020-implementar-contexto-identity.plan.md) |
| REQ-BE-00021 | Implementar contexto Marketplace — TransportWindow, CargoOffer, Quote (foundation) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00022 | Implementar contexto Fulfilment — Shipment + state machine, TrackingEvent, Route (foundation) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00023 | Auth fullstack — registro, login, sesiones + pantallas (foundation, US1+US2) | NEW | BE | 2026-05-03 | - |
| INF-BE-00001 | Reestructurar WBS por funcionalidades (no por pantallas/usuarios) | RDY | BE | 2026-04-18 | [plan](INF/INF-BE-00001/INF-BE-00001-reestructurar-wbs.plan.md) |
| INF-BE-00004 | API error envelope estándar + base controller helpers (foundation) | NEW | BE | 2026-05-03 | - |
| INF-BE-00005 | ActionMailer + Solid Queue — scaffolding de emails transaccionales (foundation) | NEW | BE | 2026-05-03 | - |
| INF-FE-00003 | Routing (React Router) + split de App.tsx en estructura por feature (foundation) | NEW | FE | 2026-05-03 | - |
| REQ-FE-00012 | Modificar perfil de usuario (US3) | NEW | FE | 2026-05-03 | - |
| REQ-FE-00013 | Filtrado multi-criterio en búsqueda de transportistas (US5) | NEW | FE | 2026-05-03 | - |
| REQ-FE-00014 | Página de detalle de transportista — perfil público + CTA ofertar (US6) | NEW | FE | 2026-05-03 | - |
| REQ-FE-00015 | Ofertar retiro de un producto — wizard de creación de oferta (US7) | NEW | FE | 2026-05-03 | - |
| REQ-FE-00016 | Publicar disponibilidad del transportista — TransportWindow CRUD (US9) | NEW | FE | 2026-05-03 | - |
| REQ-FE-00017 | Bandeja de ofertas recibidas por el transportista (US10) | NEW | FE | 2026-05-03 | - |
| REQ-FE-00018 | Filtrado de ofertas en bandeja del transportista (US11) | NEW | FE | 2026-05-03 | - |
| REQ-BE-00024 | Aceptación de viaje por el transportista (US12) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00025 | Cambiar contraseña (US16) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00026 | Marcar producto como retirado — Shipment → in_transit (US18) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00027 | Marcar producto como entregado — Shipment → delivered + dispara payout (US19) | NEW | BE | 2026-05-03 | - |
| REQ-FE-00019 | Tracking de envío en tiempo real (US21) | NEW | FE | 2026-05-03 | - |
| REQ-BE-00028 | Verificación de cuenta por email (US22) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00029 | Editar y eliminar reseña (US26) | NEW | BE | 2026-05-03 | - |
| REQ-FE-00020 | Historial de viajes — cliente y transportista, con detalle y reseñas (US17) | NEW | FE | 2026-05-03 | - |
| REQ-BE-00030 | Viajes compuestos — multi-pickup/multi-delivery (US23) | NEW | BE | 2026-05-03 | - |
| REQ-BE-00031 | Encadenado de pedidos — rutas secuenciales (US24) | NEW | BE | 2026-05-03 | - |

## Legend

**Status (S):**
- `NEW` - In Backlog, not yet planned
- `RDY` - Ready for implementation
- `IP` - In Progress
- `IR` - In Review
- `DONE` - Completed

**Prefixes:** REQ (feature), FIX (bug), DOC, TST, REF, INF, REL

**Scopes:** DOC, BE, FE, INFRA, GEN
