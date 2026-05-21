---
name: team-performance
description: "Run the team-performance CLI to measure throughput in completed User Stories, project backlog completion (forward + inverse), and emit an eye-catching team-performance.pdf (Typst + cetz). Use when the user asks 'will we finish in N sprints?', 'how many sprints to clear the backlog?', 'what's our throughput?', or wants a performance/forecast report."
---

# team-performance

Wraps the `team-performance` CLI (`docs/scripts/team_performance/`) and turns
its JSON (schema **v3**) into a **Typst report (`docs/team-performance.typ` →
`.pdf`)**. The unit is the **completed User Story**, not the GitHub issue —
issues vary too much in size to be a stable throughput unit. The report leads
with a colour-coded probability badge and lays out both **inverse** (sprints
needed at p50/p85/p95/p99) and **forward** (P[≥ target] in N sprints)
projections. Every number prints with a one-line caption — no orphaned metrics.

**Data source.** The CLI reads a hand-maintained **per-sprint ledger**:
`docs/sprints/sprint-NN.md`, one Markdown file per sprint. There is no GitHub
access. A sprint's `completed_user_stories` is whatever the team recorded —
the tool trusts the ledger.

**Language convention.** The CLI text/JSON output and the generated Typst report are **product content** (an academic deliverable shown to the team and reviewers) and therefore in **es-AR** — see `CLAUDE.md` "Language Rules". Only Python identifiers, JSON keys, Typst variable names, and this SKILL.md prose stay in English.

**Use when:**
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
| `sprints_dir`          | No (default `docs/sprints`) | Directory of `sprint-NN.md` ledger files. |
| `phase`                | No (default `development`)  | `development` or `documentation`. The CLI counts only ledger files whose `phase` matches. Default to **development** unless the user asks otherwise. |
| `backlog_us`           | No (default `docs/artifacts/backlog-us.typ`) | The US backlog artifact, used to validate that ledger US ids are real. |
| `no_us_validation`     | No (default off) | Pass `--no-us-validation` to skip checking ledger US ids against `backlog-us.typ`. Use while the ledger references stories the backlog artifact hasn't caught up with yet — otherwise an unknown id is a fatal data error (exit 3). |
| `target_user_stories`  | If projecting | Triggers the **inverse** projection. Count the User Stories the team commits to delivering — **not** necessarily all 35 in `backlog-us.typ` (Release 3 USs may be out of course scope). **Always confirm what counts as "the backlog" before running.** |
| `remaining_sprints`    | Optional | If given alongside `--target-user-stories`, also runs the **forward** projection. Cannot be used alone. |
| `bootstrap_samples`    | No | Default `10000`. |
| `seed`                 | No | Default `42`. Only override if the user explicitly asks. |
| `output_path`          | No | Default `docs/team-performance.typ` (compiled to `docs/team-performance.pdf`). Must live **under `docs/`** so `--root docs` resolves `template.typ`. |

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

`CALENDAR.md` is the source of truth for sprint numbers and windows; each
ledger file must agree with it.

---

## Critical caveats — surface these to the user before reporting numbers

1. **Throughput is lumpy.** Big User Stories span several sprints, so many sprints score 0 completed USs. The throughput distribution is sparse and the projection intervals are wide. This is honest — do not smooth it over.
2. **Need ≥ 2 closed sprints.** Otherwise the CLI exits 4 (`InsufficientDataError`); the projection block is `null`. Render the report anyway — the headline becomes "Muestra insuficiente".
3. **"Backlog" is whatever you pass to `--target-user-stories`.** The CLI does not auto-count. Confirm scope: all 35 USs, MVP only, or minus Release 3.
4. **No per-person numbers, ever.** Team aggregates only. If asked for an assignee breakdown, refuse and cite the policy.
5. **The ledger is trusted as-is.** A US counts as completed because the team wrote it in `completed_user_stories`. Garbage in, garbage out — if the ledger is stale the forecast is wrong.
6. **Infra/docs work is invisible.** `INF-*` and doc work are not User Stories, so they never appear. This is "product throughput", not "team throughput".
7. **Lead time is coarse.** Measured in whole sprints (`completion sprint − first-seen sprint`); p50/p75/p90 are often equal.
8. **Bootstrap is empirical.** Each future sprint's throughput is resampled (with replacement) from the observed per-sprint throughput. Not adjusted for capacity changes, holidays, or known scope shifts.
9. **Determinism: same seed + same ledger → byte-identical output** (excluding `generated_at`).

