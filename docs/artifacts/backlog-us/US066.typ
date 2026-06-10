== US66: Detalle de Envío Centrado en la Acción

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Envíos

*Descripción:*
Como expedidor o transportista,
quiero que el detalle de un envío (US39) priorice la acción que me corresponde según su estado y mi rol por sobre el resto de la información,
para saber qué hacer a continuación sin tener que recorrer toda la pantalla.

*Criterios de Aceptación:*
+ El detalle muestra de forma destacada y fija la acción principal disponible para quien lo mira según el estado del envío: el expedidor paga o reintenta el pago, el transportista confirma el retiro o la entrega.
+ Cuando el envío no tiene acción para ese rol en ese estado, ese mismo lugar muestra el estado actual en términos de qué se está esperando, en vez de un botón inactivo.
+ El detalle nombra a la contraparte por su rol real (transportista o expedidor) y enlaza a su reputación pública.
+ Al confirmar el pago se muestra el monto a pagar y se aclara que el dinero queda retenido hasta confirmar la entrega.
+ Una vez entregado, el transportista ve el estado de su liquidación (acreditada o en proceso) en lugar de acciones.
+ El acceso al mapa y a la navegación (US51) prioriza el punto que corresponde al estado: retiro mientras la carga no fue recogida, entrega mientras está en tránsito.
+ La información se reorganiza en columnas en pantallas anchas y se apila en una sola columna en pantallas chicas, dejando atrás el desplazamiento vertical único.
