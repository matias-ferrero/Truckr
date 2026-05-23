---
tag: REQ-FE-00021
title: Dashboard post-login + navegación global
priority: P1
status: done
created: '2026-05-10'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/146
author: Claude Code
github_issue: 146
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-11T22:38:11.191740+00:00Z
labels:
- FE
- REQ
---

**TAG**: REQ-FE-00021
**Sprint**: 1 (committed)
**Owner**: @LucasDondo

## Summary

Pantalla de aterrizaje post-login (rol-aware) más el chrome de navegación global (header persistente con links rol-aware). Es la pieza de UX que conecta todas las features de Sprint 1 entre sí — sin esto, las pantallas existen como islas y el demo se siente fragmentado.

## Why this matters

Sprint 1 produce seis features visibles (Auth, Vehicle Reg, TransportWindow publishing, TransportWindow search, Carrier profile page, AWS deploy) pero ninguna las conecta. Después de loguearse el usuario no tiene a dónde ir, no hay header con links, y cada pantalla es alcanzable sólo si conocés la URL de memoria. El dashboard arregla eso.

## Two deliverables

**1. Sketch (semana 1, entregable obligatorio)**

Lucas produce una sketch en papel / whiteboard / Figma que define:

- Qué cards/tiles aparecen en el dashboard del Carrier y en el del Shipper
- Qué links viven en el header (siempre vs sólo cuando hay sesión)
- Qué hace `/` cuando el usuario no está logueado
- Estados vacíos para placeholders

La sketch se circula a @bcespedes, @matias-ferrero, @FrancoRicciardo, @tcorzo para sign-off antes de fin de semana 1. **A partir de ahí las features de los demás se diseñan contra ese mapa.**

**2. Implementación (semana 2+, después de Auth BE)**

- Carrier dashboard con cards: Mi flota, Mis ventanas publicadas, Ofertas recibidas (placeholder), Editar perfil
- Shipper dashboard con cards: Buscar transporte (acción primaria), Mis ofertas hechas (placeholder), Editar perfil
- Header global persistente, avatar + menú de sesión
- Tests Vitest + Playwright

## Dependencies

- **Bloqueante para implementar**: REQ-BE-00023 (Auth — `current_user`, role predicates)
- **Foundation FE provista por PR #144**: React Router, ` pages/` split, ` RequireCarrier`
- **Features que el dashboard linkea**: REQ-BE-00009 + REQ-BE-00010 (en PR #144), REQ-FE-00016, REQ-FE-00006, REQ-FE-00012, REQ-FE-00017 (placeholder)

## Authoritative file

[\` .gdsi-sdlc/issues/Backlog/REQ-FE-00021-dashboard-y-navegacion-global.issue.md\` ](../tree/chore/sprint-1-plan/.gdsi-sdlc/issues/Backlog/REQ-FE-00021-dashboard-y-navegacion-global.issue.md) — full body, expected behavior, acceptance criteria.

## Related

- Sprint plan: [\` docs/features/SPRINT-1-PLAN.md\` ](../tree/chore/sprint-1-plan/docs/features/SPRINT-1-PLAN.md)
- Sprint 1 PR: #140
