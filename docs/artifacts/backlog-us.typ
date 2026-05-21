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
para identificar qué transportistas están en condiciones de realizar mi viaje y poder enviarles una oferta de carga.

*Criterios de Aceptación:*
+ Se accede a esta pantalla desde la pantalla de detalle de una carga publicada (US27).
+ El expedidor puede acotar el listado con un filtro opcional de fecha de retiro mínima y máxima.
+ El listado muestra únicamente las ventanas en estado abierta cuya franja temporal intersecta el rango de fecha de retiro indicado; si el expedidor no indica fecha mínima se asume la fecha actual sin mostrarla, y si no indica máxima no se aplica tope superior.
+ El listado muestra únicamente las ventanas cuyo origen está a una distancia menor o igual al radio de retiro declarado por el transportista respecto del origen de la carga, y cuyo destino también está dentro del mismo radio respecto del destino de la carga.
+ El listado muestra únicamente las ventanas cuyo vehículo asociado tiene capacidad disponible mayor o igual al peso de la carga.
+ Cada resultado muestra origen, destino, franja de fechas, resumen del transportista responsable y del vehículo asociado, precio por kilómetro de referencia y costo estimado total para la carga (precio por kilómetro × distancia estimada).
+ En caso de existir muchas ventanas compatibles, los resultados se muestran paginados.
+ Al hacer click sobre el resumen de una ventana, se navega al detalle del transportista responsable (US6) preservando el contexto de la carga y de la ventana seleccionada.
+ Cada fila incluye una acción "Ofertar" que lleva directamente a US7 con la carga y la ventana ya en contexto.
+ Si la carga ya tiene ofertas pendientes contra otras ventanas, se muestra un contador visible ("Ofertas pendientes: N") para que el expedidor recuerde sus propuestas en curso.
+ Si no hay ventanas compatibles, se muestra un mensaje claro indicándolo y se sugiere revisar el filtro de fecha o el origen/destino de la carga.

== US5: Refinar Ventanas Compatibles

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Buscar Transporte para mi Carga

*Descripción:*
Como expedidor,
quiero refinar el listado de ventanas compatibles con mi carga (US4),
para priorizar las opciones que mejor se ajustan a mi presupuesto o urgencia.

*Criterios de Aceptación:*
+ Se puede filtrar por precio por kilómetro máximo, ocultando las ventanas cuyo precio por kilómetro supere el valor indicado.
+ Se puede ordenar por precio estimado total (ascendente / descendente).
+ Se puede ordenar por fecha de inicio de la ventana (más próxima primero).
+ Se puede ordenar por distancia entre el origen de la carga y el origen de la ventana (más cercano primero).
+ Los filtros y el orden seleccionado se pueden combinar entre sí.
+ Al borrar un filtro seleccionado se reinicia el listado al conjunto completo de ventanas compatibles (sin abandonar el contexto de la carga).

== US6: Detalles de Transportista

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Buscar Transporte para mi Carga

*Descripción:*
Como expedidor,
quiero entrar al detalle del transportista responsable de una ventana compatible con mi carga,
para decidir si es el indicado antes de enviarle una oferta de carga.

*Criterios de Aceptación:*
+ Se accede a esta pantalla desde un resultado de US4 y se conserva el contexto de la carga y de la ventana seleccionada.
+ Se muestran fotos y una descripción detallada del/los vehículos del transportista.
+ Se muestra el resumen de la ventana seleccionada (origen, destino, franja de fechas, precio por kilómetro, capacidad disponible, radio de retiro).
+ Se indica el costo estimado del viaje, calculado como precio por kilómetro × distancia estimada para la carga en contexto (mismo cálculo que la fila de US4).
+ Se muestra un botón claro "Ofertar contra esta ventana" que navega a US7 con la carga y la ventana ya en contexto.
+ La información se carga correctamente y se presenta de forma clara y organizada.

== US7: Ofertar Retiro de una Carga

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Reservar Transportista

*Descripción:*
Como expedidor,
quiero enviar una oferta al transportista responsable de una ventana compatible con mi carga,
para contactarlo y que decida si acepta realizar el viaje.

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
quiero poder pagar de forma segura una vez que el transportista aceptó mi viaje,
para reservar el servicio y cumplir con mi parte del trato.

