---
tag: REQ-BE-00020
title: Implementar contexto Identity — migraciones + modelos AR (User, Carrier, Shipper,
  Vehicle)
priority: P0
status: backlog
created: '2026-05-03'
source: manual
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/100
author: Claude Code
github_issue: 100
github_project_item: PVTI_lAHOAm1mPc4BWhiVzgrtCXQ
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-04T02:25:26.508326+00:00Z
labels:
- REQ
- BE
- domain-model
- identity
- foundation
---

## Summary

Llevar el draft de `REQ-BE-00005` a código real: primeras migraciones, modelos ActiveRecord, validaciones, seeds, factories y exposición vía ActiveAdmin (read-only). Este issue **desbloquea todo** el resto del backend feature work — sin User/Carrier/Shipper/Vehicle persistidos no hay forma de implementar auth, búsqueda, ofertas ni nada que dependa de identidad.

## Problem Statement

`REQ-BE-00005` (en review) entrega solo el **diseño** del modelo de dominio: ADRs, ERDs, spec ready-to-migrate. No hay todavía una sola migración escrita ni un modelo poblado en `backend/app/models/`. Cualquier feature issue que mencione `Carrier.where(...)` o `current_user` está bloqueada hasta que esto exista.

## Expected Behavior

- Migraciones aplicadas para: `users`, `carriers`, `shippers`, `vehicles` (un Vehicle por Carrier — la relación 1:N viene en `REQ-BE-00010`).
- Modelos AR con: validaciones, asociaciones, scopes básicos, predicados de rol (sin booleans desnormalizados — usar la presencia de la fila de `carrier`/`shipper` como estado de rol, según la regla del proyecto).
- `User` con `has_secure_password` precargado (la lógica de auth/sesiones es responsabilidad de `REQ-BE-00023`, pero el campo `password_digest` y la columna existen desde acá).
- ActiveAdmin (de `INF-BE-00003`) expone `User`, `Carrier`, `Shipper`, `Vehicle` en modo read-only para inspección.
- Seeds (`db/seeds.rb`) con un puñado de fixtures que sirvan para demos: 3 Users, 2 Carriers, 2 Shippers, 2 Vehicles.
- Factories (`FactoryBot`) para los 4 modelos.
- Specs de modelo cubren: validaciones, asociaciones, predicados de rol.
- Glosario y `domain-model.md` actualizados si emergen decisiones nuevas durante la implementación que corrijan al draft.

## Technical Notes

- **Naming**: tablas y columnas en inglés. `users`, `carriers`, `shippers`, `vehicles`.
- **PK strategy**: la decisión sale del ADR de `REQ-BE-00005`. Aplicar consistentemente.
- **State**: `Carrier` y `Shipper` son entidades separadas con FK a `users.id`. Un mismo human puede ser ambos (dos filas, una en cada tabla).
- **Soft-delete**: aplicar la decisión del ADR. Si soft-delete, agregar `discarded_at` con un concern.
- **No exponer endpoints públicos todavía**: los CRUD aplican vía ActiveAdmin. Los endpoints `/api/...` que tocan estas entidades vienen con sus respectivos feature issues (auth, búsqueda, etc.).

## Related

- Padre: `REQ-BE-00005` (diseño — debe estar mergeado).
- Bloquea: `REQ-BE-00023` (auth), `REQ-BE-00009/10` (vehicle), `REQ-BE-00021` (marketplace), prácticamente todos los REQ feature issues.

## Acceptance Criteria

- [ ] Migraciones para `users`, `carriers`, `shippers`, `vehicles` aplicadas; `db:schema:dump` actualizado.
- [ ] Modelos AR con validaciones + asociaciones + predicados de rol (sin columnas booleanas desnormalizadas).
- [ ] `password_digest` + `has_secure_password` configurado en `User`.
- [ ] ActiveAdmin lista los 4 modelos en read-only.
- [ ] Seeds + factories cargan sin error (`bin/rails db:seed`).
- [ ] Model specs cubren validaciones + asociaciones (≥80% coverage sobre `app/models/`).
- [ ] CHANGELOG entry no requerido (issue interno; lo cubre el feat de auth/feature posterior).
- [ ] Identifiers en inglés.
