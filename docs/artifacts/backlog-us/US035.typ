== US35: Ocultar de Ventana de Transporte

*Release:* MVP \
*Prioridad:* Baja \
*Épica:* Gestión de Envíos

*Descripción:*
Como transportista,
quiero poder ocultar temporalmente una ventana de transporte sin darla de baja,
para dejar de recibir ofertas mientras evalúo cambios o resuelvo una indisponibilidad puntual, conservando la opción de reactivarla luego.

*Criterios de Aceptación:*
+ Desde la pantalla "Mi Disponibilidad", cada entrada ofrece una acción de "Ocultar" claramente diferenciada de "Eliminar" (US34).
+ Al ocultar la ventana, ésta deja de aparecer en los resultados de búsqueda de los expedidores (US4) pero permanece visible en el listado del transportista marcada como "Oculta".
+ Las ofertas pendientes recibidas previamente (US10) no se cancelan al ocultar — el transportista puede seguir aceptándolas o rechazándolas.
+ Desde la pantalla "Mi Disponibilidad", una ventana oculta ofrece una acción de "Reactivar" que la vuelve a publicar tal como estaba, sin necesidad de reingresar los datos.
+ El estado oculto persiste hasta que el transportista lo revierta explícitamente o dé de baja la ventana (US34).
