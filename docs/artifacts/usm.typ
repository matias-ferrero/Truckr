#import "../template.typ": (
  c-activ, c-epic, c-mvp, c-mvp-lane, c-post, c-post-lane, c-task, conf,
)
#show: conf

#set page(flipped: true, paper: "a3", margin: (x: 0.5cm, y: 0.8cm))

// ── Color definitions extracted from spreadsheet ──────────────────────────
#let col1-task = rgb("#FCE5CD")
#let col1-activ = rgb("#F9CB9C")
#let col2-task = rgb("#FCE5CD")
#let col2-activ = rgb("#F9CB9C")
#let col3-task = rgb("#FCE5CD")
#let col3-activ = rgb("#F9CB9C")
#let col4-task = rgb("#F4CCCC")
#let col4-activ = rgb("#EA9999")
#let col5-task = rgb("#F4CCCC")
#let col5-activ = rgb("#EA9999")
#let col6-task = rgb("#F4CCCC")
#let col6-activ = rgb("#EA9999")
#let col7-task = rgb("#D9EAD3")
#let col7-activ = rgb("#B6D7A8")
#let col8-task = rgb("#D9EAD3")
#let col8-activ = rgb("#B6D7A8")
#let col9-task = rgb("#D9EAD3")
#let col9-activ = rgb("#B6D7A8")
#let col10-task = rgb("#EAD1DC")
#let col10-activ = rgb("#C27BA0")
#let col11-task = rgb("#EAD1DC")
#let col11-activ = rgb("#C27BA0")
#let col12-task = rgb("#EAD1DC")
#let col12-activ = rgb("#C27BA0")
#let col13-task = rgb("#D9D2E9")
#let col13-activ = rgb("#8E7CC3")
#let col14-task = rgb("#D9D2E9")
#let col14-activ = rgb("#8E7CC3")
#let col15-task = rgb("#FFF2CC")
#let col15-activ = rgb("#FFE599")
#let epic-color = rgb("#9FC5E8")
#let release-color = rgb("#6AA84F")

= User Story Map

#set text(size: 9pt)

