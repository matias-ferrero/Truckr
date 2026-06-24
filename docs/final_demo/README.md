# Defensa Final — Plan de la presentación

> **Carpeta de trabajo de la demo final.** Acá va todo lo relevante para la defensa del 24/06/2026:
> el plan de la presentación, el guion de la demo, el seed de datos, las slides y el material de apoyo.

- **Fecha:** 24/06/2026, 17:00–22:00 (presencial).
- **Formato:** **35 min = 25 de presentación + 10 de Q&A.**
- **Pautas oficiales:** ver rúbrica de la cátedra (entrega + organización, claridad, demo, gestión, participación de todos, **uso de IA**).
- **Estructura obligatoria (dos partes, en este orden):**
  1. **Pitch comercial + demo** (vender el producto como a un inversor + demo).
  2. **Proceso de desarrollo** (planificación, metodología, IA, métricas, roles, reflexión crítica).

---

## Tesis central (el hilo de la Parte 2)

> **La IA colapsó el costo del código a casi cero.** Tres consecuencias:
> 1. Estimar el esfuerzo de desarrollo perdió sentido (es casi constante) → **medimos throughput en vez de estimar.**
> 2. Con user stories bien desglosadas, **contar US se vuelve una unidad honesta.**
> 3. El trabajo real se mudó aguas arriba: a **planificar y definir valor.**
>
> Por eso pudimos **sacar una fase de gestión (estimar)** y meter ese tiempo en entregar.

La IA y el "no-estimates" se cuentan como **un solo argumento causal**, no como dos secciones separadas.

---

## Parte 1 — Pitch + Demo (~13 min)

### Pitch comercial (~3 min) — *Lucas*
- **Diferencial:** "**Airbnb de los backhauls**" — monetizar viajes que el transportista **ya iba a hacer**, matcheando la carga del expedidor con ventanas de transporte **ya planificadas**.
- **Por qué invertir:** red de dos lados con **oferta ya existente** (los transportistas ya manejan esas rutas). El transportista cobra un viaje que igual hacía; el expedidor consigue capacidad más barata; nosotros nos quedamos con el spread.

### Demo (~10 min) — *Franco (Expedidor) → Fernando (Transportista)*
**Un solo hilo continuo**, siguiendo una misma carga de punta a punta, cambiando de rol en vivo:

1. **Expedidor** publica la carga *"Pallets de granos"*.
2. El sistema muestra **solo las ventanas de transporte compatibles** ← acá se ve el diferencial.
3. Se concreta la **oferta**.
4. **(Transición diegética Franco → Fernando)** — "…y acá entra el transportista".
5. **Transportista** acepta y corre el envío (start → deliver).
6. **Pago** + **notificación en tiempo real**.
7. **Reseñas mutuas** (cierra el loop de confianza del marketplace).

> ⚠️ **Transición Franco→Fernando** es el punto más delicado: debe ser fluida, sin cortar el hilo.
> ⚠️ **Demo en vivo con fallback grabado** del golden path. **Resetear el seed antes de exponer.**

#### Seed de la demo (a medida — NO el de E2E)
- **Hilo protagonista:** carga *"Pallets de granos"* + **1 ventana compatible libre** (sin contención previa).
- **Relleno de contexto** (que ningún dashboard quede vacío; no se toca en vivo):
  - **Expedidor:** 2–3 envíos en curso (uno "en tránsito", uno "entregado"), 1–2 pagos, 1 reseña recibida.
  - **Transportista:** flota 2–3 vehículos, 2–3 ventanas (una libre = la protagonista; otras ocupadas), 2–3 envíos en curso, pagos cobrados, reseña + rating.
  - **Notificaciones:** algunas leídas + campanita con algo pendiente.
- **Requisitos:** idempotente y reseteable (`db:seed:demo` o similar). El relleno **no** debe crear otra ventana compatible ni dejar la carga protagonista ya ofertada.
- **Identidades realistas:** Expedidor "Molinos del Sur", Transportista "Transportes Don Aldo".

---

## Parte 2 — Proceso (~12 min)

### IA + No-estimates (un solo argumento, ~9 min) — *Tomás (IA) → Matías (#NoEstimates)*

**IA en 3 niveles** (cada uno con una prueba mostrable):
1. **Invierte la economía de la calidad.** Los guardarraíles (CLAUDE.md, hooks, stylelint, coverage, a11y) existen **para mantener a la IA dentro de NUESTROS estándares** (relación bidireccional). Pero en un TP de 5 semanas nadie monta tanto CI/linting: el ROI no cierra. **La IA lo abarata y vuelve viable una vara de producción.**
2. **Motor de gestión.** Skills propias (`sprint-planning`, `sprint-status`, `team-performance`) → artefactos generados desde datos reales.
3. **Multiplicador de throughput.** ~20 worktrees en paralelo → la curva **3 → 15 → 9 → 14 → 11** US/sprint (**52 US en 5 sprints, 6 personas**).

