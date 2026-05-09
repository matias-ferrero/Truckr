---
name: team-performance
description: "Run the team-performance CLI to measure throughput, project backlog completion (forward + inverse, with optional scope-growth), and emit an eye-catching team-performance.pdf (Typst + cetz). Use when the user asks 'will we finish in N sprints?', 'how many sprints to clear the backlog?', 'what's our throughput?', or wants a performance/forecast report."
---

# team-performance

Wraps the `team-performance` CLI (`docs/scripts/team_performance/`) and turns
its JSON (schema **v2**) into a **Typst report (`docs/team-performance.typ` →
`.pdf`)**. The report leads with a colour-coded probability badge and lays out
both **inverse** (sprints needed at p50/p85/p95/p99) and **forward** (P[≥
target] in N sprints) projections, plus the optional **scope-growth** model.
Every number prints with a one-line caption — no orphaned metrics.

**Language convention.** The CLI text/JSON output and the generated Typst report are **product content** (an academic deliverable shown to the team and reviewers) and therefore in **es-AR** — see `CLAUDE.md` "Language Rules". Only Python identifiers, JSON keys, Typst variable names, and this SKILL.md prose stay in English. If you ever add a new metric, surface its name and `_meaning` in es-AR; keep the JSON key in `snake_case` English.

**Use when:**
- "What are the chances we finish all the backlog in N sprints?"
- "How many sprints will it take?"
- "What's our team's throughput?"
- "Forecast / project / proyectar / estimar cuánto vamos a cerrar."
- "Genera el reporte de performance del equipo."
- The user wants a snapshot of velocity for a retro / sprint review.

**Don't use when:**
- The user wants per-person stats (the tool — by design — never disaggregates by assignee).
- There are < 2 *completed* sprints of history of the relevant cadence (the projection refuses; just report observed metrics, no headline number).

---

## Inputs

| Input | Required | How to obtain |
|-------|----------|---------------|
| `sprint_start` (YYYY-MM-DD) | Yes | **Read from [`CALENDAR.md`](../../../CALENDAR.md) first** — it is the source of truth for sprint windows. Default for the dev phase: `2026-05-07`. Only ask the user if `CALENDAR.md` is missing or the user is asking about a phase not covered there. |
| `sprint_length_days`        | Yes | **Read from [`CALENDAR.md`](../../../CALENDAR.md) first.** Default: `7` (weekly, Thu → Wed). Only ask the user if they explicitly want a non-canonical cadence. |
| `as_of` (YYYY-MM-DD)        | No (default = today UTC) | Cutoff for "completed" sprints. Only fully-elapsed sprints before this date are scored. |
| `target_issues`             | If projecting | Triggers the **inverse** projection. If the user says "all of the backlog", count open issues: `gh issue list --state open --limit 1000 --json number --jq 'length'`. If they mean a specific board column, count that. **Always confirm what counts as "the backlog" before running.** |
| `remaining_sprints`         | Optional | If given alongside `--target-issues`, also runs the **forward** projection. Without it the report still shows "sprints to target". Cannot be used alone. |
| `scope_growth`              | No (default off) | Pass `--scope-growth` when the backlog is known to *grow* during execution. Enables a split Monte Carlo: each simulated sprint also adds a sampled items-created count to the running target. Off by default — explain to the user before turning it on. |
| `bootstrap_samples`         | No | Default `10000`. Lower for fast iterations, higher only if percentile noise matters. |
| `repo`                      | No | Defaults to `[tool.team_performance].repo` in `pyproject.toml` (currently `tcorzo/fiuba-gestion-tp`). |
| `seed`                      | No | Default `42`. Only override if the user explicitly asks. |
| `output_path`               | No | Default `docs/team-performance.typ` (compiled to `docs/team-performance.pdf`). Must live **under `docs/`** so the `--root docs` Typst invocation can resolve `template.typ`. |

---

## Critical caveats — surface these to the user before reporting numbers

These come from the tool's plan and they materially change the meaning of the output. Ignoring them produces misleading forecasts.

