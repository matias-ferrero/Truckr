// ── Shared burn-up overlay renderer ───────────────────────────────────────
// Renders a single, tightly-cropped burn-up chart matching the aesthetic of
// the sprint-NN-performance.typ reports, but with one or more *superimposed*
// linear projections. Used to build the "Proyecciones" slide images: each
// sprint adds its column and its projection line without erasing the previous
// ones. Coincident projections (same slope) are passed as one group and
// labelled with every sprint they represent (e.g. "2 y 3").
//
// Data comes straight from the team-performance reconstructions
// (`--as-of-sprint N`): cumulative completions and the mean throughput slope.

#import "../template.typ": c-brand, c-brand-mid, conf
#import "@preview/cetz:0.3.4": canvas, draw
#import "@preview/cetz-plot:0.1.1": plot

#let c-bad = rgb("#c0392b")
#let c-ink = rgb("#101010") // strong black — high contrast over bars and white

// Projection identity. Sprints that share a slope are one (coincident) line.
#let proj-s23 = (slope: 9, color: c-ink)
#let proj-s4 = (slope: 10.25, color: c-ink)

// Number part of the label: "2", "2 y 3", "2, 3 y 4".
#let sprint-nums(sprints) = {
  let n = sprints.len()
  if n == 1 {
    str(sprints.at(0))
  } else if n == 2 {
    str(sprints.at(0)) + " y " + str(sprints.at(1))
  } else {
    sprints.slice(0, n - 1).map(str).join(", ") + " y " + str(sprints.last())
  }
}

// projections: array of (sprints, slope, color, current).
#let render-burnup(
  cum: (),
  projections: (),
  mvp-total: 52,
  x-max: 6.5,
) = {
  show: conf
  set page(width: auto, height: auto, margin: 0.6cm)

  let scope-bars = cum.map(p => (p.at(0), mvp-total))

  align(center)[
    // Bigger tick labels (cetz captures the ambient text size).
    #set text(size: 13pt)
    #canvas(length: 1cm, {
      import draw: *
      plot.plot(
        size: (16, 8),
        x-min: -0.5,
        x-max: x-max,
        x-tick-step: 1,
        y-min: 0,
        y-max: mvp-total + 6,
        y-tick-step: 10,
        x-label: text(size: 15pt)[Sprint],
        y-label: none,
        axis-style: "left",
        {
          // Remaining (red, full scope) first, then Done (blue) overlaid.
          plot.add-bar(
            scope-bars,
            bar-width: 0.5,
            style: (fill: c-bad.lighten(35%), stroke: c-bad.darken(5%)),
          )
          plot.add-bar(
            cum,
            bar-width: 0.5,
            style: (fill: c-brand-mid, stroke: c-brand),
          )
          // MVP scope ceiling.
          plot.add-hline(
            mvp-total,
            style: (stroke: (paint: c-bad, thickness: 1.4pt)),
          )
          // Superimposed projections (previous sprints under the current one).
          for pr in projections {
            let cross-x = mvp-total / pr.slope
            let crosses = cross-x <= x-max
            let end = if crosses { (cross-x, mvp-total) } else {
              (x-max, pr.slope * x-max)
            }
            let th = if pr.at("current", default: false) { 2.4pt } else {
              1.8pt
            }
            plot.add(
              ((0, 0), end),
              style: (stroke: (paint: pr.color, dash: "dashed", thickness: th)),
            )
            // Dotted drop line from the intersection down to the x-axis.
            if crosses {
              plot.add(
                ((cross-x, 0), (cross-x, mvp-total)),
                style: (
                  stroke: (paint: pr.color, dash: "dotted", thickness: 1pt),
                ),
              )
            }
          }
          // Horizontal y-axis label, centred above the axis arrow.
          plot.annotate(resize: false, {
            content(
              (-0.5, mvp-total + 11),
              anchor: "south",
              text(size: 14pt, fill: black)[US completadas (acum.)],
            )
            // Stacked, centred labels right above each intersection.
            // Two single lines ("Sprint" over the number) so the footprint is
            // narrow and each line sits at a controlled height.
            for pr in projections {
              let cross-x = mvp-total / pr.slope
              content(
                (cross-x, mvp-total + 5.4),
                anchor: "south",
                text(size: 12pt, weight: "bold", fill: pr.color)[Sprint],
              )
              content(
                (cross-x, mvp-total + 2.7),
                anchor: "south",
                text(size: 12pt, weight: "bold", fill: pr.color)[#sprint-nums(
                  pr.sprints,
                )],
              )
            }
          })
        },
      )
    })
  ]
}