**#NoEstimates en 4 niveles (~4 min) — Matías:**

**Nivel 1 — ¿Por qué #NoEstimates?**
- **Qué es:** metodología ágil que reemplaza estimaciones subjetivas (story points) por throughput medido empíricamente. La pregunta es «¿para qué estimamos si podemos medir?»
- **Por qué lo elegimos:** equipo primerizo sin histórico → cualquier estimación era inventar. La IA colapsó el dev a ≈0 → estimar el costo de dev no aporta. US bien cortadas tienen esfuerzo ~uniforme → contarlas es una unidad honesta.
- **Trade-off honesto:** baja precisión al inicio — los primeros sprints tienen datos con alta varianza y no alcanzan para proyectar con confianza.

**Nivel 2 — Proceso: Calibrar · Medir · Proyección**
- Sprint 1–2: **calibrar** — datos con alta varianza, sin comprometerse con un forecast.
- Sprint 3+: **medir** — contar US cerradas por sprint (throughput observable cada iteración).
- **Proyección** — el burn-up chart traza la recta: ¿en qué sprint cerramos el MVP? Confirmado por simulación de Monte Carlo (nivel 4).
- Los tres puntos aparecen visibles al entrar a la slide; solo la frase-ancla final aparece on click.

**Nivel 3 — Burn-up charts (3 slides)**
- Tres slides consecutivas que acumulan proyecciones sprint a sprint (Sprint 2 → +Sprint 3 → +Sprint 4).
- **Sprint 2:** throughput 9 US/sprint → recta cruza el MVP en el sprint ~5,8.
- **+Sprint 3:** throughput sigue en 9 US/sprint → misma recta, misma lectura (~5,8). Consistencia.
- **+Sprint 4:** throughput sube a 10,25 US/sprint → recta se empina, cruce en ~5,1. Las tres rectas quedan superpuestas, la pendiente mejorando sprint a sprint.
- Remate: «el burn-up del sprint 4 decía que cerrábamos alrededor del sprint 5. El sprint 5 lo confirmó.»

**Nivel 4 — Simulación de Monte Carlo**
- Bootstrap de 10 000 muestras (seed 42) sobre los throughputs reales: 3, 15, 9, 14 US/sprint.
- Al cierre del Sprint 4: 11 US restantes, horizonte 2 sprints (Sprints 5 y 6).
- **Resultado: 93,6% de probabilidad de completar el MVP en el Sprint 5 o 6.**
- El equipo terminó en el Sprint 5 — dentro del horizonte conservador.
- Slide con bloque verde grande (93,6%) + explicación del método. Remate on click.

**Skill team_performance (al pasar, sin slide dedicada)**
- CLI propia que corre el bootstrap y genera el PDF con throughput histórico, burn-up y proyecciones.
- Modo reconstrucción `--as-of-sprint N` → origen de los gráficos y la simulación mostrados en slides.

### Artefactos (~2 min) — *Brian*
- **Protagonistas:** Lean Inception (product-vision + es/no-es + personas) + **USM** + **PDF de throughput/forecast**.
- **Excluidos del show en vivo** (aburridos, igual van al Drive): backlog, costos, riesgos, comunicaciones.
- **Mosaico de 5 seg:** WBS, features matrix, cronograma → "y todo esto también, en el Drive".

### Reflexión crítica (~2 min) — *Brian* · Cierre — *Lucas*
- **El mayor error:** confiamos de más en la IA **justo en la fase más importante (planificación)**. No refinamos US/requisitos a una especificación de verdad → en sprints 1–2 descubríamos *implementando* lo vagas que eran las US y lo mal definido que estaba el problema → refactor/reimplementación/tiempo perdido.
- **Segundo problema:** desalineación de conceptos **entre integrantes y con la IA** — la documentación no reflejaba nuestro modelo mental.
- **La solución:** desde el sprint 3 **tomamos las riendas de la planificación** + construimos el **glosario como fuente de verdad** para alinear el modelo mental del equipo y de la IA.
- **Cierre:** *"La IA no reemplaza la definición del problema: la acelera si vos ya la tenés clara. El mayor error fue delegarle lo que más importa."* ← **espeja y valida la tesis.**

### Roles asumidos (encuadre b)
La IA disolvió la frontera front/back/QA → los roles humanos fueron **dueños de valor** (dueños de épica/feature), no especialidades técnicas. **Tomás** en gestión (throughput, planificación, CLI de forecast, guardarraíles).

---

## Expositores (orden)

