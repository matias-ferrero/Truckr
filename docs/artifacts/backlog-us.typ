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
+ Si el email o nombre de usuario ya existe en el sistema, el registro falla y se muestra un mensaje de error claro.
+ La contraseña debe cumplir todos los siguientes requisitos; de lo contrario el registro falla con un mensaje indicando qué requisito no se cumple:
  - Tiene al menos 12 caracteres.
  - Incluye al menos una mayúscula (A–Z).
  - Incluye al menos una minúscula (a–z).
  - Incluye al menos un número (0–9).
+ Al completar el registro exitosamente, el usuario es redirigido a la pantalla de login con un mensaje de confirmación.
+ Los campos obligatorios están claramente marcados y se validan antes de enviar el formulario.

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

== US4: Búsqueda de Ventanas Compatibles con mi Carga

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Buscar Transporte para mi Carga

*Descripción:*
Como expedidor,
quiero ver el listado de ventanas de transporte compatibles con una carga que publiqué,
para identificar qué transportistas están en condiciones de realizar mi viaje y poder enviarles una oferta de carga.

*Criterios de Aceptación:*
+ Se accede a esta pantalla desde la pantalla de detalle de una carga publicada (US27).
+ El listado muestra únicamente las ventanas en estado abierta cuya fecha de retiro de la carga cae dentro de su franja temporal.
+ El listado muestra únicamente las ventanas cuyo origen está a una distancia menor o igual al radio de retiro declarado por el transportista respecto del origen de la carga, y cuyo destino también está dentro del mismo radio respecto del destino de la carga.
+ El listado muestra únicamente las ventanas cuyo vehículo asociado tiene capacidad disponible mayor o igual al peso de la carga.
+ Cada resultado muestra origen, destino, franja de fechas, resumen del transportista responsable y del vehículo asociado, precio por kilómetro de referencia y costo estimado total para la carga (precio por kilómetro × distancia estimada).
+ En caso de existir muchas ventanas compatibles, los resultados se muestran paginados.
+ Al hacer click sobre el resumen de una ventana, se navega al detalle del transportista responsable (US6) preservando el contexto de la carga y de la ventana seleccionada.
+ Cada fila incluye una acción "Ofertar" que lleva directamente a US7 con la carga y la ventana ya en contexto.
+ Si la carga ya tiene ofertas pendientes contra otras ventanas, se muestra un contador visible ("Ofertas pendientes: N") para que el expedidor recuerde sus propuestas en curso.
+ Si no hay ventanas compatibles, se muestra un mensaje claro indicándolo y se sugiere revisar la fecha o el origen/destino de la carga.

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

== US7: Ofertar Retiro de un Producto

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Reservar Transportista

*Descripción:*
Como expedidor,
quiero enviar una oferta de carga al transportista responsable de una ventana compatible con mi carga,
para proponerle un precio y que decida si acepta realizar el viaje.

