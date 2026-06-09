== US48: Selector de Direcciones — Ventana de Transporte

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Ventanas de Transporte

*Descripción:*
Como transportista,
quiero ingresar las direcciones de origen y destino de una ventana de transporte mediante un selector de direcciones,
para que mis ventanas queden asociadas a ubicaciones reales validadas.

*Criterios de Aceptación:*
+ El formulario de publicación de ventana (US9) y el de edición (US33) ahora tienen un selector de direcciones.
+ El selector está restringido a Argentina mediante.
+ Se rechaza la creación o edición de una ventana con direcciones inválidas.
+ Se muestra un pequeño preview del mapa con el pin del origen seleccionado (y del destino si está presente), como confirmación visual antes de guardar.
