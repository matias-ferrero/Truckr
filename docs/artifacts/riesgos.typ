#import "../template.typ": conf, stroke-std
#show: conf

= Riesgos del Proyecto

El registro de riesgos identifica eventos que pueden afectar el cumplimiento del proyecto Truckr®. Se documentan en profundidad los riesgos de mayor exposición — derivados del WBS, USM, decisiones técnicas diferidas y dependencias externas — y se mantienen como /stubs/ los demás para revisión incremental durante el avance del proyecto.

== Metodología

=== Identificación

Los riesgos se derivan de las fuentes existentes del proyecto:

- *WBS* — riesgos por entregable (integraciones con ARCA, Maps, aseguradora; pago seguro; gestión de siniestros).
- *User Story Map* — riesgos por activity / task group (matching, pagos, tracking).
- *Visión técnica del proyecto* — cada decisión diferida es un riesgo latente: SQLite como base primaria, almacenamiento geoespacial pendiente, estrategia mobile sin definir, autenticación no implementada.
- *Sistemas externos* — dependencias con ARCA, Mercado Pago, Maps/GPS y aseguradora.
- *Personas* — riesgos de adopción y /cold-start/ del marketplace de doble lado (Carriers y Shippers).

=== Evaluación

Cada riesgo se evalúa con dos dimensiones en escala 1–5:

#table(
  columns: (auto, 1fr, 1fr),
  inset: (x: 6pt, y: 5pt),
  stroke: stroke-std,
  table.header(
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Nivel]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Probabilidad]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Impacto]],
  ),
  [1], [Muy improbable], [Insignificante],
  [2], [Improbable], [Menor],
  [3], [Posible], [Moderado],
  [4], [Probable], [Mayor],
  [5], [Casi seguro], [Crítico],
)

La *exposición* se calcula como $P times I$ (rango 1–25).

=== Priorización

#table(
  columns: (auto, auto, 1fr),
  inset: (x: 6pt, y: 5pt),
  stroke: stroke-std,
  table.header(
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Nivel]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Rango]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Acción]],
  ),
  [Crítico], [≥ 16], [Mitigación + contingencia obligatorias; revisión semanal],
  [Alto], [9–15], [Mitigación obligatoria; revisión quincenal],
  [Medio], [4–8], [Mitigación opcional; revisión mensual],
  [Bajo], [1–3], [Aceptado; sin acción inmediata],
)

#pagebreak()
#set page(flipped: true, margin: (x: 1cm, y: 1.2cm))

== Registro de Riesgos

#set text(size: 9.5pt)

