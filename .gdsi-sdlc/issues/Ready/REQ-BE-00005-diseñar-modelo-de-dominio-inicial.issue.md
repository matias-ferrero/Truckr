---
tag: REQ-BE-00005
title: Diseñar modelo de dominio inicial (Identity bounded context primero)
priority: P1
status: ready
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/72
author: Claude Code
github_issue: 72
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrrNLA
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-03T16:15:50.686278+00:00Z
labels:
- BE
- REQ
- domain-model
- identity
plan: docs/features/REQ/REQ-BE-00005/REQ-BE-00005-disenar-modelo-de-dominio-inicial.plan.md
---

## Summary

Producir el **draft del modelo de dominio** que va a guiar la primera fase de implementación del backend Rails. El entregable es un documento de diseño (más diagramas ERD) que cubra los cuatro bounded contexts del producto a nivel conceptual y deje listo para implementar el contexto **Identity** (`User`, `Carrier`, `Shipper`, `Vehicle`) — la siguiente prioridad del roadmap. Esto desbloquea las primeras migraciones, los primeros modelos AR y el primer endpoint real (`Api::QuoteRequestsController`).

> **Convención de naming (regla dura del proyecto)**: modelos, tablas y columnas son **siempre en inglés**, sin excepciones por "lenguaje ubicuo". Las personas del producto se traducen para los identificadores: `Transportista` ↔ `Carrier`; `Expedidor` ↔ `Shipper`. El español queda exclusivamente para artifacts del producto (`docs/artifacts/*.typ`), títulos de issues, copy de UI y prosa narrativa que se refiere a la persona (no al identificador).
>
> **Source of truth de los términos**: `docs/05-appendices/glossary.md`. Cualquier nuevo término se agrega ahí PRIMERO; el resto (artifacts, código, docs, onboarding) tiene que ser consistente con el glosario. Drift entre glosario y otros docs cuenta como defecto.

## Problem Statement

Hoy `backend/app/models/` contiene únicamente `ApplicationRecord`. No hay migraciones, no hay esquema, y los artefactos de planificación (USM, personas, features) describen el dominio a nivel de producto pero **no a nivel de modelo persistido**. Antes de empezar a tipear migraciones hay que tomar varias decisiones cruzadas que, si se difieren, generan retrabajo:

- Cómo se relacionan `User`, `Carrier` y `Shipper` (¿STI? ¿tablas separadas con FK a `users`? ¿roles?). Un mismo human podría operar como ambos.
- Estrategia de PKs (bigint default vs UUID) — afecta a todas las tablas y al diseño de URLs públicas.
- Multi-tenant / scoping: ¿un `Carrier` posee `Vehicle`s directamente, o vía empresa intermedia?
- Soft-delete vs hard-delete (afecta queries, índices únicos, reportes ARCA).
- Timestamps + auditing: ¿`created_at`/`updated_at` solo, o `paper_trail`-style?
- Estados/state machines: en particular `Shipment` (`draft → quoted → accepted → in_transit → delivered → settled`, branch `cancelled`).
- Concerns geográficos: ubicaciones (origen/destino, posición de tracking) — texto libre, lat/lng en columnas, o PostGIS. Decisión grande, ligada a ADR pendiente.
- **Mapping persona → modelo**: el doc de diseño debe incluir una tabla explícita Spanish-persona ↔ English-model (`Transportista` ↔ `Carrier`, `Expedidor` ↔ `Shipper`) para que los artifacts del producto y el código se referencien sin ambigüedad.

Sin un draft acordado, cada migración que se mergee va a tener que volverse a tocar.

## Expected Behavior

El issue se considera resuelto cuando existe un **documento de diseño revisable** (markdown + PlantUML) con el suficiente detalle para que el siguiente issue (implementación de la primera migración Identity) sea ejecutable sin tener que tomar decisiones de modelado.

Concretamente:

