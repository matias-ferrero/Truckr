#import "@preview/cmarker:0.1.8"

= Prevent workstation from sleeping for 8 hours

_2026-05-13 02:35 UTC — rama `feature/REMOVE-quote-widget-landing` — claude-opus-4-7_

== Intercambio 1

=== Prompt

#cmarker.render(
  ```
  prevent this workstation from sleeping for 8h
  ```,
  h1-level: 4,
  label-prefix: "cc3334-",
)

=== Respuesta (Claude)

#cmarker.render(
  ```
  Lock active. Sleeps/idle/lid-switch blocked for 8h.

  - Cancel early: `pkill -f "systemd-inhibit.*claude-code"`
  - Check status: `systemd-inhibit --list`
  ```,
  h1-level: 4,
  label-prefix: "cc3335-",
)
