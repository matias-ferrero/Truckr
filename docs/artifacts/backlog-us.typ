#import "../template.typ": conf
#show: conf

= Backlog — User Stories

#v(0.5em)
#text(size: 9pt, style: "italic")[
  Todas las historias siguen el framework de las 3 C's (Card, Conversation, Confirmation) y los criterios INVEST.
  Prioridades: Alta / Media / Baja. Cada historia indica a qué release pertenece.
]

// ═══════════════════════════════════════════════════════════════════════════
// MVP — Release 1
// ═══════════════════════════════════════════════════════════════════════════

#line(length: 100%, stroke: 1.5pt + rgb("#6AA84F"))
#align(center)[#text(
  weight: "bold",
  size: 12pt,
  fill: rgb("#6AA84F"),
)[MVP — Release 1]]
#line(length: 100%, stroke: 1.5pt + rgb("#6AA84F"))

// ── Cuenta ────────────────────────────────────────────────────────────────

== US1: Registrarse

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Cuenta

*Descripción:*
Como usuario (expedidor o transportista),
quiero poder registrarme en la plataforma,
para acceder a los servicios de Truckr y satisfacer mis necesidades de transporte.

*Criterios de Aceptación:*
+ Se pueden ingresar todos los datos necesarios: email, nombre completo y contraseña.
+ Si el email ya existe en el sistema, el registro falla y se muestra un mensaje de error claro.
+ La contraseña debe cumplir todos los siguientes requisitos; de lo contrario el registro falla con un mensaje indicando qué requisito no se cumple:
  - Tiene al menos 8 caracteres.
  - Incluye al menos una mayúscula (A–Z).
  - Incluye al menos una minúscula (a–z).
  - Incluye al menos un número (0–9).
+ Al completar el registro exitosamente, el usuario es redirigido al dashboard correspondiente a su rol.
+ Todos los campos del formulario son obligatorios y se validan antes de enviar.

== US2: Login

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Cuenta

*Descripción:*
Como usuario (expedidor o transportista),
quiero poder iniciar sesión en la plataforma,
para participar en ella con mi perfil y acceder a las funcionalidades.

*Criterios de Aceptación:*
+ El usuario puede loguearse correctamente ingresando email (o nombre de usuario) y contraseña válidos.
+ Si las credenciales son incorrectas, se muestra un mensaje de error genérico que no revela si el email existe o no.
+ Al loguearse exitosamente, el usuario es redirigido a la pantalla principal correspondiente a su rol (expedidor o transportista).
+ La sesión se mantiene activa mientras el usuario navega por la plataforma.
+ El usuario puede cerrar sesión desde cualquier pantalla mediante un botón visible.

== US3: Modificar Perfil

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Cuenta

*Descripción:*
Como usuario (expedidor o transportista),
quiero poder modificar mi perfil,
para completar y mantener actualizados mis datos personales.

*Criterios de Aceptación:*
+ Los campos de datos personales (y del camión, si es transportista) se pueden llenar y persisten en el formulario hasta que se guarden o descarten los cambios.
+ Al presionar "Guardar Cambios", los datos se impactan en el perfil del usuario y se muestra una confirmación.
+ Al presionar "Descartar Cambios" o navegar a otra página sin guardar, los datos escritos no se impactan en el perfil.
+ Los datos del perfil son visibles para otros usuarios en las secciones correspondientes (detalles de transportista, detalles de expedidor).
+ Se validan los campos obligatorios antes de permitir guardar (por ejemplo, datos del camión para transportistas).

// ── Plataforma del Expedidor ────────────────────────────────────────────────

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

== US6: Detalles de Transportista

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Buscar Transporte para mi Carga

*Descripción:*
Como expedidor,
quiero entrar al perfil del transportista responsable de una ventana compatible con mi carga,
para decidir si es el indicado antes de enviarle una oferta.

*Criterios de Aceptación:*
+ Se accede a esta pantalla desde un resultado de US4 y se conserva el contexto de la carga y de la ventana seleccionada.
+ Se muestran fotos y una descripción detallada del/los vehículos del transportista.
+ La información se carga correctamente y se presenta de forma clara y organizada.

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

== US8: Realizar Pago (Expedidor)

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Reservar Transportista

*Descripción:*
Como expedidor,
quiero poder pagar de forma segura una vez que el transportista aceptó mi envío,
para reservar el servicio y cumplir con mi parte del trato.

*Criterios de Aceptación:*
+ Una vez aceptado el envío por el transportista, se habilita la opción de realizar el pago.
+ Tras confirmar el pago, el envío se muestra al expedidor con la etiqueta «A recoger» (vista derivada del estado `accepted` más la presencia del pago en `escrowed`), sin que esto implique una transición del FSM de Shipment.
+ Una vez completado el pago, se otorgan los datos de contacto del transportista.
+ Si el pago falla, se muestra un mensaje de error y se permite reintentar sin perder el contexto de la oferta.
+ El monto del pago corresponde al precio acordado en la oferta aceptada.

