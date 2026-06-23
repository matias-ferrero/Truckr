---
name: team-performance
description: "Run the team-performance CLI to measure throughput in completed User Stories, project backlog completion (forward + inverse), and emit an eye-catching team-performance.pdf (Typst + cetz). Use when the user asks 'will we finish in N sprints?', 'how many sprints to clear the backlog?', 'what's our throughput?', or wants a performance/forecast report."
---

# team-performance

Wraps the `team-performance` CLI (`docs/scripts/team_performance/`) and turns
its JSON (schema **v4**) into a **Typst report** under
`docs/team-performance/sprint-NN-performance.typ` → `.pdf`. The unit is the
**completed User Story**, not the GitHub issue — issues vary too much in size to
be a stable throughput unit. The report leads with a colour-coded probability
badge and shows throughput stats, a per-sprint bar chart, and a cumulative
burn-up chart.

**Two modes.**
- **Reconstruction (`--as-of-sprint N`, the usual one):** replay the ledger *as
  of* sprint `N` and report the forecast as it would have read then. A **single
  input** — the sprint number, bare `--as-of-sprint` = latest closed — derives
  everything else: history window `1..N`, the remaining-MVP target, and the
  `6 − N` horizon. Run it once per past sprint to build a burndown story. See
  [ADR 0001](../../../docs/adr/0001-team-performance-reconstruction-derives-scope.md).
- **Manual (`--target-user-stories` / `--remaining-sprints`):** you type the
  target and horizon. Use only when the question isn't about a past sprint.

**Data source.** The CLI reads a hand-maintained **per-sprint ledger**:
`docs/progress-reports/sprint-NN.md`, one Markdown file per sprint. These files
are the canonical, machine-readable form of the per-sprint progress reports.
There is no GitHub access. A sprint's `completed_user_stories` is whatever the
team recorded — the tool trusts the ledger.

**Language convention.** The CLI text/JSON output and the generated Typst report are **product content** (an academic deliverable shown to the team and reviewers) and therefore in **es-AR** — see `CLAUDE.md` "Language Rules". Only Python identifiers, JSON keys, Typst variable names, and this SKILL.md prose stay in English.

**Use when:**
- "Reconstruí la performance sprint a sprint" / "what did our forecast look like at sprint N?" → **reconstruction**.
- "What are the chances we finish all the backlog in N sprints?"
- "How many sprints will it take?"
- "What's our team's throughput?"
- "Genera el reporte de performance del equipo."
- The user wants a snapshot of velocity for a retro / sprint review.

**Don't use when:**
- The user wants per-person stats (the tool — by design — never disaggregates by assignee).
- There are < 2 *closed* sprint files in the ledger (the projection refuses; just report observed metrics, no headline number).

---

## Inputs

| Input | Required | How to obtain |
|-------|----------|---------------|
| `sprints_dir`          | No (default `docs/progress-reports`) | Directory of `sprint-NN.md` ledger files. |
| `phase`                | No (default `development`)  | `development` or `documentation`. |
| `backlog_us`           | No (default `docs/artifacts/backlog-us.typ`) | The US backlog artifact, used to validate US ids. |
| `no_us_validation`     | No (default off) | Pass `--no-us-validation` to skip checking ledger US ids against `backlog-us.typ`. Use while the ledger references stories the backlog artifact hasn't caught up with yet. |
| `as_of_sprint`         | Reconstruction mode | `--as-of-sprint N` reconstructs as of sprint `N`; bare = latest closed sprint. Derives target and horizon from `N` — **cannot** be combined with `target_user_stories` / `remaining_sprints`. |
| `total_dev_sprints`    | No (default `6`) | Development-phase length, for the derived horizon (`total_dev_sprints − N`). `6` per `CALENDAR.md`. |
| `target_user_stories`  | Manual mode only | Triggers the inverse projection. MVP = **50** USs (`MVP — Release 1` section of `backlog-us.typ`; backlog has **66** total). In reconstruction mode this is **derived**, not passed. |
| `remaining_sprints`    | Manual mode only | Also runs the forward projection. Cannot be used alone, nor with `--as-of-sprint`. |
| `bootstrap_samples`    | No | Default `10000`. |
| `seed`                 | No | Default `42`. Only override if the user explicitly asks. |
| `output_path`          | No | Reconstruction reports go to `docs/team-performance/sprint-NN-performance.typ`. Must live **under `docs/`** so `--root docs` resolves `template.typ`. |

