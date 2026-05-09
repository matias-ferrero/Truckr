# Sprint 1 Planning — Truckr

**Fecha:** 2026-05-03 · 20:00 (ARG) · 105 min
**Facilitador:** Tomás (PM/SM)
**Asistentes esperados:** 6 integrantes
**Sprint 1:** 2026-05-07 → 2026-05-13 (semanal, jue→mié)
**Defensa Sprint 1:** 2026-05-13 (remota)

> Nota previa: Doc Sprint 4 cierra **2026-05-06** — riesgos, comunicaciones y costos deben quedar firmes antes de esa fecha. Esta planning ya planifica el primer sprint de **dev**.

---

## 0. Apertura (5 min)

- Confirmar asistentes y quorum.
- Recordatorio: cadencia semanal, demos los miércoles, expo final 2026-06-24.
- Esta es nuestra **primera planning real** — vamos a tomar varias decisiones de proceso, no solo de scope.

## 1. Definition of Done & Definition of Ready (15 min) — DECISIÓN

**Por qué está acá:** ninguna de las dos existe (`docs/prompts/chat-2026_03_30-21_53_38.typ` lo confirma). La cátedra las espera.

Propuesta a discutir:

**DoR** (para que un issue pueda entrar al sprint):
- US con formato `Como X quiero Y para Z` y AC numerados.
- Estimación por throughput: cabe en ≤ 1 día de un dev (si no, partir).
- Sin bloqueantes externos pendientes.
- Plan de implementación o aceptación clara.

**DoD** (para mover a Done):
- Código mergeado a `main` vía PR aprobado.
- CI en verde (lint + tests donde aplique).
- AC verificados por alguien distinto al autor.
- Documentación/artifact actualizado si corresponde.
- Demoable.

**Output:** decisión registrada (commit en `docs/`).

## 2. Capacidad del sprint (10 min)

- Cada integrante: horas disponibles 2026-05-07 → 2026-05-13.
- Identificar parciales/finales/feriados de la semana.
- Calcular capacidad agregada (estimada vs. ideal de **6–12 historias/sprint** según `docs/artifacts/cost-report.typ`).

**Output:** capacidad total del equipo en horas y rango razonable de items a comprometer.

## 3. Definir epic owners (10 min) — DECISIÓN

5 epics, 6 personas. Asignación inexistente hoy.

| Epic | Descripción | Owner propuesto |
|---|---|---|
| Gestión de Cuentas | Identity bounded context, registro/login, perfiles, vehículos | _por asignar_ |
| Plataformas | Marketplaces dual Carrier/Shipper | _por asignar_ |
| Integraciones | ARCA, pagos, Google Maps | _por asignar_ |
| Seguro | Cotización + póliza + cobro | _por asignar_ |
| Gestión del Proyecto | Throughput, riesgos, comms, reporting | Tomás (PM) |

Owner ≠ único trabajador del epic; es punto de contacto y responsable de DoR.

## 4. Estado del board y candidatos (15 min)

**Snapshot 2026-05-03:** 30 issues — 21 Done · 3 InReview · 1 Ready · 5 Backlog.

**Cerrar primero (InReview, ya planificados):**
- `INF-BE-00003` — ActiveAdmin (mergear).
- `INF-GEN-00001` — Proyecciones por throughput.
- `REQ-DOC-00002` — Metodología de riesgos.

**Listo para arrancar:**
- `REQ-BE-00005` (**P1, Ready**) — Diseño de modelo de dominio (Identity bounded context). **Bloquea todo el backend.** Debe arrancar día 1 del sprint.

**Backlog candidatos (P2, sin plan aún):**
- `INF-INFRA-00001` — Centralizar workflows CI en raíz del repo.
- `INF-INFRA-00002` — Frontend CI (Vitest + Playwright). Depende de 00001.
- `INF-BE-00001` — Reestructurar FE por funcionalidades.
- `INF-FE-00001` — Cierre de artifacts.
- `REQ-FE-00002` — Cronograma básico con hitos.

## 5. Refinamiento del backlog — estrategia (15 min) — DECISIÓN

**Por qué está acá:** las US de `docs/artifacts/backlog-us.typ` son el _qué_ del producto, pero **no son backlog accionable**. Hoy:

- **26 US** distribuidas en **6 epics del USM** (Cuenta · Gestión de Viajes · Aceptar Viaje · Ver Transportistas · Reservar Transportista · Después del Viaje).
- **15 MVP / 6 Post-MVP / 5 Release 3.**
- Las 30 issues actuales (`INF-*`, `REQ-*`) son de infraestructura y proceso; **ninguna mapea 1:1 a una US**. El backlog de features está vacío como issues.
- **7 US claramente "gordas"** (6 AC c/u, son 3–4 tickets disfrazados): **US4, US5, US7, US8, US9, US11, US14**.

**Decisiones a cerrar esta noche:**

