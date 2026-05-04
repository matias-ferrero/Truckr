#import "@preview/cmarker:0.1.8"

= Sesión de chat — 26/04/2026 18:22

== Intercambio 1
_2026-04-26 19:56 UTC — copilot/auto_

=== Prompt

#cmarker.render(
  ```
  Necesito armar un artefacto *Cronograma* para este projecto basado en los #file:artifacts existentes. La User Story nos comenta lo siguiente:

  Cronograma
  Es un calendario de trabajo o actividades.

  Por que?
  Sirve para organizar y programar actividades de manera estructurada, anticipando retrasos. Ofrece una visión global del proyecto.

  Como se completa?
  Se identifican:
  - Tareas
  - Fechas de entrega
  - Relaciones entre tareas
  - Responsables


  Alternativa mejor: Jira + milestones + hitos

  1. Crear cronograma básico (aunque sea simple)
  2. Considerar usar Jira con milestones para el futuro
  3. Definir hitos clave:
     - Cierre de artifacts
     - Sprints 1, 2, 3
     - Entrega del MVP
  ```,
  h1-level: 4,
)

=== Respuesta (GitHub Copilot)

#cmarker.render(
  ```
  Voy a crear el artefacto de Cronograma en Typst alineado al estilo del repo, basándome en los artifacts existentes y luego lo voy a integrar en el documento principal para que compile dentro del flujo actual. Primero relevo formato y estructura de artifacts similares.Ahora voy a revisar [docs/artifacts/main.typ](docs/artifacts/main.typ), [docs/artifacts/wbs.typ](docs/artifacts/wbs.typ) y algún artefacto tabular para replicar convención visual y estructura.

  Ya confirmé el estilo general y ahora voy a extraer del resto de artifacts los hitos y cortes (sprints/MVP/cierre) para que el cronograma quede consistente con lo ya documentado.

  Con lo relevado, voy a tomar responsables y eventos desde el plan de comunicaciones para completar la columna de dueños del cronograma sin inventar roles fuera del proyecto.

  Ya tengo la información necesaria para redactar el cronograma: voy a crear un nuevo archivo de artefacto con tabla de actividades (tarea, fechas, dependencia, responsable), hitos explícitos (cierre de artifacts, sprints 1-3, MVP) y una nota de evolución a Jira con milestones. Luego lo incluyo en el índice principal y valido compilación.

  Ya quedó creado e integrado el nuevo artefacto. Ahora voy a correr una compilación rápida para asegurar que no haya errores de Typst y confirmar que el cronograma entra en el PDF final.

  Pequeño chequeo final: voy a consultar memoria para registrar una nota de repo útil (dependencia de typst para build) y cerrar con estado de validación.

  Se creó el artefacto de Cronograma y quedó integrado al informe de artifacts.

  Cambios realizados:
  1. Nuevo artefacto en [docs/artifacts/cronograma.typ](docs/artifacts/cronograma.typ#L1)
  2. Inclusión en el documento principal en [docs/artifacts/main.typ](docs/artifacts/main.typ#L88)

  Qué contiene el cronograma:
  1. Calendario base con tareas, fechas, relaciones y responsables:
  - Cierre de artifacts
  - Sprint 1
  - Sprint 2
  - Sprint 3
  - Cierre y entrega MVP
  2. Tabla de hitos clave con fecha objetivo y criterio de cumplimiento:
  - Cierre de artifacts
  - Fin Sprint 1, 2 y 3
  - Entrega del MVP
  3. Sección de evolución recomendada hacia Jira:
  - Milestones por hito
  - Issues por entregable con responsable y due date
  - Roadmap para dependencias y desvíos

  Validación:
  - Revisión de errores de archivo OK en:
    - [docs/artifacts/cronograma.typ](docs/artifacts/cronograma.typ)
    - [docs/artifacts/main.typ](docs/artifacts/main.typ)
  - La compilación completa no pudo ejecutarse porque falta Typst en el entorno (error: typst: not found al correr just build-artifacts).

  Siguiente paso natural:
  1. Instalar toolchain con mise install y volver a correr just build-artifacts para verificar el PDF final.
  ```,
  h1-level: 4,
)

== Intercambio 2
_2026-04-26 20:44 UTC — copilot/auto_

