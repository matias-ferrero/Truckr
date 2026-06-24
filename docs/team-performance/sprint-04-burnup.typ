// Burn-up "Proyecciones" — imagen Sprint 4 (reconstrucción --as-of-sprint 4).
// Se agrega la columna del Sprint 4 y su recta, superpuesta sobre la recta
// común de los Sprints 2 y 3. La pendiente se empina (10,25 US/sprint) y
// adelanta el cruce con el techo del MVP.
#import "_burnup-overlay.typ": proj-s23, proj-s4, render-burnup

#render-burnup(
  cum: ((0, 0), (1, 3), (2, 18), (3, 27), (4, 41)),
  projections: (
    (..proj-s23, sprints: (2, 3), current: false),
    (..proj-s4, sprints: (4,), current: true),
  ),
)
