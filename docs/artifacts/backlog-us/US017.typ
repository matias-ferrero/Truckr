== US17: Listado de Envíos

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Gestión de Envíos \
*Dependencias técnicas:* `REQ-BE-00022` (modelos de Fulfilment, mergeado); `REQ-FE-00017` / `REQ-BE-00024` (aceptación de oferta, PR #221, mergeado); `REQ-BE-00033` (US8 pago, en planificación para Sprint 3).

*Descripción (Transportista):*
Como transportista,
quiero ver el listado de envíos que estoy realizando o realicé,
para tener un registro de mi actividad y poder gestionar cada uno desde su detalle.

*Descripción (Expedidor):*
Como expedidor,
quiero ver el listado de envíos que contraté,
para hacer seguimiento del estado de cada uno y de sus pagos.

*Criterios de Aceptación:*
+ Existe una pantalla en `/carrier/shipments` accesible solo a transportistas autenticados que lista los `Shipment` donde el usuario es el transportista contratado. Si no hay envíos, se muestra un estado vacío con copy: «Aún no realizaste envíos. Aceptá una oferta para empezar.» (vía clave i18n).
+ Existe una pantalla en `/shipper/shipments` accesible solo a expedidores autenticados que lista los `Shipment` que el usuario contrató. Si no hay envíos, se muestra un estado vacío con copy: «Aún no contrataste envíos. Publicá una carga para empezar.» (vía clave i18n).
+ Cada fila del listado expone dos chips de estado independientes:
  + *Estado del envío* (`shipment.state`): uno de `Aceptado`, `En tránsito`, `Entregado`, `Cancelado` (claves i18n `shipment.state.*`). Estos son los únicos estados del `Shipment`; `pendiente de pago` y `a recoger` no son estados — son composiciones derivadas (ver siguiente AC).
  + *Estado del pago* (derivado de la relación con `Payment`): `Pendiente de pago` si no existe un `Payment` en estado `escrowed` para ese envío; `Pagado` si existe. El chip de pago se oculta cuando el envío está `Cancelado` (no aplica).
+ Cada fila muestra información resumida: origen, destino, fecha de creación, monto acordado, y los dos chips de estado.
+ Cada fila enlaza al detalle del envío (US39): `/carrier/shipments/:id` para el transportista, `/shipper/shipments/:id` para el expedidor.
+ El ordenamiento por defecto es por fecha de actividad más reciente (descendente).
+ Toda la copy de UI se resuelve por clave i18n; no hay literales en español hardcodeados en el componente.

*Fuera de alcance (Sprint 3 — derivar a un follow-up si surge la necesidad):*
+ Filtros por estado, búsqueda y paginación más allá del límite por defecto. Esta US entrega el listado plano.
+ Mapa de recorrido del envío en cada fila (corresponde a la US "marcar Recorrido" de Tomás cuando aterrice).
