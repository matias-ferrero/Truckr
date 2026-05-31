# REQ-FE-00029: Link "Volver a la búsqueda" del perfil del Carrier a la pantalla de matches (solo Shipper)

| Field | Value |
|-------|-------|
| **Tag** | REQ-FE-00029 |
| **Title** | Link "Volver a la búsqueda" del perfil del Carrier a la pantalla de matches (solo Shipper) |
| **Priority** | P3 |
| **Status** | READY |
| **Created** | 2026-05-31 |
| **Updated** | 2026-05-31 |
| **Author** | Claude Code |
| **Depends On** | Ninguna. FE-only, sin cambios de backend ni de tipos de API. |
| **Decision Doc** | N/A — decisión abierta única (mecanismo de propagación) cerrada inline en este plan. |
| **Selected Approach** | Single PR, FE-only. Propagar el origen vía **React Router `state`** (no query param) — `MatchCard` ya usa `state={{ window: match }}` en su link de cuerpo, así que es el patrón establecido del mismo archivo. `CarrierDetail` lee `location.state` + rol Shipper desde `AuthContext` y renderiza, **solo en la rama del perfil cargado**, un `.backLink` que reusa la clave i18n existente `backToSearch`. |

---

## 1. Problem Statement

El issue body (Backlog) tiene el spec completo. Resumen del estado al arrancar:

- El botón **"Ver perfil"** de `MatchCard` (`frontend/src/features/cargo/MatchCard.tsx:92-98`) navega a `/carriers/:id` **sin contexto** del `cargoId` de origen.
- `CarrierDetail` (`frontend/src/pages/public/CarrierDetail.tsx`) es ruta **pública** con múltiples entradas (búsqueda pública + matches). Su único back-link ("Volver a la búsqueda" → `/`, key `backToSearch`) vive **solo en el estado `notFound`** (`CarrierDetail.tsx:86-91`). **La vista del perfil cargado no tiene ningún back-link.**
- Un Shipper que entró desde los matches no tiene retorno explícito a `/shipper/cargos/:cargoId/matches` — depende del botón atrás del navegador.

Objetivo: agregar, **solo en la vista del perfil cargado y solo para Shippers que llegaron desde los matches**, un link que vuelva a `/shipper/cargos/:cargoId/matches`, reusando la copy/clave existente `backToSearch`.

## 2. Solution Design

### 2.1 Decisión de propagación del `cargoId` — React Router `state`

Cerrado a favor de **React Router `state`** (vs query param `?from=...`):

- `MatchCard` **ya** usa `state={{ window: match }}` en su link de cuerpo (`MatchCard.tsx:52-57`). Sumar `state` al link "Ver perfil" es consistente con el archivo.
- `CreateOfferPage` ya lee `location.state as NavState` (`CreateOfferPage.tsx:61-64`) — patrón de lectura establecido a reusar.
- Mantiene la URL pública `/carriers/:id` limpia (sin ensuciarla con query de navegación interna del Shipper).
- Trade-off aceptado: el back-link **no** sobrevive a un refresh ni a un deep-link directo a `/carriers/:id` — correcto, porque justamente solo debe aparecer cuando el usuario llegó desde los matches en esa sesión de navegación.

### 2.2 Detección de rol Shipper

`CarrierDetail` ya consume `useContext(AuthContext)` (`CarrierDetail.tsx:36`). `Me.roles` es `Role[]` (`AuthContext.tsx:12`). Condición de render: `auth?.me?.roles?.includes("shipper")`.

### 2.3 Condición de render del nuevo link

El link se renderiza **solo si ambas** se cumplen:

1. `location.state?.backToMatches` es un string no vacío (llegó desde matches), **y**
2. el usuario autenticado tiene rol `"shipper"`.

Sin las dos → no se renderiza (público anónimo, entrada por búsqueda pública, o rol Carrier). Vive dentro de la rama `return` del perfil cargado (`CarrierDetail.tsx:121-181`), arriba del `<header className="carrierHero">`.

### 2.4 Copy e i18n

Reusa `t.backToSearch` ("Volver a la búsqueda", `publicContent.ts:12`). **No** se crea clave nueva. Sin literales en JSX.

### 2.5 Estilo

Clase existente `.backLink` (`styles/shipper.css:247-258`). Sin raw hex / side-stripes / gradient-text.

---

## 3. Implementation Tasks

| # | Task | Status | Files |
|---|------|--------|-------|
| 1 | Pasar `state={{ backToMatches }}` en el link "Ver perfil" de `MatchCard` | Pending | `frontend/src/features/cargo/MatchCard.tsx` |
| 2 | En `CarrierDetail`: leer `useLocation()` + rol; renderizar `.backLink` condicional en la rama del perfil cargado | Pending | `frontend/src/pages/public/CarrierDetail.tsx` |
| 3 | Tests Vitest (render condicional + propagación) | Pending | `frontend/src/pages/public/CarrierDetail.test.tsx`, `frontend/src/features/cargo/MatchCard.test.tsx` |
| 4 | Test Playwright e2e (golden path ida y vuelta) | Pending | `frontend/e2e/` (spec nuevo o existente de matches) |
| 5 | Quality gate: `/critique` → `/polish` → `/audit`, lint, coverage, e2e | Pending | — |

---

## 4. Code Changes

