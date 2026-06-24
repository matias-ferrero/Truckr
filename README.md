# Truckr®

> **Llevamos lo tuyo, sin vueltas.**

Truckr® es un marketplace web que conecta transportistas independientes con expedidores que necesitan mover su carga. A diferencia de las empresas de transporte tradicionales, Truckr® le da visibilidad y oportunidades directas a cada transportista individual, y le simplifica al expedidor la búsqueda, contratación y pago de un flete.

## Acceso

| | URL |
|---|---|
| **Aplicación** | https://d1ln6zq4mn5erj.cloudfront.net |

---

## Equipo

- Brian Céspedes
- Fernando Yu
- Franco Ricciardo Calderaro
- Lucas Dondo
- Matias Ferrero
- Tomás Corzo

**Materia:** Gestión del Desarrollo de Sistemas Informáticos (GDSI)
**Institución:** Facultad de Ingeniería, Universidad de Buenos Aires (FIUBA)

---

## ¿Qué hace la aplicación?

La plataforma tiene dos roles principales:

- **Transportista** — dueño o conductor de camión que quiere conseguir cargas.
- **Expedidor** — persona o empresa que necesita enviar algo y busca quién lo lleve.

Ambos se registran en la misma app, y pueden tener los dos roles si lo necesitan.

### Flujo principal

```
Transportista publica disponibilidad  →  Expedidor publica carga
                                     ↓
              Expedidor busca ventanas compatibles con su carga
                                     ↓
              Expedidor hace una oferta sobre una ventana
                                     ↓
              Transportista acepta o rechaza la oferta
                                     ↓
              Expedidor paga → envío en tránsito → entregado
```

---

## Manual de usuario

### Registro e ingreso

1. Ingresá a la aplicación y hacé clic en **Registrarse**.
2. Completá tu nombre, email y contraseña.
3. Al iniciar sesión podés activar el rol de **Transportista**, de **Expedidor**, o ambos desde tu perfil.

---

### Manual del Transportista

#### 1. Mi flota — registrar vehículos

Antes de publicar disponibilidad necesitás tener al menos un vehículo registrado.

1. Desde el panel lateral, entrá a **Mi flota**.
2. Hacé clic en **Agregar vehículo**.
3. Completá la patente, tipo de vehículo y capacidad máxima de carga.
4. Guardá. El vehículo queda disponible para asignarlo a ventanas de transporte.

Para dar de baja un vehículo, hacé clic en **Dar de baja** en la fila correspondiente y confirmá en el modal.

#### 2. Ventanas de transporte — publicar disponibilidad

Una *ventana de transporte* es un bloque de disponibilidad: indicás desde dónde salís, hacia dónde vas, en qué período de tiempo y con qué camión. Los expedidores la ven cuando buscan coincidencias para su carga.

1. Desde el panel lateral, entrá a **Mis ventanas**.
2. Hacé clic en **Nueva ventana**.
3. Completá:
   - **Origen** — dirección de salida (se geolocaliza automáticamente).
   - **Radio de recogida** — cuántos km alrededor del origen estás dispuesto a desviarte para retirar la carga (1–200 km).
   - **Destino** — dirección de llegada. Podés dejarlo vacío si aceptás cargas a cualquier destino (*destino abierto*).
   - **Radio de entrega** — ídem para la entrega (solo si definiste destino).
   - **Período** — fechas de inicio y fin de disponibilidad.
   - **Vehículo** — seleccioná uno de los registrados en tu flota.
4. Publicá. La ventana queda visible para los expedidores.

Podés editar o cerrar una ventana mientras no tenga ofertas aceptadas.

#### 3. Ofertas recibidas — aceptar o rechazar

Cuando un expedidor encuentra tu ventana compatible con su carga, te envía una *oferta de carga* con el precio propuesto.

1. En el panel principal (sección **Ofertas recibidas**) vas a ver las ofertas pendientes.
2. Podés ver el detalle: origen y destino de la carga, peso, descripción y monto ofrecido.
3. Hacé clic en **Aceptar** para confirmar el envío, o en **Rechazar** si no te conviene.
4. Al aceptar, la carga queda asignada a tu vehículo y el expedidor recibe una notificación.

#### 4. Gestión del envío