1. **Documento de diseño** en `docs/02-high-level-design/domain-model.md` (o sección nueva en `high-level-design.md`) que cubra los cuatro bounded contexts a nivel **conceptual** (entidades, atributos clave, cardinalidades, invariantes):
   - Identity: `User`, `Carrier`, `Shipper`, `Vehicle`.
   - Marketplace: `TransportWindow`, `CargoOffer`, `Match`/`Quote`.
   - Fulfilment: `Shipment` (con state machine), `TrackingEvent`, `Route`.
   - Commerce: `Payment` (escrow), `InsurancePolicy`, `ArcaInvoice`.
2. **Spec detallado del contexto Identity** (nivel "ready-to-migrate"): tipo de columnas, índices, FKs, unique constraints, validaciones AR, naming **en inglés** (modelos/tablas/columnas), comentarios donde haya invariantes no obvias.
3. **Diagramas ERD** en PlantUML bajo `docs/04-database-diagrams/`:
   - `erd-identity.puml` (detallado, ya existe como draft — actualizar para usar `carriers`/`shippers` en lugar de `transportistas`/`clientes`).
   - `erd-overview.puml` (los cuatro contextos relacionados, alto nivel).
4. **ADRs** para las decisiones cruzadas (una por decisión, dentro de `docs/01-technical-vision/` siguiendo el formato existente):
   - PK strategy (bigint vs UUID).
   - User ↔ Carrier/Shipper (STI vs separated vs role-based).
   - Soft-delete vs hard-delete.
   - Geo storage (lat/lng en columnas vs PostGIS) — ya está como "Decisión Diferida" en `01-technical-vision/`; este issue debe **proponer la decisión inicial** (probablemente lat/lng en columnas para Phase 0/1, PostGIS diferido a Phase 2).
5. **Glosario como source of truth**: extender `docs/05-appendices/glossary.md` con (a) una columna **English model / table** en cada entry de "Domain Terms" cuando aplique, (b) renombrado canónico `Cliente`/`Productor` → **`Expedidor`** (con `Productor` documentado como sub-persona/sinónimo si se quiere preservar), (c) una nota explícita "Source of truth — change here first" al inicio del documento, (d) link desde `CLAUDE.md` y desde `docs/onboarding/00-philosophy-and-architecture.md` para que cualquier sesión nueva lo descubra.
6. **Auditoría de consistencia con el glosario**: barrer todos los docs y artifacts referenciando los términos viejos y actualizar en consecuencia. Específicamente:
   - `docs/artifacts/*.typ` (USM, personas, features, backlog-us, …): usar `Expedidor` en lugar de `Cliente`/`Productor` cuando se hable de la persona.
   - `docs/01-` … `docs/05-` (tech docs y onboarding): idem.
   - `docs/04-database-diagrams/*.puml`: identificadores en inglés (`carriers`, `shippers`, etc.).
   - `frontend/.impeccable.md`, copy de UI en `App.tsx` / landing data: usar `Expedidor` en copy es-AR.
   - El `grep -niE '(\\bcliente\\b|\\bproductor\\b)' docs/ frontend/src/ backend/` no debe arrojar matches relacionados con la persona del producto (sí pueden quedar coincidencias incidentales tipo "cliente fiscal" en contexto ARCA, "clientes externos" como sinónimo genérico, etc., pero documentarlas).
7. **Tabla de mapping persona ↔ modelo**: incluida en `domain-model.md`, derivada del glosario (no inventar mapeos por fuera del glosario).
8. **Tabla de mapping bounded-context ↔ módulos Rails** que indique cómo se va a organizar `backend/app/models/` (¿namespace por contexto? ¿flat con prefijo?). Decisión registrada en el documento.
9. **Update del USM / backlog** marcando explícitamente qué US del USM están cubiertas por cada modelo (no agregar US nuevas, solo cross-reference).

## Current Behavior

- `backend/app/models/` solo tiene `ApplicationRecord`.
- `backend/db/migrate/` está vacío.
- `docs/04-database-diagrams/` existe pero los `.puml` referenciados (`erd-identity`, etc.) o no están escritos o están como stubs.
- `docs/02-high-level-design/high-level-design.md` describe patrones pero no entidades persistidas con sus atributos.
- Las "Decisiones Diferidas" (PK strategy, geospatial) no tienen ADR.

