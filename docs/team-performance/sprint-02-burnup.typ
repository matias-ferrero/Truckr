// Burn-up "Proyecciones" — imagen Sprint 2 (reconstrucción --as-of-sprint 2).
// Columna acumulada hasta S2 + recta de proyección del Sprint 2.
#import "_burnup-overlay.typ": proj-s23, render-burnup

#render-burnup(
  cum: ((0, 0), (1, 3), (2, 18)),
  projections: (
    (..proj-s23, sprints: (2,), current: true),
  ),
)
