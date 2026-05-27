== US51: Mapa y Enlaces a Google Maps en Detalle de Envío

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Gestión de Envíos \
*Dependencias técnicas:* US39 (pantalla de detalle de envío — debe estar mergeada antes); pines geocodificados de US48 + US49 disponibles en los modelos `TransportWindow` y `Cargo` que el envío referencia transitivamente. Google Maps JavaScript API (mismo billing setup que US48 / US49).

*Descripción (Expedidor):*
Como expedidor,
quiero ver un mapa con los pines de origen y destino de mi envío y poder abrir cada uno en Google Maps con un toque,
para validar visualmente el recorrido sin salir de la app y para navegar a cualquiera de los dos puntos con la app de Maps cuando lo necesite (por ejemplo, ir a esperar la carga).

*Descripción (Transportista):*
Como transportista,
quiero ver un mapa con los pines de origen y destino del envío y poder abrir cada uno en Google Maps con un toque,
para orientarme visualmente antes de salir y navegar al punto de retiro o entrega usando la app nativa de Google Maps sin tener que reingresar la dirección.

*Criterios de Aceptación:*
+ En la pantalla de detalle de envío (US39), reemplaza la sección reservada «Se mostrará el mapa cuando esté disponible» por un mapa estático (no interactivo más allá del zoom + pan estándar) con dos pines: origen (verde) y destino (rojo), centrado para mostrar ambos.
+ Debajo (o al costado, según el layout) del mapa, dos botones bien diferenciados: «Abrir origen en Google Maps» y «Abrir destino en Google Maps». Cada botón dispara la URL deep-link `https://www.google.com/maps/dir/?api=1&destination=<lat>,<lng>` con las coordenadas correspondientes, en una nueva pestaña / la app nativa según el dispositivo.
+ Si por alguna razón los pines no están disponibles (caso defensivo — no debería pasar porque US48 / US49 los hacen `NOT NULL`), la sección muestra un mensaje neutral con clave i18n y no rompe el resto del detalle.
+ El mapa y los botones son visibles en cualquier estado del envío (`accepted` / `in_transit` / `delivered` / `cancelled`); los datos de origen y destino no cambian con el estado.
+ Toda la copy (labels de pines, texto de botones, mensaje defensivo) se resuelve por clave i18n.
+ Los componentes `<ShipmentMap />` y `<OpenInGmapsButton />` se entregan como piezas reusables y testeadas (Vitest + 1 spec Playwright cubriendo el golden path) — pueden montarse en futuras pantallas (ej. preview de detalle de oferta) sin retrabajo.

// ═══════════════════════════════════════════════════════════════════════════