## Reproduction Steps

N/A — feature/design request, no es bug.

## Impact

- **Equipo backend**: desbloquea las primeras migraciones e implementación del `Api::QuoteRequestsController`. Sin esto, cualquier intento de tipear migraciones es prematuro.
- **Equipo frontend**: una vez que existan los shapes JSON canónicos derivados del modelo, el form de cotización puede tipar sus payloads sin adivinar.
- **Documentación académica**: cierra una brecha visible en el reporte (los ERDs prometidos en `docs/04-database-diagrams/`).
- **AI harness**: el draft del modelo es entrada directa para el futuro skill `backend/.agents/skills/rails-model/` y `migration/`.
- **Riesgo si se omite**: cada migración subsecuente toma decisiones de modelado ad-hoc → retrabajo y schema thrash en una etapa donde **no hay datos** que migrar (= ahora es el momento de fallar barato).

## Technical Notes

- **Naming (regla dura)**: TODOS los identificadores de modelo, tabla y columna en inglés. Sin excepciones por "lenguaje ubicuo". Mapping persona → modelo: `Transportista` → `Carrier`, `Expedidor` → `Shipper`. Lista completa de modelos planeados: `User`, `Carrier`, `Shipper`, `Vehicle`, `TransportWindow`, `CargoOffer`, `Quote`, `Shipment`, `TrackingEvent`, `Route`, `Payment`, `InsurancePolicy`, `ArcaInvoice`. Spanish queda solo en artifacts del producto, títulos de issues, copy de UI y prosa narrativa que cita la persona (no el identificador).
- **Stack**: Rails 8.1 + SQLite (Phase 0/1) + Solid* stack. Cualquier feature SQL específico de Postgres (citext, partial indexes complejos, JSONB-heavy) debe declararse explícitamente como "requerirá Postgres" para alinearse con la "Decisión Diferida" de DB.
- **Phase awareness**: el draft debe tomar decisiones que **no comprometan** la migración futura SQLite → Postgres (Phase 1) ni la introducción de PostGIS (Phase 2). Ejemplo: usar `text` para enums de estado en SQLite y prever conversión a tipo nativo en Postgres.
- **State machines**: `Shipment` es el único entity con FSM no trivial (`draft → quoted → accepted → in_transit → delivered → settled` + `cancelled`). Cada transición emite `TrackingEvent`. Documentar transiciones permitidas y guards. Decidir si se usa una gem (`aasm`, `state_machines`) o se modela a mano — recomendado: a mano hasta que duela, registrar la decisión.
- **Auth boundary**: aunque el roadmap marca "auth = no aún", el diseño de `User` debe **prever** `password_digest` (`has_secure_password`) y la separación AdminUser ↔ User (ver `INF-BE-00003` ActiveAdmin que crea un `AdminUser` Devise-based para `/admin`). Decidir si conviven sin colisionar.
- **ARCA (AFIP)**: la facturación electrónica argentina (`ArcaInvoice`) impone restricciones sobre identificación fiscal del cliente y comprobantes. Solo dejar el slot conceptual; la integración real es trabajo posterior.
- **No implementar nada todavía**: este issue es **diseño**, no código de producción. Crear migraciones queda para el issue siguiente (Identity migration). Sí se permite código exploratorio en una rama scratch para validar nombres/relaciones, pero no se mergea.

## Origin

Manual — solicitado por el owner: "Draft a domain model for the initial implementation".

