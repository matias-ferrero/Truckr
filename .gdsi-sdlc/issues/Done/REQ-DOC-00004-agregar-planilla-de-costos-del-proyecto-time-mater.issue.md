---
tag: REQ-DOC-00004
title: Agregar Planilla de Costos del Proyecto (Time & Materials)
priority: P2
status: done
created: '2026-04-12'
source: github
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/37
author: ''
github_issue: 37
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-03T15:34:14.820301+00:00Z
labels:
- documentation
- artifact
- DOC
- REQ
assignees:
- tcorzo
---

## User Story: Planilla de Costos del Proyecto (Time & Materials)

**Como** equipo de proyecto
**Quiero** documentar la planilla de costos del proyecto bajo el modelo Time & Materials
**Para que** se pueda estimar y controlar el costo total del proyecto en función de las horas dedicadas y los recursos utilizados

## Descripción

Crear un nuevo artefacto `docs/artifacts/costos.typ` con la planilla de costos del proyecto bajo el esquema **Time & Materials** (T&M). En este modelo, el costo se calcula en base a las horas trabajadas por cada rol/recurso y su tarifa asociada.

**Puntos clave a documentar:**
- Roles del equipo y tarifa horaria de cada uno (valor de mercado de referencia)
- Horas estimadas por rol y por fase/sprint
- Costo total por rol y costo total del proyecto
- Otros costos (herramientas, licencias, infraestructura si aplica)
- Supuestos y consideraciones del modelo T&M elegido

### Tabla de referencia (ejemplo)

| Rol | Tarifa horaria (USD) | Horas estimadas | Costo estimado (USD) |
|---|---|---|---|
| Project Manager | X | Y | X × Y |
| Desarrollador Backend | X | Y | X × Y |
| Desarrollador Frontend | X | Y | X × Y |
| QA / Tester | X | Y | X × Y |
| Diseñador UX/UI | X | Y | X × Y |
| **Total** | | **ΣY** | **ΣCosto** |

### Resumen de costos adicionales (ejemplo)

| Concepto | Costo (USD) | Observaciones |
|---|---|---|
| Herramientas / Licencias | — | GitHub, Figma, etc. |
| Infraestructura | — | Hosting, CI/CD, etc. |
| **Total otros costos** | **Σ** | |

## Tareas

1. Investigar tarifas de mercado de referencia para cada rol del equipo
2. Crear archivo `docs/artifacts/costos.typ` con la planilla de costos T&M
3. Importar config compartida: `#import "../template.typ": conf` → `#show: conf`
4. Incluir tabla de costos por rol con tarifa horaria, horas estimadas y costo total
5. Incluir sección de otros costos (herramientas, infraestructura)
6. Incluir sección de supuestos del modelo T&M
7. Incluir en `docs/artifacts/main.typ` como nueva sección (después de la última sección existente)
8. Verificar que compila correctamente con `just build-artifact costos`
9. Respetar convenciones Typst del proyecto (escapar `\"`, `\#`, `\$`, `\@`, `\\`)

## Acceptance Criteria

- [ ] Given el archivo `docs/artifacts/costos.typ` When se compila Then genera tablas legibles con las columnas mínimas: Rol, Tarifa horaria, Horas estimadas, Costo estimado
- [ ] Given la planilla When se revisa Then refleja los roles reales del equipo del proyecto con tarifas de mercado justificadas
- [ ] Given el modelo T&M When se documenta Then incluye una sección de supuestos y justificación del modelo elegido
- [ ] Given `docs/artifacts/main.typ` When se incluye el nuevo artefacto Then compila correctamente como sección del informe
- [ ] Given costos adicionales (herramientas, infra) When se documentan Then se incluyen en una tabla separada con observaciones

## Technical Notes

- Archivo: `docs/artifacts/costos.typ`
- Pre-commit formatea con typstyle — no pelear contra el formatter
- Las tarifas deben expresarse en una moneda consistente (USD o ARS, definir y justificar)

## Dependencies

- Ninguna — artefacto independiente (aunque se beneficia de tener el WBS definido para estimar horas por fase)

## Priority

- MoSCoW: Must Have
- Este artefacto es requerido para la entrega del proyecto
