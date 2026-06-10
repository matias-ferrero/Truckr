#import "../template.typ": conf, stroke-std
#show: conf

= Plan de Comunicaciones

El Plan de Comunicaciones establece los canales, frecuencias y objetivos de cada instancia de comunicación dentro del equipo de proyecto y con los stakeholders. Esto asegura que todos los integrantes mantengan alineación, transparencia y comunicación efectiva.

== Matriz de Comunicaciones

#set text(size: 9pt)

#table(
  columns: (1.2fr, 0.9fr, 1.2fr, 1fr, 1.2fr, 1.2fr),
  inset: (x: 6pt, y: 6pt),
  stroke: stroke-std,
  align: (left, left, left, left, left, left),

  table.header(
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Instancia de Comunicación]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Tipo]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Frecuencia]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Objetivo]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Owner]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Audiencia]],
  ),

  // ── Reunión de Kickoff ─────────────────────────────────────────────────
  [*Reunión de Kickoff*],
  [Formal],
  [Una única vez (al inicio del proyecto)],
  [Establecer visión, scope, objetivos, roles y cronograma del proyecto],
  [PO],
  [Equipo],

  // ── Sprint Planning ──────────────────────────────────────────────
  [*Sprint Planning*],
  [Formal],
  [Semanal (inicio de sprint)],
  [Seleccionar user stories, definir alcance del sprint],
  [PM],
  [Equipo],

  // ── Sprint Review ──────────────────────────────────────────────────────
  [*Sprint Review*],
  [Formal],
  [Semanal (fin de sprint)],
  [Demostración de incrementos entregables, informe de avance],
  [PO],
  [Equipo],

  // ── Sprint Retrospectiva ───────────────────────────────────────────────
  [*Sprint Retrospectiva*],
  [Formal],
  [Semanal (fin de sprint, post-review)],
  [Identificar mejoras en procesos, dinámicas y herramientas del equipo],
  [PM],
  [Equipo],

  // ── Comunicación Formal (Email) ────────────────────────────────────────
  [*Comunicación Oficial (Email)*],
  [Formal],
  [Variable (según necesidad)],
  [Decisiones, preguntas formales, documentación importante],
  [PO],
  [Equipo],

  // ── Discord ───────────────────────────────────────────────────────────
  [*Canal de Chat (Discord)*],
  [Informal],
  [Frecuencia variable],
  [Documentación rápida, preguntas],
  [N/A (abierto)],
  [Equipo],

  // ── WhatsApp / Grupo de Emergencias ────────────────────────────────────
  [*Grupo de WhatsApp*],
  [Informal],
  [Diaria (continua)],
  [Comunicación rápida, preguntas, colaboración, notificaciones],
  [N/A (abierto)],
  [Equipo],

  // ── Demo Final ─────────────────────────────────────────
  [*Demo Final*],
  [Formal],
  [Una vez (al final del proyecto)],
  [Mostrar resultados al cliente y entregar el MVP completado],
  [PO],
  [Equipo],
)