// ── Plataforma del Transportista ──────────────────────────────────────────

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
+ Una vez completados los datos necesarios, se puede confirmar la publicación de la ventana.
+ La ventana aparece en los resultados de búsqueda de los expedidores cuya carga, ruta y fecha coincidan (US4 + US5).

== US10: Observar Ofertas de Envío

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Gestión de Envíos

*Descripción:*
Como transportista,
quiero poder observar un listado de ofertas de envío recibidas,
para evaluar y aceptar las que considere convenientes.

*Criterios de Aceptación:*
+ Una vez publicada una ventana de transporte (US9), se muestra un listado de ofertas realizadas por expedidores que coincidan con esa ventana.
+ Se puede entrar a los detalles de cada oferta para observar sus características (distancia, ubicación, volumen, peso, precio acordado, datos del expedidor).
+ Se muestra información resumida de cada oferta (origen, destino, fecha, precio) en el listado.
+ Cada oferta indica su estado (pendiente, aceptada, rechazada, cancelada) y la fecha en que fue recibida.

== US12: Aceptación de Oferta de Envío

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Aceptar Envío

*Descripción:*
Como transportista,
quiero poder aceptar una oferta de envío,
para comprometerme a realizarlo y generar ingresos.

*Criterios de Aceptación:*
+ Una vez seleccionada una oferta (US10), se puede aceptar mediante un botón claramente visible.
+ Al aceptar la oferta, se notifica al expedidor que su oferta fue aceptada y se habilita el flujo de pago (US8).
+ El envío aceptado aparece en la sección de "listado de envíos" del transportista (visible en el dashboard, US27).
+ Al aceptarse una oferta, las ofertas restantes de la carga asociada del expedidor, son canceladas.
+ Al aceptarse una oferta, automaticamente sera generado un envío en estado "pendiente de pago".

== US13: Realizar Envío (Navegación GPS)

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Aceptar Envío

*Descripción:*
Como transportista,
quiero poder navegar hacia el destino usando un mapa integrado,
para seguir la ruta óptima y completar el envío de forma eficiente.

*Criterios de Aceptación:*
+ Se integra con Google Maps para mostrar la ruta hacia el siguiente destino.
+ Se muestra la ubicación completa del siguiente destino (dirección de retiro o entrega).
+ Se puede ver el recorrido en tiempo real por GPS.
+ Se muestra la distancia y tiempo estimado de llegada al destino.
+ La navegación se actualiza si el transportista se desvía de la ruta.

== US14: Registro de Vehículo

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Cuenta

*Descripción:*
Como transportista,
quiero poder registrar mi camión con su patente y capacidades,
para que los expedidores conozcan las características de mi vehículo al buscarme.

*Criterios de Aceptación:*
+ Se puede ingresar la patente del camión.
+ Se pueden ingresar las dimensiones del camión (largo, ancho, alto del espacio de carga).
+ Se puede ingresar la capacidad de carga máxima en kilogramos.
+ Se pueden subir fotos del camión.
+ Se puede registrar más de un vehículo si el transportista tiene una flota.

== US15: Pago al Transportista

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Después del Envío

*Descripción:*
Como transportista,
quiero recibir el pago por los envíos concretados,
para cobrar por mi servicio de forma segura y en tiempo.

*Criterios de Aceptación:*
+ La plataforma se integra con Mercado Pago para gestionar los pagos.
+ Una vez concretado el envío (carga entregada), se efectúa la transferencia del pago al transportista.
+ El transportista puede ver el detalle de cada pago recibido (monto, envío asociado, fecha).
+ Si hay algún problema con la transferencia, se notifica al transportista.

