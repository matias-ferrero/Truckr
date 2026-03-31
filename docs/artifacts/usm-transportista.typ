#import "template.typ": c-activ, c-epic, c-mvp, c-mvp-lane, c-post, c-post-lane, c-task, conf
#show: conf

#set page(flipped: true, margin: (x: 0.8cm, y: 1.2cm))

= User Story Map — Transportista

// 10 columns:
// Cuenta (3): Crear | Login | Perfil
// Gestión de Viajes (3): Publicación de Disponibilidad | Ofertas de Viaje | Filtros
// Aceptar Viaje (2): Aceptación de Viaje | Realizar Viaje
// Después del viaje (2): Pago | Reseñas

#set text(size: 7.5pt)

#table(
  columns: (1fr,) * 10,
  inset: (x: 6pt, y: 5pt),

  // ── Row 1: Backbone — Epics ─────────────────────────────────────────────
  table.cell(colspan: 3, fill: c-epic, align: center)[
    #text(fill: white, weight: "bold")[Cuenta]
  ],
  table.cell(colspan: 3, fill: c-epic, align: center)[
    #text(fill: white, weight: "bold")[Gestión de Viajes]
  ],
  table.cell(colspan: 2, fill: c-epic, align: center)[
    #text(fill: white, weight: "bold")[Aceptar Viaje]
  ],
  table.cell(colspan: 2, fill: c-epic, align: center)[
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
    #text(fill: white, weight: "bold")[Publicación de Disponibilidad]
  ],
  table.cell(fill: c-activ, align: center)[
    #text(fill: white, weight: "bold")[Ofertas de Viaje]
  ],
  table.cell(fill: c-activ, align: center)[
    #text(fill: white, weight: "bold")[Filtros]
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

  // ── Row 3: Walking Skeleton — Tasks ─────────────────────────────────────
  table.cell(fill: c-task)[Ingresar Email y Usuario],
  table.cell(fill: c-task)[Ingresar Email o Usuario],
  table.cell(fill: c-task)[Completar datos personales y del camión en mi perfil],
  table.cell(fill: c-task)[Publicar zona origen],
  table.cell(fill: c-task)[Observar Listado de Ofertas],
  table.cell(fill: c-task)[
    - Filtrar por Ubicación Origen
    - Filtrar por Ubicación Destino
  ],
  table.cell(fill: c-task)[Aceptar viaje],
  table.cell(fill: c-task)[Ver siguiente Destino (Ubicación completa)],
  table.cell(fill: c-task)[Recibir pago de la app por los viajes concretados],
  table.cell(fill: c-task)[],

  // ── MVP Swim Lane ────────────────────────────────────────────────────────
  table.cell(colspan: 10, fill: c-mvp-lane, align: center)[
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
  ],
  table.cell(fill: c-mvp)[
    - Poner un límite de kilometros
    - Ingresar Precio/Km
  ],
  table.cell(fill: c-mvp)[],
  table.cell(fill: c-mvp)[
    - Filtrar por rangos de Fecha de retiro
    - Filtrar por Peso
    - Filtrar por Volumen
  ],
  table.cell(fill: c-mvp)[],
  table.cell(fill: c-mvp)[
    - Ver recorrido por GPS
    - Confirmar retiro de determinado producto
    - Confirmar entrega de determinado producto
  ],
  table.cell(fill: c-mvp)[],
  table.cell(fill: c-mvp)[],

  // ── Post-MVP Swim Lane ───────────────────────────────────────────────────
  table.cell(colspan: 10, fill: c-post-lane, align: center)[
    #text(fill: white, weight: "bold")[Post-MVP — Release 2+]
  ],

  // ── Post-MVP Stories ─────────────────────────────────────────────────────
  table.cell(fill: c-post)[
    - Chequear Email para verificar el correcto Registro
  ],
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[
    - Entrar a Detalles del Viaje
    - Entrar a Detalles del Cliente
    - Leer Reseñas
  ],
  table.cell(fill: c-post)[
    - Estimar una fecha de entrega según los viajes aceptados
  ],
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[],
  table.cell(fill: c-post)[],
)
