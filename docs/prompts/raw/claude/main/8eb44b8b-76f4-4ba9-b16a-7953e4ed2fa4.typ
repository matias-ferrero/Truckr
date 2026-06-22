#import "@preview/cmarker:0.1.8"

= Hide issue nomenclature from PO view

_2026-05-13 13:49 UTC — rama `main` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/clear`
  ```,
  h1-level: 4,
  label-prefix: "cc1609-",
)

== Intercambio 2

=== Prompt

#cmarker.render(
  ```
  **Comando:** `/sprint-progress-report`
  ```,
  h1-level: 4,
  label-prefix: "cc1610-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Now I have all data. Writing the report.
  ```,
  h1-level: 4,
  label-prefix: "cc1611-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Existing report is stale — #120 and #146 closed today, velocity should be 14 not 12, PR count 38 not 11, and AWS still pending (not "completed" as old doc implies). Rewriting.
  ```,
  h1-level: 4,
  label-prefix: "cc1612-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Single-shot generation, task tracking not needed.

  **Archivo:** `docs/features/SPRINT-1-REPORT.md`

  **Veredicto:** Sprint cumplido parcialmente — 6/7 entregables comprometidos. AWS ([#141][i141]) único item rojo.

  **Velocity:** 14 issues completados · 2 descartados · 38 PRs mergeados

  **Hallazgos clave vs el reporte previo en disco:**
  - #120 (perfil US6) y #146 (dashboard) cerraron hoy → ya no son housekeeping pendiente
  - Velocity real es 14 (no 12); PR count 38 (no 11)
  - AWS está OPEN/REOPENED — el reporte anterior lo dejaba como "a confirmar en demo"; ahora queda explícito como no entregado
  - Free-agent REQ-FE-00012 nunca se tomó

  [i141]: https://github.com/tcorzo/fiuba-gestion-tp/issues/141
  ```,
  h1-level: 4,
  label-prefix: "cc1613-",
)

== Intercambio 3

=== Prompt

#cmarker.render(
  ```
  Mejoremos la skill. A nuestro PO no le interesa nuestra nomenclatura de issues [REQ-XXX-YYYY] no mostremos eso. A ella le interesa nomás el valor entregado y que los AC de las US se cumplan con la implementación.
  ```,
  h1-level: 4,
  label-prefix: "cc1614-",
)

== Intercambio 4

=== Prompt

#cmarker.render(
  ```
  proceed
  ```,
  h1-level: 4,
  label-prefix: "cc1615-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Write didn't apply. Retrying.
  ```,
  h1-level: 4,
  label-prefix: "cc1616-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Ambos archivos listos.

  **Skill actualizado:** `.claude/skills/sprint-progress-report/SKILL.md`
  - Sección nueva "Audiencia y foco" con hard rule de no exponer TAGs (`REQ-...`, `REF-...`, `INF-...`, etc.).
  - Paso 4 nuevo y obligatorio: verificar AC contra la implementación con marcadores `[x]`/`[~]`/`[ ]` y evidencia.
  - Plantilla rediseñada con sección "Valor entregado" (subsección por US, AC literales del backlog).
  - Don'ts ampliados: no parafrasear AC, no marcar `[x]` sin evidencia, no usar TAGs.
  - Verificación final incluye grep de TAGs.

  **Reporte regenerado:** `docs/features/SPRINT-1-REPORT.md` (132 líneas, sin TAGs)
  - 6 US con AC verificados contra el código (US1, US2, US14, US9, US4, US6) + dashboard como UX glue.
  - Hallazgos honestos: longitud mínima de password en 8 (backlog pide 12) → `[~]`; paginado y ordenamiento en búsqueda no implementados → `[ ]`; CTA de oferta en perfil es placeholder porque US7 no está → `[~]`.
  - AWS sigue como único item no entregado del commitment.
  - Carry-over explícito al Sprint 2.
  ```,
  h1-level: 4,
  label-prefix: "cc1617-",
)

== Intercambio 5

=== Prompt

#cmarker.render(
  ```
  Refinemos un poco más la skill sin tocar el informe, la única source-of-truth de las historias de usuario es @docs/artifacts/backlog-us.typ Debemos agregar el enunciado de la US al informe encima de sus AC.
  ```,
  h1-level: 4,
  label-prefix: "cc1618-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Skill refinado. Cambios en `.claude/skills/sprint-progress-report/SKILL.md`:

  - **Inputs:** `docs/artifacts/backlog-us.typ` marcado como **fuente única** para enunciado y AC (no usar SPRINT-PLAN ni `.gdsi-sdlc/`).
  - **Paso 4:** ahora extrae dos cosas del backlog — el bloque `*Descripción:*` (enunciado "Como X, quiero Y, para Z") y los `*Criterios de Aceptación:*` — ambos textuales.
  - **Plantilla por US:** agregada sección **Enunciado** como blockquote arriba de los AC, separada de "Qué puede hacer ahora el usuario" (que sigue siendo síntesis del equipo, no copia del backlog).
  - **Verificación final:** chequeo nuevo de que cada US entregada tiene enunciado + AC y ambos coinciden literalmente con el backlog.
  - **Don'ts:** prohibición explícita de parafrasear enunciado/AC y de usar fuentes alternas para el texto de la US.

  El informe Sprint 1 ya generado queda intacto, como pediste.
  ```,
  h1-level: 4,
  label-prefix: "cc1619-",
)
