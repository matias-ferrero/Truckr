#import "../template.typ": c-brand, c-brand-mid, conf, stroke-std
#show: conf

= Informe de Costos T&M

== 1. Resumen Ejecutivo

#block(
  width: 100%,
  inset: 12pt,
  radius: 4pt,
  fill: rgb("#eaf2f8"),
  stroke: 0.5pt + c-brand,
)[
  *Modelo de contratación:* Time \& Materials (T\&M)
]

#v(0.8em)

#table(
  columns: (1fr, 1fr),
  align: (left, left),
  table.header(
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Concepto]],
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Detalle]],
  ),
  [Modelo de engagement], [T\&M con cadencia ágil (sprints de 1 semanas)],
  [Equipo], [6 Desarrolladores Semi-Senior],
  [Burn rate mensual (equipo)], [USD 26.400],
  [Burn rate por sprint (1 sem.)], [USD 1440],
  [Tooling IA mensual], [USD 120],
  [Infraestructura AWS mensual (prototipo)], [USD 68],
  [Ventana inicial de compromiso], [3 sprints semanales],
  [Costo total ventana inicial], [USD 4.752 (equipo + tooling + AWS)],
  [Período de calibración], [Sprints 1–3 (pronósticos de baja confianza)],
)

#pagebreak()

== 2. Marco de Valor (Value Framework)

En lugar de una estructura de desglose de trabajo con estimaciones horarias, se presenta un *Backlog de Valor*: una lista priorizada de capacidades ordenadas por impacto de negocio.

=== Mapa de Valor — Truckr®

#table(
  columns: (auto, 1fr, auto, 1fr),
  align: (center, left, center, left),
  table.header(
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Prio.]],
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Capacidad]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Tipo de Valor]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Resultado de Negocio]],
  ),
  [1],
  [Registro e inicio de sesión],
  [Adquisición de usuarios],
  [Base de usuarios habilitada; sin esto no hay plataforma],

  [2],
  [Publicación de disponibilidad (transportista)],
  [Generación de oferta],
  [Inventario de transportes disponibles para matchear con demanda],

  [3],
  [Búsqueda y filtrado de transportistas],
  [Adquisición de clientes],
  [Los clientes pueden encontrar el transporte que necesitan],

  [4],
  [Oferta y aceptación de viaje],
  [Ingresos directos],
  [Transacción core del marketplace; habilita el flujo de dinero],

  [5],
  [Pasarela de pagos],
  [Ingresos directos],
  [Monetización: comisiones por transacción],

  [6],
  [Tracking de estado del viaje],
  [Retención de usuarios],
  [Confianza y transparencia; reduce disputas],

  [7],
  [Modificación de perfil],
  [Retención de usuarios],
  [Personalización; datos completos mejoran el matching],

  [8],
  [Sistema de reseñas],
  [Efecto de red],
  [Confianza entre pares; diferenciador vs. transporte tradicional],

  [9],
  [Detalles del transportista],
  [Conversión],
  [Información para decidir; reduce fricción en la contratación],

  [10],
  [Viajes compuestos],
  [Expansión de mercado],
  [Abre segmento de cargas parciales; mayor utilización de flota],
)

#v(0.8em)

#block(
  width: 100%,
  inset: 10pt,
  radius: 4pt,
  fill: rgb("#fef9e7"),
  stroke: 0.5pt + rgb("#f0b429"),
)[
  *Modelo mental para el cliente:* las restricciones más duras (tiempo y personas) son fijas. La incertidumbre se gestiona a través del alcance variable. El tamaño del equipo y las tarifas están fijados; lo que flexiona es *qué se construye*, guiado por valor.
]

#pagebreak()

== 3. Composición del Equipo y Tarifa (Rate Card)

Las tarifas son multiplicadas contra *time boxes* (sprints, meses), no contra estimaciones por tarea.

=== Rate Card

#table(
  columns: (1fr, auto, auto, auto, auto),
  align: (left, center, center, center, center),
  table.header(
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Rol]],
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Cant.]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Tarifa/hora (USD)]],
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Horas/sprint]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Costo/sprint (USD)]],
  ),
  [Desarrollador Semi-Senior], [6], [\$30], [8], [\$1.440],
  table.cell(fill: luma(240), colspan: 4)[#align(
    right,
  )[*Total por sprint (1 semana)*]],
  table.cell(fill: luma(240))[*\$1.440*],
)

#v(0.5em)

