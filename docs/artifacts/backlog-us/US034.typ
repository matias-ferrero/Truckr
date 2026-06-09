== US34: Eliminar Ventana de Transporte

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Ventanas de Transporte

*Descripción:*
Como transportista,
quiero poder dar de baja definitivamente una ventana de transporte que publiqué,
para retirarla del sistema cuando ya no quiero recibir ofertas contra ella ni conservarla en mi listado.

*Criterios de Aceptación:*
+ Antes de confirmar la baja, se necesita confirmación.
+ Si la ventana tiene ofertas de envío pendientes sin aceptar, la baja las cancela automáticamente.
+ Si la ventana está asociada a un envío ya aceptado pero no terminado, la baja se rechaza.
+ La ventana dada de baja deja de aparecer en los resultados de búsqueda de los expedidores y en el listado activo del transportista.