== US17: Listado de Envíos

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Gestión de Envíos \
*Dependencias técnicas:* `REQ-BE-00022` (modelos de Fulfilment, mergeado); `REQ-FE-00017` / `REQ-BE-00024` (aceptación de oferta, PR #221, mergeado); `REQ-BE-00033` (US8 pago, en planificación para Sprint 3).

*Descripción (Transportista):*
Como transportista,
quiero ver el listado de envíos que estoy realizando o realicé,
para tener un registro de mi actividad y poder gestionar cada uno desde su detalle.

*Descripción (Expedidor):*
Como expedidor,
quiero ver el listado de envíos que contraté,
para hacer seguimiento del estado de cada uno y de sus pagos.

*Criterios de Aceptación:*
+ Existe una pantalla en `/carrier/shipments` accesible solo a transportistas autenticados que lista los `Shipment` donde el usuario es el transportista contratado. Si no hay envíos, se muestra un estado vacío con copy: «Aún no realizaste envíos. Aceptá una oferta para empezar.» (vía clave i18n).
+ Existe una pantalla en `/shipper/shipments` accesible solo a expedidores autenticados que lista los `Shipment` que el usuario contrató. Si no hay envíos, se muestra un estado vacío con copy: «Aún no contrataste envíos. Publicá una carga para empezar.» (vía clave i18n).
+ Cada fila del listado expone dos chips de estado independientes:
  + *Estado del envío* (`shipment.state`): uno de `Aceptado`, `En tránsito`, `Entregado`, `Cancelado` (claves i18n `shipment.state.*`). Estos son los únicos estados del `Shipment`; `pendiente de pago` y `a recoger` no son estados — son composiciones derivadas (ver siguiente AC).
  + *Estado del pago* (derivado de la relación con `Payment`): `Pendiente de pago` si no existe un `Payment` en estado `escrowed` para ese envío; `Pagado` si existe. El chip de pago se oculta cuando el envío está `Cancelado` (no aplica).
+ Cada fila muestra información resumida: origen, destino, fecha de creación, monto acordado, y los dos chips de estado.
+ Cada fila enlaza al detalle del envío (US39): `/carrier/shipments/:id` para el transportista, `/shipper/shipments/:id` para el expedidor.
+ El ordenamiento por defecto es por fecha de actividad más reciente (descendente).
+ Toda la copy de UI se resuelve por clave i18n; no hay literales en español hardcodeados en el componente.

*Fuera de alcance (Sprint 3 — derivar a un follow-up si surge la necesidad):*
+ Filtros por estado, búsqueda y paginación más allá del límite por defecto. Esta US entrega el listado plano.
+ Mapa de recorrido del envío en cada fila (corresponde a la US "marcar Recorrido" de Tomás cuando aterrice).

== US18: Actualización de Envío — Carga Retirada

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Aceptar Envío

*Descripción:*
Como transportista,
quiero poder marcar una carga como retirada,
para que el expedidor sepa que ya recogí su carga y el envío está en curso.

*Criterios de Aceptación:*
+ Al retirar la carga, el transportista puede marcarla como "en tránsito" con un botón.
+ Al expedidor se le muestra que el transportista ya recogió su carga en el estado del envío.
+ La fecha y hora del retiro quedan registradas en el sistema.
+ No se puede marcar como "en tránsito" un envío que aún no fue aceptado y pagado.

== US19: Actualización de Envío — Carga Entregada

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Aceptar Envío

*Descripción:*
Como transportista,
quiero poder marcar una carga como entregada,
para que el expedidor lo sepa y se concrete el pago del servicio.

*Criterios de Aceptación:*
+ Al entregar la carga, el transportista puede marcarla como "entregada" con un botón.
+ Al expedidor se le muestra el estado del envío como completado.
+ La confirmación de entrega dispara el proceso de transferencia de pago al transportista.
+ La fecha y hora de entrega quedan registradas en el sistema.
+ No se puede marcar como entregado un envío que no fue previamente marcado como "en tránsito".

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

== US36: Dashboard del Transportista

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Cuenta

*Descripción:*
Como transportista,
quiero ver un dashboard con un resumen de mi actividad al iniciar sesión,
para tener una vista general de mis ventanas, ofertas y envíos sin navegar por varias pantallas.

*Criterios de Aceptación:*
+ Al loguearse como transportista, se accede a un dashboard como pantalla principal.
+ Se muestra un listado de los vehiculos cargados por el transportista (US14).
+ Se muestra un resumen de las ventanas de transporte activas publicadas, la disponibilidad (US9).
+ Cada sección del dashboard enlaza a la pantalla detallada correspondiente.
+ Si el transportista no tiene actividad, cada sección muestra un estado vacío con una acción sugerida (por ejemplo, publicar una ventana o registrar un vehículo).

== US37: Dashboard del Expedidor

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Cuenta

*Descripción:*
Como expedidor,
quiero ver un dashboard con un resumen de mi actividad al iniciar sesión,
para hacer seguimiento de mis ofertas y envíos sin navegar por varias pantallas.

*Criterios de Aceptación:*
+ Al loguearse como expedidor, se accede a un dashboard como pantalla principal.
+ Se muestra un listado de las cargas publicadas (US27).
+ Se muestra un listado de las ofertas de retiro realizadas y su estado (pendiente, aceptada, rechazada) (US7).
+ Cada sección del dashboard enlaza a la pantalla detallada correspondiente.
+ Si el expedidor no tiene actividad, cada sección muestra un estado vacío con una acción sugerida (por ejemplo, buscar ventanas de transporte).

== US38: Landing Page

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Cuenta

*Descripción:*
Como visitante no registrado,
quiero acceder a una landing page que presente Truckr,
para entender qué ofrece la plataforma y decidir si me registro como expedidor o transportista.

*Criterios de Aceptación:*
+ La landing es la página pública de inicio y se muestra a cualquier visitante sin sesión iniciada.
+ Se presenta la propuesta de valor de Truckr y se explica cómo funciona para expedidores y para transportistas.
+ Hay llamados a la acción claros y visibles que llevan al registro (US1) y al login (US2).
+ La página es responsive y se visualiza correctamente en desktop y mobile.
+ Un usuario con sesión activa que ingresa a la landing es redirigido a la pantalla principal de su rol.

== US40: Bandeja de Usuarios

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Cuenta

*Descripción:*
Como usuario administrador,
quiero poder observar una lista de usuarios existentes en la aplicacion,
para permitirme administrarlos

*Criterios de Aceptación:*
+ Dentro del backoffice, hay un boton que me lleva a la solapa de Users
+ Una vez dentro de la pagina, tengo que poder observar la lista de usuarios existentes.

== US41: Personificar Usuario

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Cuenta

*Descripción:*
Como usuario administrador,
quiero personificar la cuenta de un usuario existente,
para meterme en ella y actuar como si fuera el.

*Criterios de Aceptación:*
+ Dentro la bandeja de usuarios, hay un boton que me redirige al dashboard de su cuenta.
+ Al hacerse la redireccion, no deba loguearme con sus datos y el inicio de sesion sea automatico.

== US42: Administrar mi Flota

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Cuenta

*Descripción:*
Como transportista,
quiero poder observar los camiones registrados en mi flota,
para poder administrar cada uno de ellos.

*Criterios de Aceptación:*
+ Al entrar a mi flota, debo poder observar cada uno de mis vehiculos registrados, con sus datos.
+ En la tarjeta del camion, debe haber un boton para entrar a modificar los datos.
+ En la tarjeta del camion, debe haber un boton para eliminar dicho vehiculo.

== US31: Editar Vehiculo de mi Flota

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Cuenta

*Descripción:*
Como transportista,
quiero poder modificar los datos de un vehículo de mi flota previamente registrado (US14),
para mantener actualizadas sus capacidades, fotos y dimensiones cuando cambien.

*Criterios de Aceptación:*
+ Desde el listado de vehículos del transportista, se puede acceder a una pantalla de edición del vehículo seleccionado.
+ Se pueden modificar dimensiones (largo, ancho, alto), capacidad de carga máxima en kilogramos, y agregar o quitar fotos del camión.
+ La patente no se puede modificar bajo ninguna circunstancia — el campo se muestra siempre deshabilitado.
+ Al guardar, los datos actualizados se reflejan inmediatamente en el perfil público del transportista (US6) y en los detalles visibles al expedidor en los resultados de búsqueda (US4).
+ Al presionar "Descartar Cambios" o navegar a otra página sin guardar, los datos escritos no se impactan.

== US32: Baja de Vehículo

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Cuenta

*Descripción:*
Como transportista,
quiero poder dar de baja un vehículo de mi flota,
para retirarlo del catálogo cuando lo vendí, deseché o ya no esté operativo.

*Criterios de Aceptación:*
+ Desde la pantalla "Mi Flota", cada entrada ofrece una acción de "Eliminar" claramente identificada.
+ Antes de confirmar la baja, se muestra un diálogo de confirmación.
+ Si el vehículo está asociado a una o más ventanas de transporte activas (US9), la baja se rechaza y se indica al usuario que debe primero dar de baja u ocultar dichas ventanas (US34, US35).
+ Si el vehículo está asociado a un envío en curso (aceptado y no entregado), la baja se rechaza y se explica el motivo.
+ El vehículo dado de baja deja de aparecer en el listado activo del transportista, pero sus datos se conservan a efectos del historial de envíos (US17) — los envíos pasados siguen mostrando el vehículo que los realizó.
+ El vehículo dado de baja deja de ser seleccionable al publicar nuevas ventanas de transporte.

== US43: Administrar mis Ventanas de Transporte

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Gestión de Envíos

*Descripción:*
Como transportista,
quiero poder ver mis ventanas de transporte en la plataforma,
para tener un registro de mis posibles envíos.

*Criterios de Aceptación:*
+ El transportista puede visualizar sus ventanas activas, junto con sus detalles.
+ Se observan botones para editarlas, ocultarlas o eliminarlas en cualquier momento.
+ En la pagina de Mi Disponibilidad, se encuentra un boton para poder publicar una nueva.

== US33: Editar Ventana de Transporte

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Gestión de Envíos

*Descripción:*
Como transportista,
quiero poder modificar los datos de una ventana de transporte que ya publiqué (US9),
para corregir errores o ajustarla a cambios en mi disponibilidad sin tener que republicarla.

*Criterios de Aceptación:*
+ Desde la pantalla "Mi Disponibilidad", se puede acceder a una pantalla de edición de la ventana seleccionada.
+ Se pueden modificar zona origen, zona destino, franja temporal (fecha/hora desde y hasta), vehículo asociado (entre los registrados en US14) y precio por kilómetro.
+ Al guardar, la ventana actualizada se refleja inmediatamente en los resultados de búsqueda de los expedidores (US4) según los nuevos criterios.
+ Si la ventana está asociada a un envío ya aceptado (US12), no se permite modificarla y se indica el motivo.
+ Al presionar "Descartar Cambios" o navegar a otra página sin guardar, los datos escritos no se impactan.

== US34: Eliminar Ventana de Transporte

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Gestión de Envíos

*Descripción:*
Como transportista,
quiero poder dar de baja definitivamente una ventana de transporte que publiqué,
para retirarla del sistema cuando ya no quiero recibir ofertas contra ella ni conservarla en mi listado.

*Criterios de Aceptación:*
+ Desde la pantalla "Mi Disponibilidad", cada entrada ofrece una acción de "Eliminar" claramente diferenciada de "Ocultar" (US35).
+ Antes de confirmar la baja, se muestra un diálogo de confirmación que aclara que la acción es irreversible y detalla las ofertas pendientes que se cancelarán.
+ Si la ventana tiene ofertas de envío pendientes (US10) sin aceptar, la baja las cancela automáticamente.
+ Si la ventana está asociada a un envío ya aceptado (US12), la baja se rechaza y se indica al transportista que debe completar o cancelar el envío primero.
+ La ventana dada de baja deja de aparecer en los resultados de búsqueda de los expedidores (US4) y en el listado activo del transportista.

== US35: Ocultar de Ventana de Transporte

*Release:* MVP \
*Prioridad:* Baja \
*Épica:* Gestión de Envíos

*Descripción:*
Como transportista,
quiero poder ocultar temporalmente una ventana de transporte sin darla de baja,
para dejar de recibir ofertas mientras evalúo cambios o resuelvo una indisponibilidad puntual, conservando la opción de reactivarla luego.

*Criterios de Aceptación:*
+ Desde la pantalla "Mi Disponibilidad", cada entrada ofrece una acción de "Ocultar" claramente diferenciada de "Eliminar" (US34).
+ Al ocultar la ventana, ésta deja de aparecer en los resultados de búsqueda de los expedidores (US4) pero permanece visible en el listado del transportista marcada como "Oculta".
+ Las ofertas pendientes recibidas previamente (US10) no se cancelan al ocultar — el transportista puede seguir aceptándolas o rechazándolas.
+ Desde la pantalla "Mi Disponibilidad", una ventana oculta ofrece una acción de "Reactivar" que la vuelve a publicar tal como estaba, sin necesidad de reingresar los datos.
+ El estado oculto persiste hasta que el transportista lo revierta explícitamente o dé de baja la ventana (US34).

== US44: Administrar Cargas

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Gestionar Cargas

*Descripción:*
Como expedidor,
quiero visualizar mis cargas creadas,
para poder administrar todas ellas.

*Criterios de Aceptación:*
+ El expedidor puede ver el listado de sus cargas publicadas, desde una sección "Mis cargas".
+ Se puede acceder a los detalles de una carga especifica, eliminarla o editarla.

== US45: Filtrar mis Cargas

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Gestionar Cargas

*Descripción:*
Como expedidor,
quiero poder filtrar mis cargas,
para poder observar mas rapido una de ellas.

*Criterios de Aceptación:*
+ En la sección "Mis cargas", se puede seleccionar un estado posible de carga.
+ El expedidor puede ver el listado de sus cargas publicadas que cumplan con dicho estado.

== US46: Ver Detalles de una Carga

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Gestionar Cargas

*Descripción:*
Como expedidor,
quiero entrar a los detalles mis cargas creadas,
para poder observar todas su informacion detallada.

*Criterios de Aceptación:*
+ El expedidor puede ver toda la informacion de dicha carga publicada.
+ Se pueden visualizar las ofertas enviadas a transportistas de dicha carga.

== US47: Editar Carga

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Cuenta

*Descripción:*
Como expedidor,
quiero poder modificar los datos de una carga,
para mantener actualizada su informacion en caso de ser necesario.

*Criterios de Aceptación:*
+ Desde el los detalles de una carga, se puede acceder a una pantalla de edición de la seleccionada.
+ Se pueden modificar descripcion, peso, volumen, valor declarado (en ARS), direccion de retiro.
+ Los campos obligatorios están claramente marcados y se validan antes de enviar el formulario; si falta uno o un valor es inválido se muestra un mensaje claro por campo.
+ Al guardar, los datos actualizados se reflejan inmediatamente en los detalles visibles de dicha carga.
+ Al presionar "Descartar Cambios" o navegar a otra página sin guardar, los datos escritos no se impactan.

== US48: Selector de Direcciones — Ventana de Transporte

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Gestión de Envíos \
*Dependencias técnicas:* Google Places JavaScript API (autocomplete + geocoding); migración que agrega `origin_lat`, `origin_lng`, `destination_lat`, `destination_lng` (todas `DECIMAL(9,6)`) a `transport_windows`. Las columnas son `NOT NULL` para `origin_*` y nullables para `destination_*` (el destino sigue siendo opcional según US9).

*Descripción:*
Como transportista,
quiero ingresar las direcciones de origen y destino de una ventana de transporte mediante un selector de direcciones geocodificadas en lugar de texto libre,
para que mis ventanas queden asociadas a ubicaciones reales validadas y los expedidores las puedan encontrar y filtrar por distancia con precisión.

*Criterios de Aceptación:*
+ El formulario de publicación de ventana (US9) y el de edición (US33) reemplazan los inputs de texto libre de las direcciones de origen y destino por un selector de direcciones (Google Places Autocomplete).
+ El selector está restringido a Argentina mediante `componentRestrictions: { country: 'ar' }` — no se ofrecen sugerencias fuera del país. No hay verificación adicional server-side (no bounding box, no reverse-geocode) — la restricción UI es suficiente para el alcance del MVP académico.
+ Al confirmar una sugerencia, el formulario captura tres datos por dirección: el texto formateado (para mostrar al usuario), y el par `lat` / `lng` con precisión `DECIMAL(9,6)` (para indexar y consultar).
+ El backend rechaza la creación o edición de una ventana cuyo `origin_lat` / `origin_lng` esté ausente o sea inválido (HTTP 422 con clave i18n). El destino se acepta sin pin solo si el campo de dirección destino también está vacío.
+ La pantalla muestra un pequeño preview del mapa con el pin del origen seleccionado (y del destino si está presente), como confirmación visual antes de guardar.
+ Toda la copy del selector (placeholder, error, vacío) se resuelve por clave i18n; no hay literales en español hardcodeados.
+ Si la API de Google Places no responde o devuelve un error, el formulario muestra un mensaje accionable («No se pudo cargar el selector — recargá la página o probá de nuevo más tarde») y bloquea el envío hasta que se elija una dirección válida.

== US49: Selector de Direcciones — Carga

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Gestionar Cargas \
*Dependencias técnicas:* Google Places JavaScript API (autocomplete + geocoding); migración que agrega `pickup_lat`, `pickup_lng`, `delivery_lat`, `delivery_lng` (todas `DECIMAL(9,6)`, `NOT NULL`) a `cargos`. Comparte el componente FE de selector con US48.

*Descripción:*
Como expedidor,
quiero ingresar las direcciones de retiro y entrega de una carga mediante un selector de direcciones geocodificadas en lugar de texto libre,
para que mi carga quede asociada a ubicaciones reales validadas y matchee con las ventanas correctas en US4 / US5.

*Criterios de Aceptación:*
+ El formulario de publicación de carga (US27) y el de edición (US47) reemplazan los inputs de texto libre de las direcciones de retiro y entrega por un selector de direcciones (Google Places Autocomplete).
+ El selector reutiliza el componente FE definido en US48 (mismo restricción `country: 'ar'`, mismo formato de captura `texto + lat + lng DECIMAL(9,6)`, mismo manejo de error de Google Places).
+ Al confirmar una sugerencia, el formulario captura tres datos por dirección: el texto formateado, y el par `lat` / `lng`.
+ El backend rechaza la creación o edición de una carga cuyos `pickup_lat` / `pickup_lng` o `delivery_lat` / `delivery_lng` estén ausentes o inválidos (HTTP 422 con clave i18n).
+ La pantalla muestra un pequeño preview del mapa con los pines de retiro y entrega seleccionados, como confirmación visual antes de guardar.
+ Toda la copy del selector se resuelve por clave i18n; no hay literales en español hardcodeados.

== US50: Definir Radio de Recogida

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Gestión de Envíos \
*Dependencias técnicas:* US48 (pin geocodificado en el origen); migración que agrega `pickup_radius_km` (`INTEGER`, `NOT NULL`, default razonable propuesto: 10) a `transport_windows`. Glossary: ver «Radio de recogida». El uso del radio en el filtrado de US5 está cubierto por el AC nuevo de US5 (Haversine en código de aplicación).

*Descripción:*
Como transportista,
quiero definir un radio de recogida alrededor del origen de mi ventana de transporte (en kilómetros),
para expresar cuánto estoy dispuesto a desviarme para retirar una carga y que el sistema solo me muestre / ofrezca cargas dentro de ese radio.

*Criterios de Aceptación:*
+ En el formulario de publicación de ventana (US9), un nuevo campo numérico «Radio de recogida (km)» permite ingresar un valor entero entre 1 y un máximo razonable (ej. 200); valor por defecto sugerido: 10 km.
+ Acompañando al campo numérico, el preview del mapa de origen (introducido por US48) renderiza un círculo arrastrable centrado en el pin del origen; arrastrar el borde del círculo actualiza el valor numérico y viceversa (los dos controles están sincronizados).
+ El valor del radio se persiste en `pickup_radius_km` y se valida server-side: rechazo HTTP 422 con clave i18n si está fuera del rango permitido o si falta.
+ El radio es editable a posteriori desde el formulario de US33 «Editar Ventana de Transporte» — misma UI, mismo rango.
+ Cambiar el radio (hacia arriba o hacia abajo) NO invalida ni cancela ninguna `CargoOffer` ya existente en estado `pending` contra esta ventana. El radio es un filtro de descubrimiento (US5), no una restricción retroactiva sobre compromisos ya hechos.
+ Toda la copy del control (label, placeholder, mensaje de validación) se resuelve por clave i18n.

== US51: Mapa y Enlaces a Google Maps en Detalle de Envío

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Gestión de Envíos \
*Dependencias técnicas:* US39 (pantalla de detalle de envío — debe estar mergeada antes); pines geocodificados de US48 + US49 disponibles en los modelos `TransportWindow` y `Cargo` que el envío referencia transitivamente. Google Maps JavaScript API (mismo billing setup que US48 / US49).

*Descripción (Expedidor):*
Como expedidor,
quiero ver un mapa con los pines de origen y destino de mi envío y poder abrir cada uno en Google Maps con un toque,
para validar visualmente el recorrido sin salir de la app y para navegar a cualquiera de los dos puntos con la app de Maps cuando lo necesite (por ejemplo, ir a esperar la carga).

*Descripción (Transportista):*
Como transportista,
quiero ver un mapa con los pines de origen y destino del envío y poder abrir cada uno en Google Maps con un toque,
para orientarme visualmente antes de salir y navegar al punto de retiro o entrega usando la app nativa de Google Maps sin tener que reingresar la dirección.

*Criterios de Aceptación:*
+ En la pantalla de detalle de envío (US39), reemplaza la sección reservada «Se mostrará el mapa cuando esté disponible» por un mapa estático (no interactivo más allá del zoom + pan estándar) con dos pines: origen (verde) y destino (rojo), centrado para mostrar ambos.
+ Debajo (o al costado, según el layout) del mapa, dos botones bien diferenciados: «Abrir origen en Google Maps» y «Abrir destino en Google Maps». Cada botón dispara la URL deep-link `https://www.google.com/maps/dir/?api=1&destination=<lat>,<lng>` con las coordenadas correspondientes, en una nueva pestaña / la app nativa según el dispositivo.
+ Si por alguna razón los pines no están disponibles (caso defensivo — no debería pasar porque US48 / US49 los hacen `NOT NULL`), la sección muestra un mensaje neutral con clave i18n y no rompe el resto del detalle.
+ El mapa y los botones son visibles en cualquier estado del envío (`accepted` / `in_transit` / `delivered` / `cancelled`); los datos de origen y destino no cambian con el estado.
+ Toda la copy (labels de pines, texto de botones, mensaje defensivo) se resuelve por clave i18n.
+ Los componentes `<ShipmentMap />` y `<OpenInGmapsButton />` se entregan como piezas reusables y testeadas (Vitest + 1 spec Playwright cubriendo el golden path) — pueden montarse en futuras pantallas (ej. preview de detalle de oferta) sin retrabajo.

// ═══════════════════════════════════════════════════════════════════════════
// Post MVP — Release 2
// ═══════════════════════════════════════════════════════════════════════════

#line(length: 100%, stroke: 1.5pt + rgb("#6AA84F"))
#align(center)[#text(
  weight: "bold",
  size: 12pt,
  fill: rgb("#6AA84F"),
)[Post MVP — Release 2]]
#line(length: 100%, stroke: 1.5pt + rgb("#6AA84F"))

