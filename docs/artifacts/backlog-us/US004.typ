== US4: Búsqueda de Ventanas Compatibles con mi Carga (REHACER)

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Buscar Transporte para mi Carga

*Descripción:*
Como expedidor,
quiero ver el listado de ventanas de transporte compatibles con una carga que publiqué,
para identificar qué transportistas están en condiciones de realizar mi envío y poder enviarles una oferta de carga.

*Criterios de Aceptación:*
+ Se accede a esta pantalla desde la pantalla de detalle de una carga publicada (US27).
+ El listado muestra únicamente las ventanas en estado abierta cuya franja temporal intersecta el rango de fecha de retiro indicado; si el expedidor no indica fecha mínima se asume la fecha actual sin mostrarla, y si no indica máxima no se aplica tope superior.
+ El listado muestra únicamente las ventanas cuyo origen está a una distancia menor o igual al radio de retiro declarado por el transportista respecto del origen de la carga, y cuyo destino también está dentro del mismo radio respecto del destino de la carga.
+ El listado muestra únicamente las ventanas cuyo vehículo asociado tiene capacidad disponible mayor o igual al peso de la carga.
+ Cada resultado muestra origen, destino, franja de fechas, resumen del transportista responsable y del vehículo asociado, precio por kilómetro de referencia y costo estimado total para la carga (precio por kilómetro × distancia estimada).
+ En caso de existir muchas ventanas compatibles, los resultados se muestran paginados.
+ Se puede navegar al detalle del transportista responsable (US6) preservando el contexto de la carga y de la ventana seleccionada.
+ Cada fila incluye una acción "Ofertar" que lleva directamente a US7 con la carga y la ventana ya en contexto.
+ Si la carga ya tiene ofertas pendientes contra otras ventanas, se muestra un contador visible ("Ofertas pendientes: N") para que el expedidor recuerde sus propuestas en curso.
+ Si no hay ventanas compatibles, se muestra un mensaje claro indicándolo y se sugiere revisar el filtro de fecha o el origen/destino de la carga.
