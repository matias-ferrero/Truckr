#import "../template.typ": conf
#show: conf

= Es / No Es / Hace / No Hace

#table(
  columns: (1fr, 1fr),
  stroke: 0.5pt,
  align: left,
  [*Es*], [*No Es*],
  [- Una plataforma de conexión entre transportistas y productores/clientes
- Un sitio web y potencialmente una app mobile], [- Una empresa de traslado de personas
- Una plataforma de compra/venta de bienes
- Una consultora de transportes
- Una red social],
  [*Hace*], [*No Hace*],
  [- Permite publicar ventanas de transporte
- Permite publicar bienes a transportar
- Registra la ubicación y capacidades de los vehículos transportistas
- Ofrece planificación de rutas más rapidas y GPS
- Ofrece una pasarela de pagos seguros
- Ofrece contratación de seguros
- Lleva historial de envíos
- Ofrece tracking de envíos
- Integración fiscal con ARCA], [- No ofrece la compra del producto a transportar
- No permite devolver el producto en caso de disconformidad
- No ofrece traslado de personas
- No ofrece servicio de mensajería],
)
