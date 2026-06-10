# Sprint 5 — Plan

- **Sprint:** 5
- **Ventana:** 2026-06-04 → 2026-06-10 (cadencia semanal jue → mié)
- **Equipo (6):** Brian Céspedes (`@bcespedes`), Fernando Yu (`@FernandoYu`), Franco Ricciardo (`@FrancoRicciardo`), Lucas Dondo (`@LucasDondo`), Matías Ferrero (`@matias-ferrero`), Tomás Corzo (`@tcorzo`).
- **PM/SM:** Tomás.

## Objetivo del sprint

> **Cerrar el MVP.** Las **tres últimas historias MVP** del backlog se entregan este sprint — US15 (Pago al Transportista), US51 (Mapa en Detalle de Envío) y US53 (Autocalculado de Distancia en Carga) — y con ellas el producto queda funcionalmente completo a nivel MVP. El resto del equipo consolida los entregables: refinamiento y verificación de artefactos (`backlog-us`, USM y demás `docs/artifacts/`), chequeos finales de despliegue (incluida la API key de Google Maps) y pulido final de UX/UI, de cara a la demo final del 2026-06-24.

Sprint 5 no abre superficie nueva: completa la terna MVP que quedaba (US15 cierra el ciclo de monetización iniciado por US8; US51 reemplaza el placeholder de mapa que dejó US39; US53 cierra el bucle geoespacial sobre la geocodificación de Sprint 4) y dedica la capacidad sobrante — el equipo arrancó sin carryovers de código — a dejar la documentación, el despliegue y la experiencia listos para la entrega. Verificado contra el backlog completo (US1–US60): tras este sprint **no queda ninguna historia MVP sin entregar**; todo el remanente es post-MVP.

## Compromisos por integrante