---

## Step-by-Step Process

### 1. Clarify scope with the user

- Confirm the **phase** (dev vs documentation; default dev).
- Confirm what counts as **the backlog** for `--target-user-stories`.
- (Optional) a specific horizon `--remaining-sprints`.

### 2. Run the CLI (JSON only — Typst owns the rendering)

```sh
uv run team-performance \
    --sprints-dir docs/sprints \
    --phase development \
    --target-user-stories <COUNT> \
    --remaining-sprints <N>         # optional; adds the forward block \
    --no-us-validation              # optional; skip the backlog-artifact id check \
    --format json \
    > /tmp/team-performance.json
```

Handle exit codes:
- `0` → success, parse `/tmp/team-performance.json`.
- `2` → usage error. `--remaining-sprints` cannot be used without `--target-user-stories`.
- `3` → data source error (ledger missing, unparseable, or failed validation). If stderr says a US id "is not declared in the US backlog", either add the story to `backlog-us.typ` or re-run with `--no-us-validation`.
- `4` → insufficient sample. The JSON is still valid (`projection: null`). Render the report; the headline becomes "Muestra insuficiente".

### 3. Generate `docs/team-performance.typ`

Write the file using the template in §"Typst Report Template" below. **Substitute every `<placeholder>` with values from the JSON.**

Pick the headline colour:

| Condition | Colour | Verdict (es-AR) |
|-----------|--------|-----------------|
| `forward` present and `p_meet_or_exceed_target ≥ 0.85` | `c-good` | "Estamos en camino." |
| `forward` present and `p_meet_or_exceed_target ≥ 0.50` | `c-warn` | "Está ajustado — protejamos el alcance." |
| `forward` present and `p_meet_or_exceed_target < 0.50` | `c-bad` | "No llegamos en el horizonte — recortar alcance o extender." |
| `forward` absent and `did_not_finish_pct ≤ 0.05` | `c-good` | "Backlog alcanzable al ritmo actual." |
| `forward` absent and `did_not_finish_pct ≤ 0.25` | `c-warn` | "Alcanzable pero ajustado — protejamos el alcance." |
| `forward` absent and `did_not_finish_pct > 0.25` | `c-bad` | "El backlog crece más rápido que el throughput — recortar alcance." |
| `projection` is `null` | `c-warn` | "Se necesitan ≥ 2 sprints cerrados antes de poder proyectar." |

### 4. Compile to PDF

```sh
typst compile --root docs docs/team-performance.typ
# → docs/team-performance.pdf
```

If the compile fails, fix the `.typ` template and re-run — never edit the PDF or JSON.

### 5. End-of-task checks

- Read the PDF and verify the headline matches the JSON, every metric table has its "Significado" column populated, and all copy is es-AR.
- Tell the user the report path, the headline number + verdict, and offer to rerun with a different scope/horizon.

---

## Typst Report Template (`docs/team-performance.typ`)

Substitute every `<…>` with values from the JSON. The data block at the top is the **only** thing that changes between runs.

