---
tag: INF-BE-00001
title: Reestructurar WBS por funcionalidades (no por pantallas/usuarios)
priority: P2
status: ready
created: 2026-05-03
updated: 2026-05-03
author: Claude Code
depends_on: []
decision_doc: N/A
selected_approach: N/A
---

# INF-BE-00001: Reestructurar WBS por funcionalidades (no por pantallas/usuarios)

| Field | Value |
|-------|-------|
| **Tag** | INF-BE-00001 |
| **Title** | Reestructurar WBS por funcionalidades (no por pantallas/usuarios) |
| **Priority** | P2 |
| **Status** | READY |
| **Created** | 2026-05-03 |
| **Updated** | 2026-05-03 |
| **Author** | Claude Code |
| **Depends On** | — |
| **Decision Doc** | N/A |
| **Selected Approach** | N/A |

---

## 1. Problem Statement

El WBS actual (`docs/artifacts/wbs.typ`) está organizado por **pantallas/usuarios** y no por funcionalidades:

- La rama **2. Plataformas** concentra casi todo el desarrollo, partida en `2.1 Plataforma Cliente` y `2.2 Plataforma Transportista` (más de 25 nodos hoja entre ambas).
- Las otras ramas (1. Gestión de Cuentas, 3. Integraciones, 4. Seguro, 5. Gestión del Proyecto) son comparativamente pequeñas → desbalanceadas.
- Una misma funcionalidad (p.ej. "viaje") aparece duplicada del lado cliente y del lado transportista, dificultando estimación, asignación y planificación.

Se requiere reorganizar a un WBS **alineado a features** (autenticación, búsqueda, viajes, pagos, reseñas, seguros, etc.), eliminando la rama "Plataformas", logrando ramas balanceadas y con descomposición a nivel estimable.

---

## 2. Solution Design

Reescribir el cuerpo `cetz/canvas` de `docs/artifacts/wbs.typ` reemplazando las 5 ramas actuales por **9 ramas alineadas a features**. Se preservan los helpers (`node`, `trunk`, `branch`, `arrow`, `branch-x`) y la configuración de página (356×630 mm). Sólo cambia la lista de nodos y aristas.

### Mapeo "rama actual → rama nueva"

| Nodos actuales (rama / sub) | Nueva rama destino |
|---|---|
| `1.1 Registro`, `1.2 Login`, `1.3 Perfil` (sin `1.3.3 Camión`) | **1. Cuenta y Acceso** |
| `1.3.3 Registro de camión` | **2. Vehículos y Flota** |
| `2.1.1 Búsqueda`, `2.1.2 Filtrado`, `2.1.3 Detalles del Transportista` | **3. Búsqueda y Descubrimiento** |
| `2.1.4 Oferta de Retiro`, `2.2.3 Aceptación de Viaje` | **4. Cotización y Reserva** |
| `2.2.1 Disponibilidad`, `2.2.2 Visualización de Ofertas`, `2.2.4 Realización del Viaje`, `3.3 Google Maps` | **5. Ejecución del Viaje** |
| `2.1.5 Pago`, `3.1 ARCA`, `3.2 Pago Seguro` | **6. Pagos y Facturación** |
| `2.1.3.4 Reseñas` (escindida y ampliada) | **7. Reseñas y Reputación** |
| Toda la rama `4. Seguro` (sin cambios estructurales mayores) | **8. Seguros** |
| `5.1 Artefactos` (re-balanceada) | **9. Gestión del Proyecto** |

Notas clave:
- **Eliminar la rama "2. Plataformas"** y todas las sub-ramas `Plataforma Cliente` / `Plataforma Transportista`. Distribuir su contenido por feature.
- **Eliminar la rama "3. Integraciones"** como tal; sus integraciones se incorporan a la feature que las consume (Google Maps → Ejecución del Viaje + Búsqueda; ARCA → Pagos; Mercado Pago → Pagos; Aseguradora → Seguros).
- **Descomponer hasta nivel estimable** (cada hoja debe ser una tarea cuantificable; granularidad ≈ 0.5–3 días de esfuerzo).
- **Balance**: target 4–6 sub-ramas por rama de nivel 1, 2–4 hojas por sub-rama. Total ≈ 60–75 hojas (vs ~50 actuales) — "mejor descomponer de más que de menos" según la nota del issue.