=== Prompt

#cmarker.render(
  ```
  Mira nuestra materia tiene un calendario que te voy a dejar aca abajo la informacion necesaria, asi dejamos el cronograma impecable:


  06/05/2026
  "Defensa de la entrega de los artefactos. Presentación (Google Slides o similar) de 25 minutos en donde deben mostrar el uso de herramientas de IA/desarrollo agéntico, las versiones generadas en cada iteracion, la evolución de los artefactos hasta llegar al artefacto final y justificación del resultado. Todos los miembros del grupo deben exponer a su ayudante (Product Owner).

  Artefactos a presentar:
  - Planilla de Riesgos del TP
  - Cierre Plan de Comunicaciones, Planilla de Costos

  Inicio del Desarrollo"

  13/05/2026
  "Defensa de la entrega de los artefactos del Sprint 1 de desarrollo. Presentación (Google Slides o similar) de 25 minutos en donde deben mostrar la Demo y Retro del Sprint, que debe quedar documentada. Todos los miembros del grupo deben exponer a su ayudante (Product Owner).

  Esta presentación debe incluir:
  - Alcance del sprint (cuanto fue implementado y si hubo carryover)
  - Métricas del sprint
  - Revisión y actualización de riesgos, alcance, tiempos, costos, indicadores, estimaciones, pruebas
  - Demo del producto
  - Retrospectiva del producto
  - Definición del alcance de la iteración siguiente con criterios de aceptación
  - Por cada artefacto indicar el uso de IA, la evolución de los artefactos hasta llegar al artefacto final y justificación del resultado"

  20/05/2026
  "Defensa de la entrega de los artefactos del Sprint 2 de desarrollo. Presentación (Google Slides o similar) de 25 minutos en donde deben mostrar la Demo y Retro del Sprint, que debe quedar documentada. Todos los miembros del grupo deben exponer a su ayudante (Product Owner).

  Esta presentación debe incluir:
  - Alcance del sprint (cuanto fue implementado y si hubo carryover)
  - Métricas del sprint
  - Revisión y actualización de riesgos, alcance, tiempos, costos, indicadores, estimaciones, pruebas,
  - Definición del alcance de la iteración siguiente con criterios de aceptación
  - Por cada artefacto indicar el uso de IA, la evolución de los artefactos hasta llegar al artefacto final y justificación del resultado"

  27/05/2026
  "Defensa de la entrega de los artefactos del Sprint 3 de desarrollo. Presentación (Google Slides o similar) de 25 minutos en donde deben mostrar la Demo y Retro del Sprint, que debe quedar documentada. Todos los miembros del grupo deben exponer a su ayudante (Product Owner).

  Esta presentación debe incluir:
  - Alcance del sprint (cuanto fue implementado y si hubo carryover)
  - Métricas del sprint
  - Revisión y actualización de riesgos, alcance, tiempos, costos, indicadores, estimaciones, pruebas,
  - Definición del alcance de la iteración siguiente con criterios de aceptación
  - Por cada artefacto indicar el uso de IA, la evolución de los artefactos hasta llegar al artefacto final y justificación del resultado"

  03/06/2026
  "Defensa de la entrega de los artefactos del Sprint 4 de desarrollo. Presentación (Google Slides o similar) de 25 minutos en donde deben mostrar la Demo y Retro del Sprint, que debe quedar documentada. Todos los miembros del grupo deben exponer a su ayudante (Product Owner).

  Esta presentación debe incluir:
  - Alcance del sprint (cuanto fue implementado y si hubo carryover)
  - Métricas del sprint
  - Revisión y actualización de riesgos, alcance, tiempos, costos, indicadores, estimaciones, pruebas,
  - Definición del alcance de la iteración siguiente con criterios de aceptación
  - Por cada artefacto indicar el uso de IA, la evolución de los artefactos hasta llegar al artefacto final y justificación del resultado"

  10/06/2026
  "Defensa de la entrega de los artefactos del Sprint 5 de desarrollo. Presentación (Google Slides o similar) de 25 minutos en donde deben mostrar la Demo y Retro del Sprint, que debe quedar documentada. Todos los miembros del grupo deben exponer a su ayudante (Product Owner).

  Esta presentación debe incluir:
  - Alcance del sprint (cuanto fue implementado y si hubo carryover)
  - Métricas del sprint
  - Revisión y actualización de riesgos, alcance, tiempos, costos, indicadores, estimaciones, pruebas,
  - Definición del alcance de la iteración siguiente con criterios de aceptación
  - Por cada artefacto indicar el uso de IA, la evolución de los artefactos hasta llegar al artefacto final y justificación del resultado"

  17/06/2026
  "Defensa de la entrega de los artefactos del Sprint 6 de desarrollo. Presentación (Google Slides o similar) de 25 minutos en donde deben mostrar la Demo y Retro del Sprint, que debe quedar documentada. Todos los miembros del grupo deben exponer a su ayudante (Product Owner).

  Esta presentación debe incluir:
  - Alcance del sprint (cuanto fue implementado y si hubo carryover)
  - Métricas del sprint
  - Revisión y actualización de riesgos, alcance, tiempos, costos, indicadores, estimaciones, pruebas,
  - Definición del alcance de la iteración siguiente con criterios de aceptación
  - Por cada artefacto indicar el uso de IA, la evolución de los artefactos hasta llegar al artefacto final y justificación del resultado"

  24/06/2026
  Cierre Sprint 7 y Exposicion / Entrega Final. Ver documento con detalle de la Defensa Final.
  ```,
  h1-level: 4,
)

