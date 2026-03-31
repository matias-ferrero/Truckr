#import "template.typ": conf
#show: conf

#set page(flipped: true, margin: (x: 0.8cm, y: 1.2cm))

#let c-epic = rgb("#154360")
#let c-activ = rgb("#1f618d")
#let c-task = rgb("#aed6f1")
#let c-mvp-lane = rgb("#1e8449")
#let c-mvp = rgb("#d5f5e3")
#let c-post-lane = rgb("#6e2f1a")
#let c-post = rgb("#fef5e4")

= User Story Map — Productor

// 9 columns:
// Cuenta (3): Crear | Login | Perfil
// Ver Transportistas Disponibles (3): Búsqueda | Filtros | Detalles del Transportista
// Reservar Transportista (2): Ofertar | Pagos
// Después del viaje (1): Reseñas

#set text(size: 7.5pt)

#table(
  columns: (1fr,) * 9,
  stroke: 0.5pt + luma(160),
  inset: (x: 6pt, y: 5pt),

  // ── Row 1: Backbone — Epics ─────────────────────────────────────────────
  table.cell(colspan: 3, fill: c-epic, align: center)[
    #text(fill: white, weight: "bold")[Cuenta]
  ],
  table.cell(colspan: 3, fill: c-epic, align: center)[
    #text(fill: white, weight: "bold")[Ver Transportistas Disponibles]
  ],
  table.cell(colspan: 2, fill: c-epic, align: center)[
    #text(fill: white, weight: "bold")[Reservar Transportista]
  ],
  table.cell(fill: c-epic, align: center)[
    #text(fill: white, weight: "bold")[Después del viaje]
  ],

  // ── Row 2: Activities ───────────────────────────────────────────────────
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
    #text(fill: white, weight: "bold")[Ofertar]
  ],
  table.cell(fill: c-activ, align: center)[
    #text(fill: white, weight: "bold")[Pagos]
  ],
  table.cell(fill: c-activ, align: center)[
    #text(fill: white, weight: "bold")[Reseñas]
  ],

  // ── Row 3: Walking Skeleton — Tasks ─────────────────────────────────────
  table.cell(fill: c-task)[Ingresar Email y Usuario],
  table.cell(fill: c-task)[Ingresar Email o Usuario],
  table.cell(fill: c-task)[Completar datos personales de mi perfil],
  table.cell(fill: c-task)[
    - Ingresar Ubicación Origen
    - Ingresar Ubicación Destino
  ],
  table.cell(fill: c-task)[Filtrar por Precio/Km],
  table.cell(fill: c-task)[Ver Fotos y Descripción],
  table.cell(fill: c-task)[Seleccionar Fecha de Retiro del producto],
  table.cell(fill: c-task)[Realizar el pago seguro integrado],
  table.cell(fill: c-task)[Hacer reseña al transportista],

  // ── MVP Swim Lane ────────────────────────────────────────────────────────
  table.cell(colspan: 9, fill: c-mvp-lane, align: center)[
    #text(fill: white, weight: "bold")[MVP — Release 1]
  ],

  // ── MVP Stories ──────────────────────────────────────────────────────────
  table.cell(fill: c-mvp)[
    - Ingresar Contraseña
  ],
  table.cell(fill: c-mvp)[
    - Ingresar Contraseña
    - Clickear Boton de Login
  ],
  table.cell(fill: c-mvp)[
    - Guardar los cambios
    - Ver mi historial de viajes
  ],
  table.cell(fill: c-mvp)[
    - Ingresar rango de Fecha de Retiro
    - Paginado
    - Scrollear entre Transportistas Disponibles
    - Sort By
  ],
  table.cell(fill: c-mvp)[
    - Integración con Google Maps
    - Filtrar por Dimensiones
    - Filtrar por capacidad del camión
  ],
  table.cell(fill: c-mvp)[
    - Ver Precio del Servicio
    - Ver su historial de viajes
  ],
  table.cell(fill: c-mvp)[
    - Ingresar Dirección completa de Retiro del producto
    - Ingresar Dirección completa de Entrega del producto
  ],
  table.cell(fill: c-mvp)[
    - Reserva instantánea
    - Brindar Datos de contacto del Transportista
  ],
  table.cell(fill: c-mvp)[],

  // ── Post-MVP Swim Lane ───────────────────────────────────────────────────
  table.cell(colspan: 9, fill: c-post-lane, align: center)[
    #text(fill: white, weight: "bold")[Post-MVP — Release 2+]
  ],

  // ── Post-MVP Stories ─────────────────────────────────────────────────────
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
  table.cell(fill: c-post)[
    - Leer Reseñas
  ],
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[],
)
