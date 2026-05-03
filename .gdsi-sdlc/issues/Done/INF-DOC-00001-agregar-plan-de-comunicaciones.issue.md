---
tag: INF-DOC-00001
title: Agregar Plan de Comunicaciones
priority: P2
status: done
created: '2026-04-12'
source: github
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/36
author: ''
github_issue: 36
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-03T15:34:14.816319+00:00Z
labels:
- documentation
- artifact
- INF
- DOC
assignees:
- FrancoRicciardo
---

## User Story: Plan de Comunicaciones

**Como** equipo de proyecto
**Quiero** documentar el plan de comunicaciones del proyecto
**Para que** todos los integrantes y stakeholders conozcan los canales, frecuencias y objetivos de cada instancia de comunicación

## Descripción

Crear un nuevo artefacto `docs/artifacts/comunicaciones.typ` con una tabla que defina las comunicaciones del proyecto. No es una plantilla rígida — se pueden agregar o quitar columnas siempre que se justifique ante el PO.

**Puntos clave a documentar:**
- Comunicación formal (mail, etc.) e informal (Discord, WhatsApp, etc.)
- Frecuencia de cada instancia
- Objetivo de la comunicación
- Owner y audiencia
- Se recomienda incluir reunión de status (no solo mandar tareas y reunirse al final del sprint)

### Tabla de referencia (ejemplo)

| Comunicación | Frecuencia | Objetivo | Owner | Audiencia |
|---|---|---|---|---|
| Kickoff | Una vez | Dar inicio al desarrollo | PM | Equipo y PO |
| Sprint DEMO | Semanal | Mostrar el progreso del proyecto | PM | Equipo y PO |
| Sprint RETRO | Semanal | Mejorar procesos | PM | Equipo y PO |
| Sprint Planning | Semanal | Planificar el sprint | PM | Equipo |
| Daily Standup | 2-3 veces por semana | Sincronización de avance del equipo | PM | Equipo |
| Reporte de incidentes | Ad-hoc | Escalar problemas | PM | Equipo y PO |
| Demo Final | Una vez | Entregar el MVP completado | PM y equipo de desarrollo | Equipo del Proyecto y clientes |

## Tareas

1. Crear archivo `docs/artifacts/comunicaciones.typ` con la tabla de comunicaciones
2. Importar config compartida: `#import "../template.typ": conf` → `#show: conf`
3. Incluir en `docs/artifacts/main.typ` como nueva sección (después de Backlog o donde corresponda)
4. Verificar que compila correctamente con `just build-artifact comunicaciones`
5. Respetar convenciones Typst del proyecto (escapar `\"`, `\#`, `\$`, `\@`, `\\`)

## Acceptance Criteria

- [ ] Given el archivo `docs/artifacts/comunicaciones.typ` When se compila Then genera una tabla legible con las columnas mínimas: Comunicación, Frecuencia, Objetivo, Owner, Audiencia
- [ ] Given el artefacto When se revisa Then refleja las comunicaciones reales del equipo (canales, horarios, herramientas)
- [ ] Given `docs/artifacts/main.typ` When se incluye el nuevo artefacto Then compila correctamente como sección del informe
- [ ] Given columnas modificadas respecto al ejemplo When se presentan al PO Then se incluye justificación de los cambios

## Technical Notes

- Archivo: `docs/artifacts/comunicaciones.typ`
- Pre-commit formatea con typstyle — no pelear contra el formatter

## Dependencies

- Ninguna — artefacto independiente

## Priority

- MoSCoW: Must Have
- Este artefacto es requerido para la entrega del proyecto
