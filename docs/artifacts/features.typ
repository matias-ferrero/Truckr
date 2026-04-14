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

// Average row color scale (smooth gradient red -> green)
#let avg-color-0 = rgb("#C5221F")
#let avg-color-1 = rgb("#D32F2F")
#let avg-color-2 = rgb("#E53935")
#let avg-color-3 = rgb("#E06666")
#let avg-color-4 = rgb("#E8725E")
#let avg-color-5 = rgb("#ED9A56")
#let avg-color-6 = rgb("#F1C232")
#let avg-color-7 = rgb("#B8D89F")
#let avg-color-8 = rgb("#A8D08E")
#let avg-color-9 = rgb("#98C87D")
#let avg-color-10 = rgb("#88C06C")
#let avg-color-11 = rgb("#78B85B")
#let avg-color-12 = rgb("#68B04A")
#let avg-color-13 = rgb("#5A9F44")
#let avg-color-14 = rgb("#4C8E3E")
#let avg-font-color = rgb("#000000")

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

  table.cell(fill: personas-color)[Hugo Fernandez (64 años)],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],

  table.cell(fill: personas-color)[Martín Fernandez (32 años)],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],

  table.cell(fill: personas-color)[AgroTransport],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],

  table.cell(fill: personas-color)[Juan Martinez (41 años)],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★☆☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],

  table.cell(fill: personas-color)[Carolina Souza (35 años)],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],

  table.cell(fill: personas-color)[Manuel Ramos (52 años)],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
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

  table.cell(fill: personas-color)[Sofía Carrasco (24 años)],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★☆☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★★★★]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[☆☆☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★★☆☆☆]]],
  table.cell(fill: data-color)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: data-font-color)[★☆☆☆☆]]],

  table.cell(fill: personas-color)[Average],
  table.cell(fill: avg-color-10)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[3.90]]],
  table.cell(fill: avg-color-12)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[4.70]]],
  table.cell(fill: avg-color-11)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[4.20]]],
  table.cell(fill: avg-color-10)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[4.10]]],
  table.cell(fill: avg-color-9)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[3.80]]],
  table.cell(fill: avg-color-9)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[3.60]]],
  table.cell(fill: avg-color-10)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[4.00]]],
  table.cell(fill: avg-color-9)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[3.70]]],
  table.cell(fill: avg-color-7)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[3.20]]],
  table.cell(fill: avg-color-7)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[3.11]]],
  table.cell(fill: avg-color-8)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[3.30]]],
  table.cell(fill: avg-color-8)[#align(center)[#text(size: 17pt, font: "DejaVu Sans", fill: avg-font-color)[3.40]]],

)