```typst
#import "template.typ": c-brand, c-brand-mid, conf
#import "@preview/cetz:0.3.4": canvas, draw
#import "@preview/cetz-plot:0.1.1": plot

#show: conf
#set page(margin: (x: 1.8cm, y: 1.8cm))

// ── Traffic-light palette ─────────────────────────────────────────────────
#let c-good = rgb("#1e8449")
#let c-warn = rgb("#d68910")
#let c-bad  = rgb("#c0392b")
#let c-muted = luma(120)

// ── Data block (regenerated each run from the CLI JSON) ───────────────────
#let phase = "<config_snapshot.phase>"
#let schema-version = "<schema_version>"
#let bootstrap-samples = <projection.bootstrap_samples or 0>
#let seed = <config_snapshot.seed>

// One row per *closed* sprint:
// (index, "window_start → window_end", completed_count, wip_at_end)
#let sprints = (
  (1, "<s1.window_start> → <s1.window_end>", <s1.completed_count>, <s1.wip_at_end>),
  // …repeat per sprint…
)

#let throughput-mean   = <aggregate.throughput.mean>
#let throughput-median = <aggregate.throughput.median>
#let throughput-stdev  = <aggregate.throughput.stdev>     // or `none` if null
#let throughput-min    = <aggregate.throughput.min>
#let throughput-max    = <aggregate.throughput.max>
#let lead-p50 = <aggregate.lead_time_sprints.p50>          // or `none`
#let lead-p75 = <aggregate.lead_time_sprints.p75>
#let lead-p90 = <aggregate.lead_time_sprints.p90>

// Projection — set `has-projection` to `false` if JSON `projection == null`
#let has-projection = true
#let target-us = <projection.target_user_stories>

// Inverse — always present when has-projection
#let inv-p50 = <projection.sprints_to_target.p50>
#let inv-p85 = <projection.sprints_to_target.p85>
#let inv-p95 = <projection.sprints_to_target.p95>
#let inv-p99 = <projection.sprints_to_target.p99>
#let inv-did-not-finish = <projection.sprints_to_target.did_not_finish_pct>
#let inv-cap = <projection.sprints_to_target.cap_sprints>

// Forward — set has-forward = false if JSON `projection.forward == null`
#let has-forward = true
#let remaining-sprints = <projection.forward.remaining_sprints>
#let p-meet = <projection.forward.p_meet_or_exceed_target>
#let proj-p10 = <projection.forward.total_projected_p10>
#let proj-p50 = <projection.forward.total_projected_p50>
#let proj-p90 = <projection.forward.total_projected_p90>

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
#let headline-msg   = verdict.at(0)

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
          #text(size: 11pt)[Probabilidad de completar #target-us User Stories en #remaining-sprints sprints]
          #v(0.15cm)
          #text(size: 56pt, weight: "black")[
            #calc.round(p-meet * 100, digits: 1)%
          ]
        ] else [
          #text(size: 11pt)[Sprints para completar #target-us User Stories (confianza 85%)]
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
    [*#*], [*Ventana*], [*US completadas*], [*WIP\@fin*],
    ..sprints.map(s => (
      [#s.at(0)],
      [#s.at(1)],
      [#s.at(2)],
      [#s.at(3)],
    )).flatten()
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
    fill: luma(248), stroke: 0.5pt + luma(200), inset: 0.7cm, radius: 4pt, width: 100%,
    [
      #text(size: 11pt, weight: "bold", fill: c-brand)[Throughput (US completadas / sprint)]
      #v(0.2cm)
      #table(
        columns: (auto, auto, 1fr),
        stroke: none,
        [*Media*],   [#calc.round(throughput-mean, digits: 2)],   [Promedio de User Stories completadas por sprint.],
        [*Mediana*], [#calc.round(throughput-median, digits: 2)], [User Stories completadas en un sprint típico.],
        [*Desv. estándar*],  [#if throughput-stdev == none { "—" } else { calc.round(throughput-stdev, digits: 2) }], [Dispersión alrededor de la media — mayor = menos predecible.],
        [*Mín/Máx*], [#throughput-min / #throughput-max], [Peor / mejor sprint observado.],
      )
    ],
  ),
  block(
    fill: luma(248), stroke: 0.5pt + luma(200), inset: 0.7cm, radius: 4pt, width: 100%,
    [
      #text(size: 11pt, weight: "bold", fill: c-brand)[Lead time (sprints)]
      #v(0.2cm)
      #if lead-p50 == none [
        #text(fill: c-muted)[No hay User Stories completadas todavía.]
      ] else [
        #table(
          columns: (auto, auto, 1fr),
          stroke: none,
          [*p50*], [#calc.round(lead-p50, digits: 1)], [La mitad de las US se completan dentro de esta cantidad de sprints.],
          [*p75*], [#calc.round(lead-p75, digits: 1)], [Tres cuartos se completan dentro de esta cantidad de sprints.],
          [*p90*], [#calc.round(lead-p90, digits: 1)], [Nueve de cada diez se completan dentro de esta cantidad de sprints.],
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
      [p50],  [#inv-p50],  [La mitad de los futuros simulados terminan en este sprint (mediana).],
      [p85],  [#inv-p85],  [Línea base de planificación — el 85% de los futuros terminan en este sprint.],
      [p95],  [#inv-p95],  [Compromiso con confianza — el 95% de los futuros terminan en este sprint.],
      [p99],  [#inv-p99],  [Peor caso — el 99% de los futuros terminan en este sprint.],
      [did_not_finish],  [#calc.round(inv-did-not-finish * 100, digits: 1)%],  [Simulaciones que llegan al tope de #inv-cap sprints. Distinto de cero ⇒ alcance > capacidad.],
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
        [P(completar ≥ target) en #remaining-sprints sprints], [#calc.round(p-meet * 100, digits: 1)%], [Probabilidad de terminar el backlog dentro del horizonte fijo.],
        [Total pesimista (p10)], [#proj-p10], [Sólo el 10% de los futuros entregan menos que esto.],
        [Total mediano (p50)], [#proj-p50], [Mediana del total entregado sobre el horizonte.],
        [Total optimista (p90)], [#proj-p90], [Sólo el 10% de los futuros entregan más que esto.],
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
  hay sprints con 0 US completadas. Los intervalos de proyección son anchos.
- El lead time se mide en *sprints enteros*.
- Cambios futuros de capacidad (feriados, cambios en el equipo) *no* están
  modelados. El bootstrap asume que los sprints futuros se comportan como los
  pasados.
- "Target = #target-us" se pasó como entrada. Si cambia el alcance, volver a
  correr con el nuevo conteo.
- Los números son *agregados del equipo*. La desagregación por persona no se
  produce intencionalmente.
- Reproducible con seed *#seed* contra el mismo ledger para obtener salida
  byte-idéntica (excluyendo `generated_at`).
```