== US11: Filtrado de Ofertas de Envío

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Gestión de Envíos

*Descripción:*
Como transportista,
quiero poder filtrar las ofertas de envío recibidas,
para encontrar rápidamente las que mejor se ajusten a mi disponibilidad y preferencias.

*Criterios de Aceptación:*
+ Se puede filtrar por ubicación de origen de la carga.
+ Se puede filtrar por rango de fecha de retiro.
+ Se puede filtrar por peso de la carga a transportar.
+ Se puede filtrar por volumen de la carga a transportar.
+ Al borrar un filtro, se resetea y aparecen todas las ofertas disponibles.
+ Los filtros se pueden combinar entre sí.

== US16: Cambiar Contraseña

*Release:* Release 2 \
*Prioridad:* Media \
*Épica:* Cuenta

*Descripción:*
Como usuario (expedidor o transportista),
quiero poder cambiar mi contraseña,
para mantener la seguridad de mi cuenta.

*Criterios de Aceptación:*
+ Se solicita la contraseña actual antes de permitir el cambio.
+ La nueva contraseña debe cumplir los mismos requisitos de seguridad que en el registro.
+ Se pide confirmar la nueva contraseña ingresándola dos veces.
+ Al cambiar la contraseña exitosamente, se muestra un mensaje de confirmación.
+ Si la contraseña actual es incorrecta, se muestra un mensaje de error y no se permite el cambio.

