== US4: Búsqueda de Ventanas Compatibles con mi Carga

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Buscar Transporte para mi Carga

*Descripción:*
Como expedidor,
quiero ver el listado de ventanas de transporte compatibles con una carga que publiqué,
para identificar qué transportistas están en condiciones de realizar mi envío y poder enviarles una oferta de carga.

*Criterios de Aceptación:*
+ Se accede a esta pantalla desde la pantalla de detalle de una carga publicada (US27).
+ El listado muestra únicamente las ventanas en estado abierta cuya franja temporal intersecta el rango de fecha de retiro indicado.
+ El listado muestra únicamente las ventanas cuyo origen está a una distancia menor o igual al radio de retiro declarado por el transportista respecto del origen de la carga, y, si tuviese destino, también está dentro del mismo radio respecto del destino de la carga.
+ El listado muestra únicamente las ventanas cuyo vehículo asociado tiene capacidad disponible mayor o igual al peso de la carga.
+ Cada resultado muestra origen, destino, franja de fechas, resumen del transportista responsable y del vehículo asociado, precio por kilómetro de referencia y costo estimado total para la carga (precio por kilómetro × distancia estimada).
+ En caso de existir muchas ventanas compatibles, los resultados se muestran paginados.
+ Se puede navegar al detalle del transportista responsable (US6) preservando el contexto de la carga y de la ventana seleccionada.
+ Desde cada fila se puede navegar directamente a la pantalla de oferta con la carga y la ventana ya en contexto.
+ Si no hay ventanas compatibles, se muestra un mensaje claro indicándolo y se sugiere revisar el filtro de fecha o el origen/destino de la carga.