### Estructura nueva propuesta

```
Truckr® — Plataforma de Transporte
├── 1. Cuenta y Acceso
│   ├── 1.1 Registro
│   │   ├── 1.1.1 Formulario (email, nombre, contraseña)
│   │   ├── 1.1.2 Validación de contraseña segura
│   │   └── 1.1.3 Control de usuario duplicado
│   ├── 1.2 Login y Sesión
│   │   ├── 1.2.1 Ingreso con email y contraseña
│   │   ├── 1.2.2 Validación de credenciales
│   │   └── 1.2.3 Gestión de sesión (token / cookie)
│   ├── 1.3 Perfil de Usuario
│   │   ├── 1.3.1 Edición de datos personales
│   │   └── 1.3.2 Actualización de foto de perfil
│   └── 1.4 Recuperación de contraseña
│       ├── 1.4.1 Solicitud de reset por email
│       └── 1.4.2 Cambio con token de reset
│
├── 2. Vehículos y Flota
│   ├── 2.1 Registro de Vehículo
│   │   ├── 2.1.1 Datos básicos (patente, marca, modelo)
│   │   └── 2.1.2 Dimensiones y capacidad
│   ├── 2.2 Fotos del Vehículo
│   │   ├── 2.2.1 Carga múltiple
│   │   └── 2.2.2 Foto principal
│   └── 2.3 Multi-vehículo (Flota)
│       ├── 2.3.1 Listado de vehículos del transportista
│       └── 2.3.2 Selección de vehículo por viaje
│
├── 3. Búsqueda y Descubrimiento
│   ├── 3.1 Búsqueda de Transportistas
│   │   ├── 3.1.1 Búsqueda por origen y destino
│   │   ├── 3.1.2 Búsqueda por rango de fecha
│   │   ├── 3.1.3 Geocodificación de direcciones (Google Maps)
│   │   ├── 3.1.4 Listado paginado y scrolleable
│   │   └── 3.1.5 Ordenamiento de resultados
│   ├── 3.2 Filtrado de Resultados
│   │   ├── 3.2.1 Filtro por precio
│   │   ├── 3.2.2 Filtro por peso/volumen
│   │   ├── 3.2.3 Filtro por dimensiones
│   │   ├── 3.2.4 Filtro por capacidad del camión
│   │   └── 3.2.5 Reset de filtros
│   └── 3.3 Detalle del Transportista
│       ├── 3.3.1 Fotos y descripción del camión
│       ├── 3.3.2 Estimación de costos del viaje
│       ├── 3.3.3 Historial de viajes
│       └── 3.3.4 Reseñas en el perfil
│
├── 4. Cotización y Reserva
│   ├── 4.1 Oferta de Retiro
│   │   ├── 4.1.1 Fecha de retiro
│   │   ├── 4.1.2 Dirección de retiro
│   │   ├── 4.1.3 Dirección de entrega
│   │   └── 4.1.4 Confirmación de oferta
│   └── 4.2 Aceptación del Transportista
│       ├── 4.2.1 Botón de aceptación
│       └── 4.2.2 Actualización de fecha estimada de entrega
│
├── 5. Ejecución del Viaje
│   ├── 5.1 Publicación de Disponibilidad
│   │   ├── 5.1.1 Indicar zona de origen
│   │   ├── 5.1.2 Indicar límite de kilómetros
│   │   ├── 5.1.3 Indicar precio por km
│   │   └── 5.1.4 Confirmar publicación
│   ├── 5.2 Visualización de Ofertas
│   │   ├── 5.2.1 Listado de ofertas recibidas
│   │   ├── 5.2.2 Detalle del viaje
│   │   └── 5.2.3 Detalle del cliente
│   ├── 5.3 Tracking en Vivo
│   │   ├── 5.3.1 Posición GPS del transportista
│   │   └── 5.3.2 Visualización de ruta (Google Maps)
│   └── 5.4 Estados del Viaje
│       ├── 5.4.1 Marcar producto como recibido
│       ├── 5.4.2 Marcar como entregado
│       └── 5.4.3 Notificaciones de estado
│
├── 6. Pagos y Facturación
│   ├── 6.1 Integración Mercado Pago
│   │   ├── 6.1.1 SDK Checkout
│   │   └── 6.1.2 Webhooks de pago
│   ├── 6.2 Pago del Cliente
│   │   ├── 6.2.1 Pago tras aceptación de oferta
│   │   └── 6.2.2 Revelación de datos de contacto post-pago
│   ├── 6.3 Payout al Transportista
│   │   ├── 6.3.1 Liquidación post-entrega
│   │   └── 6.3.2 Historial de pagos recibidos
│   └── 6.4 Facturación (ARCA)
│       ├── 6.4.1 Integración con ARCA
│       └── 6.4.2 Emisión de factura electrónica
│
├── 7. Reseñas y Reputación
│   ├── 7.1 Creación de Reseña
│   │   ├── 7.1.1 Formulario post-viaje
│   │   └── 7.1.2 Restricción una-por-viaje
│   └── 7.2 Visualización
│       ├── 7.2.1 Listado en perfil del transportista
│       └── 7.2.2 Cálculo y visualización de promedio
│
├── 8. Seguros
│   ├── 8.1 Integración con Aseguradora
│   │   ├── 8.1.1 API de aseguradora
│   │   └── 8.1.2 Obtención de coberturas
│   ├── 8.2 Cotización
│   │   ├── 8.2.1 Cálculo por valor declarado
│   │   ├── 8.2.2 Cálculo por distancia
│   │   └── 8.2.3 Visualización al cliente
│   ├── 8.3 Contratación
│   │   ├── 8.3.1 Selección de cobertura
│   │   ├── 8.3.2 Pago integrado al flujo
│   │   └── 8.3.3 Emisión y envío de póliza
│   ├── 8.4 Gestión de Pólizas
│   │   ├── 8.4.1 Historial de seguros contratados
│   │   └── 8.4.2 Descarga de póliza
│   └── 8.5 Siniestros
│       ├── 8.5.1 Declaración
│       └── 8.5.2 Seguimiento
│
└── 9. Gestión del Proyecto
    ├── 9.1 Visión y Discovery (Lean, Personas, ENEHNH)
    ├── 9.2 Backlog y USM
    ├── 9.3 WBS y Cronograma
    ├── 9.4 Plan de Costos
    └── 9.5 Plan de Comunicaciones
```