#table(
  columns: (1fr, auto),
  align: (left, center),
  table.header(
    table.cell(fill: c-brand-mid)[#text(fill: white, weight: "bold")[Período]],
    table.cell(fill: c-brand-mid)[#text(
      fill: white,
      weight: "bold",
    )[Costo Equipo (USD)]],
  ),
  [1 sprint (1 semana)], [\$1.440],
  [1 mes (4 sprints)], [\$5.760],
  [Ventana inicial — 3 sprints], [\$5.760],
)

#pagebreak()

== 4. Presupuesto de Tooling IA y Materiales

Estos no son costos vinculados a reducir horas en tareas específicas — son *inversiones en infraestructura que incrementan el throughput*.

=== Costos Mensuales de Herramientas IA

#table(
  columns: (1fr, auto, auto, auto),
  align: (left, center, center, center),
  table.header(
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Herramienta]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Costo unitario]],
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Cantidad]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Costo mensual (USD)]],
  ),
  [Asistente de código IA (Cursor / Copilot / Claude Code)],
  [\$20/seat],
  [6 seats],
  [\$120],
  table.cell(fill: luma(240), colspan: 3)[#align(
    right,
  )[*Total mensual tooling IA*]],
  table.cell(fill: luma(240))[*\$120*],
)

#v(0.8em)

#block(
  width: 100%,
  inset: 10pt,
  radius: 4pt,
  fill: rgb("#eaf2f8"),
  stroke: 0.5pt + c-brand,
)[
  *Justificación:* Las herramientas de coding con IA ahorran en promedio \~3.6 horas/semana/desarrollador. En un modelo \#NoEstimates, esto se traduce directamente en *más ítems entregados por sprint*, no en menos horas facturadas.
]

#v(1em)

=== Infraestructura Cloud — AWS (Prototipo)

Los recursos están dimensionados para un entorno de prototipo con carga baja (\~50 usuarios concurrentes). Se prioriza costo sobre disponibilidad; sin Multi-AZ ni redundancia hasta validar el producto.

#table(
  columns: (1fr, auto, auto, auto, auto),
  align: (left, left, center, center, center),
  table.header(
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Servicio]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Tipo / Instancia]],
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Cant.]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Precio unitario]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Costo mensual (USD)]],
  ),
  [EC2 — Servidor de aplicación (API \+ backend)],
  [t3.small (2 vCPU, 2 GB RAM)],
  [1],
  [\$15,18/mes],
  [\$15,18],

  [EC2 — Servidor de workers / tareas asíncronas],
  [t3.micro (2 vCPU, 1 GB RAM)],
  [1],
  [\$7,59/mes],
  [\$7,59],

  [RDS — Base de datos relacional (PostgreSQL 16)],
  [db.t3.micro (2 vCPU, 1 GB RAM, 20 GB SSD, Single-AZ)],
  [1],
  [\$14,93/mes],
  [\$14,93],

  [ElastiCache — Caché y sesiones (Redis 7)],
  [cache.t3.micro (1 vCPU, 0,5 GB RAM)],
  [1],
  [\$11,52/mes],
  [\$11,52],

  [S3 — Almacenamiento (imágenes, docs, backups)],
  [Standard — 50 GB \+ 10 GB transferencia],
  [1],
  [≈ \$1,15/mes],
  [\$1,15],

  [Application Load Balancer],
  [ALB (1 regla, \~10 LCU estimadas)],
  [1],
  [\$16,20/mes],
  [\$16,20],

  [Route 53 — DNS],
  [Hosted Zone \+ consultas estándar],
  [1],
  [\$0,50/mes],
  [\$0,50],

  [CloudFront — CDN (assets estáticos)],
  [10 GB transferencia, 1M requests],
  [1],
  [≈ \$1,00/mes],
  [\$1,00],

  [Elastic IP],
  [IPv4 — asociada a EC2],
  [1],
  [\$0,00/mes],
  [\$0,00],

  table.cell(fill: luma(240), colspan: 4)[#align(
    right,
  )[*Total mensual infraestructura AWS*]],
  table.cell(fill: luma(240))[*\~\$68,07*],
)

#v(0.8em)

#block(
  width: 100%,
  inset: 10pt,
  radius: 4pt,
  fill: rgb("#fef9e7"),
  stroke: 0.5pt + rgb("#f0b429"),
)[
  *Supuestos del sizing:* precios us-east-1 (Virginia), sin reserva (on-demand). Las instancias `t3` tienen créditos de CPU burst, adecuadas para cargas variables de prototipo. Para producción, se recomienda evaluar Reserved Instances (ahorro \~30–40\%) y habilitar Multi-AZ en RDS.
]

#pagebreak()

