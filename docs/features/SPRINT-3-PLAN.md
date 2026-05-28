# Sprint 3 — Plan

- **Sprint:** 3
- **Ventana:** 2026-05-21 → 2026-05-27 (cadencia semanal jue → mié)
- **Equipo (6):** Brian Céspedes (`@bcespedes`), Fernando Yu (`@FernandoYu`), Franco Ricciardo (`@FrancoRicciardo`), Lucas Dondo (`@LucasDondo`), Matías Ferrero (`@matias-ferrero`), Tomás Corzo (`@tcorzo`).
- **PM/SM:** Tomás.

> **Enmienda 2026-05-24 (día 4 de 7).** Tras la sesión de grilling sobre los FSMs de `Shipment` / `Payment` (PR #231), se agregaron cuatro commitments al sprint (US17 Carrier+Shipper, US39, endpoints `/api/.../shipments`). Está marcado en **Riesgos** como capacity-add mid-sprint con go/no-go explícito: si la carga no entra, el corte natural es diferir US17/US39 a Sprint 4 dejando los endpoints BE como semilla.
>
> **Enmienda 2026-05-25 (día 5 de 7).** `REQ-BE-00035` (Envíos index BE) se reasigna de Franco a Tomás. Franco entra al día 5 sin PR abierto sobre el add-on y el endpoint es el critical-path de tres FE add-ons (US17 Carrier, US17 Shipper, US39 detail). Tomás absorbe el BE para tenerlo en pareja con su propio FE de US39 y desbloquear a Matías + Lucas. La US de "marcar Recorrido" (GMaps) — que nunca tuvo TAG ni issue — sale formalmente de Sprint 3 y queda diferida; ya estaba marcada como sin compromiso firme en *Fuera de alcance*. Franco queda con su carryover ya mergeado (PR #221) como único compromiso de Sprint 3.

## Objetivo del sprint

> **Cerrar el flujo de marketplace end-to-end:** que un Expedidor pueda publicar carga, recibir ofertas, aceptar una, **pagar** sobre el Shipment aceptado (con gateway mockeado), mientras se sanea la búsqueda de Ventanas de Transporte y el Transportista puede dar de baja vehículos. En paralelo, infraestructura: automatizar el deploy con OIDC y montar el scaffold de notificaciones web en tiempo real.

Sprint 3 no introduce nuevas surface areas grandes: cierra la cadena de valor que arrastramos desde Sprint 2 (US10/US12 carryover de Fran), saca el primer eslabón de monetización (US8) y deja la plataforma operativa para los sprints de calidad y release que vienen.

## Compromisos por integrante

| Integrante | TAG (gh #) | Trabajo | Tipo | Carryover |
|---|---|---|---|---|
| **Matías** (`@matias-ferrero`) | `FIX-BE-00001` (#211) | Permitir `destination` nullable en `TransportWindow` — desbloquea US4 / US5 (resto de los AC ya pasaban). | Bugfix | No |
| **Brian** (`@bcespedes`) | `REQ-BE-00033` (#213) | US8 — Realizar pago del Expedidor sobre Shipment aceptado, **gateway mockeado**. MercadoPago real diferido. | Feature | No |
| **Franco** (`@FrancoRicciardo`) | `REQ-FE-00017` (#123) + `REQ-BE-00024` (#104) — PR #221 **mergeado** | US10 (bandeja de ofertas recibidas por el Transportista) + US12 (aceptación de `CargoOffer` con cascada `sibling-reject`). Rebase resuelto, mergeado a `main` 2026-05-24. | Feature | Cerrado — fue carryover de Sprint 2 |
| **Tomás** (`@tcorzo`) | `REQ-BE-00035` (local) | Endpoints de Envíos: `GET /api/carriers/me/shipments`, `GET /api/shippers/me/shipments`, `GET /api/shipments/:id`. Base BE para US17 + US39. | Feature | No — reasignado desde Franco el 2026-05-25 (ver Enmienda) |
| **Lucas** (`@LucasDondo`) | `REQ-BE-00034` (#215) | US32 — Baja de vehículo (soft delete vía `discard`, ADR-009). | Feature | No |
| **Lucas** (`@LucasDondo`) — add-on | `REQ-FE-00023` (local) | US17 — Listado de Envíos para Expedidor (`/shipper/shipments`). Chips de `shipment.state` (4) + `payment.state` derivado. | Feature | No — agregado mid-sprint |
| **Matías** (`@matias-ferrero`) — add-on | `REQ-FE-00022` (local) | US17 — Listado de Envíos para Transportista (`/carrier/shipments`). Mismo componente UI que la versión Shipper, distinto persona-prefix y acciones. | Feature | No — agregado mid-sprint |
| **Fernando** (`@FernandoYu`) | (a) `INF-INFRA-00004` (#202) — PR #203 creó la issue; **implementación por arrancar**. (b) `INF-FE-00005` (#217). | (a) Automatización de deploy vía GitHub Actions con OIDC (`infra-plan`, `infra-apply`, `backend-deploy`, `frontend-deploy`). (b) Framework de notificaciones web en tiempo real — scaffold (ActionCable + Solid Cable sobre SQLite, según política de DB). | Infra | **(a) Sí — carryover de Sprint 2.** (b) No. |
| **Tomás** (`@tcorzo`) — add-on | `REQ-FE-00024` (local) | US39 — Detalle de envío (`/carrier/shipments/:id` y `/shipper/shipments/:id`). Componente único, acciones según rol. Placeholder para el mapa (sin US de Recorrido este sprint). | Feature | No — agregado mid-sprint |

## Carryovers (lo que NO es trabajo nuevo)

- **Franco — PR #221 (US10 + US12).** ~~Pendiente de rebase~~ **Cerrado**: rebase resuelto y mergeado a `main` el 2026-05-24 (día 4). Destraba US8 de Brian y abre la base para las US17/US39 agregadas como add-on.
- **Fernando (a) — INF-INFRA-00004 (#202).** Issue creada vía PR de triage #203, pero la implementación recién arranca este sprint. No hubo trabajo perdido en Sprint 2; es carryover de prioridad, no de código.

## Bugfixes / saneamiento

- **Matías — `FIX-BE-00001` (#211).** `TransportWindow.destination` debe poder ser nulo para soportar el camino "publico una ventana sin destino fijo" (US4/US5). El resto de los AC de US4/US5 ya estaban verdes; este fix los cierra. **No es feature nueva**, va en su propio renglón para que el sprint no parezca inflado.

## Dependencias entre tareas

| Origen | Destino | Naturaleza | Acción |
|---|---|---|---|
| Franco — PR #221 (US10/US12) ✅ | Brian — US8 | US8 toma el `Shipment` aceptado por US12 como punto de entrada del pago. | **Resuelto**: PR #221 mergeado a `main` el 2026-05-24. Brian arranca contra `main`. |
| Franco — PR #221 (US10/US12) ✅ | Tomás — `REQ-BE-00035` Envíos index | Los endpoints leen del `Shipment` que produce US12. | Resuelto por el merge de #221. |
| Tomás — `REQ-BE-00035` Envíos index | Matías — US17 Carrier FE (`REQ-FE-00022`) | El listado consume `GET /api/carriers/me/shipments`. | Tomás entrega el endpoint primero (puede mockear contract si Matías necesita arrancar UI en paralelo). |
| Tomás — `REQ-BE-00035` Envíos index | Lucas — US17 Shipper FE (`REQ-FE-00023`) | El listado consume `GET /api/shippers/me/shipments`. | Idem fila anterior. |
| Tomás — `REQ-BE-00035` Envíos index | Tomás — US39 detail FE (`REQ-FE-00024`) | El detalle consume `GET /api/shipments/:id`. | Auto-coordinación: Tomás secuencia BE → FE en su propia rama. |
| Brian — `REQ-BE-00033` US8 Payment | Tomás — US39 detail FE | El chip de `payment.state` se deriva del listado de Payments del Shipment; AC14 (cancellation interlock) afecta los botones del detalle. | Brian y Tomás alinean i18n keys y forma del JSON cuando Brian abra su PR. No bloqueante para arrancar UI con mock. |
| Fernando (b) — `INF-FE-00005` notifs | Fernando (a) — OIDC deploy | El upgrade WebSocket en el proxy Kamal forma parte del story de deploy. | Fernando coordina ambos consigo mismo; orden recomendado: deploy primero, scaffold de notifs después, para que el scaffold ya pruebe contra el proxy correcto. |
| Lucas — US32 baja de vehículo | Franco — PR #221 ✅ | Ambos tocan `Shipment.belongs_to :vehicle` y la asociación con `Vehicle`. | Resuelto por el merge de #221; Lucas abre su PR contra `main`. |
| Matías — `FIX-BE-00001` | (ninguna) | Independiente. | Puede mergear día 1. |

## Fuera de alcance — diferido deliberadamente

- **Integración real con MercadoPago (`REQ-BE-00006`).** US8 ship con gateway mockeado por decisión de scope. **No es un "fase 1 — luego migramos"**: es la forma en que se entrega el MVP para la cátedra. El swap a un proveedor real, si llegara, es trabajo nuevo de otro sprint con su propio análisis.
- **US11 — filtrado de ofertas.** Estaba marcada en `cronograma.typ` para este sprint; se baja porque US10 (bandeja) todavía es carryover y filtrar sobre una bandeja que aún no mergeó no agrega valor demoable.
- **Consumidores específicos de notificaciones** (oferta recibida, estado de Shipment, pago confirmado). El scaffold de Fernando (b) deja la plomería; los consumidores se enganchan en sprints posteriores.
- **Hard delete / purge job para vehículos descartados.** US32 ship como soft delete (`discard`) y suficiente para el demo. No hay job de purga programado.
- **`tcorzo` — US de "marcar Recorrido" GMaps.** Diferida formalmente fuera de Sprint 3 con la Enmienda del 2026-05-25 (Tomás absorbe `REQ-BE-00035` y no le queda capacidad para escribir + implementar la US este sprint). US39 deja el placeholder del mapa indefinidamente hasta que la US aterrice en un sprint futuro.
- **Filtros / búsqueda / paginación en US17/US39.** Mid-sprint scope cut. El listado entrega una sola lista ordenada por `updated_at desc`; ver `REQ-FE-00022/23` para el alcance exacto. Filtros llegan en otro sprint si la demanda aparece.

## Definition of Done

Cada compromiso cierra cuando se cumple lo siguiente — es el contrato que evita PRs "casi listos":

1. Código mergeado a `main` vía PR aprobado, con `Closes #N` referenciando la issue.
2. CI en verde: RSpec, Vitest + Playwright (e2e cuando toca UI), `just lint`, `just build-artifacts` (cuando toca `docs/`).
3. Para cambios de frontend: corrida de las skills `/critique` → `/polish` → `/audit` (gate documentado en `CLAUDE.md` § "Pre-PR UI quality gate"). Findings intencionales se anotan en el body del PR.
4. Acceptance criteria de la US verificados por alguien distinto al autor durante el review.
5. Demoable end-to-end en el entorno desplegado.
6. Artifact o documentación afectada actualizada (USM, backlog-us, glossary) si el cambio toca un concepto del dominio.

## Riesgos

- **🚨 Capacity-add mid-sprint (día 4 de 7) — go/no-go del PM.** Se sumaron 4 commitments (US17 Carrier + Shipper, US39, endpoints BE de Envíos) tras la sesión de grilling de FSMs. Esto pasa de 1 a 2 streams para Matías, Lucas, Franco y Tomás. **Go/no-go al cierre del día 5 (2026-05-25)**: si dos o más add-ons no tienen PR abierto para ese momento, **diferir a Sprint 4** todos los add-ons FE (US17 Carrier, US17 Shipper, US39) y mantener solamente `REQ-BE-00035` (endpoints BE) en Sprint 3 como semilla para Sprint 4. Decisión final: Tomás (PM).
- **Dependencia en `REQ-BE-00033` (Brian) sigue en planificación.** US39 deriva el chip `payment.state` del listado de Payments de Brian. Si Brian no abre PR antes del día 6, US39 ship con el chip mockeado y AC14 (cancellation interlock) verificado por integración manual contra el endpoint cuando esté disponible. No bloquea el merge del FE.
- **ActionCable sobre SQLite bajo el proxy Kamal — primera vez en este stack.** El scaffold de Fernando (b) es el primer WS de producción del equipo. Riesgo de pasar más tiempo en infra de transporte que en producto. Mitigación: scope explícito a *scaffold* — un canal de prueba, un consumidor dummy, sin acoplar a una notificación real este sprint.
- **El gateway mockeado de US8 puede pintar deuda arquitectónica si no se diseña con interface clara.** Mitigación: Brian define un puerto (`PaymentGateway`) y la implementación mock vive detrás. La intención no es prepararse para "el día que migremos a MercadoPago" — es que el mock no se filtre como acoplamiento al modelo de `Payment`.
- **Carga heterogénea entre devs.** Post-enmienda 2026-05-25 los streams quedan: Matías, Lucas y Tomás con 2 ítems cada uno (Tomás concentra el par BE+FE de Envíos/US39); Franco con su carryover mergeado como único compromiso de Sprint 3; Brian con 1 ítem grande; Fernando con 2 ítems infra. La dependencia FE → BE ahora vive dentro de la rama de Tomás (BE primero, FE encima) y los add-ons de Matías/Lucas dependen de que Tomás abra el PR del BE en día 5-6 para que ellos arranquen contra el endpoint real o un contract mock.
- **`cronograma.typ` desalineado.** El cronograma planificado marca US7 y US11 para Sprint 3, pero US7 terminó en Sprint 2 y US11 se baja. Hay que actualizar `cronograma.typ` cuando se confirme el closing del sprint, no dentro de esta sesión.

## Referencias

- User stories: [`docs/artifacts/backlog-us.typ`](../artifacts/backlog-us.typ) (US4 línea 86, US5 línea 109, US8 línea 167, US10 línea 207, US12 línea 224, US17 + US39 reescritas en PR #231, US32 línea 500).
- Decisiones de FSM `Shipment` / `Payment` que originan los add-ons mid-sprint: PR #231 (sesión de grilling 2026-05-24).
- Issues nuevas (locales, sin GH): `REQ-BE-00035`, `REQ-FE-00022`, `REQ-FE-00023`, `REQ-FE-00024` — viven en branch `worktree-sprint3-us17-us39-fulfilment-ui` hasta el merge de PR #231.
- Cronograma planificado: [`docs/artifacts/cronograma.typ`](../artifacts/cronograma.typ).
- Glosario (fuente de verdad de términos): [`docs/05-appendices/glossary.md`](../05-appendices/glossary.md).
- Issues vivas: `.gdsi-sdlc/issues/{Ready,InProgress,Backlog}/` + `gh issue list --repo tcorzo/fiuba-gestion-tp`.
- Sprint 1 — Plan: [`SPRINT-1-PLAN.md`](SPRINT-1-PLAN.md) (estructura de referencia).
- Sprint 2 — Cierre: [`../sprints/sprint-02.md`](../sprints/sprint-02.md) y [`../progress-reports/sprint-2.md`](../progress-reports/sprint-2.md).
- Política de DB (SQLite forever) y de idioma (inglés en código, español en UI vía i18n): [`../../CLAUDE.md`](../../CLAUDE.md).
- Throughput / proyección: se corre la skill `team-performance` al cierre del sprint, no en planning.

## Mapping at a glance

```
Sprint 3 commitment (post-enmienda 2026-05-24)
├── Bugfix marketplace      ─▶ FIX-BE-00001  (#211)    (Matías)            ── desbloquea US4/US5
├── US8 Pago (mock)         ─▶ REQ-BE-00033  (#213)    (Brian)             ── arranca contra main
├── US10 + US12             ─▶ REQ-FE-00017 (#123)
│                              + REQ-BE-00024 (#104)   (Franco) — PR #221  ── ✅ mergeado 2026-05-24
├── Envíos index (BE)       ─▶ REQ-BE-00035  (local)   (Tomás)             ── base para US17/US39 (reasignado 2026-05-25)
├── US17 Carrier (FE)       ─▶ REQ-FE-00022  (local)   (Matías — add-on)   ── /carrier/shipments
├── US17 Shipper (FE)       ─▶ REQ-FE-00023  (local)   (Lucas  — add-on)   ── /shipper/shipments
├── US32 Baja de Vehículo   ─▶ REQ-BE-00034  (#215)    (Lucas)             ── soft delete (discard)
├── OIDC deploy automation  ─▶ INF-INFRA-00004 (#202)  (Fernando — a)      ── carryover de Sprint 2
├── Notif web scaffold      ─▶ INF-FE-00005  (#217)    (Fernando — b)      ── ActionCable + Solid Cable
└── US39 detalle de envío   ─▶ REQ-FE-00024  (local)   (Tomás — add-on)    ── /{carrier,shipper}/shipments/:id

(local) = issue file en .gdsi-sdlc/issues/Backlog/, sin issue en GH (decisión del PM mid-sprint).
```
