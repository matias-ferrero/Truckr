// Burn-up "Proyecciones" — imagen Sprint 3 (reconstrucción --as-of-sprint 3).
// Se agrega la columna del Sprint 3; su recta tiene la misma pendiente que la
// del Sprint 2 (9 US/sprint), así que se superponen en una sola recta rotulada
// "Sprint 2 y 3".
#import "_burnup-overlay.typ": proj-s23, render-burnup

#render-burnup(
  cum: ((0, 0), (1, 3), (2, 18), (3, 27)),
  projections: (
    (..proj-s23, sprints: (2, 3), current: true),
  ),
)