== 5. Modelo de Proyección (Throughput-Based Forecasting)

El progreso se mide contando ítems entregados y comparándolos con el backlog pendiente. No se usan estimaciones horarias ni story points.

=== Disciplina de Slicing de Stories

Cada historia de usuario debe ser *independiente y pequeña*: idealmente, no más de 1 día de desarrollo. El objetivo es entregar entre 6 y 12 stories por sprint de 1 semana.

=== Medición de Throughput

Después de 3–5 iteraciones, se dispone de datos suficientes para medir ítems/sprint y proyectar hacia adelante.

#table(
  columns: (auto, auto, auto, auto),
  align: (center, center, center, center),
  table.header(
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Sprint]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Ítems entregados]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Throughput acum.]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Confianza del pronóstico]],
  ),
  [Sprint 1], [? (calibración)], [—], [Muy baja],
  [Sprint 2], [? (calibración)], [—], [Baja],
  [Sprint 3], [? (calibración)], [Promedio 3 sprints], [Media],
  [Sprint 4], [Medido], [Promedio 4 sprints], [Media-Alta],
  [Sprint 5], [Medido], [Promedio 5 sprints], [Alta],
  [Sprint 6+], [Medido], [Media móvil], [Alta],
)

=== Simulación Monte Carlo

Las proyecciones son *probabilísticas*, no determinísticas. Se utiliza referencia de clase (reference class forecasting) basada en datos reales de rendimiento pasado.

#block(
  width: 100%,
  inset: 10pt,
  radius: 4pt,
  fill: rgb("#eaf2f8"),
  stroke: 0.5pt + c-brand,
)[
  *Ejemplo de pronóstico (post-calibración):*\
  - Backlog MVP restante: 45 ítems\
  - Throughput promedio: 9 ítems/sprint (±2)\
  - Pronóstico Monte Carlo:\
    - 50\% de probabilidad: 5 sprints\
    - 85\% de probabilidad: 6 sprints\
    - 95\% de probabilidad: 7 sprints
]

#pagebreak()

== 6. Plan de Calibración

Los primeros 3–5 sprints constituyen el *período de calibración* donde se establece el throughput del equipo. Durante este período, los pronósticos son de baja confianza.

#table(
  columns: (auto, 1fr, 1fr),
  align: (center, left, left),
  table.header(
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Sprint]],
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Foco]],
    table.cell(fill: c-brand)[#text(
      fill: white,
      weight: "bold",
    )[Entregable de gestión]],
  ),
  [1],
  [
    Setup del entorno de desarrollo\
    Onboarding del equipo\
    Configuración de CI/CD\
    Primeras stories de Registro/Login
  ],
  [
    Primer dato de throughput\
    Validación del proceso de slicing\
    Rate card y tooling confirmados
  ],

  [2],
  [
    Completar flujo de registro\
    Publicación de disponibilidad (transportista)\
    Refinamiento del backlog con el cliente
  ],
  [
    Segundo dato de throughput\
    Ajuste del proceso si hay bloqueos\
    Primer burn-up chart
  ],

  [3],
  [
    Búsqueda y filtrado de transportistas\
    Primeras stories de oferta de viaje
  ],
  [
    Primer pronóstico Monte Carlo (baja confianza)\
    Throughput promedio de 3 sprints\
    Retrospectiva de calibración
  ],

  [4–5],
  [
    Continuación de funcionalidades por prioridad de valor\
    Pasarela de pagos\
    Tracking de viaje
  ],
  [
    Pronósticos de confianza media-alta\
    Proyección de fecha para MVP\
    Primer value checkpoint con el cliente
  ],
)

#pagebreak()

== 7. Cadencia de Reportes

El informe compromete una *cadencia de transparencia* en lugar de un plan de entrega fijo.

=== Entregables por Sprint

#table(
  columns: (auto, 1fr),
  align: (left, left),
  table.header(
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Artefacto]],
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Descripción]],
  ),
  [Sprint Review], [Demostración de ítems entregados con conteo acumulado],
  [Burn-up Chart],
  [Ítems completados vs. tamaño total del backlog (incluyendo ítems descubiertos)],

  [Throughput Chart], [Ítems/sprint con media móvil y tendencia],
  [Pronóstico Monte Carlo],
  [Proyección probabilística actualizada con datos reales del sprint],

  [Mapa de Valor actualizado],
  [Resultados de negocio habilitados hasta el momento, mapeados al marco de valor],

  [Reporte de inversión], [Gasto acumulado vs. valor entregado; ROI proyectado],
)

#v(0.8em)

