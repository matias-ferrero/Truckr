#import "../template.typ": c-brand, c-brand-mid, conf, stroke-std
#show: conf

= Cronograma

Cronograma en formato planilla de trabajo por sprint, con tareas numeradas del backlog y su ventana prevista de implementación.

#set text(size: 8pt)

#table(
  columns: (
    1.2fr,
    0.8fr,
    1.4fr,
    0.9fr,
    0.42fr,
    0.42fr,
    0.42fr,
    0.42fr,
    0.42fr,
    0.42fr,
    0.42fr,
  ),
  inset: (x: 4pt, y: 3pt),
  stroke: stroke-std,
  align: (
    left,
    left,
    left,
    center,
    center,
    center,
    center,
    center,
    center,
    center,
    center,
  ),

  table.header(
    table.cell(fill: c-brand, align: center)[#text(
      fill: white,
      weight: "bold",
    )[Fase]],
    table.cell(fill: c-brand, align: center)[#text(
      fill: white,
      weight: "bold",
    )[ID]],
    table.cell(fill: c-brand, align: center)[#text(
      fill: white,
      weight: "bold",
    )[Tarea]],
    table.cell(fill: c-brand, align: center)[#text(
      fill: white,
      weight: "bold",
    )[Responsable]],
    table.cell(fill: c-brand, align: center)[#text(
      fill: white,
      weight: "bold",
    )[S1 \
      (06/05)]],
    table.cell(fill: c-brand, align: center)[#text(
      fill: white,
      weight: "bold",
    )[S2 \
      (13/05)]],
    table.cell(fill: c-brand, align: center)[#text(
      fill: white,
      weight: "bold",
    )[S3 \
      (20/05)]],
    table.cell(fill: c-brand, align: center)[#text(
      fill: white,
      weight: "bold",
    )[S4 \
      (27/05)]],
    table.cell(fill: c-brand, align: center)[#text(
      fill: white,
      weight: "bold",
    )[S5 \
      (03/06)]],
    table.cell(fill: c-brand, align: center)[#text(
      fill: white,
      weight: "bold",
    )[S6 \
      (10/06)]],
    table.cell(fill: c-brand, align: center)[#text(
      fill: white,
      weight: "bold",
    )[S7 \
      (17/06)]],
  ),

  [Planning],
  [A1],
  [Cierre de artefactos \ (cronograma, riesgos, \ costos, comunicaciones)],
  [Equipo + PM + PO],
  [X],
  [],
  [],
  [],
  [],
  [],
  [],

  [Planning], [A2], [Defensa de artefactos e inicio de desarrollo (06/05)], [Equipo], [X], [], [], [], [], [], [],

  [Sprint 1], [US1], [Registro de usuario], [Equipo], [X], [], [], [], [], [], [],

  [Sprint 1], [US2], [Login], [Equipo], [X], [], [], [], [], [], [],

  [Sprint 1], [US3], [Modificar perfil], [Equipo], [X], [], [], [], [], [], [],

  [Sprint 1], [US6], [Perfil de Transportista], [Equipo], [X], [], [], [], [], [], [],

  [Sprint 1], [US9], [Publicar disponibilidad], [Equipo], [X], [], [], [], [], [], [],

  [Sprint 1], [US14], [Registro de vehículo], [Equipo], [X], [], [], [], [], [], [],

  [Sprint 1], [US31], [Editar vehículo], [Equipo], [X], [], [], [], [], [], [],

  [Sprint 1], [US33], [Editar ventana de \ transporte], [Equipo], [X], [], [], [], [], [], [],

  [Sprint 1], [US34], [Eliminar ventana de \ transporte], [Equipo], [X], [], [], [], [], [], [],

  [Sprint 1], [US35], [Ocultar ventana de \ transporte], [Equipo], [X], [], [], [], [], [], [],

  [Sprint 1], [US36], [Dashboard del \ transportista], [Equipo], [X], [], [], [], [], [], [],

  [Sprint 1], [US37], [Dashboard del expedidor], [Equipo], [X], [], [], [], [], [], [],

  [Sprint 1], [US38], [Landing page], [Equipo], [X], [], [], [], [], [], [],

  [Sprint 1], [US42], [Administrar mi flota], [Equipo], [X], [], [], [], [], [], [],

  [Sprint 1], [US43], [Administrar ventanas de transporte], [Equipo], [X], [], [], [], [], [], [],

  [Sprint 2], [US7], [Ofertar retiro de producto], [Equipo], [], [X], [], [], [], [], [],

  [Sprint 2], [US27], [Publicar carga], [Equipo], [], [X], [], [], [], [], [],

  [Sprint 2], [US44], [Administrar cargas], [Equipo], [], [X], [], [], [], [], [],

  [Sprint 2], [US45], [Filtrar mis cargas], [Equipo], [], [X], [], [], [], [], [],

  [Sprint 2], [US46], [Ver detalles de una carga], [Equipo], [], [X], [], [], [], [], [],

  [Sprint 2], [US47], [Editar carga], [Equipo], [], [X], [], [], [], [], [],

  [Sprint 3], [US4], [Búsqueda de \ transportistas], [Equipo], [], [], [X], [], [], [], [],

  [Sprint 3], [US8], [Pago cliente (maquetado funcional)], [Equipo], [], [], [X], [], [], [], [],

  [Sprint 3], [US10], [Observar ofertas de envío], [Equipo], [], [], [X], [], [], [], [],

  [Sprint 3], [US12], [Aceptación de envío], [Equipo], [], [], [X], [], [], [], [],

  [Sprint 3], [US17], [Historial de envíos], [Equipo], [], [], [X], [], [], [], [],

  [Sprint 3], [US32], [Baja de vehículo], [Equipo], [], [], [X], [], [], [], [],

  [Sprint 3], [US39], [Detalles de envío], [Equipo], [], [], [X], [], [], [], [],

  [Sprint 3], [US52], [Listado de envíos de \ expedidor], [Equipo], [], [], [X], [], [], [], [],

  [Sprint 4], [US18], [Actualización de Envío — \ Inicio de Envio], [Equipo], [], [], [], [X], [], [], [],

  [Sprint 4], [US19], [Actualización de Envío — \ Carga Entregada], [Equipo], [], [], [], [X], [], [], [],

  [Sprint 4], [US20], [Crear reseña de \ Transportista], [Equipo], [], [], [], [X], [], [], [],

  [Sprint 4], [US26], [Visualizar reseñas de Transportista], [Equipo], [], [], [], [X], [], [], [],

  [Sprint 4], [US30], [Crear reseña de expedidor], [Equipo], [], [], [], [X], [], [], [],

  [Sprint 4], [US54], [Visualizar reseñas de \ expedidor], [Equipo], [], [], [], [X], [], [], [],

  [Sprint 4], [US59], [Perfil de expedidor], [Equipo], [], [], [], [X], [], [], [],

  [Sprint 4], [US48], [Selector de direcciones — Ventana de transporte], [Equipo], [], [], [], [X], [], [], [],

  [Sprint 4], [US49], [Selector de direcciones — Carga], [Equipo], [], [], [], [X], [], [], [],

  [Sprint 4], [US50], [Definir radio de recogida], [Equipo], [], [], [], [X], [], [], [],

  [Sprint 4], [US58], [Notificación de oferta \ recibida], [Equipo], [], [], [], [X], [], [], [],

  [Sprint 4], [US57], [Notificación de respuesta \ a mi oferta], [Equipo], [], [], [], [X], [], [], [],

  [Sprint 5], [US25], [Paginado de Ventanas \ Compatibles con mi Carga], [Equipo], [], [], [], [], [X], [], [],

  [Sprint 5], [US53], [Autocalculado de \ distancia], [Equipo], [], [], [], [], [X], [], [],

  [Sprint 5], [US51], [Mapa en detalle de envío], [Equipo], [], [], [], [], [X], [], [],

  [Sprint 5], [US15], [Pago al transportista], [Equipo], [], [], [], [], [X], [], [],

  [Sprint 5], [US40], [Mis Pagos como Transportista], [Equipo], [], [], [], [], [X], [], [],

  [Sprint 5], [US60], [Notificación en Tiempo \ Real de Pago Recibido], [Equipo], [], [], [], [], [X], [], [],

  [Sprint 5], [US64], [Panel Centrado en \ Cargas de Expedidor], [Equipo], [], [], [], [], [X], [], [],

  [Sprint 5], [US65], [Panel Centrado en \ Cargas de Transportista], [Equipo], [], [], [], [], [X], [], [],

  [Sprint 5], [US66], [Detalles de Envío \ centrado en la Acción], [Equipo], [], [], [], [], [X], [], [],

  [Sprint 5], [US67], [Navegación Lateral \ Persistente por Rol], [Equipo], [], [], [], [], [X], [], [],

  [Sprint 6 y 7], [A3], [Preparación de demo final], [Equipo + PM], [], [], [], [], [], [X], [X],
)

#v(0.8em)

== Hitos Clave

#table(
  columns: (1.4fr, auto, 1.8fr),
  inset: (x: 6pt, y: 6pt),
  stroke: stroke-std,
  align: (left, center, left),

  table.header(
    table.cell(fill: c-brand-mid, align: center)[#text(
      fill: white,
      weight: "bold",
    )[Hito]],
    table.cell(fill: c-brand-mid, align: center)[#text(
      fill: white,
      weight: "bold",
    )[Fecha]],
    table.cell(fill: c-brand-mid, align: center)[#text(
      fill: white,
      weight: "bold",
    )[Criterio]],
  ),

  [Cierre de artefactos y kickoff de desarrollo], [06/05/2026], [Artefactos base defendidos y backlog operativo],

  [Demo final], [24/06/2026], [Cierre de Sprint 7, exposición y entrega final],
)
