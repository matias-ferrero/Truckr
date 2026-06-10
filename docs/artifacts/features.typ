#import "../template.typ": conf
#show: conf

#set page(
  flipped: true,
  footer: [(\*) Estas _features_ no fueron incluidas en el MVP, por lo que serán implementadas en un release post-MVP.],
  paper: "a3",
  margin: (x: 0.5cm, y: 0.8cm),
)

= Features Matrix

// ── Colors ────────────────────────────────────────────────────────────────
#let personas-color = rgb("#C9DAF8")
#let data-color = rgb("#FFFFFF")
#let data-font-color = rgb("#FBBC04")
#let avg-font-color = rgb("#000000")

// Average row: smooth gradient red → green (indices 0–14)
#let avg-colors = (
  rgb("#C5221F"),
  rgb("#D32F2F"),
  rgb("#E53935"),
  rgb("#E06666"),
  rgb("#E8725E"),
  rgb("#ED9A56"),
  rgb("#F1C232"),
  rgb("#B8D89F"),
  rgb("#A8D08E"),
  rgb("#98C87D"),
  rgb("#88C06C"),
  rgb("#78B85B"),
  rgb("#68B04A"),
  rgb("#5A9F44"),
  rgb("#4C8E3E"),
)

// ── Ratings ───────────────────────────────────────────────────────────────
// Columns: flota, ventanas, cargas, busqueda, compuestos, encadenados,
//          mapping, gps, pagos, seguros, historial, reseñas, notificaciones
#let ratings = (
  (5, 4, 3, 5, 5, 3, 3, 1, 3, 1, 2, 3, 3), // Hugo Fernandez
  (5, 5, 4, 5, 3, 5, 5, 4, 4, 1, 4, 3, 4), // Martín Fernandez
  (5, 5, 3, 4, 5, 4, 5, 5, 4, 4, 5, 4, 3), // AgroTransport
  (5, 5, 4, 5, 5, 5, 4, 3, 5, 2, 3, 3, 4), // Juan Martinez
  (5, 5, 4, 5, 2, 3, 4, 4, 4, 4, 2, 4, 3), // Carolina Souza
  (5, 5, 3, 5, 4, 5, 5, 5, 5, 4, 5, 3, 4), // Manuel Ramos
  (1, 3, 5, 4, 1, 1, 4, 3, 3, 3, 2, 5, 2), // Daniela Perez
  (1, 4, 5, 5, 2, 2, 5, 5, 5, 4, 4, 5, 4), // Florencia Scazzola
  (1, 2, 4, 4, 1, 1, 3, 5, 2, 5, 3, 2, 2), // Campos Gimenez
  (1, 1, 4, 4, 1, 1, 4, 5, 2, 4, 1, 5, 2), // Sofia Carrasco
)

// ── Helpers ───────────────────────────────────────────────────────────────
#let col-avg(col) = (
  ratings.map(r => r.at(col)).fold(0, (a, b) => a + b) / ratings.len()
)

#let fmt-avg(v) = {
  let s = str(calc.round(v, digits: 1))
  if not s.contains(".") { s + ".0" } else { s }
}

#let stars(n) = {
  let s = ""
  for i in range(5) {
    s += if i < n { "★" } else { "☆" }
  }
  s
}

#let data-cell(n) = table.cell(fill: data-color)[#align(center)[#text(
  size: 17pt,
  font: "DejaVu Sans",
  fill: data-font-color,
)[#stars(n)]]]

#let avg-cell(col) = {
  let avg = col-avg(col)
  let idx = calc.min(14, calc.floor((avg - 1) * 3.5))
  table.cell(fill: avg-colors.at(idx))[#align(center)[#text(
    size: 17pt,
    font: "DejaVu Sans",
    fill: avg-font-color,
  )[#fmt-avg(avg)]]]
}

#table(
  columns: (1fr,) * 14,
  stroke: 1.5pt,
  align: center,
  inset: (x: 4pt, y: 15pt),

  // ── Header row ────────────────────────────────────────────────────────
  table.cell(fill: personas-color, align: center + horizon)[
    #set par(justify: true)
    *Features*
    #v(0.2em)
    #line(length: 80%, stroke: 0.5pt)
    #v(0.2em)
    *Personas*
  ],
  table.cell(align: center + horizon)[
    #set par(justify: false)
    *Registrar Flota*
  ],
  table.cell(align: center + horizon)[
    #set par(justify: false)
    *Publicar Ventanas de Transporte*
  ],
  table.cell(align: center + horizon)[
    #set par(justify: false)
    *Publicar Cargas*
  ],
  table.cell(align: center + horizon)[
    #set par(justify: false)
    *Búsqueda\ de Cargas y Ventanas de Transporte*
  ],
  table.cell(align: center + horizon)[
    #set par(justify: false)
    *Envíos Compuestos\**
  ],
  table.cell(align: center + horizon)[
    #set par(justify: false)
    *Envíos Encadenados\**
  ],
  table.cell(align: center + horizon)[
    #set par(justify: false)
    *Mapping*
  ],
  table.cell(align: center + horizon)[
    #set par(justify: false)
    *Integración con GPS\**
  ],
  table.cell(align: center + horizon)[
    #set par(justify: false)
    *Integración de Pagos\**
  ],
  table.cell(align: center + horizon)[
    #set par(justify: false)
    *Gestión de Seguros\**
  ],
  table.cell(align: center + horizon)[
    #set par(justify: false)
    *Historial de Envíos*
  ],
  table.cell(align: center + horizon)[
    #set par(justify: false)
    *Reseñas*
  ],
  table.cell(align: center + horizon)[
    #set par(justify: false)
    *Notificaciones*
  ],

  // ── Data rows ─────────────────────────────────────────────────────────
  table.cell(fill: personas-color)[Hugo Fernandez (64 años)],
  ..ratings.at(0).map(data-cell),

  table.cell(fill: personas-color)[Martín Fernandez (32 años)],
  ..ratings.at(1).map(data-cell),

  table.cell(fill: personas-color)[AgroTransport],
  ..ratings.at(2).map(data-cell),

  table.cell(fill: personas-color)[Juan Martinez (41 años)],
  ..ratings.at(3).map(data-cell),

  table.cell(fill: personas-color)[Carolina Souza (35 años)],
  ..ratings.at(4).map(data-cell),

  table.cell(fill: personas-color)[Manuel Ramos (52 años)],
  ..ratings.at(5).map(data-cell),

  table.cell(fill: personas-color)[Daniela Perez (señora de 55 años)],
  ..ratings.at(6).map(data-cell),

  table.cell(fill: personas-color)[Florencia Scazzola (mujer de 40 años).],
  ..ratings.at(7).map(data-cell),

  table.cell(fill: personas-color)[Campos Giménez],
  ..ratings.at(8).map(data-cell),

  table.cell(fill: personas-color)[Sofía Carrasco (24 años)],
  ..ratings.at(9).map(data-cell),

  // ── Average row ───────────────────────────────────────────────────────
  table.cell(fill: personas-color)[Average],
  ..range(13).map(avg-cell),
)