*Criterios de Aceptación:*
+ Una vez aceptado el viaje por el transportista, se habilita la opción de realizar el pago.
+ El pago se realiza a través de Mercado Pago integrado en la plataforma (mismo proveedor que en US15).
+ La reserva se confirma de forma instantánea al completarse el pago.
+ Una vez completado el pago, se otorgan los datos de contacto del transportista.
+ Si el pago falla, se muestra un mensaje de error y se permite reintentar sin perder el contexto de la oferta.
+ El monto del pago corresponde al precio acordado en la oferta aceptada.
+ El pago se reintenta o cancela dentro de una ventana configurable (por defecto 24h); si vence, la oferta se libera y el transportista vuelve a estar disponible.

// ── Plataforma del Transportista ──────────────────────────────────────────

== US9: Publicar Ventana de Transporte

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Gestión de Viajes

*Descripción:*
Como transportista,
quiero publicar una ventana de transporte en la plataforma,
para que los expedidores cuya carga coincida con mi ruta y fecha me encuentren y me ofrezcan viajes.

*Criterios de Aceptación:*
+ Se puede indicar la zona origen desde donde el transportista está dispuesto a partir.
+ Se puede indicar la zona destino hasta donde el transportista está dispuesto a llegar.
+ Se puede indicar la franja temporal (fecha y hora desde / hasta) en la que la ventana está vigente.
+ Se debe asociar uno de los vehículos previamente registrados por el transportista (US14) — la capacidad y dimensiones del vehículo determinan qué cargas pueden coincidir con la ventana.
+ Se puede indicar un precio por kilómetro para el servicio.
+ Una vez completados los datos necesarios, se puede confirmar la publicación de la ventana.
+ La ventana aparece en los resultados de búsqueda de los expedidores cuya carga, ruta y fecha coincidan.

== US10: Observar Ofertas de Viaje

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Gestión de Viajes

*Descripción:*
Como transportista,
quiero poder observar un listado de ofertas de viaje recibidas,
para evaluar y aceptar las que considere convenientes.

*Criterios de Aceptación:*
+ Una vez publicada una ventana de transporte (US9), se muestra un listado de ofertas realizadas por expedidores que coincidan con esa ventana.
+ Se puede entrar a los detalles de cada oferta para observar sus características (distancia, ubicación, volumen, peso, precio acordado, datos del expedidor).
+ El listado se actualiza al refrescar la pantalla y al navegar al dashboard del transportista (US27).
+ Se muestra información resumida de cada oferta (origen, destino, fecha, precio) en el listado.
+ Cada oferta indica su estado (pendiente, aceptada, rechazada) y la fecha en que fue recibida.

== US11: Filtrado de Ofertas de Viaje

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Gestión de Viajes

*Descripción:*
Como transportista,
quiero poder filtrar las ofertas de viaje recibidas,
para encontrar rápidamente las que mejor se ajusten a mi disponibilidad y preferencias.

*Criterios de Aceptación:*
+ Se puede filtrar por ubicación de origen de la carga.
+ Se puede filtrar por rango de fecha de retiro.
+ Se puede filtrar por peso de la carga a transportar.
+ Se puede filtrar por volumen de la carga a transportar.
+ Al borrar un filtro, se resetea y aparecen todas las ofertas disponibles.
+ Los filtros se pueden combinar entre sí.

== US12: Aceptación de Viaje

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Aceptar Viaje

*Descripción:*
Como transportista,
quiero poder aceptar una oferta de viaje,
para comprometerme a realizarlo y generar ingresos.

*Criterios de Aceptación:*
+ Una vez seleccionada una oferta (US10), se puede aceptar mediante un botón claramente visible.
+ Al aceptar la oferta, se notifica al expedidor que su oferta fue aceptada y se habilita el flujo de pago (US8).
+ Al aceptar la oferta, se calcula y muestra al expedidor una estimación de fecha de entrega basada en la franja temporal de la ventana asociada.
+ El viaje aceptado aparece en la sección de "viajes activos" del transportista (visible en el dashboard, US27).
+ Una oferta aceptada queda bloqueada para otros transportistas: no puede ser aceptada dos veces ni modificada por el expedidor.

