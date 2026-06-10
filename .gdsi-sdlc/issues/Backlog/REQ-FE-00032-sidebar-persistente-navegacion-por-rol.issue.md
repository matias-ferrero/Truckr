---
tag: REQ-FE-00032
title: Sidebar de navegación persistente con ítems por rol (Carrier / Shipper)
priority: P2
status: backlog
created: '2026-06-09'
source: manual
source_url:
author: Claude Code
labels:
- REQ
- FE
- navigation
- ux
- app-shell
---

## Summary

Agregar una **barra lateral (sidebar) de navegación persistente** al app-shell del frontend, visible en todas las páginas de la aplicación, que exponga los ítems de navegación correspondientes al rol del usuario autenticado: el conjunto de páginas del **Carrier** (`/carrier/*`) y/o del **Shipper** (`/shipper/*`). Hoy la única navegación entre secciones es el `Header` superior (`frontend/src/components/Header.tsx`), que sólo expone un par de links condicionales del Carrier; el usuario no tiene un mapa lateral estable de las secciones disponibles para su rol. El sidebar debe coexistir con el Header dentro de los layouts por rol (`CarrierLayout` / `ShipperLayout`) y respetar usuarios con **doble rol** (carrier + shipper a la vez).

## Problem Statement

La app tiene una superficie de rutas grande por rol (vehículos, disponibilidad, ofertas, envíos, payouts para Carrier; cargas, matches, ofertas, envíos, pagos, dashboard para Shipper — ver `frontend/src/routes.tsx`), pero la navegación se apoya en un `Header` minimalista con sólo links sueltos del Carrier. No existe un componente de navegación lateral que:

- Liste de forma estable todas las secciones disponibles según el rol.
- Indique en qué sección está parado el usuario (estado activo).
- Esté presente de forma consistente en toda la app.

Esto obliga al usuario a navegar por URL o a depender de links contextuales dispersos. Falta un **app-shell** con sidebar que dé estructura y orientación.

## Expected Behavior

### Presencia y layout

- Un componente `Sidebar` montado dentro del app-shell autenticado, presente en **todas las páginas de la aplicación logueada** (rutas `/carrier/*`, `/shipper/*`, `/profile`, y demás vistas autenticadas).
- Coexiste con el `Header` actual (no lo reemplaza en este sprint). El layout resultante es: Header arriba + Sidebar a la izquierda + `Outlet` del contenido a la derecha.
- Integrado en los wrappers de layout existentes (`CarrierLayout`, `ShipperLayout` y el shell autenticado correspondiente en `frontend/src/routes.tsx`), no duplicado por página.

### Ítems por rol

- Si el usuario tiene rol **carrier** (`me?.roles.includes("carrier")`): grupo de ítems del Carrier → Vehículos (`/carrier/vehicles`), Disponibilidad (`/carrier/availability`), Ofertas de carga (`/carrier/cargo-offers`), Mis Envíos (`/carrier/shipments`), Pagos / Payouts (`/carrier/payouts`).
- Si el usuario tiene rol **shipper** (`me?.roles.includes("shipper")`): grupo de ítems del Shipper → Dashboard (`/shipper/dashboard`), Mis Cargas (`/shipper/cargos`), Mis Envíos (`/shipper/shipments`).
- Si el usuario tiene **ambos roles**: se muestran ambos grupos, visualmente separados/etiquetados por rol.
- Las rutas concretas y los labels deben confirmarse contra `frontend/src/routes.tsx` al implementar (la lista de arriba es el inventario actual de rutas raíz por sección, no rutas de detalle/edición).

### Estado activo

- El ítem correspondiente a la ruta actual se marca como activo (usar `NavLink` de React Router con su estado `isActive`).

### i18n

- Todos los labels resueltos vía bundle de contenido prototipo (p. ej. nuevo `sidebarContent.ts`), siguiendo el patrón vigente de `landingContent.ts` / `carrierContent.ts`. **Sin literales hardcoded** en el JSX (política de idioma del repo).

### Responsive

- En viewport angosto (mobile), el sidebar colapsa a un patrón apropiado (off-canvas con toggle, o se oculta delegando la navegación al Header). Definir el patrón mínimo y dejar el golden path cubierto.

## Current Behavior

No existe sidebar. La navegación entre secciones se hace exclusivamente vía el `Header` superior (`frontend/src/components/Header.tsx`), que sólo expone links condicionales del Carrier (inbox de ofertas, payouts) + notificaciones + widget de sesión. Cada layout por rol renderiza `Header + Outlet` sin navegación lateral.

## Reproduction Steps

1. Loguearse como Carrier o Shipper.
2. Navegar a cualquier página autenticada (p. ej. `/carrier/vehicles` o `/shipper/cargos`).
3. Observar que no hay barra lateral; la única navegación entre secciones es el Header superior, que no lista todas las secciones del rol.