### The sprint ledger file

```yaml
---
sprint: 1
phase: development          # development | documentation
status: closed              # closed = counted; in_progress = skipped
window: 2026-05-07 -> 2026-05-13
in_progress_user_stories: [US7]
completed_user_stories: [US1, US2, US14]
---
## Retro / ## Notas por US  (free-form body; the tool ignores it)
```

---

## Critical caveats — surface these to the user before reporting numbers

1. **Throughput is lumpy.** Big User Stories span several sprints, so many sprints score 0 completed USs. The projection intervals are wide. This is honest — do not smooth it over.
2. **Need ≥ 2 closed sprints.** Otherwise `has-forward = false`; render the report anyway — the headline becomes "Muestra insuficiente".
3. **"Backlog" scope.** In reconstruction mode the target is auto-derived as the remaining MVP. In manual mode confirm scope: the 50 MVP USs, or some other slice.
4. **No per-person numbers, ever.** Team aggregates only.
5. **The ledger is trusted as-is.** Garbage in, garbage out.
6. **Infra/docs work is invisible.** `INF-*` and doc work are not User Stories.
7. **Bootstrap is empirical.** Each future sprint's throughput is resampled (with replacement) from the observed per-sprint throughput. Not adjusted for capacity changes.
8. **Determinism: same seed + same ledger → byte-identical output** (excluding `generated_at`).

---

## Step-by-Step Process

### 1. Clarify scope with the user

- Confirm the **phase** (dev vs documentation; default dev).
- **Reconstruction** (the usual ask): confirm which sprint(s). To reconstruct the whole project, run once per closed sprint. Target and horizon are derived — nothing else to ask.
- **Manual** mode only: confirm what counts as **the backlog** for `--target-user-stories` and, optionally, the horizon `--remaining-sprints`.

### 2. Run the CLI (JSON only — Typst owns the rendering)

**Reconstruction** — one call per past sprint:

```sh
uv run team-performance \
    --sprints-dir docs/progress-reports --phase development \
    --as-of-sprint <N> \
    --no-us-validation \
    --format json \
    > /tmp/team-performance-s<N>.json
```

**Manual** — type the target/horizon yourself:

```sh
uv run team-performance --sprints-dir docs/progress-reports --phase development \
    --target-user-stories <COUNT> --remaining-sprints <N> --no-us-validation \
    --format json > /tmp/team-performance.json
```

Handle exit codes:
- `0` → success, parse the JSON. In reconstruction mode an `already_complete: true` report also exits `0` with `projection: null`.
- `2` → usage error.
- `3` → data source error. If stderr says a US id "is not declared in the US backlog", re-run with `--no-us-validation`.
- `4` → insufficient sample (< 2 closed sprints). JSON still valid (`projection: null`). Render anyway; `has-forward = false` → headline becomes "Muestra insuficiente".

### 3. Generate `docs/team-performance/sprint-NN-performance.typ`

Write the file using the template in §"Typst Report Template" below. **Substitute every `<placeholder>` with values from the JSON.**

Key mappings from JSON to template variables:
- `has-forward`: `true` if `projection != null` AND `projection.forward != null`; `false` otherwise (insufficient data OR already complete with `target-us = 0`)
- `p-meet`: `projection.forward.p_meet_or_exceed_target` (only when `has-forward = true`; set to `0` otherwise)
- `remaining-sprints`: `reconstruction.derived_remaining_sprints` (reconstruction) or the `--remaining-sprints` arg (manual)
- `target-us`: `reconstruction.derived_target_user_stories` (reconstruction) or `--target-user-stories` (manual); set to `0` when `already_complete = true`
- `throughput-mean/min/max`: from `aggregate.throughput.*`
- `mvp-total`: `reconstruction.mvp_total`
- `mvp-done`: `reconstruction.mvp_completed_through`
- `already-complete`: `reconstruction.already_complete`

