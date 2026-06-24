---
# ── Headmatter (global config) ──────────────────────────────────────────────
theme: default
title: Truckr® — Defensa Final TP GDSI
info: |
  ## Truckr®
  El marketplace que monetiza viajes que ya iban a ocurrir.
  Defensa Final · 24/06/2026 · GDSI
author: Franco · Fernando · Brian · Matías · Tomás · Lucas
colorSchema: light
aspectRatio: 16/9
canvasWidth: 980
presenter: true
exportFilename: truckr-defensa-final
fonts:
  # Mirrors the Impeccable type stack: Unbounded display + Alegreya Sans body.
  sans: Alegreya Sans
  serif: Unbounded
  weights: '400,500,600,700'
  fallbacks: false
layout: cover
class: cover-truckr
---

# Truckr<span class="reg">®</span>

<p class="cover-sub">El marketplace que monetiza viajes que <em>ya iban a ocurrir</em>.</p>

<div class="cover-voices">
  <span class="chip chip--shipper">Expedidor</span>
  <span class="chip chip--carrier">Transportista</span>
</div>

<p class="cover-meta">Franco · Fernando · Brian · Matías · Tomás · Lucas<br>24/06/2026 — Defensa Final TP · GDSI</p>

<!--
**Todos** — abrir con energía. La Parte 1 vende, la Parte 2 demuestra cómo lo logramos. No leer las slides. Marcar el reloj mentalmente: 25 de presentación + 10 de Q&A.
-->

---
layout: default
---

# Hoja de ruta

<div class="agenda">

<div class="agenda-item voice-shipper">
<span class="agenda-num">01</span>
<div>
<h3>Parte 1 — El producto</h3>
<p>Pitch comercial + demo en vivo · ≈13 min</p>
</div>
</div>

<div class="agenda-item voice-carrier">
<span class="agenda-num">02</span>
<div>
<h3>Parte 2 — El proceso</h3>
<p>IA, métricas y aprendizajes · ≈12 min</p>
</div>
</div>

</div>

<p class="foot">35 min totales · 25 de presentación + 10 de Q&amp;A</p>

<!--
**Todos** — la Parte 1 vende, la Parte 2 demuestra cómo lo logramos. Una idea por slide; el detalle va en la voz, no en la pantalla.
-->

---
layout: section
class: section-shipper
---

<span class="kicker">Parte 1</span>

# El producto

<p class="section-by">Lucas</p>

<!--
**Lucas** arranca con el pitch. Energía de venta — estás vendiendo a inversores, no rindiendo un TP.
-->

---
layout: default
---

# El problema

<p class="thesis">El mercado está fragmentado. Hay expedidores y hay transportistas, pero <span class="hl-shipper">no se encuentran</span>.</p>

<v>

- El transportista independiente depende de intermediarios.
- Mercado fragmentado e informal: funciona a fuerza de contactos y teléfono.
- El expedidor no tiene forma confiable ni transparente de conseguir transportistas.

</v>

<!--
**Lucas** — pintá el dolor en 30 s: un mercado roto donde oferta y demanda no se ven. El público tiene que **sentir** el problema antes de la solución.
-->

---
layout: default
---

# El diferencial

<p class="thesis">Truckr matchea la carga del expedidor con <span class="hl-shipper">viajes que el transportista ya tenía planificados</span>.</p>

<v>

- El camión que volvía vacío ahora carga y cobra.
- Truckr vs. la competencia: no **creamos** oferta, **aprovechamos la que ya rueda**.
- El transportista cobra un viaje que igual hacía · el expedidor paga menos · nosotros tomamos la diferencia.

</v>

<!--
**Lucas** — **Este** es el mensaje de la defensa. Decilo lento. El camión vacío es el **diferencial**, no el problema: nos separa de la competencia (ellos crean oferta, nosotros usamos la que ya rueda). Acá va el dato del % de viajes en vacío. «Oferta ya existente» = por qué un inversor apuesta. Cerrá pasando a Franco para la demo.
-->

---
layout: center
class: demo-slide
---

<div class="demo-stage">

# Demo en vivo

<div class="demo-chips">
<span class="chip chip--shipper">Expedidor</span>
<span class="arrow">→</span>
<span class="chip chip--carrier">Transportista</span>
</div>

<p class="demo-sub">Un hilo · una carga · de punta a punta</p>

</div>

<!--
**Franco + Fernando** — a partir de acá se comparte pantalla / proyector con el **producto real**. Esta slide es solo el cartel de transición.

**ANTES de exponer:** resetear el seed (`db:seed:demo`) + tener el **fallback grabado** abierto en otra pestaña por si falla la red.

