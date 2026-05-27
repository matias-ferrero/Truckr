== US50: Definir Radio de Recogida

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Gestión de Envíos \
*Dependencias técnicas:* US48 (pin geocodificado en el origen); migración que agrega `pickup_radius_km` (`INTEGER`, `NOT NULL`, default razonable propuesto: 10) a `transport_windows`. Glossary: ver «Radio de recogida». El uso del radio en el filtrado de US5 está cubierto por el AC nuevo de US5 (Haversine en código de aplicación).

*Descripción:*
Como transportista,
quiero definir un radio de recogida alrededor del origen de mi ventana de transporte (en kilómetros),
para expresar cuánto estoy dispuesto a desviarme para retirar una carga y que el sistema solo me muestre / ofrezca cargas dentro de ese radio.

*Criterios de Aceptación:*
+ En el formulario de publicación de ventana (US9), un nuevo campo numérico «Radio de recogida (km)» permite ingresar un valor entero entre 1 y un máximo razonable (ej. 200); valor por defecto sugerido: 10 km.
+ Acompañando al campo numérico, el preview del mapa de origen (introducido por US48) renderiza un círculo arrastrable centrado en el pin del origen; arrastrar el borde del círculo actualiza el valor numérico y viceversa (los dos controles están sincronizados).
+ El valor del radio se persiste en `pickup_radius_km` y se valida server-side: rechazo HTTP 422 con clave i18n si está fuera del rango permitido o si falta.
+ El radio es editable a posteriori desde el formulario de US33 «Editar Ventana de Transporte» — misma UI, mismo rango.
+ Cambiar el radio (hacia arriba o hacia abajo) NO invalida ni cancela ninguna `CargoOffer` ya existente en estado `pending` contra esta ventana. El radio es un filtro de descubrimiento (US5), no una restricción retroactiva sobre compromisos ya hechos.
+ Toda la copy del control (label, placeholder, mensaje de validación) se resuelve por clave i18n.