*Criterios de Aceptación:*
+ El acceso a esta pantalla requiere tener una carga en estado abierta y una ventana en estado abierta ya seleccionadas; los datos de origen, destino y fecha de retiro provienen de la carga (no se vuelven a pedir).
+ El monto propuesto se precarga automáticamente con precio por kilómetro × distancia estimada de la ventana seleccionada y puede ser editado libremente por el expedidor antes de confirmar.
+ Se puede ingresar un mensaje opcional dirigido al transportista (por ejemplo, detalles de la carga, condiciones de retiro).
+ Se informa visiblemente que la oferta expira automáticamente a las 48 horas de enviada si el transportista no responde.
+ Se valida que el monto propuesto sea mayor a cero antes de confirmar.
+ Al confirmar, se crea una oferta de carga en estado pendiente asociada a la carga, a la ventana, al transportista y al vehículo de la ventana.
+ Al confirmar, la ventana seleccionada pasa de abierta a con oferta pendiente (otros expedidores dejan de verla en su búsqueda mientras la oferta siga pendiente).
+ La carga permanece en estado abierta mientras existan ofertas pendientes; sólo pasa a aceptada cuando algún transportista acepta una de las ofertas.
+ El transportista correspondiente es notificado de la nueva oferta recibida.
+ Tras confirmar, el expedidor regresa al detalle de la carga, donde la nueva oferta aparece en el listado de ofertas de la carga con su estado actual.
+ El expedidor puede repetir US7 contra otras ventanas compatibles de la misma carga mientras existan ventanas abiertas disponibles; cada confirmación produce una oferta independiente.
+ Si entre que el expedidor abre la pantalla y confirma la oferta la ventana fue tomada por otra propuesta, se muestra un mensaje claro ("esta ventana ya recibió una oferta, elegí otra") y no se crea la oferta.
+ Si el transportista rechaza la oferta o ésta expira a las 48 horas, la ventana vuelve automáticamente a estado abierta y queda disponible para otros expedidores.

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
+ El pago se realiza a través de una pasarela de pago seguro integrada en la plataforma.
+ La reserva se confirma de forma instantánea al completarse el pago.
+ Una vez completado el pago, se otorgan los datos de contacto del transportista.
+ Si el pago falla, se muestra un mensaje de error y se permite reintentar.
+ El monto del pago corresponde al precio acordado en la oferta aceptada.

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
+ La ventana aparece en los resultados de búsqueda (US4) de los expedidores cuya carga, ruta y fecha coincidan.
+ El transportista puede listar sus ventanas activas, editarlas o despublicarlas en cualquier momento.

== US10: Observar Ofertas de Viaje

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Gestión de Viajes

*Descripción:*
Como transportista,
quiero poder observar un listado de ofertas de viaje recibidas,
para evaluar y aceptar las que considere convenientes.

*Criterios de Aceptación:*
+ Una vez publicada la disponibilidad, se muestra un listado de ofertas realizadas por expedidors.
+ Se puede entrar a los detalles de cada viaje para observar sus características (distancia, ubicación, volumen, peso, etc.).
+ El listado se actualiza cuando llegan nuevas ofertas.
+ Se muestra información resumida de cada oferta (origen, destino, fecha, precio) en el listado.

== US11: Filtrado de Ofertas de Viaje

*Release:* MVP \
*Prioridad:* Media \
*Épica:* Gestión de Viajes

*Descripción:*
Como transportista,
quiero poder filtrar las ofertas de viaje recibidas,
para encontrar rápidamente las que mejor se ajusten a mi disponibilidad y preferencias.

*Criterios de Aceptación:*
+ Se puede filtrar por ubicación de origen del producto.
+ Se puede filtrar por rango de fecha de retiro.
+ Se puede filtrar por peso del producto a transportar.
+ Se puede filtrar por volumen del producto a transportar.
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
+ Una vez seleccionado un viaje, se puede aceptar mediante un botón claramente visible.
+ Al aceptar el viaje, se notifica al expedidor que su oferta fue aceptada.
+ Al aceptar el viaje, se actualiza la estimación de fecha de entrega para el expedidor.
+ El viaje aceptado aparece en una sección de "viajes activos" del transportista.

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
para que los expedidors conozcan las características de mi vehículo al buscarme.

*Criterios de Aceptación:*
+ Se puede ingresar la patente del camión.
+ Se pueden ingresar las dimensiones del camión (largo, ancho, alto del espacio de carga).
+ Se puede ingresar la capacidad de carga máxima en kilogramos.
+ Se pueden subir fotos del camión.
+ Los datos del vehículo se muestran en el perfil del transportista y en los detalles visibles al expedidor.
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
+ Una vez concretado el viaje (producto entregado), se efectúa la transferencia del pago al transportista.
+ El transportista puede ver el detalle de cada pago recibido (monto, viaje asociado, fecha).
+ Si hay algún problema con la transferencia, se notifica al transportista.

== US27: Publicar Carga

*Release:* MVP \
*Prioridad:* Alta \
*Épica:* Gestionar Cargas

