---
tag: INF-BE-00003
title: Agregar ActiveAdmin al backend
priority: P2
status: backlog
created: '2026-05-03'
source: manual
author: Claude Code
labels:
- INF
- BE
- admin
---

## Summary

Incorporar [ActiveAdmin](https://activeadmin.info/) al backend Rails para disponer de una UI administrativa lista para CRUD sobre los modelos del dominio (transportistas, clientes, viajes, pagos, etc.) sin tener que construir pantallas internas a mano.

## Problem Statement

El backend Rails está scaffoldeado pero no expone ninguna superficie de administración. A medida que aparezcan los primeros modelos del dominio (post `INF-GEN-00002`), el equipo necesitará:

- Crear/editar/eliminar registros de prueba para QA y demos.
- Inspeccionar datos productivos sin abrir Rails console.
- Operar un MVP con muy pocos usuarios donde un panel admin alcanza para soporte.

Construir un backoffice propio en este momento no aporta valor académico ni de producto. ActiveAdmin cubre el caso con configuración mínima.

## Expected Behavior

- `Gemfile` incluye `activeadmin` y sus dependencias requeridas (`devise`, `sassc-rails` o equivalente para los assets de AA en Rails 8.1).
- Generadores corridos: `rails g active_admin:install` deja `config/initializers/active_admin.rb`, migraciones para `AdminUser` y `ActiveAdmin::Comment`, ruta `mount ActiveAdmin::Engine => '/admin'`, y registros base en `app/admin/`.
- `db:migrate` aplica las migraciones nuevas; `db:seed` crea un admin inicial parametrizable por env (`SEED_ADMIN_EMAIL`, `SEED_ADMIN_PASSWORD`).
- `just backend-dev` (o equivalente) levanta Rails y `/admin` redirige a login y permite entrar con el seed.
- Compatibilidad con Propshaft (asset pipeline default de Rails 8) verificada — si AA requiere shim adicional, queda documentado.
- README del backend documenta cómo crear un admin y acceder al panel.

## Current Behavior

- `backend/Gemfile` no incluye `activeadmin` ni `devise`.
- No existen rutas montadas bajo `/admin`.
- No hay modelos `AdminUser` ni inicializador de ActiveAdmin.
- Cualquier alta/baja/modificación de datos requiere Rails console o seeds manuales.

## Reproduction Steps

N/A — feature/infra request, no es bug.

## Impact

- **Equipo**: desbloquea operaciones manuales sobre los modelos a medida que se implementen las primeras US.
- **QA / demos**: permite preparar escenarios de demo sin scripts ad-hoc.
- **Onboarding**: nuevos colaboradores ven el dominio listado en `/admin` sin leer todo el código.

## Technical Notes

- Stack actual: Rails `~> 8.1.3`, SQLite (Active Record), Propshaft, Importmap, Puma. ActiveAdmin 3.x soporta Rails 7+; verificar compatibilidad con Rails 8.1 al momento de instalar (puede requerir versión `>= 3.2`).
- Devise se introduce como dependencia de AA — definir si será también el sistema de auth para usuarios end-user (transportistas/clientes) o si quedará aislado al namespace admin. Recomendado: aislar `AdminUser` y dejar la auth de dominio como decisión separada.
- Decidir estrategia de assets: AA históricamente dependió de Sprockets. En Rails 8 con Propshaft puede ser necesario el plugin `cssbundling-rails` o configurar `activeadmin` con su pipeline propio.
- Seed del admin inicial debe leer credenciales de variables de entorno; nunca hardcodear en el repo.
- Considerar política CSRF / hosts permitidos para que `/admin` funcione tanto en dev (`localhost:3000`) como detrás del frontend (`:5173` proxy).

## Origin

Manual — solicitado por el owner del repo: "Add ActiveAdmin to the backend".

## Related

- Issue relacionado: `INF-GEN-00002` (bootstrap BE/FE/docs/AI harness) — define el contexto del backend recién scaffoldeado.
- Paths: `backend/Gemfile`, `backend/config/routes.rb`, `backend/config/initializers/`, `backend/db/migrate/`, `backend/db/seeds.rb`, `backend/app/admin/`.

## Acceptance Criteria

- [ ] `activeadmin` (y `devise`) agregados al `Gemfile` con versiones compatibles con Rails 8.1; `bundle install` corre limpio.
- [ ] `rails g active_admin:install` ejecutado; archivos generados commiteados (initializer, migraciones, registros base).
- [ ] `bin/rails db:migrate` aplica las migraciones de `AdminUser` y `ActiveAdmin::Comment` sin errores.
- [ ] `db:seed` crea un admin inicial leyendo `SEED_ADMIN_EMAIL` / `SEED_ADMIN_PASSWORD`; documentado el fallback para entornos de dev.
- [ ] `/admin` accesible vía `just backend-dev`, login funcional con el seed.
- [ ] Assets de ActiveAdmin se sirven correctamente bajo Propshaft (o shim documentado si se requiere).
- [ ] `backend/README.md` (o `CLAUDE.md` correspondiente) actualizado con sección "Admin panel": cómo crear admin, dónde se registran nuevos resources (`app/admin/<resource>.rb`).
- [ ] Specs RSpec mínimos: smoke test que verifica que `/admin` redirige a login (200/302) y que un `AdminUser` válido puede iniciar sesión.
- [ ] Conventional Commits respetados (`feat(backend): add ActiveAdmin admin panel` o similar).
