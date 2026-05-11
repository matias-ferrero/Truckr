---
tag: REQ-FE-00021
title: Dashboard post-login + navegación global
priority: P1
status: backlog
created: '2026-05-10'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/146
author: Claude Code
github_issue: 146
github_repo: tcorzo/fiuba-gestion-tp
labels:
- REQ
- FE
- ux
- navigation
- mvp
- sprint-1
---

## Summary

Pantalla de aterrizaje post-login (rol-aware) más el chrome de navegación global (header persistente con links rol-aware). Es la pieza de UX que conecta todas las features de Sprint 1 entre sí — sin esto, las pantallas existen como islas y el demo se siente fragmentado.

## Problem Statement

Sprint 1 produce seis features visibles (Auth, Vehicle Reg, TransportWindow publishing, TransportWindow search, Carrier profile page, AWS deploy) pero ninguna las conecta. Después de loguearse, el usuario no tiene un punto de aterrizaje, no hay header con links a otras features, y cada pantalla es alcanzable sólo si conocés la URL de memoria. Esto no es aceptable para el demo.

El dashboard cumple dos funciones:

1. **Punto de aterrizaje rol-aware**: lo primero que el usuario ve después de loguearse. Según el rol (Carrier vs Shipper), expone las acciones primarias relevantes con cards/tiles.
2. **Mapa de la aplicación**: aunque algunas features de la card todavía no estén implementadas (ej. "Ofertas recibidas" para el Carrier en Sprint 1), aparecen como placeholders informando "próximamente". Esto comunica al usuario qué está disponible y qué viene.

El header global complementa: links persistentes en todas las pantallas para que el usuario nunca quede atrapado.

## Expected Behavior

### Sketch (semana 1 — entregable obligatorio)

Antes de empezar a implementar, Lucas produce una **sketch** (papel, whiteboard, Figma rápido) que define:

- Qué cards/tiles aparecen en el dashboard del Carrier y en el del Shipper
- Qué links viven en el header (con cuáles aparecen siempre vs sólo cuando hay sesión)
- Qué hace el `/` cuando el usuario no está logueado (landing pública vs redirect a login)
- Cómo se muestra el rol activo si el `User` tiene ambos perfiles (`Carrier` + `Shipper`) — selector? tabs?
- Estados vacíos para placeholders ("aún no tenés ventanas publicadas", "aún no recibiste ofertas")

La sketch se circula a Brian, Matias, Franco y Tomás para sign-off antes de fin de semana 1. **A partir de ahí, las features de los demás se diseñan contra ese mapa.**

### Implementación

**Carrier dashboard (`/dashboard` cuando el `current_user.carrier?` es true):**