1. **Sprint length must be consistent between history and projection.** Throughput is "issues / sprint" — if history was measured in 14-day sprints, the rate does not translate to a 7-day horizon. Pick one cadence and stick to it. If the user asks for weekly projections but history is biweekly, **say so and stop**; do not silently re-bin or scale.
2. **Need ≥ 2 completed sprints of the same cadence.** Otherwise the CLI exits 4 (`InsufficientDataError`). The observed metrics are still emitted; the projection block will be `null`. Render the report anyway — the headline becomes "Muestra insuficiente" instead of a probability — and explain why.
3. **"Backlog" is whatever you pass to `--target-issues`.** The CLI does not auto-count open issues. Confirm the scope: *all* open issues, or only `Backlog/`+`Ready/` board items? Different scopes → different probabilities.
4. **No per-person numbers, ever.** Team aggregates only. If the user asks for an assignee breakdown, refuse and cite the policy (deliberate decision recorded in the implementation plan).
5. **Closed ≠ delivered.** As of schema v2, the CLI consults GitHub's `stateReason`: only `COMPLETED` closures count toward throughput. `NOT_PLANNED` and `DUPLICATE` closures are reported in a separate "excluded" column so the operator can audit them but they don't pollute the velocity sample.
6. **Bootstrap is empirical, not Monte Carlo over estimates.** Each future sprint's throughput is sampled (with replacement) from the observed-throughput distribution. The output is *purely* historical replay — not adjusted for team capacity changes, holidays, or known scope shifts. Flag any of those that the user mentions; they are not modelled.
7. **Scope-growth is opt-in.** When the user mentions "the backlog will keep growing" or you can see in the per-sprint table that `created > closed`, suggest `--scope-growth`. The split Monte Carlo will also sample items-created per sprint and grow the target during each trial — so `did_not_finish_pct` can shoot up if the team is intake-bound. Off by default because the math is harder to explain.
8. **Determinism: same seed + same data → byte-identical output** (excluding `generated_at`). If two runs differ, the data underneath changed.

---

## Step-by-Step Process

### 1. Clarify scope with the user (if not already pinned down)

**First, read [`CALENDAR.md`](../../../CALENDAR.md) at the repo root.** It pins down sprint length, sprint windows, and which phase (documentation vs. development) we're in. Use those values as the defaults — do **not** ask the user to restate what `CALENDAR.md` already specifies.

Then confirm in one short turn whatever `CALENDAR.md` does *not* answer:
- Which phase is the question about (dev vs. documentation)? Default to **dev** unless context says otherwise.
- What counts as "the backlog" for this question (all open GH issues vs. specific board columns).
- Whether to model scope growth (default off; turn on when the user mentions the backlog will keep growing or per-sprint `created > closed` historically).
- (Optional) A specific horizon `--remaining-sprints` if the user is asking the "in N sprints?" framing in addition to "how many sprints?".

If `CALENDAR.md` is missing, fall back to asking the user for sprint length + Sprint 1 start, and offer to create `CALENDAR.md` from their answer. Do not pick defaults silently.

### 2. Count the target issues (if projecting)

```sh
# All open issues in the configured repo:
gh issue list --state open --limit 1000 --json number --jq 'length'

# Or, only board columns Backlog + Ready:
ls .gdsi-sdlc/issues/Backlog .gdsi-sdlc/issues/Ready | grep -c '\.issue\.md$'
```

Echo the count back to the user and confirm.

### 3. Run the CLI (JSON only — Typst will own the rendering)

```sh
uv run team-performance \
    --sprint-start <YYYY-MM-DD> \
    --sprint-length-days <N> \
    --as-of <YYYY-MM-DD>            # optional, defaults to today \
    --target-issues <COUNT> \
    --remaining-sprints <N>         # optional; adds the forward block \
    --scope-growth                  # optional; enables split Monte Carlo \
    --format json \
    > /tmp/team-performance.json
```

Handle exit codes:
- `0` → success, parse `/tmp/team-performance.json`.
- `2` → usage error. Re-read the flags; `--remaining-sprints` cannot be used without `--target-issues`.
- `3` → data source error (`gh` missing or repo wrong). Surface stderr to the user.
- `4` → insufficient sample. The JSON is still valid (with `projection: null`). Render the report; the headline section becomes "Muestra insuficiente" rather than a probability.

### 4. Generate `docs/team-performance.typ`

