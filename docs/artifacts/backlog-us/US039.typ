== US39: Detalles de Envío

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Gestión de Envíos \
*Dependencias técnicas:* `REQ-BE-00022` (modelos de Fulfilment, mergeado); endpoint `GET /api/shipments/:id` (parte de la BE issue de Sprint 3, junto con los índices del listado).

*Descripción (Transportista):*
Como transportista,
quiero entrar al detalle de un envío que estoy realizando o realicé,
para ver toda su información, su estado actual y las acciones que puedo tomar (marcar carga retirada, marcar entregada).

*Descripción (Expedidor):*
Como expedidor,
quiero entrar al detalle de un envío que contraté,
para ver toda su información, su estado y el del pago, y las acciones disponibles (reintentar pago si falló, cancelar si aún no está pagado).

*Criterios de Aceptación:*
+ La pantalla de detalle es alcanzable desde el listado (US17). Rutas: `/carrier/shipments/:id` para el transportista, `/shipper/shipments/:id` para el expedidor. Un usuario no puede acceder al detalle de un envío que no le pertenece — el backend responde HTTP 404 si quien consulta no es la contraparte.
+ La pantalla muestra los datos del envío: origen, destino, descripción y peso de la carga, vehículo asignado (placa, tipo), contraparte (nombre del transportista o del expedidor según el rol que mira), fecha de creación y monto acordado.
+ La pantalla muestra los dos chips de estado independientes definidos en US17 (`shipment.state` + estado de pago derivado de `Payment`).
+ La pantalla muestra el historial de `TrackingEvent` asociados al envío en forma de timeline textual (timestamp + tipo de evento). El mapa visual de origen y destino queda explícitamente fuera de alcance en esta US — se aterriza vía US51 «Mapa y Enlaces a Google Maps en Detalle de Envío». En su ausencia, una sección reservada con copy «Se mostrará el mapa cuando esté disponible» (clave i18n).
+ Acciones contextuales según el estado actual y el rol del usuario:
  + Transportista, envío en `accepted` + pagado: botón «Marcar carga retirada» (dispara la transición de US18).
  + Transportista, envío en `in_transit`: botón «Marcar entregada» (dispara la transición de US19).
  + Expedidor, envío en `accepted` + sin pago en `escrowed`: botón «Reintentar pago» (dispara el flujo de US8). La cancelación pre-pago está diferida a Sprint 4+ (decisión Q3 del triage 2026-05-24); no se ofrece en esta US.
  + Expedidor, envío en `accepted` + pagado: no se ofrece cancelación (interlock — refund/dispute fuera de MVP per ADR-012).
  + Envío en `delivered` o `cancelled`: la pantalla es solo lectura, sin acciones.
+ Toda la copy de UI se resuelve por clave i18n; no hay literales en español hardcodeados en el componente.

*Fuera de alcance (Sprint 3 — derivar a un follow-up si surge la necesidad):*
+ Mapa de origen / destino + enlaces «Abrir en Google Maps» (US51, Sprint 4).
+ Reseñas / calificaciones desde el detalle (US15 / US16).