---

## Examples

### Example 1 — "Will we finish all the backlog in 5 sprints?"

1. Confirm phase (development) and what "the backlog" means → e.g. 18 remaining USs.
2. Run:
   ```sh
   uv run team-performance \
       --sprints-dir docs/sprints --phase development \
       --target-user-stories 18 --remaining-sprints 5 \
       --format json > /tmp/tp.json
   ```
3. Generate `docs/team-performance.typ` from the template; pick the headline colour from the forward rule.
4. `typst compile --root docs docs/team-performance.typ`.
5. Report path + headline number + verdict.

### Example 2 — "How many sprints do we need?" (inverse only)

Drop `--remaining-sprints`; keep `--target-user-stories`. `forward` is `null`; the headline becomes "p85 = N sprints".

### Example 3 — "Just stats, no projection."

Run without `--target-user-stories`. `projection` is `null`; set `has-projection = false`; the headline falls back to "Muestra insuficiente". The throughput chart, sprint detail and aggregate cards still render.

---

## Don'ts

- **Don't** invent projection numbers when the CLI emitted `projection: null`.
- **Don't** add per-assignee tables, even if asked.
- **Don't** commit `team-performance.typ` / `team-performance.pdf` to git unless the user asks.
- **Don't** edit the JSON output by hand. If it's wrong, fix the ledger and re-run.
- **Don't** skip the `--root docs` flag when compiling.
- **Don't** put the `.typ` outside `docs/`.
- **Don't** put a number in the report without a one-line meaning beside it.
- **Don't** leave English copy in the rendered PDF. Code identifiers (Python, Typst variable names, JSON keys) stay English.

---

## See also

- Tool source + JSON schema: `docs/scripts/team_performance/README.md`
- The sprint ledger: `docs/sprints/sprint-NN.md`
- Calendar / sprint windows: `CALENDAR.md`
- Issue: `INF-GEN-00003` (refactor to the User-Story ledger); predecessor `INF-GEN-00001`
- Shared Typst styling: `docs/template.typ` (palette: `c-brand`, `c-brand-mid`)
