#import "../template.typ": c-brand, c-brand-mid, conf
#import "@preview/cetz:0.3.4": canvas, draw

#show: conf

#set page(width: 356mm, height: 630mm, margin: (x: 1cm, y: 1.2cm))

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
        (px, py - hh),   // bottom of parent
        (px, my),
        (cx, my),
        (cx, cy + hh),   // top of child
        mark: (end: ">", fill: c-brand, size: 0.3),
        stroke: 0.8pt + c-brand,
      )
    }

    // ── Nivel 0: Raíz ──────────────────────────────────────────────────────
    let root = (0, 0)
    node(root, rhw, hh, [*Truckr® — Plataforma de Transporte*])

    // ── 1. Gestión de Cuentas ──────────────────────────────────────────────
    let gestion = (-14, -1.8)
    node(gestion, hw, hh, [1. Gestión de Cuentas])

    let gestion-branch-x = branch-x(gestion.at(0))
    let registro = (gestion-branch-x, -3.0)
    node(registro, hw, hh, [1.1 Registro])

    let registro-branch-x = branch-x(registro.at(0))
    let formulario = (registro-branch-x, -4.6)
    node(formulario, hw, 2 * hh, [1.1.1 Formulario de \ Registro (email, \ nombre, contraseña)])
    let validacion-contra = (registro-branch-x, -6.2)
    node(validacion-contra, hw, hh, [1.1.2 Validación de \ contraseña segura])
    let control = (registro-branch-x, -7.4)
    node(control, hw, hh, [1.1.3 Control de \ usuario duplicado])

    let login = (gestion-branch-x, -8.6)
    node(login, hw, hh, [1.2 Login])

    let login-branch-x = branch-x(login.at(0))
    let ingreso = (login-branch-x, -9.8)
    node(ingreso, hw, hh, [1.2.1 Ingreso con \ email y contraseña])
    let validacion-cred = (login-branch-x, -11)
    node(validacion-cred, hw, hh, [1.2.2 Validación de \ credenciales])
    let sesion = (login-branch-x, -12.2)
    node(sesion, hw, hh, [1.2.3 Gestión de sesión])

    let perfil = (gestion-branch-x, -13.4)
    node(perfil, hw, hh, [1.3 Perfil de Usuario])

    let perfil-branch-x = branch-x(perfil.at(0))
    let edicion = (perfil-branch-x, -14.6)
    node(edicion, hw, hh, [1.3.1 Edición de datos \ personales])
    let foto = (perfil-branch-x, -15.8)
    node(foto, hw, hh, [1.3.2 Actualización de \ foto de perfil])
    let camion = (perfil-branch-x, -17.4)
    node(camion, hw, 2 * hh, [1.3.3 Registro de \ camión, patente \ y dimensiones])

    trunk(gestion, perfil)
    branch(gestion, registro, hw)
    branch(gestion, login, hw)
    branch(gestion, perfil, hw)

    trunk(registro, control)
    branch(registro, formulario, hw)
    branch(registro, validacion-contra, hw)
    branch(registro, control, hw)

    trunk(login, sesion)
    branch(login, ingreso, hw)
    branch(login, validacion-cred, hw)
    branch(login, sesion, hw)

    trunk(perfil, camion)
    branch(perfil, edicion, hw)
    branch(perfil, foto, hw)
    branch(perfil, camion, hw)

    // ── 2. Plataformas ──────────────────────────────────────────────
    let plataformas = (-7.5, -1.8)
    node(plataformas, hw, hh, [2. Plataformas])

    let plataformas-branch-x = branch-x(plataformas.at(0))
    let plataforma-cliente = (plataformas-branch-x, -3.0)
    node(plataforma-cliente, hw, hh, [2.1 Plataforma Cliente])

    let plataforma-cliente-branch-x = branch-x(plataforma-cliente.at(0))
    let busqueda = (plataforma-cliente-branch-x, -4.2)
    node(busqueda, hw, hh, [2.1.1 Búsqueda de \ Transportistas])

    let busqueda-branch-x = branch-x(busqueda.at(0))
    let origen-destino = (busqueda-branch-x, -5.4)
    node(origen-destino, hw, hh, [2.1.1.1 Búsqueda por \ origen y destino])
    let fecha = (busqueda-branch-x, -6.6)
    node(fecha, hw, hh, [2.1.1.2 Búsqueda por \ rango de fecha])
    let listado = (busqueda-branch-x, -7.8)
    node(listado, hw, hh, [2.1.1.3 Listado paginado \ y scrolleable])
    let ordenamiento = (busqueda-branch-x, -9)
    node(ordenamiento, hw, hh, [2.1.1.4 Ordenamiento])

    let filtrado = (plataforma-cliente-branch-x, -10.2)
    node(filtrado, hw, hh, [2.1.2 Filtrado de \ Transportistas])

    let filtrado-branch-x = branch-x(filtrado.at(0))
    let precio = (filtrado-branch-x, -11.4)
    node(precio, hw, hh, [2.1.2.1 Filtro por precio])
    let peso = (filtrado-branch-x, -12.6)
    node(peso, hw, hh, [2.1.2.2 Filtro por peso])
    let dimensiones = (filtrado-branch-x, -13.8)
    node(dimensiones, hw, hh, [2.1.2.3 Filtro por \ dimensiones])
    let capacidad = (filtrado-branch-x, -15)
    node(capacidad, hw, hh, [2.1.2.4 Filtro por \ capacidad del camión])
    let reset = (filtrado-branch-x, -16.2)
    node(reset, hw, hh, [2.1.2.5 Reset de filtros])

    let detalles = (plataforma-cliente-branch-x, -17.4)
    node(detalles, hw, hh, [2.1.3 Detalles del \ Transportista])

    let detalles-branch-x = branch-x(detalles.at(0))
    let fotos-camion = (detalles-branch-x, -18.6)
    node(fotos-camion, hw, hh, [2.1.3.1 Fotos y descripción \ del camión])
    let estimacion = (detalles-branch-x, -19.8)
    node(estimacion, hw, hh, [2.1.3.2 Estimación de \ costos del viaje])
    let historial = (detalles-branch-x, -21)
    node(historial, hw, hh, [2.1.3.3 Historial de \ viajes del transportista])
    let resenias = (detalles-branch-x, -22.2)
    node(resenias, hw, hh, [2.1.3.4 Reseñas \ del transportista])

    let oferta = (plataforma-cliente-branch-x, -23.4)
    node(oferta, hw, hh, [2.1.4 Oferta de Retiro])

    let oferta-branch-x = branch-x(oferta.at(0))
    let fecha-retiro = (oferta-branch-x, -24.6)
    node(fecha-retiro, hw, hh, [2.1.4.1 Indicar fecha \ de retiro])
    let direccion-retiro = (oferta-branch-x, -25.8)
    node(direccion-retiro, hw, hh, [2.1.4.2 Indicar dirección \ de retiro])
    let direccion-entrega = (oferta-branch-x, -27)
    node(direccion-entrega, hw, hh, [2.1.4.3 Indicar dirección \ de entrega])
    let confirmar-oferta = (oferta-branch-x, -28.2)
    node(confirmar-oferta, hw, hh, [2.1.4.4 Confirmar oferta])

    let pago = (plataforma-cliente-branch-x, -29.4)
    node(pago, hw, hh, [2.1.5 Pago del Servicio])

    let pago-branch-x = branch-x(pago.at(0))
    let pago-1 = (pago-branch-x, -30.6)
    node(pago-1, hw, hh, [2.1.5.1 Realizar pago \ tras aceptación])
    let pago-2 = (pago-branch-x, -31.8)
    node(pago-2, hw, hh, [2.1.5.2 Recibir datos de \ contacto del transportista])

    let plataforma-transportista = (plataformas-branch-x, -33.0)
    node(plataforma-transportista, hw, hh, [2.2 Plataforma \ Transportista])

    let plataforma-transportista-branch-x = branch-x(plataforma-transportista.at(0))
    
    let disponibilidad = (plataforma-transportista-branch-x, -34.2)
    node(disponibilidad, hw, hh, [2.2.1 Publicación de \ Disponibilidad])

    let disponibilidad-branch-x = branch-x(disponibilidad.at(0))
    let zona-origen = (disponibilidad-branch-x, -35.4)
    node(zona-origen, hw, hh, [2.2.1.1 Indicar zona \ de origen])
    let limite-km = (disponibilidad-branch-x, -36.6)
    node(limite-km, hw, hh, [2.2.1.2 Indicar limite \ de kilómetros])
    let precio-km = (disponibilidad-branch-x, -37.8)
    node(precio-km, hw, hh, [2.2.1.3 Indicar precio \ por km])
    let confirmar-publicacion = (disponibilidad-branch-x, -39)
    node(confirmar-publicacion, hw, hh, [2.2.1.4 Confirmar \ publicación])

    let visualizacion-ofertas = (plataforma-transportista-branch-x, -40.2)
    node(visualizacion-ofertas, hw, hh, [2.2.2 Visualización de \ Ofertas])

    let visualizacion-ofertas-branch-x = branch-x(visualizacion-ofertas.at(0))
    let listado-ofertas = (visualizacion-ofertas-branch-x, -41.4)
    node(listado-ofertas, hw, hh, [2.2.2.1 Listado de \ ofertas recibidas])
    let detalle-viaje = (visualizacion-ofertas-branch-x, -43.0)
    node(detalle-viaje, hw, 2 * hh, [2.2.2.2 Detalle de viaje \ (distancia, ubicación, \ volumen, peso)])
    let detalle-cliente = (visualizacion-ofertas-branch-x, -44.6)
    node(detalle-cliente, hw, hh, [2.2.2.3 Detalle del cliente \ (datos personales, reseñas)])

    let aceptacion = (plataforma-transportista-branch-x, -46.2)
    node(aceptacion, hw, hh, [2.2.3 Aceptación de Viaje])

    let aceptacion-branch-x = branch-x(aceptacion.at(0))
    let boton-aceptacion = (aceptacion-branch-x, -47.4)
    node(boton-aceptacion, hw, hh, [2.2.3.1 Botón de \ aceptación de viaje])
    let actualizacion-fecha = (aceptacion-branch-x, -48.6)
    node(actualizacion-fecha, hw, hh, [2.2.3.2 Actualización de \ fecha estimada de entrega])

    let realizacion-viaje = (plataforma-transportista-branch-x, -50.2)
    node(realizacion-viaje, hw, hh, [2.2.4 Realización del Viaje])

    let realizacion-viaje-branch-x = branch-x(realizacion-viaje.at(0))
    let marcar-recibido = (realizacion-viaje-branch-x, -51.4)
    node(marcar-recibido, hw, hh, [2.2.4.1 Marcar producto \ como recibido])
    let marcar-entregado = (realizacion-viaje-branch-x, -52.6)
    node(marcar-entregado, hw, hh, [2.2.4.2 Marcar producto \ como entregado])
    let notificacion-estado = (realizacion-viaje-branch-x, -53.8)
    node(notificacion-estado, hw, hh, [2.2.4.3 Notificación de \ estado al cliente])

    trunk(plataformas, plataforma-transportista)
    branch(plataformas, plataforma-cliente, hw)
    branch(plataformas, plataforma-transportista, hw)

    trunk(plataforma-cliente, pago)
    branch(plataforma-cliente, busqueda, hw)
    branch(plataforma-cliente, filtrado, hw)
    branch(plataforma-cliente, detalles, hw)
    branch(plataforma-cliente, oferta, hw)
    branch(plataforma-cliente, pago, hw)

    trunk(busqueda, ordenamiento)
    branch(busqueda, origen-destino, hw)
    branch(busqueda, fecha, hw)
    branch(busqueda, listado, hw)
    branch(busqueda, ordenamiento, hw)

    trunk(filtrado, reset)
    branch(filtrado, precio, hw)
    branch(filtrado, peso, hw)
    branch(filtrado, dimensiones, hw)
    branch(filtrado, capacidad, hw)
    branch(filtrado, reset, hw)

    trunk(detalles, resenias)
    branch(detalles, fotos-camion, hw)
    branch(detalles, estimacion, hw)
    branch(detalles, historial, hw)
    branch(detalles, resenias, hw)

    trunk(oferta, confirmar-oferta)
    branch(oferta, fecha-retiro, hw)
    branch(oferta, direccion-retiro, hw)
    branch(oferta, direccion-entrega, hw)
    branch(oferta, confirmar-oferta, hw)

    trunk(pago, pago-2)
    branch(pago, pago-1, hw)
    branch(pago, pago-2, hw)

    trunk(plataforma-transportista, realizacion-viaje)
    branch(plataforma-transportista, disponibilidad, hw)
    branch(plataforma-transportista, visualizacion-ofertas, hw)
    branch(plataforma-transportista, aceptacion, hw)
    branch(plataforma-transportista, realizacion-viaje, hw)

    trunk(disponibilidad, confirmar-publicacion)
    branch(disponibilidad, zona-origen, hw)
    branch(disponibilidad, limite-km, hw)
    branch(disponibilidad, precio-km, hw)
    branch(disponibilidad, confirmar-publicacion, hw)

    trunk(visualizacion-ofertas, detalle-cliente)
    branch(visualizacion-ofertas, listado-ofertas, hw)
    branch(visualizacion-ofertas, detalle-viaje, hw)
    branch(visualizacion-ofertas, detalle-cliente, hw)

    trunk(aceptacion, actualizacion-fecha)
    branch(aceptacion, boton-aceptacion, hw)
    branch(aceptacion, actualizacion-fecha, hw)

    trunk(realizacion-viaje, notificacion-estado)
    branch(realizacion-viaje, marcar-recibido, hw)
    branch(realizacion-viaje, marcar-entregado, hw)
    branch(realizacion-viaje, notificacion-estado, hw)

    // ── 3. Integraciones ─────────────────────────────────────────────
    let integraciones = (0, -1.8)
    node(integraciones, hw, hh, [3. Integraciones])

    let integraciones-branch-x = branch-x(integraciones.at(0))
    let arca = (integraciones-branch-x, -3.0)
    node(arca, hw, hh, [3.1 Integración con \ ARCA])
    let pago-seguro = (integraciones-branch-x, -4.2)
    node(pago-seguro, hw, hh, [3.2 Integración con \ medio de pago seguro])
    let google-maps = (integraciones-branch-x, -5.4)
    node(google-maps, hw, hh, [3.3 Integración con \ Google Maps])

    let google-maps-branch-x = branch-x(google-maps.at(0))
    let geocoding = (google-maps-branch-x, -6.6)
    node(geocoding, hw, hh, [3.3.1 Geocodificación \ de direcciones])
    let rutas = (google-maps-branch-x, -7.8)
    node(rutas, hw, hh, [3.3.2 Visualización \ de rutas])

    trunk(integraciones, google-maps)
    branch(integraciones, arca, hw)
    branch(integraciones, pago-seguro, hw)
    branch(integraciones, google-maps, hw)

    trunk(google-maps, rutas)
    branch(google-maps, geocoding, hw)
    branch(google-maps, rutas, hw)

    // ── 4. Seguro ────────────────────────────────────────────────────
    let seguro = (6, -1.8)
    node(seguro, hw, hh, [4. Seguro])

    let seguro-branch-x = branch-x(seguro.at(0))
    let seguro-integracion = (seguro-branch-x, -3.0)
    node(seguro-integracion, hw, hh, [4.1 Integración con \ Aseguradora])

    let seguro-integracion-branch-x = branch-x(seguro-integracion.at(0))
    let seguro-int-api = (seguro-integracion-branch-x, -4.2)
    node(seguro-int-api, hw, hh, [4.1.1 Integración con \ API de aseguradora])
    let seguro-int-coberturas = (seguro-integracion-branch-x, -5.4)
    node(seguro-int-coberturas, hw, hh, [4.1.2 Obtención de \ coberturas disponibles])

    let seguro-cotizacion = (seguro-branch-x, -6.6)
    node(seguro-cotizacion, hw, hh, [4.2 Cotización del Seguro])

    let seguro-cotizacion-branch-x = branch-x(seguro-cotizacion.at(0))
    let seguro-cot-valor = (seguro-cotizacion-branch-x, -7.8)
    node(seguro-cot-valor, hw, hh, [4.2.1 Cálculo por \ valor declarado])
    let seguro-cot-distancia = (seguro-cotizacion-branch-x, -9)
    node(seguro-cot-distancia, hw, hh, [4.2.2 Cálculo por \ distancia del viaje])
    let seguro-cot-visualizacion = (seguro-cotizacion-branch-x, -10.2)
    node(seguro-cot-visualizacion, hw, hh, [4.2.3 Visualización del \ costo al cliente])

    let seguro-contratacion = (seguro-branch-x, -11.4)
    node(seguro-contratacion, hw, hh, [4.3 Contratación del Seguro])

    let seguro-contratacion-branch-x = branch-x(seguro-contratacion.at(0))
    let seguro-cont-seleccion = (seguro-contratacion-branch-x, -12.6)
    node(seguro-cont-seleccion, hw, hh, [4.3.1 Selección de cobertura])
    let seguro-cont-pago = (seguro-contratacion-branch-x, -13.8)
    node(seguro-cont-pago, hw, hh, [4.3.2 Pago integrado \ al flujo de pago])
    let seguro-cont-emision = (seguro-contratacion-branch-x, -15)
    node(seguro-cont-emision, hw, hh, [4.3.3 Emisión y envío \ de póliza])

    let seguro-polizas = (seguro-branch-x, -16.2)
    node(seguro-polizas, hw, hh, [4.4 Gestión de Pólizas])

    let seguro-polizas-branch-x = branch-x(seguro-polizas.at(0))
    let seguro-pol-historial = (seguro-polizas-branch-x, -17.4)
    node(seguro-pol-historial, hw, hh, [4.4.1 Historial de \ seguros contratados])
    let seguro-pol-descarga = (seguro-polizas-branch-x, -18.6)
    node(seguro-pol-descarga, hw, hh, [4.4.2 Descarga de póliza])

    let seguro-siniestros = (seguro-branch-x, -19.8)
    node(seguro-siniestros, hw, hh, [4.5 Gestión de Siniestros])

    let seguro-siniestros-branch-x = branch-x(seguro-siniestros.at(0))
    let seguro-sin-declaracion = (seguro-siniestros-branch-x, -21)
    node(seguro-sin-declaracion, hw, hh, [4.5.1 Declaración \ de siniestro])
    let seguro-sin-seguimiento = (seguro-siniestros-branch-x, -22.2)
    node(seguro-sin-seguimiento, hw, hh, [4.5.2 Seguimiento \ del siniestro])

    trunk(seguro, seguro-siniestros)
    branch(seguro, seguro-integracion, hw)
    branch(seguro, seguro-cotizacion, hw)
    branch(seguro, seguro-contratacion, hw)
    branch(seguro, seguro-polizas, hw)
    branch(seguro, seguro-siniestros, hw)

    trunk(seguro-integracion, seguro-int-coberturas)
    branch(seguro-integracion, seguro-int-api, hw)
    branch(seguro-integracion, seguro-int-coberturas, hw)

    trunk(seguro-cotizacion, seguro-cot-visualizacion)
    branch(seguro-cotizacion, seguro-cot-valor, hw)
    branch(seguro-cotizacion, seguro-cot-distancia, hw)
    branch(seguro-cotizacion, seguro-cot-visualizacion, hw)

    trunk(seguro-contratacion, seguro-cont-emision)
    branch(seguro-contratacion, seguro-cont-seleccion, hw)
    branch(seguro-contratacion, seguro-cont-pago, hw)
    branch(seguro-contratacion, seguro-cont-emision, hw)

    trunk(seguro-polizas, seguro-pol-descarga)
    branch(seguro-polizas, seguro-pol-historial, hw)
    branch(seguro-polizas, seguro-pol-descarga, hw)

    trunk(seguro-siniestros, seguro-sin-seguimiento)
    branch(seguro-siniestros, seguro-sin-declaracion, hw)
    branch(seguro-siniestros, seguro-sin-seguimiento, hw)

    // ── 5. Gestión del Proyecto ──────────────────────────────────────
    let proyecto = (12, -1.8)
    node(proyecto, hw, hh, [5. Gestión del Proyecto])

    let proyecto-branch-x = branch-x(proyecto.at(0))
    let artefactos = (proyecto-branch-x, -3.0)
    node(artefactos, hw, hh, [5.1 Artefactos])

    let artefactos-branch-x = branch-x(artefactos.at(0))
    let lean = (artefactos-branch-x, -4.2)
    node(lean, hw, hh, [5.1.1 Artefactos Lean])
    let backlog = (artefactos-branch-x, -5.4)
    node(backlog, hw, hh, [5.1.2 Product Backlog])
    let usm = (artefactos-branch-x, -6.6)
    node(usm, hw, hh, [5.1.3 User Story Map])
    let wbs = (artefactos-branch-x, -7.8)
    node(wbs, hw, hh, [5.1.4 Work Breakdown \ Structure])
    let cronograma = (artefactos-branch-x, -9)
    node(cronograma, hw, hh, [5.1.5 Cronograma])
    let planilla-costos = (artefactos-branch-x, -10.2)
    node(planilla-costos, hw, hh, [5.1.6 Planilla de Costos])
    let plan-comunicacion = (artefactos-branch-x, -11.4)
    node(plan-comunicacion, hw, hh, [5.1.7 Plan de \ Comunicación])

    trunk(proyecto, artefactos)
    branch(proyecto, artefactos, hw)

    trunk(artefactos, plan-comunicacion)
    branch(artefactos, lean, hw)
    branch(artefactos, backlog, hw)
    branch(artefactos, usm, hw)
    branch(artefactos, wbs, hw)
    branch(artefactos, cronograma, hw)
    branch(artefactos, planilla-costos, hw)
    branch(artefactos, plan-comunicacion, hw)

    // ── Aristas raíz → nivel 1 ───────────────────────────────────────
    arrow(root, gestion)
    arrow(root, plataformas)
    arrow(root, integraciones)
    arrow(root, seguro)
    arrow(root, proyecto)
  })
]
