#import "../template.typ": c-brand, c-brand-mid, conf, stroke-std
#show: conf

= Informe de Costos T&M

== 1. Modelo de Proyección (Throughput-Based Forecasting)

El progreso se mide contando ítems entregados y comparándolos con el backlog pendiente. No se usan estimaciones horarias ni story points.

=== Disciplina de Slicing de Stories

Cada historia de usuario debe ser *independiente y pequeña*: idealmente, no más de 1 día de desarrollo. El objetivo es entregar entre 6 y 12 stories por sprint de 1 semana.

=== Medición de Throughput

Después de 3–5 iteraciones, se dispone de datos suficientes para medir ítems/sprint y proyectar hacia adelante.

#table(
  columns: (auto, auto, auto, auto),
  align: (center, center, center, center),
  table.header(
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Sprint]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Ítems entregados]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Throughput acum.]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Confianza del pronóstico]],
  ),
  [Sprint 1], [? (calibración)], [—], [Muy baja],
  [Sprint 2], [? (calibración)], [—], [Baja],
  [Sprint 3], [? (calibración)], [Promedio 3 sprints], [Media],
  [Sprint 4], [Medido], [Promedio 4 sprints], [Media-Alta],
  [Sprint 5], [Medido], [Promedio 5 sprints], [Alta],
  [Sprint 6+], [Medido], [Media móvil], [Alta],
)

=== Simulación Monte Carlo

Las proyecciones son *probabilísticas*, no determinísticas. Se utiliza referencia de clase (reference class forecasting) basada en datos reales de rendimiento pasado.

#block(
  width: 100%,
  inset: 10pt,
  radius: 4pt,
  fill: rgb("#eaf2f8"),
  stroke: 0.5pt + c-brand,
)[
  *Ejemplo de pronóstico (post-calibración):*\
  - Backlog MVP restante: 45 ítems\
  - Throughput promedio: 9 ítems/sprint (±2)\
  - Pronóstico Monte Carlo:\
    - 50\% de probabilidad: 5 sprints\
    - 85\% de probabilidad: 6 sprints\
    - 95\% de probabilidad: 7 sprints
]

#pagebreak()

== 2. Composición del Equipo y Tarifa (Rate Card)

Las tarifas son multiplicadas contra *time boxes* (sprints, meses), no contra estimaciones por tarea.

=== Rate Card

#table(
  columns: (1fr, auto, auto, auto, auto),
  align: (left, center, center, center, center),
  table.header(
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Rol]],
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Cant.]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Tarifa/hora (USD)]],
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Horas/sprint]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Costo/sprint (USD)]],
  ),
  [Desarrollador Semi-Senior], [5], [\$22], [8], [\$880],
  [Project Manager], [1], [\$24], [8], [\$192],
  table.cell(fill: luma(240), colspan: 4)[#align(
    right,
  )[*Total por sprint (1 semana)*]],
  table.cell(fill: luma(240))[*\$1.072*],
)

#v(0.5em)

#table(
  columns: (1fr, auto),
  align: (left, center),
  table.header(
    table.cell(fill: c-brand-mid)[#text(fill: white, weight: "bold")[Período]],
    table.cell(fill: c-brand-mid)[#text(
      fill: white,
      weight: "bold",
    )[Costo Equipo (USD)]],
  ),
  [1 sprint (1 semana)], [\$1.072],
  [3 sprints (ventana inicial)], [\$3.216],
  [4 sprints (1 mes)], [\$4.288],
  [7 sprints (máximo proyecto)], [\$7.504],
)

#pagebreak()

== 3. Presupuesto de Tooling IA y Materiales

Estos no son costos vinculados a reducir horas en tareas específicas — son *inversiones en infraestructura que incrementan el throughput*.

=== Costos Mensuales de Herramientas IA