=== Respuesta (GitHub Copilot)

#cmarker.render(
  ```
  Perfecto, con este calendario oficial voy a recalibrar el cronograma para que quede 1:1 con las fechas de cátedra (06/05 a 24/06), incluyendo defensas por sprint y cierre final. Después lo compilo para validar que quede impecable en el PDF.

  Voy a ajustar el archivo para que siga exactamente el calendario real de la materia: una fila por sprint con su fecha de defensa semanal, más el cierre final del 24/06, y una sección breve con el contenido obligatorio de cada defensa.

  El parche anterior falló por desajuste de contexto; voy a reemplazar el contenido completo de [docs/artifacts/cronograma.typ](docs/artifacts/cronograma.typ#L1) en una sola edición para evitar inconsistencias y dejarlo exacto al calendario que pasaste.

  El cronograma ya quedó sincronizado con todas las fechas oficiales. Ahora hago validación rápida de errores y compilación del informe para confirmar que se renderiza bien.

  Quedó impecable y alineado al calendario oficial de la materia.

  Actualicé [docs/artifacts/cronograma.typ](docs/artifacts/cronograma.typ) con:
  1. Calendario completo desde 27/04 hasta 24/06.
  2. Sprints 1 a 7 con sus ventanas semanales reales.
  3. Hitos de defensa exactos:
  - 06/05 artifacts + inicio desarrollo
  - 13/05 Sprint 1
  - 20/05 Sprint 2
  - 27/05 Sprint 3
  - 03/06 Sprint 4
  - 10/06 Sprint 5
  - 17/06 Sprint 6
  - 24/06 cierre Sprint 7 + entrega/exposición final
  4. Sección explícita con contenido obligatorio de cada defensa semanal.
  5. Ajuste del enfoque No-Estimates para proyectar cierre hasta Sprint 7.
  6. Recomendación Jira actualizada con milestones en todas las fechas de defensa.

  Validación:
  1. Sin errores en [docs/artifacts/cronograma.typ](docs/artifacts/cronograma.typ).
  2. Compilación de artifacts OK con mise exec -- just build-artifacts.

  Si querés, en el próximo paso te dejo una versión espejo de este cronograma en formato checklist para usar directo en la presentación de 25 minutos de cada defensa.
  ```,
  h1-level: 4,
)

== Intercambio 3
_2026-04-26 21:04 UTC — copilot/auto_

=== Prompt

#cmarker.render(
  ```
  Mira en el repo hay un Cronograma.xlsx de ejemplo, basicamente es un template que nos dejaron. No deberiamos armar algo mas de ese estilo? Que hayan tareas e ir poniendo cuando se implementarian a lo largo de las semanas/sprints. Fijate en nuestro backlog o el User Story Mapping las tareas numeradas para ir poniendo en el cronograma nuestro. Y despues si armate un par de hitos claves (como cierra de artefactos y comienzo de desarrollo, mitad del desarrollo, demo final. Los que creas necesarios)
  ```,
  h1-level: 4,
)