### Layout (cetz coordinates)

El canvas actual usa anchos fijos (`x = -14, -7.5, 0, 6, 12` para las 5 ramas). Con 9 ramas necesitamos:

- Distribuir las raíces de nivel-1 sobre el ancho disponible (~36 cm útiles).
- Spacing horizontal entre raíces: ~4 cm (`x = -16, -12, -8, -4, 0, 4, 8, 12, 16`).
- Las ramas se "estiran" verticalmente (Y negativo crece hacia abajo). El alto de página actual es 630 mm (≈ 60 unidades cetz a 1cm). La rama más larga estimada (8. Seguros con 5 sub-ramas y 13 hojas, o 6. Pagos con 4 sub-ramas y 8 hojas) cabe holgada.
- Mantener `hw = 1.5`, `hh = 0.4`, `branch-offset = 2.25`, `trunk-offset = 1`.

### Key Components

- **`docs/artifacts/wbs.typ`**: archivo único a reescribir. Helpers preservados, cuerpo reescrito.
- **No tocar** `docs/artifacts/main.typ` (sigue usando `#include "wbs.typ"`).
- **No tocar** template ni otros artefactos.

---

## 3. Implementation Tasks

| # | Task | Status | Files |
|---|------|--------|-------|
| 1 | Diseñar coordenadas X/Y de las 9 nuevas ramas (mapa de layout en comentarios) | Pending | `docs/artifacts/wbs.typ` |
| 2 | Reescribir cuerpo del canvas: helpers se preservan, eliminar nodos/aristas actuales | Pending | `docs/artifacts/wbs.typ` |
| 3 | Implementar **Rama 1: Cuenta y Acceso** (4 sub-ramas, 11 hojas) | Pending | `docs/artifacts/wbs.typ` |
| 4 | Implementar **Rama 2: Vehículos y Flota** (3 sub-ramas, 6 hojas) | Pending | `docs/artifacts/wbs.typ` |
| 5 | Implementar **Rama 3: Búsqueda y Descubrimiento** (3 sub-ramas, 14 hojas) | Pending | `docs/artifacts/wbs.typ` |
| 6 | Implementar **Rama 4: Cotización y Reserva** (2 sub-ramas, 6 hojas) | Pending | `docs/artifacts/wbs.typ` |
| 7 | Implementar **Rama 5: Ejecución del Viaje** (4 sub-ramas, 12 hojas) | Pending | `docs/artifacts/wbs.typ` |
| 8 | Implementar **Rama 6: Pagos y Facturación** (4 sub-ramas, 8 hojas) | Pending | `docs/artifacts/wbs.typ` |
| 9 | Implementar **Rama 7: Reseñas y Reputación** (2 sub-ramas, 4 hojas) | Pending | `docs/artifacts/wbs.typ` |
| 10 | Implementar **Rama 8: Seguros** (5 sub-ramas, 13 hojas) | Pending | `docs/artifacts/wbs.typ` |
| 11 | Implementar **Rama 9: Gestión del Proyecto** (5 sub-ramas, sin hojas) | Pending | `docs/artifacts/wbs.typ` |
| 12 | Conectar `arrow(root, ramaN)` para las 9 ramas | Pending | `docs/artifacts/wbs.typ` |
| 13 | `just build-artifact wbs` y verificar que el PDF compila sin warnings | Pending | — |
| 14 | Inspeccionar visualmente el PDF: balance, sin solapamientos, todo el árbol cabe en la página | Pending | `docs/artifacts/main.pdf` |
| 15 | `just build-artifacts` (regenera el informe completo) | Pending | — |
| 16 | `just fmt` para typstyle | Pending | `docs/artifacts/wbs.typ` |