== US13: Realizar Viaje (Navegación GPS)

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Aceptar Viaje

*Descripción:*
Como transportista,
quiero poder navegar hacia el destino usando un mapa integrado,
para seguir la ruta óptima y completar el viaje de forma eficiente.

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
*Épica:* Después del Viaje

*Descripción:*
Como transportista,
quiero recibir el pago por los viajes concretados,
para cobrar por mi servicio de forma segura y en tiempo.

*Criterios de Aceptación:*
+ La plataforma se integra con Mercado Pago para gestionar los pagos.
+ Una vez concretado el viaje (carga entregada), se efectúa la transferencia del pago al transportista.
+ El transportista puede ver el detalle de cada pago recibido (monto, viaje asociado, fecha).
+ Si hay algún problema con la transferencia, se notifica al transportista.

== US27: Publicar Carga

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Gestionar Cargas

*Descripción:*
Como expedidor,
quiero publicar una carga con toda su informacion detallada,
para poder enviarla.

*Criterios de Aceptación:*
+ Se pueden ingresar los datos de la dirección de origen y de la dirección de destino (calle, número, código postal, ciudad y provincia).
+ Se puede ingresar el peso de la carga en kilogramos (debe ser mayor a cero).
+ Se puede ingresar una descripción de la carga a transportar.
+ Se pueden ingresar instrucciones de manipulación especial (opcional, por ejemplo "frágil", "refrigerado").
+ Los campos obligatorios están claramente marcados y se validan antes de enviar el formulario; si falta uno o un valor es inválido se muestra un mensaje claro por campo.
+ Solo los expedidores autenticados pueden publicar una carga; un transportista logueado no ve la opción.
+ Al publicar exitosamente, la carga queda en estado abierta (sin ofertas asociadas todavía).
+ Al publicar exitosamente, el expedidor es redirigido a la pantalla detalles de la carga.
+ Al publicar exitosamente, se inicia la búsqueda de ventanas de transporte compatibles (US4).

== US36: Dashboard del Transportista

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Gestión de Viajes

*Descripción:*
Como transportista,
quiero ver un dashboard con un resumen de mi actividad al iniciar sesión,
para tener una vista general de mis ventanas, ofertas y viajes sin navegar por varias pantallas.

*Criterios de Aceptación:*
+ Al loguearse como transportista, se accede a un dashboard como pantalla principal.
+ Se muestra un listado de los vehiculos cargados por el transportista (US14).
+ Se muestra un resumen de las ventanas de transporte activas publicadas, la disponibilidad (US9).
+ Cada sección del dashboard enlaza a la pantalla detallada correspondiente.
+ Si el transportista no tiene actividad, cada sección muestra un estado vacío con una acción sugerida (por ejemplo, publicar una ventana o registrar un vehículo).

== US37: Dashboard del Expedidor

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Reservar Transportista

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

== US39: Crear Administrador

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Cuenta

*Descripción:*
Como dueño del producto,
quiero poder crear una cuenta admin,
para poder administrador al resto de usuarios y entidades existentes en la aplicacion.

*Criterios de Aceptación:*
+ Al estar logueado como admin, se puede acceder a un formulario a rellenar con los datos del nuevo admin
+ Se realiza una validacion donde solo un administrador, puede dar de alta otra cuenta de admin.

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

== US43: Administrar mis Ventanas de Transporte

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Gestión de Viajes

*Descripción:*
Como transportista,
quiero poder ver mis ventanas de transporte en la plataforma,
para tener un registro de mis posibles viajes.

*Criterios de Aceptación:*
+ El transportista puede visualizar sus ventanas activas, junto con sus detalles.
+ Se observan botones para editarlas, ocultarlas o eliminarlas en cualquier momento.
+ En la pagina de Mi Disponibilidad, se encuentra un boton para poder publicar una nueva.

== US33: Editar Ventana de Transporte

*Release:* Release 2 \
*Prioridad:* Media \
*Épica:* Gestión de Viajes

*Descripción:*
Como transportista,
quiero poder modificar los datos de una ventana de transporte (`TransportWindow`) que ya publiqué (US9),
para corregir errores o ajustarla a cambios en mi disponibilidad sin tener que despublicarla y republicarla.