Write the file using the template in §"Typst Report Template" below. **Substitute every `<placeholder>` with values from the JSON** — the template is fully self-contained (uses only `cetz:0.3.4`, `cetz-plot:0.1.1`, and the repo's `template.typ`) so the only step that varies between runs is the data block at the top.

Pick the headline colour from the inverse projection's `did_not_finish_pct` *and* (if present) the forward `p_meet_or_exceed_target`:

| Condition | Colour | Verdict (es-AR, as rendered) |
|-----------|--------|------------------------------|
| `forward` present and `p_meet_or_exceed_target ≥ 0.85` | `c-good` (green) | "Estamos en camino." |
| `forward` present and `p_meet_or_exceed_target ≥ 0.50` | `c-warn` (amber) | "Está ajustado — protejamos el alcance." |
| `forward` present and `p_meet_or_exceed_target < 0.50` | `c-bad` (red) | "No llegamos en el horizonte — recortar alcance o extender." |
| `forward` absent and `did_not_finish_pct ≤ 0.05` | `c-good` | "Backlog alcanzable al ritmo actual." |
| `forward` absent and `did_not_finish_pct ≤ 0.25` | `c-warn` | "Alcanzable pero ajustado — protejamos el alcance." |
| `forward` absent and `did_not_finish_pct > 0.25` | `c-bad` | "El backlog crece más rápido que el throughput — recortar alcance o cambiar cadencia." |
| `projection` is `null` (insufficient sample) | `c-warn` | "Se necesitan ≥ 2 sprints completados antes de poder proyectar." |

If `scope_growth_enabled = true`, the template appends "(con crecimiento de alcance)" to the verdict so the reader knows the projection includes intake.

### 5. Compile to PDF

```sh
typst compile --root docs docs/team-performance.typ
# → docs/team-performance.pdf
```

If the compile fails, **do not edit the PDF or the JSON** — fix the `.typ` template and re-run.

### 6. End-of-task checks

- Read the PDF (this tool can read PDFs) and verify:
  - The headline number matches the JSON.
  - **Every metric in every table has its "Significado" column populated** — no orphan numbers.
  - The per-sprint detail table shows the "Excl." column (even if zero) and the caption defines it.
  - If `--scope-growth` was on, the scope-growth section ("Modelo de crecimiento de alcance") is present and the verdict ends in "(con crecimiento de alcance)".
  - All user-facing copy is in es-AR — only JSON keys, Typst variable names, and `state_reason` enum values stay English.
- Tell the user the report path (`docs/team-performance.pdf`), the headline number + verdict, and offer to rerun with a different scope/horizon/scope-growth setting.

---

## Typst Report Template (`docs/team-performance.typ`)

Substitute every `<…>` with values from the JSON. The data block at the top is the **only** thing that should change between runs; the rendering logic stays put.

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
#let repo = "<repo>"
#let as-of = "<as_of>"
#let sprint-start = "<sprint_start>"
#let sprint-length-days = <sprint_length_days>
#let schema-version = "<schema_version>"
#let bootstrap-samples = <bootstrap_samples>
#let seed = <seed>

// One row per *completed* sprint
// (index, "start → end", closed_count, closed_excluded_count, created_count, wip_at_end)
#let sprints = (
  (1, "<s1.start_date> → <s1.end_date>", <s1.closed_count>, <s1.closed_excluded_count>, <s1.created_count>, <s1.wip_at_end>),
  // …repeat per sprint…
)

#let throughput-mean   = <aggregate.throughput.mean>
#let throughput-median = <aggregate.throughput.median>
#let throughput-stdev  = <aggregate.throughput.stdev>     // or `none` if null
#let throughput-min    = <aggregate.throughput.min>
#let throughput-max    = <aggregate.throughput.max>
#let closed-excluded-total = <aggregate.closed_excluded_total>
#let cycle-p50 = <aggregate.cycle_time_days.p50>           // or `none`
#let cycle-p75 = <aggregate.cycle_time_days.p75>
#let cycle-p90 = <aggregate.cycle_time_days.p90>

// Projection block — set `has-projection` to `false` if JSON `projection == null`
#let has-projection = true
#let scope-growth-on = <projection.scope_growth_enabled>   // bool
#let target-issues = <projection.target_issues>

// Inverse — always present when has-projection
#let inv-p50 = <projection.sprints_to_target.p50>
#let inv-p85 = <projection.sprints_to_target.p85>
#let inv-p95 = <projection.sprints_to_target.p95>
#let inv-p99 = <projection.sprints_to_target.p99>
#let inv-did-not-finish = <projection.sprints_to_target.did_not_finish_pct>   // 0.0 – 1.0
#let inv-cap = <projection.sprints_to_target.cap_sprints>

