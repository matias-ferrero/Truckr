== US48: Selector de Direcciones — Ventana de Transporte

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Gestión de Envíos \
*Dependencias técnicas:* Google Places JavaScript API (autocomplete + geocoding); migración que agrega `origin_lat`, `origin_lng`, `destination_lat`, `destination_lng` (todas `DECIMAL(9,6)`) a `transport_windows`. Las columnas son `NOT NULL` para `origin_*` y nullables para `destination_*` (el destino sigue siendo opcional según US9).

*Descripción:*
Como transportista,
quiero ingresar las direcciones de origen y destino de una ventana de transporte mediante un selector de direcciones geocodificadas en lugar de texto libre,
para que mis ventanas queden asociadas a ubicaciones reales validadas y los expedidores las puedan encontrar y filtrar por distancia con precisión.

*Criterios de Aceptación:*
+ El formulario de publicación de ventana (US9) y el de edición (US33) reemplazan los inputs de texto libre de las direcciones de origen y destino por un selector de direcciones (Google Places Autocomplete).
+ El selector está restringido a Argentina mediante `componentRestrictions: { country: 'ar' }` — no se ofrecen sugerencias fuera del país. No hay verificación adicional server-side (no bounding box, no reverse-geocode) — la restricción UI es suficiente para el alcance del MVP académico.
+ Al confirmar una sugerencia, el formulario captura tres datos por dirección: el texto formateado (para mostrar al usuario), y el par `lat` / `lng` con precisión `DECIMAL(9,6)` (para indexar y consultar).
+ El backend rechaza la creación o edición de una ventana cuyo `origin_lat` / `origin_lng` esté ausente o sea inválido (HTTP 422 con clave i18n). El destino se acepta sin pin solo si el campo de dirección destino también está vacío.
+ La pantalla muestra un pequeño preview del mapa con el pin del origen seleccionado (y del destino si está presente), como confirmación visual antes de guardar.
+ Toda la copy del selector (placeholder, error, vacío) se resuelve por clave i18n; no hay literales en español hardcodeados.
+ Si la API de Google Places no responde o devuelve un error, el formulario muestra un mensaje accionable («No se pudo cargar el selector — recargá la página o probá de nuevo más tarde») y bloquea el envío hasta que se elija una dirección válida.
