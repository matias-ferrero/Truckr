# SPRINT-N-PLAN.md skeleton

Copy this structure verbatim, filling the `‹…›` placeholders. Live reference examples in the repo: `docs/features/SPRINT-3-PLAN.md` and `SPRINT-4-PLAN.md` (richest). Keep section order and headings exactly — `/sprint-status` parses *Compromisos por integrante* and *Ventana*.

Sections marked **(optional)** appear only when relevant (no bugfixes this sprint → drop *Bugfixes*; no mid-sprint change → drop *Enmienda*).

---

```markdown
# Sprint ‹N› — Plan

- **Sprint:** ‹N›
- **Ventana:** ‹YYYY-MM-DD› → ‹YYYY-MM-DD› (cadencia semanal jue → mié)
- **Equipo (6):** Brian Céspedes (`@bcespedes`), Fernando Yu (`@FernandoYu`), Franco Ricciardo (`@FrancoRicciardo`), Lucas Dondo (`@LucasDondo`), Matías Ferrero (`@matias-ferrero`), Tomás Corzo (`@tcorzo`).
- **PM/SM:** Tomás.

‹(optional) one or more amendment blockquotes, added later, never at first write:›
> **Enmienda ‹YYYY-MM-DD› (día ‹X› de 7).** ‹Qué cambió mid-sprint y por qué; si hay go/no-go, decir el corte explícito y quién decide.›

## Objetivo del sprint

> **‹Objetivo en una frase, en negrita:›** ‹qué valor end-to-end queda demoable al cierre.›

‹Un párrafo de narrativa: cómo este sprint encaja con lo arrastrado y lo que viene. Sin surface areas nuevas no diseñadas; nombrar los carryovers que cierra.›

## Compromisos por integrante

| Integrante | TAG (gh #) | Trabajo | Tipo | Carryover |
|---|---|---|---|---|
| **‹Nombre›** (`@‹login›`) | `‹TAG›` (#‹gh›) | ‹Qué entrega, alcance concreto, US# que cubre.› | ‹Feature/Bugfix/Infra› | ‹No / Sí — …› |
‹… una fila por stream. Un dev puede tener 2 filas si una es chica o carryover. Issues locales sin GH: `(local)`.›

‹(optional) párrafo free-agent: quién absorbe el primer issue libre o entra como reviewer tras cerrar lo suyo.›

## Carryovers (lo que NO es trabajo nuevo)

- **‹Dev› — ‹PR #/TAG›.** ‹Qué arrastra y desde qué sprint; qué desbloquea al cerrarse.›

## Bugfixes / saneamiento  ‹(optional)›

- **‹Dev› — `‹FIX-TAG›` (#‹gh›).** ‹Qué arregla; por qué va en su renglón y no infla el sprint como feature.›

## Dependencias entre tareas

| Origen | Destino | Naturaleza | Acción |
|---|---|---|---|
| ‹Dev — TAG/PR› | ‹Dev — TAG› | ‹Por qué B depende de A.› | ‹Cómo se resuelve: secuenciar, mockear el contract, tomar la review día 1, etc.› |

## Fuera de alcance — diferido deliberadamente

- **‹Tema (US/TAG)›.** ‹Por qué se difiere.› ‹Si aplica: dejar claro que NO es "fase 1 → luego migramos" — es la forma del MVP, o una limitación final. Nunca framing Postgres/escala.›

## Definition of Done

Cada compromiso cierra cuando se cumple lo siguiente — es el contrato que evita PRs "casi listos":

1. Código mergeado a `main` vía PR aprobado, con `Closes #N` referenciando la issue.
2. CI en verde: RSpec, Vitest + Playwright (e2e cuando toca UI), `just lint`, `just build-artifacts` (cuando toca `docs/`).
3. Para cambios de frontend: corrida de las skills `/critique` → `/polish` → `/audit` (gate documentado en `CLAUDE.md` § "Pre-PR UI quality gate"). Findings intencionales se anotan en el body del PR.
4. Acceptance criteria de la US verificados por alguien distinto al autor durante el review.
5. Demoable end-to-end en el entorno desplegado.
6. Artifact o documentación afectada actualizada (USM, backlog-us, glossary) si el cambio toca un concepto del dominio.

## Riesgos

- **‹Riesgo en negrita.›** ‹Por qué es riesgo.› **Mitigación**: ‹qué se hace / go-no-go / quién decide.›

## Referencias

- User stories: [`docs/artifacts/backlog-us.typ`](../artifacts/backlog-us.typ) ‹(líneas/US relevantes)›.
- Cronograma planificado: [`docs/artifacts/cronograma.typ`](../artifacts/cronograma.typ).
- Glosario (fuente de verdad de términos): [`docs/05-appendices/glossary.md`](../05-appendices/glossary.md).
- Issues vivas: `.gdsi-sdlc/issues/{Ready,InProgress,Backlog}/` + `gh issue list --repo tcorzo/fiuba-gestion-tp`.
- Sprint ‹N-1› — Plan: [`SPRINT-‹N-1›-PLAN.md`](SPRINT-‹N-1›-PLAN.md) (estructura de referencia).
- Sprint ‹N-1› — Cierre: [`../sprints/sprint-0‹N-1›.md`](../sprints/sprint-0‹N-1›.md).
- Política de DB (SQLite forever) y de idioma (inglés en código, español en UI vía i18n): [`../../CLAUDE.md`](../../CLAUDE.md).
- Throughput / proyección: se corre la skill `team-performance` al cierre del sprint, no en planning.

## Mapping at a glance

```
Sprint ‹N› commitment
├── ‹Feature corto›        ─▶ ‹TAG› (#‹gh›)   (‹Dev›)   ── ‹nota: deps / carryover / post-merge›
├── …
└── ‹Feature corto›        ─▶ ‹TAG› (#‹gh›)   (‹Dev›)   ── ‹nota›

‹(optional)›
Diferido a Sprint ‹N+1›
└── ‹Tema›                 ─▶ ‹TAG› (#‹gh›)             ── ‹nota›
```
```

---

# Closure stub — docs/progress-reports/sprint-NN.md (zero-padded)

Write this alongside the plan, to be completed at sprint close. `status: planned` and empty completed list at planning time.

```markdown
---
sprint: ‹N›
phase: development
status: planned
window: ‹YYYY-MM-DD› → ‹YYYY-MM-DD›
in_progress_user_stories: []
completed_user_stories: []
---

## Retro

- _A completar por el equipo._

## Notas por US

- _A completar al cierre del sprint._
```