// Forward — set has-forward = false if JSON `projection.forward == null`
#let has-forward = true
#let remaining-sprints = <projection.forward.remaining_sprints>
#let p-meet = <projection.forward.p_meet_or_exceed_target>
#let proj-p10 = <projection.forward.total_projected_p10>
#let proj-p50 = <projection.forward.total_projected_p50>
#let proj-p90 = <projection.forward.total_projected_p90>

// Scope growth — set has-scope-growth = false if JSON `projection.scope_growth == null`
#let has-scope-growth = scope-growth-on
#let created-mean = <projection.scope_growth.created_per_sprint_mean>
#let created-median = <projection.scope_growth.created_per_sprint_median>
#let created-min = <projection.scope_growth.created_per_sprint_min>
#let created-max = <projection.scope_growth.created_per_sprint_max>

// Traffic-light selection — see §4 of SKILL.md
#let verdict = if not has-projection {
  ("Se necesitan ≥ 2 sprints completados antes de poder proyectar.", c-warn)
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
  ("El backlog crece más rápido que el throughput — recortar alcance o cambiar cadencia.", c-bad)
}
#let headline-color = verdict.at(1)
#let headline-msg   = verdict.at(0) + (if scope-growth-on and has-projection { " (con crecimiento de alcance)" } else { "" })

// ── Document ──────────────────────────────────────────────────────────────

#align(center)[
  #text(size: 9pt, fill: c-muted)[
    Reporte de performance del equipo · #repo · al #as-of
  ]
  #v(0.2cm)
  #text(size: 28pt, weight: "bold", fill: c-brand)[
    Throughput y proyección
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
          #text(size: 11pt)[Probabilidad de cerrar #target-issues issues en #remaining-sprints sprints]
          #v(0.15cm)
          #text(size: 56pt, weight: "black")[
            #calc.round(p-meet * 100, digits: 1)%
          ]
        ] else [
          #text(size: 11pt)[Sprints para cerrar #target-issues issues (confianza 85%)]
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
  Inicio Sprint 1 *#sprint-start* · duración *#sprint-length-days d* ·
  esquema *#schema-version* · seed *#seed* · muestras *#bootstrap-samples* ·
  crecimiento de alcance *#if scope-growth-on { "activado" } else { "desactivado" }*
]

#v(0.6cm)

// ── Throughput per completed sprint ───────────────────────────────────────
== Throughput por sprint completado

#align(center)[
  #canvas(length: 1cm, {
    import draw: *
    plot.plot(
      size: (14, 5),
      x-tick-step: 1,
      y-tick-step: none,
      y-min: 0,
      x-label: "Sprint #",
      y-label: "Issues entregados",
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
    Barras: issues entregados por sprint (sólo state\_reason = COMPLETED).
    Línea punteada: throughput medio (#calc.round(throughput-mean, digits: 2) issues/sprint).
  ]
]

#v(0.4cm)

== Detalle por sprint