**Small sample warning:** include the warning block (see template) when `has-forward = true` AND the number of closed sprints in the history window (N) is ≤ 3. The block references N directly: `"Muestra pequeña (N = X sprints):"`. Remove the block entirely for N ≥ 4 or when `has-forward = false`.

Pick the headline colour:

| Condition | Colour | Verdict (es-AR) |
|-----------|--------|-----------------|
| `already-complete` is `true` | `c-good` | "MVP completo a esta altura." |
| `has-forward` is `false` (and not already-complete) | `c-warn` | "Muestra insuficiente para proyectar (< 2 sprints)." |
| `p-meet ≥ 0.85` | `c-good` | "Estábamos en camino." |
| `p-meet ≥ 0.50` | `c-warn` | "Estaba ajustado — proteger el alcance." |
| `p-meet < 0.50` | `c-bad` | "No llegábamos en el horizonte — recortar o extender." |

### 4. Compile to PDF

```sh
typst compile --root docs docs/team-performance/sprint-NN-performance.typ
# or compile the whole set: just build-team-performance
```

### 5. End-of-task checks

- Verify the headline matches the JSON, the reconstruction header states the right as-of sprint / window / horizon, and all copy is es-AR.
- Tell the user the report path, the headline number + verdict, and (for a full reconstruction) offer to render the remaining sprints.

---

## Typst Report Template (`docs/team-performance/sprint-NN-performance.typ`)

Substitute every `<…>` with values from the JSON. The data block at the top is the **only** thing that changes between runs.

```typst
#import "../template.typ": c-brand, c-brand-mid, conf
#import "@preview/cetz:0.3.4": canvas, draw
#import "@preview/cetz-plot:0.1.1": plot

#show: conf
#set page(margin: (x: 1.8cm, y: 1.8cm))

// ── Traffic-light palette ─────────────────────────────────────────────────
#let c-good = rgb("#1e8449")
#let c-warn = rgb("#d68910")
#let c-bad  = rgb("#c0392b")
#let c-muted = luma(120)
#let c-proj = rgb("#1a1a1a")

// ── Data block (regenerated each run from the CLI JSON) ───────────────────
#let phase = "<config_snapshot.phase>"
#let schema-version = "<schema_version>"
#let bootstrap-samples = <projection.bootstrap_samples or 10000>
#let seed = <config_snapshot.seed>

// One row per *closed* sprint:
// (index, "window_start → window_end", completed_count, wip_at_end)
#let sprints = (
  (1, "<s1.window_start> → <s1.window_end>", <s1.completed_count>, <s1.wip_at_end>),
  // …repeat per sprint…
)

#let throughput-mean = <aggregate.throughput.mean>
#let throughput-min  = <aggregate.throughput.min>
#let throughput-max  = <aggregate.throughput.max>

#let target-us = <derived_target_user_stories or 0 when already_complete>

// Set has-forward = true when projection != null AND projection.forward != null.
// Set has-forward = false for sprint 1 (insufficient data) or already-complete.
#let has-forward = <true | false>
#let remaining-sprints = <derived_remaining_sprints or remaining_sprints>
#let p-meet = <projection.forward.p_meet_or_exceed_target or 0>

// Reconstruction — set is-reconstruction = false if JSON reconstruction == null.
#let is-reconstruction = true
#let as-of-sprint = <reconstruction.as_of_sprint>
#let hist-from = <reconstruction.history_from>
#let hist-to = <reconstruction.history_to>
#let mvp-total = <reconstruction.mvp_total>
#let mvp-done = <reconstruction.mvp_completed_through>
#let already-complete = <reconstruction.already_complete>

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
#let headline-msg   = verdict.at(0)

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
        #text(size: 9pt)[Probabilidad de completar #target-us User Stories en #remaining-sprints sprints]
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
        #text(size: 9pt, weight: "medium")[#headline-msg]
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

// ── Small sample warning (include when has-forward = true AND N ≤ 3) ──────
// Replace <X> with the actual sprint count in the history window (hist-to value).
// Remove this block entirely for N ≥ 4 or when has-forward = false.
#v(0.4cm)
#block(
  fill: c-warn.lighten(85%),
  stroke: 0.5pt + c-warn,
  inset: (x: 0.6cm, y: 0.35cm),
  radius: 4pt,
  width: 100%,
  [
    #text(weight: "bold", fill: c-warn)[Muestra pequeña (N = <X> sprints):] resultado indicativo — con tan pocos datos el bootstrap es muy sensible a valores individuales.
  ],
)

#v(0.4cm)

// ── Detalle por sprint ────────────────────────────────────────────────────
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

// ── Estadísticas de throughput ────────────────────────────────────────────
== Estadísticas de throughput

#block(
  fill: luma(248),
  stroke: 0.5pt + luma(200),
  inset: 0.7cm,
  radius: 4pt,
  width: 100%,
  [
    #text(size: 11pt, weight: "bold", fill: c-brand)[Throughput (US MVP completadas / sprint)]
    #v(0.2cm)
    #table(
      columns: (auto, auto, 1fr),
      stroke: none,
      [*Media*],   [#calc.round(throughput-mean, digits: 2)], [Promedio de User Stories del MVP completadas por sprint.],
      [*Mín/Máx*], [#throughput-min / #throughput-max],       [Peor / mejor sprint observado.],
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
```

