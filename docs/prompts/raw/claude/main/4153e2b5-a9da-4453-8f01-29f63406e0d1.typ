#import "@preview/cmarker:0.1.8"

= Create sprint progress report generator

_2026-05-13 12:18 UTC — rama `main` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/gdsi-sdlc:project:onboard full`
  ```,
  h1-level: 4,
  label-prefix: "cc614-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  Hoy cerramos nuestro 1er sprint, nuestro PO nos pidió lo siguiente para nuestra reunión de hoy:

  Un informe de avance (1 página que diga:
  - fecha del sprint (inicio y fin)
  - una lista con las historias de usuario resueltas
  - la velocity a partir del número de issues de gh cerrados
  - Observaciones
  - ¿Historias completadas o no completadas?

  Armá un skill para generar este informe de avance en español para cada sprint.

  Leé @CALENDAR.md , @docs/features/SPRINT-1-PLAN.md los issues de gh cerrados hasta ahora mismo
  ```,
  h1-level: 4,
  label-prefix: "cc615-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Tengo data suficiente. Creo el skill y luego genero el informe de Sprint 1.
  ```,
  h1-level: 4,
  label-prefix: "cc616-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Skill creado. Ahora aplico el skill y genero el informe del Sprint 1.
  ```,
  h1-level: 4,
  label-prefix: "cc617-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Skill creado y aplicado.

  **Actions taken:**
  - Creé el skill `sprint-progress-report` (Markdown, una página, en español; lee `CALENDAR.md` + `SPRINT-N-PLAN.md` + `gh` y cruza commitment vs cerrados).
  - Lo apliqué para Sprint 1 (2026-05-07 → 2026-05-13) usando los 14 cierres de GH del período.

  **Files created:**
  - `.claude/skills/sprint-progress-report/SKILL.md` — el skill reutilizable para cada sprint.
  - `docs/features/SPRINT-1-REPORT.md` — informe de avance del Sprint 1, listo para la reunión con el PO.

  **Hallazgos clave del Sprint 1:**
  - **Veredicto: cumplido.** 6/6 entregables de producto con PR a `main`.
  - **Velocity: 12 issues** completados (5 US, 3 foundation, 2 infra CI, 2 tooling/refactor); 2 cierres NOT_PLANNED no cuentan.
  - **Housekeeping pendiente** (acción para HOY): cerrar issues [#120][1] (US6, PR #164 mergeado) y [#146][2] (Dashboard, PR #162 mergeado) — sus PRs ya están en main pero los issues siguen abiertos y por eso el conteo "real" de US cerradas en GH dice 5 en vez de 7.

  [1]: https://github.com/tcorzo/fiuba-gestion-tp/issues/120
  [2]: https://github.com/tcorzo/fiuba-gestion-tp/issues/146
  ```,
  h1-level: 4,
  label-prefix: "cc618-",
)
