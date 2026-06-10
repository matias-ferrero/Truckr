== US67: Navegación Lateral Persistente por Rol

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Navegación

*Descripción:*
Como expedidor o transportista,
quiero una barra de navegación lateral persistente que muestre las secciones propias de mi rol,
para moverme entre las áreas de la aplicación desde cualquier pantalla sin depender del encabezado.

*Criterios de Aceptación:*
+ Una vez iniciada la sesión, la barra de navegación lateral está presente de forma persistente en las pantallas de la aplicación.
+ La barra muestra únicamente las secciones que corresponden al rol del usuario: el transportista ve sus vehículos, disponibilidad, ofertas, envíos y pagos; el expedidor ve su panel, cargas y envíos. Un usuario con ambos roles ve los dos grupos diferenciados.
+ "Mis Pagos" deja de estar en el encabezado y pasa a la barra lateral del transportista.
+ Sobre la sección de ofertas del transportista se muestra el contador de ofertas pendientes.
+ La sección activa se distingue visualmente del resto de las secciones.
+ Un visitante sin sesión no ve la barra lateral.
