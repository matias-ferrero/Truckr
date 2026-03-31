#import "../template.typ": c-brand, c-brand-mid, conf, stroke-std
#show: conf

#set page(flipped: true, margin: (x: 1cm, y: 1.2cm))

= WBS — Work Breakdown Structure

#set text(size: 7.5pt)

#let wbs-h(body) = table.cell(
  fill: c-brand,
  align: center,
)[#text(fill: white, weight: "bold")[#body]]

#let wbs-l2(body) = table.cell(
  fill: c-brand-mid,
  align: center,
)[#text(fill: white, weight: "bold")[#body]]

#let wbs-leaf(body) = table.cell(
  fill: luma(245),
  align: left,
)[#body]

// ── Nivel 0 ────────────────────────────────────────────────────────────────
#align(center)[
  #block(
    width: 30%,
    inset: 8pt,
    radius: 4pt,
    fill: c-brand,
  )[
    #align(center)[#text(fill: white, weight: "bold", size: 10pt)[Truckr® — Plataforma de Transporte]]
  ]
]

#v(0.6em)

// ── Niveles 1–3 ────────────────────────────────────────────────────────────
#table(
  columns: (1fr,) * 6,
  inset: (x: 5pt, y: 5pt),

  // ── Nivel 1: Paquetes de trabajo principales ────────────────────────────
  wbs-h[1. Gestión de Cuentas],
  wbs-h[2. Plataforma del Cliente],
  wbs-h[3. Plataforma del Transportista],
  wbs-h[4. Funcionalidades Transversales],
  wbs-h[5. Infraestructura y Soporte],
  wbs-h[6. Mejoras Post-MVP],

  // ── Nivel 2: Sub-paquetes ───────────────────────────────────────────────
  wbs-l2[1.1 Registro],
  wbs-l2[2.1 Búsqueda de Transportistas],
  wbs-l2[3.1 Publicación de Disponibilidad],
  wbs-l2[4.1 Sistema de Reseñas],
  wbs-l2[5.1 Pasarela de Pagos],
  wbs-l2[6.1 Viajes Compuestos],

  // ── Nivel 3: Entregables ────────────────────────────────────────────────
  wbs-leaf[
    - Formulario de alta (email, nombre, contraseña)
    - Validación de contraseña segura
    - Control de usuario duplicado
  ],
  wbs-leaf[
    - Búsqueda por origen y destino
    - Búsqueda por rango de fecha
    - Listado paginado y scrolleable
    - Ordenamiento por características
  ],
  wbs-leaf[
    - Indicar zona de origen
    - Indicar límite de kilómetros
    - Indicar precio por km
    - Confirmar publicación
  ],
  wbs-leaf[
    - Reseña de cliente a transportista
    - Visualización de reseñas en perfil
  ],
  wbs-leaf[
    - Integración con medio de pago seguro
    - Reserva instantánea
    - Transferencia al transportista
  ],
  wbs-leaf[
    - Múltiples envíos en un viaje
    - Optimización de carga
  ],

  // ── Nivel 2 (continuación) ──────────────────────────────────────────────
  wbs-l2[1.2 Login],
  wbs-l2[2.2 Filtrado de Transportistas],
  wbs-l2[3.2 Visualización de Ofertas],
  wbs-l2[4.2 Historial de Envíos],
  wbs-l2[5.2 Integración Fiscal],
  wbs-l2[6.2 Encadenado de Pedidos],

  // ── Nivel 3 ─────────────────────────────────────────────────────────────
  wbs-leaf[
    - Ingreso por email o usuario
    - Validación de credenciales
    - Gestión de sesión
  ],
  wbs-leaf[
    - Filtro por precio
    - Filtro por peso
    - Filtro por volumen / dimensiones
    - Filtro por capacidad del camión
    - Reset de filtros
  ],
  wbs-leaf[
    - Listado de ofertas recibidas
    - Detalle de viaje (distancia, ubicación, volumen, peso)
    - Detalle del cliente (datos personales, reseñas)
  ],
  wbs-leaf[
    - Registro de viajes realizados por transportista
    - Registro de envíos contratados por cliente
  ],
  wbs-leaf[
    - Integración con ARCA
  ],
  wbs-leaf[
    - Encadenar múltiples pedidos en ruta
  ],

  // ── Nivel 2 (continuación) ──────────────────────────────────────────────
  wbs-l2[1.3 Perfil de Usuario],
  wbs-l2[2.3 Detalles de Transportista],
  wbs-l2[3.3 Aceptación de Viaje],
  wbs-l2[4.3 Tracking de Envío],
  wbs-l2[5.3 Integración con Google Maps],
  wbs-l2[6.3 Gestión de Seguros],

  // ── Nivel 3 ─────────────────────────────────────────────────────────────
  wbs-leaf[
    - Edición de datos personales
    - Registro de camión, patente y capacidades
    - Guardar / descartar cambios
  ],
  wbs-leaf[
    - Fotos y descripción del camión
    - Costo estimado del viaje
    - Historial de viajes del transportista
    - Sección de reseñas
  ],
  wbs-leaf[
    - Botón de aceptación de viaje
    - Actualización de fecha estimada de entrega
  ],
  wbs-leaf[
    - Seguimiento en tiempo real del envío
    - Recorrido por GPS
  ],
  wbs-leaf[
    - Geocodificación de direcciones
    - Visualización de rutas
  ],
  wbs-leaf[
    - Venta de seguros de transporte
  ],

  // ── Nivel 2 (continuación) ──────────────────────────────────────────────
  [], wbs-l2[2.4 Oferta de Retiro], wbs-l2[3.4 Realización del Viaje], [], [], wbs-l2[6.4 Verificación de Cuenta],

  // ── Nivel 3 ─────────────────────────────────────────────────────────────
  [],
  wbs-leaf[
    - Indicar fecha de retiro
    - Indicar dirección de retiro
    - Indicar dirección de entrega
    - Confirmar oferta
  ],
  wbs-leaf[
    - Marcar producto como recibido
    - Marcar producto como entregado
    - Notificación de estado al cliente
  ],
  [],
  [],
  wbs-leaf[
    - Verificación de cuenta vía email
  ],

  // ── Nivel 2 (continuación) ──────────────────────────────────────────────
  [], wbs-l2[2.5 Pago del Servicio], [], [], [], [],

  // ── Nivel 3 ─────────────────────────────────────────────────────────────
  [],
  wbs-leaf[
    - Realizar pago tras aceptación
    - Recibir datos de contacto del transportista
  ],
  [],
  [],
  [],
  [],
)

#v(1em)

#text(size: 8pt)[
  _Nota: Los ítems 1–5 corresponden al alcance del MVP (Release 1). El paquete 6 agrupa mejoras planificadas para releases posteriores._
]