== US20: Reseñas

*Release:* Release 2 \
*Prioridad:* Media \
*Épica:* Después del Envío

*Descripción:*
Como expedidor,
quiero poder escribir y leer reseñas sobre los transportistas,
para compartir mi experiencia y consultar las de otros antes de contratar un servicio.

*Criterios de Aceptación:*
+ Un expedidor puede escribir una reseña sobre un transportista una vez que el envío se completó.
+ La reseña incluye una puntuación (por ejemplo, 1 a 5 estrellas) y un comentario de texto.
+ Las reseñas de un transportista son visibles en su perfil para todos los usuarios.
+ Se muestra el promedio de puntuación del transportista junto a las reseñas individuales.
+ Un expedidor solo puede dejar una reseña por envío completado.

// ═══════════════════════════════════════════════════════════════════════════
// Post MVP — Release 3
// ═══════════════════════════════════════════════════════════════════════════

#line(length: 100%, stroke: 1.5pt + rgb("#6AA84F"))
#align(center)[#text(
  weight: "bold",
  size: 12pt,
  fill: rgb("#6AA84F"),
)[Post MVP — Release 3]]
#line(length: 100%, stroke: 1.5pt + rgb("#6AA84F"))

== US21: Tracking de Envío

*Release:* Release 2 \
*Prioridad:* Media \
*Épica:* Gestión de Envíos

