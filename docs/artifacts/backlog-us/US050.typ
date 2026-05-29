== US50: Definir Radio de Recogida

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Gestión de Envíos

*Descripción:*
Como transportista,
quiero definir un radio de recogida alrededor del origen de mi ventana de transporte (en kilómetros),
para expresar cuánto estoy dispuesto a desviarme para retirar una carga y que el sistema solo me muestre / ofrezca cargas dentro de ese radio.

*Criterios de Aceptación:*
+ En el formulario de publicación de ventana (US9), hay un campo numérico «Radio de recogida (km)» que permite ingresar un valor entero entre 1 y 200 km, con un valor por defecto de 10 km.
+ Acompañando al campo numérico, en el preview del mapa de origen (introducido por US48) se renderiza un círculo arrastrable centrado en el pin del origen.
+ El círculo actualiza el valor numérico y viceversa (los dos controles están sincronizados).
+ El radio es editable a posteriori desde el formulario de US33 «Editar Ventana de Transporte» — misma UI, mismo rango.
+ Cambiar el radio (hacia arriba o hacia abajo) NO invalida ni cancela ninguna oferta de carga ya existente en estado ACEPTADA contra esta ventana. El radio es un filtro de descubrimiento (US5), no una restricción retroactiva sobre compromisos ya hechos.
