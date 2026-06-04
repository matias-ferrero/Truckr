# Sprint 4 — Plan

- **Sprint:** 4
- **Ventana:** 2026-05-28 → 2026-06-03 (cadencia semanal jue → mié)
- **Equipo (6):** Brian Céspedes (`@bcespedes`), Fernando Yu (`@FernandoYu`), Franco Ricciardo (`@FrancoRicciardo`), Lucas Dondo (`@LucasDondo`), Matías Ferrero (`@matias-ferrero`), Tomás Corzo (`@tcorzo`).
- **PM/SM:** Tomás.

## Objetivo del sprint

> **Cerrar el flujo geoespacial end-to-end:** que las Ventanas de Transporte y las Cargas usen direcciones concretas con coordenadas, la búsqueda aplique Haversine con radio de recogida y se migre el matcher a address-driven (retirando los matchers de provincia), mientras el Detalle de Envío queda funcional como pantalla central del Carrier y el Shipper. En paralelo: completar los carryovers urgentes (US32, US39), habilitar el ciclo de vida completo del Envío con las transiciones de Carrier (US18/US19), iniciar el sistema de reseñas (US20/US26/US30/US54), y cerrar definitivamente el scaffold de notificaciones con sus primeros consumidores reales.

Sprint 4 no introduce surface areas nuevas que no hayan sido diseñadas ya: consolida el trabajo geoespacial de Tomás (PR #264 en vuelo desde Sprint 3), cierra los carryovers pendientes desde Sprint 2 (notificaciones) y Sprint 3 (US32, US39), y arranca el sistema de reseñas que completará el ciclo de confianza entre Carrier y Shipper.

## Compromisos por integrante

| Integrante | TAG (gh #) | Trabajo | Tipo | Carryover |
|---|---|---|---|---|
| **Tomás** (`@tcorzo`) | `REQ-BE-00036` (#234) + `REQ-BE-00037` (#235) — PR #264 | US48+US49+US50 BE: migraciones lat/lng en `TransportWindow` y `Cargo`, columna `pickup_radius_km`, Haversine matcher. PR en vuelo al inicio del sprint. | Feature | Sí — arrancado en Sprint 3 |
| **Tomás** (`@tcorzo`) — secuencial post-merge #264 | `REQ-FE-00025` (#239) | US48 — Selector de Direcciones FE para Ventana de Transporte (picker compartido). Desbloquea por merge de PR #264. | Feature | No |
| **Tomás** (`@tcorzo`) — secuencial post-merge #264 | `REQ-FE-00026` (#240) | US49 — Selector de Direcciones FE para Carga (reuso del picker compartido de US48). Desbloquea por merge de PR #264. | Feature | No |
| **Tomás** (`@tcorzo`) — secuencial post-merge #264 | `REQ-FE-00027` (#241) | US50 — Radio de Recogida FE: input numérico + círculo arrastrable sobre el mapa. Desbloquea por merge de PR #264. | Feature | No |
| **Matías** (`@matias-ferrero`) | `REQ-FE-00024` (#238) | US39 — Detalle de Envío (`/carrier/shipments/:id` y `/shipper/shipments/:id`). Componente único con acciones según rol. Carryover sin PR al cierre de Sprint 3. | Feature | Sí |
| **Franco** (`@FrancoRicciardo`) | `REQ-BE-00038` (#243) | US18+US19 — Transiciones de Shipment: `start_transit` (Carrier confirma inicio) y `deliver` (Carrier confirma entrega). Carrier-only; actualiza `TrackingEvent`. | Feature | No |
| **Lucas** (`@LucasDondo`) | `REQ-BE-00034` (#215) | US32 — Baja de vehículo (soft delete vía `discard`, ADR-009). PR #275 abierto al inicio del sprint, pendiente review. | Feature | Sí — PR en review |
| **Lucas** (`@LucasDondo`) | `REQ-BE-00042` (#281) | US20 — Crear Reseña de Transportista (Shipper→Carrier, fullstack). Rating 1–5 + comentario; se habilita cuando el Shipment pasa a `delivered`. | Feature | No |
| **Lucas** (`@LucasDondo`) | `REQ-BE-00043` (#282) | US26 — Visualizar Reseñas de Transportista (fullstack). Listado público de reseñas recibidas por el Carrier, agregado de rating. | Feature | No |
| **Brian** (`@bcespedes`) | `REQ-BE-00044` (#283) | US30 — Crear Reseña de Expedidor (Carrier→Shipper, fullstack). Simétrico a US20, Carrier evalúa al Shipper post-entrega. | Feature | No |
| **Brian** (`@bcespedes`) | `REQ-BE-00045` (#284) | US54 — Visualizar Reseñas de Expedidor (fullstack). Perfil público del Shipper con su historial de reseñas recibidas. | Feature | No |
| **Fernando** (`@FernandoYu`) | `INF-FE-00005` (#217) + (local) consumidores de notificaciones | (a) Cerrar el scaffold de ActionCable + Solid Cable sobre SQLite. (b) Implementar los primeros consumidores reales de notificaciones: **oferta recibida** (Carrier recibe CargoOffer), **cambio de estado de Shipment** (start_transit / deliver), **confirmación de pago** — los tres canales que ya tiene el dominio. Sin issues GH todavía para (b); se crean en el sprint si el scope lo justifica. | Infra | (a) Sí — carryover de Sprint 2+3; (b) No |

**Matías** actúa como free-agent después de completar #238: absorbe el primer issue sin dueño disponible o contribuye como reviewer en los PRs de Tomás (geo cluster) y Lucas (US32).

## Carryovers (lo que NO es trabajo nuevo)

- **Tomás — PR #264 (US48+US49+US50 BE).** Arrancado en Sprint 3 dentro de la US de "marcar Recorrido" diferida y la tarea de geocoding. PR abierto al inicio de Sprint 4; Tomás lo cierra primero para desbloquear sus tres FE issues.
- **Matías — US39 FE (`REQ-FE-00024`, #238).** Add-on mid-Sprint 3 sin PR al cierre. Los endpoints BE de Shipments (`REQ-BE-00035`, ya en `main`) están disponibles; Matías arranca contra `main` desde día 1.
- **Lucas — US32 (`REQ-BE-00034`, #215) — PR #275.** PR abierto al cierre de Sprint 3, sin review. Prioridad alta en la cola de reviews de Sprint 4.
- **Fernando — INF-FE-00005 (#217).** Scaffold de notificaciones arrastra desde Sprint 2. Sprint 4 es el sprint donde tiene que cerrar, con al menos un consumidor real conectado al dominio.

## Dependencias entre tareas

| Origen | Destino | Naturaleza | Acción |
|---|---|---|---|
| Tomás — PR #264 (US48+US49+US50 BE) | Tomás — FE cluster (#239, #240, #241) | Los selectores de dirección y el radio FE consumen los endpoints y el esquema que introduce PR #264. | Tomás auto-secuencia: cierra PR #264 primero, abre el FE encima. Puede mockear el contract para arrancar UI en paralelo si la review demora. |
| Tomás — `REQ-BE-00035` Envíos index (ya en `main`) | Matías — US39 FE (#238) | El detalle consume `GET /api/shipments/:id`. | Endpoint disponible; Matías arranca desde día 1 contra `main`. |
| Lucas — PR #275 (US32) | Review del equipo | PR abierto, sin reviewer asignado. | Franco o Brian toman la review en día 1–2 para no bloquear a Lucas con sus issues de reseñas. |
| Brian — `REQ-BE-00033` (US8 Payment, ya en `main`) | Lucas — US20/US26 (`REQ-BE-00042/43`) + Brian — US30/US54 | Las reseñas se habilitan post-`delivered`; el chip de `payment.state` aparece en el contexto. | El endpoint de payments ya está; si el estado exacto es ambiguo, mockear en UI para no bloquear el merge del FE. |
| Franco — `REQ-BE-00038` (US18+US19 transitions) | Futuras US de tracking | Las transiciones `start_transit` / `deliver` son prerequisito para el tracking de recorrido. | No afecta Sprint 4; Franco implementa sin dependencia upstream en este sprint. |
| Fernando — `INF-FE-00005` scaffold | Fernando — (local) consumidores | Los consumidores de notificaciones necesitan el canal ActionCable levantado. | Fernando entrega scaffold primero en la semana, conecta consumidores encima. |

## Fuera de alcance — diferido deliberadamente

- **US51 — Mapa estático + deep-links GMaps en Detalle de Envío (#242).** Queda para Sprint 5. US39 (Detalle de Envío) deja el placeholder `<section id="shipment-tracking-map">` que US51 reemplazará.
- **Integración real con MercadoPago.** US8 ship con gateway mockeado; no hay sprint que incluya el swap real.
- **US11 — filtrado de ofertas.** Sin demanda suficiente para desplazar issues de mayor valor.
- **Hard delete / purge job para vehículos descartados.** US32 ship como soft delete; suficiente para el MVP.
- **Filtros / búsqueda / paginación en listados de Envíos y Reseñas.** Scope cut explícito; el listado entrega una sola página ordenada por `updated_at desc`.
- **Route tracking / "marcar Recorrido" en mapa.** Sin US ni TAG todavía; diferida indefinidamente hasta que el equipo la priorice.
- **Issues de dependencias de seguridad (Dependabot #228, #201).** No son trabajo del sprint; el PM los mergea si pasan CI.

## Definition of Done

Cada compromiso cierra cuando se cumple lo siguiente:

1. Código mergeado a `main` vía PR aprobado, con `Closes #N` referenciando la issue.
2. CI en verde: RSpec, Vitest + Playwright (e2e cuando toca UI), `just lint`, `just build-artifacts` (cuando toca `docs/`).
3. Para cambios de frontend: corrida de las skills `/critique` → `/polish` → `/audit` (gate documentado en `CLAUDE.md` § "Pre-PR UI quality gate"). Findings intencionales se anotan en el body del PR.
4. Acceptance criteria de la US verificados por alguien distinto al autor durante el review.
5. Demoable end-to-end en el entorno desplegado.
6. Artifact o documentación afectada actualizada (USM, backlog-us, glossary) si el cambio toca un concepto del dominio.

## Riesgos

- **Tomás concentra 6 issues del cluster geo.** PR #264 bloquea los tres FE issues (#239, #240, #241). Si PR #264 no obtiene review en día 1–2, el FE cluster no puede arrancar. **Mitigación**: Matías o Franco toman la review de #264 el día 1; Tomás puede abrir el FE en un branch paralelo mockeando el contract si la review demora más de 2 días.
- **Lucas tiene 3 issues: 1 en review + 2 nuevas (reseñas fullstack).** Si la review de US32 (PR #275) se extiende con rondas de cambios, las reseñas quedan comprimidas al final de la semana. **Mitigación**: review de #275 en día 1 (Franco o Brian). Si las reseñas no cierran, se carryovean a Sprint 5 — las reseñas son P2 y no bloquean la demo principal.
- **Fernando arrastra el scaffold de notificaciones desde Sprint 2.** Tercer sprint consecutivo sin cerrar. Sprint 4 es el límite: si no hay un consumidor real conectado al cierre, el PM evalúa reasignar el issue a otro integrante. **Mitigación**: scope mínimo definido — un canal, un consumidor real (oferta recibida), CI en verde — no se espera que los tres consumidores cierren si la infra consume más tiempo del esperado.
- **Las reseñas (US20/US26/US30/US54) son issues "fullstack"** — BE + FE en el mismo issue. Cada una puede esconder más scope del estimado. **Mitigación**: Lucas y Brian definen el scope mínimo demoable (crear reseña + verla en perfil) en los primeros dos días; si el FE queda incompleto, el BE se mergea solo y el FE carryovea.
- **`cronograma.typ` desalineado.** Hay que actualizarlo cuando se confirme el cierre del sprint, no dentro de esta sesión.

## Referencias

- User stories: [`docs/artifacts/backlog-us.typ`](../artifacts/backlog-us.typ) (US18 línea ~280, US19, US20, US26, US30, US32, US39, US48, US49, US50, US54).
- PR #264 (Tomás, geo BE en vuelo): `feat(fulfilment): geocoded addresses, pickup radius, and Haversine matching`.
- PR #275 (Lucas, US32 en review): `feat(vehicles): implemented soft deletion of vehicles`.
- Issues: `gh issue list --repo tcorzo/fiuba-gestion-tp --state open`.
- Cronograma planificado: [`docs/artifacts/cronograma.typ`](../artifacts/cronograma.typ).
- Glosario (fuente de verdad de términos): [`docs/05-appendices/glossary.md`](../05-appendices/glossary.md).
- Issues vivas: `.gdsi-sdlc/issues/{Ready,InProgress,Backlog}/` + `gh issue list --repo tcorzo/fiuba-gestion-tp`.
- Sprint 3 — Plan: [`SPRINT-3-PLAN.md`](SPRINT-3-PLAN.md) (estructura de referencia).
- Sprint 3 — Cierre: [`../sprints/sprint-03.md`](../sprints/sprint-03.md).
- Política de DB (SQLite forever) y de idioma (inglés en código, español en UI vía i18n): [`../../CLAUDE.md`](../../CLAUDE.md).
- Throughput / proyección: se corre la skill `team-performance` al cierre del sprint, no en planning.

## Mapping at a glance

```
Sprint 4 commitment
├── Geo BE (US48+49+50)     ─▶ REQ-BE-00036 (#234)
│                              + REQ-BE-00037 (#235) — PR #264  (Tomás)  ── carryover Sprint 3
├── US48 Selector Dir. TW   ─▶ REQ-FE-00025 (#239)             (Tomás)  ── post-merge #264
├── US49 Selector Dir. Cargo ─▶ REQ-FE-00026 (#240)             (Tomás)  ── post-merge #264
├── US50 Radio de Recogida  ─▶ REQ-FE-00027 (#241)             (Tomás)  ── post-merge #264
├── US39 Detalle de Envío   ─▶ REQ-FE-00024 (#238)             (Matías) ── carryover Sprint 3
├── US18+US19 Transitions   ─▶ REQ-BE-00038 (#243)             (Franco) ── start_transit / deliver
├── US32 Baja de Vehículo   ─▶ REQ-BE-00034 (#215) — PR #275   (Lucas)  ── en review al inicio
├── US20 Reseña → Carrier   ─▶ REQ-BE-00042 (#281)             (Lucas)  ── fullstack
├── US26 Ver Reseñas Carrier ─▶ REQ-BE-00043 (#282)             (Lucas)  ── fullstack
├── US30 Reseña → Shipper   ─▶ REQ-BE-00044 (#283)             (Brian)  ── fullstack
├── US54 Ver Reseñas Shipper ─▶ REQ-BE-00045 (#284)             (Brian)  ── fullstack
└── Notif scaffold + consums ─▶ INF-FE-00005 (#217) + (local)  (Fernando) ── carryover Sprint 2+3

Diferido a Sprint 5
└── US51 Mapa + GMaps links  ─▶ REQ-FE-00028 (#242)                     ── monta sobre US39
```
