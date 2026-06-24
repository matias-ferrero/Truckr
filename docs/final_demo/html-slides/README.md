# Deck HTML — Truckr® Defensa Final

Deck **web/HTML** de la defensa (la única versión: el deck Typst quedó descartado).
6 bloques, una idea por slide, con notas de orador — renderizado con arquitectura web y
**reutilizando los design tokens reales del frontend** (Impeccable), así las slides y el
producto comparten una sola paleta.

---

## Por qué Slidev (research)

Se evaluaron las librerías TypeScript/JS para generar slides con arquitectura web:

| Librería | Base | Notas de orador | Export | Veredicto |
|---|---|---|---|---|
| **Slidev** ✅ | Vue 3 + Vite + TS | Sí, por slide (markdown) | PDF · **PPTX** · PNG · SPA | **Elegida** |
| Reveal.js | HTML/JS puro | Plugin | PDF (print) | Más bajo nivel, todo manual |
| Spectacle | React | Sí (componente) | PDF | Deck-as-JSX, más verboso |
| Marp | Markdown | Limitadas | PDF/PPTX | Menos control de layout/CSS |

**Slidev gana** para este caso porque:

1. **Notas de orador por slide** (markdown) — tenemos 6 expositores, cada bloque con sus cues.
   La vista de presentador (`presenter: true`) las muestra en la segunda pantalla.
2. **Export a PPTX** → se importa a **Google Slides**, que es el formato que pide la rúbrica
   del Drive. Y export a PDF para el handout.
3. **Markdown** → el equipo edita el contenido sin tocar componentes.
4. **CSS-first** → los tokens de Impeccable entran **tal cual** (custom properties), sin port.
5. Vite/HMR → live-reload mientras se ensaya.

> Slidev es Vue por dentro, pero el contenido es markdown + HTML + CSS: no hace falta saber Vue
> para mantenerlo.

---

## Tokens de Impeccable, reutilizados directos

`styles/tokens.css` es una **copia verbatim** del bloque `:root` de
`frontend/src/styles/global.css` (la fuente de verdad, espejada por `tailwind.css` y
`landing.css`). No se reescribieron valores: el deck consume los mismos
`--brand-primary` (sky / Expedidor), `--brand-secondary` (saffron / Transportista),
`--ink`, `--accent` (Deep Harbor), espaciado, radios, sombras y tipografía
(**Unbounded** display + **Alegreya Sans** body).

`styles/theme.css` mapea esos tokens al DOM de Slidev, respetando las reglas de `DESIGN.md`:

- **Two-Voice Rule** — sky = Expedidor, saffron = Transportista. Los colores de rol se usan
  **solo** en el producto (Parte 1) y en los chips; las slides de proceso (Parte 2) van con
  ink + el acento Deep Harbor.
- **No-Pure-Neutral** — nunca `#000`/`#fff` en texto/estados.
- **Single-Display** — Unbounded para todo display; Alegreya Sans en cuerpo.
- **Pill-or-Container** — radio pill solo en chips; cards en 16/24px.

> Si un token cambia en el frontend, re-copiar el `:root` a `styles/tokens.css` y el deck
> queda alineado automáticamente.

---

## Uso

Requiere Node (hay `node` vía mise). Desde esta carpeta:

```sh
npm install            # instala slidev + tema + vue
npm run dev            # live-reload en el navegador (vista normal)
# vista de presentador con notas: abrir /presenter sobre la URL del dev server
```

Export para el Drive / fallback:

```sh
npm run export         # → truckr-defensa-final.pdf
npm run export:pptx    # → truckr-defensa-final.pptx  (importar a Google Slides)
```

> El export necesita `playwright-chromium`; Slidev lo pide la primera vez (`npx playwright install`).

Estructura:

```
html-slides/
├── slides.md          # el deck (markdown + HTML + notas de orador)
├── styles/
│   ├── index.ts       # auto-import: tokens → theme
│   ├── tokens.css     # tokens de Impeccable, VERBATIM del frontend
│   └── theme.css      # mapea tokens al DOM de Slidev
├── package.json
└── .gitignore         # node_modules, dist, exports
```

---

## Pendientes (idénticos al deck Typst)

Los marcadores `.proof-slot` (cajas punteadas) señalan dónde reemplazar por la captura real:

- [ ] PR rechazado por un hook (IA nivel 1).
- [ ] PDF de `team_performance` + un SPRINT-N-PLAN (IA nivel 2).
- [ ] Gráfico de la curva de throughput (IA nivel 3 / Tomás).
- [ ] PDF de forecast con p50/p85/p95 + **predicho vs. real** (Tomás).
- [ ] USM + collage de Lean Inception (Lucas).
- [ ] Seed de demo (`db:seed:demo`) y grabación de fallback del golden path.
