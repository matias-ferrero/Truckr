#import "../template.typ": conf
#show: conf

#set page(flipped: true, paper: "a3", margin: (x: 0.5cm, y: 0.8cm))

= Features Matrix

_Observación: - Verde: Planificadas para el MVP - Rojo: Posible Mejora_

#table(
  columns: (1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr, 1fr),
  stroke: 0.5pt,
  align: center,
  inset: (x: 4pt, y: 15pt),
  table.cell(align: center + horizon)[
    #set par(justify: true)
    *Features*
    #v(0.2em)
    #line(length: 80%, stroke: 0.5pt)
    #v(0.2em)
    *Personas*
  ],
  table.cell(align: center + horizon)[
    #set par(justify: true)
    *Registro de camión, patente y capacidades*
  ],
  table.cell(align: center + horizon)[
    #set par(justify: true)
    *Publicado de ventanas de transporte*
  ],
  table.cell(align: center + horizon)[
    #set par(justify: true)
    *Publicado de pedidos de transporte*
  ],
  table.cell(align: center + horizon)[
    #set par(justify: true)
    *Búsqueda filtrada de pedidos de transporte*
  ],
  table.cell(align: center + horizon)[
    #set par(justify: true)
    *Pasarela de pago seguro*
  ],
  table.cell(align: center + horizon)[
    #set par(justify: true)
    *Historial de envíos*
  ],
  table.cell(align: center + horizon)[
    #set par(justify: true)
    *Tracking de envío*
  ],
  table.cell(align: center + horizon)[
    #set par(justify: true)
    *Reseñas*
  ],
  table.cell(align: center + horizon)[
    #set par(justify: true)
    *Viajes compuestos por múltiples envíos*
  ],
  table.cell(align: center + horizon)[
    #set par(justify: true)
    *Encadenado de pedidos*
  ],
  table.cell(align: center + horizon)[
    #set par(justify: true)
    *Gestión de venta de seguros*
  ],
  table.cell(align: center + horizon)[
    #set par(justify: true)
    *Mapping/Integración con GPS*
  ],

  [Hugo (58 años)], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★☆☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★☆☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★☆☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]],
  [Martín: hijo de Hugo.], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★☆☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★☆☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★☆☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]],
  [Daniela Perez (señora de 55 años)], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★☆☆☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★☆☆☆☆]]],
  [Florencia Scazzola (mujer de 40 años).], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★☆☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★☆☆☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★☆☆☆☆]]],
  [AgroTransport], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]],
  [Campos Giménez], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★☆☆☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★☆☆☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★☆☆☆☆]]],
  [Average], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★★]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★★☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★☆☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]], [#align(center)[#text(size: 17pt, font: "DejaVu Sans")[★★★☆☆]]],
)
