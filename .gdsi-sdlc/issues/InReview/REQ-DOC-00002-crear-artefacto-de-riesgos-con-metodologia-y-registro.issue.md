---
tag: REQ-DOC-00002
title: Crear artefacto de riesgos con metodología, registro y cobertura por categorías
priority: P2
status: in_review
created: '2026-04-18'
source: github
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/54
author: ''
github_issue: 54
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-03T00:00:00+00:00Z
plan: docs/features/REQ/REQ-DOC-00002/REQ-DOC-00002-crear-artefacto-de-riesgos.plan.md
labels:
- enhancement
- artifact
- DOC
- REQ
---

## Resumen
Crear el artefacto de Riesgos del proyecto Truckr® como fuente Typst en
`docs/artifacts/riesgos.typ`, integrado a la entrega académica vía
`docs/artifacts/main.typ`. El artefacto debe registrar riesgos con metodología
explícita, escala uniforme P×I, esquema de registro consistente y cobertura por
categoría — no una lista plana.

## Contexto
- Cierra la fase de planificación junto con WBS, Cronograma y demás (ver
  `INF-FE-00001`).
- La cátedra espera amplitud de categorías, no profundidad en una sola.
- "Calidad > cantidad": pocos riesgos completos + stubs por categoría supera
  muchos riesgos superficiales.
- El implementador identifica los riesgos concretos a partir de WBS, USM,
  personas, ADRs y dependencias externas. No usar candidatos genéricos
  prescritos en el issue.

## Alcance del entregable
1. Archivo `docs/artifacts/riesgos.typ` siguiendo el template compartido
   (`#import "../template.typ": conf` / `#show: conf`).
2. Inclusión en `docs/artifacts/main.typ` para que entre al PDF agregado.
3. Sección de metodología (identificación, evaluación, priorización).
4. Registro de riesgos con esquema uniforme.
5. Cobertura por categorías.

## Metodología

### Identificación
Derivar candidatos de fuentes existentes:
- `docs/artifacts/wbs.typ` — riesgos por entregable.
- `docs/artifacts/usm.typ` — riesgos por activity / task group.
- `docs/01-technical-vision/technical-vision.md` § "Decisions Deferred" — cada
  decisión diferida es un riesgo latente.
- `docs/05-appendices/` (sistemas externos) — dependencias.
- `docs/artifacts/personas.typ` — riesgos de adopción / cold-start de doble lado.

### Escala
Escala **1–5** para Probabilidad y para Impacto. Exposición = P × I (1–25):
- Crítico: ≥ 16
- Alto: 9–15
- Medio: 4–8
- Bajo: 1–3

### Esquema del registro
Riesgo **completo**:
- ID (`R-NN`)
- Categoría
- Descripción (qué, dónde, gatillo posible)
- Probabilidad (1–5, con justificación)
- Impacto (1–5, con justificación)
- Exposición (P×I) y nivel
- Trigger / señales tempranas
- Plan de mitigación (reducir P o I)
- Plan de contingencia (qué hacer si ocurre)
- Owner
- Estado (`abierto`, `mitigado`, `cerrado`)

Riesgo en **stub**: ID, Categoría, Descripción 1–2 líneas, P/I tentativos.

## Cobertura mínima
- ≥ 3 riesgos completos según el esquema.
- ≥ 5 riesgos en stub.
- Las 5 categorías presentes con al menos 1 riesgo (completo o stub):
  - Técnico
  - Negocio / mercado
  - Equipo / proceso
  - Externo / dependencias
  - Regulatorio / legal

Distribución exacta a criterio del implementador.

## Especificación de salida
- **Archivo**: `docs/artifacts/riesgos.typ`
- **Inclusión**: `docs/artifacts/main.typ`
- **Formato**: Typst con `#show: conf` del template compartido
- **Compilación**: `just build-artifact riesgos` produce PDF sin warnings
- **Estilo**: tablas Typst para el registro, narrativa para metodología

## Fuera de alcance
- Implementación de mitigaciones reales (cada acción derivada va a un issue
  separado).
- Risk burn-down / tracking temporal — el artefacto es snapshot a la fecha
  de entrega.
- Riesgos post-MVP / fase 2+ (mencionables como nota, no documentables).

## Dependencias
- `INF-FE-00001` — cierre de artifacts.
- `docs/artifacts/{wbs,usm,personas,features}.typ` — fuentes de derivación.
- `docs/01-technical-vision/technical-vision.md` § Decisions Deferred.

## Criterios de aceptación
- [ ] `docs/artifacts/riesgos.typ` existe, importa el template compartido y
      compila con `just build-artifact riesgos`.
- [ ] Incluido en `docs/artifacts/main.typ` y aparece en `just build-artifacts`.
- [ ] Sección de metodología explícita: identificación, escala P×I, schema.
- [ ] ≥ 3 riesgos completos, cada uno con todos los campos del schema.
- [ ] ≥ 5 riesgos en stub.
- [ ] Las 5 categorías presentes con al menos 1 riesgo.
- [ ] Cada riesgo completo enlaza a su fuente de derivación (WBS, USM, ADR…)
      cuando aplique.
- [ ] Contenido en es-AR.
- [ ] `prek run` (typstyle) pasa sin cambios.