- Card "Mi flota" → linkea al CRUD de vehículos (`REQ-BE-00009` / `REQ-BE-00010`, ya en PR #144)
- Card "Mis ventanas de transporte publicadas" → linkea al CRUD de TransportWindows (`REQ-FE-00016`)
- Card "Ofertas recibidas" → placeholder con estado "próximamente" (la inbox `REQ-FE-00017` no está en Sprint 1)
- Card "Editar mi perfil" → linkea al perfil (`REQ-FE-00012`, free-agent issue)

**Shipper dashboard (`/dashboard` cuando el `current_user.shipper?` es true):**

- Card "Buscar transporte" como acción primaria → linkea a la búsqueda (`REQ-FE-00006`)
- Card "Mis ofertas hechas" → placeholder ("próximamente")
- Card "Editar mi perfil" → linkea al perfil (`REQ-FE-00012`)

**Si el `User` tiene ambos perfiles**: el dashboard expone un selector/toggle de rol activo, y muestra las cards correspondientes al rol seleccionado. La preferencia se persiste (localStorage o `User.preferred_role` — Lucas decide en la sketch).

**Header global**:

- Logo / nombre de la app (linkea a `/`)
- Links persistentes según rol activo (Mi flota, Buscar, etc. — coordinar con la sketch)
- Avatar / nombre del usuario en la esquina derecha → menú con "Mi perfil", "Cerrar sesión"
- Visible en todas las pantallas autenticadas

### Routing

- `/` cuando no logueado: landing pública existente (placeholder o redirect a `/login` — Lucas decide en la sketch)
- `/` cuando logueado: redirect a `/dashboard`
- `/dashboard`: el componente nuevo, rol-aware
- Rutas protegidas: ya existe `RequireCarrier.tsx` en PR #144 — extender a un patrón general (`RequireAuth`, `RequireShipper`) si hace falta

## Current Behavior

`frontend/src/App.tsx` es un único archivo de ~20KB con un quote-form de placeholder. PR #144 introduce React Router (`router.tsx`), un splitter de páginas bajo `pages/`, y `RequireCarrier.tsx`, pero no hay dashboard ni header global todavía. Una vez que un usuario se logue (cuando exista Auth, `REQ-BE-00023`), no tiene a dónde ir excepto URLs que conozca de memoria.

## Impact

- **Demo de Sprint 1**: sin dashboard, las features se ven como islas y el demo no fluye. Con dashboard, el flujo *"sign up → land → publish window / register vehicle → search from the other side"* se vuelve obvio.
- **Calidad de UX como first-class concern**: explicita que alguien del equipo está pensando el flujo completo, no sólo features aisladas.
- **Bloquea el resto del equipo a nivel diseño** hasta que la sketch esté circulada — pero **desbloquea coherencia visual** una vez que está.

## Technical Notes

- **Stack**: React + Vite + TypeScript + Deno (frontend), React Router (introducido en PR #144).
- **Estilos**: seguir el patrón que establezca PR #144 (`frontend/src/styles/transportista.css` ya existe). Lucas decide si extender ese archivo o introducir un módulo `dashboard.css`.
- **Auth dependency**: necesita `REQ-BE-00023` para `current_user`, `current_user.carrier?`, `current_user.shipper?`, y la sesión. **El BE half de Auth debe estar mergeado antes de que Lucas pueda implementar el dashboard real.**
- **Sketch primero, código después**: la sketch es semana 1, el código viene a partir de la semana 2 (después de Auth BE). Esto es intencional — la sketch desbloquea a los demás devs aunque la implementación venga más tarde.
- **Tests**:
  - Vitest + RTL: render del dashboard según rol, links a cada card
  - Playwright E2E: smoke del happy path (login → land en dashboard correcto → click en card → llegar a la feature)
- **Out of scope** para esta issue:
  - Personalización del dashboard (drag-and-drop, ocultar cards, etc.)
  - Notificaciones in-app
  - Search bar en el header (lo de la home del Shipper alcanza)
  - Dark mode / theming

## Origin

Surgió en la conversación de planificación de Sprint 1 — el usuario observó que las features estaban siendo pensadas pantalla-por-pantalla sin nadie a cargo del flujo entre ellas. Asignado a Lucas (que se quedó sin scope primario después de que PR #144 absorbiera su trabajo de FE foundation).

## Related

- **Sprint plan**: [`docs/features/SPRINT-1-PLAN.md`](../../../docs/features/SPRINT-1-PLAN.md) (sección "Post-login dashboard + global navigation")
- **Auth (bloqueante para implementación)**: `REQ-BE-00023`
- **Foundation FE (ya provista por PR #144)**: React Router, `pages/` split, `RequireCarrier`
- **Features que el dashboard linkea**:
  - `REQ-BE-00009` + `REQ-BE-00010` (Vehicle / Fleet — ya en PR #144)
  - `REQ-FE-00016` (TransportWindow publishing)
  - `REQ-FE-00006` (TransportWindow search)
  - `REQ-FE-00014` (Carrier profile page — accesible vía search results, no desde dashboard directamente)
  - `REQ-FE-00012` (profile editing — free-agent)
  - `REQ-FE-00017` (carrier offers inbox — placeholder, no se implementa en Sprint 1)
- **Glosario**: [`docs/05-appendices/glossary.md`](../../../docs/05-appendices/glossary.md) (`User`, `Carrier`, `Shipper`)

## Acceptance Criteria

### Sketch (entregable de semana 1)

- [ ] Sketch del dashboard del Carrier producida (papel / whiteboard / Figma)
- [ ] Sketch del dashboard del Shipper producida
- [ ] Sketch del header global producida
- [ ] Decisión documentada sobre `/` no-logueado (landing pública o redirect a login)
- [ ] Decisión documentada sobre selector de rol cuando `User` tiene ambos perfiles
- [ ] Sketch circulada a Brian, Matias, Franco, Tomás para sign-off antes de fin de semana 1

### Implementación (después de Auth BE)

- [ ] Componente `<Dashboard />` rol-aware bajo `frontend/src/pages/dashboard/`
- [ ] Header global persistente en todas las rutas autenticadas
- [ ] `/` logueado redirige a `/dashboard`
- [ ] Cards del Carrier renderean según AC visual (fleet, windows, ofertas-placeholder, perfil)
- [ ] Cards del Shipper renderean según AC visual (search primario, ofertas-placeholder, perfil)
- [ ] Selector de rol activo funciona si el `User` tiene ambos perfiles
- [ ] Cada card linkea a la ruta correcta (las que existen) o muestra placeholder informativo (las que no)
- [ ] Estados vacíos cubiertos ("aún no tenés ventanas publicadas", etc.)
- [ ] Tests Vitest + RTL: render por rol, links correctos, placeholders presentes
- [ ] Test Playwright E2E: login → land en dashboard correcto → click en una card → llegar a la feature
- [ ] Identifiers en inglés, copy en es-AR
