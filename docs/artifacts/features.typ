#import "template.typ": conf
#show: conf

= Features Matrix

_Observación:
- Verde: Planificadas para el MVP
- Rojo: Posible Mejora_

#table(
  columns: (auto, auto, auto, auto, auto, auto, auto, auto, auto, auto, auto, auto),
  stroke: 0.5pt,
  align: center,
  [*Persona*], [*Registro de camión, patente y capacidades*], [*Publicado de ventanas de transporte*], [*Publicado de pedidos de transporte*], [*Búsqueda filtrada de pedidos de transporte*], [*Pasarela de pago seguro*], [*Historial de envíos*], [*Tracking de envío*], [*Reseñas*], [*Viajes compuestos por múltiples envíos*], [*Encadenado de pedidos*], [*Gestión de venta de seguros*],
  [Hugo (58 años)], [4], [5], [5], [5], [2], [3], [2], [3], [5], [3], [2],
  [Martín: hijo de Hugo.], [5], [5], [5], [5], [3], [2], [2], [4], [5], [5], [2],
  [Daniela Perez (señora de 55 años)], [3], [5], [5], [3], [5], [4], [5], [5], [3], [1], [4],
  [Florencia Scazzola (mujer de 40 años).], [2], [5], [5], [3], [5], [4], [5], [5], [3], [1], [4],
  [AgroTransport], [5], [5], [5], [5], [4], [5], [5], [4], [5], [5], [3],
  [Campos Giménez], [3], [5], [4], [3], [3], [3], [4], [3], [1], [1], [5],
  [*Average*], [*3.67*], [*5*], [*4.83*], [*4*], [*3.67*], [*3.5*], [*3.83*], [*4*], [*3.67*], [*2.67*], [*3.33*],
)
