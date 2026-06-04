#import "template.typ": c-brand, c-brand-mid, conf
#import "@preview/cetz:0.3.4": canvas, draw
#import "@preview/cetz-plot:0.1.1": plot

#show: conf
#set page(margin: (x: 1.8cm, y: 1.8cm))

// ── Traffic-light palette ─────────────────────────────────────────────────
#let c-good = rgb("#1e8449")
#let c-warn = rgb("#d68910")
#let c-bad = rgb("#c0392b")
#let c-muted = luma(120)

// ── Data block (regenerated each run from the CLI JSON) ───────────────────
#let phase = "development"
#let schema-version = "3"
#let bootstrap-samples = 10000
#let seed = 42

// One row per *closed* sprint:
// (index, "window_start → window_end", completed_count, wip_at_end)
#let sprints = (
  (1, "2026-05-07 → 2026-05-13", 3, 12),
  (2, "2026-05-14 → 2026-05-20", 16, 4),
  (3, "2026-05-21 → 2026-05-27", 10, 2),
  (4, "2026-05-27 → 2026-06-03", 14, 0),
)

#let throughput-mean = 10.75
#let throughput-median = 12.0
#let throughput-stdev = 5.737304826019502
#let throughput-min = 3
#let throughput-max = 16
#let lead-p50 = 0.0
#let lead-p75 = 1.0
#let lead-p90 = 1.0

// Projection — set `has-projection` to `false` if JSON `projection == null`
#let has-projection = true
#let target-us = 5

// Inverse — always present when has-projection
#let inv-p50 = 1
#let inv-p85 = 2
#let inv-p95 = 2
#let inv-p99 = 2
#let inv-did-not-finish = 0.0
#let inv-cap = 60

// Forward — set has-forward = false if JSON `projection.forward == null`
#let has-forward = true
#let remaining-sprints = 3
#let p-meet = 1.0
#let proj-p10 = 20
#let proj-p50 = 33
#let proj-p90 = 44

// Traffic-light selection — see §3 of SKILL.md
#let verdict = if not has-projection {
  ("Se necesitan ≥ 2 sprints cerrados antes de poder proyectar.", c-warn)
} else if has-forward and p-meet >= 0.85 {
  ("Estamos en camino.", c-good)
} else if has-forward and p-meet >= 0.50 {
  ("Está ajustado — protejamos el alcance.", c-warn)
} else if has-forward {
  ("No llegamos en el horizonte — recortar alcance o extender.", c-bad)
} else if inv-did-not-finish <= 0.05 {
  ("Backlog alcanzable al ritmo actual.", c-good)
} else if inv-did-not-finish <= 0.25 {
  ("Alcanzable pero ajustado — protejamos el alcance.", c-warn)
} else {
  ("El backlog crece más rápido que el throughput — recortar alcance.", c-bad)
}
#let headline-color = verdict.at(1)
#let headline-msg = verdict.at(0)

// ── Document ──────────────────────────────────────────────────────────────

#align(center)[
  #text(size: 9pt, fill: c-muted)[
    Reporte de performance del equipo · fase #phase · esquema #schema-version
  ]
  #v(0.2cm)
  #text(size: 28pt, weight: "bold", fill: c-brand)[
    Throughput de User Stories y proyección
  ]
]

#v(0.6cm)

// ── Headline badge ────────────────────────────────────────────────────────
#align(center)[
  #block(
    fill: headline-color,
    inset: (x: 1.5cm, y: 0.9cm),
    radius: 8pt,
    width: 80%,
    [
      #set text(fill: white)
      #if has-projection [
        #if has-forward [
          #text(
            size: 11pt,
          )[Probabilidad de completar #target-us User Stories en #remaining-sprints sprints]
          #v(0.15cm)
          #text(size: 56pt, weight: "black")[
            #calc.round(p-meet * 100, digits: 1)%
          ]
        ] else [
          #text(
            size: 11pt,
          )[Sprints para completar #target-us User Stories (confianza 85%)]
          #v(0.15cm)
          #text(size: 56pt, weight: "black")[#inv-p85]
        ]
        #v(-0.2cm)
        #text(size: 13pt, weight: "medium")[#headline-msg]
      ] else [
        #text(size: 32pt, weight: "black")[Muestra insuficiente]
        #v(-0.1cm)
        #text(size: 13pt, weight: "medium")[#headline-msg]
      ]
    ],
  )
]

