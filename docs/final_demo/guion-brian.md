# Guion — Brian

> **Defensa Final · 24/06/2026.** Guion de orador para el bloque de Brian:
> **Artefactos — Lean Inception + USM (~2 min)**, que recorre lo que *definimos antes de
> escribir código*. (La **reflexión crítica** —segunda mitad del slot de Brian, ~2 min— va en su
> propio guion; acá termina con el handoff hacia ella.)
>
> **Alcance acordado:** en vivo mostramos **product-vision → es/no-es → personas → USM**.
> *(Opcional «riesgos» marcado como tal más abajo; por ahora no entra.)*
>
> **Cómo usarlo:** el texto en *cursiva* es lo que decís; lo que está entre **[corchetes]** son cues
> (qué slide/artefacto, qué hacer, dónde pausar). **No leas las tablas** —el artefacto es el respaldo,
> vos contás la historia que lo une. Apuntá a ~130 palabras/min: este guion entra holgado en ~2 min.

---

## El hilo de todo el bloque (leé esto antes que nada)

Venís después de Matías (no-estimates + throughput). Tu bloque es la **bisagra de la Parte 2**: probás
que *el trabajo real se movió aguas arriba, a la planificación y la definición de valor*. Estos cuatro
artefactos **no son documentación de relleno** —son la cadena que va de «una idea» a «51 US construidas»:

> **Visión → qué es / qué no es → para quién (personas) → cómo se ordena en releases (USM).**

Tu frase-ancla, la que repetís al abrir y al cerrar el bloque:

> *«Antes de escribir una línea de código, definimos el producto. Esa fue la parte difícil.»*

---

## Artefactos — Lean Inception + USM (~2 min)

### 0. Apertura del bloque (~15 s)

**[Slide de sección «Artefactos / Lean Inception». Te parás de frente, tranquilo —cambia el registro:
de los números de Matías al razonamiento de producto.]**

> *Recién vieron cuánto entregamos. Yo les quiero mostrar **lo que hicimos antes de entregar nada**:
> cómo definimos el producto. Porque si la IA abarata el código a casi cero, el trabajo de verdad se
> corre para acá —a decidir **qué** construir y **para quién**. Lo hicimos con una **Lean Inception**.*

**[Cue: una sola respiración. No expliques qué es una Lean Inception en abstracto —mostrá los pedazos.]**

### 1. Product Vision (~25 s)

**[Avanzás a la slide «Product Vision» (la plantilla Para/quienes/es-un/que/diferente-a).]**

> *Arrancamos con una sola frase de visión. Truckr es **para transportistas y expedidores** que quieren
> simplificar la búsqueda, el pago y la gestión de transportes; es un sitio donde publican y **unen
> sus disponibilidades con sus necesidades**.*

**[Marcá la línea del «diferente a» —es la que conecta con el pitch de Lucas.]**

> *Y la última línea es la clave: **a diferencia de una empresa de transporte**, Truckr le da oportunidades
> al **transportista independiente**. Eso —no competir con la flota, sino activar la que ya rueda— es lo
> que Lucas les contó al principio. Ya estaba acá, en la primera frase del proyecto.*

### 2. Es / No Es · Hace / No Hace (~25 s)

**[Avanzás a la slide «Es / No Es · Hace / No Hace». Es la slide del *alcance*.]**

> *Después marcamos los límites, porque definir un producto es sobre todo decir **que no**. Truckr **es**
> una plataforma de conexión; **no es** una mudadora de personas, ni un marketplace de compra-venta, ni
> una red social.*

**[Cue: no leas las nueve filas de «Hace». Agrupá en tres ideas y seguí.]**

> *Del lado del «hace», el corazón son tres cosas: **publicar ventanas de transporte**, **publicar cargas**,
> y **matchearlas**; alrededor, pagos seguros, reseñas, tracking y seguros. Y lo que **no** hace nos ahorró
> sprints enteros: no compramos la mercadería, no gestionamos devoluciones. **El alcance es una decisión de
> diseño, no una omisión.***

### 3. Personas (~30 s)

**[Avanzás a la slide «Personas». 10 tarjetas; NO las recorras una por una. Anclá en dos.]**

> *Para quién, lo bajamos a **diez personas** —seis del lado transportista, cuatro del lado expedidor—.
> No las voy a leer todas; les muestro **por qué importan dos de ellas.***

**[Señalás a Hugo.]**

> *Este es **Hugo**, transportista independiente, 64, malo con la tecnología, que quiere más viajes
> **pero siempre volviendo a casa con la carga llena**. Hugo es, literalmente, la persona que describe
> nuestro diferencial: aprovechar el viaje de vuelta. La tesis del pitch nació de acá.*

**[Señalás a Campos Giménez.]**