*Criterios de Aceptación:*
+ Desde la pantalla "Mi Disponibilidad", se puede acceder a una pantalla de edición de la ventana seleccionada.
+ Se pueden modificar zona origen, zona destino, franja temporal (fecha/hora desde y hasta), vehículo asociado (entre los registrados en US14) y precio por kilómetro.
+ Al guardar, la ventana actualizada se refleja inmediatamente en los resultados de búsqueda de los expedidores (US4) según los nuevos criterios.
+ Si la ventana ya tiene ofertas de viaje recibidas (US10) que dejarían de ser compatibles con los nuevos datos (por ejemplo, fechas que ya no se solapan o vehículo de menor capacidad), se muestra una advertencia antes de confirmar listando las ofertas afectadas.
+ Si la ventana está asociada a un viaje ya aceptado (US12), no se permite modificarla y se indica el motivo.
+ Al presionar "Descartar Cambios" o navegar a otra página sin guardar, los datos escritos no se impactan.

== US34: Eliminar Ventana de Transporte

*Release:* Release 2 \
*Prioridad:* Media \
*Épica:* Gestión de Viajes

*Descripción:*
Como transportista,
quiero poder dar de baja definitivamente una ventana de transporte que publiqué,
para retirarla del sistema cuando ya no quiero recibir ofertas contra ella ni conservarla en mi listado.

*Criterios de Aceptación:*
+ Desde la pantalla "Mi Disponibilidad", cada entrada ofrece una acción de "Eliminar" claramente diferenciada de "Ocultar" (US35).
+ Antes de confirmar la baja, se muestra un diálogo de confirmación que aclara que la acción es irreversible y detalla las ofertas pendientes que se cancelarán.
+ Si la ventana tiene ofertas de viaje pendientes (US10) sin aceptar, la baja las cancela automáticamente y notifica a los expedidores correspondientes.
+ Si la ventana está asociada a un viaje ya aceptado (US12), la baja se rechaza y se indica al transportista que debe completar o cancelar el viaje primero.
+ La ventana dada de baja deja de aparecer en los resultados de búsqueda de los expedidores (US4) y en el listado activo del transportista, pero se conserva en el historial a efectos de auditoría.
+ La ventana dada de baja no puede reactivarse — para volver a operar el mismo trayecto el transportista debe publicar una nueva ventana (US9).

== US35: Ocultar de Ventana de Transporte

*Release:* Release 2 \
*Prioridad:* Baja \
*Épica:* Gestión de Viajes

*Descripción:*
Como transportista,
quiero poder ocultar temporalmente una ventana de transporte sin darla de baja,
para dejar de recibir ofertas mientras evalúo cambios o resuelvo una indisponibilidad puntual, conservando la opción de reactivarla luego.

*Criterios de Aceptación:*
+ Desde la pantalla "Mi Disponibilidad", cada entrada ofrece una acción de "Ocultar" claramente diferenciada de "Eliminar" (US34).
+ Al ocultar la ventana, ésta deja de aparecer en los resultados de búsqueda de los expedidores (US4) pero permanece visible en el listado del transportista marcada como "Oculta".
+ Las ofertas pendientes recibidas previamente (US10) no se cancelan al ocultar — el transportista puede seguir aceptándolas o rechazándolas.
+ Desde la pantalla "Mi Disponibilidad", una ventana oculta ofrece una acción de "Reactivar" que la vuelve a publicar tal como estaba, sin necesidad de reingresar los datos.
+ El ocultamiento no afecta viajes ya aceptados (US12) asociados a la ventana.
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
+ Se puede observar el estado actual de dichas cargas (abierta / aceptada / cancelada).
+ Se puede acceder a los detalles de una carga especifica.

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
+ Se puede observar el estado actual de dichas cargas (abierta / aceptada / cancelada).
+ Se pueden visualizar las ofertas enviadas a transportistas de dicha carga.

== US47: Editar Carga

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Cuenta

*Descripción:*
Como transportista,
quiero poder modificar los datos de una carga,
para mantener actualizada su informacion en caso de ser necesario.