---

## 4. Code Changes

### 4.1 File: `docs/artifacts/wbs.typ`

**Purpose**: Reemplazar el contenido del bloque `canvas(...)` por la nueva estructura de 9 ramas alineadas a features. Los helpers (`node`, `trunk`, `branch`, `arrow`, `branch-x`) y la configuración de página/estilo se preservan idénticos.

Patrón a usar para cada rama (ejemplo Rama 1):

```typst
// ── 1. Cuenta y Acceso ─────────────────────────────────────────────
let cuenta = (-16, -1.8)
node(cuenta, hw, hh, [1. Cuenta y Acceso])

let cuenta-branch-x = branch-x(cuenta.at(0))
let registro = (cuenta-branch-x, -3.0)
node(registro, hw, hh, [1.1 Registro])

let registro-branch-x = branch-x(registro.at(0))
let formulario = (registro-branch-x, -4.6)
node(formulario, hw, 2 * hh, [1.1.1 Formulario \ (email, nombre, \ contraseña)])
let validacion-contra = (registro-branch-x, -6.2)
node(validacion-contra, hw, hh, [1.1.2 Validación de \ contraseña segura])
let control = (registro-branch-x, -7.4)
node(control, hw, hh, [1.1.3 Control de \ usuario duplicado])

// ... 1.2 Login y Sesión, 1.3 Perfil, 1.4 Recuperación

trunk(cuenta, recuperacion)
branch(cuenta, registro, hw)
branch(cuenta, login, hw)
branch(cuenta, perfil, hw)
branch(cuenta, recuperacion, hw)

trunk(registro, control)
branch(registro, formulario, hw)
branch(registro, validacion-contra, hw)
branch(registro, control, hw)
// ... resto de trunks/branches
```

