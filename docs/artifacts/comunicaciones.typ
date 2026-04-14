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
  [Una única vez (inicio)],
  [Establecer visión, scope, objetivos, roles y cronograma del proyecto],
  [PM],
  [Equipo + PO],

  // ── Daily Standup ──────────────────────────────────────────────────────
  [*Daily Standup*],
  [Informal],
  [2-3 veces por semana (máx. 15 min)],
  [Sincronización rápida: qué se hizo, qué se hace ahora, impedimentos],
  [Scrum Master / PM],
  [Equipo],

  // ── Sprint Planning ──────────────────────────────────────────────
  [*Sprint Planning*],
  [Formal],
  [Semanal (inicio de semana)],
  [Seleccionar user stories, definir alcance del sprint],
  [Scrum Master / PM],
  [Equipo + PO],

  // ── Sprint Review ──────────────────────────────────────────────────────
  [*Sprint Review*],
  [Formal],
  [Quincenal (fin de sprint)],
  [Demostración de incrementos entregables, feedback de stakeholders],
  [Equipo],
  [PO],

  // ── Sprint Retrospectiva ───────────────────────────────────────────────
  [*Sprint Retrospectiva*],
  [Formal],
  [Quincenal (fin de sprint, post-review)],
  [Identificar mejoras en procesos, dinámicas y herramientas del equipo],
  [Scrum Master / PM],
  [Equipo + PO],

  // ── Comunicación Formal (Email) ────────────────────────────────────────
  [*Comunicación Oficial (Email)*],
  [Formal],
  [Frecuencia variable (según necesidad)],
  [Decisiones, cambios de scope, comunicados a stakeholders],
  [Product Owner / Scrum Master],
  [Equipo + Stakeholders (según destino)],

  // ── Slack / Discord ────────────────────────────────────────────────────
  [*Canal de Chat (Discord)*],
  [Informal],
  [Diaria (continua)],
  [Comunicación rápida, preguntas, colaboración, notificaciones],
  [N/A (abierto)],
  [Equipo de Desarrollo],

  // ── WhatsApp / Grupo de Emergencias ────────────────────────────────────
  [*Grupo WhatsApp (Urgencias)*],
  [Informal],
  [Según necesidad (urgencias)],
  [Notificación rápida de incidentes críticos o bloqueadores],
  [N/A (abierto)],
  [Equipo de Desarrollo],

  // ── Demo Final ─────────────────────────────────────────
  [*Demo Final*],
  [Formal],
  [Una vez (final del proyecto)],
  [Mostrar resultados al cliente y entregar el MVP completado],
  [Equipo],
  [PO + Clientes],
)

#v(1em)

== Notas y Consideraciones

- *Flexibilidad:* Esta estructura puede ajustarse según la evolución del proyecto. Cualquier cambio debe justificarse ante el Product Owner.

- *Herramientas por Tipo:*
  - *Formal* — Reuniones síncronas (Google Meet, Zoom), Email, Documentos compartidos
  - *Informal* — Discord, WhatsApp, comunicación verbal en la facultad

- *Objetivos de Alineación:* Las reuniones formales (Kickoff, Planning, Review, Retrospectiva) son obligatorias para alineación y toma de decisiones. Las dailies y chats son para fluidez operativa.

- *Owner:* Cada instancia tiene un propietario responsable de convocar, moderar y documentar outcomes.

- *Documentación de Decisiones:* Las decisiones importantes deben quedar registradas como documentación en formato .typ dentro del repositorio