#table(
  columns: (1fr, auto, auto, auto),
  align: (left, center, center, center),
  table.header(
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Herramienta]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Costo unitario]],
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Cantidad]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Costo mensual (USD)]],
  ),
  [Asistente de código IA (Cursor / Copilot / Claude Code)],
  [\$20/seat],
  [6 seats],
  [\$120],
  table.cell(fill: luma(240), colspan: 3)[#align(
    right,
  )[*Total mensual tooling IA*]],
  table.cell(fill: luma(240))[*\$120*],
)

#v(0.8em)

=== Infraestructura Cloud — AWS (Prototipo)

Los recursos están dimensionados para un entorno de prototipo con carga baja (\~50 usuarios concurrentes). Se prioriza costo sobre disponibilidad; sin Multi-AZ ni redundancia hasta validar el producto.

#table(
  columns: (auto, auto, auto, auto, auto),
  align: (left, left, center, center, center),
  table.header(
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Servicio]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Tipo / Instancia]],
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Cant.]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Precio unitario]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Costo mensual (USD)]],
  ),
  [ECS — Servidor de aplicación (API \+ backend)],
  [t3.small (2 vCPU, 2 GB RAM)],
  [1],
  [\$15,18/mes],
  [\$15,18],

  [ECS — Servidor de workers / tareas asíncronas],
  [t3.micro (2 vCPU, 1 GB RAM)],
  [1],
  [\$7,59/mes],
  [\$7,59],

  [RDS — Base de datos relacional (PostgreSQL 18)],
  [db.t3.micro (2 vCPU, 1 GB RAM, 20 GB SSD, Single-AZ)],
  [1],
  [\$14,93/mes],
  [\$14,93],

  [ElastiCache — Caché y sesiones (Redis 7)],
  [cache.t3.micro (1 vCPU, 0,5 GB RAM)],
  [1],
  [\$11,52/mes],
  [\$11,52],

  [S3 — Almacenamiento (imágenes, docs, backups)],
  [Standard — 50 GB \+ 10 GB transferencia],
  [1],
  [≈ \$1,15/mes],
  [\$1,15],

  [Application Load Balancer],
  [ALB (1 regla, \~10 LCU estimadas)],
  [1],
  [\$16,20/mes],
  [\$16,20],

  [Route 53 — DNS],
  [Hosted Zone \+ consultas estándar],
  [1],
  [\$0,50/mes],
  [\$0,50],

  [Amplify Hosting — Frontend (assets estáticos)],
  [10 GB servidos, 1 GB almacenamiento],
  [1],
  [≈ \$1,52/mes],
  [\$1,52],

  [Elastic IP],
  [IPv4 — asociada a ECS],
  [1],
  [\$0,00/mes],
  [\$0,00],

  table.cell(fill: luma(240), colspan: 4)[#align(
    right,
  )[*Total mensual infraestructura AWS*]],
  table.cell(fill: luma(240))[*\~\$68,59*],
)

#pagebreak()

== 4. Resumen Ejecutivo

#block(
  width: 100%,
  inset: 12pt,
  radius: 4pt,
  fill: rgb("#eaf2f8"),
  stroke: 0.5pt + c-brand,
)[
  *Modelo de contratación:* Time \& Materials (T\&M)
]

#v(0.8em)

#table(
  columns: (1fr, 1fr),
  align: (left, left),
  table.header(
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Concepto]],
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Detalle]],
  ),
  [Modelo de engagement], [T\&M con cadencia ágil (sprints de 1 semanas)],
  [Equipo], [6 Desarrolladores Semi-Senior],
  [Burn rate mensual (equipo)], [USD 5.760],
  [Burn rate por sprint (1 sem.)], [USD 1440],
  [Tooling IA mensual], [USD 120],
  [Infraestructura AWS mensual (prototipo)], [USD 68],
  [Ventana inicial de compromiso], [3 sprints semanales],
  [Costo total ventana inicial], [USD 4.461 (equipo + tooling + AWS)],
  [Período de calibración], [Sprints 1–3 (pronósticos de baja confianza)],
)
