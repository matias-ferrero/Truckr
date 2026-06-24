#import "../template.typ": c-brand, c-brand-mid, conf
#import "@preview/cetz:0.3.4": canvas, draw

#show: conf

#set page(
  width: 594mm,
  height: 380mm,
  margin: (x: 1cm, y: 1.2cm),
  footer: "(*) Estos trabajos han sido tomados para el momento post-MVP, por lo que no se verán implementados en el producto mínimo viable.",
)

= WBS — Work Breakdown Structure

#set text(size: 9pt)

#let node-stroke = 1.2pt + c-brand
#let node-fill = luma(245)


#let hw = 1.8
#let hh = 0.5
#let rhw = 3.5
#let trunk-offset = 1
#let branch-offset = 2.25

#align(center)[
  #canvas(length: 1cm, {
    import draw: *

    let node(pos, half-w, half-h, label, fill: node-fill) = {
      let (cx, cy) = pos
      rect(
        (cx - half-w, cy - half-h),
        (cx + half-w, cy + half-h),
        fill: fill,
        stroke: node-stroke,
        radius: 2pt,
      )
      content((cx, cy), label)
    }

    let trunk(p, last-child) = {
      let (px, py) = p
      let (_, last-cy) = last-child
      line(
        (px - trunk-offset, py - hh),
        (px - trunk-offset, last-cy),
        stroke: 0.8pt + c-brand,
      )
    }

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

    let arrow(p, c) = {
      let (px, py) = p
      let (cx, cy) = c
      let my = (py + cy) / 2
      line(
        (px, py - hh),
        (px, my),
        (cx, my),
        (cx, cy + hh),
        mark: (end: ">", fill: c-brand, size: 0.3),
        stroke: 0.8pt + c-brand,
      )
    }

    // ── Nivel 0: Raíz ──────────────────────────────────────────────────────
    let root = (0, 0)
    node(root, rhw, hh, [*Truckr® — Plataforma de Transporte*])

    // ── 1. Autenticación y Cuentas ─────────────────────────────────────────
    let cuentas = (-26, -2.2)
    node(cuentas, hw, hh, [1. Autenticación \ y Cuentas])

    let cuentas-bx = branch-x(cuentas.at(0))

    let c-registro = (cuentas-bx, -3.8)
    node(c-registro, hw, hh, [1.1 Registro])

    let c-registro-bx = branch-x(c-registro.at(0))
    let c-reg-1 = (c-registro-bx, -5.2)
    node(c-reg-1, hw, hh, [1.1.1 Registrarse])
    let c-reg-2 = (c-registro-bx, -6.8)
    node(c-reg-2, hw, hh, [1.1.2 Landing Page])
    let c-reg-3 = (c-registro-bx, -8.2)
    node(c-reg-3, hw, hh, [1.1.3 Verificar Cuenta\*])

    let c-login = (cuentas-bx, -9.8)
    node(c-login, hw, hh, [1.2 Login])

    let c-login-bx = branch-x(c-login.at(0))
    let c-log-1 = (c-login-bx, -11.2)
    node(c-log-1, hw, hh, [1.2.1 Login])
    let c-log-2 = (c-login-bx, -12.8)
    node(c-log-2, hw, hh, [1.2.2 Cambiar/Recuperar \ Contraseña\*])

    let c-perfil = (cuentas-bx, -14.2)
    node(c-perfil, hw, hh, [1.3 Perfil de Usuario])

    let c-vehiculo = (cuentas-bx, -15.8)
    node(c-vehiculo, hw, hh, [1.4 Gestión de Vehículos])

    let c-vehiculo-bx = branch-x(c-vehiculo.at(0))
    let c-veh-1 = (c-vehiculo-bx, -17.2)
    node(c-veh-1, hw, hh, [1.4.1 Registrar Vehículo])
    let c-veh-2 = (c-vehiculo-bx, -18.8)
    node(c-veh-2, hw, hh, [1.4.2 Administrar mi flota])
    let c-veh-3 = (c-vehiculo-bx, -20.2)
    node(c-veh-3, hw, hh, [1.4.3 Editar Vehículo])
    let c-veh-4 = (c-vehiculo-bx, -21.8)
    node(c-veh-4, hw, hh, [1.4.4 Baja de Vehículo])

    let c-dashboard = (cuentas-bx, -23.2)
    node(c-dashboard, hw, hh, [1.5 Dashboard])

    trunk(cuentas, c-dashboard)
    branch(cuentas, c-registro, hw)
    branch(cuentas, c-login, hw)
    branch(cuentas, c-perfil, hw)
    branch(cuentas, c-vehiculo, hw)
    branch(cuentas, c-dashboard, hw)

    trunk(c-registro, c-reg-3)
    branch(c-registro, c-reg-1, hw)
    branch(c-registro, c-reg-2, hw)
    branch(c-registro, c-reg-3, hw)

    trunk(c-login, c-log-2)
    branch(c-login, c-log-1, hw)
    branch(c-login, c-log-2, hw)

    trunk(c-vehiculo, c-veh-4)
    branch(c-vehiculo, c-veh-1, hw)
    branch(c-vehiculo, c-veh-2, hw)
    branch(c-vehiculo, c-veh-3, hw)
    branch(c-vehiculo, c-veh-4, hw)

    // ── 2. Ventanas de Transporte ──────────────────────────────────────────
    let ventanas = (-19.5, -2.2)
    node(ventanas, hw, hh, [2. Ventanas de \ Transporte])

    let ventanas-bx = branch-x(ventanas.at(0))

    let v-publicar = (ventanas-bx, -3.8)
    node(v-publicar, hw, hh, [2.1 Publicar])

    let v-pub-bx = branch-x(v-publicar.at(0))
    let v-pub-1 = (v-pub-bx, -5.2)
    node(v-pub-1, hw, hh, [2.1.1 Publicar Ventana])
    let v-pub-2 = (v-pub-bx, -6.8)
    node(v-pub-2, hw, hh, [2.1.2 Radio de recogida])

    let v-administrar = (ventanas-bx, -8.2)
    node(v-administrar, hw, hh, [2.2 Administrar])

    let v-adm-bx = branch-x(v-administrar.at(0))
    let v-adm-1 = (v-adm-bx, -9.8)
    node(v-adm-1, hw, hh, [2.2.1 Administrar Ventanas])
    let v-adm-2 = (v-adm-bx, -11.2)
    node(v-adm-2, hw, hh, [2.2.2 Editar Ventana])
    let v-adm-3 = (v-adm-bx, -12.8)
    node(v-adm-3, hw, hh, [2.2.3 Ocultar Ventana])
    let v-adm-4 = (v-adm-bx, -14.2)
    node(v-adm-4, hw, hh, [2.2.4 Eliminar Ventana])

    trunk(ventanas, v-administrar)
    branch(ventanas, v-publicar, hw)
    branch(ventanas, v-administrar, hw)

    trunk(v-publicar, v-pub-2)
    branch(v-publicar, v-pub-1, hw)
    branch(v-publicar, v-pub-2, hw)

    trunk(v-administrar, v-adm-4)
    branch(v-administrar, v-adm-1, hw)
    branch(v-administrar, v-adm-2, hw)
    branch(v-administrar, v-adm-3, hw)
    branch(v-administrar, v-adm-4, hw)

    // ── 3. Cargas y Ofertas ────────────────────────────────────────────────
    let cargasofertas = (-13, -2.2)
    node(cargasofertas, hw, hh, [3. Cargas y Ofertas])

    let co-bx = branch-x(cargasofertas.at(0))

    let co-publicar = (co-bx, -3.8)
    node(co-publicar, hw, hh, [3.1 Publicar])

    let co-admin = (co-bx, -5.2)
    node(co-admin, hw, hh, [3.2 Administrar])

    let co-adm-bx = branch-x(co-admin.at(0))
    let co-adm-1 = (co-adm-bx, -6.8)
    node(co-adm-1, hw, hh, [3.2.1 Administrar cargas])
    let co-adm-2 = (co-adm-bx, -8.2)
    node(co-adm-2, hw, hh, [3.2.2 Filtrar mis cargas])
    let co-adm-3 = (co-adm-bx, -9.8)
    node(co-adm-3, hw, hh, [3.2.3 Ver detalles de carga])
    let co-adm-4 = (co-adm-bx, -11.2)
    node(co-adm-4, hw, hh, [3.2.4 Editar carga])

    let co-busqueda = (co-bx, -12.8)
    node(co-busqueda, hw, hh, [3.3 Búsqueda de \ Ventanas])

    let co-bus-bx = branch-x(co-busqueda.at(0))
    let co-bus-1 = (co-bus-bx, -14.2)
    node(co-bus-1, hw, hh, [3.3.1 Buscar Ventanas])
    let co-bus-2 = (co-bus-bx, -15.8)
    node(co-bus-2, hw, hh, [3.3.2 Filtrar Ventanas])

    let co-ofertas = (co-bx, -17.2)
    node(co-ofertas, hw, hh, [3.4 Ofertas])

    let co-of-bx = branch-x(co-ofertas.at(0))
    let co-of-1 = (co-of-bx, -18.8)
    node(co-of-1, hw, hh, [3.4.1 Ofertar retiro])
    let co-of-2 = (co-of-bx, -20.2)
    node(co-of-2, hw, hh, [3.4.2 Ver ofertas de envío])
    let co-of-3 = (co-of-bx, -21.8)
    node(co-of-3, hw, hh, [3.4.3 Filtrar ofertas\*])
    let co-of-4 = (co-of-bx, -23.2)
    node(co-of-4, hw, hh, [3.4.4 Aceptar oferta])

    trunk(cargasofertas, co-ofertas)
    branch(cargasofertas, co-publicar, hw)
    branch(cargasofertas, co-admin, hw)
    branch(cargasofertas, co-busqueda, hw)
    branch(cargasofertas, co-ofertas, hw)

    trunk(co-admin, co-adm-4)
    branch(co-admin, co-adm-1, hw)
    branch(co-admin, co-adm-2, hw)
    branch(co-admin, co-adm-3, hw)
    branch(co-admin, co-adm-4, hw)

    trunk(co-busqueda, co-bus-2)
    branch(co-busqueda, co-bus-1, hw)
    branch(co-busqueda, co-bus-2, hw)

    trunk(co-ofertas, co-of-4)
    branch(co-ofertas, co-of-1, hw)
    branch(co-ofertas, co-of-2, hw)
    branch(co-ofertas, co-of-3, hw)
    branch(co-ofertas, co-of-4, hw)

    // ── 4. Ejecución de Envíos ─────────────────────────────────────────────
    let ejecucion = (-6.5, -2.2)
    node(ejecucion, hw, hh, [4. Envíos])

    let ejecucion-bx = branch-x(ejecucion.at(0))

    let e-administrar = (ejecucion-bx, -3.8)
    node(e-administrar, hw, hh, [4.1 Administrar])

    let e-adm-bx = branch-x(e-administrar.at(0))
    let e-adm-3 = (e-adm-bx, -5.2)
    node(e-adm-3, hw, hh, [4.1.3 Detalles de envío])
    let e-adm-4 = (e-adm-bx, -6.8)
    node(e-adm-4, hw, hh, [4.1.4 Mapa en detalles])

    let e-aceptar = (ejecucion-bx, -8.2)
    node(e-aceptar, hw, hh, [4.2 Aceptar y Ejecutar])

    let e-ace-bx = branch-x(e-aceptar.at(0))
    let e-ace-2 = (e-ace-bx, -9.8)
    node(e-ace-2, hw, hh, [4.2.1 Inicio de Envío])
    let e-ace-3 = (e-ace-bx, -11.2)
    node(e-ace-3, hw, hh, [4.2.2 Carga entregada])

    let e-avanzados = (ejecucion-bx, -12.8)
    node(e-avanzados, hw, hh, [4.3 Envíos Compuestos\*])

    let e-ava-bx = branch-x(e-avanzados.at(0))
    let e-ava-1 = (e-ava-bx, -14.2)
    node(e-ava-1, hw, hh, [4.3.1 Combinar Envíos\*])
    let e-ava-2 = (e-ava-bx, -15.8)
    node(e-ava-2, hw, hh, [4.3.2 Encadenar Envíos\*])

    let e-notifs = (ejecucion-bx, -17.2)
    node(e-notifs, hw, hh, [4.4 Notificaciones])

    let e-nrt-bx = branch-x(e-notifs.at(0))
    let e-nrt-1 = (e-nrt-bx, -18.8)
    node(e-nrt-1, hw, hh, [4.4.1 Oferta recibida])
    let e-nrt-2 = (e-nrt-bx, -20.2)
    node(e-nrt-2, hw, hh, [4.4.2 Oferta respondida])
    let e-nrt-3 = (e-nrt-bx, -21.8)
    node(e-nrt-3, hw, hh, [4.4.3 Pago recibido])

    trunk(ejecucion, e-notifs)
    branch(ejecucion, e-administrar, hw)
    branch(ejecucion, e-aceptar, hw)
    branch(ejecucion, e-avanzados, hw)
    branch(ejecucion, e-notifs, hw)

    trunk(e-administrar, e-adm-4)
    branch(e-administrar, e-adm-3, hw)
    branch(e-administrar, e-adm-4, hw)

    trunk(e-aceptar, e-ace-3)
    branch(e-aceptar, e-ace-2, hw)
    branch(e-aceptar, e-ace-3, hw)

    trunk(e-avanzados, e-ava-2)
    branch(e-avanzados, e-ava-1, hw)
    branch(e-avanzados, e-ava-2, hw)

    trunk(e-notifs, e-nrt-3)
    branch(e-notifs, e-nrt-1, hw)
    branch(e-notifs, e-nrt-2, hw)
    branch(e-notifs, e-nrt-3, hw)

    // ── 5. Pagos y Seguros ─────────────────────────────────────────────────
    let pagos = (0, -2.2)
    node(pagos, hw, hh, [5. Pagos y Seguros])

    let pagos-bx = branch-x(pagos.at(0))

    let p-realizar = (pagos-bx, -3.8)
    node(p-realizar, hw, hh, [5.1 Gestionar Pagos])

    let p-real-bx = branch-x(p-realizar.at(0))
    let p-real-1 = (p-real-bx, -5.2)
    node(p-real-1, hw, hh, [5.1.1 Pago del Expedidor])
    let p-real-2 = (p-real-bx, -6.8)
    node(p-real-2, hw, hh, [5.1.2 Cobro del Transportista])
    let p-real-3 = (p-real-bx, -8.2)
    node(p-real-3, hw, hh, [5.1.3 Bandeja de Pagos])

    let p-seguro = (pagos-bx, -9.8)
    node(p-seguro, hw, hh, [5.2 Contratación \ del Seguro\*])

    let p-seg-bx = branch-x(p-seguro.at(0))
    let p-seg-1 = (p-seg-bx, -11.2)
    node(p-seg-1, hw, hh, [5.2.1 Seleccionar cobertura])
    let p-seg-2 = (p-seg-bx, -12.8)
    node(p-seg-2, hw, hh, [5.2.2 Pago integrado \ al flujo])

    let p-siniestros = (pagos-bx, -14.2)
    node(p-siniestros, hw, hh, [5.3 Gestión de \ Siniestros\*])

    let p-sin-bx = branch-x(p-siniestros.at(0))
    let p-sin-1 = (p-sin-bx, -15.8)
    node(p-sin-1, hw, hh, [5.3.1 Declaración \ de siniestro])
    let p-sin-2 = (p-sin-bx, -17.2)
    node(p-sin-2, hw, hh, [5.3.2 Confirmación \ de reclamo])

    trunk(pagos, p-siniestros)
    branch(pagos, p-realizar, hw)
    branch(pagos, p-seguro, hw)
    branch(pagos, p-siniestros, hw)

    trunk(p-realizar, p-real-3)
    branch(p-realizar, p-real-1, hw)
    branch(p-realizar, p-real-2, hw)
    branch(p-realizar, p-real-3, hw)

    trunk(p-seguro, p-seg-2)
    branch(p-seguro, p-seg-1, hw)
    branch(p-seguro, p-seg-2, hw)

    trunk(p-siniestros, p-sin-2)
    branch(p-siniestros, p-sin-1, hw)
    branch(p-siniestros, p-sin-2, hw)

    // ── 7. Reseñas y Calificaciones ────────────────────────────────────────
    let resenias = (6.5, -2.2)
    node(resenias, hw, hh, [6. Reseñas y \ Calificaciones])

    let resenias-bx = branch-x(resenias.at(0))

    let re-crear = (resenias-bx, -3.8)
    node(re-crear, hw, hh, [6.1 Crear Reseña])

    let re-crear-bx = branch-x(re-crear.at(0))
    let re-cre-texto = (re-crear-bx, -5.2)
    node(re-cre-texto, hw, hh, [6.1.1 Redactar texto \ de la reseña])
    let re-cre-puntaje = (re-crear-bx, -6.8)
    node(re-cre-puntaje, hw, hh, [6.1.2 Asignar puntaje])

    let re-leer = (resenias-bx, -8.2)
    node(re-leer, hw, hh, [6.2 Leer Reseñas])

    let re-leer-bx = branch-x(re-leer.at(0))
    let re-lee-listado = (re-leer-bx, -9.8)
    node(re-lee-listado, hw, hh, [6.2.1 Listado de reseñas])
    let re-lee-promedio = (re-leer-bx, -11.2)
    node(re-lee-promedio, hw, hh, [6.2.2 Puntaje promedio])

    let re-gestionar = (resenias-bx, -12.8)
    node(re-gestionar, hw, hh, [6.3 Gestión de Reseñas\*])

    let re-gest-bx = branch-x(re-gestionar.at(0))
    let re-gest-editar = (re-gest-bx, -14.2)
    node(re-gest-editar, hw, hh, [6.3.1 Editar reseña \ propia])
    let re-gest-eliminar = (re-gest-bx, -15.8)
    node(re-gest-eliminar, hw, hh, [6.3.2 Eliminar reseña \ propia])

    trunk(resenias, re-gestionar)
    branch(resenias, re-crear, hw)
    branch(resenias, re-leer, hw)
    branch(resenias, re-gestionar, hw)

    trunk(re-crear, re-cre-puntaje)
    branch(re-crear, re-cre-texto, hw)
    branch(re-crear, re-cre-puntaje, hw)

    trunk(re-leer, re-lee-promedio)
    branch(re-leer, re-lee-listado, hw)
    branch(re-leer, re-lee-promedio, hw)

    trunk(re-gestionar, re-gest-eliminar)
    branch(re-gestionar, re-gest-editar, hw)
    branch(re-gestionar, re-gest-eliminar, hw)

    // ── 8. Integraciones Externas ──────────────────────────────────────────
    let integraciones = (13, -2.2)
    node(integraciones, hw, hh, [7. Integraciones \ Externas])

    let int-bx = branch-x(integraciones.at(0))

    let i-arca = (int-bx, -3.8)
    node(i-arca, hw, hh, [7.1 ARCA\*])

    let i-arca-bx = branch-x(i-arca.at(0))
    let i-arc-api = (i-arca-bx, -5.2)
    node(i-arc-api, hw, hh, [7.1.1 Integración con \ API de ARCA])
    let i-arc-validacion = (i-arca-bx, -6.8)
    node(i-arc-validacion, hw, hh, [7.1.2 Validación \ fiscal de usuarios])

    let i-mp = (int-bx, -8.2)
    node(i-mp, hw, hh, [7.2 Mercado Pago\*])

    let i-maps = (int-bx, -9.8)
    node(i-maps, hw, hh, [7.3 Google Maps])

    let i-maps-bx = branch-x(i-maps.at(0))
    let i-map-geo = (i-maps-bx, -11.2)
    node(i-map-geo, hw, hh, [7.3.1 Geocodificación \ de direcciones])
    let i-map-rutas = (i-maps-bx, -12.8)
    node(i-map-rutas, hw, hh, [7.3.2 Visualización \ de rutas])
    let i-map-dist = (i-maps-bx, -14.2)
    node(i-map-dist, hw, hh, [7.3.3 Cálculo de \ distancias])
    let i-map-track = (i-maps-bx, -15.8)
    node(i-map-track, hw, hh, [7.3.4 Tracking de Envío\*])

    let i-aseg = (int-bx, -17.2)
    node(i-aseg, hw, hh, [7.4 API Aseguradora\*])

    let i-aseg-bx = branch-x(i-aseg.at(0))
    let i-aseg-coberturas = (i-aseg-bx, -18.8)
    node(i-aseg-coberturas, hw, hh, [7.4.1 Consulta de \ coberturas])
    let i-aseg-emision = (i-aseg-bx, -20.2)
    node(i-aseg-emision, hw, hh, [7.4.2 Emisión de póliza])

    trunk(integraciones, i-aseg)
    branch(integraciones, i-arca, hw)
    branch(integraciones, i-mp, hw)
    branch(integraciones, i-maps, hw)
    branch(integraciones, i-aseg, hw)

    trunk(i-arca, i-arc-validacion)
    branch(i-arca, i-arc-api, hw)
    branch(i-arca, i-arc-validacion, hw)

    trunk(i-maps, i-map-track)
    branch(i-maps, i-map-geo, hw)
    branch(i-maps, i-map-rutas, hw)
    branch(i-maps, i-map-dist, hw)
    branch(i-maps, i-map-track, hw)

    trunk(i-aseg, i-aseg-emision)
    branch(i-aseg, i-aseg-coberturas, hw)
    branch(i-aseg, i-aseg-emision, hw)

    // ── 9. Gestión del Proyecto ────────────────────────────────────────────
    let proyecto = (19.5, -2.2)
    node(proyecto, hw, hh, [8. Gestión del Proyecto])

    let proyecto-bx = branch-x(proyecto.at(0))

    let proy-artefactos = (proyecto-bx, -3.8)
    node(proy-artefactos, hw, hh, [8.1 Artefactos])

    let proy-art-bx = branch-x(proy-artefactos.at(0))
    let proy-lean = (proy-art-bx, -5.2)
    node(proy-lean, hw, hh, [8.1.1 Artefactos Lean])
    let proy-backlog = (proy-art-bx, -6.8)
    node(proy-backlog, hw, hh, [8.1.2 Product Backlog])
    let proy-usm = (proy-art-bx, -8.2)
    node(proy-usm, hw, hh, [8.1.3 User Story Map])
    let proy-wbs = (proy-art-bx, -9.8)
    node(proy-wbs, hw, hh, [8.1.4 Work Breakdown \ Structure])
    let proy-cron = (proy-art-bx, -11.2)
    node(proy-cron, hw, hh, [8.1.5 Cronograma])
    let proy-costos = (proy-art-bx, -12.8)
    node(proy-costos, hw, hh, [8.1.6 Planilla de Costos])
    let proy-com = (proy-art-bx, -14.2)
    node(proy-com, hw, hh, [8.1.7 Plan de \ Comunicación])

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
    arrow(root, ventanas)
    arrow(root, cargasofertas)
    arrow(root, ejecucion)
    arrow(root, pagos)
    arrow(root, resenias)
    arrow(root, integraciones)
    arrow(root, proyecto)
  })
]
