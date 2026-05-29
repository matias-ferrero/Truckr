== US9: Publicar Ventana de Transporte

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Gestión de Envíos

*Descripción:*
Como transportista,
quiero publicar una ventana de transporte en la plataforma,
para que los expedidores cuya carga coincida con mi ruta y fecha me encuentren y me ofrezcan envíos.

*Criterios de Aceptación:*
+ Se debe indicar la dirección origen desde donde el transportista partirá, ingresada mediante el selector de direcciones geocodificadas (US48); el formulario persiste tanto el texto de la dirección como el pin (`origin_lat` / `origin_lng`).
+ Se puede indicar la dirección destino a la que el transportista desea llegar (si no la indica, el destino puede ser variable según el envío); cuando se indica, también se ingresa mediante el selector de direcciones (US48) y se persiste el pin (`destination_lat` / `destination_lng`).
+ Se debe indicar la franja temporal (fecha y hora desde / hasta) en la que la ventana está vigente.
+ Se debe asociar uno de los vehículos previamente registrados por el transportista (US14).
+ Se puede indicar un precio por kilómetro para el servicio.
+ Se debe indicar el radio de recogida del origen (`pickup_radius_km`) que el transportista está dispuesto a desviarse para retirar cargas — ver US50.
+ Cuando el destino está definido (no es destino abierto), se debe indicar también el radio de entrega (`dropoff_radius_km`) que el transportista está dispuesto a desviarse para entregar cargas — ver US52. Cuando el destino es abierto, este campo queda oculto y se persiste `NULL`.
+ Una vez completados los datos necesarios, se puede confirmar la publicación de la ventana.
+ La ventana aparece en los resultados de búsqueda de los expedidores cuya carga, ruta y fecha coincidan (US4 + US5).
