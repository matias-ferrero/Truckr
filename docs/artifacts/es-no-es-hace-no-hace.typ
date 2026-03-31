#import "../template.typ": conf
#show: conf

= Es / No Es / Hace / No Hace

#table(
  columns: (1fr, 1fr),
  align: left,
  [*Es*], [*No Es*],
  [
    - Una plataforma de conexión entre transportistas y productores/clientes
    - Un sitio web y potencialmente una app mobile
  ],
  [
    - Una empresa de traslado de personas
    - Una plataforma de compra/venta de bienes
    - Una consultora de transportes
  ],

  [*Hace*], [*No Hace*],
  [
    - permite publicar ventanas de transporte
    - permite publicar bienes a transportar
    - registra la ubicación y capacidades de los vehículos transportistas
    - ofrece una pasarela de pagos seguros
    - lleva historial de envíos
    - ofrece tracking de envíos
    - integración fiscal con ARCA
  ],
  [
    - No ofrece la compra del producto a transportar
    - No permite devolver el producto en caso de disconformidad
    - No se hace responsable de daños ocurridos durante el transporte
    - No ofrece servicio de grúa
    - No ofrece planificación de ruta
    - No ofrece traslado de personas
    - No ofrece servicio de mensajería
  ],
)
