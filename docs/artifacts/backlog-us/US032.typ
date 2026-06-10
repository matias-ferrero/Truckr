== US32: Baja de Vehículo

*Release:* MVP \
*Prioridad:* Baja \
*Épica:* Cuenta

*Descripción:*
Como transportista,
quiero poder dar de baja un vehículo de mi flota,
para retirarlo del catálogo cuando lo vendí, deseché o ya no esté operativo.

*Criterios de Aceptación:*
+ Cada vehículo ofrece una opción para ser dado de baja.
+ Antes de confirmar la baja, se necesita confirmación.
+ Si el vehículo está asociado a una o más ventanas de transporte activas, la baja se rechaza hasta que se den de baja u oculten dichas ventanas.
+ Si el vehículo está asociado a un envío en curso (aceptado y no entregado), la baja se rechaza.
+ El vehículo dado de baja deja de aparecer en el listado activo del transportista, pero sus datos se conservan a efectos del historial de datos.
+ El vehículo dado de baja deja de ser seleccionable al publicar nuevas ventanas de transporte.