#v(0.4cm)

// ── Configuration strip ───────────────────────────────────────────────────
#align(center)[
  #set text(size: 9pt, fill: c-muted)
  Fase *#phase* · esquema *#schema-version* · seed *#seed* · muestras *#bootstrap-samples*
]

#v(0.6cm)

// ── Throughput per closed sprint ──────────────────────────────────────────
== Throughput por sprint cerrado

#align(center)[
  #canvas(length: 1cm, {
    import draw: *
    plot.plot(
      size: (14, 5),
      x-tick-step: 1,
      y-tick-step: none,
      y-min: 0,
      x-label: "Sprint #",
      y-label: "User Stories completadas",
      axis-style: "school-book",
      {
        plot.add-bar(
          sprints.map(s => (s.at(0), s.at(2))),
          bar-width: 0.6,
          style: (fill: c-brand-mid, stroke: c-brand),
        )
        plot.add-hline(
          throughput-mean,
          style: (stroke: (paint: c-warn, dash: "dashed", thickness: 1.2pt)),
        )
      },
    )
  })
  #text(size: 8pt, fill: c-muted)[
    Barras: User Stories completadas por sprint.
    Línea punteada: throughput medio (#calc.round(throughput-mean, digits: 2) US/sprint).
  ]
]

#v(0.4cm)

== Detalle por sprint

