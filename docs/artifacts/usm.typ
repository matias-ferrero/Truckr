#import "../template.typ": c-activ, c-epic, c-mvp, c-mvp-lane, c-post, c-post-lane, c-task, conf
#show: conf

#set page(flipped: true, margin: (x: 0.8cm, y: 1.2cm))

= User Story Map

#set text(size: 7.5pt)

#table(
  columns: (1fr,) * 15,
  inset: (x: 6pt, y: 5pt),

  // ── Row 1: Backbone — Epics ─────────────────────────────────────────────
  table.cell(colspan: 3, fill: rgb("#9FC5E8"), align: center)[
    #text(fill: black, weight: "bold")[Cuenta]
  ],
  table.cell(colspan: 3, fill: rgb("#9FC5E8"), align: center)[
    #text(fill: black, weight: "bold")[Ver Transportistas Disponibles]
  ],
  table.cell(colspan: 3, fill: rgb("#9FC5E8"), align: center)[
    #text(fill: black, weight: "bold")[Gestión de Viajes]
  ],
  table.cell(colspan: 2, fill: rgb("#9FC5E8"), align: center)[
    #text(fill: black, weight: "bold")[Reservar Transportista]
  ],
  table.cell(colspan: 2, fill: rgb("#9FC5E8"), align: center)[
    #text(fill: black, weight: "bold")[Aceptar Viaje]
  ],
  table.cell(colspan: 2, fill: rgb("#9FC5E8"), align: center)[
    #text(fill: black, weight: "bold")[Después del viaje]
  ],
  table.cell(fill: rgb("#F9CB9C"), align: center)[
    #text(fill: black, weight: "bold")[Crear]
  ],
  table.cell(fill: rgb("#F9CB9C"), align: center)[
    #text(fill: black, weight: "bold")[Login]
  ],
  table.cell(fill: rgb("#F9CB9C"), align: center)[
    #text(fill: black, weight: "bold")[Perfil]
  ],
  table.cell(fill: rgb("#EA9999"), align: center)[
    #text(fill: black, weight: "bold")[Búsqueda]
  ],
  table.cell(fill: rgb("#EA9999"), align: center)[
    #text(fill: black, weight: "bold")[Filtros]
  ],
  table.cell(fill: rgb("#EA9999"), align: center)[
    #text(fill: black, weight: "bold")[Detalles del Transportista]
  ],
  table.cell(fill: rgb("#B6D7A8"), align: center)[
    #text(fill: black, weight: "bold")[Publicación de Disponibilidad de Transporte]
  ],
  table.cell(fill: rgb("#B6D7A8"), align: center)[
    #text(fill: black, weight: "bold")[Ofertas de Viaje]
  ],
  table.cell(fill: rgb("#B6D7A8"), align: center)[
    #text(fill: black, weight: "bold")[Filtros]
  ],
  table.cell(fill: rgb("#C27BA0"), align: center)[
    #text(fill: black, weight: "bold")[Ofertar]
  ],
  table.cell(fill: rgb("#C27BA0"), align: center)[
    #text(fill: black, weight: "bold")[Pagos]
  ],
  table.cell(fill: rgb("#8E7CC3"), align: center)[
    #text(fill: black, weight: "bold")[Aceptación de Viaje]
  ],
  table.cell(fill: rgb("#8E7CC3"), align: center)[
    #text(fill: black, weight: "bold")[Realizar Viaje]
  ],
  table.cell(fill: rgb("#FFE599"), align: center)[
    #text(fill: black, weight: "bold")[Pago]
  ],
  table.cell(fill: rgb("#FFE599"), align: center)[
    #text(fill: black, weight: "bold")[Reseñas]
  ],

  // ── MVP — Release 1 Stories ──────────────────────────────────────────────────────────
  table.cell(fill: rgb("#FCE5CD"))[
    - Ingresar Email y Usuario
    - Ingresar Contraseña
  ],
  table.cell(fill: rgb("#FCE5CD"))[
    - Ingresar Email o Usuario
    - Ingresar Contraseña
    - Clickear Boton de Login
  ],
  table.cell(fill: rgb("#FCE5CD"))[
    - Completar datos personales de mi perfil
    - Guardar los cambios
  ],
  table.cell(fill: rgb("#F4CCCC"))[
    - Ingresar Ubicación Origen
    - Ingresar Ubicación Destino
    - Ingresar rango de Fecha de Retiro
    - Scrollear entre Transportistas Disponibles
  ],
  table.cell(fill: rgb("#F4CCCC"))[
    - Filtrar por Precio/Km
    - Filtrar por Dimensiones
    - Filtrar por capacidad del camión
  ],
  table.cell(fill: rgb("#F4CCCC"))[
    - Ver Fotos y Descripción
    - Ver Precio del Servicio
  ],
  table.cell(fill: rgb("#D9EAD3"))[
    - Ingresar Precio/Km
    - Publicar zona origen
  ],
  table.cell(fill: rgb("#D9EAD3"))[
    - Observar Listado de Ofertas
  ],
  table.cell(fill: rgb("#D9EAD3"))[
    - Filtrar por Ubicación Origen
    - Filtrar por rangos de Fecha de retiro
    - Filtrar por Peso
    - Filtrar por Volumen
  ],
  table.cell(fill: rgb("#EAD1DC"))[
    - Seleccionar Fecha de Retiro del producto
    - Ingresar Dirección completa de Retiro del producto
    - Ingresar Dirección completa de Entrega del producto
  ],
  table.cell(fill: rgb("#EAD1DC"))[
    - Realizar el pago seguro integrado
    - Reserva instantánea
    - Brindar Datos de contacto del Transportista
  ],
  table.cell(fill: rgb("#D9D2E9"))[
    - Aceptar viaje
  ],
  table.cell(fill: rgb("#D9D2E9"))[
    - Integración con Google Maps
    - Ver siguiente Destino (Ubicacion completa)
    - Ver recorrido por GPS
  ],
  table.cell(fill: rgb("#FFF2CC"))[
    - Integración con Mercado Pago
    - Recibir pago de la app por los viajes concretados
    - Efectuar pago al transportista
  ],
  table.cell(fill: rgb("#FCE5CD"))[],

  // ── MVP — Release 1 Marker ────────────────────────────────────────────────────────
  table.cell(colspan: 15, fill: rgb("#6AA84F"), align: center)[
    #text(fill: black, weight: "bold")[MVP — Release 1]
  ],
  // ── Post MVP — Release 2 Stories ──────────────────────────────────────────────────────────
  table.cell(fill: rgb("#FCE5CD"))[],
  table.cell(fill: rgb("#FCE5CD"))[
    - Cambiar Contraseña
  ],
  table.cell(fill: rgb("#FCE5CD"))[
    - Ver mi historial de viajes
  ],
  table.cell(fill: rgb("#F4CCCC"))[
    - Paginado
    - Sort By
  ],
  table.cell(fill: rgb("#F4CCCC"))[
    - Filtrar por Distancia
  ],
  table.cell(fill: rgb("#F4CCCC"))[
    - Ver su historial de viajes
  ],
  table.cell(fill: rgb("#D9EAD3"))[
    - Poner un límite de kilometros
  ],
  table.cell(fill: rgb("#D9EAD3"))[
    - Entrar a Detalles del Viaje
    - Paginado
    - Sort By
  ],
  table.cell(fill: rgb("#D9EAD3"))[
    - Filtrar por Ubicación Destino
  ],
  table.cell(fill: rgb("#EAD1DC"))[],
  table.cell(fill: rgb("#EAD1DC"))[],
  table.cell(fill: rgb("#D9D2E9"))[],
  table.cell(fill: rgb("#D9D2E9"))[
    - Confirmar retiro de determinado producto
    - Confirmar entrega de determinado producto
  ],
  table.cell(fill: rgb("#FFF2CC"))[],
  table.cell(fill: rgb("#FCE5CD"))[
    - Hacer reseña al transportista
    - Leer Reseñas
  ],

  // ── Post MVP — Release 2 Marker ────────────────────────────────────────────────────────
  table.cell(colspan: 15, fill: rgb("#6AA84F"), align: center)[
    #text(fill: black, weight: "bold")[Post MVP — Release 2]
  ],
  // ── Post MVP — Release 3 Stories ──────────────────────────────────────────────────────────
  table.cell(fill: rgb("#FCE5CD"))[
    - Verificar cuenta mediante mail
  ],
  table.cell(fill: rgb("#FCE5CD"))[],
  table.cell(fill: rgb("#FCE5CD"))[],
  table.cell(fill: rgb("#F4CCCC"))[
    - Ingresar datos extras
    - Guardado de búsquedas
  ],
  table.cell(fill: rgb("#F4CCCC"))[
    - Filtrar si Es Contenedor
  ],
  table.cell(fill: rgb("#F4CCCC"))[],
  table.cell(fill: rgb("#D9EAD3"))[],
  table.cell(fill: rgb("#D9EAD3"))[
    - Entrar a Detalles del Cliente
    - Ver su historial de viajes
  ],
  table.cell(fill: rgb("#D9EAD3"))[
    - Estimar una fecha de entrega según los viajes aceptados
  ],
  table.cell(fill: rgb("#EAD1DC"))[],
  table.cell(fill: rgb("#EAD1DC"))[],
  table.cell(fill: rgb("#D9D2E9"))[],
  table.cell(fill: rgb("#D9D2E9"))[],
  table.cell(fill: rgb("#FFF2CC"))[],
  table.cell(fill: rgb("#FCE5CD"))[
    - Editar o eliminar una reseña hecha previamente
  ],

  // ── Post MVP — Release 3 Marker ────────────────────────────────────────────────────────
  table.cell(colspan: 15, fill: rgb("#6AA84F"), align: center)[
    #text(fill: black, weight: "bold")[Post MVP — Release 3]
  ],
)