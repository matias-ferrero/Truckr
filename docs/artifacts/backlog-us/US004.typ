== US4: Búsqueda de Ventanas Compatibles con mi Carga

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Reservar Transportista

*Descripción:*
Como expedidor,
quiero ver el listado de ventanas de transporte compatibles con una carga que publiqué,
para identificar qué transportistas están en condiciones de realizar mi envío y poder enviarles una oferta de carga.

*Criterios de Aceptación:*
+ Se realiza una búsqueda de ventana solo con la carga publicada sin enviar
+ Se realizan búsquedas de ventanas compatibles con la carga publicada por el expedidor, considerando:
  - La ventana debe estar en estado abierta.
  - La franja temporal de la ventana debe intersectar el rango de fecha de retiro indicado por el expedidor.
  - El origen de la ventana debe estar a una distancia menor o igual al radio de retiro declarado por el transportista respecto del origen de la carga, y, si tuviese destino, también debe estar dentro del mismo radio respecto del destino de la carga.
  - El vehículo asociado a la ventana debe tener capacidad disponible mayor o igual al peso de la carga.
+ Cada resultado muestra los datos de la carga, de la ventana de transporte, y el precio del envío.
+ En caso de existir muchas ventanas compatibles, los resultados se muestran paginados.
+ El expedidor puede seleccionar una ventana compatible para enviarle una oferta de carga.
+ Se informa al expedidor en caso de no existir ventanas compatibles con la carga publicada.
