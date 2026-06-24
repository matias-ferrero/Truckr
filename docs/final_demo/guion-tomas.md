# Guion — Tomás

> **Defensa Final · 24/06/2026.** Bloque de Tomás: **El proceso — IA sobre el ciclo de
> desarrollo.** Abre la Parte 2 (cómo lo construimos).
>
> Versión reescrita a partir de cómo Tomás habla **realmente** la demo (a capela, pasando las
> slides en la segunda pantalla). No es un libreto para leer: es el contenido real, en su voz,
> ordenado por slide. Alineado con `html-slides/slides.md`.
>
> **Estado:** capturadas slides 2–4 (ciclo, worktrees, techo de atención). Pendiente: cierre /
> Motor de gestión (slide 5) + handoff a Matías.

---

## Slide 1 — «El proceso» (transición desde la demo)

Bueno, eso fue la demo. Ahora vamos a ver **cómo fue el proceso** para llegar al producto al que
llegamos, en el tiempo en que llegamos.

---

## Slide 2 — «El ciclo tradicional → + Agente IA → + #NoEstimates» (animada, 2 clicks)

Si pensamos en el flujo tradicional de desarrollo de un feature, primero definimos requisitos, diseñamos una solución, implementamos, probamos y luego deployamos.

Pero nosotros ya sabíamos de entrada que el desarrollo agéntico iba a reducir drásticamente el esfuerzo y tiempo de las etapas de desarrollo.


**[BEAT 0 — el ciclo de manual en pantalla]**

Si pensamos en el ciclo tradicional del desarrollo de software, sabemos que gran parte del esfuerzo
de desarrollar un feature, una user story, cae en la **implementación y las pruebas**.

**[CLICK 1 — «+ IA»: Implementación y Testing se desinflan, Requisitos y Diseño engordan]**

Ahora hay un cambio fundamental en cómo nos manejamos hoy: la IA. Lo que estamos viendo es que la IA
**colapsa el tiempo de implementación y testing a casi cero**. Es muy poco el tiempo que nos lleva
implementar algo bien planificado.

Entonces, el tiempo que yo gastaba en implementación y testing, ahora lo puedo **invertir en
requisitos y en diseño**: en evaluar cuál es el valor que realmente quiero entregarle al usuario, y
en definir una buena solución para esos requisitos.

**[CLICK 2 — «+ #NoEstimates»: «Estimar» se cae del ciclo]**

Y adicionalmente, en nuestro proceso usamos el concepto de **#NoEstimates**: eliminamos otra gran
parte del costo —**estimar**— y lo dedicamos, de nuevo, a requisitos y diseño.

---

## Slide 3 — «¿Qué hago mientras el agente trabaja?» (animada, 2 clicks)

**[BEAT 0 — un agente trabajando]**

Ahora, una cosa de la que me di cuenta mientras implementábamos: armo esa buena user story, defino
los requisitos que quiero cumplir, planifico la implementación y se la delego al agente… y me quedo
**sentado mirándolo trabajar**, sin hacer nada —mirando el partido en la segunda pantalla, lo que
sea—. Y digo: este es tiempo mío que estoy perdiendo. Es inaceptable.

**[CLICK 1 — aparece un segundo agente: colisión (coral)]**

Entonces agarro otro issue, otra user story, la planifico y se la disparo a otro agente. Pero ¿qué
pasa? Cuando intento trabajar en el mismo directorio, **los agentes se pisan**: misma rama, mismos
puertos, misma base de datos. Tenemos colisiones.

**[CLICK 2 — cada lane queda aislada (sky): worktrees + puertos propios]**

Así que lo que adoptamos fue un esquema de **git worktrees** —una feature propia de Git que te arma
un segundo directorio en su propia branch, bajo el mismo sistema de control de versiones; no es lo
mismo que hacer un `cp` del repo—. Y además implementamos **scripts que generan puertos aleatorios**
que no conflictúan con otras sesiones.

Esto se lo podés pedir a Claude cada vez que arrancás una sesión nueva… o, ya después de la tercera o
cuarta vez de hacerlo, te cansás y lo convertís en una **skill**.

---

## Slide 4 — «El techo es mi atención» (animada, 2 clicks)

**[BEAT 0 — la barra entera (100%) es una sola sesión]**

Mi atención es un presupuesto fijo: cien por ciento. Con una sola sesión, ese cien por ciento va
todo ahí. Ahora, si con dos sesiones mejoro un montón mi performance —supongamos que la duplico—,
¿por qué no puedo usar 3, 4, 5, 20 sesiones?

**[CLICK 1 — la barra se parte en ~5 tajadas, ~20% cada una]**

El problema es que la atención no se multiplica: **se divide**. Cuanto más sesiones abro, más fina
es la tajada que le toca a cada una —de cien por ciento paso a darle como un veinte por ciento a cada
una—. Y cualquiera que haya programado concurrente —creo que todos lo hicimos en esta cátedra— sabe
que **cambiar de tarea tiene un costo**: el context switch tiene un costo.

**[CLICK 2 — las tajadas caen bajo el «mínimo útil»; F·G·H quedan starved]**

Hay un momento en el que el overhead de mover la atención de una tarea a otra **sobrepasa el
beneficio** que te da la concurrencia. Experimentando nos dimos cuenta de que, para tareas pesadas,
la concurrencia no puede superar mucho más que **dos sesiones, tres con toda la furia**. Pero si
tenés una o dos tareas pesadas, podés llegar a sumarle dos o tres **livianas** —que se hacen
prácticamente solas y no requieren una revisada general antes de mergearlas—.

---

## Slide 5 — «Research → Plan → Implement» (lo más jugoso)

**[Apertura — la slide arranca solo con el título]**

Y acá está lo más jugoso de todo lo que usamos: el workflow que llamamos **RPI — Research, Plan,
Implement**. Algo tan sencillo como "implementar esta user story" lo separamos en tres etapas.

**[CLICK 1 — aparece la tarjeta «Research»: user story → issue]**

**Research** toma un deseo de alto nivel —una **user story**— y lo transforma en un **issue de
GitHub**, donde se establecen los criterios de aceptación ya **en términos de código**.

**[CLICK 2 — aparece «Plan»: issue → markdown]**

**Plan** toma esa issue y genera un **markdown con una solución diseñada** para cumplir esos
criterios, a nivel código, **línea por línea**.

**[CLICK 3 — aparece «Implement»: plan → código]**

Y **Implement** es nada más y nada menos que **implementar el plan**.

**[Sin click — esto lo decís de viva voz, las tres tarjetas ya en pantalla: el costo del error de
alineamiento]**

Ahora, ¿por qué tomar algo tan sencillo y partirlo en tres? Todo se centra en **reducir el costo del
error de alineamiento**.

Muchas veces le pedís a Claude Code que implemente algo y no hace exactamente lo que vos esperabas:
**eso es un error de alineamiento**. Y no es lo mismo cometer ese error en la fase de implementación
—donde el error puede ser un `if/else` o un test mal hecho— que en la fase de **research**, donde
estás definiendo **qué** vas a construir. Un error allá arriba, si llega hasta implementación, genera
una **cascada mucho más costosa**. Por eso atajamos el alineamiento temprano, donde corregir es barato.

**[Handoff a Matías]**

Y con un flujo así —donde el grueso del trabajo está en research y plan, y la implementación se vuelve
barata— la pregunta deja de ser *"cuánto va a costar esto"* y pasa a ser *"cuánto estamos
entregando"*. De medir en vez de estimar les habla **Matías**.
