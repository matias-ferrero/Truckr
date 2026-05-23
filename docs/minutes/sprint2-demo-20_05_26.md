# Informe de Avance

Esta muy bien! Recuerden mostrar tema velocity y enfoque No Estimates

### Observaciones de Liz:

- La demo final armenla al pie de la letra con lo que esta anotado.
- Denle importancia a las cualidades especiales del equipo como el enfoque No Estimates.
- Usen el template de las slides para la demo final (obligatorio).
- La clase del 17/06 Liz no va a estar porque se va de viaje. Si venimos muy bien, no hay demo. Si hace falta coordinamos algun otro dia.
- Vayan implementando ahora las features mas core del producto.
- Si quieren pueden hacer la integracion con google maps para el MVP y relegar todo el tema de reseñas para algun release futuro.
- Liz quiere que el Sprint 7, NO se desarrolle mas. Esa semana sera para preparar la demo final. Incluso menciono, que si podemos ir dejando de implementar features nuevas para el Sprint 6 mejor.
- Liz no quiere que presentemos en la demo final, cosas que no vio ella.
- La demo final son 25 minutos para hablar entre los seis integrantes (dividirse bien, que hablen todos), y la demo del producto son solo 5 minutos (mostrar algo interesante, de valor).

---

# Demo

Se leera en el Backlog, cada US con sus criterios de aceptacion para hacer la demo de dicha feature en el proyecto.

---

## Backoffice:

"Tenemos un admin hardcodeado" (futura US crear uno)

## US40 - Bandeja de Usuarios

Check!

## US41 - Personificar Usuario

Check!

Liz dijo que tema back office no se lo mostremos a ella, y cuanto menos hagamos de eso mejor (no le agrega valor al producto, aunq nos sirva a nosotros)

---

## Carry Over de Sprint 1:

### US3 - Modificar Perfil

Check!

---

## Como Transportista (Carrier)
### US14 - Registro de Vehiculo

Check!

### US42 - Administrar mi Flota

Check!
- Tema de la imagen anda pero tuve que descargar una dependencia (mal dockerizado?)

### US31 - Editar Vehiculo de mi Flota

Check! Pero...
VALIDACION FALTANTE: no se deberia poder cambiar la patente del vehiculo

### US9 - Publicar Ventana de Transporte

Check!

### US43 - Administrar mis Ventanas de Transporte

Check!

### US33 - Editar una Ventana de Transporte

Check!

### US35 - Ocultar una Ventana de Transporte

Check!

### US34 - Eliminar una Ventana de Transporte

**Solo** se puede eliminar una ventana que NO tenga ofertas de shippers en ella.

Si se trata de eliminar una con ofertas, el backend devuelve error code 500. Esto no deberia ser asi, deberia devolver un error 400 conocido para mostrar un pop up en la vista!

---

## Como Expedidor (Shipper)

### US6 - Detalles de Transportistas

Check!
Fran agrego un boton de "Ver Perfil" dentro de la card del transportista, se agrego un action button al componente.

---

## Home's

### US38 - Landing Page

Check!

### US36 - Dashboard del Expedidor

Check! Liz nos dijo que si hay que seguir agregando cosas a los dashboard:
- Si es cambio significativo, se agrega una US
- Si es cambio menor (like agregado de boton), se agrega CA a equis US

### US37 - Dashboard del Transportista

Check! Liz nos dijo que si hay que seguir agregando cosas a los dashboard:
- Si es cambio significativo, se agrega una US
- Si es cambio menor (like agregado de boton), se agrega CA a equis US

---

# Sprint 2

### US27 - Publicar Carga

Se crea una carga correctamente pero, NO completada!
- Hay que desglosar toda la direccion y como se ingresa la misma
- Hay que revisar el seteo del precio porque los numeros se comportan raro al ingresarlos (centavos? dolar? pesos?)

### US44 - Administrar Cargas

Check!

### US45 - Filtrar mis Cargas

Check!

### US46 - Ver Detalles de una Carga

Check!

### US47 - Editar Carga

Check! Pero
- Hay que revisar el seteo del precio porque los numeros se comportan raro al ingresarlos (centavos? dolar? pesos?)

### US48 - Busqueda de Ventanas Compatibles con mi Carga

Check! Pero, como hay cambio de contrato se agrego esta US.

Se cambio el search, ahora es automatico por compatibilidad.
- Si aprieto la Carga creada en dashboard, me busca los transportistas disponibles compatibles (shortcut)
- Otro camino, ir a ver todas mis cargas y clickear en una especifica

### US7 - Ofertar Retiro de una Carga

Check!

### US10 - Bandeja de Ofertas de Viaje

No la logramos integrar pero fran la hizo -> Carryover Sprint 3

### US12 - Aceptacion de Oferta

No la logramos integrar pero fran la hizo -> Carryover Sprint 3
