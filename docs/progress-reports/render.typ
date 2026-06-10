// Progress-report renderer — turns a markdown sprint report into a themed PDF.
//
// Driven by `just build-progress-reports` / `just build-progress-report <name>`,
// which pass the source path as a typst input:
//
//   typst compile --root docs --input report=/progress-reports/sprint-05.md \
//       docs/progress-reports/render.typ docs/progress-reports/sprint-05.pdf
//
// The markdown body is rendered via cmarker; the YAML frontmatter becomes a
// themed title block. Add a new sprint by dropping a `sprint-NN.md` next to
// this file — no edits here.

#import "../template.typ": c-brand, c-brand-mid, conf
#import "@preview/cmarker:0.1.6"

#let report-path = sys.inputs.at(
  "report",
  default: none,
)
#if report-path == none {
  panic(
    "missing --input report=<path>; run via `just build-progress-report <name>`",
  )
}

#let source = read(report-path)

// Split a leading `---\n … \n---` YAML frontmatter block off the markdown body.
// Returns (frontmatter-string-or-none, body-markdown).
#let split-frontmatter(src) = {
  if not src.starts-with("---\n") {
    return (none, src)
  }
  let rest = src.slice(4)
  let close = rest.position("\n---")
  if close == none {
    return (none, src)
  }
  let fm = rest.slice(0, close)
  let after = rest.slice(close + 4) // drop "\n---"
  let nl = after.position("\n")
  let body = if nl == none { "" } else { after.slice(nl + 1) }
  (fm, body)
}

#let (frontmatter, body) = split-frontmatter(source)
#let meta = if frontmatter == none { (:) } else { yaml(bytes(frontmatter)) }

#let meta-line = {
  let parts = ()
  if "window" in meta { parts.push([Ventana: #meta.window]) }
  if "phase" in meta { parts.push([Fase: #meta.phase]) }
  if "status" in meta { parts.push([Estado: #meta.status]) }
  parts
}

#show: conf
#set page(numbering: "1 / 1")

// ── Title block ─────────────────────────────────────────────────────────────
#if "sprint" in meta {
  block(
    width: 100%,
    inset: (bottom: 0.6em),
    stroke: (bottom: 1.5pt + c-brand),
  )[
    #text(size: 20pt, weight: "bold", fill: c-brand)[
      Sprint #meta.sprint — Reporte de Progreso
    ]
    #if meta-line.len() > 0 {
      linebreak()
      text(size: 9.5pt, fill: c-brand-mid)[#meta-line.join(text(
        fill: luma(150),
      )[ · ])]
    }
    #if (
      "completed_user_stories" in meta
        and type(meta.completed_user_stories) == array
    ) {
      linebreak()
      text(size: 9.5pt, fill: luma(90))[
        #meta.completed_user_stories.len() historias completadas
      ]
    }
  ]
  v(0.4em)
}

// ── Body ────────────────────────────────────────────────────────────────────
#cmarker.render(body)
