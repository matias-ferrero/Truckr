== US7: Ofertar Retiro de una Carga

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Reservar Transportista

*Descripción:*
Como expedidor,
quiero enviar una oferta al transportista responsable de una ventana compatible con mi carga,
para contactarlo y que decida si acepta realizar el envío.

*Criterios de Aceptación:*
+ Para publicar una oferta, se debe tener una carga en estado abierta y una ventana en estado abierta ya seleccionadas.
+ En la publicación de la oferta, se define una fecha de retiro de la carga.
+ Se puede ingresar un mensaje opcional dirigido al transportista.
+ El monto de la oferta se calcula como el precio por kilómetro de la ventana por la distancia del traslado y se muestra antes de confirmar.
+ Al confirmar, se crea una oferta de carga en estado pendiente asociada a la carga, a la ventana, al transportista y al vehículo de la ventana.
+ Al confirmar, el monto de la oferta queda congelado.
+ Se informa visiblemente que la oferta expira automáticamente a las 48 horas de enviada si el transportista no responde.
+ Tras confirmar, el expedidor regresa al detalle de la carga, donde la nueva oferta aparece en el listado de ofertas de la carga con su estado actual; la oferta también aparece en su dashboard (US37).
+ El expedidor puede volver a ofertar a otras ventanas abiertas compatibles de la misma carga.
