# REQ-DOC-00002: Crear artefacto de riesgos con metodología, registro y cobertura por categorías

| Field | Value |
|-------|-------|
| **Tag** | REQ-DOC-00002 |
| **Title** | Crear artefacto de riesgos con metodología, registro y cobertura por categorías |
| **Priority** | P2 |
| **Status** | READY |
| **Created** | 2026-05-03 |
| **Updated** | 2026-05-03 |
| **Author** | Claude Code |
| **Depends On** | None — fuentes de derivación (`wbs.typ`, `usm.typ`, `personas.typ`, `features.typ`, `01-technical-vision/technical-vision.md` § Decisions Deferred) ya existen |
| **Decision Doc** | N/A — solución única clara: artefacto Typst siguiendo el patrón de `comunicaciones.typ` |
| **Selected Approach** | Single approach: nuevo `docs/artifacts/riesgos.typ` con secciones de metodología + tabla de registro + tabla de stubs, integrado a `main.typ` |

---

## 1. Problem Statement

El artefacto de Riesgos es uno de los entregables pendientes para cerrar la fase de planificación (ver `INF-FE-00001`). No existe `docs/artifacts/riesgos.typ`. La versión anterior de este issue prescribía 2-3 riesgos genéricos sin metodología; la cátedra espera **amplitud por categoría** + **profundidad metodológica**, no una lista plana.

Este plan define la estructura, metodología y cobertura del artefacto. **No prescribe los riesgos concretos** — esos los identifica el implementador a partir de las fuentes existentes (WBS, USM, personas, ADRs, dependencias externas).

---

## 2. Solution Design

### 2.1 Approach

**Patrón establecido**: replicar la estructura de `docs/artifacts/comunicaciones.typ`:

- Importar `conf` + `stroke-std` del template compartido.
- Usar `#table()` nativo de Typst para el registro (no `cetz`, no canvas — el artefacto es tabular).
- Header de tabla con `c-brand` (#154360) en blanco, igual que comunicaciones.
- Inclusión en `docs/artifacts/main.typ` mediante `#include "riesgos.typ"` con `#pagebreak()` separadores.

### 2.2 Estructura del artefacto

Cinco secciones, en este orden:

1. **`= Riesgos del Proyecto`** — heading principal + 1 párrafo de propósito.
2. **`== Metodología`** — narrativa breve:
   - Identificación: cómo se derivan los candidatos (lista de fuentes).
   - Evaluación: escala P × I (ver §2.3).
   - Priorización: umbrales de exposición.
3. **`== Escala de Probabilidad e Impacto`** — tabla 2-columna (nivel → descriptor) para P y otra para I, o una tabla combinada. Más una tabla de umbrales de exposición.
4. **`== Registro de Riesgos`** — tabla principal con riesgos completos. Columnas:
   `ID | Categoría | Descripción | P | I | Exp. | Trigger | Mitigación | Contingencia | Owner | Estado`.
   Mínimo **3 filas**.
5. **`== Riesgos en Stub`** — tabla compacta. Columnas: `ID | Categoría | Descripción | P | I`. Mínimo **5 filas**.

Opcional: **`== Notas`** al final con caveats (snapshot a fecha de entrega, mitigaciones reales fuera de alcance).

### 2.3 Escala P × I

Escala **1-5** uniforme para Probabilidad y para Impacto. Exposición = P × I (rango 1-25).

| Nivel | Probabilidad | Impacto |
|-------|--------------|---------|
| 1 | Muy improbable | Insignificante |
| 2 | Improbable | Menor |
| 3 | Posible | Moderado |
| 4 | Probable | Mayor |
| 5 | Casi seguro | Crítico |

Umbrales de exposición:

| Nivel | Rango | Acción |
|-------|-------|--------|
| Crítico | ≥ 16 | Plan de mitigación + contingencia obligatorios; revisión semanal |
| Alto | 9-15 | Plan de mitigación obligatorio; revisión quincenal |
| Medio | 4-8 | Mitigación opcional; revisión mensual |
| Bajo | 1-3 | Aceptado; sin acción |

### 2.4 Categorías

Las **5 categorías** que el artefacto debe cubrir (al menos 1 riesgo — completo o stub — por categoría):

1. **Técnico** — stack, scaling, deuda técnica, integraciones internas.
2. **Negocio / mercado** — adopción, cold-start de marketplace, competencia, pricing.
3. **Equipo / proceso** — tamaño del equipo, disponibilidad, conocimiento, dinámica.
4. **Externo / dependencias** — proveedores (ARCA, Maps, pagos, seguros), APIs.
5. **Regulatorio / legal** — normativa de transporte AR, datos personales, fiscal.

Distribución entre completos/stubs por categoría: **a criterio del implementador**.

### 2.5 Esquema del registro

Riesgo **completo**:
- `ID` — formato `R-NN` (`R-01`, `R-02`, …).
- `Categoría` — una de las 5.
- `Descripción` — qué, dónde, gatillo posible (1-3 oraciones).
- `Probabilidad` — 1-5 + justificación corta entre paréntesis.
- `Impacto` — 1-5 + justificación corta.
- `Exposición` — P × I (con nivel: Crítico/Alto/Medio/Bajo).
- `Trigger` — señal temprana observable.
- `Mitigación` — acción para reducir P o I.
- `Contingencia` — qué hacer si ocurre.
- `Owner` — rol responsable (PM, Tech Lead, etc., o `TBD`).
- `Estado` — `abierto` / `mitigado` / `cerrado`.

Riesgo **stub**: `ID`, `Categoría`, `Descripción` (1-2 líneas), `P` y `I` tentativos.

### 2.6 Integración con `main.typ`

Insertar en `docs/artifacts/main.typ` **después** de `comunicaciones.typ` y **antes** de `cost-report.typ` — agrupa los artefactos de gestión de proyecto:

```typ
// ── 8. Plan de Comunicaciones ──────────────────────────────────────────────
#include "comunicaciones.typ"

#pagebreak()

// ── 9. Riesgos del Proyecto ────────────────────────────────────────────────
#include "riesgos.typ"

// ── 10. Informe de Costos T&M ──────────────────────────────────────────────
#include "cost-report.typ"
```

Renumerar comentarios subsecuentes para mantener orden coherente.

---

## 3. Implementation Tasks

| # | Task | Status | Files |
|---|------|--------|-------|
| 1 | Crear `docs/artifacts/riesgos.typ` con header, imports y heading principal | Pending | `docs/artifacts/riesgos.typ` |
| 2 | Escribir sección `== Metodología` (identificación + evaluación + priorización) | Pending | `docs/artifacts/riesgos.typ` |
| 3 | Escribir sección `== Escala de Probabilidad e Impacto` con tablas P, I y umbrales | Pending | `docs/artifacts/riesgos.typ` |
| 4 | Identificar ≥3 riesgos completos cubriendo categorías diferentes (derivar de WBS/USM/ADRs) | Pending | — (research) |
| 5 | Escribir sección `== Registro de Riesgos` con tabla de los riesgos completos | Pending | `docs/artifacts/riesgos.typ` |
| 6 | Identificar ≥5 riesgos en stub cubriendo el resto de categorías | Pending | — (research) |
| 7 | Escribir sección `== Riesgos en Stub` con tabla compacta | Pending | `docs/artifacts/riesgos.typ` |
| 8 | Integrar `riesgos.typ` en `docs/artifacts/main.typ` entre comunicaciones y cost-report | Pending | `docs/artifacts/main.typ` |
| 9 | Compilar `just build-artifact riesgos` y `just build-artifacts` — verificar que no hay warnings | Pending | — |
| 10 | Correr `prek run` (typstyle) y dejar pasar formateo automático | Pending | — |

---

## 4. Code Changes

### 4.1 New file: `docs/artifacts/riesgos.typ`

**Purpose**: artefacto Typst del registro de riesgos.

Esqueleto (el implementador completa los riesgos concretos):

```typ
#import "../template.typ": conf, stroke-std
#show: conf

= Riesgos del Proyecto

El registro de riesgos identifica eventos que pueden afectar el cumplimiento
del proyecto Truckr®. Se documentan en profundidad los riesgos de mayor
exposición, y se mantienen como /stubs/ los demás para revisión incremental.

== Metodología

=== Identificación

Los riesgos se derivan de las fuentes existentes del proyecto:

- *WBS* (`wbs.typ`) — riesgos por entregable.
- *USM* (`usm.typ`) — riesgos por activity / task group.
- *Visión técnica* (`01-technical-vision/technical-vision.md` § Decisiones
  Diferidas) — cada decisión diferida es un riesgo latente.
- *Apéndice de sistemas externos* — dependencias.
- *Personas* (`personas.typ`) — riesgos de adopción y cold-start de
  marketplace de doble lado.

=== Evaluación

Cada riesgo se evalúa con dos dimensiones en escala 1–5:

#table(
  columns: (auto, 1fr, 1fr),
  inset: (x: 6pt, y: 5pt),
  stroke: stroke-std,
  table.header(
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[Nivel]],
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[Probabilidad]],
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[Impacto]],
  ),
  [1], [Muy improbable], [Insignificante],
  [2], [Improbable], [Menor],
  [3], [Posible], [Moderado],
  [4], [Probable], [Mayor],
  [5], [Casi seguro], [Crítico],
)

La *exposición* se calcula como $P times I$ (rango 1–25).

=== Priorización

#table(
  columns: (auto, auto, 1fr),
  inset: (x: 6pt, y: 5pt),
  stroke: stroke-std,
  table.header(
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[Nivel]],
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[Rango]],
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[Acción]],
  ),
  [Crítico], [≥ 16], [Mitigación + contingencia obligatorias; revisión semanal],
  [Alto], [9–15], [Mitigación obligatoria; revisión quincenal],
  [Medio], [4–8], [Mitigación opcional; revisión mensual],
  [Bajo], [1–3], [Aceptado; sin acción],
)

== Registro de Riesgos

#set text(size: 8.5pt)

#table(
  columns: (auto, auto, 2fr, auto, auto, auto, 1.5fr, 1.5fr, 1.5fr, auto, auto),
  inset: (x: 4pt, y: 5pt),
  stroke: stroke-std,
  table.header(
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[ID]],
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[Categoría]],
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[Descripción]],
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[P]],
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[I]],
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[Exp.]],
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[Trigger]],
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[Mitigación]],
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[Contingencia]],
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[Owner]],
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[Estado]],
  ),

  // R-01 .. R-NN — riesgos completos a identificar por el implementador
  // (≥3 filas, cubriendo al menos 3 categorías distintas)
)

#set text(size: 10pt)

== Riesgos en Stub

#set text(size: 9pt)

#table(
  columns: (auto, auto, 3fr, auto, auto),
  inset: (x: 6pt, y: 5pt),
  stroke: stroke-std,
  table.header(
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[ID]],
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[Categoría]],
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[Descripción]],
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[P]],
    table.cell(fill: rgb("#154360"))[#text(fill: white, weight: "bold")[I]],
  ),

  // S-01 .. S-NN — riesgos en stub a identificar por el implementador
  // (≥5 filas, completar la cobertura de las 5 categorías)
)

#set text(size: 10pt)

== Notas

- El registro es un /snapshot/ a la fecha de entrega; no se hace burn-down
  temporal en este artefacto.
- Las mitigaciones que requieran trabajo concreto se trackean como issues
  separados en `.gdsi-sdlc/`.
- Los riesgos post-MVP / fase 2+ no se registran aquí.
```

> El implementador completa el cuerpo de las dos tablas (`R-NN` y `S-NN`) tras identificar los riesgos concretos. El esqueleto y la metodología no se modifican.

### 4.2 Modified file: `docs/artifacts/main.typ`

**Purpose**: incluir el nuevo artefacto en el reporte agregado.

Insertar entre `comunicaciones.typ` y `cost-report.typ` (alrededor de línea 97-100):

```typ
// ── 8. Plan de Comunicaciones ──────────────────────────────────────────────
#include "comunicaciones.typ"

#pagebreak()

// ── 9. Riesgos del Proyecto ────────────────────────────────────────────────
#include "riesgos.typ"

// ── 10. Informe de Costos T&M ──────────────────────────────────────────────
#include "cost-report.typ"
```

---

## 5. Testing

No hay test suite para artefactos. Verificación manual:

### Compilación
- `just build-artifact riesgos` → produce `docs/artifacts/riesgos.pdf` sin warnings.
- `just build-artifacts` → produce `docs/artifacts/main.pdf` sin warnings.

### Verificación visual
- Abrir `riesgos.pdf` y `main.pdf`.
- Confirmar que las tablas de Registro y Stub renderizan sin overflow horizontal.
- Confirmar que el heading aparece en el outline (`main.pdf` § Riesgos del Proyecto).

### Lint
- `prek run --files docs/artifacts/riesgos.typ docs/artifacts/main.typ` → typstyle pasa o auto-formatea sin diff inesperado.

---

## 6. Acceptance Criteria

- [ ] `docs/artifacts/riesgos.typ` existe, importa `conf` + `stroke-std` del template compartido y compila con `just build-artifact riesgos` sin warnings.
- [ ] Incluido en `docs/artifacts/main.typ` (entre `comunicaciones.typ` y `cost-report.typ`); aparece en `just build-artifacts`.
- [ ] Sección `== Metodología` con identificación, escala P × I y priorización.
- [ ] Tabla de `== Escala` cubre niveles 1–5 para P y para I, más umbrales de exposición.
- [ ] `== Registro de Riesgos` tiene **≥ 3 filas** con todos los campos del schema (ID, Categoría, Descripción, P, I, Exp., Trigger, Mitigación, Contingencia, Owner, Estado).
- [ ] `== Riesgos en Stub` tiene **≥ 5 filas** con ID, Categoría, Descripción, P, I.
- [ ] Las **5 categorías** (Técnico / Negocio / Equipo / Externo / Regulatorio) tienen al menos 1 riesgo (completo o stub).
- [ ] Cada riesgo completo enlaza implícita o explícitamente a su fuente de derivación (WBS/USM/ADR/persona/dependencia) cuando aplique.
- [ ] Contenido en es-AR; identificadores (`R-NN`, `S-NN`) y términos técnicos consistentes.
- [ ] `prek run` pasa en los archivos modificados (typstyle no introduce diff manual).

---

## 7. Files Summary

### New Files

| File | Description |
|------|-------------|
| `docs/artifacts/riesgos.typ` | Artefacto Typst del registro de riesgos: metodología + escala + tabla de registro completos + tabla de stubs |

### Modified Files

| File | Changes |
|------|---------|
| `docs/artifacts/main.typ` | Incluir `riesgos.typ` entre `comunicaciones.typ` y `cost-report.typ` con `#pagebreak()` separador |
| `docs/features/ISSUES-INDEX.md` | Agregar fila para `REQ-DOC-00002` con estado `RDY` y link al plan |
| `.gdsi-sdlc/issues/Backlog/REQ-DOC-00002-….issue.md` → `Ready/` | Move issue file; update frontmatter `status: ready` y agregar `plan:` |
