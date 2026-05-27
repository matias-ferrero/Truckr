== US5: Fitrar Ventanas Compatibles

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Buscar Transporte para mi Carga

*Descripción:*
Como expedidor,
quiero filtrar el listado de ventanas compatibles con mi carga (US4),
para priorizar las opciones que mejor se ajustan a mi presupuesto o urgencia.

*Criterios de Aceptación:*
+ Se puede filtrar por precio por kilómetro máximo, ocultando las ventanas cuyo precio por kilómetro supere el valor indicado.
+ El expedidor puede acotar el listado con un filtro opcional de fecha de retiro mínima y máxima.
+ Se puede ordenar por precio estimado total (ascendente / descendente).
+ Se puede ordenar por fecha de inicio de la ventana (más próxima primero).
+ Se puede ordenar por distancia entre el origen de la carga y el origen de la ventana (más cercano primero), calculada por Haversine en código de aplicación sobre los pines geocodificados de US48 y US49 (nunca PostGIS, por la política SQLite-forever).
+ El listado de ventanas compatibles excluye automáticamente aquellas cuyo origen está a más de `pickup_radius_km` del pickup de la carga del expedidor (ver US50). Esto se aplica antes de cualquier filtro adicional del expedidor; no es un filtro opcional ni configurable desde esta pantalla.
+ Los filtros y el orden seleccionado se pueden combinar entre sí.
+ Al borrar un filtro seleccionado se reinicia el listado al conjunto completo de ventanas compatibles (sin abandonar el contexto de la carga).
