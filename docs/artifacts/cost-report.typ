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

=== Infraestructura Cloud — AWS (staging)

Topología fijada por `CLAUDE.md § "Database policy"`: SQLite + un único contenedor con Kamal. Sin RDS, sin Redis administrado, sin ALB. La aplicación corre en una EC2 con kamal-proxy terminando TLS vía Let's Encrypt sobre un hostname sslip.io. El frontend se sirve desde S3 + CloudFront. Provisionado por Terraform (`infra/envs/staging/`).

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
  [EC2 — Servidor de aplicación (Rails \+ Kamal)],
  [t3.micro (2 vCPU, 1 GB RAM)],
  [1],
  [\$7,59/mes],
  [\$7,59],

  [EBS gp3 — Volumen root con SQLite],
  [20 GB gp3],
  [1],
  [\$1,60/mes],
  [\$1,60],

  [EBS Snapshots — Backups diarios (DLM, 7 días retención)],
  [≈ 20 GB efectivos],
  [1],
  [\$0,50/mes],
  [\$0,50],

  [Elastic IP — Hostname estable para sslip.io],
  [IPv4 asociada a EC2],
  [1],
  [\$0,00/mes],
  [\$0,00],

  [ECR — Registro de imágenes Docker (truckr-backend)],
  [\~0,5 GB con lifecycle policy],
  [1],
  [\$0,05/mes],
  [\$0,05],

  [S3 — Bundle frontend \+ tfstate],
  [Standard — \~6 GB \+ 5 GB transferencia],
  [2 buckets],
  [\$0,14/mes],
  [\$0,14],

  [CloudFront — CDN del frontend],
  [\~10 GB transferencia/mes],
  [1],
  [\$0,85/mes],
  [\$0,85],

  [DynamoDB — Lock de Terraform state],
  [On-demand, \<100 ops/mes],
  [1],
  [\$0,01/mes],
  [\$0,01],

  [SSM Parameter Store — Secretos],
  [Standard params, sin throughput extra],
  [1],
  [\$0,00/mes],
  [\$0,00],

  [TLS — kamal-proxy \+ Let's Encrypt],
  [Auto-renew sobre sslip.io],
  [—],
  [\$0,00/mes],
  [\$0,00],

  table.cell(fill: luma(240), colspan: 4)[#align(
    right,
  )[*Total mensual infraestructura AWS*]],
  table.cell(fill: luma(240))[*\$10,74*],
)

#pagebreak()

== 4. Resumen Ejecutivo

#table(
  columns: (1fr, auto, auto, auto),
  align: (left, center, center, center),
  table.header(
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Concepto]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Por Sprint (USD)]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Ventana Inicial — 3 Sprints (USD)]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Proyecto — 7 Sprints (USD)]],
  ),
  [Equipo (5 Dev + 1 PM)], [\$1.072], [\$3.216], [\$7.504],
  [Tooling IA], [\$30], [\$90], [\$210],
  [Infraestructura AWS], [\$10,74], [\$10,74], [\$21,48],
  table.cell(fill: luma(240), colspan: 1)[#align(right)[*Total*]],
  table.cell(fill: luma(240))[*\$1.112,74*],
  table.cell(fill: luma(240))[*\$3.316,74*],
  table.cell(fill: luma(240))[*\$7.735,48*],
)