Alineado con el roadmap (`docs/onboarding/06-roadmap.md` § Priority Work, item #1: "First domain model — Identity bounded context").

## Related

- Roadmap doc: `docs/onboarding/06-roadmap.md` (Priority Work #1).
- HLD: `docs/02-high-level-design/high-level-design.md` (sección "Domain Model" a expandir).
- DB diagrams: `docs/04-database-diagrams/` (ERDs nuevos).
- Tech vision: `docs/01-technical-vision/technical-vision.md` (ADRs nuevos).
- Artifacts ya existentes que sirven como input (siguen en español; este issue NO los modifica):
  - `docs/artifacts/usm.typ` — User Story Map.
  - `docs/artifacts/personas.typ` — perfiles de Transportista / Expedidor (personas en español; mapean a `Carrier` / `Shipper` en código). Hoy referencia `Cliente`/`Productor`; este issue lo actualiza.
  - `docs/artifacts/features.typ` — matriz feature × persona.
- Issue dependiente (futuro, no crear todavía): primera migración Identity — bloqueado por este issue.
- Issue relacionado: `INF-BE-00003` (ActiveAdmin) — toca `AdminUser`; el diseño de `User` debe coexistir limpio con `AdminUser`.
- Skill candidato (futuro): `backend/.agents/skills/rails-model/`, `backend/.agents/skills/migration/` — outputs de este issue son inputs naturales.

## Acceptance Criteria

- [ ] Existe `docs/02-high-level-design/domain-model.md` (o sección expandida en `high-level-design.md`) cubriendo los cuatro bounded contexts a nivel conceptual con entidades, atributos principales, cardinalidades e invariantes.
- [ ] El bounded context **Identity** está especificado a nivel "ready-to-migrate": tipo de cada columna, índices, FKs, unique constraints, validaciones AR esperadas, namespace de modelos.
- [ ] `docs/04-database-diagrams/erd-identity.puml` existe, compila, y refleja el spec del paso anterior.
- [ ] `docs/04-database-diagrams/erd-overview.puml` existe y muestra los cuatro contextos relacionados a alto nivel.
- [ ] Una ADR por cada decisión cruzada bajo `docs/01-technical-vision/` (PK strategy, User↔Carrier/Shipper, soft-delete, geo storage). Formato ADR consistente con los existentes (ADR-001…ADR-006).
- [ ] La state machine de `Shipment` está documentada explícitamente (transiciones permitidas, guards, side effects = `TrackingEvent` + payment release en `settled`).
- [ ] Cross-reference USM/backlog ↔ entidades del modelo agregada al documento de diseño (qué entidades cubren qué US, sin agregar US nuevas).
- [ ] `docs/05-appendices/glossary.md` actualizado: declara explícitamente "Source of truth"; incluye columna English-model / table en Domain Terms; entrada `Expedidor` reemplaza `Cliente` (con `Productor` referenciado como sinónimo o sub-persona).
- [ ] `CLAUDE.md` y `docs/onboarding/00-philosophy-and-architecture.md` linkean al glosario y mencionan que es el source of truth.
- [ ] Tabla de mapping persona ↔ modelo (`Transportista`→`Carrier`, `Expedidor`→`Shipper`, etc.) incluida en `domain-model.md`, derivada del glosario.
- [ ] Auditoría de consistencia ejecutada: `grep -niE '(\bcliente\b|\bproductor\b)' docs/ frontend/src/ backend/` revisado — toda ocurrencia con sentido de persona del producto reemplazada por `Expedidor` (excepciones documentadas en su contexto).
- [ ] `docs/artifacts/*.typ` actualizados (`personas.typ`, `usm.typ`, `features.typ`, `backlog-us.typ`, etc.) para usar `Expedidor` donde corresponda.
- [ ] Decisión sobre coexistencia `User` ↔ `AdminUser` (ActiveAdmin/Devise) explícita en el documento.
- [ ] Naming pasa el filtro: TODOS los identificadores de modelo/tabla/columna en inglés. Cero rastros de `Transportista`/`Cliente`/`Productor`/`Expedidor` (u otros términos en español) como nombres de modelo, tabla o columna en los ERDs y en el spec.
- [ ] No se agrega código a `backend/app/models/` ni migraciones en este issue.
- [ ] `docs/features/ISSUES-INDEX.md` y `docs/onboarding/06-roadmap.md` actualizados para reflejar el cierre del slot "domain model draft".
- [ ] Conventional Commit del trabajo: `docs(domain): draft initial domain model and identity context spec` (o similar `docs(...)` / `feat(docs): ...`).