Y al final:
```typst
// ── Aristas raíz → nivel 1 ───────────────────────────────────────
arrow(root, cuenta)
arrow(root, vehiculos)
arrow(root, busqueda)
arrow(root, cotizacion)
arrow(root, ejecucion)
arrow(root, pagos)
arrow(root, resenas)
arrow(root, seguros)
arrow(root, proyecto)
```

### Coordenadas X de las 9 raíces de nivel-1

| Rama | Variable | X |
|------|----------|---|
| 1. Cuenta y Acceso | `cuenta` | -16 |
| 2. Vehículos y Flota | `vehiculos` | -12 |
| 3. Búsqueda y Descubrimiento | `busqueda` | -8 |
| 4. Cotización y Reserva | `cotizacion` | -4 |
| 5. Ejecución del Viaje | `ejecucion` | 0 |
| 6. Pagos y Facturación | `pagos` | 4 |
| 7. Reseñas y Reputación | `resenas` | 8 |
| 8. Seguros | `seguros` | 12 |
| 9. Gestión del Proyecto | `proyecto` | 16 |

(Si el ancho real del canvas no alcanza, ajustar `branch-offset` o reducir spacing a 3.5.)

---

## 5. Testing

### Validaciones de compilación
- `just build-artifact wbs` debe compilar sin errores ni warnings de Typst.
- El PDF resultante debe tener exactamente 1 página (la rama más larga debe caber en `630mm`).
- `just build-artifacts` debe regenerar `docs/artifacts/main.pdf` completo (incluye WBS, USM, etc.).

### Validaciones visuales (manual)
- Las 9 ramas deben aparecer alineadas horizontalmente, sin solapamientos de nodos ni de aristas.
- Cada rama debe tener entre 2 y 5 sub-ramas.
- Cada sub-rama debe tener entre 2 y 5 hojas.
- No debe quedar ningún nodo "Plataforma Cliente" ni "Plataforma Transportista".
- La numeración debe ser consistente (1.1.1, 1.1.2 …) sin saltos.

### Validaciones de balance (heurística)
- Diferencia entre la rama con más hojas y la rama con menos hojas ≤ 4× (target: ≤ 3×).
- Total de hojas: 60–75 (vs ~50 actuales).

---

## 6. Acceptance Criteria

- [ ] La rama "Plataformas" (con sub-ramas Cliente/Transportista) ya no existe.
- [ ] El WBS está organizado en ramas alineadas a features (Cuenta, Vehículos, Búsqueda, Cotización, Ejecución, Pagos, Reseñas, Seguros, Proyecto).
- [ ] Cada hoja del WBS describe una tarea estimable (≈ 0.5–3 días de esfuerzo).
- [ ] Las ramas están razonablemente balanceadas (sub-ramas y hojas por rama dentro del rango target).
- [ ] `just build-artifact wbs` compila sin errores.
- [ ] `just build-artifacts` regenera el reporte completo sin errores.
- [ ] `just fmt` no reporta cambios pendientes en `wbs.typ`.
- [ ] El PDF cabe en la página actual (356×630 mm, una sola página).
- [ ] Inspección visual: sin solapamientos, numeración consistente, no quedan strings "Plataforma Cliente" / "Plataforma Transportista" en el archivo.

---

## 7. Files Summary

### New Files
| File | Description |
|------|-------------|
| — | — |

### Modified Files
| File | Changes |
|------|---------|
| `docs/artifacts/wbs.typ` | Cuerpo del canvas reescrito completamente: 9 ramas feature-aligned reemplazan las 5 actuales (Gestión de Cuentas, Plataformas, Integraciones, Seguro, Proyecto). Helpers, page setup y header preservados. |
| `docs/features/ISSUES-INDEX.md` | Marcar INF-BE-00001 como `RDY` y enlazar al plan. |
| `.gdsi-sdlc/issues/Backlog/INF-BE-00001-...issue.md` | Mover a `Ready/`, agregar `plan:` en frontmatter, cambiar `status: ready`. |