---

## Examples

### Example 1 — "Reconstruct our performance sprint by sprint" (the usual ask)

```sh
for n in 1 2 3 4 5; do
  uv run team-performance --sprints-dir docs/progress-reports --phase development \
      --as-of-sprint $n --no-us-validation --format json > /tmp/tp-s$n.json
done
```

For each: read the `reconstruction` block, generate `docs/team-performance/sprint-0$n-performance.typ` from the template, then compile. Expect **sprint 1 → "Muestra insuficiente"** (`has-forward = false`), **sprints 2-3 → small sample warning**, and once the MVP is burned down, **`already_complete = true` → "MVP completo a esta altura."**.

### Example 2 — "What were our odds at the end of sprint 3?"

`uv run team-performance --as-of-sprint 3 --no-us-validation --format json`. Headline = forward `p_meet_or_exceed_target` for the derived target over the `6 − 3 = 3`-sprint horizon.

### Example 3 — Manual "What are our odds of finishing X USs in N sprints?"

Drop `--as-of-sprint`; pass `--target-user-stories X --remaining-sprints N`. Set `is-reconstruction = false`; headline becomes the forward `p_meet_or_exceed_target`.

---

## Don'ts

- **Don't** invent projection numbers when the CLI emitted `projection: null`.
- **Don't** add per-assignee tables, even if asked.
- **Don't** combine `--as-of-sprint` with `--target-user-stories` / `--remaining-sprints` — the CLI exits 2.
- **Don't** pass the *total* MVP count as the reconstruction target — the tool forecasts *remaining* work.
- **Don't** commit `team-performance/*.typ` / `*.pdf` to git unless the user asks.
- **Don't** edit the JSON output by hand.
- **Don't** skip the `--root docs` flag when compiling.
- **Don't** put the `.typ` outside `docs/team-performance/`.
- **Don't** include `throughput-median`, `throughput-stdev`, `lead-p*`, `inv-*`, or `proj-p10/50/90` variables — they are not in the template and will cause Typst errors.
- **Don't** use the large badge dimensions (`width: 80%`, `56pt` text) — the real template uses `width: 40%` and `28pt`.
- **Don't** include "Proyección — inversa", "Proyección — directa", or "Aclaraciones" sections — those are not part of the current report structure.

---

## See also

- **Design decision:** [ADR 0001 — reconstruction derives its scope](../../../docs/adr/0001-team-performance-reconstruction-derives-scope.md)
- Tool source + JSON schema (v4): `docs/scripts/team_performance/README.md`
- The sprint ledger: `docs/progress-reports/sprint-NN.md`
- Calendar / sprint windows (6 dev sprints): `CALENDAR.md`
- MVP scope source: `MVP — Release 1` section of `docs/artifacts/backlog-us.typ`
- Shared Typst styling: `docs/template.typ` (palette: `c-brand`, `c-brand-mid`)
