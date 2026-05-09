#import "../template.typ": conf, stroke-std
#show: conf

= Registro de Riesgos

Este artefacto consolida la matriz de riesgos del proyecto Truckr® en formato de registro. Incluye riesgos negativos y una oportunidad positiva, con foco en el alcance del MVP, las decisiones técnicas diferidas y las dependencias externas ya identificadas en el resto de los artefactos.

== Criterios de valoración

La probabilidad y el impacto se expresan en escala de 0 a 1. La exposición se calcula como $P times I$ y se usa para priorizar el seguimiento del riesgo.

== Criterios de seguimiento

- El registro se toma como snapshot a la fecha de actualización de cada fila.
- Los owners corresponden a roles del equipo, no a personas nominales.
- Las mitigaciones que requieran trabajo concreto deben bajar a issues o tareas del backlog.

#set page(flipped: true, margin: (x: 0.8cm, y: 1cm))
#set text(size: 8.3pt)

#table(
  columns: (
    auto,
    2.2fr,
    0.9fr,
    1.45fr,
    1.55fr,
    1fr,
    0.8fr,
    0.8fr,
    0.9fr,
    2.05fr,
    1.9fr,
    2.0fr,
    0.85fr,
    1.0fr,
    1.0fr,
  ),
  inset: (x: 3pt, y: 4pt),
  stroke: stroke-std,
  align: (
    center,
    left,
    left,
    left,
    left,
    left,
    center,
    center,
    center,
    left,
    left,
    left,
    center,
    left,
    center,
  ),
  table.header(
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[\#]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Descripción]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Tipo]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Causas]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Consecuencias]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Categoría]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Prob]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Imp]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Exp]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Plan de Respuesta]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Umbral]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Plan de Contingencia]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Estado]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Responsable]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Fecha Actualización]],
  ),

  [1],
  [Lanzamiento o presentación alineados con una ventana de mayor demanda logística o interés por digitalizar operaciones.],
  [Positivo],
  [La fecha elegida coincide con campañas comerciales, cierres de carga o mayor atención del mercado al problema que resuelve Truckr®.],
  [Mayor tracción inicial, más registros para pilotos y mejor recepción de la demo.],
  [Mercado],
  [0.3],
  [0.5],
  [0.15],
  [Explotar: reforzar difusión, demos y captación de pilotos en esa ventana.],
  [Más de 20% de registros o interés en demos por encima de la línea base esperada.],
  [Aumentar alcance de comunicación, sumar casos de uso y priorizar seguimiento de leads.],
  [Activo],
  [PM],
  [2026-05-08],

  [2],
  [Cold-start del marketplace de doble lado.],
  [Negativo],
  [No hay suficiente oferta publicada de transportistas ni demanda activa de expedidores al mismo tiempo.],
  [Baja tasa de match, abandono de usuarios iniciales y poca validación del producto.],
  [Mercado],
  [0.8],
  [0.9],
  [0.72],
  [Mitigar: sembrar oferta y demanda con pilotos previos y un alcance geográfico acotado.],
  [Menos de 5 ofertas activas o tasa de match menor al 20% durante una semana.],
  [Presentar la demo con datos precargados y un recorrido guiado en lugar de depender de adopción orgánica.],
  [Activo],
  [PM],
  [2026-05-08],

  [3],
  [Demora en cerrar e implementar autenticación y roles.],
  [Negativo],
  [La definición de identidad quedó diferida y todavía no está resuelto el flujo básico de acceso y permisos.],
  [Se bloquean stories de perfil, publicación, aceptación y pago.],
  [Técnico],
  [0.7],
  [0.8],
  [0.56],
  [Mitigar: cerrar el modelo de identidad y llevar una autenticación mínima al frente del plan.],
  [No se completa el alta y el login de usuarios de prueba dentro del sprint que ata el core.],
  [Usar cuentas semilla para la demo y postergar el autoservicio de registro si hace falta.],
  [Activo],
  [Líder técnico],
  [2026-05-08],

  [4],
  [Techo de escala de SQLite como base primaria.],
  [Negativo],
  [El producto arranca sobre SQLite y aún no está cerrada la migración a PostgreSQL.],
  [Aparece contention de escritura o degradación de performance al crecer la carga.],
  [Técnico],
  [0.5],
  [0.7],
  [0.35],
  [Mitigar: encapsular persistencia y controlar métricas de consulta desde temprano.],
  [Tiempos de respuesta mayores a 2 segundos en matching o búsqueda bajo carga de demo.],
  [Congelar nuevas features no críticas y abrir un slice de migración a PostgreSQL.],
  [Activo],
  [Líder técnico],
  [2026-05-08],

  [5],
  [Dependencias externas agrupadas: Maps (geocoding/ruteo), ARCA (facturación), proveedores GPS/telemetría, PSP/pagos y aseguradoras.],
  [Negativo],
  [Latencias, cambios de API, falta de sandbox, límites de uso o requisitos contractuales que atrasen integraciones y funcionalidades del MVP (geocoding, facturación, tracking, cobros).],
  [Se retrasan historias críticas de integración, se degradan demos o se requieren soluciones manuales que impactan la entrega del MVP.],
  [Externo / dependencias],
  [0.7],
  [0.8],
  [0.56],
  [Mitigar: priorizar adapters y mocks, definir alcance mínimo de integración para el MVP y negociar sandboxes/credenciales tempranas.],
  [Falta de credenciales o sandbox operativo dentro de las dos primeras semanas de implementación para integraciones críticas.],
  [Contingencia: demos con facturación manual, tracking por hitos y geocoding estimado; diferir integración completa a post-MVP.],
  [Activo],
  [Líder técnico],
  [2026-05-08],

  [6],
  [Escrow o retención de pagos con encuadre legal insuficiente.],
  [Negativo],
  [El flujo de pagos entre expedidor y transportista puede requerir estructura regulatoria específica en Argentina.],
  [Exposición legal y necesidad de rediseñar el flujo de cobro.],
  [Regulatorio / legal],
  [0.6],
  [0.9],
  [0.54],
  [Mitigar: limitar el MVP a pago directo con processor y revisar T\&C básicos.],
  [Feedback legal o de cátedra indica que el flujo requiere encuadre PSP o cuenta recaudadora.],
  [Eliminar el escrow del MVP y mostrar un flujo de pago directo.],
  [Activo],
  [PM],
  [2026-05-08],

  [7],
  [Scope creep por feedback intermedio y cambios de alcance.],
  [Negativo],
  [Las revisiones académicas o del equipo pueden empujar funcionalidades nuevas no previstas.],
  [Se compromete el deadline y se diluye el foco del MVP.],
  [Equipo / proceso],
  [0.6],
  [0.7],
  [0.42],
  [Mitigar: congelar alcance contra WBS y USM, y revisar todo cambio contra el MVP.],
  [Entran funcionalidades nuevas sin mapeo a entregable o aparecen carry-overs por más de 2 sprints.],
  [Aceptar solo defectos y postergar nuevas ideas a una revisión posterior.],
  [Activo],
  [PM],
  [2026-05-08],

  [8],
  [Capacidad del equipo y bus factor bajo.],
  [Negativo],
  [El equipo es chico y varios frentes críticos dependen de pocas personas, con cobertura de tests todavía limitada.],
  [Una ausencia o una regresión puede frenar un flujo entero del proyecto.],
  [Equipo / proceso],
  [0.7],
  [0.8],
  [0.56],
  [Mitigar: pair programming en lo crítico y sumar pruebas automáticas mínimas.],
  [Un epic queda con una sola persona o la velocidad cae más de 30% contra el sprint previo.],
  [Recortar alcance al core de matching y pagos directos si la capacidad no alcanza.],
  [Activo],
  [PM + Líder técnico],
  [2026-05-08],
)

#set page(flipped: false, margin: 2cm)
#set text(size: 10pt)