*Descripción:*
Como expedidor,
quiero publicar una carga con su origen, destino, fecha de retiro, peso y descripción,
para luego poder buscar ventanas de transporte compatibles y enviar ofertas de carga a los transportistas que las publicaron.

*Criterios de Aceptación:*
+ Se pueden ingresar los datos de la dirección de origen y de la dirección de destino (calle, número, código postal, ciudad y provincia).
+ Se puede ingresar la fecha de retiro estimada (debe ser igual o posterior al día actual).
+ Se puede ingresar el peso de la carga en kilogramos (debe ser mayor a cero).
+ Se puede ingresar una descripción del producto a transportar.
+ Se pueden ingresar instrucciones de manipulación especial (opcional, por ejemplo "frágil", "refrigerado").
+ Los campos obligatorios están claramente marcados y se validan antes de enviar el formulario; si falta uno o un valor es inválido se muestra un mensaje claro por campo.
+ Solo los expedidores autenticados pueden publicar una carga; un transportista logueado no ve la opción.
+ Al publicar exitosamente, la carga queda en estado abierta (sin ofertas asociadas todavía) y el expedidor es redirigido a la pantalla de detalle de la carga, desde donde puede iniciar la búsqueda de ventanas de transporte compatibles (US4).
+ El expedidor puede ver el listado de sus cargas publicadas, con su estado actual (abierta / aceptada / cancelada), desde una sección "Mis cargas".

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
+ El historial de viajes del transportista es visible para los expedidors que consultan sus detalles.

== US18: Actualización de Viaje — Producto Retirado

*Release:* Release 2 \
*Prioridad:* Media \
*Épica:* Aceptar Viaje

*Descripción:*
Como transportista,
quiero poder marcar un producto como retirado,
para que el expedidor sepa que ya recogí su producto y el viaje está en curso.

*Criterios de Aceptación:*
+ Al retirar el producto, el transportista puede marcarlo como "retirado" con un botón.
+ Al expedidor se le muestra que el transportista ya recogió su producto en el estado del viaje.
+ La fecha y hora del retiro quedan registradas en el sistema.
+ No se puede marcar como retirado un viaje que aún no fue aceptado y pagado.

== US19: Actualización de Viaje — Producto Entregado

*Release:* Release 2 \
*Prioridad:* Alta \
*Épica:* Aceptar Viaje

*Descripción:*
Como transportista,
quiero poder marcar un producto como entregado,
para que el expedidor lo sepa y se concrete el pago del servicio.

*Criterios de Aceptación:*
+ Al entregar el producto, el transportista puede marcarlo como "entregado" con un botón.
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
para saber dónde está mi producto y cuándo llegará.

*Criterios de Aceptación:*
+ Se muestra la ubicación del transportista en un mapa en tiempo real mientras el viaje está en curso.
+ Se muestra el estado actual del envío (pendiente de retiro, en tránsito, entregado).
+ Se muestra una estimación del tiempo restante de llegada.
+ El tracking solo está disponible para viajes que fueron aceptados y pagados.
+ La información se actualiza periódicamente sin que el expedidor deba refrescar la página.

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
para realizar viajes largos recogiendo y entregando productos a lo largo del camino.

*Criterios de Aceptación:*
+ El transportista puede seleccionar múltiples pedidos que se encadenan en una ruta secuencial.
+ Se muestra la ruta completa con todos los puntos de retiro y entrega en orden.
+ Se estima la fecha de entrega de cada producto según la posición en la cadena.
+ El sistema sugiere pedidos compatibles con la ruta actual del transportista.
+ Cada expedidor es notificado de la fecha estimada de entrega según la cadena planificada.

== US25: Gestión de Seguros

*Release:* Release 3 \
*Prioridad:* Baja \
*Épica:* Reservar Transportista

*Descripción:*
Como expedidor,
quiero poder contratar un seguro para mi envío al momento de reservar el transporte,
para proteger mi producto en caso de daño o pérdida durante el viaje.

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
