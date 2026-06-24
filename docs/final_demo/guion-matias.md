# Guion — Matías

> **Defensa Final · 24/06/2026.** Guion de orador para el bloque de Matías:
> **#NoEstimates — qué es, proceso, burn-up charts, simulación de Monte Carlo (~4 min)** — sigue a Tomás dentro de la Parte 2.
> Alineado con `html-slides/slides.md` (slides «¿Por qué #NoEstimates?», «Calibrar · Medir · Proyección»,
> «Proyecciones · Sprint 2/3/4», «Simulación de Monte Carlo»).
>
> **Cómo usarlo:** el texto en *cursiva* es lo que decís; **[corchetes]** son cues. No leas las slides.
> ~130 palabras/min. Venís de Tomás, que cerró con «si el código casi no cuesta, ¿para qué estimarlo?».

---

## Bloque 5 — #NoEstimates (~4 min)

**Objetivo:** mostrar que la decisión de no estimar fue una **decisión metodológica consciente**, no una
omisión. El argumento tiene cuatro momentos: por qué lo elegimos, cómo lo aplicamos, la prueba empírica
en los burn-up charts, y la confirmación vía simulación de Monte Carlo.

---

### 5.1 ¿Por qué #NoEstimates? (~1:00)

**[Slide «¿Por qué #NoEstimates?». Levantás la pregunta que Tomás dejó picando.]**

> *La respuesta a esa pregunta se llama **#NoEstimates**: una metodología ágil que reemplaza las
> estimaciones subjetivas — los story points, el planning poker — por throughput medido empíricamente.
> La idea central es simple: en vez de predecir cuánto va a costar algo, **medís cuánto tardaste y
> proyectás desde ahí**.*

> *¿Por qué lo elegimos? Tres razones concretas.* **[contás con los dedos]** *Primero: éramos un equipo
> sin histórico. Cualquier estimación en el sprint 1 era inventar un número. Segundo: como dijo Tomás,
> la IA colapsa el costo del desarrollo a casi cero — si el código no cuesta, estimar el costo del
> código no aporta nada. Y tercero: con user stories de esfuerzo uniforme, **contar cuántas cerramos
> por sprint se vuelve una unidad honesta**.*

**[Beat breve — mostrás el panel de ventajas y trade-off de la slide.]**

> *Las ventajas son directas: ahorro de tiempo y métricas basadas en datos reales, no en percepción.
> Y el trade-off es honesto: baja precisión al inicio — los primeros sprints no tienen suficiente
> historia para proyectar bien. Ahora les cuento cómo lo manejamos.*

---

### 5.2 Calibrar · Medir · Proyección (~0:45)

**[Slide «Calibrar · Medir · Proyección». Los tres puntos ya están visibles.]**

> *El proceso fue en tres tiempos.* **[contás con los dedos]**

> *Primero: **calibrar** — los sprints 1 y 2 generan datos con alta varianza. Son ruidosos en cualquier
> equipo nuevo; comprometerse con un número ahí es inútil. Los usamos para aprender el ritmo, no para
> proyectar.*

> *Segundo: **medir** — a partir del sprint 3, contamos las US cerradas por sprint. Eso es el throughput:
> observable, real, sin interpretación subjetiva.*

> *Y tercero: **proyección** — con el burn-up chart y la simulación de Monte Carlo proyectamos cuándo
> cerramos el MVP. No es «vamos a terminar». Es «con estos datos, así se ve el camino».*

**[Click — aparece la frase final. Pausa.]**

---

### 5.3 Burn-up charts — la prueba (~1:00)

**[Tres slides seguidas: Sprint 2, +Sprint 3, +Sprint 4. Las pasás contando la historia, sin parar.]**

**[Slide «Proyecciones · Sprint 2»]**

> *Este es el burn-up al cierre del Sprint 2. Las barras azules son las US del MVP completadas,
> las rojas lo que falta para llegar a 52. La recta diagonal es la proyección: con un throughput
> de 9 US/sprint, cruza el techo del MVP alrededor del **sprint ~5,8**.*

**[Slide «Proyecciones · + Sprint 3»]**

> *Agrego el Sprint 3. El throughput sigue en 9 US/sprint — la recta nueva apunta al **mismo ~5,8**.
> Dos sprints seguidos confirmando la misma lectura.*

**[Slide «Proyecciones · + Sprint 4»]**

> *Agrego el Sprint 4. El throughput sube a **10,25 US/sprint** — la pendiente se empina y el cruce
> se adelanta al **~5,1**. Las tres rectas quedan superpuestas: la pendiente mejorando sprint a sprint.*

**[Pausa real. Dejás que el gráfico hable.]**

> *El burn-up del sprint 4 decía que cerrábamos alrededor del sprint 5. El sprint 5 lo confirmó:
> 52 de 52 user stories entregadas.*

---

### 5.4 Simulación de Monte Carlo (~0:45)

**[Slide «Simulación de Monte Carlo».]**

> *Y para cuantificar esa proyección, corrimos una simulación de Monte Carlo: resampleamos los
> throughputs reales — 3, 15, 9, 14 US/sprint — 10 000 veces y medimos en qué fracción de escenarios
> llegábamos a completar el MVP dentro del horizonte.*

> *Al cierre del Sprint 4, con 11 user stories restantes: **93,6% de probabilidad de completar el
> MVP en el Sprint 5 o 6**. El horizonte era conservador — dos sprints más. El Sprint 5 lo confirmó.*

**[Click — aparece el remate. Pausa real.]**

---

### 5.5 Skill team_performance (al pasar, ~15 s)

> *Todo esto lo corre una CLI propia: `team_performance`. Bootstrap, burn-up, proyecciones —
> generadas desde datos reales y auditables con `--as-of-sprint N`.*

---

### 5.6 Cierre + handoff a Brian (~15 s)

**[Remate y pase a Brian.]**

> *En resumen: no estimar no es dejar de gestionar. Es gestionar con datos — y en nuestro caso,
> lo pudimos probar. Brian les muestra ahora qué fue lo que pasó antes del código: la planificación
> que hizo posible cortar bien esas 52 historias.*

---

## Notas rápidas para Matías

- **La frase-ancla:** «no estimar no es dejar de gestionar; es gestionar con datos». Está en la slide
  y cerrás con ella. Repetila al cerrar explícitamente.
- **El remate del burn-up es el momento más fuerte del bloque.** «La recta del sprint 4 apuntaba al
  sprint ~5. El sprint 5 lo confirmó.» Pausa real después de esa frase. No la atropelles.
- **Monte Carlo refuerza el burn-up:** no es una slide separada del argumento, es la confirmación
  probabilística de la misma proyección. 93,6% no es suerte — es el throughput mejorando sprint a sprint.
- **Encadenamiento con Tomás:** la razón 2 («IA colapsa el dev a ≈0») es literalmente la tesis de
  Tomás. Nombralo: «como dijo Tomás…». La Parte 2 tiene que sonar a un solo argumento.
- **Encadenamiento con Brian:** al cierre, el handoff explica por qué Brian viene ahora. Sin esa
  conexión, parece un bloque suelto.
- **Tiempos:** ~4 min. Si te apurás, recortá el 5.5 (skill) — es al pasar. Nunca recortes el burn-up
  ni Monte Carlo.
- **Q&A:** preparate «no estimar, ¿no es no hacer gestión?» → medición + burn-up + Monte Carlo **es**
  gestión, más rigurosa. Y «¿qué hiciste vos vs. la IA?» → diseñaste el esquema de NoEstimates,
  corriste la CLI, analizaste el burndown sprint a sprint.

---

*Fuentes: `docs/final_demo/README.md` y `docs/final_demo/html-slides/slides.md`.
Datos: `docs/team-performance/sprint-NN-performance.typ` (PR #351).*
