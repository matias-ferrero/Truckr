#import "../template.typ": c-activ, c-epic, c-mvp, c-mvp-lane, c-post, c-post-lane, c-task, conf
#show: conf

#set page(flipped: true, margin: (x: 0.8cm, y: 1.2cm))

= User Story Map

#set text(size: 7.5pt)

#table(
  columns: (1fr,) * 15,
  inset: (x: 6pt, y: 5pt),

  // ── Row 1: Backbone — Epics ─────────────────────────────────────────────
  table.cell(colspan: 3, fill: c-epic, align: center)[
    #text(fill: white, weight: "bold")[Cuenta]
  ],
  table.cell(colspan: 3, fill: c-epic, align: center)[
    #text(fill: white, weight: "bold")[Ver Transportistas Disponibles]
  ],
  table.cell(colspan: 3, fill: c-epic, align: center)[
    #text(fill: white, weight: "bold")[Gestión de Viajes]
  ],
  table.cell(colspan: 2, fill: c-epic, align: center)[
    #text(fill: white, weight: "bold")[Reservar Transportista]
  ],
  table.cell(colspan: 2, fill: c-epic, align: center)[
    #text(fill: white, weight: "bold")[Aceptar Viaje]
  ],
  table.cell(colspan: 2, fill: c-epic, align: center)[
    #text(fill: white, weight: "bold")[Después del viaje]
  ],
  table.cell(fill: c-activ, align: center)[
    #text(fill: white, weight: "bold")[Crear]
  ],
  table.cell(fill: c-activ, align: center)[
    #text(fill: white, weight: "bold")[Login]
  ],
  table.cell(fill: c-activ, align: center)[
    #text(fill: white, weight: "bold")[Perfil]
  ],
  table.cell(fill: c-activ, align: center)[
    #text(fill: white, weight: "bold")[Búsqueda]
  ],
  table.cell(fill: c-activ, align: center)[
    #text(fill: white, weight: "bold")[Filtros]
  ],
  table.cell(fill: c-activ, align: center)[
    #text(fill: white, weight: "bold")[Detalles del Transportista]
  ],
  table.cell(fill: c-activ, align: center)[
    #text(fill: white, weight: "bold")[Publicación de Disponibilidad de Transporte]
  ],
  table.cell(fill: c-activ, align: center)[
    #text(fill: white, weight: "bold")[Ofertas de Viaje]
  ],
  table.cell(fill: c-activ, align: center)[
    #text(fill: white, weight: "bold")[Filtros]
  ],
  table.cell(fill: c-activ, align: center)[
    #text(fill: white, weight: "bold")[Ofertar]
  ],
  table.cell(fill: c-activ, align: center)[
    #text(fill: white, weight: "bold")[Pagos]
  ],
  table.cell(fill: c-activ, align: center)[
    #text(fill: white, weight: "bold")[Aceptación de Viaje]
  ],
  table.cell(fill: c-activ, align: center)[
    #text(fill: white, weight: "bold")[Realizar Viaje]
  ],
  table.cell(fill: c-activ, align: center)[
    #text(fill: white, weight: "bold")[Pago]
  ],
  table.cell(fill: c-activ, align: center)[
    #text(fill: white, weight: "bold")[Reseñas]
  ],

  // ── MVP — Release 1 Stories ──────────────────────────────────────────────────────────
  table.cell(fill: c-mvp)[
    - Ingresar Email y Usuario
    - Ingresar Contraseña
  ],
  table.cell(fill: c-mvp)[
    - Ingresar Email o Usuario
    - Ingresar Contraseña
    - Clickear Boton de Login
  ],
  table.cell(fill: c-mvp)[
    - Completar datos personales de mi perfil
    - Guardar los cambios
  ],
  table.cell(fill: c-mvp)[
    - Ingresar Ubicación Origen
    - Ingresar Ubicación Destino
    - Ingresar rango de Fecha de Retiro
    - Scrollear entre Transportistas Disponibles
  ],
  table.cell(fill: c-mvp)[
    - Filtrar por Precio/Km
    - Filtrar por Dimensiones
    - Filtrar por capacidad del camión
  ],
  table.cell(fill: c-mvp)[
    - Ver Fotos y Descripción
    - Ver Precio del Servicio
  ],
  table.cell(fill: c-mvp)[
    - Ingresar Precio/Km
    - Publicar zona origen
  ],
  table.cell(fill: c-mvp)[
    - Observar Listado de Ofertas
  ],
  table.cell(fill: c-mvp)[
    - Filtrar por Ubicación Origen
    - Filtrar por rangos de Fecha de retiro
    - Filtrar por Peso
    - Filtrar por Volumen
  ],
  table.cell(fill: c-mvp)[
    - Seleccionar Fecha de Retiro del producto
    - Ingresar Dirección completa de Retiro del producto
    - Ingresar Dirección completa de Entrega del producto
  ],
  table.cell(fill: c-mvp)[
    - Realizar el pago seguro integrado
    - Reserva instantánea
    - Brindar Datos de contacto del Transportista
  ],
  table.cell(fill: c-mvp)[
    - Aceptar viaje
  ],
  table.cell(fill: c-mvp)[
    - Integración con Google Maps
    - Ver siguiente Destino (Ubicacion completa)
    - Ver recorrido por GPS
  ],
  table.cell(fill: c-mvp)[
    - Integración con Mercado Pago
    - Recibir pago de la app por los viajes concretados
    - Efectuar pago al transportista
  ],
  table.cell(fill: c-mvp)[],

  // ── MVP — Release 1 Marker ────────────────────────────────────────────────────────
  table.cell(colspan: 15, fill: c-mvp-lane, align: center)[
    #text(fill: white, weight: "bold")[MVP — Release 1]
  ],
  // ── Post MVP — Release 2 Stories ──────────────────────────────────────────────────────────
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[
    - Cambiar Contraseña
  ],
  table.cell(fill: c-post)[
    - Ver mi historial de viajes
  ],
  table.cell(fill: c-post)[
    - Paginado
    - Sort By
  ],
  table.cell(fill: c-post)[
    - Filtrar por Distancia
  ],
  table.cell(fill: c-post)[
    - Ver su historial de viajes
  ],
  table.cell(fill: c-post)[
    - Poner un límite de kilometros
  ],
  table.cell(fill: c-post)[
    - Entrar a Detalles del Viaje
    - Paginado
    - Sort By
  ],
  table.cell(fill: c-post)[
    - Filtrar por Ubicación Destino
  ],
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[
    - Confirmar retiro de determinado producto
    - Confirmar entrega de determinado producto
  ],
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[
    - Hacer reseña al transportista
    - Leer Reseñas
  ],

  // ── Post MVP — Release 2 Marker ────────────────────────────────────────────────────────
  table.cell(colspan: 15, fill: c-post-lane, align: center)[
    #text(fill: white, weight: "bold")[Post MVP — Release 2]
  ],
  // ── Post MVP — Release 3 Stories ──────────────────────────────────────────────────────────
  table.cell(fill: c-post)[
    - Verificar cuenta mediante mail
  ],
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[
    - Ingresar datos extras
    - Guardado de búsquedas
  ],
  table.cell(fill: c-post)[
    - Filtrar si Es Contenedor
  ],
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[
    - Entrar a Detalles del Cliente
    - Ver su historial de viajes
  ],
  table.cell(fill: c-post)[
    - Estimar una fecha de entrega según los viajes aceptados
  ],
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[
    - Editar o eliminar una reseña hecha previamente
  ],

  // ── Post MVP — Release 3 Marker ────────────────────────────────────────────────────────
  table.cell(colspan: 15, fill: c-post-lane, align: center)[
    #text(fill: white, weight: "bold")[Post MVP — Release 3]
  ],
)