*Criterios de Aceptación:*
+ Desde el los detalles de una carga, se puede acceder a una pantalla de edición de la seleccionada.
+ Se pueden modificar descripcion, peso, volumen, valor declarado (en ARS), direccion de retiro.
+ Los campos obligatorios están claramente marcados y se validan antes de enviar el formulario; si falta uno o un valor es inválido se muestra un mensaje claro por campo.
+ Al guardar, los datos actualizados se reflejan inmediatamente en los detalles visibles de dicha carga.
+ Al presionar "Descartar Cambios" o navegar a otra página sin guardar, los datos escritos no se impactan.

== US48: Búsqueda de Ventanas Compatibles con mi Carga

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Buscar Transporte para mi Carga

*Descripción:*
Como expedidor,
quiero ver el listado de ventanas de transporte compatibles con una carga que publiqué,
para identificar qué transportistas están en condiciones de realizar mi viaje y poder enviarles una oferta de carga.

*Criterios de Aceptación:*
+ Se accede a esta pantalla desde la pantalla de detalle de una carga publicada (US27).
+ El expedidor puede acotar el listado con un filtro opcional de fecha de retiro mínima y máxima.
+ El listado muestra únicamente las ventanas en estado abierta cuya franja temporal intersecta el rango de fecha de retiro indicado; si el expedidor no indica fecha mínima se asume la fecha actual sin mostrarla, y si no indica máxima no se aplica tope superior.
+ El listado muestra únicamente las ventanas cuyo origen está a una distancia menor o igual al radio de retiro declarado por el transportista respecto del origen de la carga, y cuyo destino también está dentro del mismo radio respecto del destino de la carga.
+ El listado muestra únicamente las ventanas cuyo vehículo asociado tiene capacidad disponible mayor o igual al peso de la carga.
+ Cada resultado muestra origen, destino, franja de fechas, resumen del transportista responsable y del vehículo asociado, precio por kilómetro de referencia y costo estimado total para la carga (precio por kilómetro × distancia estimada).
+ En caso de existir muchas ventanas compatibles, los resultados se muestran paginados.
+ Al hacer click sobre el resumen de una ventana, se navega al detalle del transportista responsable (US6) preservando el contexto de la carga y de la ventana seleccionada.
+ Cada fila incluye una acción "Ofertar" que lleva directamente a US7 con la carga y la ventana ya en contexto.
+ Si la carga ya tiene ofertas pendientes contra otras ventanas, se muestra un contador visible ("Ofertas pendientes: N") para que el expedidor recuerde sus propuestas en curso.
+ Si no hay ventanas compatibles, se muestra un mensaje claro indicándolo y se sugiere revisar el filtro de fecha o el origen/destino de la carga.

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

== US17: Historial de Viajes

*Release:* Release 2 \
*Prioridad:* Media \
*Épica:* Cuenta

*Descripción:*
Como usuario (expedidor o transportista),
quiero poder ver mi historial de viajes realizados,
para tener un registro de toda mi actividad en la plataforma.

*Criterios de Aceptación:*
+ El expedidor puede ver un listado de todos los envíos que contrató, con su estado (completado, en curso, cancelado).
+ El transportista puede ver un listado de todos los viajes que realizó, con su estado.
+ Cada entrada del historial muestra información resumida: origen, destino, fecha, precio.
+ Se puede acceder al detalle de cada viaje desde el historial.
+ El historial de viajes del transportista es visible para los expedidores que consultan sus detalles.

== US18: Actualización de Viaje — Carga Retirada

*Release:* Release 2 \
*Prioridad:* Media \
*Épica:* Aceptar Viaje

*Descripción:*
Como transportista,
quiero poder marcar una carga como retirada,
para que el expedidor sepa que ya recogí su carga y el viaje está en curso.

*Criterios de Aceptación:*
+ Al retirar la carga, el transportista puede marcarla como "retirada" con un botón.
+ Al expedidor se le muestra que el transportista ya recogió su carga en el estado del viaje.
+ La fecha y hora del retiro quedan registradas en el sistema.
+ No se puede marcar como retirado un viaje que aún no fue aceptado y pagado.

== US19: Actualización de Viaje — Carga Entregada

*Release:* Release 2 \
*Prioridad:* Alta \
*Épica:* Aceptar Viaje

*Descripción:*
Como transportista,
quiero poder marcar una carga como entregada,
para que el expedidor lo sepa y se concrete el pago del servicio.