1. **Convención de splitting:** una US grande se rompe en N issues `REQ-BE-*` / `REQ-FE-*` con AC subset. La US queda como "epic-ito" trazable; los issues son la unidad de trabajo.
2. **Naming/labels:** mapeo US → issues (¿label `us:US7`? ¿prefix?). Para que el board siga siendo navegable.
3. **Quién refina qué:** asignar las 6 epics del USM a refinadores (típicamente el epic owner de la sección 3). Cada refinador trabaja sus US antes de la sesión dedicada.
4. **Sesión dedicada de refinamiento:** agendar una _backlog refinement_ de ~2 hs entre 2026-05-08 y 2026-05-11 (durante Sprint 1) para producir los issues. **No se hace acá esta noche** — son demasiadas US.
5. **Definition of Ready aplica:** ningún issue derivado entra a Sprint 2 si no cumple la DoR de la sección 1.

**Output:** convención escrita, owners por epic, fecha y hora de la sesión de refinamiento, deadline para tener el backlog refinado (proponer **lunes 2026-05-11 EOD**, así Sprint 2 planning lo encuentra listo).

> Nota: Sprint 1 **no consume US** (su goal es dominio + CI), así que el refinamiento puede correr en paralelo sin bloquear el sprint actual.

## 6. Sprint Goal (10 min) — DECISIÓN

Propuesta:

> **"Cerrar el modelo de dominio (Identity) y dejar el pipeline de CI completo (back + front) para que el resto del equipo pueda mergear con confianza desde el sprint 2."**

Justificación: combina la única P1 Ready (`REQ-BE-00005`) con el bloqueante de infraestructura (`INF-INFRA-00001/00002`, FE-CI no existe hoy). Cualquier feature posterior depende de ambos.

Discutir alternativas y cerrar **un** sprint goal en una oración.

## 7. Compromiso del sprint (15 min)

Cruzar capacidad (sección 2) contra candidatos (sección 4). Lista propuesta para comprometer:

1. Mergear los 3 InReview (≈ 0.5 día equipo).
2. `REQ-BE-00005` — modelo de dominio (P1).
3. `INF-INFRA-00001` — centralizar CI.
4. `INF-INFRA-00002` — frontend CI.
5. (Stretch) `INF-BE-00001` — reestructura FE si entra en capacidad.

Asignar dueño por item. Lo que no entra → queda en Backlog priorizado.

## 8. Riesgos y decisiones diferidas (10 min)

Bloqueante duro:
- **Frontend CI inexistente** — sin esto no validamos PRs de front. Va al sprint sí o sí.

Decisiones arquitectónicas pendientes (no bloquean Sprint 1, pero no podemos llegar a Sprint 2 sin ellas):
- **Estrategia mobile:** PWA vs. React Native.
- **Geoespacial:** PostGIS vs. proveedor externo (Google Maps / OSRM / HERE).
- **Auth/Authz:** scheme y librería (Devise? rodauth? JWT?).
- **DB de producción:** confirmar PostgreSQL.

**Acción:** designar dueños de spike para cada decisión, deadline mid-Sprint 1 (lunes 2026-05-11).

Dependencias a vigilar:
- `REQ-DOC-00001` (Pagos/GPS) y `REQ-DOC-00003` (USM seguro+GPS) deben alimentar el modelo de dominio antes de migraciones definitivas.

## 9. Logística de ceremonias (5 min)

- **Daily:** 2–3 veces/semana, async preferido, máx 15 min (ya definido en `docs/artifacts/comunicaciones.typ`).
- Confirmar canal y horario.
- **Review:** miércoles 2026-05-13 (junto a la defensa).
- **Retro:** quincenal — primera retro al cierre de Sprint 2.
- Confirmar herramienta de tracking (GitHub Projects v2 vía c9y-sdlc).

## 10. Cierre (5 min)

- Recap del sprint goal.
- Recap de items comprometidos + dueños.
- Recap de action items fuera del sprint (DoD/DoR redactadas, spikes de decisión).
- Próxima planning: 2026-05-13 post-review.

---

## Anexo — Datos de la investigación

**Equipo (6):** Tomás Corzo (PM), Brian Céspedes, Fernando Yu, Franco Ricciardo Calderaro, Matias Ferrero, +1.

**Estimación:** throughput-based (sin story points). Target 6–12 historias/sprint. Monte Carlo bootstrapping desde sprint 3–5 (`docs/artifacts/cost-report.typ`).

**User stories:** formato `Como X quiero Y para Z`, AC numerados, 3 C's + INVEST (`docs/artifacts/backlog-us.typ`).

**Naming hard rule:** modelos/tablas/columnas en inglés (`Carrier`, `Shipper`); español solo en docs. Glossary: `docs/05-appendices/glossary.md`.

**Infra:**
- Backend: Rails 8.1 scaffolded, sin modelos. CI corre en `backend/.github/workflows/ci.yml`.
- Frontend: React + Vite + Deno scaffolded, landing estático. **Sin CI.**
- Root: solo `release-please.yml`.

**Calendario académico:**
- Doc Sprint 4 cierra: 2026-05-06.
- Dev Sprints: 7 semanales (2026-05-07 → 2026-06-24).
- Parcialitos: sprints 1–4.
- Expo final: 2026-06-24, 17:00–21:00 presencial.
