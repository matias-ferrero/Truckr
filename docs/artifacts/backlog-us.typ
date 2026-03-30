#import "template.typ": conf
#show: conf

= Backlog — User Stories

== US1: Registrarse

*Priority:* Alta

*Description:*
Como usuario (cliente o transportista)
quiero poder registrarme en la plataforma
para satisfacer mis necesidades

*Acceptance Criteria:*
- Se pueden ingresar todos los datos necesarios: email, nombre completo y contraseña
- Si el usuario esta repetido, falla el registro.
- Si la Contraseña no cumple alguno de estos, falla el registro:
  - Tiene al menos 12–16 caracteres (más es mejor)
  - Incluye mayúsculas (A-Z)
  - Incluye minúsculas (a-z)
  - Incluye números (0-9)

== US2: Login

*Priority:* Alta

*Description:*
Como usuario (cliente o transportista)
quiero poder loguearme en la plataforma
para participar en ella con mi perfil

*Acceptance Criteria:*
- Poder loguearse correctamente si las credenciales ingresadas (usuario y password) son correctas

== US3: Modificar Perfil

*Priority:* Media

*Description:*
Como usuario (cliente o transportista)
quiero poder modificar mi perfil
para completar mis datos personales

*Acceptance Criteria:*
- Si lleno los campos de mis datos personales (y del camion), se persistan hasta que se guarden/descarten los cambios
- Al apretar el boton de Guardar Cambios, se impacten en mi perfil
- Al apretar el boton de Descartar Cambios o cambiar de pagina, los datos escritos no se impacten en mi perfil

== US4: Busqueda de Transportista

*Priority:* Alta

*Description:*
Como cliente
quiero buscar transportistas disponibles
para decidir cual pedirle el servicio de un viaje

*Acceptance Criteria:*
- Al ingresar una ubicacion origen y una destino, me aparezcan los transportistas dispuestos a realizar el viaje por esas zonas
- Al ingresar un rango de fecha, solo deben aparecer los transportistas disponibles dentro de ella
- Al entrar a esta solapa de busqueda, que me permita scrollear entre todos los disponibles de la pagina
- En caso de existir muchos transportistas disponibles, mostrarlos en distintas paginas
- Si aprieto click en un transportista, debo entrar a los detalles del seleccionado
- Si selecciono un orden por cierta caracteristica, que se ordenen (ascendente/descendente) los transportistas disponibles

== US5: Filtrado de Transportistas

*Priority:* Media

*Description:*
Como cliente
quiero filtrar los transportistas disponibles
para encontrar mas rapido al que quiero

*Acceptance Criteria:*
- Si filtro por precio, solo deben salirme los posibles viajes que cumplan dicha caracteristica
- Si filtro por peso, solo deben aparecer los transportistas capaces de cargar dicho peso
- Si filtro por volumen, solo deben aparecer los transportistas capaces de cargar dicho tamaño de producto
- Si borro un filtro seleccionado, debe resetearse las busqueda y aparecer todos los transportistas disponibles

== US6: Detalles de Transportista

*Priority:* Media

*Description:*
Como cliente
quiero entrar a los detalles del transportista
para decidir si es el indicado para mi viaje

*Acceptance Criteria:*
- Al entrar a los detalles, que aparezcan fotos y una descripcion detallada del camion del transportista
- Al entrar a los detalles, que indique el costo de realizar el supuesto viaje
- Al entrar a los detalles, que aparezca un historial de viajes ya realizados por dicho transportista
- ... , que aparezca una sección de reseñas hechas por otros clientes sobre el transportista

== US7: Ofertar Retiro de un Producto

*Priority:* Alta

*Description:*
Como cliente
quiero ofertar un retiro de un producto a un transportista
para que realice el viaje y me lo entregue

*Acceptance Criteria:*
- Que se pueda indicar la fecha en la que se debe retirar el producto
- Que se pueda indicar la ubicacion exacta a la que retirar el producto
- Que se pueda indicar la ubicacion exacta a la que entregar el producto
- Una vez completados dichos datos necesarios, se confirme la oferta

== US8: Realizar Pago

*Priority:* Alta

*Description:*
Como cliente
quiero poder pagar al transportista una vez me acepto el viaje
para cumplir con mi parte del trato

*Acceptance Criteria:*
- Una vez aceptado el viaje, se debe permitir realizar el pago para reservar al transportista
- Una vez hecho el pago, se deben otorgar los datos de contacto del transportista

== US9: Publicar Disponibilidad

*Priority:* Alta

*Description:*
Como transportista
quiero poder publicar mi disponibilidad en la web
para encontrar clientes a los cuales llevarles su producto

*Acceptance Criteria:*
- Que se pueda indicar la zona desde donde estaría dispuesto a partir
- Que se pueda indicar un limite a recorrer por el transportista
- Una vez completados dichos datos necesarios, se confirme la publicacion de disponibilidad

== US10: Observar Ofertas de Viaje

*Priority:* Alta

*Description:*
Como transportista
quiero poder observar un listado de ofertas de viaje
para aceptar los que considere a mi criterio

*Acceptance Criteria:*
- Una vez publicada la disponibilidad, debo poder ver un listado de ofertas de los clientes
- Debo poder entrar a los detalles del viaje, para observar las caracteristicas (como distancia, ubicacion, volumen, peso, etc) del viaje y producto
- Debo poder entrar a los detellas del cliente, para observar sus datos personales y reseñas como el mismo

== US11: Aceptacion de Viaje

*Priority:* Alta

*Description:*
Como transportista
quiero poder aceptar una oferta de viaje
para realizarlo y generar ingresos

*Acceptance Criteria:*
- Una vez seleccionado un viaje, debo poder aceptarlo correctamente mediante el clickeo de un boton
- Al aceptar dicho viaje, se debe actualizar una estimacion para la fecha de entrega de los respectivos productos a cada cliente

== US12: actualización de viaje al tomar el producto

*Priority:* media

*Description:*
Como transportista
quiero poder marcar al producto como recibido
para que al cliente le llegue esa actualización del viaje

*Acceptance Criteria:*
- Al retirar el producto, debo poder marcarlo como recibido.
- Al cliente se le debe mostrar que el transportista ya recogió su producto en el estado del viaje.

== US13: actualización del viaje al entregar el producto

*Priority:* alta

*Description:*
Como transportista
quiero poder marcar al producto como entregado
para que el cliente lo sepa y se concrete el pago

*Acceptance Criteria:*
- Al entregar el producto, debo poder marcarlo como entregado.
- Al cliente se le debe mostrar que el estado del viaje como completado.