*Criterios de Aceptación:*
+ Al entregar la carga, el transportista puede marcarla como "entregada" con un botón.
+ Al expedidor se le muestra el estado del viaje como completado.
+ La confirmación de entrega dispara el proceso de transferencia de pago al transportista.
+ La fecha y hora de entrega quedan registradas en el sistema.
+ No se puede marcar como entregado un viaje que no fue previamente marcado como retirado.

== US20: Reseñas

*Release:* Release 2 \
*Prioridad:* Media \
*Épica:* Después del Viaje

*Descripción:*
Como expedidor,
quiero poder escribir y leer reseñas sobre los transportistas,
para compartir mi experiencia y consultar las de otros antes de contratar un servicio.

*Criterios de Aceptación:*
+ Un expedidor puede escribir una reseña sobre un transportista una vez que el viaje se completó.
+ La reseña incluye una puntuación (por ejemplo, 1 a 5 estrellas) y un comentario de texto.
+ Las reseñas de un transportista son visibles en su perfil para todos los usuarios.
+ Se muestra el promedio de puntuación del transportista junto a las reseñas individuales.
+ Un expedidor solo puede dejar una reseña por viaje completado.

== US21: Tracking de Envío

*Release:* Release 2 \
*Prioridad:* Media \
*Épica:* Gestión de Viajes

*Descripción:*
Como expedidor,
quiero poder hacer seguimiento de mi envío en tiempo real,
para saber dónde está mi carga y cuándo llegará.

*Criterios de Aceptación:*
+ Se muestra la ubicación del transportista en un mapa en tiempo real mientras el viaje está en curso.
+ Se muestra el estado actual del envío (pendiente de retiro, en tránsito, entregado).
+ Se muestra una estimación del tiempo restante de llegada.
+ El tracking solo está disponible para viajes que fueron aceptados y pagados.
+ La información se actualiza periódicamente sin que el expedidor deba refrescar la página.

== US32: Baja de Vehículo

*Release:* Release 2 \
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
+ Si el vehículo está asociado a un viaje en curso (aceptado y no entregado), la baja se rechaza y se explica el motivo.
+ El vehículo dado de baja deja de aparecer en el listado activo del transportista, pero sus datos se conservan a efectos del historial de viajes (US17) — los viajes pasados siguen mostrando el vehículo que los realizó.
+ El vehículo dado de baja deja de ser seleccionable al publicar nuevas ventanas de transporte.

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

== US23: Viajes Compuestos (Múltiples Envíos)

*Release:* Release 3 \
*Prioridad:* Baja \
*Épica:* Gestión de Viajes

*Descripción:*
Como transportista,
quiero poder agrupar múltiples envíos en un solo viaje,
para optimizar la carga y maximizar los ingresos por recorrido.

*Criterios de Aceptación:*
+ El transportista puede aceptar múltiples ofertas de viaje y agruparlas en un viaje compuesto.
+ Se muestra la ruta optimizada que contempla todos los puntos de retiro y entrega.
+ Cada expedidor puede ver el estado de su envío individual dentro del viaje compuesto.
+ Se valida que la capacidad del vehículo no sea excedida por la suma de los envíos agrupados.
+ El transportista puede ver un resumen con todos los envíos del viaje, sus estados y destinos.

== US24: Encadenado de Pedidos

*Release:* Release 3 \
*Prioridad:* Baja \
*Épica:* Gestión de Viajes

*Descripción:*
Como transportista,
quiero poder encadenar pedidos en una ruta continua,
para realizar viajes largos recogiendo y entregando cargas a lo largo del camino.

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
para proteger mi carga en caso de daño o pérdida durante el viaje.

*Criterios de Aceptación:*
+ Al confirmar una oferta de retiro, se ofrece la opción de contratar un seguro para el envío.
+ Se muestran las opciones de seguro disponibles con su cobertura y precio.
+ El costo del seguro se suma al total del pago.
+ En caso de siniestro, el expedidor puede iniciar un reclamo desde la plataforma.
+ El detalle del seguro contratado es visible en el historial del viaje.

== US26: Editar o Eliminar Reseña

*Release:* Release 3 \
*Prioridad:* Baja \
*Épica:* Después del Viaje

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
