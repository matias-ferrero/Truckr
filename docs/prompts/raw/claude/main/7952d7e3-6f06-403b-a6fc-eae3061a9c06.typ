#import "@preview/cmarker:0.1.8"

= Fix user story requirements in backlog

_2026-05-14 21:23 UTC — rama `main`_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  Corrijamos la US en @docs/artifacts/backlog-us.typ del registro:
  "redirigir al login después de crear cuenta" es falso, simplemente te lleva al dashboard
  "mail o nombre de usuario deben ser únicos" falso, solo el mail debe ser único
  la contraseña debe tener al menos 8 caracteres
  todos los campos son obligatorios, no están marcados
  ```,
  h1-level: 4,
  label-prefix: "cc1242-",
)
