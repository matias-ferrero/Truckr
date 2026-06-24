# Guion — Brian · Reflexión crítica

> **Defensa Final · 24/06/2026.** Segunda mitad del slot de Brian: la **reflexión crítica (~2 min)**.
> Continúa directo desde [`guion-brian.md`](./guion-brian.md) (artefactos) — **no hay cambio de orador**:
> venís de tu propio recorrido de Lean Inception + USM y enganchás acá. Cerrás pasándole el cierre a Lucas.
> Alineado con `html-slides/slides.md` (slide «El error que más nos costó» → slide «Cierre» de Lucas).
>
> **Cómo usarlo:** el texto en *cursiva* es lo que decís; **[corchetes]** son cues. ~130 palabras/min.

---

## El hilo de esta mitad (leé esto antes que nada)

Acabás de mostrar lo prolijo: visión → alcance → personas → USM. Ahora venís a romper esa prolijidad a
propósito. La regla de oro: **autocrítica genuina, NO la vuelta de la victoria.** Los docentes pican el
«todo salió bárbaro»; un error contado con honestidad suma más que diez aciertos.

El giro que vuelve potente al error —y que tenés que dejar explícito— es este:

> **El error no contradice nuestra tesis: la confirma. La IA acelera la definición del problema; no la reemplaza.**

Tu frase-ancla:

> *«Lo planificamos prolijo… pero le delegamos a la IA justo lo que más importaba.»*

---

## Reflexión crítica (~2 min)

### 1. El error que más nos costó (~45 s)

**[Slide «El error que más nos costó». Bajá el ritmo. Cambiás del tono expositivo del USM a uno honesto,
casi confesional. Esto se cuenta con la cara de quien lo vivió.]**

> *Que lo hayamos planificado así de prolijo no quiere decir que nos salió bien a la primera. Si me
> preguntan cuál fue nuestro error más grande, lo tengo clarísimo, y fue **justo en esta etapa**: la
> planificación. **Confiamos de más en la IA en la fase más importante del proyecto.***

**[Pausa. Dejá que pegue antes de explicar el cómo.]**

> *Le delegamos el refinamiento de las user stories y de los requisitos **sin bajarlos a una
> especificación de verdad**. ¿Qué pasó? Que recién **descubríamos implementando** lo vagas que eran esas
> historias y lo mal definido que estaba el problema. Y eso, en software, se paga caro: **refactors y
> reimplementación en los sprints 1 y 2** — tiempo que tiramos.*

### 2. El problema de fondo — desalineación de conceptos (~30 s)

**[Mismo slide, o el bullet de desalineación. Este es el diagnóstico, no solo el síntoma.]**

> *Y abajo de eso había un problema más sutil: **desalineación de conceptos** — entre nosotros, y con la
> IA. La documentación no reflejaba un **modelo mental compartido**, así que cada integrante —y la
> IA— entendía el dominio un poco distinto. Llamábamos a la misma cosa con tres nombres, y la IA
> heredaba esa confusión y la multiplicaba en el código.*

### 3. Cómo lo corregimos (~30 s)

**[Acá levantás de nuevo: del error a la decisión. Esto es lo que demuestra madurez de equipo.]**

> *Lo corregimos a partir del **sprint 3**, con dos movidas. Primero, **tomamos las riendas de la
> planificación nosotros** — dejamos de delegarle a la IA la definición y pasamos a usarla para
> ejecutarla. Y segundo, construimos un **glosario como única fuente de verdad**: cada término del
> dominio, un solo nombre, una sola definición, para alinear el modelo mental del equipo **y** el de la IA.*

**[Cue: el glosario es real y verificable —vive en `docs/05-appendices/glossary.md`—. Si te preguntan,
es tu prueba concreta de la corrección, no una promesa.]**

> *Desde ahí, los conceptos dejaron de chocar, las US dejaron de ser ambiguas, y el rework se desplomó.
> No por casualidad el throughput se estabiliza justo cuando tomamos esta decisión.*

### 4. El remate que valida la tesis + handoff a Lucas (~15 s)

**[Este es el puente. Conectás tu error con la tesis de Tomás — y se lo dejás servido a Lucas.]**

> *Y fíjense en algo: este error **no contradice** nuestra tesis sobre la IA. **La confirma.** La IA
> acelera la definición del problema, pero **no la reemplaza** —cuando se la delegamos entera, lo
> pagamos—. Y sobre esa idea cierra Lucas.*

**[Mirás a Lucas. Le pasás el cierre.]**

> *Lucas, cerrá vos.*

---

## Notas rápidas para Brian (reflexión)

- **NO es la vuelta olímpica.** El error tiene que sonar a error de verdad: nombrá lo que dolió
  (refactors, sprints 1–2, tiempo perdido). La honestidad es lo que el jurado valora acá.
- **Error → diagnóstico → corrección → tesis.** Ese es el arco en 4 beats. Si te apurás, comprimí el
  diagnóstico (sección 2), nunca la corrección (es lo que muestra que aprendimos).
- **El glosario es tu prueba dura.** `docs/05-appendices/glossary.md` existe y es la fuente de verdad de
  terminología; es también la continuación natural del cue terminológico que dejaste en el bloque de
  personas («expedidor»/«transportista»).
- **Encadená con Tomás:** el remate «la IA acelera, no reemplaza» es literalmente su tesis. Decilo como
  cierre del círculo de toda la Parte 2.
- **Es tu munición para el Q&A:** «muéstrenme una decisión donde le dijeron que NO a la IA» → es
  exactamente esto, la corrección de planificación del sprint 3. Tenelo listo palabra por palabra.
- **Tiempos:** ~2 min (45 s error + 30 s diagnóstico + 30 s corrección + 15 s remate/handoff).

---

*Fuentes: `docs/final_demo/README.md` (reflexión crítica, corrección del sprint 3, glosario);
`docs/final_demo/html-slides/slides.md` (slide «El error que más nos costó»);
`docs/05-appendices/glossary.md` (glosario como fuente de verdad). Continúa de `guion-brian.md`.*