| Integrante | TAG (gh #) | Trabajo | Tipo | Carryover |
|---|---|---|---|---|
| **Franco** (`@FrancoRicciardo`) | `REQ-BE-00046` (local) | US15 — Pago al Transportista (Alta). **Fullstack.** Liquidación del pago al Transportista una vez que el Shipment pasa a `delivered`; reutiliza el puerto `PaymentGateway` mockeado de US8. BE: modelo/estado de payout + endpoint de listado de pagos recibidos del Transportista. FE: detalle de cada pago (monto, envío asociado, fecha) y aviso ante fallo de transferencia (engancha al sistema de notificaciones de US57/US58). | Feature | No |
| **Matías** (`@matias-ferrero`) | `REQ-BE-00047` (local) | US53 — Autocalculado de Distancia en Carga (Media). **Fullstack.** Migración `route_length_km` en `cargos`; servicio Google Maps **Directions** server-side (la "downstream integration" que ya anticipa `app/models/route.rb`); refactor del cálculo de costo en `CargoOffer` para derivarlo de `cargo.route_length_km` y **eliminar el input manual `estimated_km`**; FE del form de oferta (sin input de km, muestra distancia calculada + precio). | Feature | No |
| **Fernando** (`@FernandoYu`) | `REQ-FE-00028` (#242) | US51 — Mapa en Detalle de Envío (Media). `<ShipmentMap />` (mapa estático con pin de origen/destino, `fitBounds`) + `<OpenInGmapsButton />` (deep-links), reutilizando `getGoogleMapsLoader` (`frontend/src/lib/gmaps.ts`). **Además — Infra:** chequeos finales de despliegue, incluida la provisión de la API key de Google Maps (server-side para Directions de US53 + `VITE_GOOGLE_MAPS_API_KEY` en el build del frontend). | Feature + Infra | Sí — US51 fue el diferido explícito de Sprint 4 a Sprint 5 |
| **Matías + Franco** | (consolidación, sin issue) | Refinamiento y verificación de [`docs/artifacts/backlog-us.typ`](../artifacts/backlog-us.typ) (+ los per-US bajo `backlog-us/`) y del User Story Map [`docs/artifacts/usm.typ`](../artifacts/usm.typ): reconciliar estados reales vs. lo planificado, reflejar el MVP completo. | Docs | — |
| **Brian + Lucas** (`@bcespedes`, `@LucasDondo`) | (consolidación, sin issue) | Refinamiento y verificación del resto de `docs/artifacts/` (`features`, `cost-report`, `riesgos`, `personas`, `product-vision`, `wbs`, `es-no-es-hace-no-hace`, `comunicaciones`): consistencia con el estado final del MVP. | Docs | — |
| **Tomás** (`@tcorzo`) | (pulido, sin issue) | Pulido final de UX/UI sobre las pantallas del MVP — corrida del gate `/critique` → `/polish` → `/audit` (CLAUDE.md § "Pre-PR UI quality gate"). + rol PM/SM. | Polish | — |

## Carryovers (lo que NO es trabajo nuevo)

- **Ninguno de código.** Sprint 4 cerró limpio (`in_progress: []`); no hubo PRs de feature en vuelo al inicio de Sprint 5. Es un arranque sin deuda de sprint anterior — inusual respecto de sprints previos.
- Únicos PRs abiertos al inicio: el favicon de Fernando (#313) y dependabot (#201, #228, #291–294) — el PM los mergea si pasan CI; no son trabajo del sprint.

## Dependencias entre tareas

| Origen | Destino | Naturaleza | Acción |
|---|---|---|---|
| Fernando — API key de Google Maps (server-side) | Matías — US53 servicio Directions | El cálculo de `route_length_km` necesita la API key de Directions provista en el entorno backend. | Fernando provisiona la key temprano. Matías desarrolla contra un cliente Directions **mockeado** (mismo patrón que el mock de `@googlemaps/js-api-loader` en los tests del AddressPicker) hasta que la key esté disponible — no bloquea el arranque. |
| Fernando — `VITE_GOOGLE_MAPS_API_KEY` en build | Fernando — US51 mapa | El mapa estático usa el loader del frontend, que lee esa env var (ya en uso por el AddressPicker desde US48/49). | Auto-coordinación: la key del frontend ya existe en dev; Fernando confirma su presencia en el build de despliegue como parte de los chequeos. |
| Matías — US53 BE (`route_length_km` + costo en `CargoOffer`) | Matías — US53 FE (form de oferta) | El form deja de pedir km y muestra distancia+precio derivados del backend. | Mismo dueño; secuencia BE → FE en su propia rama. |
| Franco/Matías/Fernando — features FE | Tomás — pulido de UX/UI | El pulido corre sobre pantallas que tienen que existir primero. | Trabajo de fin de sprint; Tomás corre el gate `/critique`→`/polish`→`/audit` a medida que cada pantalla aterriza. |
| Features de US15/US51/US53 | Refinamiento de artefactos (Matías+Franco, Brian+Lucas) | La verificación de `backlog-us`/USM/artefactos refleja el estado final del MVP. | Puede arrancar con el estado actual y finalizar al cierre, una vez mergeadas las tres features. |

## Fuera de alcance — diferido deliberadamente

- **Todo el remanente del backlog es post-MVP.** Tras US15/US51/US53 no queda historia MVP pendiente. Quedan fuera, como backlog post-MVP (no como "fase pendiente" ni deuda de migración): **US5** (filtrar ventanas), **US11** (filtrado de ofertas), **US13** (realizar envío / navegación GPS), **US16** (cambiar contraseña), **US21** (tracking de envío), **US22** (verificación por email), **US23** (envíos compuestos), **US24** (encadenado de pedidos), **US25** (gestión de seguros), **US28/US29** (editar/eliminar reseña de Transportista), **US55/US56** (editar/eliminar reseña de Expedidor).
- **Integración real con Mercado Pago (AC1 de US15).** US15 entrega con el **gateway mockeado** detrás del puerto `PaymentGateway`, igual que US8. No es un "fase 1 → luego migramos": es la forma en que se entrega el MVP para la cátedra. Un proveedor real, si llegara, es trabajo nuevo con su propio análisis.
- **Verificación por email / infraestructura de correo (US22).** Sigue fuera, como en todos los sprints anteriores. El aviso de fallo de transferencia de US15 (AC4) se resuelve sobre el sistema de notificaciones en tiempo real ya entregado (US57/US58), no por email.
- **Caché / rate-limit fino de las llamadas a Directions.** US53 hace la llamada en la creación de la Carga y persiste el resultado; optimizaciones de costo de API quedan fuera salvo que el volumen lo justifique.

## Definition of Done

Cada compromiso cierra cuando se cumple lo siguiente — es el contrato que evita PRs "casi listos":

1. Código mergeado a `main` vía PR aprobado, con `Closes #N` referenciando la issue.
2. CI en verde: RSpec, Vitest + Playwright (e2e cuando toca UI), `just lint`, `just build-artifacts` (cuando toca `docs/`).
3. Para cambios de frontend: corrida de las skills `/critique` → `/polish` → `/audit` (gate documentado en `CLAUDE.md` § "Pre-PR UI quality gate"). Findings intencionales se anotan en el body del PR.
4. Acceptance criteria de la US verificados por alguien distinto al autor durante el review.
5. Demoable end-to-end en el entorno desplegado.
6. Artifact o documentación afectada actualizada (USM, backlog-us, glossary) si el cambio toca un concepto del dominio.

## Riesgos

- **🚨 US15 es la única historia de prioridad Alta y cierra el ciclo de dinero — Franco fullstack en solitario.** Si se atrasa, el MVP no queda cerrado. **Mitigación**: reutiliza el puerto `PaymentGateway` mockeado de US8 (patrón conocido), así que el riesgo es de alcance FE/estado de payout, no de integración de pagos. El PM toma la review temprano.
- **La API key de Google Maps es dependencia compartida de US51 (build) y US53 (Directions server-side).** Si el trabajo de despliegue de Fernando se atrasa, ambas features podrían quedar a la espera. **Mitigación**: Matías desarrolla US53 contra un cliente Directions mockeado y US51 corre con la key de dev existente; la provisión en el entorno desplegado es un chequeo de Fernando, no un bloqueante de desarrollo.
- **US53 toca el camino de costo de la oferta (elimina `estimated_km` manual).** Riesgo de romper la creación de ofertas / el cálculo de monto existente. **Mitigación**: se conserva la derivación de `amount_cents`, sólo cambia la fuente del dato (de input manual a `cargo.route_length_km`); cubrir con specs de `CargoOffer`.
- **La consolidación de docs puede leerse como relleno.** Cuatro personas en refinamiento/verificación de artefactos. **Mitigación**: es verificación contra el estado final del MVP y es entregable de cátedra para la demo del 24/06, no busywork — cada par firma qué artefacto revisó.
- **`cronograma.typ` desalineado.** Marca US17/US18/US19 para Sprint 5, pero las tres ya se entregaron en sprints anteriores; el equipo va adelantado al plan. Hay que actualizarlo al confirmar el cierre del sprint, no en esta sesión — entra dentro del refinamiento de artefactos.

## Referencias

- User stories: [`docs/artifacts/backlog-us.typ`](../artifacts/backlog-us.typ) — US15 (`backlog-us/US015.typ`, Pago al Transportista, Alta), US51 (`US051.typ`, Mapa en Detalle de Envío), US53 (`US053.typ`, Autocalculado de Distancia en Carga). Todas `Release: MVP`.
- US51 — issue + plan: `.gdsi-sdlc/issues/Ready/REQ-FE-00028-us51-mapa-enlaces-gmaps-detalle-envio.issue.md` (#242).
- Integración Directions anticipada: `backend/app/models/route.rb`; Haversine existente: `backend/lib/truckr/geo.rb`; loader FE: `frontend/src/lib/gmaps.ts`.
- User Story Map: [`docs/artifacts/usm.typ`](../artifacts/usm.typ).
- Cronograma planificado (desalineado, a actualizar al cierre): [`docs/artifacts/cronograma.typ`](../artifacts/cronograma.typ).
- Glosario (fuente de verdad de términos): [`docs/05-appendices/glossary.md`](../05-appendices/glossary.md).
- Issues vivas: `.gdsi-sdlc/issues/{Ready,InProgress,Backlog}/` + `gh issue list --repo tcorzo/fiuba-gestion-tp`.
- Sprint 4 — Plan: [`SPRINT-4-PLAN.md`](SPRINT-4-PLAN.md) (estructura de referencia).
- Sprint 4 — Cierre: [`../progress-reports/sprint-04.md`](../progress-reports/sprint-04.md).
- Política de DB (SQLite forever) y de idioma (inglés en código, español en UI vía i18n): [`../../CLAUDE.md`](../../CLAUDE.md).
- Throughput / proyección: se corre la skill `team-performance` al cierre del sprint, no en planning.

## Mapping at a glance

```
Sprint 5 commitment — cierre del MVP (últimas 3 historias MVP)
├── US15 Pago al Transportista   ─▶ REQ-BE-00046 (local)  (Franco)   ── fullstack, gateway mockeado (reusa US8)
├── US53 Autocalc. Distancia     ─▶ REQ-BE-00047 (local)  (Matías)   ── fullstack, GMaps Directions + quita estimated_km
└── US51 Mapa en Detalle Envío   ─▶ REQ-FE-00028 (#242)   (Fernando) ── diferido de Sprint 4; + API key + deploy checks

Consolidación (sin issue — entregable de demo 24/06)
├── backlog-us + USM refinement/verificación              (Matías + Franco)
├── resto de docs/artifacts refinement/verificación       (Brian + Lucas)
└── pulido final de UX/UI (/critique → /polish → /audit)   (Tomás, PM/SM)

Post-MVP (fuera de alcance — todo el remanente)
└── US5, US11, US13, US16, US21, US22, US23, US24, US25, US28, US29, US55, US56
```