> *Y esta es **Campos Giménez**, un campo cerca de Rosario que necesita sacar su **cosecha** estacionalmente.
> Es la expedidora cuya carga van a ver en la demo —**los pallets de granos**. Las personas no son un
> ejercicio: son los protagonistas reales del producto que les acabamos de mostrar funcionando.*

**[Cue terminológico, por si el jurado pregunta: «expedidor» es nuestro término de producto para quien pide
el envío (modelo `Shipper`); «transportista» es `Carrier`. Lo fijamos en el glosario como fuente de verdad.]**

### 4. USM — User Story Map (~25 s)

**[Avanzás a la slide «USM» (la grilla A3 apaisada). Es el puente de la visión al backlog.]**

> *Y todo esto se ordena en el **User Story Map**. Arriba, la **columna vertebral**: las nueve épicas que
> recorre un usuario —Cuenta, Ventanas de Transporte, Cargas, Reservar Transportista, Envíos, Reseñas,
> Pagos, Notificaciones y Seguros—.*

**[Pasá el dedo horizontal por el backbone, después bajá a la línea del MVP.]**

> *Y abajo, lo cortamos en releases. Esta línea es el **MVP**: el camino mínimo para que una carga llegue
> de punta a punta —que es exactamente la que siguieron en la demo—. Lo de más abajo, tracking GPS, envíos
> encadenados, seguros, quedó **explícitamente** para releases posteriores.*

**[Frase de cierre del recorrido —decila mirando al jurado.]**

> *Este mapa es el que convertimos en **51 historias** y el que Matías midió como throughput. La visión,
> el alcance y las personas terminan acá, en algo construible y ordenado por valor.*

### 5. Handoff a la reflexión crítica (~10 s)

**[Cerrás el recorrido de artefactos y enganchás tu propia segunda mitad —no hay cambio de orador acá.]**

> *Ahora bien —que lo hayamos planificado así, prolijo, no quiere decir que nos salió bien a la primera.
> Déjenme contarles **el error más grande que cometimos**, que fue justo acá, en esta etapa.*

**[Pasás a tu slide de reflexión crítica. Seguís vos. → ver `guion-brian-reflexion.md` / sección de reflexión.]**

---

## Beat OPCIONAL — Riesgos (~20 s, sólo si se decide sumarlo)

> **[No entra por ahora. Si el equipo decide agregarlo, va entre el USM y el handoff, como un mosaico rápido:]**
>
> *Y sí, también mapeamos los riesgos del proyecto —técnicos, de adopción, de las dos puntas del mercado—
> con su plan de mitigación. Está en el Drive junto al resto.*
>
> **[Cue: si entra, es un «pasá-y-seguí» de 20 s, nunca un recorrido fila por fila. Mostrar que existe, no leerlo.]**

---

## Notas rápidas para Brian

- **El hilo, no las tablas.** Tu valor es la **cadena visión → alcance → personas → USM**. Cada artefacto
  es un eslabón; si leés celdas, perdés el hilo. Mostrás la slide, contás el porqué, avanzás.
- **Dos ganchos que NO podés saltear**, porque amarran tu bloque al resto de la defensa:
  - **Hugo** = el diferencial de Lucas («el viaje de vuelta») ya estaba en las personas.
  - **Campos Giménez / pallets de granos** = la carga de la demo. Las personas son reales, no decorado.
- **«Definir es decir que no».** El es/no-es y el recorte del MVP en el USM son la misma idea: el alcance
  es una **decisión**. Eso prepara el terreno para tu reflexión crítica (donde el problema fue, justamente,
  **no** haber refinado bien esa definición al principio).
- **Terminología:** «expedidor» (Shipper) / «transportista» (Carrier). Nunca «cliente» ni «productor».
  Si te preguntan por el glosario: lo construimos como **fuente de verdad** para alinear al equipo y a la IA
  —y es parte de cómo arreglamos el problema del sprint 3 (lo contás en la reflexión).
- **Tiempos:** apertura 15 s · vision 25 s · es/no-es 25 s · personas 30 s · USM 25 s · handoff 10 s ≈ **2 min**.
  Si vas apretado, lo que se comprime es el es/no-es (agrupá en «es / no es / 3 cosas que hace»), nunca los
  dos ganchos de personas.
- **No leas las slides.** El USM en A3 es denso a propósito: se muestra como *mapa*, se señala el backbone y
  la línea del MVP, no se lee.

---

*Fuentes: `docs/artifacts/product-vision.typ`, `docs/artifacts/es-no-es-hace-no-hace.typ`,
`docs/artifacts/personas.typ`, `docs/artifacts/usm.typ`; `docs/final_demo/README.md` (mapa de
expositores, bloque «Artefactos» y «Reflexión crítica»); `docs/05-appendices/glossary.md` (terminología).*
