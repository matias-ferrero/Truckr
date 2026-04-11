#import "../template.typ": conf
#show: conf

#set page(flipped: true, paper: "a3", margin: (x: 0.5cm, y: 0.8cm))

= Features Matrix

_Observación: - Verde: Planificadas para el MVP - Rojo: Posible Mejora_

// ── Color definitions extracted from spreadsheet ──────────────────────────
#let personas-color = rgb("#C9DAF8")
#let personas-font-color = rgb("#000000")
#let data-color = rgb("#FFFFFF")
#let data-font-color = rgb("#FBBC04")

// Header colors
#let col1-color = rgb("#93C47D")
#let col1-font-color = rgb("#FBBC04")
#let col2-color = rgb("#93C47D")
#let col2-font-color = rgb("#FBBC04")
#let col3-color = rgb("#E06666")
#let col3-font-color = rgb("#FBBC04")
#let col4-color = rgb("#93C47D")
#let col4-font-color = rgb("#FBBC04")
#let col5-color = rgb("#93C47D")
#let col5-font-color = rgb("#FBBC04")
#let col6-color = rgb("#93C47D")
#let col6-font-color = rgb("#FBBC04")
#let col7-color = rgb("#93C47D")
#let col7-font-color = rgb("#FBBC04")
#let col8-color = rgb("#E06666")
#let col8-font-color = rgb("#FBBC04")
#let col9-color = rgb("#E06666")
#let col9-font-color = rgb("#FBBC04")
#let col10-color = rgb("#E06666")
#let col10-font-color = rgb("#FBBC04")
#let col11-color = rgb("#E06666")
#let col11-font-color = rgb("#FBBC04")
#let col12-color = rgb("#93C47D")
#let col12-font-color = rgb("#FBBC04")

// Average row color scale (2.67-5.00): smooth gradient strong red -> green
#let avg-color-min = rgb("#C5221F")     // Strong red (2.67)
#let avg-color-1 = rgb("#D32F2F")       // Dark red
#let avg-color-2 = rgb("#E53935")       // Red
#let avg-color-3 = rgb("#E06666")       // Light red
#let avg-color-4 = rgb("#E8725E")       // Red-orange
#let avg-color-5 = rgb("#ED9A56")       // Orange
#let avg-color-6 = rgb("#EFAD4E")       // Light orange
#let avg-color-7 = rgb("#E8B953")       // Orange-green
#let avg-color-8 = rgb("#D4B871")       // Green-orange
#let avg-color-9 = rgb("#B8B779")       // Light green-yellow
#let avg-color-10 = rgb("#A2B681")      // Green-yellow
#let avg-color-11 = rgb("#8CB589")      // Green
#let avg-color-12 = rgb("#78B491")      // Light green
#let avg-color-13 = rgb("#6BB199")      // Green 2
#let avg-color-max = rgb("#5FA76F")     // Dark green (5.00)
#let avg-font-color = rgb("#000000")    // Black text

#table(
  columns: (1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
  stroke: 1.5pt,
  align: center,
  inset: (x: 4pt, y: 15pt),
  table.cell(fill: personas-color, align: center + horizon)[
    #set par(justify: true)
    *Features*
    #v(0.2em)
    #line(length: 80%, stroke: 0.5pt)
    #v(0.2em)
    *Personas*
  ],
  table.cell(fill: col1-color, align: center + horizon)[
    #set par(justify: true)
    *Registro de camión, patente y capacidades*
  ],
  table.cell(fill: col2-color, align: center + horizon)[
    #set par(justify: true)
    *Publicado de ventanas de transporte*
  ],
  table.cell(fill: col3-color, align: center + horizon)[
    #set par(justify: true)
    *Publicado de pedidos de transporte*
  ],
  table.cell(fill: col4-color, align: center + horizon)[
    #set par(justify: true)
    *Búsqueda filtrada de pedidos de transporte*
  ],
  table.cell(fill: col5-color, align: center + horizon)[
    #set par(justify: true)
    *Pasarela de pago seguro*
  ],
  table.cell(fill: col6-color, align: center + horizon)[
    #set par(justify: true)
    *Historial de envíos*
  ],
  table.cell(fill: col7-color, align: center + horizon)[
    #set par(justify: true)
    *Tracking de envío*
  ],
  table.cell(fill: col8-color, align: center + horizon)[
    #set par(justify: true)
    *Reseñas*
  ],
  table.cell(fill: col9-color, align: center + horizon)[
    #set par(justify: true)
    *Viajes compuestos por múltiples envíos*
  ],
  table.cell(fill: col10-color, align: center + horizon)[
    #set par(justify: true)
    *Encadenado de pedidos*
  ],
  table.cell(fill: col11-color, align: center + horizon)[
    #set par(justify: true)
    *Gestión de venta de seguros*
  ],
  table.cell(fill: col12-color, align: center + horizon)[
    #set par(justify: true)
    *Mapping/Integración con GPS*
  ],

  table.cell(fill: personas-color)[Hugo (58 años)],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],

  table.cell(fill: personas-color)[Martín: hijo de Hugo.],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],

  table.cell(fill: personas-color)[Daniela Perez (señora de 55 años)],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★☆☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★☆☆☆☆]]],

  table.cell(fill: personas-color)[Florencia Scazzola (mujer de 40 años).],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★☆☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★☆☆☆☆]]],

  table.cell(fill: personas-color)[AgroTransport],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],

  table.cell(fill: personas-color)[Campos Giménez],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★☆☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★☆☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★☆☆☆☆]]],

  table.cell(fill: personas-color)[Average],
  table.cell(fill: avg-color-8)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[3.83]]],
  table.cell(fill: avg-color-max)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[5.00]]],
  table.cell(fill: avg-color-13)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[4.83]]],
  table.cell(fill: avg-color-10)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[4.00]]],
  table.cell(fill: avg-color-7)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[3.67]]],
  table.cell(fill: avg-color-6)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[3.50]]],
  table.cell(fill: avg-color-8)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[3.83]]],
  table.cell(fill: avg-color-10)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[4.00]]],
  table.cell(fill: avg-color-7)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[3.67]]],
  table.cell(fill: avg-color-min)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[2.67]]],
  table.cell(fill: avg-color-4)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[3.33]]],
  table.cell(fill: avg-color-2)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[3.00]]],
)
