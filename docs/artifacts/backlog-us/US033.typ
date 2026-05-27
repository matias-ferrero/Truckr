== US33: Editar Ventana de Transporte

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Gestión de Envíos

*Descripción:*
Como transportista,
quiero poder modificar los datos de una ventana de transporte que ya publiqué (US9),
para corregir errores o ajustarla a cambios en mi disponibilidad sin tener que republicarla.

*Criterios de Aceptación:*
+ Desde la pantalla "Mi Disponibilidad", se puede acceder a una pantalla de edición de la ventana seleccionada.
+ Se pueden modificar zona origen, zona destino, franja temporal (fecha/hora desde y hasta), vehículo asociado (entre los registrados en US14) y precio por kilómetro.
+ Al guardar, la ventana actualizada se refleja inmediatamente en los resultados de búsqueda de los expedidores (US4) según los nuevos criterios.
+ Si la ventana está asociada a un envío ya aceptado (US12), no se permite modificarla y se indica el motivo.
+ Al presionar "Descartar Cambios" o navegar a otra página sin guardar, los datos escritos no se impactan.
