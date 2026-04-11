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
    *Persona*
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

  [Hugo (58 años)], [5], [5], [5], [5], [2], [3], [2], [3], [5], [3], [2], [5],
  [Martín: hijo de Hugo.], [5], [5], [5], [5], [3], [2], [2], [4], [5], [5], [2], [5],
  [Daniela Perez (señora de 55 años)], [3], [5], [5], [3], [5], [4], [5], [5], [3], [1], [4], [1],
  [Florencia Scazzola (mujer de 40 años).], [2], [5], [5], [3], [5], [4], [5], [5], [3], [1], [4], [1],
  [AgroTransport], [5], [5], [5], [5], [4], [5], [5], [4], [5], [5], [3], [5],
  [Campos Giménez], [3], [5], [4], [3], [3], [3], [4], [3], [1], [1], [5], [1],
  [Average], [3.83], [5], [4.83], [4], [3.67], [3.5], [3.83], [4], [3.67], [2.67], [3.33], [3],
)