=== Rolling Wave Forecasting

En lugar de re-estimar todo con cada cambio, se proyecta basado en datos reales. La gestión continua de alcance opera desde el día uno, alcanzando niveles de precisión cercanos al 100\% a medida que se acumulan datos.

#pagebreak()

== 8. Guardarraíles de Inversión

Aun sin estimaciones, el cliente necesita seguridad financiera.

#table(
  columns: (auto, 1fr),
  align: (left, left),
  table.header(
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Mecanismo]],
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Detalle]],
  ),
  [Ventana de compromiso],
  [3 meses iniciales (6 sprints). Renovable por períodos de 1–3 meses.],

  [Tope de gasto por sprint],
  [\$19.200 de equipo + hasta \$1.515 de tooling = máximo \$20.715/sprint. El burn rate es predecible porque la composición del equipo es fija.],

  [Value checkpoints],
  [
    Al final del Sprint 3 (fin de calibración) y Sprint 6 (fin de ventana inicial).\
    El cliente evalúa si el valor entregado justifica continuar la inversión.\
    *Ejemplo:* si al Sprint 6 el equipo entregó features que cubren el 80\% del valor proyectado, el cliente puede decidir frenar — y eso es un éxito, no un fracaso.
  ],

  [Rampas de salida (off-ramps)],
  [
    El cliente puede finalizar el engagement al cierre de cualquier sprint con 2 semanas de aviso.\
    Todo el código y artefactos producidos son propiedad del cliente.
  ],

  [Scope como variable],
  [
    El alcance nunca se asume fijo.\
    El \"scope creep\" se reenmarca como *descubrimiento de valor*: un proceso natural donde ítems descubiertos se incorporan a medida que las prioridades cambian.
  ],
)

#pagebreak()

== 9. Riesgos y Supuestos

#table(
  columns: (auto, 1fr, 1fr),
  align: (left, left, left),
  table.header(
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Riesgo]],
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Descripción]],
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Mitigación]],
  ),
  [Calibración],
  [Los primeros 3–5 sprints tendrán datos de throughput poco fiables. Los pronósticos iniciales no son confiables.],
  [Comunicación transparente. No se prometen fechas hasta completar la calibración.],

  [Variabilidad de productividad IA],
  [
    Si bien los desarrolladores perciben un 20\% de mejora con IA, estudios controlados muestran resultados mixtos — la revisión y debugging a veces agregan tiempo.
  ],
  [
    El modelo mide throughput *real*, no productividad asumida. La mejora de IA se captura automáticamente en los datos.
  ],

  [Madurez de slicing],
  [
    Todo el modelo depende de stories consistentemente pequeñas. Si el equipo tiene dificultades con el slicing, el throughput se vuelve volátil.
  ],
  [
    Coaching de slicing en sprints iniciales. Workshops de refinamiento con el Tech Lead.
  ],

  [Colaboración del cliente],
  [
    Value-first requiere participación activa del cliente en la priorización cada sprint.
  ],
  [
    Sesiones de refinamiento agendadas. Product Owner del lado del cliente comprometido.
  ],

  [Dependencias externas],
  [
    Integraciones con pasarelas de pago u otros servicios externos pueden bloquear stories.
  ],
  [
    Stories independientes. Mocks y stubs para desarrollar sin depender de terceros.
  ],
)

#pagebreak()

== 10. Qué No Incluye Este Informe (y por qué)

#table(
  columns: (1fr, 1fr),
  align: (left, left),
  table.header(
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Excluido]],
    table.cell(fill: c-brand)[#text(fill: white, weight: "bold")[Razón]],
  ),
  [Estimaciones de costo por feature],
  [
    Los delays en un sistema complejo son impredecibles. El trabajo pasa considerablemente más tiempo idle y bloqueado por restricciones del sistema que avanzando activamente.
  ],

  [Diagramas de Gantt con fechas por feature],
  [
    Reemplazados por pronósticos probabilísticos (Monte Carlo) que reflejan la realidad con mayor precisión.
  ],

  [Story points o compromisos de velocity],
  [
    Reemplazados por throughput (ítems/sprint): una métrica observable y no inflable.
  ],

  [Costo total del proyecto],
  [
    Reemplazado por *costo por time-box* + *cantidad proyectada de time-boxes para alcanzar el umbral de valor*. El costo total emerge de los datos, no de una estimación a priori.
  ],

  [Alcance fijo],
  [
    El alcance es la variable de ajuste. Las restricciones fijas son tiempo (cadencia de sprints) y personas (composición del equipo).
  ],
)
