// Shared template for GDSI project artifacts (Truckr®)

// ── Brand palette ─────────────────────────────────────────────────────────
#let c-brand = rgb("#154360")   // Truckr deep navy
#let c-brand-mid = rgb("#1f618d")   // Accent blue

// ── User Story Map palette ────────────────────────────────────────────────
#let c-epic = rgb("#154360")
#let c-activ = rgb("#1f618d")
#let c-task = rgb("#aed6f1")
#let c-mvp-lane = rgb("#1e8449")
#let c-mvp = rgb("#d5f5e3")
#let c-post-lane = rgb("#6e2f1a")
#let c-post = rgb("#fef5e4")

// ── Shared stroke ─────────────────────────────────────────────────────────
#let stroke-std = 0.5pt + luma(180)

#let conf(body) = {
  set text(lang: "es", size: 10pt)
  set page(margin: 2cm)
  set par(justify: true)
  set table(stroke: stroke-std)
  show heading: set text(fill: c-brand)
  body
}