#table(
  columns: (
    auto,
    auto,
    2.2fr,
    auto,
    auto,
    auto,
    1.5fr,
    1.8fr,
    1.6fr,
    auto,
    auto,
  ),
  inset: (x: 4pt, y: 5pt),
  stroke: stroke-std,
  align: (
    left,
    left,
    left,
    center,
    center,
    center,
    left,
    left,
    left,
    left,
    left,
  ),
  table.header(
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[ID]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Categoría]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Descripción]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[P]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[I]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Exp.]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Trigger]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Mitigación]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Contingencia]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Owner]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Estado]],
  ),

  // ── R-01 — Externo / dependencias ──────────────────────────────────────
  [*R-01*],
  [Externo / dependencias],
  [Demora o falta de acceso al ambiente de homologación de *ARCA* (WBS 3.1) bloquea la facturación electrónica de viajes. El alta de CUIT de prueba y la obtención de certificados pueden tardar semanas y dependen de un tercero estatal.],
  [4],
  [4],
  [16 — Crítico],
  [No se obtiene CUIT/certificado de prueba dentro de las 2 primeras semanas del sprint que ataca facturación.],
  [Iniciar el trámite ARCA al inicio del proyecto; encapsular la integración detrás de un /adapter/ con stub local; priorizar el flujo MVP sin facturación electrónica obligatoria.],
  [Diferir la integración ARCA a fase post-MVP y dejar la emisión manual fuera de la app para la demo; documentar la limitación en la nota de entrega.],
  [Tech Lead],
  [abierto],

  // ── R-02 — Negocio / mercado ───────────────────────────────────────────
  [*R-02*],
  [Negocio / mercado],
  [/Cold-start/ del marketplace de doble lado: sin Carriers publicando disponibilidad (WBS 2.2.1) los Shippers no encuentran ofertas, y sin demanda los Carriers abandonan. Riesgo derivado directamente del modelo de personas del proyecto.],
  [4],
  [4],
  [16 — Crítico],
  [En la demo o en pruebas con usuarios piloto: < 5 publicaciones activas o tasa de match < 20% en una semana.],
  [Sembrar el lado oferta con 3–5 Carriers conocidos antes de abrir la plataforma; diseñar la demo con datos /seed/ realistas; enfocar el MVP en una zona geográfica acotada (AMBA).],
  [Pivotar la demo a un escenario guiado (datos pre-cargados) en lugar de captación orgánica; documentar el supuesto de /seed/ en la presentación.],
  [PM],
  [abierto],

  // ── R-03 — Equipo / proceso ────────────────────────────────────────────
  [*R-03*],
  [Equipo / proceso],
  [*Capacidad de equipo de 6 personas* contra un backlog amplio (5 epics: cuentas, plataformas, integraciones, seguro, gestión). La distribución promedio es 1–2 personas por epic: ausencias coincidentes (examen, enfermedad, carga laboral) en un mismo frente pueden detenerlo, y un /bus factor/ = 1 por epic queda como riesgo latente. La ausencia actual de tests automatizados amplifica el costo de regresiones.],
  [3],
  [3],
  [9 — Alto],
  [Velocity por sprint cae > 30 % respecto al sprint anterior, o aparece una US carry-over por 2+ sprints consecutivos.],
  [Recortar alcance del MVP a las epics 1–2 (cuentas + plataforma cliente); aplicar /pair programming/ sobre módulos críticos para evitar /bus factor/ = 1; priorizar tests de integración mínimos sobre flujos de pago.],
  [Mover seguro y ARCA a /post-MVP/ explícitamente; entregar demo basada solo en matching + pago manual fuera de plataforma.],
  [PM],
  [abierto],

  // ── R-04 — Técnico ─────────────────────────────────────────────────────
  [*R-04*],
  [Técnico],
  [La decisión diferida de *almacenamiento geoespacial* (planteada en la Visión Técnica como parte de la /Scalability Roadmap/ fase 2) impacta el filtrado por origen/destino (WBS 2.1.1.1), la estimación de costos (WBS 2.1.3.2) y la integración con Maps (WBS 3.3). SQLite no soporta consultas geoespaciales eficientes y postergar la decisión obliga a re-trabajar consultas.],
  [3],
  [4],
  [12 — Alto],
  [Aparición de la primera US que requiera /bounding-box query/ o /distance-from-point/, o degradación de tiempos de respuesta en búsqueda de Carriers.],
  [Tomar la decisión geo (PostGIS vs. proveedor externo) antes de implementar la primera US de búsqueda geográfica; encapsular consultas geográficas detrás de un /repository/ para poder cambiar el /backend/ después.],
  [Implementar el filtrado geográfico inicial con cálculo de Haversine en Ruby + filtro por bounding-box en SQLite; aceptar la degradación hasta migrar.],
  [Tech Lead],
  [abierto],

  // ── R-05 — Regulatorio / legal ─────────────────────────────────────────
  [*R-05*],
  [Regulatorio / legal],
  [El esquema de *escrow / retención de pagos* entre Shipper y Carrier (WBS 2.1.5 + 3.2) configura intermediación financiera en AR. Sin estructura legal adecuada (cuenta recaudadora, T\&C, condiciones de uso) se incurre en exposición regulatoria por Ley 25.246 (UIF) y normativa BCRA sobre PSP.],
  [3],
  [5],
  [15 — Alto],
  [Conversación con asesor legal o feedback de la cátedra que indique que el flujo de pago propuesto requiere licencia / encuadre PSP.],
  [Limitar la integración de pago del MVP a Mercado Pago como /payment processor/ sin retención (pago directo Shipper → Carrier vía /Marketplace/ ML); documentar T\&C básicos; consultar normativa antes de implementar escrow propio.],
  [Eliminar el escrow del alcance del MVP; mostrar el flujo como pago directo y documentar el escrow como /feature/ post-MVP que requiere análisis legal previo.],
  [PM],
  [abierto],
)

