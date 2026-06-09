#import "../template.typ": c-activ, c-epic, c-mvp, c-mvp-lane, c-post, c-post-lane, c-task, conf
#show: conf

#set page(flipped: true, paper: "a3", margin: (x: 0.5cm, y: 0.8cm))

// ── Color definitions extracted from spreadsheet ──────────────────────────
#let col1-task = rgb("#FCE5CD")
#let col1-activ = rgb("#F6B26B")
#let col2-task = rgb("#FCE5CD")
#let col2-activ = rgb("#F6B26B")
#let col3-task = rgb("#FCE5CD")
#let col3-activ = rgb("#F6B26B")
#let col4-task = rgb("#FCE5CD")
#let col4-activ = rgb("#F6B26B")
#let col5-task = rgb("#FCE5CD")
#let col5-activ = rgb("#F6B26B")
#let col6-task = rgb("#D9EAD3")
#let col6-activ = rgb("#93C47D")
#let col7-task = rgb("#D9EAD3")
#let col7-activ = rgb("#93C47D")
#let col8-task = rgb("#CFE2F3")
#let col8-activ = rgb("#6FA8DC")
#let col9-task = rgb("#CFE2F3")
#let col9-activ = rgb("#6FA8DC")
#let col10-task = rgb("#EAD1DC")
#let col10-activ = rgb("#C27BA0")
#let col11-task = rgb("#EAD1DC")
#let col11-activ = rgb("#C27BA0")
#let col12-task = rgb("#E6B8AF")
#let col12-activ = rgb("#CC4125")
#let col13-task = rgb("#E6B8AF")
#let col13-activ = rgb("#CC4125")
#let col14-task = rgb("#E6B8AF")
#let col14-activ = rgb("#CC4125")
#let col15-task = rgb("#FFF2CC")
#let col15-activ = rgb("#FFD966")
#let col16-task = rgb("#FFF2CC")
#let col16-activ = rgb("#FFD966")
#let col17-task = rgb("#D9D2E9")
#let col17-activ = rgb("#8E7CC3")
#let col18-task = rgb("#D9D2E9")
#let col18-activ = rgb("#8E7CC3")
#let col19-task = rgb("#F4CCCC")
#let col19-activ = rgb("#E06666")
#let col20-task = rgb("#F4CCCC")
#let col20-activ = rgb("#E06666")
#let col21-task = rgb("#D9EAD3")
#let col21-activ = rgb("#93C47D")
#let epic-color = rgb("#9FC5E8")
#let release-color = rgb("#6AA84F")

= User Story Map

#set text(size: 9pt)

