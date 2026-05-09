---
tag: INF-BE-00001
title: Reestructurar por funcionalidades (NO por pantallas/usuarios)
priority: P2
status: ready
plan: docs/features/INF/INF-BE-00001/INF-BE-00001-reestructurar-wbs.plan.md
created: '2026-04-18'
source: github
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/50
author: ''
github_issue: 50
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-03T12:54:04.035216+00:00Z
labels:
- correction
- artifact
- INF
- BE
assignees:
- FernandoYu
---

## Estado actual
- Casi todo el desarrollo está en la rama 1
- Desbalanceado — falta uniformidad

## Cambio requerido
Reorganizar por funcionalidades (no por pantallas/usuarios)

## Tareas
1. **Redimensionar completamente** el WBS
2. **Eliminar rama 1** (la que tiene casi todo) y distribuir su contenido
3. **Reorganizar por funcionalidades** principales:
   - Autenticación/Login
   - Búsqueda y cotización
   - Gestión de viajes/órdenes
   - Seguros
   - Pagos
   - Calificaciones/Reseñas
   - etc.
4. **Descomponer hasta nivel estimable**
   - Cada tarea debe poder ser estimada
   - Cada tarea debe poder ser dimensionada
5. **Uniformidad**: El WBS debe quedar mucho más balanceado
   - Ramas similares en tamaño
   - Distribución clara del esfuerzo

## Notas
- Mejor descomponer de más que de menos
- El WBS es donde está casi el desarrollo completo