#align(center)[
  #table(
    columns: (auto, 1fr, auto, auto, auto, auto),
    align: (center, left, right, right, right, right),
    fill: (col, row) => if row == 0 { c-brand.lighten(80%) } else { none },
    [*#*], [*Ventana*], [*Cerrados*], [*Excl.*], [*Creados*], [*WIP\@fin*],
    ..sprints.map(s => (
      [#s.at(0)],
      [#s.at(1)],
      [#s.at(2)],
      [#s.at(3)],
      [#s.at(4)],
      [#s.at(5)],
    )).flatten()
  )
  #text(size: 8pt, fill: c-muted)[
    *Cerrados* = entregados (state\_reason = COMPLETED).
    *Excl.* = cerrados-pero-no-entregados (NOT\_PLANNED, DUPLICATE) — visibles para auditoría, *no* cuentan como throughput.
    *Creados* = ítems agregados al alcance en la ventana. *WIP\@fin* = ítems abiertos al cierre del sprint.
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
      #text(size: 11pt, weight: "bold", fill: c-brand)[Throughput (issues entregados / sprint)]
      #v(0.2cm)
      #table(
        columns: (auto, auto, 1fr),
        stroke: none,
        [*Media*],   [#calc.round(throughput-mean, digits: 2)],   [Promedio de issues entregados por sprint.],
        [*Mediana*], [#calc.round(throughput-median, digits: 2)], [Issues entregados en un sprint típico.],
        [*Desv. estándar*],  [#if throughput-stdev == none { "—" } else { calc.round(throughput-stdev, digits: 2) }], [Dispersión alrededor de la media — mayor = menos predecible.],
        [*Mín/Máx*], [#throughput-min / #throughput-max], [Peor / mejor sprint observado.],
        [*Cierres excluidos*], [#closed-excluded-total], [Cerrados como not\_planned/duplicate, no cuentan como throughput.],
      )
    ],
  ),
  block(
    fill: luma(248), stroke: 0.5pt + luma(200), inset: 0.7cm, radius: 4pt, width: 100%,
    [
      #text(size: 11pt, weight: "bold", fill: c-brand)[Tiempo de ciclo (días, sólo entregados)]
      #v(0.2cm)
      #if cycle-p50 == none [
        #text(fill: c-muted)[No hay issues cerrados todavía.]
      ] else [
        #table(
          columns: (auto, auto, 1fr),
          stroke: none,
          [*p50*], [#calc.round(cycle-p50, digits: 1)], [La mitad de los issues se completan dentro de estos días.],
          [*p75*], [#calc.round(cycle-p75, digits: 1)], [Tres cuartos se completan dentro de estos días.],
          [*p90*], [#calc.round(cycle-p90, digits: 1)], [Nueve de cada diez se completan dentro de estos días.],
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
      Método: #if scope-growth-on { "bootstrap split (throughput + crecimiento de alcance)" } else { "bootstrap sólo del throughput" } ·
      #bootstrap-samples muestras · seed #seed.
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
          y-label: "Issues cerrados (total proyectado)",
          axis-style: "school-book",
          {
            plot.add-bar(
              ((1, proj-p10), (2, proj-p50), (3, proj-p90)),
              bar-width: 0.6,
              style: (fill: c-brand-mid, stroke: c-brand),
            )
            plot.add-hline(
              target-issues,
              style: (stroke: (paint: c-bad, dash: "dashed", thickness: 1.4pt)),
            )
          },
        )
      })
      #text(size: 8pt, fill: c-muted)[
        Barras: total proyectado de issues entregados en p10 / p50 / p90 sobre #bootstrap-samples muestras de bootstrap.
        Línea roja punteada: target = #target-issues.
      ]
    ]

    #v(0.3cm)

    #align(center)[
      #table(
        columns: (auto, auto, 1fr),
        align: (left, right, left),
        fill: (col, row) => if row == 0 { c-brand.lighten(80%) } else { none },
        [*Métrica*], [*Valor*], [*Significado*],
        [P(cerrar ≥ target) en #remaining-sprints sprints], [#calc.round(p-meet * 100, digits: 1)%], [Probabilidad de terminar el backlog dentro del horizonte fijo.],
        [Total pesimista (p10)], [#proj-p10], [Sólo el 10% de los futuros entregan menos que esto.],
        [Total mediano (p50)], [#proj-p50], [Mediana del total entregado sobre el horizonte.],
        [Total optimista (p90)], [#proj-p90], [Sólo el 10% de los futuros entregan más que esto.],
      )
    ]

    #v(0.4cm)
  ]

  #if has-scope-growth [
    == Modelo de crecimiento de alcance

    #align(center)[
      #table(
        columns: (auto, auto, 1fr),
        align: (left, right, left),
        fill: (col, row) => if row == 0 { c-brand.lighten(80%) } else { none },
        [*Ítems agregados por sprint*], [*Valor*], [*Significado*],
        [Media], [#calc.round(created-mean, digits: 2)], [Promedio histórico de ítems agregados por sprint — usado para hacer crecer el target en cada sprint simulado.],
        [Mediana], [#created-median], [Ítems agregados en un sprint típico.],
        [Mín], [#created-min], [Sprint histórico más tranquilo por intake.],
        [Máx], [#created-max], [Sprint histórico más ruidoso por intake.],
      )
      #text(size: 8pt, fill: c-muted)[
        Bootstrap split: cada sprint simulado también muestrea un valor de esta distribución y lo suma al target acumulado.
        Si media(agregados) ≥ media(entregados), el modelo no llega al target frecuentemente — ver *did_not_finish* arriba.
      ]
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
      sprints completados de la cadencia configurada (#sprint-length-days días).
      Volver a correr cuando cierre un sprint más.
    ],
  )
]

#v(0.6cm)

== Aclaraciones

#set text(size: 9pt)
- El throughput se muestrea con la duración de sprint configurada
  (*#sprint-length-days días*). Si el equipo cambia la cadencia, esta
  proyección deja de aplicar.
- *Cerrados* cuenta sólo `state_reason = COMPLETED`. Los cerrados como
  `NOT_PLANNED` o `DUPLICATE` aparecen en la columna *Excl.* y no alimentan
  el throughput.
- Cambios futuros de capacidad (feriados, cambios en el tamaño del equipo)
  *no* están modelados. El bootstrap asume que los sprints futuros se
  comportan como los pasados.
- "Target = #target-issues" se pasó como entrada. Si cambia el alcance del
  backlog, volver a correr con el nuevo conteo.
- #if scope-growth-on [ El crecimiento de alcance está *activado*: el target
  crece en cada sprint simulado por una cantidad muestreada de ítems
  creados. ] else [ El crecimiento de alcance está *desactivado*: el target
  queda fijo. Volver a correr con `--scope-growth` si se sabe que el backlog
  va a seguir creciendo durante la ejecución. ]
- Los números son *agregados del equipo*. La desagregación por persona
  asignada no se produce intencionalmente.
- Reproducible con seed *#seed* contra el mismo dataset para obtener salida
  byte-idéntica (excluyendo `generated_at`).
```

---

## Examples

### Example 1 — "Will we finish all the backlog in 7 weekly sprints?"

```
User: We have ~30 issues left. Will we finish in 7 weekly sprints?
       Sprint 1 started 2026-04-21.
```

1. Read `CALENDAR.md`. If it confirms weekly cadence + a `2026-04-21` start (or close), use those defaults; otherwise confirm.
2. Confirm: target = 30. Ask whether scope-growth should be on (it should, if the team is still adding issues).
3. Run:
   ```sh
   uv run team-performance \
       --sprint-start 2026-04-21 \
       --sprint-length-days 7 \
       --target-issues 30 \
       --remaining-sprints 7 \
       --scope-growth \
       --format json > /tmp/tp.json
   ```
4. Generate `docs/team-performance.typ` from the template, substituting JSON values. Pick the headline colour from the forward-projection rule (since `--remaining-sprints` was given).
5. `typst compile --root docs docs/team-performance.typ`.
6. Tell the user: report path + headline number + verdict + offer to tweak inputs.

### Example 2 — "How many sprints do we need?" (inverse only, no horizon)

```
User: I don't care about the horizon — just tell me how many sprints
       it'll take to clear the backlog.
```

Drop `--remaining-sprints`; keep `--target-issues`. The CLI emits the inverse projection only; `forward` will be `null`. The headline becomes "p85 = N sprints" with the inverse-only traffic-light rule.

### Example 3 — "Just stats, no projection."

Run without `--target-issues` (and without `--remaining-sprints`). The CLI returns `projection: null`. In the template, set `has-projection = false`; the headline falls back to the insufficient-sample branch ("Muestra insuficiente") and the projection sections are omitted. The throughput chart, sprint detail, and aggregate cards still render — every metric still has its "Significado" column.

---

## Don'ts

- **Don't** silently translate biweekly throughput to weekly horizons (or vice versa). Refuse and explain.
- **Don't** invent projection numbers when the CLI emitted `projection: null`.
- **Don't** add per-assignee tables, even if asked. Cite the policy and offer team aggregates instead.
- **Don't** commit `team-performance.typ` / `team-performance.pdf` to git unless the user asks — they're ad-hoc snapshots, not tracked artifacts. (`*.pdf` is already ignored.)
- **Don't** edit the JSON output by hand. If it's wrong, fix the inputs and re-run.
- **Don't** skip the `--root docs` flag when compiling — `template.typ` resolution depends on it.
- **Don't** put the `.typ` outside `docs/` — the template import will break.
- **Don't** put a number in the report without a one-line meaning beside it. The schema's `_meaning` companion fields exist precisely so the report can print metric + caption together.
- **Don't** leave English copy in the rendered PDF. Per `CLAUDE.md`, product output is es-AR. Code identifiers (Python, Typst variable names, JSON keys) and the `state_reason` enum stay English.

---

## See also

- Tool source + JSON schema: `docs/scripts/team_performance/README.md`
- Implementation plan + design rationale: `docs/features/INF/INF-GEN-00001/INF-GEN-00001-team-performance-script.plan.md`
- Issue: `INF-GEN-00001` (GitHub #51)
- Shared Typst styling: `docs/template.typ` (palette: `c-brand`, `c-brand-mid`, etc.)