### 4.1 File: `frontend/src/features/cargo/MatchCard.tsx`

**Purpose**: propagar la URL de retorno a los matches al navegar a "Ver perfil". `cargoId` ya es prop.

```tsx
<div className="cardActions matchCardActions">
    <Link
        className="button buttonGhost"
        to={`/carriers/${match.carrier.id}`}
        state={{ backToMatches: `/shipper/cargos/${cargoId}/matches` }}
    >
        {t.viewCarrierDetail}
    </Link>
</div>
```

### 4.2 File: `frontend/src/pages/public/CarrierDetail.tsx`

**Purpose**: leer el contexto de origen + rol, y renderizar el back-link solo en la vista cargada.

```tsx
// imports
import { Link, useLocation, useParams } from "react-router-dom";

// dentro del componente, junto a los otros hooks
const location = useLocation();
const backToMatches = (location.state as { backToMatches?: string } | null)?.backToMatches;
const isShipper = auth?.me?.roles?.includes("shipper") ?? false;
const showBackToMatches = isShipper && !!backToMatches;

// dentro del `return` del perfil cargado (status === "ready"),
// arriba del <header className="carrierHero">:
{showBackToMatches && (
    <Link to={backToMatches} className="backLink">
        {t.backToSearch}
    </Link>
)}
```

Notas:
- `useLocation` se agrega al import existente de `react-router-dom` (línea 2).
- El estado `notFound` (`CarrierDetail.tsx:86-91`) **no se toca** — su link "Volver a la búsqueda" → `/` queda intacto (AC7).
- `backToMatches` se valida como string truthy; no se confía ciegamente en `location.state`.

---

## 5. Testing

### Unit Tests (Vitest)

**`CarrierDetail.test.tsx`** (nuevo o extendido):
- Perfil cargado + `location.state.backToMatches` presente + `me.roles` incluye `"shipper"` → renderiza el link con copy "Volver a la búsqueda" y `href` = `/shipper/cargos/:cargoId/matches`.
- Perfil cargado + sin `location.state` (entrante público/anónimo, `me = null`) → el link NO se renderiza (el resto del perfil sí).
- Perfil cargado + `me.roles = ["carrier"]` (aunque hubiera state) → el link NO se renderiza.
- Estado `notFound` → sigue renderizando el link "Volver a la búsqueda" → `/` (regresión AC7).

> Montar con `MemoryRouter` + `initialEntries` con `state`, y envolver en un `AuthContext.Provider` mock (patrón ya usado en `MatchCard.test.tsx` y `RequireShipper.test.tsx`).

**`MatchCard.test.tsx`** (extendido):
- El link "Ver perfil" navega a `/carriers/:id` con `location.state.backToMatches === "/shipper/cargos/:cargoId/matches"` (el archivo ya inspecciona `useLocation()` en sus tests, líneas 41+).

### Integration / E2E (Playwright)

- Golden path: login Shipper → `/shipper/cargos/:id/matches` → click "Ver perfil" → en el perfil, click "Volver a la búsqueda" → vuelve a `/shipper/cargos/:id/matches`.

---

## 6. Acceptance Criteria

> Textuales del issue body (Backlog).

- [ ] **AC1** — Shipper desde matches ("Ver perfil") ve, arriba de la vista del perfil cargado, un link con copy "Volver a la búsqueda".
- [ ] **AC2** — El link navega a `/shipper/cargos/:cargoId/matches` (la misma carga de origen).
- [ ] **AC3** — No se muestra para entrante público/anónimo ni sin contexto de origen.
- [ ] **AC4** — No se muestra para rol Carrier.
- [ ] **AC5** — Reusa la clave i18n `backToSearch`; sin clave nueva ni literales hardcoded.
- [ ] **AC6** — Usa `.backLink`; `just frontend-lint-css` limpio.
- [ ] **AC7** — El link del estado `notFound` (`CarrierDetail.tsx:86-91`) intacto.
- [ ] Todos los tests passing; coverage ≥ 80%.

---

## 7. Files Summary

### New Files
| File | Description |
|------|-------------|
| `frontend/src/pages/public/CarrierDetail.test.tsx` | Tests de render condicional del back-link (si no existe ya). |

### Modified Files
| File | Changes |
|------|---------|
| `frontend/src/features/cargo/MatchCard.tsx` | `state={{ backToMatches }}` en el link "Ver perfil". |
| `frontend/src/pages/public/CarrierDetail.tsx` | `useLocation()` + detección de rol; `.backLink` condicional en la rama del perfil cargado. |
| `frontend/src/features/cargo/MatchCard.test.tsx` | Assert de propagación del `state`. |
| `frontend/e2e/*` | Spec e2e del golden path ida y vuelta. |

---

## 8. Notas para el assignee

- **PR title**: prefijo conventional (`feat(cargo): ...`), sin bracket `[REQ-FE-00029]`. `Closes #289` en el cuerpo.
- **`gh pr create --assignee @me`**.
- **No tocar `.gdsi-sdlc/config.json`.**
- **Pre-PR UI quality gate** (CLAUDE.md): `/critique` → `/polish` → `/audit`, luego `just lint`, `just frontend-test-coverage` (80%), `just frontend-test-e2e`.
- Issue pequeño (S, riesgo bajo): 2 archivos de producción, FE-only, sin backend.