## Impact

Afecta a todos los usuarios autenticados (Carriers y Shippers). Mejora la orientación y el descubrimiento de secciones; reduce la dependencia de navegación por URL o de links contextuales dispersos. No es bloqueante (el Header ofrece un workaround parcial), por eso P2.

## Technical Notes

- **Routing/layouts:** `frontend/src/routes.tsx` — wrappers `CarrierLayout`, `ShipperLayout`, `PublicLayout`, `AuthShell`. El sidebar se integra en los layouts autenticados; evaluar si la landing/login/`PublicLayout` quedan **fuera** (ver Open Questions).
- **Rol del usuario:** `frontend/src/auth/AuthContext.tsx` + hook `useCurrentUser()` (`frontend/src/auth/useCurrentUser.ts`); chequear `me?.roles` (`"carrier" | "shipper"`, puede tener ambos). Reutilizar la lógica de los guards `RequireCarrier` / `RequireShipper`.
- **Estado activo:** `NavLink` de React Router DOM (v6.26.2, ya instalado).
- **i18n:** no hay librería i18n aún; usar bundle de contenido prototipo (`sidebarContent.ts`) como `landingContent.ts`. Migrará a la librería real cuando aterrice.
- **Design system:** respetar tokens de `frontend/src/styles/global.css` y `frontend/DESIGN.md` (paleta two-voice: azul Open-Sky para Shipper, saffron/cream para Carrier; sin `#000`/`#fff` crudos, sin side-stripes `border-left/right > 1px`, sin gradient-text). El `stylelint` del repo bloquea esas infracciones — ver CLAUDE.md.
- **CSS:** nuevo archivo de estilos del sidebar (p. ej. `frontend/src/styles/sidebar.css`) usando variables de diseño existentes.
- **a11y:** envolver en landmark `<nav aria-label=...>`, navegación por teclado, focus states visibles, `aria-current` en el ítem activo. El `/audit` de impeccable bloquea merge si quedan findings (gate de UI pre-PR de CLAUDE.md).

## Open Questions

- **"En cualquier página":** ¿el sidebar también aparece en landing (`/`), `/login`, `/signup` y páginas públicas de perfil (`/carriers/:id`, `/shippers/:id`)? Esas vistas no tienen contexto de rol. Default propuesto: el sidebar se muestra en todas las páginas **autenticadas**; landing/login/públicas quedan fuera (no hay ítems de rol que mostrar). Confirmar con el PM.
- **Reemplazo del Header:** ¿el sidebar absorbe los links del Header (ofertas/payouts) y los quita de arriba, o coexisten? Default: coexisten en este sprint; la consolidación del Header es un follow-up.
- **Doble rol:** ¿agrupar por rol con encabezados, o un único listado fusionado? Default: dos grupos etiquetados.

## Related

- Related code: `frontend/src/routes.tsx`, `frontend/src/components/Header.tsx`, `frontend/src/auth/AuthContext.tsx`, `frontend/src/auth/useCurrentUser.ts`, `frontend/src/styles/global.css`, `frontend/DESIGN.md`
- [[REQ-FE-00022]] / [[REQ-FE-00023]] — definen los labels de "Mis Envíos" (Carrier/Shipper) y mencionan explícitamente una "entrada en el sidebar"; alinear nomenclatura.

## Acceptance Criteria

- [ ] Existe un componente `Sidebar` integrado en los layouts autenticados (`CarrierLayout` / `ShipperLayout`) en `frontend/src/routes.tsx`, presente en todas las páginas autenticadas sin duplicar markup por página.
- [ ] Usuario con rol carrier ve el grupo de ítems del Carrier; usuario con rol shipper ve el grupo del Shipper; usuario con ambos roles ve ambos grupos, etiquetados.
- [ ] Cada ítem enlaza a su ruta canónica (verificada contra `routes.tsx`) y marca el estado activo según la ruta actual (`NavLink` / `aria-current`).
- [ ] Todos los labels provienen de un bundle de contenido (`sidebarContent.ts`); cero literales hardcoded en el JSX.
- [ ] El sidebar usa tokens de `global.css` y cumple `frontend/DESIGN.md`; `just frontend-lint-css` (stylelint) pasa sin findings.
- [ ] Comportamiento responsive definido: en mobile el sidebar colapsa de forma usable (off-canvas con toggle o se oculta delegando al Header).
- [ ] a11y: navegación dentro de `<nav>` con label, navegable por teclado, focus states visibles, `aria-current` en el ítem activo; `/audit` sin findings bloqueantes.
- [ ] Cobertura: test de componente (Vitest) para render por rol y estado activo; spec E2E (Playwright) del golden path (login como Carrier → click ítem del sidebar → navega a la sección).
- [ ] Resuelta la Open Question de alcance ("en cualquier página" vs sólo autenticadas) con el PM antes de implementar.
