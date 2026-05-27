== US34: Eliminar Ventana de Transporte

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Gestión de Envíos

*Descripción:*
Como transportista,
quiero poder dar de baja definitivamente una ventana de transporte que publiqué,
para retirarla del sistema cuando ya no quiero recibir ofertas contra ella ni conservarla en mi listado.

*Criterios de Aceptación:*
+ Desde la pantalla "Mi Disponibilidad", cada entrada ofrece una acción de "Eliminar" claramente diferenciada de "Ocultar" (US35).
+ Antes de confirmar la baja, se muestra un diálogo de confirmación que aclara que la acción es irreversible y detalla las ofertas pendientes que se cancelarán.
+ Si la ventana tiene ofertas de envío pendientes (US10) sin aceptar, la baja las cancela automáticamente.
+ Si la ventana está asociada a un envío ya aceptado (US12), la baja se rechaza y se indica al transportista que debe completar o cancelar el envío primero.
+ La ventana dada de baja deja de aparecer en los resultados de búsqueda de los expedidores (US4) y en el listado activo del transportista.
