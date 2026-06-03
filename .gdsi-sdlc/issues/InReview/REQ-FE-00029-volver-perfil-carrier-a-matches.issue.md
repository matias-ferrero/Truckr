---
tag: REQ-FE-00029
title: Link "Volver a la búsqueda" del perfil del Carrier a la pantalla de matches (solo Shipper)
priority: P3
status: in_review
created: '2026-05-31'
plan: docs/features/REQ/REQ-FE-00029/REQ-FE-00029-volver-perfil-carrier-a-matches.plan.md
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/289
author: Claude Code
github_issue: 289
github_repo: tcorzo/fiuba-gestion-tp
labels:
- REQ
- FE
- shipper
- navigation
- ux
---

## Summary

Cuando un **Shipper** llega al perfil de un Carrier (`/carriers/:id`) desde la pantalla de matches de una carga (`/shipper/cargos/:cargoId/matches`, botón **"Ver perfil"** de `MatchCard`), no tiene forma explícita de volver a la lista de matches. Hoy el único back-link de la página (copy **"Volver a la búsqueda"**, key `backToSearch` en `publicContent.ts:12`) apunta a `/` y **solo aparece en el estado *not found***; la vista del perfil cargado no tiene ningún back-link. Agregar un link en la vista del perfil cargado que devuelva al Shipper a la pantalla de matches de la carga desde la que entró, **reusando la misma copy `backToSearch` ("Volver a la búsqueda")** del estado not-found (sin clave i18n nueva). Solo se muestra para usuarios Shipper que llegaron por ese flujo; no debe aparecer para el entrante público anónimo ni para Carriers.

## Problem Statement

`CarrierDetail` (`frontend/src/pages/public/CarrierDetail.tsx`) es una ruta **pública** (`/carriers/:id`) con múltiples puntos de entrada:

- Búsqueda pública de transportistas (entrante anónimo).
- Botón "Ver perfil" de `MatchCard` dentro de la pantalla de matches del Shipper.

Hoy el único back-link de la página apunta a `/` con copy "Volver a la búsqueda" (`publicContent.ts:12`, render en `CarrierDetail.tsx:79-95`), y solo aparece en el estado *not found*. El Shipper que entró desde los matches y quiere volver a comparar candidatos depende del botón "atrás" del navegador. Falta un affordance explícito hacia `/shipper/cargos/:cargoId/matches`.

El problema de diseño es que `CarrierDetail` **no conoce el `cargoId`** de origen: la navegación actual es `to={`/carriers/${match.carrier.id}`}` (`MatchCard.tsx:92-98`), sin contexto. Para construir la URL de retorno hay que propagar de dónde vino el usuario.

## Expected Behavior

- Cuando un Shipper autenticado abre `/carriers/:id` **desde** la pantalla de matches de una carga, la vista de perfil del Carrier muestra, en la parte superior, un link que navega a `/shipper/cargos/:cargoId/matches` (la misma carga desde la que se hizo click en "Ver perfil").
- El link **reusa la clave i18n existente `backToSearch` ("Volver a la búsqueda")** (`publicContent.ts:12`) — la misma que el estado *not found*. No se crea una clave nueva. Visualmente sigue el patrón `.backLink` (`frontend/src/styles/shipper.css:247-258`).
- El link **no** se renderiza para:
  - Entrante público/anónimo (sin rol Shipper).
  - Usuarios sin contexto de carga de origen (entraron por la búsqueda pública).
  - Carriers viendo el perfil.

## Current Behavior

El perfil del Carrier solo ofrece "Volver a la búsqueda" → `/` (y solo en el estado *not found*). El Shipper que vino de los matches no tiene retorno directo a `/shipper/cargos/:cargoId/matches`.

## Reproduction Steps

1. Loguearse como Shipper.
2. Ir a una carga propia y abrir su pantalla de matches: `/shipper/cargos/:cargoId/matches`.
3. En una `MatchCard`, hacer click en **"Ver perfil"** → navega a `/carriers/:id`.
4. Observar que no hay un link "← Volver" a la pantalla de matches; el único camino de retorno es el botón atrás del navegador.

## Impact

Shippers comparando candidatos en la pantalla de matches. Severidad baja (P3): hay workaround trivial (botón atrás del navegador), pero el affordance explícito reduce fricción en el flujo de selección de transportista, que es central para el Shipper.

## Technical Notes

- **Propagar el origen** — `MatchCard.tsx:92-98` debe pasar contexto del `cargoId` al navegar. Dos opciones:
  - **React Router `state`** en el `<Link>`: `to={`/carriers/${match.carrier.id}`} state={{ backToMatches: `/shipper/cargos/${cargo.id}/matches` }}`. `CargoMatches` ya tiene el `cargo.id` (`CargoMatches.tsx`, back-link a `/shipper/cargos/${cargo.id}`); pasarlo por prop a `MatchCard`.
  - **Query param** `?from=/shipper/cargos/:cargoId/matches`. Más visible/compartible pero ensucia la URL pública.
  - Preferir `state` salvo que se quiera deep-linkability. Decidir en planning.
