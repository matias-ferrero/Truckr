#import "../template.typ": c-brand, c-brand-mid, conf
#import "@preview/cetz:0.3.4": canvas, draw
#import "@preview/cetz-plot:0.1.1": plot

#show: conf
#set page(margin: (x: 1.8cm, y: 1.8cm))

// ── Traffic-light palette ─────────────────────────────────────────────────
#let c-good = rgb("#1e8449")
#let c-warn = rgb("#d68910")
#let c-bad = rgb("#c0392b")
#let c-muted = luma(120)
#let c-proj = rgb("#1a1a1a")

// ── Data block (regenerated each run from the CLI JSON) ───────────────────
#let phase = "development"
#let schema-version = "4"
#let bootstrap-samples = 10000
#let seed = 42

#let sprints = (
  (1, "2026-05-06 → 2026-05-13", 3, 4),
  (2, "2026-05-13 → 2026-05-20", 15, 6),
  (3, "2026-05-20 → 2026-05-27", 9, 3),
  (4, "2026-05-27 → 2026-06-03", 14, 0),
)

#let throughput-mean = 10.25
#let throughput-min = 3
#let throughput-max = 15

#let target-us = 11

#let has-forward = true
#let remaining-sprints = 2
#let p-meet = 0.9361

// Reconstruction
#let is-reconstruction = true
#let as-of-sprint = 4
#let hist-from = 1
#let hist-to = 4
#let mvp-total = 52
#let mvp-done = 41
#let already-complete = false

#let verdict = if is-reconstruction and already-complete {
  ("MVP completo a esta altura.", c-good)
} else if not has-forward {
  ("Muestra insuficiente para proyectar (< 2 sprints).", c-warn)
} else if p-meet >= 0.85 {
  ("Estábamos en camino.", c-good)
} else if p-meet >= 0.50 {
  ("Estaba ajustado — proteger el alcance.", c-warn)
} else {
  ("No llegábamos en el horizonte — recortar o extender.", c-bad)
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
    Performance del Equipo
  ]
  #if is-reconstruction [
    #v(0.15cm)
    #text(size: 12pt, weight: "medium", fill: c-brand-mid)[
      Reconstrucción al cierre del Sprint #as-of-sprint
    ]
    #v(0.1cm)
    #text(size: 9pt, fill: c-muted)[
      Historia Sprints #hist-from–#hist-to · MVP restante #target-us de #mvp-total
      (#mvp-done ya completadas) · horizonte #remaining-sprints sprints
    ]
  ]
]

#v(0.6cm)

// ── Headline badge ────────────────────────────────────────────────────────
#align(center)[
  #block(
    fill: headline-color,
    inset: (x: 0.75cm, y: 0.45cm),
    radius: 6pt,
    width: 40%,
    [
      #set text(fill: white)
      #if has-forward [
        #text(
          size: 9pt,
        )[Probabilidad de completar #target-us User Stories en #remaining-sprints sprints]
        #v(0.08cm)
        #text(size: 28pt, weight: "black")[
          #calc.round(p-meet * 100, digits: 1)%
        ]
        #v(-0.1cm)
        #text(size: 9pt, weight: "medium")[#headline-msg]
      ] else if is-reconstruction and already-complete [
        #text(size: 9pt)[MVP completado al cierre del Sprint #as-of-sprint]
        #v(0.08cm)
        #text(size: 28pt, weight: "black")[100%]
        #v(-0.1cm)
        #text(size: 10pt, weight: "medium")[#headline-msg]
      ] else [
        #text(size: 16pt, weight: "black")[Muestra insuficiente]
        #v(-0.05cm)
        #text(size: 10pt, weight: "medium")[#headline-msg]
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
    *US completadas* = User Stories del MVP terminadas (todos los criterios) en la ventana.
    *WIP\@fin* = User Stories en progreso, no terminadas, al cierre del sprint.
  ]
]

#v(0.4cm)

== Estadísticas de throughput