#table(
  columns: (2fr,) * 15,
  inset: (x: 4pt, y: 3pt),

  // ── Row 1: Backbone — Epics ─────────────────────────────────────────────
  table.cell(colspan: 3, fill: epic-color, align: center)[
    #text(fill: black, weight: "bold")[Cuenta]
  ],
  table.cell(colspan: 3, fill: epic-color, align: center)[
    #text(fill: black, weight: "bold")[Ver Transportistas Disponibles]
  ],
  table.cell(colspan: 3, fill: epic-color, align: center)[
    #text(fill: black, weight: "bold")[Gestión de Viajes]
  ],
  table.cell(colspan: 3, fill: epic-color, align: center)[
    #text(fill: black, weight: "bold")[Reservar Transportista]
  ],
  table.cell(colspan: 2, fill: epic-color, align: center)[
    #text(fill: black, weight: "bold")[Aceptar Viaje]
  ],
  table.cell(colspan: 1, fill: epic-color, align: center)[
    #text(fill: black, weight: "bold")[Despues del viaje]
  ],
  table.cell(fill: col1-activ, align: center)[
    #text(fill: black, weight: "bold")[Crear]
  ],
  table.cell(fill: col2-activ, align: center)[
    #text(fill: black, weight: "bold")[Login]
  ],
  table.cell(fill: col3-activ, align: center)[
    #text(fill: black, weight: "bold")[Perfil]
  ],
  table.cell(fill: col4-activ, align: center)[
    #text(fill: black, weight: "bold")[Búsqueda]
  ],
  table.cell(fill: col5-activ, align: center)[
    #text(fill: black, weight: "bold")[Filtros]
  ],
  table.cell(fill: col6-activ, align: center)[
    #text(fill: black, weight: "bold")[Detalles del Transportista]
  ],
  table.cell(fill: col7-activ, align: center)[
    #text(
      fill: black,
      weight: "bold",
    )[Publicación de Disponibilidad de Transporte]
  ],
  table.cell(fill: col8-activ, align: center)[
    #text(fill: black, weight: "bold")[Ofertas de Viaje]
  ],
  table.cell(fill: col9-activ, align: center)[
    #text(fill: black, weight: "bold")[Filtros]
  ],
  table.cell(fill: col10-activ, align: center)[
    #text(fill: black, weight: "bold")[Ofertar]
  ],
  table.cell(fill: col11-activ, align: center)[
    #text(fill: black, weight: "bold")[Pagos]
  ],
  table.cell(fill: col12-activ, align: center)[
    #text(fill: black, weight: "bold")[Seguros]
  ],
  table.cell(fill: col13-activ, align: center)[
    #text(fill: black, weight: "bold")[Aceptación de Viaje]
  ],
  table.cell(fill: col14-activ, align: center)[
    #text(fill: black, weight: "bold")[Realizar Viaje]
  ],
  table.cell(fill: col15-activ, align: center)[
    #text(fill: black, weight: "bold")[Reseñas]
  ],

  // ── MVP — Release 1 Stories ──────────────────────────────────────────────────────────
  table.cell(fill: col1-task)[
    - Ingresar Email y Usuario
    - Ingresar Contraseña
  ],
  table.cell(fill: col2-task)[
    - Ingresar Email o Usuario
    - Ingresar Contraseña
    - Clickear Boton de Login
  ],
  table.cell(fill: col3-task)[
    - Completar datos personales de mi perfil
    - Guardar los cambios
  ],
  table.cell(fill: col4-task)[
    - Ingresar Ubicación Origen
    - Ingresar Ubicación Destino
    - Ingresar rango de Fecha de Retiro
    - Scrollear entre Transportistas Disponibles
  ],
  table.cell(fill: col5-task)[
    - Filtrar por Precio/Km
    - Filtrar por Dimensiones
    - Filtrar por capacidad del camión
  ],
  table.cell(fill: col6-task)[
    - Ver Fotos y Descripción
    - Ver Precio del Servicio
  ],
  table.cell(fill: col7-task)[
    - Ingresar Precio/Km
    - Publicar zona origen
  ],
  table.cell(fill: col8-task)[
    - Observar Listado de Ofertas
    - Entrar a Detalles del Viaje
    - Entrar a Detalles del Expedidor
  ],
  table.cell(fill: col9-task)[
    - Filtrar por Ubicación Origen
    - Filtrar por rangos de Fecha de retiro
    - Filtrar por Peso
    - Filtrar por Volumen
  ],
  table.cell(fill: col10-task)[
    - Seleccionar Fecha de Retiro del producto
    - Ingresar Dirección completa de Retiro del producto
    - Ingresar Dirección completa de Entrega del producto
  ],
  table.cell(fill: col11-task)[
    - Realizar el pago
    - Reserva instantánea
    - Brindar Datos de contacto del Transportista
  ],
  table.cell(fill: col12-task)[
    - Ofrecer venta de seguros
    - Aceptar compra de un seguro
    - Enviar documentación del seguro
  ],
  table.cell(fill: col13-task)[
    - Aceptar viaje
  ],
  table.cell(fill: col14-task)[
    - Confirmar retiro de determinado producto
    - Confirmar entrega de determinado producto
  ],
  table.cell(fill: col15-task)[
    - Hacer reseña al transportista
    - Leer Reseñas
    - Editar o eliminar una reseña hecha previamente
  ],

  // ── MVP — Release 1 Marker ────────────────────────────────────────────────────────
  table.cell(colspan: 15, fill: release-color, align: center)[
    #text(fill: black, weight: "bold")[MVP — Release 1]
  ],
  // ── Post MVP — Release 2 Stories ──────────────────────────────────────────────────────────
  table.cell(fill: col1-task)[],
  table.cell(fill: col2-task)[
    - Cambiar Contraseña
  ],
  table.cell(fill: col3-task)[
    - Ver mi historial de viajes
  ],
  table.cell(fill: col4-task)[
    - Paginado
    - Sort By
  ],
  table.cell(fill: col5-task)[],
  table.cell(fill: col6-task)[
    - Ver historial de viajes del transportista
  ],
  table.cell(fill: col7-task)[],
  table.cell(fill: col8-task)[
    - Paginado
    - Sort By
    - Ver historial de viajes del consumidor
  ],
  table.cell(fill: col9-task)[
    - Filtrar por Ubicación Destino
  ],
  table.cell(fill: col10-task)[],
  table.cell(fill: col11-task)[],
  table.cell(fill: col12-task)[
    - Filtrar entre seguros
  ],
  table.cell(fill: col13-task)[],
  table.cell(fill: col14-task)[],
  table.cell(fill: col15-task)[],

  // ── Post MVP — Release 2 Marker ────────────────────────────────────────────────────────
  table.cell(colspan: 15, fill: release-color, align: center)[
    #text(fill: black, weight: "bold")[Post MVP — Release 2]
  ],
  // ── Post MVP — Release 3 Stories ──────────────────────────────────────────────────────────
  table.cell(fill: col1-task)[
    - Verificar cuenta mediante mail
  ],
  table.cell(fill: col2-task)[],
  table.cell(fill: col3-task)[],
  table.cell(fill: col4-task)[
    - Guardado de búsquedas
  ],
  table.cell(fill: col5-task)[
    - Filtrar por Distancia
  ],
  table.cell(fill: col6-task)[],
  table.cell(fill: col7-task)[
    - Poner un límite de kilometros
  ],
  table.cell(fill: col8-task)[],
  table.cell(fill: col9-task)[
    - Estimar una fecha de entrega según los viajes aceptados
  ],
  table.cell(fill: col10-task)[],
  table.cell(fill: col11-task)[
    - Integración con Mercado Pago
    - Recibir pago de la app por los viajes concretados
    - Efectuar pago al transportista
  ],
  table.cell(fill: col12-task)[
    - Recibir pago por el servicio del seguro
    - Hacer pago al seguro
  ],
  table.cell(fill: col13-task)[],
  table.cell(fill: col14-task)[
    - Integración con Google Maps
    - Ver siguiente Destino (Ubicacion completa)
    - Ver recorrido por GPS
  ],
  table.cell(fill: col15-task)[],

  // ── Post MVP — Release 3 Marker ────────────────────────────────────────────────────────
  table.cell(colspan: 15, fill: release-color, align: center)[
    #text(fill: black, weight: "bold")[Post MVP — Release 3]
  ],
)
