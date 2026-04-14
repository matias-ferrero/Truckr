#import "../template.typ": conf
#show: conf

= Es / No Es / Hace / No Hace

#table(
  columns: (1fr, 1fr),
  stroke: 0.5pt,
  inset: 8pt,
  [#align(center + horizon)[*Es*]], [#align(center + horizon)[*No Es*]],
  [#align(left + horizon)[
    - Una plataforma de conexión entre transportistas y productores/clientes
    - Un sitio web y potencialmente una app mobile
  ]],
  [#align(left + horizon)[
    - Una empresa de traslado de personas
    - Una plataforma de compra/venta de bienes
    - Una consultora de transportes
    - Una red social
  ]],

  [#align(center + horizon)[*Hace*]], [#align(center + horizon)[*No Hace*]],
  [#align(left + horizon)[
    - Permite publicar ventanas de transporte
    - Permite publicar bienes a transportar
    - Registra la ubicación y capacidades de los vehículos transportistas
    - Ofrece planificación de rutas más rapidas y GPS
    - Ofrece una pasarela de pagos seguros
    - Ofrece contratación de seguros
    - Lleva historial de envíos
    - Ofrece tracking de envíos
    - Integración fiscal con ARCA
  ]],
  [#align(left + horizon)[
    - No ofrece la compra del producto a transportar
    - No permite devolver el producto en caso de disconformidad
    - No ofrece traslado de personas
    - No ofrece servicio de mensajería
  ]],
)
