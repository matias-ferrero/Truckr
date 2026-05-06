#import "../template.typ": c-brand, c-brand-mid, conf
#import "@preview/cetz:0.3.4": canvas, draw

#show: conf

#set page(width: 594mm, height: 345mm, margin: (x: 1cm, y: 1.2cm))

= WBS — Work Breakdown Structure

#set text(size: 7.5pt)

#let node-stroke = 1.2pt + c-brand
#let node-fill = luma(245)

// nw/nh: half-widths and half-heights of nodes
#let hw = 1.5  // half node width
#let hh = 0.4  // half node height
#let rhw = 3 // root half-width
#let trunk-offset = 1 // horizontal offset from trunk to branch
#let branch-offset = 2.25 // horizontal offset from parent node to child node

#align(center)[
  #canvas(length: 1cm, {
    import draw: *

    // helper: draw a rect node centered at (cx, cy)
    let node(pos, half-w, half-h, label) = {
      let (cx, cy) = pos
      rect(
        (cx - half-w, cy - half-h),
        (cx + half-w, cy + half-h),
        fill: node-fill,
        stroke: node-stroke,
        radius: 2pt,
      )
      content((cx, cy), label)
    }

    // helper: vertical trunk from the bottom of a node down to the Y level of the last child
    let trunk(p, last-child) = {
      let (px, py) = p
      let (_, last-cy) = last-child
      line(
        (px - trunk-offset, py - hh),
        (px - trunk-offset, last-cy),
        stroke: 0.8pt + c-brand,
      )
    }

    // helper: horizontal arrow from the trunk X to the left edge of a child node
    let branch(trunk-p, child, child-hw) = {
      let (tx, _) = trunk-p
      let (cx, cy) = child
      line(
        (tx - trunk-offset, cy),
        (cx - child-hw, cy),
        mark: (end: ">", fill: c-brand, size: 0.3),
        stroke: 0.8pt + c-brand,
      )
    }

    let branch-x(px) = px + branch-offset - trunk-offset

    // helper: orthogonal arrow (down → horizontal → down)
    // cetz Y increases upward; children have more negative Y (visually below)
    let arrow(p, c) = {
      let (px, py) = p
      let (cx, cy) = c

      let my = (py + cy) / 2
      line(
        (px, py - hh), // bottom of parent
        (px, my),
        (cx, my),
        (cx, cy + hh), // top of child
        mark: (end: ">", fill: c-brand, size: 0.3),
        stroke: 0.8pt + c-brand,
      )
    }

    // ── Nivel 0: Raíz ──────────────────────────────────────────────────────
    let root = (0, 0)
    node(root, rhw, hh, [*Truckr® — Plataforma de Transporte*])

    // Posiciones x de las 9 ramas top-level, equiespaciadas a 6.5cm
    // x: -26, -19.5, -13, -6.5, 0, 6.5, 13, 19.5, 26

    // ── 1. Autenticación y Cuentas ─────────────────────────────────────────
    let cuentas = (-26, -1.8)
    node(cuentas, hw, hh, [1. Autenticación \ y Cuentas])

    let cuentas-bx = branch-x(cuentas.at(0))

    let c-registro = (cuentas-bx, -3.0)
    node(c-registro, hw, hh, [1.1 Registro])

    let c-registro-bx = branch-x(c-registro.at(0))
    let c-reg-form = (c-registro-bx, -4.2)
    node(
      c-reg-form,
      hw,
      hh,
      [1.1.1 Formulario de registro \ (email, nombre, contraseña)],
    )
    let c-reg-pass = (c-registro-bx, -5.4)
    node(c-reg-pass, hw, hh, [1.1.2 Validación de \ contraseña segura])
    let c-reg-dup = (c-registro-bx, -6.6)
    node(c-reg-dup, hw, hh, [1.1.3 Control de \ usuario duplicado])
    let c-reg-email = (c-registro-bx, -7.8)
    node(c-reg-email, hw, hh, [1.1.4 Verificación de \ cuenta por email])

    let c-login = (cuentas-bx, -9.0)
    node(c-login, hw, hh, [1.2 Login])

    let c-login-bx = branch-x(c-login.at(0))
    let c-log-ingreso = (c-login-bx, -10.2)
    node(c-log-ingreso, hw, hh, [1.2.1 Ingreso con email \ o usuario])
    let c-log-cred = (c-login-bx, -11.4)
    node(c-log-cred, hw, hh, [1.2.2 Validación de \ credenciales])
    let c-log-sesion = (c-login-bx, -12.6)
    node(c-log-sesion, hw, hh, [1.2.3 Gestión de sesión])
    let c-log-cambio = (c-login-bx, -13.8)
    node(c-log-cambio, hw, hh, [1.2.4 Cambiar contraseña])

    let c-perfil = (cuentas-bx, -15.0)
    node(c-perfil, hw, hh, [1.3 Perfil de Usuario])

    let c-perfil-bx = branch-x(c-perfil.at(0))
    let c-per-edicion = (c-perfil-bx, -16.2)
    node(c-per-edicion, hw, hh, [1.3.1 Edición de datos \ personales])
    let c-per-foto = (c-perfil-bx, -17.4)
    node(c-per-foto, hw, hh, [1.3.2 Actualización de \ foto de perfil])
    let c-per-historial = (c-perfil-bx, -18.6)
    node(c-per-historial, hw, hh, [1.3.3 Historial de viajes])

    let c-vehiculo = (cuentas-bx, -19.8)
    node(c-vehiculo, hw, hh, [1.4 Registro de Vehículo])

    let c-vehiculo-bx = branch-x(c-vehiculo.at(0))
    let c-veh-patente = (c-vehiculo-bx, -21.0)
    node(c-veh-patente, hw, hh, [1.4.1 Registrar patente])
    let c-veh-dim = (c-vehiculo-bx, -22.2)
    node(
      c-veh-dim,
      hw,
      hh,
      [1.4.2 Registrar dimensiones \ y capacidad de carga],
    )
    let c-veh-fotos = (c-vehiculo-bx, -23.4)
    node(c-veh-fotos, hw, hh, [1.4.3 Subir fotos \ del vehículo])

    trunk(cuentas, c-vehiculo)
    branch(cuentas, c-registro, hw)
    branch(cuentas, c-login, hw)
    branch(cuentas, c-perfil, hw)
    branch(cuentas, c-vehiculo, hw)

    trunk(c-registro, c-reg-email)
    branch(c-registro, c-reg-form, hw)
    branch(c-registro, c-reg-pass, hw)
    branch(c-registro, c-reg-dup, hw)
    branch(c-registro, c-reg-email, hw)

    trunk(c-login, c-log-cambio)
    branch(c-login, c-log-ingreso, hw)
    branch(c-login, c-log-cred, hw)
    branch(c-login, c-log-sesion, hw)
    branch(c-login, c-log-cambio, hw)

    trunk(c-perfil, c-per-historial)
    branch(c-perfil, c-per-edicion, hw)
    branch(c-perfil, c-per-foto, hw)
    branch(c-perfil, c-per-historial, hw)

    trunk(c-vehiculo, c-veh-fotos)
    branch(c-vehiculo, c-veh-patente, hw)
    branch(c-vehiculo, c-veh-dim, hw)
    branch(c-vehiculo, c-veh-fotos, hw)

    // ── 2. Búsqueda y Descubrimiento ───────────────────────────────────────
    let busqueda = (-19.5, -1.8)
    node(busqueda, hw, hh, [2. Búsqueda y \ Descubrimiento])

    let busqueda-bx = branch-x(busqueda.at(0))

    let b-busq = (busqueda-bx, -3.0)
    node(b-busq, hw, hh, [2.1 Búsqueda de \ Transportistas])

    let b-busq-bx = branch-x(b-busq.at(0))
    let b-busq-origen = (b-busq-bx, -4.2)
    node(b-busq-origen, hw, hh, [2.1.1 Ingresar ubicación \ origen])
    let b-busq-destino = (b-busq-bx, -5.4)
    node(b-busq-destino, hw, hh, [2.1.2 Ingresar ubicación \ destino])
    let b-busq-fecha = (b-busq-bx, -6.6)
    node(b-busq-fecha, hw, hh, [2.1.3 Ingresar rango \ de fechas])
    let b-busq-scroll = (b-busq-bx, -7.8)
    node(b-busq-scroll, hw, hh, [2.1.4 Listado paginado \ y scrolleable])
    let b-busq-orden = (b-busq-bx, -9.0)
    node(b-busq-orden, hw, hh, [2.1.5 Ordenamiento \ de resultados])

    let b-filtros = (busqueda-bx, -10.2)
    node(b-filtros, hw, hh, [2.2 Filtrado de \ Transportistas])

    let b-filtros-bx = branch-x(b-filtros.at(0))
    let b-fil-precio = (b-filtros-bx, -11.4)
    node(b-fil-precio, hw, hh, [2.2.1 Filtro por precio/km])
    let b-fil-peso = (b-filtros-bx, -12.6)
    node(b-fil-peso, hw, hh, [2.2.2 Filtro por peso])
    let b-fil-vol = (b-filtros-bx, -13.8)
    node(b-fil-vol, hw, hh, [2.2.3 Filtro por volumen])
    let b-fil-dim = (b-filtros-bx, -15.0)
    node(b-fil-dim, hw, hh, [2.2.4 Filtro por \ dimensiones])
    let b-fil-cap = (b-filtros-bx, -16.2)
    node(b-fil-cap, hw, hh, [2.2.5 Filtro por \ capacidad del camión])
    let b-fil-dist = (b-filtros-bx, -17.4)
    node(b-fil-dist, hw, hh, [2.2.6 Filtro por distancia])
    let b-fil-reset = (b-filtros-bx, -18.6)
    node(b-fil-reset, hw, hh, [2.2.7 Reset de filtros])

    let b-detalles = (busqueda-bx, -19.8)
    node(b-detalles, hw, hh, [2.3 Detalles del \ Transportista])

    let b-det-bx = branch-x(b-detalles.at(0))
    let b-det-fotos = (b-det-bx, -21.0)
    node(b-det-fotos, hw, hh, [2.3.1 Ver fotos y \ descripción del camión])
    let b-det-precio = (b-det-bx, -22.2)
    node(b-det-precio, hw, hh, [2.3.2 Ver estimación \ de costo del viaje])
    let b-det-hist = (b-det-bx, -23.4)
    node(
      b-det-hist,
      hw,
      hh,
      [2.3.3 Ver historial de \ viajes del transportista],
    )
    let b-det-rese = (b-det-bx, -24.6)
    node(b-det-rese, hw, hh, [2.3.4 Ver reseñas \ del transportista])

    trunk(busqueda, b-detalles)
    branch(busqueda, b-busq, hw)
    branch(busqueda, b-filtros, hw)
    branch(busqueda, b-detalles, hw)

    trunk(b-busq, b-busq-orden)
    branch(b-busq, b-busq-origen, hw)
    branch(b-busq, b-busq-destino, hw)
    branch(b-busq, b-busq-fecha, hw)
    branch(b-busq, b-busq-scroll, hw)
    branch(b-busq, b-busq-orden, hw)

    trunk(b-filtros, b-fil-reset)
    branch(b-filtros, b-fil-precio, hw)
    branch(b-filtros, b-fil-peso, hw)
    branch(b-filtros, b-fil-vol, hw)
    branch(b-filtros, b-fil-dim, hw)
    branch(b-filtros, b-fil-cap, hw)
    branch(b-filtros, b-fil-dist, hw)
    branch(b-filtros, b-fil-reset, hw)

    trunk(b-detalles, b-det-rese)
    branch(b-detalles, b-det-fotos, hw)
    branch(b-detalles, b-det-precio, hw)
    branch(b-detalles, b-det-hist, hw)
    branch(b-detalles, b-det-rese, hw)

    // ── 3. Reservas y Ofertas ──────────────────────────────────────────────
    let reservas = (-13, -1.8)
    node(reservas, hw, hh, [3. Reservas y Ofertas])

    let reservas-bx = branch-x(reservas.at(0))

    let r-oferta = (reservas-bx, -3.0)
    node(r-oferta, hw, hh, [3.1 Oferta de Retiro \ (Cliente)])

    let r-oferta-bx = branch-x(r-oferta.at(0))
    let r-of-fecha = (r-oferta-bx, -4.2)
    node(r-of-fecha, hw, hh, [3.1.1 Seleccionar \ fecha de retiro])
    let r-of-retiro = (r-oferta-bx, -5.4)
    node(r-of-retiro, hw, hh, [3.1.2 Ingresar dirección \ de retiro])
    let r-of-entrega = (r-oferta-bx, -6.6)
    node(r-of-entrega, hw, hh, [3.1.3 Ingresar dirección \ de entrega])
    let r-of-confirmar = (r-oferta-bx, -7.8)
    node(r-of-confirmar, hw, hh, [3.1.4 Confirmar oferta])

    let r-disponibilidad = (reservas-bx, -9.0)
    node(
      r-disponibilidad,
      hw,
      hh,
      [3.2 Publicación de \ Disponibilidad],
    )

    let r-disp-bx = branch-x(r-disponibilidad.at(0))
    let r-disp-zona = (r-disp-bx, -10.2)
    node(r-disp-zona, hw, hh, [3.2.1 Indicar zona \ de origen])
    let r-disp-km = (r-disp-bx, -11.4)
    node(r-disp-km, hw, hh, [3.2.2 Indicar límite \ de kilómetros])
    let r-disp-precio = (r-disp-bx, -12.6)
    node(r-disp-precio, hw, hh, [3.2.3 Indicar precio \ por km])
    let r-disp-pub = (r-disp-bx, -13.8)
    node(r-disp-pub, hw, hh, [3.2.4 Confirmar publicación])

    let r-vis-ofertas = (reservas-bx, -15.0)
    node(
      r-vis-ofertas,
      hw,
      hh,
      [3.3 Visualización de \ Ofertas],
    )

    let r-vis-bx = branch-x(r-vis-ofertas.at(0))
    let r-vis-listado = (r-vis-bx, -16.2)
    node(r-vis-listado, hw, hh, [3.3.1 Listado de \ ofertas recibidas])
    let r-vis-det-viaje = (r-vis-bx, -17.4)
    node(
      r-vis-det-viaje,
      hw,
      hh,
      [3.3.2 Detalle de viaje \ (distancia, volumen, peso)],
    )
    let r-vis-det-cliente = (r-vis-bx, -18.6)
    node(
      r-vis-det-cliente,
      hw,
      hh,
      [3.3.3 Detalle del cliente \ (datos personales, reseñas)],
    )
    let r-vis-hist-cliente = (r-vis-bx, -19.8)
    node(r-vis-hist-cliente, hw, hh, [3.3.4 Historial del cliente])

    let r-filtros = (reservas-bx, -21.0)
    node(r-filtros, hw, hh, [3.4 Filtros de Ofertas])

    let r-fil-bx = branch-x(r-filtros.at(0))
    let r-fil-origen = (r-fil-bx, -22.2)
    node(r-fil-origen, hw, hh, [3.4.1 Filtrar por \ ubicación origen])
    let r-fil-fecha = (r-fil-bx, -23.4)
    node(r-fil-fecha, hw, hh, [3.4.2 Filtrar por \ rango de fecha])
    let r-fil-peso = (r-fil-bx, -24.6)
    node(r-fil-peso, hw, hh, [3.4.3 Filtrar por peso])
    let r-fil-vol = (r-fil-bx, -25.8)
    node(r-fil-vol, hw, hh, [3.4.4 Filtrar por volumen])
    let r-fil-destino = (r-fil-bx, -27.0)
    node(r-fil-destino, hw, hh, [3.4.5 Filtrar por \ ubicación destino])

    let r-aceptacion = (reservas-bx, -28.2)
    node(r-aceptacion, hw, hh, [3.5 Aceptación de Viaje])

    let r-acep-bx = branch-x(r-aceptacion.at(0))
    let r-acep-boton = (r-acep-bx, -29.4)
    node(r-acep-boton, hw, hh, [3.5.1 Aceptar viaje])
    let r-acep-fecha = (r-acep-bx, -30.6)
    node(
      r-acep-fecha,
      hw,
      hh,
      [3.5.2 Actualización de fecha \ estimada de entrega],
    )

    trunk(reservas, r-aceptacion)
    branch(reservas, r-oferta, hw)
    branch(reservas, r-disponibilidad, hw)
    branch(reservas, r-vis-ofertas, hw)
    branch(reservas, r-filtros, hw)
    branch(reservas, r-aceptacion, hw)

    trunk(r-oferta, r-of-confirmar)
    branch(r-oferta, r-of-fecha, hw)
    branch(r-oferta, r-of-retiro, hw)
    branch(r-oferta, r-of-entrega, hw)
    branch(r-oferta, r-of-confirmar, hw)

    trunk(r-disponibilidad, r-disp-pub)
    branch(r-disponibilidad, r-disp-zona, hw)
    branch(r-disponibilidad, r-disp-km, hw)
    branch(r-disponibilidad, r-disp-precio, hw)
    branch(r-disponibilidad, r-disp-pub, hw)

    trunk(r-vis-ofertas, r-vis-hist-cliente)
    branch(r-vis-ofertas, r-vis-listado, hw)
    branch(r-vis-ofertas, r-vis-det-viaje, hw)
    branch(r-vis-ofertas, r-vis-det-cliente, hw)
    branch(r-vis-ofertas, r-vis-hist-cliente, hw)

    trunk(r-filtros, r-fil-destino)
    branch(r-filtros, r-fil-origen, hw)
    branch(r-filtros, r-fil-fecha, hw)
    branch(r-filtros, r-fil-peso, hw)
    branch(r-filtros, r-fil-vol, hw)
    branch(r-filtros, r-fil-destino, hw)

    trunk(r-aceptacion, r-acep-fecha)
    branch(r-aceptacion, r-acep-boton, hw)
    branch(r-aceptacion, r-acep-fecha, hw)

    // ── 4. Ejecución de Viajes ─────────────────────────────────────────────
    let ejecucion = (-6.5, -1.8)
    node(ejecucion, hw, hh, [4. Ejecución \ de Viajes])

    let ejecucion-bx = branch-x(ejecucion.at(0))

    let e-estados = (ejecucion-bx, -3.0)
    node(e-estados, hw, hh, [4.1 Estados del Viaje])

    let e-estados-bx = branch-x(e-estados.at(0))
    let e-est-retirado = (e-estados-bx, -4.2)
    node(e-est-retirado, hw, hh, [4.1.1 Confirmar producto \ retirado])
    let e-est-entregado = (e-estados-bx, -5.4)
    node(e-est-entregado, hw, hh, [4.1.2 Confirmar producto \ entregado])

    let e-notif = (ejecucion-bx, -6.6)
    node(e-notif, hw, hh, [4.2 Notificaciones \ al Cliente])

    let e-notif-bx = branch-x(e-notif.at(0))
    let e-notif-retiro = (e-notif-bx, -7.8)
    node(e-notif-retiro, hw, hh, [4.2.1 Notificación de \ producto retirado])
    let e-notif-entrega = (e-notif-bx, -9.0)
    node(e-notif-entrega, hw, hh, [4.2.2 Notificación de \ producto entregado])

    let e-tracking = (ejecucion-bx, -10.2)
    node(e-tracking, hw, hh, [4.3 Tracking GPS])

    let e-tracking-bx = branch-x(e-tracking.at(0))
    let e-track-maps = (e-tracking-bx, -11.4)
    node(e-track-maps, hw, hh, [4.3.1 Integración con \ Google Maps])
    let e-track-recorrido = (e-tracking-bx, -12.6)
    node(e-track-recorrido, hw, hh, [4.3.2 Ver recorrido \ en tiempo real])
    let e-track-destino = (e-tracking-bx, -13.8)
    node(e-track-destino, hw, hh, [4.3.3 Ver siguiente \ destino])

    let e-avanzados = (ejecucion-bx, -15.0)
    node(e-avanzados, hw, hh, [4.4 Viajes Avanzados])

    let e-avanz-bx = branch-x(e-avanzados.at(0))
    let e-avanz-comp = (e-avanz-bx, -16.2)
    node(e-avanz-comp, hw, hh, [4.4.1 Viajes compuestos \ (múltiples envíos)])
    let e-avanz-cadena = (e-avanz-bx, -17.4)
    node(e-avanz-cadena, hw, hh, [4.4.2 Encadenado \ de pedidos])

    trunk(ejecucion, e-avanzados)
    branch(ejecucion, e-estados, hw)
    branch(ejecucion, e-notif, hw)
    branch(ejecucion, e-tracking, hw)
    branch(ejecucion, e-avanzados, hw)

    trunk(e-estados, e-est-entregado)
    branch(e-estados, e-est-retirado, hw)
    branch(e-estados, e-est-entregado, hw)

    trunk(e-notif, e-notif-entrega)
    branch(e-notif, e-notif-retiro, hw)
    branch(e-notif, e-notif-entrega, hw)

    trunk(e-tracking, e-track-destino)
    branch(e-tracking, e-track-maps, hw)
    branch(e-tracking, e-track-recorrido, hw)
    branch(e-tracking, e-track-destino, hw)

    trunk(e-avanzados, e-avanz-cadena)
    branch(e-avanzados, e-avanz-comp, hw)
    branch(e-avanzados, e-avanz-cadena, hw)

    // ── 5. Pagos ───────────────────────────────────────────────────────────
    let pagos = (0, -1.8)
    node(pagos, hw, hh, [5. Pagos])

    let pagos-bx = branch-x(pagos.at(0))

    let p-cliente = (pagos-bx, -3.0)
    node(p-cliente, hw, hh, [5.1 Pago del Cliente])

    let p-cliente-bx = branch-x(p-cliente.at(0))
    let p-cli-reserva = (p-cliente-bx, -4.2)
    node(
      p-cli-reserva,
      hw,
      hh,
      [5.1.1 Realizar pago \ tras aceptación del viaje],
    )
    let p-cli-contacto = (p-cliente-bx, -5.4)
    node(
      p-cli-contacto,
      hw,
      hh,
      [5.1.2 Recibir datos de \ contacto del transportista],
    )

    let p-transportista = (pagos-bx, -6.6)
    node(p-transportista, hw, hh, [5.2 Pago al Transportista])

    let p-transp-bx = branch-x(p-transportista.at(0))
    let p-transp-liquidacion = (p-transp-bx, -7.8)
    node(
      p-transp-liquidacion,
      hw,
      hh,
      [5.2.1 Liquidación al \ transportista tras entrega],
    )
    let p-transp-historial = (p-transp-bx, -9.0)
    node(p-transp-historial, hw, hh, [5.2.2 Historial de cobros])

    let p-pasarela = (pagos-bx, -10.2)
    node(p-pasarela, hw, hh, [5.3 Pasarela de Pago])

    let p-pas-bx = branch-x(p-pasarela.at(0))
    let p-pas-mp = (p-pas-bx, -11.4)
    node(p-pas-mp, hw, hh, [5.3.1 Integración \ Mercado Pago])
    let p-pas-seguro = (p-pas-bx, -12.6)
    node(p-pas-seguro, hw, hh, [5.3.2 Procesamiento \ seguro de pagos])
    let p-pas-reembolso = (p-pas-bx, -13.8)
    node(p-pas-reembolso, hw, hh, [5.3.3 Gestión de \ reembolsos])

    trunk(pagos, p-pasarela)
    branch(pagos, p-cliente, hw)
    branch(pagos, p-transportista, hw)
    branch(pagos, p-pasarela, hw)

    trunk(p-cliente, p-cli-contacto)
    branch(p-cliente, p-cli-reserva, hw)
    branch(p-cliente, p-cli-contacto, hw)

    trunk(p-transportista, p-transp-historial)
    branch(p-transportista, p-transp-liquidacion, hw)
    branch(p-transportista, p-transp-historial, hw)

    trunk(p-pasarela, p-pas-reembolso)
    branch(p-pasarela, p-pas-mp, hw)
    branch(p-pasarela, p-pas-seguro, hw)
    branch(p-pasarela, p-pas-reembolso, hw)

    // ── 6. Seguros ─────────────────────────────────────────────────────────
    let seguros = (6.5, -1.8)
    node(seguros, hw, hh, [6. Seguros])

    let seguros-bx = branch-x(seguros.at(0))

    let s-integracion = (seguros-bx, -3.0)
    node(s-integracion, hw, hh, [6.1 Integración con \ Aseguradora])

    let s-int-bx = branch-x(s-integracion.at(0))
    let s-int-api = (s-int-bx, -4.2)
    node(s-int-api, hw, hh, [6.1.1 Integración con \ API de aseguradora])
    let s-int-coberturas = (s-int-bx, -5.4)
    node(
      s-int-coberturas,
      hw,
      hh,
      [6.1.2 Obtención de \ coberturas disponibles],
    )

    let s-cotizacion = (seguros-bx, -6.6)
    node(s-cotizacion, hw, hh, [6.2 Cotización del Seguro])

    let s-cot-bx = branch-x(s-cotizacion.at(0))
    let s-cot-valor = (s-cot-bx, -7.8)
    node(s-cot-valor, hw, hh, [6.2.1 Cálculo por \ valor declarado])
    let s-cot-dist = (s-cot-bx, -9.0)
    node(s-cot-dist, hw, hh, [6.2.2 Cálculo por \ distancia del viaje])
    let s-cot-vis = (s-cot-bx, -10.2)
    node(s-cot-vis, hw, hh, [6.2.3 Visualización del \ costo al cliente])

    let s-contratacion = (seguros-bx, -11.4)
    node(s-contratacion, hw, hh, [6.3 Contratación del Seguro])

    let s-cont-bx = branch-x(s-contratacion.at(0))
    let s-cont-seleccion = (s-cont-bx, -12.6)
    node(s-cont-seleccion, hw, hh, [6.3.1 Selección de cobertura])
    let s-cont-pago = (s-cont-bx, -13.8)
    node(s-cont-pago, hw, hh, [6.3.2 Pago integrado \ al flujo de compra])
    let s-cont-emision = (s-cont-bx, -15.0)
    node(s-cont-emision, hw, hh, [6.3.3 Emisión y envío \ de póliza])

    let s-polizas = (seguros-bx, -16.2)
    node(s-polizas, hw, hh, [6.4 Gestión de Pólizas])

    let s-pol-bx = branch-x(s-polizas.at(0))
    let s-pol-historial = (s-pol-bx, -17.4)
    node(s-pol-historial, hw, hh, [6.4.1 Historial de \ seguros contratados])
    let s-pol-descarga = (s-pol-bx, -18.6)
    node(s-pol-descarga, hw, hh, [6.4.2 Descarga de póliza])

    let s-siniestros = (seguros-bx, -19.8)
    node(s-siniestros, hw, hh, [6.5 Gestión de Siniestros])

    let s-sin-bx = branch-x(s-siniestros.at(0))
    let s-sin-declaracion = (s-sin-bx, -21.0)
    node(s-sin-declaracion, hw, hh, [6.5.1 Declaración \ de siniestro])
    let s-sin-seguimiento = (s-sin-bx, -22.2)
    node(s-sin-seguimiento, hw, hh, [6.5.2 Seguimiento \ del siniestro])

    trunk(seguros, s-siniestros)
    branch(seguros, s-integracion, hw)
    branch(seguros, s-cotizacion, hw)
    branch(seguros, s-contratacion, hw)
    branch(seguros, s-polizas, hw)
    branch(seguros, s-siniestros, hw)

    trunk(s-integracion, s-int-coberturas)
    branch(s-integracion, s-int-api, hw)
    branch(s-integracion, s-int-coberturas, hw)

    trunk(s-cotizacion, s-cot-vis)
    branch(s-cotizacion, s-cot-valor, hw)
    branch(s-cotizacion, s-cot-dist, hw)
    branch(s-cotizacion, s-cot-vis, hw)

    trunk(s-contratacion, s-cont-emision)
    branch(s-contratacion, s-cont-seleccion, hw)
    branch(s-contratacion, s-cont-pago, hw)
    branch(s-contratacion, s-cont-emision, hw)

    trunk(s-polizas, s-pol-descarga)
    branch(s-polizas, s-pol-historial, hw)
    branch(s-polizas, s-pol-descarga, hw)

    trunk(s-siniestros, s-sin-seguimiento)
    branch(s-siniestros, s-sin-declaracion, hw)
    branch(s-siniestros, s-sin-seguimiento, hw)

    // ── 7. Reseñas y Calificaciones ────────────────────────────────────────
    let resenias = (13, -1.8)
    node(resenias, hw, hh, [7. Reseñas y \ Calificaciones])

    let resenias-bx = branch-x(resenias.at(0))

    let re-crear = (resenias-bx, -3.0)
    node(re-crear, hw, hh, [7.1 Crear Reseña])

    let re-crear-bx = branch-x(re-crear.at(0))
    let re-cre-texto = (re-crear-bx, -4.2)
    node(re-cre-texto, hw, hh, [7.1.1 Redactar texto \ de la reseña])
    let re-cre-puntaje = (re-crear-bx, -5.4)
    node(re-cre-puntaje, hw, hh, [7.1.2 Asignar puntaje])
    let re-cre-enviar = (re-crear-bx, -6.6)
    node(re-cre-enviar, hw, hh, [7.1.3 Enviar reseña \ al transportista])

    let re-leer = (resenias-bx, -7.8)
    node(re-leer, hw, hh, [7.2 Leer Reseñas])

    let re-leer-bx = branch-x(re-leer.at(0))
    let re-lee-listado = (re-leer-bx, -9.0)
    node(re-lee-listado, hw, hh, [7.2.1 Listado de reseñas \ del transportista])
    let re-lee-promedio = (re-leer-bx, -10.2)
    node(re-lee-promedio, hw, hh, [7.2.2 Puntaje promedio])

    let re-gestionar = (resenias-bx, -11.4)
    node(re-gestionar, hw, hh, [7.3 Gestión de Reseñas])

    let re-gest-bx = branch-x(re-gestionar.at(0))
    let re-gest-editar = (re-gest-bx, -12.6)
    node(re-gest-editar, hw, hh, [7.3.1 Editar reseña \ propia])
    let re-gest-eliminar = (re-gest-bx, -13.8)
    node(re-gest-eliminar, hw, hh, [7.3.2 Eliminar reseña \ propia])

    trunk(resenias, re-gestionar)
    branch(resenias, re-crear, hw)
    branch(resenias, re-leer, hw)
    branch(resenias, re-gestionar, hw)

    trunk(re-crear, re-cre-enviar)
    branch(re-crear, re-cre-texto, hw)
    branch(re-crear, re-cre-puntaje, hw)
    branch(re-crear, re-cre-enviar, hw)

    trunk(re-leer, re-lee-promedio)
    branch(re-leer, re-lee-listado, hw)
    branch(re-leer, re-lee-promedio, hw)

    trunk(re-gestionar, re-gest-eliminar)
    branch(re-gestionar, re-gest-editar, hw)
    branch(re-gestionar, re-gest-eliminar, hw)

    // ── 8. Integraciones Externas ──────────────────────────────────────────
    let integraciones = (19.5, -1.8)
    node(integraciones, hw, hh, [8. Integraciones \ Externas])

    let int-bx = branch-x(integraciones.at(0))

    let i-arca = (int-bx, -3.0)
    node(i-arca, hw, hh, [8.1 ARCA])

    let i-arca-bx = branch-x(i-arca.at(0))
    let i-arc-api = (i-arca-bx, -4.2)
    node(i-arc-api, hw, hh, [8.1.1 Integración con \ API de ARCA])
    let i-arc-validacion = (i-arca-bx, -5.4)
    node(i-arc-validacion, hw, hh, [8.1.2 Validación \ fiscal de usuarios])

    let i-mp = (int-bx, -6.6)
    node(i-mp, hw, hh, [8.2 Mercado Pago])

    let i-mp-bx = branch-x(i-mp.at(0))
    let i-mp-api = (i-mp-bx, -7.8)
    node(i-mp-api, hw, hh, [8.2.1 Integración con \ API de Mercado Pago])
    let i-mp-webhook = (i-mp-bx, -9.0)
    node(i-mp-webhook, hw, hh, [8.2.2 Webhooks de \ confirmación de pago])

    let i-maps = (int-bx, -10.2)
    node(i-maps, hw, hh, [8.3 Google Maps])

    let i-maps-bx = branch-x(i-maps.at(0))
    let i-map-geo = (i-maps-bx, -11.4)
    node(i-map-geo, hw, hh, [8.3.1 Geocodificación \ de direcciones])
    let i-map-rutas = (i-maps-bx, -12.6)
    node(i-map-rutas, hw, hh, [8.3.2 Visualización \ de rutas])
    let i-map-dist = (i-maps-bx, -13.8)
    node(i-map-dist, hw, hh, [8.3.3 Cálculo de \ distancias])

    let i-aseg = (int-bx, -15.0)
    node(i-aseg, hw, hh, [8.4 API Aseguradora])

    let i-aseg-bx = branch-x(i-aseg.at(0))
    let i-aseg-coberturas = (i-aseg-bx, -16.2)
    node(i-aseg-coberturas, hw, hh, [8.4.1 Consulta de \ coberturas])
    let i-aseg-emision = (i-aseg-bx, -17.4)
    node(i-aseg-emision, hw, hh, [8.4.2 Emisión de póliza])
    let i-aseg-siniestro = (i-aseg-bx, -18.6)
    node(i-aseg-siniestro, hw, hh, [8.4.3 Notificación \ de siniestros])

    trunk(integraciones, i-aseg)
    branch(integraciones, i-arca, hw)
    branch(integraciones, i-mp, hw)
    branch(integraciones, i-maps, hw)
    branch(integraciones, i-aseg, hw)

    trunk(i-arca, i-arc-validacion)
    branch(i-arca, i-arc-api, hw)
    branch(i-arca, i-arc-validacion, hw)

    trunk(i-mp, i-mp-webhook)
    branch(i-mp, i-mp-api, hw)
    branch(i-mp, i-mp-webhook, hw)

    trunk(i-maps, i-map-dist)
    branch(i-maps, i-map-geo, hw)
    branch(i-maps, i-map-rutas, hw)
    branch(i-maps, i-map-dist, hw)

    trunk(i-aseg, i-aseg-siniestro)
    branch(i-aseg, i-aseg-coberturas, hw)
    branch(i-aseg, i-aseg-emision, hw)
    branch(i-aseg, i-aseg-siniestro, hw)

    // ── 9. Gestión del Proyecto ────────────────────────────────────────────
    let proyecto = (26, -1.8)
    node(proyecto, hw, hh, [9. Gestión del Proyecto])

    let proyecto-bx = branch-x(proyecto.at(0))

    let proy-artefactos = (proyecto-bx, -3.0)
    node(proy-artefactos, hw, hh, [9.1 Artefactos])

    let proy-art-bx = branch-x(proy-artefactos.at(0))
    let proy-lean = (proy-art-bx, -4.2)
    node(proy-lean, hw, hh, [9.1.1 Artefactos Lean])
    let proy-backlog = (proy-art-bx, -5.4)
    node(proy-backlog, hw, hh, [9.1.2 Product Backlog])
    let proy-usm = (proy-art-bx, -6.6)
    node(proy-usm, hw, hh, [9.1.3 User Story Map])
    let proy-wbs = (proy-art-bx, -7.8)
    node(proy-wbs, hw, hh, [9.1.4 Work Breakdown \ Structure])
    let proy-cron = (proy-art-bx, -9.0)
    node(proy-cron, hw, hh, [9.1.5 Cronograma])
    let proy-costos = (proy-art-bx, -10.2)
    node(proy-costos, hw, hh, [9.1.6 Planilla de Costos])
    let proy-com = (proy-art-bx, -11.4)
    node(proy-com, hw, hh, [9.1.7 Plan de \ Comunicación])

    trunk(proyecto, proy-artefactos)
    branch(proyecto, proy-artefactos, hw)

    trunk(proy-artefactos, proy-com)
    branch(proy-artefactos, proy-lean, hw)
    branch(proy-artefactos, proy-backlog, hw)
    branch(proy-artefactos, proy-usm, hw)
    branch(proy-artefactos, proy-wbs, hw)
    branch(proy-artefactos, proy-cron, hw)
    branch(proy-artefactos, proy-costos, hw)
    branch(proy-artefactos, proy-com, hw)

    // ── Aristas raíz → nivel 1 ─────────────────────────────────────────────
    arrow(root, cuentas)
    arrow(root, busqueda)
    arrow(root, reservas)
    arrow(root, ejecucion)
    arrow(root, pagos)
    arrow(root, seguros)
    arrow(root, resenias)
    arrow(root, integraciones)
    arrow(root, proyecto)
  })
]
