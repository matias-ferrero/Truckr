#import "../template.typ": conf
#show: conf

= Backlog — User Stories

// ───────────────────────────────────────────────────────────────────────────
// Helper: release banner
// ───────────────────────────────────────────────────────────────────────────

#let release-banner(label, color) = {
  v(2em)
  block(
    fill: color,
    width: 100%,
    inset: (x: 1em, y: 0.75em),
    radius: 4pt,
  )[
    #text(weight: "bold", size: 13pt, fill: white)[#label]
  ]
  v(0.75em)
}

#let us(path) = {
  v(1.2em)
  block(
    breakable: false,
    width: 100%,
    inset: (x: 0.6em, y: 0.6em),
    stroke: (left: 2pt + rgb("#DADADA")),
    radius: (left: 2pt),
  )[
    #include path
  ]
}

// ═══════════════════════════════════════════════════════════════════════════
// MVP — Release 1
// ═══════════════════════════════════════════════════════════════════════════

#release-banner("MVP — Release 1", rgb("#6AA84F"))

#us("backlog-us/US001.typ")
#us("backlog-us/US002.typ")
#us("backlog-us/US003.typ")
#us("backlog-us/US004.typ")
#us("backlog-us/US006.typ")
#us("backlog-us/US007.typ")
#us("backlog-us/US008.typ")
#us("backlog-us/US009.typ")
#us("backlog-us/US010.typ")
#us("backlog-us/US012.typ")
#us("backlog-us/US014.typ")
#us("backlog-us/US015.typ")
#us("backlog-us/US017.typ")
#us("backlog-us/US018.typ")
#us("backlog-us/US019.typ")
#us("backlog-us/US020.typ")
#us("backlog-us/US025.typ")
#us("backlog-us/US026.typ")
#us("backlog-us/US027.typ")
#us("backlog-us/US030.typ")
#us("backlog-us/US031.typ")
#us("backlog-us/US032.typ")
#us("backlog-us/US033.typ")
#us("backlog-us/US034.typ")
#us("backlog-us/US035.typ")
#us("backlog-us/US036.typ")
#us("backlog-us/US037.typ")
#us("backlog-us/US038.typ")
#us("backlog-us/US039.typ")
#us("backlog-us/US040.typ")
#us("backlog-us/US042.typ")
#us("backlog-us/US043.typ")
#us("backlog-us/US044.typ")
#us("backlog-us/US045.typ")
#us("backlog-us/US046.typ")
#us("backlog-us/US047.typ")
#us("backlog-us/US048.typ")
#us("backlog-us/US049.typ")
#us("backlog-us/US050.typ")
#us("backlog-us/US051.typ")
#us("backlog-us/US052.typ")
#us("backlog-us/US053.typ")
#us("backlog-us/US054.typ")
#us("backlog-us/US057.typ")
#us("backlog-us/US058.typ")
#us("backlog-us/US059.typ")

#include "backlog-us/US060.typ"

#include "backlog-us/US064.typ"

#include "backlog-us/US065.typ"

#include "backlog-us/US066.typ"

#include "backlog-us/US067.typ"

// ═══════════════════════════════════════════════════════════════════════════
// Post MVP — Release 2
// ═══════════════════════════════════════════════════════════════════════════

#release-banner("Post MVP — Release 2", rgb("#3D7AB5"))

#us("backlog-us/US005.typ")
#us("backlog-us/US011.typ")
#us("backlog-us/US016.typ")
#us("backlog-us/US022.typ")
#us("backlog-us/US028.typ")
#us("backlog-us/US029.typ")
#us("backlog-us/US041.typ")
#us("backlog-us/US055.typ")
#us("backlog-us/US056.typ")

// ═══════════════════════════════════════════════════════════════════════════
// Post MVP — Release 3
// ═══════════════════════════════════════════════════════════════════════════

#release-banner("Post MVP — Release 3", rgb("#7B5EA7"))

#us("backlog-us/US013.typ")
#us("backlog-us/US021.typ")
#us("backlog-us/US023.typ")
#us("backlog-us/US024.typ")
#us("backlog-us/US061.typ")
#us("backlog-us/US062.typ")
#us("backlog-us/US063.typ")
