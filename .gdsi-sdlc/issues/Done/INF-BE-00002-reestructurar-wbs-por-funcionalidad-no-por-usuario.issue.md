---
tag: INF-BE-00002
title: Reestructurar WBS por funcionalidad (no por usuario)
priority: P2
status: done
created: '2026-04-02'
source: github
source_url: https://github.com/tcorzo/fiuba-gestion-tp/issues/25
author: ''
github_issue: 25
github_repo: tcorzo/fiuba-gestion-tp
last_synced: 2026-05-03T12:54:04.036188+00:00Z
labels:
- correction
- artifact
- INF
- BE
assignees:
- FernandoYu
---

La profesora indicó que el WBS no está bien — es la parte más difícil de hacer con IA.

## Problema actual
- El WBS fue organizado por **usuario** (siguiendo la estructura del USM), cuando debería estar organizado por **funcionalidad**.
- Los niveles intermedios no deberían tener funcionalidad propia; la funcionalidad debe estar en el **último nivel**.

## Tareas
1. Reorganizar `wbs.typ` agrupando por **funcionalidad** (no por usuario).
2. El WBS debe dar un pantallazo del producto a construir, análogo al USM.
3. Debe estar tan granulado que permita estimar el esfuerzo de cada ítem.
4. Iterar con IA para que genere el WBS basado en producto.
5. Debe quedar similar/alineado con el USM.

_Corrección de la Prof. — revisión Sprint 1_
