#import "../template.typ": conf
#show: conf

#set heading(numbering: "1.")

// ── Cover ──────────────────────────────────────────────────────────────────
#set page(margin: (x: 3cm, top: 4cm, bottom: 3cm))

#align(center)[
  #v(3fr)

  #text(size: 48pt, weight: "black", fill: rgb("#154360"))[Truckr®]

  #v(1em)
  #text(size: 18pt, weight: "light")[Informe del Proyecto]

  #v(3em)
  #line(length: 60%, stroke: 0.5pt + luma(180))
  #v(1.5em)

  #text(size: 11pt)[
    Gestión del Desarrollo de Sistemas Informáticos \
    Facultad de Ingeniería — UBA
  ]

  #v(1em)
  #text(size: 10pt, fill: luma(100))[Marzo 2026]

  #v(3fr)
]

#pagebreak()

// ── Table of Contents ──────────────────────────────────────────────────────
#set page(margin: 2cm)

#outline(
  title: [Índice],
  depth: 2,
  indent: 1.2em,
)

#pagebreak()

// ── 1. Visión del Producto ─────────────────────────────────────────────────
#include "product-vision.typ"

#pagebreak()

// ── 2. Es / No Es / Hace / No Hace ────────────────────────────────────────
#include "es-no-es-hace-no-hace.typ"

#pagebreak()

// ── 3. Personas ────────────────────────────────────────────────────────────
#include "personas.typ"

#pagebreak()

// ── 4. Features Matrix (landscape — 12 columns) ───────────────────────────
#set page(flipped: true, margin: (x: 1cm, y: 1.2cm))
#set text(size: 8pt)

#include "features.typ"

// ── Reset to portrait ──────────────────────────────────────────────────────
#set page(flipped: false, margin: 2cm)
#set text(size: 10pt)

#pagebreak()

// ── 5. User Story Map — Productor ─────────────────────────────────────────
// (usm-productor.typ sets its own landscape + text size internally)
#include "usm-productor.typ"

// Reset portrait + text after USM landscape
#set page(flipped: false, margin: 2cm)
#set text(size: 10pt)

#pagebreak()

// ── 6. User Story Map — Transportista ─────────────────────────────────────
#include "usm-transportista.typ"

// Reset portrait + text after USM landscape
#set page(flipped: false, margin: 2cm)
#set text(size: 10pt)

#pagebreak()

// ── 7. WBS — Work Breakdown Structure ─────────────────────────────────────
#include "wbs.typ"

// Reset portrait + text after WBS landscape
#set page(flipped: false, margin: 2cm)
#set text(size: 10pt)

#pagebreak()

// ── 8. Backlog — User Stories ──────────────────────────────────────────────
#include "backlog-us.typ"
