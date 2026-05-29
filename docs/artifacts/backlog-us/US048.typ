== US48: Selector de Direcciones — Ventana de Transporte

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Gestión de Envíos

*Descripción:*
Como transportista,
quiero ingresar las direcciones de origen y destino de una ventana de transporte mediante un selector de direcciones reales en lugar de texto libre,
para que mis ventanas queden asociadas a ubicaciones reales validadas y los expedidores las puedan encontrar y filtrar por distancia con precisión.

*Criterios de Aceptación:*
+ El formulario de publicación de ventana (US9) y el de edición (US33) reemplazan los inputs de texto libre de las direcciones de origen y destino por un selector de direcciones.
+ El selector está restringido a Argentina mediante.
+ Se rechaza la creación o edición de una ventana con direcciones inválidas.
+ Se muestra un pequeño preview del mapa con el pin del origen seleccionado (y del destino si está presente), como confirmación visual antes de guardar.
