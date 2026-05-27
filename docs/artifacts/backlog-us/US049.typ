== US49: Selector de Direcciones — Carga

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Gestionar Cargas \
*Dependencias técnicas:* Google Places JavaScript API (autocomplete + geocoding); migración que agrega `pickup_lat`, `pickup_lng`, `delivery_lat`, `delivery_lng` (todas `DECIMAL(9,6)`, `NOT NULL`) a `cargos`. Comparte el componente FE de selector con US48.

*Descripción:*
Como expedidor,
quiero ingresar las direcciones de retiro y entrega de una carga mediante un selector de direcciones geocodificadas en lugar de texto libre,
para que mi carga quede asociada a ubicaciones reales validadas y matchee con las ventanas correctas en US4 / US5.

*Criterios de Aceptación:*
+ El formulario de publicación de carga (US27) y el de edición (US47) reemplazan los inputs de texto libre de las direcciones de retiro y entrega por un selector de direcciones (Google Places Autocomplete).
+ El selector reutiliza el componente FE definido en US48 (mismo restricción `country: 'ar'`, mismo formato de captura `texto + lat + lng DECIMAL(9,6)`, mismo manejo de error de Google Places).
+ Al confirmar una sugerencia, el formulario captura tres datos por dirección: el texto formateado, y el par `lat` / `lng`.
+ El backend rechaza la creación o edición de una carga cuyos `pickup_lat` / `pickup_lng` o `delivery_lat` / `delivery_lng` estén ausentes o inválidos (HTTP 422 con clave i18n).
+ La pantalla muestra un pequeño preview del mapa con los pines de retiro y entrega seleccionados, como confirmación visual antes de guardar.
+ Toda la copy del selector se resuelve por clave i18n; no hay literales en español hardcodeados.