#block(
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
    )[Throughput (US MVP completadas / sprint)]
    #v(0.2cm)
    #table(
      columns: (auto, auto, 1fr),
      stroke: none,
      [*Media*], [#calc.round(throughput-mean, digits: 2)], [Promedio de User Stories del MVP completadas por sprint.],

      [*Mín/Máx*], [#throughput-min / #throughput-max], [Peor / mejor sprint observado.],
    )
  ],
)

#v(0.4cm)

// ── Throughput per closed sprint ──────────────────────────────────────────
== Throughput por sprint

#align(center)[
  #canvas(length: 1cm, {
    import draw: *
    plot.plot(
      size: (14, 5),
      x-tick-step: 1,
      y-tick-step: 5,
      y-min: 0,
      x-label: "Sprint #",
      y-label: "US Completadas",
      axis-style: "school-book",
      {
        plot.add-bar(
          sprints.map(s => (s.at(0), s.at(2))),
          bar-width: 0.4,
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
    Barras: User Stories del MVP completadas por sprint.
    Línea punteada: throughput medio (#calc.round(throughput-mean, digits: 2) US/sprint).
  ]
]

#v(0.4cm)

// ── Cumulative burn-up (CFD) ──────────────────────────────────────────────
== Avance acumulado (burn-up)

#let total-dev = as-of-sprint + remaining-sprints

// Cumulative MVP completions, with a Sprint 0 baseline at zero.
#let cum-points = {
  let acc = 0
  let pts = ((0, 0),)
  for s in sprints {
    acc += s.at(2)
    pts += ((s.at(0), acc),)
  }
  pts
}

// Full-scope bars (red) overlaid by the done bars (blue) → stacked look.
#let scope-bars = cum-points.map(p => (p.at(0), mvp-total))

// Linear "done" projection at mean throughput, from the origin to the ceiling.
#let release-x = if throughput-mean > 0 { mvp-total / throughput-mean } else { 0 }
#let cross-on-chart = has-forward and release-x <= total-dev
#let proj-end = if cross-on-chart {
  (release-x, mvp-total)
} else {
  (total-dev, calc.min(throughput-mean * total-dev, mvp-total))
}

#align(center)[
  #canvas(length: 1cm, {
    import draw: *
    plot.plot(
      size: (14, 7),
      x-min: -0.5,
      x-max: total-dev + 0.5,
      x-tick-step: 1,
      y-min: 0,
      y-max: mvp-total + 6,
      y-tick-step: 10,
      x-label: "Sprint",
      y-label: "US completas (acumuladas)",
      axis-style: "left",
      {
        // Remaining (red, full scope) first, then Done (blue) overlaid.
        plot.add-bar(
          scope-bars,
          bar-width: 0.5,
          style: (fill: c-bad.lighten(35%), stroke: c-bad.darken(5%)),
        )
        plot.add-bar(
          cum-points,
          bar-width: 0.5,
          style: (fill: c-brand-mid, stroke: c-brand),
        )
        // MVP scope ceiling.
        plot.add-hline(
          mvp-total,
          style: (stroke: (paint: c-bad, thickness: 1.2pt)),
        )
        if has-forward {
          plot.add(
            ((0, 0), proj-end),
            style: (stroke: (paint: c-proj, dash: "dashed", thickness: 1.6pt)),
          )
          if cross-on-chart {
            plot.add-vline(
              release-x,
              style: (stroke: (paint: c-proj, dash: "dotted", thickness: 0.8pt)),
            )
          }
        }
      },
    )
  })
  #text(size: 8pt, fill: c-muted)[
    Barras apiladas: #text(fill: c-brand)[*completadas*] (abajo) y #text(fill: c-bad)[*restantes*] (arriba) sobre un alcance MVP de #mvp-total US (línea roja). El Sprint 0 es el punto de partida (0 completadas).#if has-forward [ Diagonal punteada: proyección lineal al throughput medio (#calc.round(throughput-mean, digits: 2) US/sprint), que alcanza el MVP hacia el *Sprint #calc.ceil(release-x)*.]
  ]
]