**Flujo — Franco (Expedidor):** publica «Pallets de granos» → el sistema muestra **solo** las ventanas de transporte compatibles (el «wow» del diferencial) → envía la oferta.

**Handoff sin cortar el hilo:** «…y acá entra el transportista».

**Fernando (Transportista):** acepta → *start* / *deliver* → pago + notificación en tiempo real → reseñas mutuas.

**Cierre volviendo al valor:** «esto que vieron lo construyeron 6 personas en 5 semanas — ahora les contamos cómo».
-->

---
layout: section
class: section-process
---

<span class="kicker">Parte 2</span>

# El proceso

<p class="section-by">Tomás</p>

<!--
**Tomás** abre la Parte 2. Cambiamos el registro: de vender a demostrar el método.
-->

---
layout: default
class: flow-slide
---

<span class="by">IA · El flujo de desarrollo</span>

# El flujo tradicional<span v-click class="h1-tag h1-tag--ia">+ IA</span><span v-click class="h1-tag h1-tag--noest">+ #NoEstimates</span>

<div class="flow" :class="{ 'flow--ia': $clicks >= 1, 'flow--noest': $clicks >= 2 }">
  <span class="step step-up">Requisitos</span>
  <span class="step-arrow">→</span>
  <span class="step step-est">Estimar</span>
  <span class="step-arrow step-arrow--est">→</span>
  <span class="step step-up">Diseño</span>
  <span class="step-arrow">→</span>
  <span class="step step-dev">Implementación</span>
  <span class="step-arrow">→</span>
  <span class="step step-dev">Testing</span>
  <span class="step-arrow">→</span>
  <span class="step step-dep">Deploy</span>
</div>

