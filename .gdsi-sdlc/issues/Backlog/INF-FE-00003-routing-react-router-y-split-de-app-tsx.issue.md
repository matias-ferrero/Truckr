---
tag: INF-FE-00003
title: Routing (React Router) + split de App.tsx en estructura por feature
priority: P1
status: backlog
created: '2026-05-03'
source: manual
author: Claude Code
labels:
- INF
- FE
- routing
- refactor
- foundation
---

## Summary

Introducir React Router en el frontend, dividir `App.tsx` (~620 LOC) en módulos por feature, y dejar la estructura de carpetas lista para que las pantallas que vienen (auth, search, offer, trip, etc.) se dropeen sin tener que decidir architectura cada vez. Pre-requisito de cualquier issue que agregue una segunda ruta.

## Problem Statement

Hoy `frontend/src/App.tsx` es un único archivo ~620 LOC con la landing + el quote-form local-state. Cualquier issue que agregue una pantalla nueva (registro, login, search, offer, etc.) va a:
1. Inflar más `App.tsx`, o
2. Inventar su propio routing ad-hoc.

El roadmap (`docs/onboarding/06-roadmap.md`) ya identifica esto como tech debt prioritaria: "Single-file App.tsx (~620 LOC) needs splitting before a second route lands."

## Expected Behavior

### Routing
- React Router v6 instalado vía `frontend/deno.json` imports.
- Rutas iniciales:
  - `/` — landing (lo que hoy está en App.tsx).
  - `/registro`, `/login` — placeholders (las cubre `REQ-BE-00023`).
  - `/buscar-transportistas` — placeholder (la cubre `REQ-FE-00006`).
  - `/transportista` — placeholder home del rol Carrier.
  - `/expedidor` — placeholder home del rol Shipper.
- 404 con un componente NotFound básico.

### Estructura de carpetas
- `frontend/src/`:
  - `pages/` — un componente por ruta top-level (`pages/Landing.tsx`, `pages/Login.tsx`, etc.).
  - `features/` — módulos por bounded context (`features/auth/`, `features/search/`, `features/offer/`, etc.). Cada feature contiene sus componentes, hooks, types, y tests.
  - `components/` — componentes reutilizables cross-feature (Button, Input, Card, Modal, …).
  - `lib/` — utilidades agnósticas (api client, fetcher, schema validators con zod, etc.).
  - `hooks/` — hooks globales (`useCurrentUser`, `useToast`, …).
  - `app/` — composición top-level: `App.tsx` (router + providers) + `routes.tsx` (definición de rutas).

### Split de App.tsx actual
- La landing se mueve a `pages/Landing.tsx`.
- El quote-form local-state se mueve a `features/quote-form/QuoteForm.tsx` (placeholder, será reemplazado por US7 cuando exista).

> Note: bajo el rename `Quote → CargoOffer`, este folder pasará a llamarse `features/cargo-offer/` (y el componente `CargoOfferForm.tsx`). El rename de la carpeta y del componente se hace en el PR de implementación de US7, no en este issue de bootstrap de routing — acá se preserva `quote-form` como placeholder para que el grep siga encontrándolo.
- Los datos hardcoded de la landing (`landingContent.ts`) se mueven a `features/landing/content.ts`.

### Providers
- `App.tsx` queda chico (~30 LOC): wrapping con `BrowserRouter`, eventual `QueryClientProvider` (TanStack Query) si se decide ahora, `AuthProvider` (placeholder hasta `REQ-BE-00023`), `Toaster`.
- Decisión sobre data-fetching library (TanStack Query vs raw fetch + custom hooks) registrada en este issue (recomendado: TanStack Query — caching y reval gratis, encaja con el patrón de "schema validation con zod" del HLD).

### Tests
- Vitest tests existentes siguen pasando.
- Smoke E2E (Playwright) ejerce: `/`, `/registro`, `/login`, `/buscar-transportistas`, `/404`.

## Technical Notes

- **React Router v6**: `createBrowserRouter` + `RouterProvider` (no nested `<Routes>` JSX) para que sea fácil agregar loaders después.
- **No code-splitting agresivo todavía**: ruta única chunk. Cuando crezca, dividir con `lazy()`.
- **Feature folder convention**: cada feature exporta su API pública en un `index.ts`. Los componentes internos no se importan cross-feature directamente.
- **Routing config**: rutas centralizadas en `app/routes.tsx` (no esparcidas). Permite que un sidebar/footer lea los paths sin magic strings.
- **Types**: tipos de rutas con union string literal o constantes (`AppRoutes.LOGIN`).

## Related

- Padre: ninguno.
- Bloquea: `REQ-BE-00023` (auth UI), `REQ-FE-00006/7/8` (search), todos los issues de FE feature.
- Mencionado como debt en `docs/onboarding/06-roadmap.md`.

## Acceptance Criteria

- [ ] React Router v6 instalado y configurado.
- [ ] Estructura de carpetas `pages/features/components/lib/hooks/app/` aplicada.
- [ ] `App.tsx` quedó bajo 50 LOC (router + providers).
- [ ] Landing + quote-form mudados a `pages/Landing.tsx` y `features/quote-form/QuoteForm.tsx` sin regresiones visuales.
- [ ] Rutas placeholder para registro, login, buscar-transportistas, transportista home, expedidor home.
- [ ] 404 component cubre rutas no matcheadas.
- [ ] Decisión data-fetching documentada (en `frontend/CLAUDE.md` o equivalente).
- [ ] Vitest sigue verde.
- [ ] Playwright smoke ejerce las 5+ rutas placeholder.
- [ ] Conventional commit: `refactor(frontend): introduce router and feature-based structure`.
