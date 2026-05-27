== US27: Publicar Carga

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Gestionar Cargas

*Descripción:*
Como expedidor,
quiero publicar una carga con toda su informacion detallada,
para poder enviarla.

*Criterios de Aceptación:*
+ Se ingresan las direcciones de origen (retiro) y destino (entrega) mediante el selector de direcciones geocodificadas (US49); el formulario persiste tanto el texto formateado de cada dirección como su pin (`pickup_lat` / `pickup_lng`, `delivery_lat` / `delivery_lng`).
+ Se puede ingresar el peso de la carga en kilogramos (debe ser mayor a cero).
+ Se puede ingresar una descripción de la carga a transportar.
+ Los campos obligatorios están claramente marcados y se validan antes de enviar el formulario; si falta uno o un valor es inválido se muestra un mensaje claro por campo.
+ Solo los expedidores autenticados pueden publicar una carga; un transportista logueado no ve la opción.
+ Al publicar exitosamente, la carga queda en estado abierta (sin ofertas asociadas todavía).
+ Al publicar exitosamente, el expedidor debe poder navegar a los detalles de la carga o iniciar la búsqueda de ventanas de transporte compatibles (US4).