| # | Bloque | Tiempo | Expositor |
|---|---|---|---|
| 1 | Pitch comercial | ~3 min | **Lucas** |
| 2 | Demo — rol Expedidor | ~5 min | **Franco** |
| 3 | Demo — rol Transportista | ~5 min | **Fernando** |
| 4 | IA (3 niveles) | ~5 min | **Tomás** |
| 5 | #NoEstimates — qué es, proceso, burn-up chart, skill | ~4 min | **Matías** |
| 6 | Artefactos + reflexión crítica | ~4 min | **Brian** |
| 7 | Cierre | ~1 min | **Lucas** |

> Todos deben permanecer en el aula todo el turno; participar en el Q&A de otros equipos suma a la nota individual.

---

## Slides

El deck es **HTML/web con [Slidev](https://sli.dev)** (Vue+Vite+TS). Vive en [`html-slides/`](./html-slides/).

> El deck extrae los **design tokens del frontend** (Impeccable) tal cual: `styles/tokens.css` es copia
> verbatim del `:root` de `frontend/src/styles/global.css`, con la misma paleta de dos voces del producto
> (Expedidor = sky, Transportista = saffron). Ver [`html-slides/README.md`](./html-slides/README.md) para el
> research de librerías y el detalle.

> La demo **no tiene slides de contenido**: hay una única slide-cartel «Demo en vivo» y a partir de ahí se **comparte pantalla con el producto real** en el proyector. Todos los cues (reset de seed, fallback, flujo, handoff Franco→Fernando) están en la nota del orador de esa slide.

- **Notas del orador:** cada slide tiene presenter notes con el nombre del expositor y sus cues; la vista de presentador es `/presenter` en el navegador (segunda pantalla).
- **Densidad:** ~18–22 slides, peso en la Parte 2. Pitch+demo livianos (la demo es en vivo).
- **Export:** `npm run export:pptx` → PPTX para subir a Google Slides en el Drive.

```sh
cd docs/final_demo/html-slides
npm install
npm run dev            # editar con live-reload; vista de presentador en /presenter
npm run export:pptx    # PPTX → Google Slides para el Drive
```

> **Gráficos embebidos (Matías):** las slides «Proyecciones» usan tres burn-up superpuestos generados desde el análisis de `team_performance`. Los PNGs están en `.gitignore` — hay que regenerarlos antes de presentar. Las fuentes son `docs/team-performance/sprint-0{2,3,4}-burnup.typ` (comparten el helper `_burnup-overlay.typ`); cada una rinde **sólo** el gráfico, con la página auto-ajustada al contenido (sin recorte manual):
> ```sh
> for n in 02 03 04; do
>   typst compile --root docs --format png --ppi 192 \
>     "docs/team-performance/sprint-$n-burnup.typ" \
>     "docs/final_demo/html-slides/sprint-$n-burnup.png"
>   cp "docs/final_demo/html-slides/sprint-$n-burnup.png" \
>      "docs/final_demo/html-slides/public/sprint-$n-burnup.png"
> done
> ```
> Los PNGs (`sprint-0{2,3,4}-burnup.png`) deben quedar junto a `slides.md` (las slides los referencian con `./sprint-0N-burnup.png`). Cada `.typ` agrega la columna y la recta de proyección del sprint correspondiente **sin borrar las anteriores** (Sprint 2 → 3 → 4), con los mismos ejes para que se superpongan al pasar de slide.

---

## Pendientes

- [x] **Scaffold del deck** en Slidev (6 bloques + presenter notes por expositor) → [`html-slides/`](./html-slides/).
- [ ] Completar el contenido de cada slide e insertar pruebas/capturas.
- [ ] **Seed de la demo** (`db:seed:demo` idempotente) según el spec de arriba.
- [x] **Forecast predicho vs. real** — ✅ calculado con `team_performance --as-of-sprint N`. Ver tabla en la sección de Matías arriba.
- [ ] **Q&A prep** — 5 preguntas filosas anticipadas:
  1. Si confiaron de más en la IA, ¿cómo sé que el producto no es "AI slop"? → guardarraíles + 80% coverage + a11y + E2E.
  2. El throughput es alto porque el proyecto es chico. → 51 US / 5 semanas / 6 primerizos; el punto es la **curva** (relativo), no el absoluto.
  3. No estimar, ¿no es no hacer gestión? → medición empírica + forecast probabilístico **es** gestión, más rigurosa.
  4. **¿Qué hizo cada uno vs. la IA?** → cada integrante debe tener su respuesta individual lista (define la nota individual).
  5. Muéstrenme una decisión donde le dijeron **que no** a la IA. → la corrección de planificación del sprint 3.
- [ ] **Grabación de fallback** del golden path de la demo.