*Descripción:*
Como expedidor,
quiero poder hacer seguimiento de mi envío en tiempo real,
para saber dónde está mi carga y cuándo llegará.

*Criterios de Aceptación:*
+ Se muestra la ubicación del transportista en un mapa en tiempo real mientras el envío está en curso.
+ Se muestra el estado actual del envío (pendiente de retiro, en tránsito, entregado).
+ Se muestra una estimación del tiempo restante de llegada.
+ El tracking solo está disponible para envíos que fueron aceptados y pagados.
+ La información se actualiza periódicamente sin que el expedidor deba refrescar la página.

== US22: Verificación de Cuenta por Email

*Release:* Release 3 \
*Prioridad:* Media \
*Épica:* Cuenta

*Descripción:*
Como usuario (expedidor o transportista),
quiero verificar mi cuenta mediante un email de confirmación,
para asegurar que mi email es válido y aumentar la confianza en la plataforma.

*Criterios de Aceptación:*
+ Al registrarse, el usuario recibe un email con un enlace de verificación.
+ Al hacer click en el enlace, la cuenta queda verificada y se muestra una confirmación.
+ El enlace de verificación tiene una expiración (por ejemplo, 24 horas).
+ Si el enlace expiró, el usuario puede solicitar el reenvío del email de verificación.
+ Las cuentas verificadas se distinguen visualmente de las no verificadas en la plataforma.