Una vez aceptada la oferta, el envío aparece en **Mis envíos**.

- Cuando retirás la carga, marcá el envío como **En tránsito**.
- Al entregar, marcalo como **Entregado**.
- En el detalle del envío podés ver el mapa con el trayecto.

#### 5. Mis pagos

En **Mis pagos** podés ver el historial de cobros recibidos por envíos completados.

---

### Manual del Expedidor

#### 1. Publicar una carga

1. Desde el panel lateral, entrá a **Mis cargas**.
2. Hacé clic en **Nueva carga**.
3. Completá:
   - **Dirección de retiro** — desde dónde hay que retirar la mercadería.
   - **Dirección de entrega** — adónde tiene que llegar.
   - **Descripción** — qué es lo que se transporta.
   - **Peso** — capacidad necesaria.
4. Publicá. La carga queda en estado *abierta* y puede recibir ofertas.

#### 2. Buscar transporte compatible

1. Desde el detalle de una carga abierta, hacé clic en **Buscar transporte**.
2. La plataforma lista las *ventanas de transporte* cuyo origen y destino son compatibles con tu carga (cálculo por distancia Haversine — no necesitás coordenadas exactas).
3. Podés ver en el mapa la ventana y su radio de cobertura.
4. Hacé clic en **Ver detalle** para ver la información del transportista y el vehículo.

#### 3. Hacer una oferta

1. En la ventana que te interesa, hacé clic en **Hacer oferta**.
2. Ingresá el precio que estás dispuesto a pagar.
3. Confirmá. El transportista recibe una notificación con tu propuesta.
4. Podés seguir el estado de tu oferta (pendiente / aceptada / rechazada) desde el detalle de la carga.

#### 4. Pagar el envío

Una vez que el transportista acepta tu oferta:

1. En el detalle del envío, hacé clic en **Pagar**.
2. La plataforma procesa el pago y el dinero queda en escrow hasta que el envío se complete.
3. Recibís una notificación de confirmación de pago.

#### 5. Seguimiento del envío

En **Mis envíos** podés ver el estado actual de cada envío (a recoger / en tránsito / entregado) y el mapa con el trayecto planificado.

---

## Estructura del repositorio

```
truckr/
├── backend/          # API Rails 8 (Ruby 3.4, SQLite)
├── frontend/         # SPA React + Vite + TypeScript + Deno
└── docs/             # Artefactos académicos en Typst
    ├── artifacts/    # Informe del proyecto (visión, WBS, personas, USM, …)
    ├── prompts/      # Registro de sesiones de IA utilizadas
    └── progress-reports/  # Reportes de sprint en Markdown
```

## Stack tecnológico

| Capa | Tecnología |
|---|---|
| Backend | Rails 8 (API-only), Ruby 3.4 |
| Base de datos | SQLite |
| Frontend | React 18, TypeScript, Vite, Deno |
| WebSockets | Action Cable (solid_cable) |
| Jobs | solid_queue |
| Deploy | Kamal + Docker |
| Documentación | Typst |

---

## Para desarrolladores

<details>
<summary>Configuración del entorno y comandos de build</summary>

### Prerequisitos

Este proyecto usa [mise](https://mise.jdx.dev/) como gestor de versiones. Instalá todo con:

```sh
mise install
prek install   # instala pre-commit hooks
```

### Servidor de desarrollo

```sh
just backend-dev     # levanta backend

just frontend-dev    # levanta frontend
```

Los worktrees paralelos usan puertos dinámicos — ver `script/review-worktree.sh` y `just review`.

### Acceso a Backoffice de Users

| | URL |
|---|---|
| **Backoffice** (admin) | https://ip-18-228-83-21.sslip.io/admin/users |

### Documentación (Typst)

```sh
just build               # todo
just build-artifacts     # informe completo → docs/artifacts/main.pdf
just build-artifact wbs  # un artefacto individual
just build-chats         # sesiones de IA → PDF
just build-progress-reports  # reportes de sprint
just fmt                 # formatear .typ con typstyle
just lint                # todos los hooks de pre-commit
just clean               # borrar PDFs generados
```

### Tests

```sh
just backend-test              # RSpec
just frontend-test-coverage    # Vitest (umbral: 80%)
just frontend-test-e2e         # Playwright
```

</details>