<!--
**Tomás** — BEAT 0: el ciclo tradicional, el grueso del esfuerzo cae en **implementación y testing**.
CLICK 1 (+IA): la IA colapsa implementación y testing a casi cero; ese tiempo lo **invierto en requisitos y diseño** — qué valor entrego y cómo lo resuelvo.
CLICK 2 (+#NoEstimates): se cae **estimar** del ciclo; ese costo también lo dedicás a requisitos y diseño. No leas las barras: contás la historia, las barras la muestran.
-->


---
layout: default
---

<span class="by">IA · RPI</span>

# Research → Plan → Implement

<div class="rpi">

<v-click>
<div class="rpi-card">
  <span class="rpi-step">Research</span>
  <p class="rpi-io">User story <span class="rpi-arrow">→</span> Issue</p>
  <p class="rpi-desc">Criterios de aceptación ya <strong>en términos de código</strong>.</p>
</div>
</v-click>

<v-click>
<div class="rpi-card">
  <span class="rpi-step">Plan</span>
  <p class="rpi-io">Issue <span class="rpi-arrow">→</span> Markdown</p>
  <p class="rpi-desc">Una solución diseñada, <strong>línea por línea</strong>.</p>
</div>
</v-click>

<v-click>
<div class="rpi-card rpi-card--cheap">
  <span class="rpi-step">Implement</span>
  <p class="rpi-io">Plan <span class="rpi-arrow">→</span> Código</p>
  <p class="rpi-desc">Nada más que ejecutar el plan. <strong>Barato</strong>.</p>
</div>
</v-click>

</div>

<!--
**Tomás** — lo más jugoso. Apertura: solo el título. «Implementar esta US» lo partimos en tres.
CLICK 1 **Research**: deseo de alto nivel (US) → issue de GitHub con criterios en términos de código.
CLICK 2 **Plan**: issue → markdown con la solución diseñada, línea por línea.
CLICK 3 **Implement**: implementar el plan, y nada más.
DE VIVA VOZ (sin click): ¿por qué partirlo en tres? Para **reducir el costo del error de alineamiento**. Un error en research, si llega a implementación, genera una **cascada cara**; lo atajamos arriba, donde corregir es barato.
HANDOFF: con el grueso en research y plan, la pregunta deja de ser «cuánto cuesta» y pasa a «cuánto entregamos». De medir en vez de estimar habla **Matías**.
-->

---
layout: default
---

<span class="by">IA · Concurrencia</span>

# ¿Qué hago mientras el agente trabaja?

<div class="wt" :class="{ 'is-clash': $clicks === 1, 'is-safe': $clicks >= 2 }">

  <div class="wt-card">
    <span class="wt-name">Agente A</span>
    <dl class="wt-cfg">
      <dt>working tree</dt>
      <dd><code>{{ $clicks >= 2 ? '~/trukr/.claude/worktrees/feature-A' : '~/trukr' }}</code></dd>
      <dt>backend</dt>
      <dd><code>:3000</code></dd>
      <dt>frontend</dt>
      <dd><code>:5173</code></dd>
      <dt>DB</dt>
      <dd><code>{{ $clicks >= 2 ? 'db_A.sqlite3' : 'db.sqlite3' }}</code></dd>
    </dl>
  </div>

  <div class="wt-verdict">
    <span class="wt-pill wt-pill--bad" v-if="$clicks === 1">✕ Colisiona</span>
    <span class="wt-pill wt-pill--ok" v-click="2">✓ Aislados</span>
  </div>

  <div class="wt-card" v-click="1">
    <span class="wt-name">Agente B</span>
    <dl class="wt-cfg">
      <dt>working tree</dt>
      <dd><code>{{ $clicks >= 2 ? '~/trukr/.claude/worktrees/feature-B' : '~/trukr' }}</code></dd>
      <dt>backend</dt>
      <dd><code>{{ $clicks >= 2 ? ':3001' : ':3000' }}</code></dd>
      <dt>frontend</dt>
      <dd><code>{{ $clicks >= 2 ? ':5174' : ':5173' }}</code></dd>
      <dt>DB</dt>
      <dd><code>{{ $clicks >= 2 ? 'db_B.sqlite3' : 'db.sqlite3' }}</code></dd>
    </dl>
  </div>

</div>

<p class="wt-foot" v-if="$clicks === 1">Misma rama · mismo <code>:3000</code> · misma <code>db.sqlite3</code> — se pisan.</p>
<p class="wt-foot wt-foot--ok" v-else-if="$clicks >= 2">Branch, puertos y DB propios por worktree (no un <code>cp</code>) · de pedirlo cada vez a una <strong>skill</strong>.</p>

<!--
**Tomás** — BEAT 0 (Agente A solo): armo la US, la delego, y me quedo mirándolo — inaceptable, es tiempo mío.
CLICK 1 (aparece Agente B, todo en rojo): disparo otro issue a otro agente en el mismo directorio — misma working tree, mismo `:3000`/`:5173`, misma `db.sqlite3`. Todo idéntico → **colisionan**.
CLICK 2 (la config se vuelve azul y distinta): adoptamos **git worktrees** (un dir en su propia branch bajo el mismo VCS, no es un `cp`) + **puertos aleatorios**. Cada agente: su worktree, su puerto, su DB → **aislados**. Se lo pedís a Claude cada sesión… o lo convertís en **skill**.
-->

---
layout: default
class: attn-slide
clicks: 3
---

<span class="by">IA · Atención</span>

# El techo es mi atención

<div class="attn" :class="{ 'is-split': $clicks >= 1, 'is-starved': $clicks >= 2, 'c1': $clicks >= 1, 'c2': $clicks >= 2, 'c3': $clicks >= 3 }">
  <div class="attn-min"><span>mínimo útil</span></div>
  <div class="attn-track">
    <div class="attn-seg" v-for="n in 2 ** $clicks" :key="n">
      <span class="seg-pct">{{ +(100 / 2 ** $clicks).toFixed(1) }}%</span>
    </div>
  </div>
  <!-- <div class="attn-cap">
    <span class="cap cap-0">1 sesión: todo tu presupuesto va a una.</span>
    <span class="cap cap-1">2 sesiones: la atención se divide, no se multiplica.</span>
    <span class="cap cap-2">4 sesiones: cada tajada cae bajo el mínimo útil.</span>
    <span class="cap cap-3">8 sesiones: el context switch te deja sin atención.</span>
  </div> -->
</div>


<!--
**Tomás** — BEAT 0: mi atención es un presupuesto fijo, 100%. Con una sola sesión va todo ahí.
CLICK 1 (2 sesiones · 50%): si abro otra, ¿por qué no duplico? Pero la atención no se multiplica: **se divide**. Con dos, todavía cada una zafa.
CLICK 2 (4 sesiones · 25%): la duplico otra vez y cada tajada cae **bajo el mínimo útil** — y el **context switch cuesta** (todos programamos concurrente en esta cátedra).
CLICK 3 (8 sesiones · 12,5%): el overhead supera el beneficio. Para tareas pesadas no pasás de **2, 3 con furia**; sumales 2–3 **livianas** que se hacen casi solas.
-->


---
layout: default
---

<span class="by">No Estimates · Nivel 1</span>

# ¿Por qué #NoEstimates?

<v-clicks>

- **Story points**: Generan tiempo de discusión + ilusión de precisión.
- **#NoEstimates**: Reemplazar estimaciones por mediciones y proyecciones.
- Condición: US de esfuerzo uniforme.

</v-clicks>

<v-click>

<div style="display:grid; grid-template-columns:1fr 1fr; gap:12px; margin-top:1rem; font-size:0.82rem;">
<div style="background:var(--surface-cool); border:1px solid var(--border-sky); border-radius:var(--radius-md); padding:12px 16px;">
<p style="font-family:var(--font-display); font-weight:700; color:var(--accent); margin:0 0 8px 0; font-size:0.75rem; letter-spacing:0.06em; text-transform:uppercase;">Ventajas</p>
<ul style="margin:0; padding-left:14px; line-height:1.8;">
<li>Ahorro de tiempo</li>
<li>Datos Reales</li>
</ul>
</div>
<div style="background:#fff5f5; border:1px solid #fecaca; border-radius:var(--radius-md); padding:12px 16px;">
<p style="font-family:var(--font-display); font-weight:700; color:#dc2626; margin:0 0 8px 0; font-size:0.75rem; letter-spacing:0.06em; text-transform:uppercase;">Trade-off</p>
<ul style="margin:0; padding-left:14px; line-height:1.8;">
<li>Baja precisión al inicio</li>
</ul>
</div>
</div>

</v-click>

<!--
**Matías** — arrancás después de Tomás. Él dijo que la IA abarató el código. Vos continuás: si el código no cuesta, estimarlo tampoco aporta. Presentá los trade-offs con honestidad — el ❌ de «≥ 2 sprints» lo usarás en la siguiente slide para explicar la fase de calibración.
-->

---
layout: default
---

<span class="by">No Estimates · Nivel 2</span>

# Calibrar · Medir · Proyección

1. **Calibrar** (S1–S2) — datos con alta varianza.
2. **Medir** — contar el throughput por sprint.
3. **Proyección** — con un Burn-up Chart y simulación de Monte Carlo.

<v-click>

<p class="thesis" style="margin-top:5rem; max-width:none;">No es "dejar de gestionar". Es gestionar con <span class="hl-carrier">datos</span>.</p>

</v-click>

<!--
**Matías** — contá los tres tiempos con los dedos. El punto central: esta fue una decisión consciente, no una improvisación. El equipo eligió no comprometerse hasta tener datos. Eso es rigor.
-->

---
layout: default
---

<span class="by">No Estimates · Nivel 3</span>

# Proyecciones <span style="font-weight:400;color:var(--ink-2);font-size:0.6em;">· Sprint 2</span>

<div style="display:flex;justify-content:center;margin-top:0.5rem;">
  <img src="./sprint-02-burnup.png" style="max-height:380px;max-width:100%;object-fit:contain;" />
</div>

<!--
**Matías** — primer tiempo. Burn-up reconstruido al cierre del Sprint 2 (`team_performance --as-of-sprint 2`). Las barras azules son las US del MVP completadas (3 → 18); las rojas, lo que falta para el techo de 52. La recta diagonal ámbar es la proyección: su pendiente es el throughput medio de ese momento (9 US/sprint) y, prolongada hasta el techo del MVP, cruza en el **sprint ~5,8** (la vertical punteada). Esa es la primera lectura: «si seguimos así, cerramos cerca del 5,8».
-->

---
layout: default
---

<span class="by">No Estimates · Nivel 3</span>

# Proyecciones <span style="font-weight:400;color:var(--ink-2);font-size:0.6em;">· + Sprint 3</span>

<div style="display:flex;justify-content:center;margin-top:0.5rem;">
  <img src="./sprint-03-burnup.png" style="max-height:380px;max-width:100%;object-fit:contain;" />
</div>

<!--
**Matías** — segundo tiempo. Se agrega la columna del Sprint 3 (27 US) y **su** recta de proyección (azul), pero **no borro la del Sprint 2**: quedan superpuestas. El throughput medio sigue en 9 US/sprint, así que la recta nueva apunta al **mismo ~5,8**. El mensaje es la consistencia: dos sprints seguidos confirman la misma fecha de cierre.
-->

---
layout: default
---

<span class="by">No Estimates · Nivel 3</span>

# Proyecciones <span style="font-weight:400;color:var(--ink-2);font-size:0.6em;">· + Sprint 4</span>

<div style="display:flex;justify-content:center;margin-top:0.5rem;">
  <img src="./sprint-04-burnup.png" style="max-height:380px;max-width:100%;object-fit:contain;" />
</div>

<!--
**Matías** — tercer tiempo, el remate. Se agrega la columna del Sprint 4 (41 US) y la tercera recta (negra), superpuesta sobre las dos anteriores. El throughput sube a **10,25 US/sprint**: la pendiente se empina y el cruce con el techo se **adelanta al ~5,1**. Ahí está la historia completa en un solo gráfico: tres proyecciones conviviendo, la pendiente mejorando sprint a sprint. Son las mismas proyecciones del análisis de team performance (`--as-of-sprint 2/3/4`), reconstruibles y auditables. El burn-up decía «cerramos en ~5» — el Sprint 5 lo confirmó.
-->

---
layout: default
---

<span class="by">No Estimates · Nivel 4</span>

# Simulación de Monte Carlo

<p style="font-size:0.88rem; margin-bottom:1.4rem; color:var(--ink-2);">Bootstrap de 10 000 muestras sobre el throughput histórico — cierre del <strong>Sprint 4</strong>.</p>

<div style="display:grid; grid-template-columns:1fr 1fr; gap:20px; align-items:center;">

<div style="background:#f0fdf4; border:2px solid #16a34a; border-radius:var(--radius-md); padding:28px 32px; text-align:center;">
  <div style="font-size:0.8rem; color:var(--ink-2); margin-bottom:4px;">11 US restantes · horizonte 2 sprints</div>
  <div style="color:#16a34a; font-weight:700; font-size:3.5rem; line-height:1;">93.6%</div>
  <div style="font-size:0.8rem; color:#16a34a; margin-top:4px; font-weight:600;">de completar el MVP en el Sprint 5 o 6</div>
</div>

<div style="font-size:0.88rem; line-height:1.8;">
  <p style="margin:0 0 10px 0;"><strong>Cómo funciona:</strong> se resamplean los throughputs históricos (3, 15, 9, 14 US/sprint) 10 000 veces y se mide en qué fracción de escenarios se llega a 52 US dentro del horizonte.</p>
  <p style="margin:0; color:var(--ink-2);">El horizonte era los <strong>Sprints 5 y 6</strong>. El equipo terminó en el <strong>Sprint 5</strong>.</p>
</div>

</div>

<v-click>

<p style="margin-top:1.6rem; font-size:0.95rem;"><strong>93.6% de completar el MVP en los sprints 5 o 6 — el Sprint 5 lo confirmó.</strong></p>

</v-click>

<!--
**Matías** — el bloque izquierdo habla solo: 93.6%, verde, grande. Explicá el lado derecho en voz: «resampleamos los throughputs reales 10 000 veces y medimos cuántas veces llegamos a 52 US». El horizonte era Sprint 6 — terminamos en Sprint 5. Eso no es suerte: es que el throughput mejoró sprint a sprint y la simulación lo capturó. Pausa real después del remate.
-->

---
layout: section
class: section-process
---

<span class="kicker">Parte 2 · artefactos</span>

# Artefactos y aprendizajes

<p class="section-by">Brian</p>

<!--
**Brian** — artefactos + reflexión crítica. Venís después de Matías (no-estimates + throughput).
Tu bloque es la bisagra de la Parte 2: probás que el trabajo real se movió aguas arriba, a la planificación.
Frase-ancla: «Antes de escribir una línea de código, definimos el producto. Esa fue la parte difícil.»
-->

---
layout: default
---

# Antes de escribir una línea de código

<p class="thesis">Recién vieron cuánto entregamos. Ahora les muestro <strong>lo que hicimos preliminarmente</strong>: definición del producto con una <span class="hl-carrier">Lean Inception</span>.</p>

<v-clicks>

- La IA abarata el código a casi cero, el trabajo real es: **decidir qué construir y para quién**.
- La cadena: **Visión → Alcance → Personas → USM**.

</v-clicks>

<!--
**Brian** — no expliques qué es una Lean Inception en abstracto: mostrá los pedazos.
-->

---
layout: default
---

<span class="by">Lean Inception · 1 de 4</span>

# Product Vision

<div style="margin-top: 1rem;">
<table style="width:100%; border-collapse:collapse; font-family:var(--font-display); font-size:0.95rem;">
  <tbody>
    <tr style="background:var(--surface-cool); border-bottom:1px solid var(--border-sky);">
      <td style="padding:10px 14px; font-weight:700; color:var(--accent); width:120px; white-space:nowrap;">Para</td>
      <td style="padding:10px 14px;">transportistas y expedidores</td>
    </tr>
    <tr style="border-bottom:1px solid var(--border);">
      <td style="padding:10px 14px; font-weight:700; color:var(--accent);">Quienes</td>
      <td style="padding:10px 14px;">buscan simplificar el proceso de búsqueda, pago y gestión de transportes</td>
    </tr>
    <tr style="background:var(--surface-cool); border-bottom:1px solid var(--border-sky);">
      <td style="padding:10px 14px; font-weight:700; color:var(--accent);">Es un</td>
      <td style="padding:10px 14px;">sitio web de contratación de servicios de transporte de bienes</td>
    </tr>
    <tr style="border-bottom:1px solid var(--border);">
      <td style="padding:10px 14px; font-weight:700; color:var(--accent);">Que</td>
      <td style="padding:10px 14px;">permite a transportistas y expedidores publicar y <strong>unir sus disponibilidades y necesidades</strong></td>
    </tr>
    <tr style="background:var(--surface-cool); border-bottom:1px solid var(--border-sky);">
      <td style="padding:10px 14px; font-weight:700; color:var(--accent);">Diferente a</td>
      <td style="padding:10px 14px;">las empresas de transporte</td>
    </tr>
    <tr>
      <td style="padding:10px 14px; font-weight:700; color:var(--accent);">Nuestro producto</td>
      <td style="padding:10px 14px;"><span class="hl-carrier">ofrece oportunidades individuales a transportistas independientes</span></td>
    </tr>
  </tbody>
</table>
</div>

<!--
**Brian** — señalá la última fila: «ofrece oportunidades individuales a transportistas independientes».
Esa línea ES el pitch de Lucas. El pitch no surgió de la nada: estaba acá desde el día 1.
-->

---
layout: default
---

<span class="by">Lean Inception · 2.1 de 4</span>

# Es / No Es

<div style="display:grid; grid-template-columns:1fr 1fr; gap:16px; margin-top:0.8rem; font-size:0.88rem;">

<div style="background:var(--surface-cool); border:1px solid var(--border-sky); border-radius:var(--radius-md); padding:16px 20px;">
  <p style="font-family:var(--font-display); font-weight:700; color:var(--accent); margin:0 0 10px 0; font-size:0.8rem; letter-spacing:0.07em; text-transform:uppercase;">✓ Es</p>
  <ul style="margin:0; padding-left:16px; line-height:1.6;">
    <li>Una plataforma de conexión entre transportistas y expedidores</li>
    <li>Un sitio web y potencialmente una app mobile</li>
    <li>...</li>
  </ul>
</div>

<div style="background:#fff5f5; border:1px solid #fecaca; border-radius:var(--radius-md); padding:16px 20px;">
  <p style="font-family:var(--font-display); font-weight:700; color:#dc2626; margin:0 0 10px 0; font-size:0.8rem; letter-spacing:0.07em; text-transform:uppercase;">✗ No Es</p>
  <ul style="margin:0; padding-left:16px; line-height:1.6;">
    <li>Una empresa de traslado de personas</li>
    <li>Una plataforma de compra/venta de bienes</li>
    <li>...</li>
  </ul>
</div>

</div>

---
layout: default
---

<span class="by">Lean Inception · 2.2 de 4</span>

# Hace / No Hace

<div style="display:grid; grid-template-columns:1fr 1fr; gap:16px; margin-top:0.8rem; font-size:0.88rem;">

<div style="background:var(--surface-2); border:1px solid var(--border-cream); border-radius:var(--radius-md); padding:16px 20px;">
  <p style="font-family:var(--font-display); font-weight:700; color:var(--accent); margin:0 0 10px 0; font-size:0.8rem; letter-spacing:0.07em; text-transform:uppercase;">✓ Hace</p>
  <ul style="margin:0; padding-left:16px; line-height:1.6;">
    <li>Publica ventanas de transporte y cargas</li>
    <li>Registra ubicación y capacidades de vehículos</li>
    <li>...</li>
  </ul>
</div>

<div style="background:#fff5f5; border:1px solid #fecaca; border-radius:var(--radius-md); padding:16px 20px;">
  <p style="font-family:var(--font-display); font-weight:700; color:#dc2626; margin:0 0 10px 0; font-size:0.8rem; letter-spacing:0.07em; text-transform:uppercase;">✗ No Hace</p>
  <ul style="margin:0; padding-left:16px; line-height:1.6;">
    <li>No ofrece la compra del producto a transportar</li>
    <li>No permite devoluciones</li>
    <li>...</li>
  </ul>
</div>

</div>

<!--
**Brian** — señalá los "No Hace": cada uno es un sprint que no tiramos.
«El alcance es una decisión de diseño» — esta grilla es la prueba.
-->

---
layout: default
---

<span class="by">Lean Inception · 3 de 4 — 10 personas: 6 transportistas, 4 expedidores</span>

# Personas

<div style="display:grid; grid-template-columns:1fr 1fr; gap:16px; margin-top:0.6rem; font-size:0.88rem;">

<div style="background:var(--surface-2); border:1px solid var(--border-cream); border-radius:var(--radius-md); padding:12px 16px;">
  <div style="margin-bottom:8px;">
    <p style="font-family:var(--font-display); font-weight:700; font-size:1rem; margin:0 0 4px 0;">Hugo</p>
    <span class="chip chip--carrier">Transportista</span>
  </div>
  <ul style="margin:0; padding-left:14px; line-height:1.6;">
    <li>64 años, transportista independiente</li>
    <li>Quiere más viajes <strong>volviendo con la carga llena</strong></li>
    <li style="color:var(--accent); font-weight:600;">= El diferencial: el viaje de vuelta</li>
  </ul>
</div>

<div style="background:var(--surface-cool); border:1px solid var(--border-sky); border-radius:var(--radius-md); padding:12px 16px;">
  <div style="margin-bottom:8px;">
    <p style="font-family:var(--font-display); font-weight:700; font-size:1rem; margin:0 0 4px 0;">Campos Giménez</p>
    <span class="chip chip--shipper">Expedidor</span>
  </div>
  <ul style="margin:0; padding-left:14px; line-height:1.6;">
    <li>Campo cerca de Rosario · cosecha estacional</li>
    <li>Carga: <strong>pallets de granos</strong></li>
    <li style="color:var(--accent); font-weight:600;">= La carga que se quiere transportar</li>
  </ul>
</div>

</div>

<!--
**Brian** — dos ganchos que NO saltear:
· Hugo = el diferencial de Lucas («el viaje de vuelta») ya estaba en las personas.
· Campos Giménez / pallets de granos = la carga de la demo. No son decorado.
-->

---
layout: default
---

<span class="by">Lean Inception · 4 de 4</span>

# User Story Map

<div style="margin-top:0.6rem; overflow:hidden;">

<div style="display:grid; grid-template-columns:repeat(9,1fr); gap:5px; font-size:0.62rem;">

<div style="background:var(--accent); color:white; border-radius:8px; padding:6px 8px; font-family:var(--font-display); font-weight:700; text-align:center;">Cuenta</div>
<div style="background:var(--accent); color:white; border-radius:8px; padding:6px 8px; font-family:var(--font-display); font-weight:700; text-align:center;">Ventanas</div>
<div style="background:var(--accent); color:white; border-radius:8px; padding:6px 8px; font-family:var(--font-display); font-weight:700; text-align:center;">Cargas</div>
<div style="background:var(--accent); color:white; border-radius:8px; padding:6px 8px; font-family:var(--font-display); font-weight:700; text-align:center;">Reservar</div>
<div style="background:var(--accent); color:white; border-radius:8px; padding:6px 8px; font-family:var(--font-display); font-weight:700; text-align:center;">Envíos</div>
<div style="background:var(--accent); color:white; border-radius:8px; padding:6px 8px; font-family:var(--font-display); font-weight:700; text-align:center;">Reseñas</div>
<div style="background:var(--accent); color:white; border-radius:8px; padding:6px 8px; font-family:var(--font-display); font-weight:700; text-align:center;">Pagos</div>
<div style="background:var(--accent); color:white; border-radius:8px; padding:6px 8px; font-family:var(--font-display); font-weight:700; text-align:center;">Notif.</div>
<div style="background:var(--accent); color:white; border-radius:8px; padding:6px 8px; font-family:var(--font-display); font-weight:700; text-align:center;">Seguros</div>

<div style="background:var(--surface-cool); border:1px solid var(--border-sky); border-radius:6px; padding:5px 7px;">US001 Registro</div>
<div style="background:var(--surface-cool); border:1px solid var(--border-sky); border-radius:6px; padding:5px 7px;">US009 Publicar</div>
<div style="background:var(--surface-cool); border:1px solid var(--border-sky); border-radius:6px; padding:5px 7px;">US027 Publicar</div>
<div style="background:var(--surface-cool); border:1px solid var(--border-sky); border-radius:6px; padding:5px 7px;">US004 Buscar</div>
<div style="background:var(--surface-cool); border:1px solid var(--border-sky); border-radius:6px; padding:5px 7px;">US017 Listado</div>
<div style="background:var(--surface-cool); border:1px solid var(--border-sky); border-radius:6px; padding:5px 7px;">US020 Crear</div>
<div style="background:var(--surface-cool); border:1px solid var(--border-sky); border-radius:6px; padding:5px 7px;">US008 Pago</div>
<div style="background:var(--surface-cool); border:1px solid var(--border-sky); border-radius:6px; padding:5px 7px;">US058 Oferta</div>
<div style="background:#f3f4f6; border:1px solid #e5e7eb; border-radius:6px; padding:5px 7px; color:#9ca3af;">Release 2</div>

<div style="background:var(--surface-cool); border:1px solid var(--border-sky); border-radius:6px; padding:5px 7px;">US002 Login</div>
<div style="background:var(--surface-cool); border:1px solid var(--border-sky); border-radius:6px; padding:5px 7px;">US043 Admin.</div>
<div style="background:var(--surface-cool); border:1px solid var(--border-sky); border-radius:6px; padding:5px 7px;">US044 Admin.</div>
<div style="background:var(--surface-cool); border:1px solid var(--border-sky); border-radius:6px; padding:5px 7px;">US007 Ofertar</div>
<div style="background:var(--surface-cool); border:1px solid var(--border-sky); border-radius:6px; padding:5px 7px;">US018 Inicio</div>
<div style="background:var(--surface-cool); border:1px solid var(--border-sky); border-radius:6px; padding:5px 7px;">US026 Ver</div>
<div style="background:var(--surface-cool); border:1px solid var(--border-sky); border-radius:6px; padding:5px 7px;">US015 Al transp.</div>
<div style="background:var(--surface-cool); border:1px solid var(--border-sky); border-radius:6px; padding:5px 7px;">US060 Pago</div>
<div style="background:#f3f4f6; border:1px solid #e5e7eb; border-radius:6px; padding:5px 7px; color:#9ca3af;">Release 2</div>

</div>

<div style="margin-top:10px; display:flex; align-items:center; gap:10px;">
  <div style="height:3px; flex:1; background:linear-gradient(90deg, var(--brand-primary), var(--brand-secondary)); border-radius:2px;"></div>
  <span style="font-family:var(--font-display); font-weight:700; font-size:0.7rem; color:var(--accent); white-space:nowrap;">↑ MVP · 51 historias</span>
  <div style="height:3px; flex:1; background:linear-gradient(90deg, var(--brand-secondary), var(--brand-primary)); border-radius:2px;"></div>
</div>

</div>

<!--
**Brian** — pasá el dedo horizontal por el backbone (fila de colores oscuros).
Bajá a la línea del MVP — exactamente lo que siguieron en la demo.
«La visión, el alcance y las personas terminan acá, en algo construible y ordenado por valor.»
-->

---
layout: default
---

# El error que más nos costó

<v-clicks>

- **Confiamos de más en la IA justo en la planificación** — lo que más importa.
- Le delegamos el refinamiento de user stories **sin bajarlas a una especificación de verdad** → descubríamos lo vagas que eran recién al implementar.
- Resultado: **refactors y reimplementación en los sprints 1 y 2** — tiempo que tiramos.
- Debajo, un problema más sutil: **desalineación de conceptos** — el mismo dominio con tres nombres distintos; la IA heredaba esa confusión y la multiplicaba en el código.

</v-clicks>

<!--
**Brian** — bajá el ritmo. Cambiás del tono expositivo a uno honesto, casi confesional.
Pausa después del primer bullet — dejá que pegue.
-->

---
layout: default
---

# Cómo lo corregimos

<p class="thesis">A partir del <strong>sprint 3</strong>, dos movidas concretas:</p>

<v-clicks>

1. **Tomamos las riendas de la planificación** — dejamos de delegarle a la IA la definición y pasamos a usarla para ejecutarla.
2. **Glosario como única fuente de verdad** — cada término del dominio, un solo nombre, una sola definición, para alinear el modelo mental del equipo **y** el de la IA.

</v-clicks>

<v-click>

> Desde ahí, los conceptos dejaron de chocar, las US dejaron de ser ambiguas, y el rework se desplomó. No por casualidad el throughput se estabiliza **justo cuando tomamos esta decisión**.

</v-click>

<!--
**Brian** — acá levantás de nuevo: del error a la decisión. Esto demuestra madurez de equipo.
El glosario es real: docs/05-appendices/glossary.md — si preguntan, es tu prueba concreta.
Remate: «Este error no contradice nuestra tesis. La confirma. La IA acelera la ejecución,
pero no reemplaza la definición — cuando se la delegamos entera, lo pagamos.»
-->

<!--
**Lucas** — cierre fuerte y corto. Una frase, pausa, «gracias». Roles (encuadre b): dueños de valor + Tomás en gestión, por si preguntan en el Q&A.
-->

---
layout: center
class: closing
---

<p class="thesis">La IA no reemplaza la definición del problema: la acelera <em>si es que vos ya la tenés clara</em>.</p>

---
layout: center
class: thanks
---

# ¡Gracias!

<p>Truckr® | Franco · Fernando · Brian · Matías · Tomás · Lucas</p>

<!--
**Todos** — Q&A: 10 min. Repasar las 5 preguntas filosas del README antes de subir. Cada uno con su respuesta a «¿qué hiciste vos vs. la IA?». Nadie se retira del aula hasta el final del turno (afecta la nota individual).
-->