#align(center)[
  #table(
    columns: (auto, 1fr, auto, auto),
    align: (center, left, right, right),
    fill: (col, row) => if row == 0 { c-brand.lighten(80%) } else { none },
    [*\#*], [*Ventana*], [*US completadas*], [*WIP\@fin*],
    ..sprints
      .map(s => (
        [#s.at(0)],
        [#s.at(1)],
        [#s.at(2)],
        [#s.at(3)],
      ))
      .flatten(),
  )
  #text(size: 8pt, fill: c-muted)[
    *US completadas* = User Stories terminadas (todos los criterios de aceptación) en la ventana.
    *WIP\@fin* = User Stories en progreso, no terminadas, al cierre del sprint.
  ]
]

#v(0.4cm)

== Agregado

#grid(
  columns: (1fr, 1fr),
  gutter: 0.6cm,
  block(
    fill: luma(248),
    stroke: 0.5pt + luma(200),
    inset: 0.7cm,
    radius: 4pt,
    width: 100%,
    [
      #text(
        size: 11pt,
        weight: "bold",
        fill: c-brand,
      )[Throughput (US completadas / sprint)]
      #v(0.2cm)
      #table(
        columns: (auto, auto, 1fr),
        stroke: none,
        [*Media*],
        [#calc.round(throughput-mean, digits: 2)],
        [Promedio de User Stories completadas por sprint.],

        [*Mediana*],
        [#calc.round(throughput-median, digits: 2)],
        [User Stories completadas en un sprint típico.],

        [*Desv. estándar*],
        [#if throughput-stdev == none { "—" } else {
          calc.round(throughput-stdev, digits: 2)
        }],
        [Dispersión alrededor de la media — mayor = menos predecible.],

        [*Mín/Máx*],
        [#throughput-min / #throughput-max],
        [Peor / mejor sprint observado.],
      )
    ],
  ),
  block(
    fill: luma(248),
    stroke: 0.5pt + luma(200),
    inset: 0.7cm,
    radius: 4pt,
    width: 100%,
    [
      #text(size: 11pt, weight: "bold", fill: c-brand)[Lead time (sprints)]
      #v(0.2cm)
      #if lead-p50 == none [
        #text(fill: c-muted)[No hay User Stories completadas todavía.]
      ] else [
        #table(
          columns: (auto, auto, 1fr),
          stroke: none,
          [*p50*],
          [#calc.round(lead-p50, digits: 1)],
          [La mitad de las US se completan dentro de esta cantidad de sprints.],

          [*p75*],
          [#calc.round(lead-p75, digits: 1)],
          [Tres cuartos se completan dentro de esta cantidad de sprints.],

          [*p90*],
          [#calc.round(lead-p90, digits: 1)],
          [Nueve de cada diez se completan dentro de esta cantidad de sprints.],
        )
      ]
    ],
  ),
)

#v(0.5cm)

#if has-projection [
  == Proyección — inversa (sprints para llegar al target)

  #align(center)[
    #table(
      columns: (auto, auto, 1fr),
      align: (center, center, left),
      fill: (col, row) => if row == 0 { c-brand.lighten(80%) } else { none },
      [*Confianza*], [*Sprints*], [*Significado*],
      [p50],
      [#inv-p50],
      [La mitad de los futuros simulados terminan en este sprint (mediana).],

      [p85],
      [#inv-p85],
      [Línea base de planificación — el 85% de los futuros terminan en este sprint.],

      [p95],
      [#inv-p95],
      [Compromiso con confianza — el 95% de los futuros terminan en este sprint.],

      [p99],
      [#inv-p99],
      [Peor caso — el 99% de los futuros terminan en este sprint.],

      [did_not_finish],
      [#calc.round(inv-did-not-finish * 100, digits: 1)%],
      [Simulaciones que llegan al tope de #inv-cap sprints. Distinto de cero ⇒ alcance > capacidad.],
    )
    #text(size: 8pt, fill: c-muted)[
      Método: bootstrap del throughput observado · #bootstrap-samples muestras · seed #seed.
    ]
  ]

  #v(0.4cm)

  #if has-forward [
    == Proyección — directa (horizonte fijo)

    #align(center)[
      #canvas(length: 1cm, {
        import draw: *
        plot.plot(
          size: (14, 5),
          x-tick-step: none,
          y-tick-step: none,
          y-min: 0,
          x-label: none,
          y-label: "US completadas (total proyectado)",
          axis-style: "school-book",
          {
            plot.add-bar(
              ((1, proj-p10), (2, proj-p50), (3, proj-p90)),
              bar-width: 0.6,
              style: (fill: c-brand-mid, stroke: c-brand),
            )
            plot.add-hline(
              target-us,
              style: (stroke: (paint: c-bad, dash: "dashed", thickness: 1.4pt)),
            )
          },
        )
      })
      #text(size: 8pt, fill: c-muted)[
        Barras: total proyectado de US completadas en p10 / p50 / p90 sobre #bootstrap-samples muestras.
        Línea roja punteada: target = #target-us.
      ]
    ]

    #v(0.3cm)

    #align(center)[
      #table(
        columns: (auto, auto, 1fr),
        align: (left, right, left),
        fill: (col, row) => if row == 0 { c-brand.lighten(80%) } else { none },
        [*Métrica*], [*Valor*], [*Significado*],
        [P(completar ≥ target) en #remaining-sprints sprints],
        [#calc.round(p-meet * 100, digits: 1)%],
        [Probabilidad de terminar el backlog dentro del horizonte fijo.],

        [Total pesimista (p10)],
        [#proj-p10],
        [Sólo el 10% de los futuros entregan menos que esto.],

        [Total mediano (p50)],
        [#proj-p50],
        [Mediana del total entregado sobre el horizonte.],

        [Total optimista (p90)],
        [#proj-p90],
        [Sólo el 10% de los futuros entregan más que esto.],
      )
    ]

    #v(0.4cm)
  ]
] else [
  == Proyección

  #block(
    fill: c-warn.lighten(85%),
    stroke: 0.5pt + c-warn,
    inset: 0.7cm,
    radius: 4pt,
    width: 100%,
    [
      *Muestra insuficiente.* La proyección por bootstrap requiere al menos 2
      sprints cerrados en el ledger. Volver a correr cuando cierre un sprint más.
    ],
  )
]

#v(0.6cm)

== Aclaraciones

#set text(size: 9pt)
- La unidad es la *User Story completada*. El trabajo de infraestructura y
  documentación no son User Stories y no aparecen acá.
- El throughput es *grumoso*: las US grandes abarcan varios sprints, así que
  hay sprints con pocas US completadas. Los intervalos de proyección son anchos.
- El lead time se mide en *sprints enteros*.
- Cambios futuros de capacidad (feriados, cambios en el equipo) *no* están
  modelados. El bootstrap asume que los sprints futuros se comportan como los
  pasados.
- "Target = #target-us" se pasó como entrada (User Stories restantes del MVP /
  Release 1). Si cambia el alcance, volver a correr con el nuevo conteo.
- Los números son *agregados del equipo*. La desagregación por persona no se
  produce intencionalmente.
- Reproducible con seed *#seed* contra el mismo ledger para obtener salida
  byte-idéntica (excluyendo `generated_at`).