#pagebreak()
#set page(flipped: false, margin: 2cm)
#set text(size: 10pt)

== Riesgos en Stub

#set text(size: 9pt)

#table(
  columns: (auto, auto, 3fr, auto, auto),
  inset: (x: 6pt, y: 5pt),
  stroke: stroke-std,
  align: (left, left, left, center, center),
  table.header(
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[ID]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Categoría]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[Descripción]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[P]],
    table.cell(fill: rgb("#154360"), align: center)[#text(
      fill: white,
      weight: "bold",
    )[I]],
  ),

  [*S-01*],
  [Técnico],
  [Techo de escala de SQLite como base primaria (decisión diferida): /write contention/ al crecer el volumen de ofertas y reseñas obliga a migrar a PostgreSQL antes de lo planificado en la /Scalability Roadmap/ fase 1.],
  [2],
  [3],

  [*S-02*],
  [Técnico],
  [Ausencia de /authentication-authorization/ implementada (decisión diferida): retrasos en el diseño del modelo de identidad bloquean US dependientes (perfil, ofertas, pagos).],
  [3],
  [3],

  [*S-03*],
  [Externo / dependencias],
  [/Lock-in/ con Google Maps por costos de geocoding y rutas (WBS 3.3); cambio a proveedor alternativo (HERE, OSRM) requiere reescribir la capa de mapas.],
  [2],
  [3],

  [*S-04*],
  [Externo / dependencias],
  [Falta de API estable de aseguradora para cotización por viaje (WBS 4.1, 4.2): la mayoría de aseguradoras AR no expone APIs públicas de /quote\&bind/ y obliga a integración manual o /broker/ intermediario.],
  [4],
  [3],

  [*S-05*],
  [Negocio / mercado],
  [Datos de tracking GPS imprecisos o ausentes en zonas rurales argentinas; impacta la confianza del Shipper en la actualización de estado del viaje (WBS 2.2.4.3).],
  [3],
  [2],

  [*S-06*],
  [Equipo / proceso],
  [/Scope creep/ por feedback de cátedra: pedidos de funcionalidades nuevas en revisiones intermedias que no estaban en el USM/WBS aprobado, comprometiendo el deadline académico.],
  [3],
  [3],

  [*S-07*],
  [Regulatorio / legal],
  [Cambios normativos en transporte de cargas AR (CNRT, peajes, bromatología) durante el ciclo del proyecto que invaliden supuestos del modelo de negocio o de las US.],
  [2],
  [3],

  [*S-08*],
  [Equipo / proceso],
  [Deadline académico fijo (entrega de cuatrimestre) vs. backlog amplio: imposibilidad de mover la fecha si aparecen bloqueos técnicos no anticipados.],
  [3],
  [4],
)

#set text(size: 10pt)

== Notas

- El registro es un /snapshot/ a la fecha de entrega; este artefacto no incluye /risk burn-down/ temporal ni histórico de transiciones de estado.
- Las mitigaciones que requieran trabajo concreto se trackean como /issues/ separados en el sistema de seguimiento del proyecto y se derivan de los planes de mitigación listados arriba.
- Los riesgos asociados a /features/ post-MVP / fase 2+ (mobile, multi-región, alta disponibilidad) se mencionan implícitamente vía referencias a la /Scalability Roadmap/ pero no se documentan aquí.
- Los /owners/ (`PM`, `Tech Lead`) corresponden a roles del equipo, no a personas nombradas, dado el tamaño y la dinámica del equipo (6 integrantes con roles compartidos).