- **Render condicional en `CarrierDetail`** — la vista ya consume rol via `useContext(AuthContext)` (`CarrierDetail.tsx:36`); `me.roles` incluye `"shipper"` (`AuthContext.tsx`, `RequireShipper.tsx:19`). Mostrar el link solo si: el usuario es Shipper **y** existe contexto de origen (`location.state?.backToMatches` o el query param). Sin ambas condiciones → no renderizar.
- **i18n — reusar `backToSearch`** — el link usa la clave existente `t.backToSearch` ("Volver a la búsqueda", `publicContent.ts:12`), la misma del estado *not found*. **No** crear una clave nueva. Sin literales españoles en JSX (CLAUDE.md, política de idioma).
- **CSS** — reutilizar la clase `.backLink` (`styles/shipper.css:247-258`). No agregar side-stripes ni raw hex (stylelint hook).
- **Posición** — colocar el link arriba del hero del perfil **en la vista del perfil cargado** (el `return` final, alrededor de `CarrierDetail.tsx:121-124`, antes del `<header className="carrierHero">`), consistente con `CargoMatches`/`CargoDetail`. Hoy esa vista no tiene back-link.
- **No romper el estado *not found*** — el link "Volver a la búsqueda" → `/` del bloque `notFound` (`CarrierDetail.tsx:86-91`) se mantiene tal cual. El nuevo link es aditivo, vive en la rama del perfil cargado y es condicional (Shipper + contexto de origen).

## Related

- Pantalla de matches: `frontend/src/features/cargo/CargoMatches.tsx`.
- Botón "Ver perfil": `frontend/src/features/cargo/MatchCard.tsx:92-98`; copy en `frontend/src/features/cargo/cargosContent.ts:205` (`viewCarrierDetail: "Ver perfil"`).
- Perfil del Carrier: `frontend/src/pages/public/CarrierDetail.tsx` (ruta `/carriers/:id`, `routes.tsx:147-151`).
- Copy del perfil: `frontend/src/pages/public/publicContent.ts:12` (`backToSearch`).
- Patrón back-link: `.backLink` en `frontend/src/styles/shipper.css:247-258`; ejemplos en `CargoMatches.tsx:123-125`, `CargoDetail.tsx:133`.
- Auth/rol: `frontend/src/auth/AuthContext.tsx`, `frontend/src/auth/useCurrentUser.ts`, `frontend/src/auth/RequireShipper.tsx`.
- Política: [`CLAUDE.md`](../../../CLAUDE.md) (idioma, design-system/lint, pre-PR UI quality gate).

## Notas de implementación para el assignee

- **PR title format** — prefijo conventional obligatorio (`feat(cargo): ...` o `feat(shipper): ...`), sin bracket `[REQ-FE-00029]` en el título. Referenciar el TAG en el cuerpo (`Closes #N`) y en el branch name.
- **`gh pr create --assignee @me`**.
- **No tocar `.gdsi-sdlc/config.json`.**
- **Pre-PR UI quality gate** (CLAUDE.md): `/critique` → `/polish` → `/audit`. Luego `just lint`, `just frontend-test-coverage` (80%), `just frontend-test-e2e`.

## Acceptance Criteria

- [ ] **AC1** — Un Shipper que abre el perfil de un Carrier desde la pantalla de matches (botón "Ver perfil") ve, en la parte superior de la vista del perfil cargado, un link con la copy **"Volver a la búsqueda"**.
- [ ] **AC2** — El link navega a `/shipper/cargos/:cargoId/matches`, devolviendo al Shipper a la pantalla de matches de la **misma** carga desde la que entró.
- [ ] **AC3** — El link **no** se muestra para el entrante público/anónimo ni para usuarios sin contexto de carga de origen.
- [ ] **AC4** — El link **no** se muestra para usuarios con rol Carrier.
- [ ] **AC5** — La copy del link **reusa la clave i18n existente `backToSearch`** (`publicContent.ts:12`); no se crea una clave nueva ni hay literales españoles hardcoded en JSX.
- [ ] **AC6** — El link usa la clase `.backLink` existente; sin nuevos raw hex / side-stripes / gradient-text (`just frontend-lint-css` limpio).
- [ ] **AC7** — El link "Volver a la búsqueda" → `/` del estado *not found* (`CarrierDetail.tsx:86-91`) sigue intacto. El nuevo link es aditivo y vive solo en la vista del perfil cargado (que hoy no tiene back-link).

### Tests requeridos

- [ ] Vitest — `CarrierDetail` renderiza el link "Volver a la búsqueda" hacia `/shipper/cargos/:cargoId/matches` cuando hay contexto de matches y el usuario es Shipper.
- [ ] Vitest — el link NO se renderiza para entrante anónimo / sin contexto de origen.
- [ ] Vitest — el link NO se renderiza para rol Carrier.
- [ ] Vitest — `MatchCard` propaga el contexto del `cargoId` al navegar a "Ver perfil".
- [ ] Playwright e2e — golden path: Shipper → matches → "Ver perfil" → "Volver a la búsqueda" → regresa a la pantalla de matches de la carga.

## Decisiones abiertas para planning

1. **Mecanismo de propagación del origen** — React Router `state` vs query param (`?from=...`). Recomendado `state`; confirmar en planning.
2. ~~**Copy exacto**~~ — cerrado: reusar la clave `backToSearch` ("Volver a la búsqueda"), sin clave i18n nueva.