== US23: Envíos Compuestos (Múltiples Envíos)

*Release:* Release 3 \
*Prioridad:* Baja \
*Épica:* Gestión de Envíos

*Descripción:*
Como transportista,
quiero poder agrupar múltiples envíos en un solo envío,
para optimizar la carga y maximizar los ingresos por recorrido.

*Criterios de Aceptación:*
+ El transportista puede aceptar múltiples ofertas de envío y agruparlas en un envío compuesto.
+ Se muestra la ruta optimizada que contempla todos los puntos de retiro y entrega.
+ Cada expedidor puede ver el estado de su envío individual dentro del envío compuesto.
+ Se valida que la capacidad del vehículo no sea excedida por la suma de los envíos agrupados.
+ El transportista puede ver un resumen con todos los envíos del envío, sus estados y destinos.

== US24: Encadenado de Pedidos

*Release:* Release 3 \
*Prioridad:* Baja \
*Épica:* Gestión de Envíos

*Descripción:*
Como transportista,
quiero poder encadenar pedidos en una ruta continua,
para realizar envíos largos recogiendo y entregando cargas a lo largo del camino.

*Criterios de Aceptación:*
+ El transportista puede seleccionar múltiples pedidos que se encadenan en una ruta secuencial.
+ Se muestra la ruta completa con todos los puntos de retiro y entrega en orden.
+ Se estima la fecha de entrega de cada carga según la posición en la cadena.
+ El sistema sugiere pedidos compatibles con la ruta actual del transportista.
+ Cada expedidor es notificado de la fecha estimada de entrega según la cadena planificada.