#table(
  columns: (2fr,) * 21,
  inset: (x: 4pt, y: 3pt),

  // ── Row 1: Backbone — Epics ─────────────────────────────────────────────
  table.cell(colspan: 5, fill: epic-color, align: center)[
    #text(fill: black, weight: "bold")[Cuenta]
  ],
  table.cell(colspan: 2, fill: epic-color, align: center)[
    #text(fill: black, weight: "bold")[Ventanas de Transporte]
  ],
  table.cell(colspan: 2, fill: epic-color, align: center)[
    #text(fill: black, weight: "bold")[Cargas]
  ],
  table.cell(colspan: 2, fill: epic-color, align: center)[
    #text(fill: black, weight: "bold")[Reservar Transportista]
  ],
  table.cell(colspan: 3, fill: epic-color, align: center)[
    #text(fill: black, weight: "bold")[Envíos]
  ],
  table.cell(colspan: 2, fill: epic-color, align: center)[
    #text(fill: black, weight: "bold")[Reseñas]
  ],
  table.cell(colspan: 2, fill: epic-color, align: center)[
    #text(fill: black, weight: "bold")[Servicio de Pagos]
  ],
  table.cell(colspan: 2, fill: epic-color, align: center)[
    #text(fill: black, weight: "bold")[Notificaciones]
  ],
  table.cell(colspan: 1, fill: epic-color, align: center)[
    #text(fill: black, weight: "bold")[Seguros]
  ],
  table.cell(fill: col1-activ, align: center)[
    #text(fill: black, weight: "bold")[Registro]
  ],
  table.cell(fill: col2-activ, align: center)[
    #text(fill: black, weight: "bold")[Login]
  ],
  table.cell(fill: col3-activ, align: center)[
    #text(fill: black, weight: "bold")[Perfil]
  ],
  table.cell(fill: col4-activ, align: center)[
    #text(fill: black, weight: "bold")[Dashboard]
  ],
  table.cell(fill: col5-activ, align: center)[
    #text(fill: black, weight: "bold")[Flota de Transportista]
  ],
  table.cell(fill: col6-activ, align: center)[
    #text(fill: black, weight: "bold")[Publicar]
  ],
  table.cell(fill: col7-activ, align: center)[
    #text(fill: black, weight: "bold")[Administrar]
  ],
  table.cell(fill: col8-activ, align: center)[
    #text(fill: black, weight: "bold")[Publicar]
  ],
  table.cell(fill: col9-activ, align: center)[
    #text(fill: black, weight: "bold")[Administrar]
  ],
  table.cell(fill: col10-activ, align: center)[
    #text(fill: black, weight: "bold")[Busqueda y Filtrado]
  ],
  table.cell(fill: col11-activ, align: center)[
    #text(fill: black, weight: "bold")[Ofertas]
  ],
  table.cell(fill: col12-activ, align: center)[
    #text(fill: black, weight: "bold")[Administrar]
  ],
  table.cell(fill: col13-activ, align: center)[
    #text(fill: black, weight: "bold")[Aceptar]
  ],
  table.cell(fill: col14-activ, align: center)[
    #text(fill: black, weight: "bold")[Realizar]
  ],
  table.cell(fill: col15-activ, align: center)[
    #text(fill: black, weight: "bold")[Altas y Consultas]
  ],
  table.cell(fill: col16-activ, align: center)[
    #text(fill: black, weight: "bold")[Bajas y Modificaciones]
  ],
  table.cell(fill: col17-activ, align: center)[
    #text(fill: black, weight: "bold")[Realizar Pago]
  ],
  table.cell(fill: col18-activ, align: center)[
    #text(fill: black, weight: "bold")[Bandeja]
  ],
  table.cell(fill: col19-activ, align: center)[
    #text(fill: black, weight: "bold")[Ofertas]
  ],
  table.cell(fill: col20-activ, align: center)[
    #text(fill: black, weight: "bold")[Pagos]
  ],
  table.cell(fill: col21-activ, align: center)[
    #text(fill: black, weight: "bold")[Gestión de Seguros]
  ],

  // ── MVP — Stories ─────────────────────────────────────────────────────
  table.cell(fill: col1-task)[
    - US001: Registrarse
    - US038: Landing Page
  ],
  table.cell(fill: col2-task)[
    - US002: Login
  ],
  table.cell(fill: col3-task)[
    - US006: Perfil de Transportista
    - US059: Perfil de Expedidor
    - US003: Modificar perfil
  ],
  table.cell(fill: col4-task)[
    - US036: Dashboard del Transportista
    - US037: Dashboard del Expedidor
  ],
  table.cell(fill: col5-task)[
    - US014: Registro de Vehiculo
    - US042: Administrar mi flota
    - US031: Editar Vehiculo de mi flota
    - US032: Baja de Vehiculo
  ],
  table.cell(fill: col6-task)[
    - US009: Publicar Ventana de Transporte
    - US050: Definir radio de recogida
    - US048: Selector de direcciones - Ventana de Transporte
  ],
  table.cell(fill: col7-task)[
    - US043: Administrar mis Ventanas de Transporte
    - US033: Editar Ventana de Transporte
    - US035: Ocultar Ventana de Transporte
    - US034: Eliminar Ventana de Transporte
  ],
  table.cell(fill: col8-task)[
    - US027: Publicar carga
    - US049: Selector de direcciones - Carga
    - US053: Autocalculado de distancia
  ],
  table.cell(fill: col9-task)[
    - US044: Administrar cargas
    - US045: Filtrar mis cargas
    - US046: Ver detalles de una carga
    - US047: Editar carga
  ],
  table.cell(fill: col10-task)[
    - US004: Busqueda de Ventanas Compatibles con mi Carga
    - US025: Paginado de Ventanas Compatibles con mi Carga
  ],
  table.cell(fill: col11-task)[
    - US007: Ofertar retiro de una carga
    - US010: Observar ofertas de envio
  ],
  table.cell(fill: col12-task)[
    - US017: Listado de envios de Transportista
    - US052: Listado de envios de Expedidor
    - US039: Detalles de envio
    - US051: Mapa en detalles de envio
  ],
  table.cell(fill: col13-task)[
    - US012: Aceptacion de oferta de envio
  ],
  table.cell(fill: col14-task)[
    - US018: Actualizacion de Envio - Inicio de Envio
    - US019: Actualizacion de Envio - Carga entregada
  ],
  table.cell(fill: col15-task)[
    - US020: Crear reseña del transportista
    - US026: Visualizar Reseñas del transportista
    - US030: Crear reseña del expedidor
    - US054: Visualizar Reseñas del expedidor
  ],
  table.cell(fill: col16-task)[],
  table.cell(fill: col17-task)[
    - US008: Realizar pago (Expedidor)
    - US015: Pago al Transportista
  ],
  table.cell(fill: col18-task)[
    - US040: Mis pagos como transportista
  ],
  table.cell(fill: col19-task)[
    - US058: Notificacion en tiempo real de Oferta Recibida
    - US057: Notificacion en tiempo real de Respuesta a mi Oferta
  ],
  table.cell(fill: col20-task)[
    - US060: Notificacion en tiempo real de Pago Recibido
  ],
  table.cell(fill: col21-task)[],

  // ── MVP — Marker ───────────────────────────────────────────────────────
  table.cell(colspan: 21, fill: release-color, align: center)[
    #text(fill: black, weight: "bold")[MVP]
  ],
  // ── Release 2 — Stories ─────────────────────────────────────────────────────
  table.cell(fill: col1-task)[
    - US022: Verificacion de cuenta por Email
  ],
  table.cell(fill: col2-task)[
    - US016: Cambiar Contraseña
    - US041: Recupero de Contraseña
  ],
  table.cell(fill: col3-task)[],
  table.cell(fill: col4-task)[],
  table.cell(fill: col5-task)[],
  table.cell(fill: col6-task)[],
  table.cell(fill: col7-task)[],
  table.cell(fill: col8-task)[],
  table.cell(fill: col9-task)[],
  table.cell(fill: col10-task)[
    - US005: Filtrar ventanas compatibles
  ],
  table.cell(fill: col11-task)[
    - US011: Filtrado de ofertas de envio
  ],
  table.cell(fill: col12-task)[],
  table.cell(fill: col13-task)[],
  table.cell(fill: col14-task)[],
  table.cell(fill: col15-task)[],
  table.cell(fill: col16-task)[
    - US028: Editar reseña del transportista
    - US029: Eliminar reseña del transportista
    - US055: Editar reseña del expedidor
    - US056: Eliminar una reseña del expedidor
  ],
  table.cell(fill: col17-task)[],
  table.cell(fill: col18-task)[],
  table.cell(fill: col19-task)[],
  table.cell(fill: col20-task)[],
  table.cell(fill: col21-task)[],

  // ── Release 2 — Marker ───────────────────────────────────────────────────────
  table.cell(colspan: 21, fill: release-color, align: center)[
    #text(fill: black, weight: "bold")[Release 2]
  ],
  // ── Release 3 — Stories ─────────────────────────────────────────────────────
  table.cell(fill: col1-task)[],
  table.cell(fill: col2-task)[],
  table.cell(fill: col3-task)[],
  table.cell(fill: col4-task)[],
  table.cell(fill: col5-task)[],
  table.cell(fill: col6-task)[],
  table.cell(fill: col7-task)[],
  table.cell(fill: col8-task)[],
  table.cell(fill: col9-task)[],
  table.cell(fill: col10-task)[],
  table.cell(fill: col11-task)[],
  table.cell(fill: col12-task)[
    - US023: Envios compuestos
    - US024: Encadenado de pedidos
  ],
  table.cell(fill: col13-task)[],
  table.cell(fill: col14-task)[
    - US021: Tracking de Envio
    - US013: Navegacion GPS del Envio
  ],
  table.cell(fill: col15-task)[],
  table.cell(fill: col16-task)[],
  table.cell(fill: col17-task)[],
  table.cell(fill: col18-task)[],
  table.cell(fill: col19-task)[],
  table.cell(fill: col20-task)[],
  table.cell(fill: col21-task)[
    - US061: Contratar seguro al reservar transporte
    - US062: Iniciar reclamo de siniestro
    - US063: Detalles del seguro
  ],

  // ── Release 3 — Marker ───────────────────────────────────────────────────────
  table.cell(colspan: 21, fill: release-color, align: center)[
    #text(fill: black, weight: "bold")[Release 3]
  ],
)