== US32: Baja de Vehículo

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Cuenta

*Descripción:*
Como transportista,
quiero poder dar de baja un vehículo de mi flota,
para retirarlo del catálogo cuando lo vendí, deseché o ya no esté operativo.

*Criterios de Aceptación:*
+ Desde la pantalla "Mi Flota", cada entrada ofrece una acción de "Eliminar" claramente identificada.
+ Antes de confirmar la baja, se muestra un diálogo de confirmación.
+ Si el vehículo está asociado a una o más ventanas de transporte activas (US9), la baja se rechaza y se indica al usuario que debe primero dar de baja u ocultar dichas ventanas (US34, US35).
+ Si el vehículo está asociado a un envío en curso (aceptado y no entregado), la baja se rechaza y se explica el motivo.
+ El vehículo dado de baja deja de aparecer en el listado activo del transportista, pero sus datos se conservan a efectos del historial de envíos (US17) — los envíos pasados siguen mostrando el vehículo que los realizó.
+ El vehículo dado de baja deja de ser seleccionable al publicar nuevas ventanas de transporte.