== US25: Gestión de Seguros

*Release:* Release 3 \
*Prioridad:* Baja \
*Épica:* Reservar Transportista

*Descripción:*
Como expedidor,
quiero poder contratar un seguro para mi envío al momento de reservar el transporte,
para proteger mi carga en caso de daño o pérdida durante el envío.

*Criterios de Aceptación:*
+ Al confirmar una oferta de retiro, se ofrece la opción de contratar un seguro para el envío.
+ Se muestran las opciones de seguro disponibles con su cobertura y precio.
+ El costo del seguro se suma al total del pago.
+ En caso de siniestro, el expedidor puede iniciar un reclamo desde la plataforma.
+ El detalle del seguro contratado es visible en el historial del envío.

== US26: Editar o Eliminar Reseña

*Release:* Release 3 \
*Prioridad:* Baja \
*Épica:* Después del Envío

*Descripción:*
Como expedidor,
quiero poder editar o eliminar una reseña que hice previamente,
para corregir mi opinión si cambié de parecer o cometí un error.

*Criterios de Aceptación:*
+ El expedidor puede editar el texto y la puntuación de una reseña que realizó.
+ El expedidor puede eliminar una reseña que realizó.
+ Al editar una reseña, se indica visualmente que fue modificada (por ejemplo, "editada").
+ Al eliminar una reseña, se recalcula el promedio de puntuación del transportista.
+ Se pide confirmación antes de eliminar una reseña.