=== Respuesta (GitHub Copilot)

#cmarker.render(
  ```
  Sí, tiene mucho sentido: voy a tomar el formato del ejemplo de cronograma tipo grilla por semanas/sprints y rehacer nuestro artefacto con tareas numeradas (US) distribuidas en Sprint 1–7, más hitos clave al final. Primero localizo el Excel de referencia y extraigo estructura.

  Ahora voy a inspeccionar la estructura del Excel para copiar el estilo de planificación (columnas/sprints/convenciones) y adaptarlo a sus US.

  Voy a dejarlo en formato “planilla” como el Excel: filas de tareas (con IDs US), columnas Sprint 1–7 con marcas X, y al final una tabla corta de hitos clave. Después compilo para verificar que no se rompa el informe.

  Sí, totalmente: ya lo rehice en ese estilo de planilla tipo Excel.

  Qué cambié en [docs/artifacts/cronograma.typ](docs/artifacts/cronograma.typ):
  1. Pasé a formato matriz por sprints, similar a Cronograma.xlsx:
  - Columnas: Fase, ID, Tarea, Responsable, S1..S7
  - Filas: tareas numeradas del backlog (US1..US26) + tareas de planning/cierre
  - Marcación con X en el sprint donde se implementa cada tarea
  2. Tomé tareas reales del backlog y las distribuí a lo largo de Sprint 1-7:
  - MVP temprano (US1, US2, US4, US7, US8, US9, US10, US12, US13, US14, US15)
  - Post-MVP en sprints posteriores (US17..US26)
  3. Dejé una tabla de calendario de defensas con las fechas de cátedra.
  4. Agregué hitos clave, como pediste:
  - Cierre de artefactos e inicio de desarrollo
  - Mitad del desarrollo
  - Demo final

  Validación:
  1. Sin errores en [docs/artifacts/cronograma.typ](docs/artifacts/cronograma.typ).
  2. Build completo OK con mise exec -- just build-artifacts.

  Si querés, el próximo ajuste fino puede ser:
  1. Reubicar 3-5 US entre sprints para balancear carga.
  2. Cambiar responsables por subequipo (Frontend, Backend, QA) en vez de Equipo.
  3. Marcar algunas US en dos sprints (implementación + estabilización), como en el Excel de ejemplo.
  ```,
  h1-level: 4,
)

== Intercambio 4
_2026-04-26 21:14 UTC — copilot/auto_

=== Prompt

#cmarker.render(
  ```
  Muchisimo mejor! Una consultita, y si borramos la tabla calendario de defensas completa? Siento que no suma tanto y en los titulos de las columnas S1, S2, ..., Sn podriamos poner que dia comienza esa semana/sprint
  ```,
  h1-level: 4,
)

=== Respuesta (GitHub Copilot)

#cmarker.render(
  ```
  Sí, totalmente razonable. Voy a sacar la tabla de calendario de defensas y renombrar las columnas S1..S7 con la fecha de inicio de cada sprint para que la grilla sea autoexplicativa.

  Hice el ajuste exacto que pediste. Ahora valido que compile bien tras borrar esa sección y cambiar los encabezados.

  Quedó hecho.

  Cambios aplicados en [docs/artifacts/cronograma.typ](docs/artifacts/cronograma.typ):
  1. Eliminé por completo la sección `Calendario de Defensas`.
  2. Renombré las columnas de sprint para incluir fecha de inicio:
  - `S1 (06/05)`
  - `S2 (13/05)`
  - `S3 (20/05)`
  - `S4 (27/05)`
  - `S5 (03/06)`
  - `S6 (10/06)`
  - `S7 (17/06)`

  Validación:
  1. Sin errores en [docs/artifacts/cronograma.typ](docs/artifacts/cronograma.typ).
  2. Compilación general OK con `mise exec -- just build-artifacts`.

  Si querés, como ajuste final puedo achicar un poco el texto de algunas tareas largas para que la tabla entre más “limpia” en una sola página.
  ```,
  h1-level: 4,
)
