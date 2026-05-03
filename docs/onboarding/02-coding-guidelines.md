# Coding Guidelines

## Languages & Style

| Surface | Style | Enforcer |
|---------|-------|----------|
| Ruby (`backend/`) | `rubocop-rails-omakase` (Rails official) | `bin/rubocop`. Not yet on pre-commit. |
| TypeScript (`frontend/`) | `tsc --strict`. ESLint not configured yet. | `tsc` via `deno task build`. |
| Typst (`docs/`) | `typstyle` | `prek` pre-commit hook (auto-formats `.typ` on commit). |
| Markdown / config | Standard `prettier`-style; no enforcer. | — |

## Language Rules

- **Spanish (es-AR)** — product artifacts under `docs/artifacts/`, user/job stories, prompts under `docs/prompts/` and `docs/raw/`, issue titles, `frontend/.impeccable.md` content where it relates to UX copy.
- **English** — code identifiers, comments (when warranted), commit messages, branch names, this onboarding folder, all `.md` under `docs/00-` … `docs/05-` and `docs/onboarding/`.

## Commits

- **Conventional Commits required**: `<type>(<scope>): <subject>`.
- Types in use: `feat`, `fix`, `docs`, `chore`, `refactor`, `ci`. `feat!:` / `BREAKING CHANGE:` for major bumps.
- Scopes are free-form but track repo areas (`frontend`, `backend`, `docs`, `triage`, `issues`, `justfile`, …).
- `release-please` reads commits on `main` to bump SemVer, write `CHANGELOG.md`, and tag releases. Drift = silently dropped.

## Naming

| Surface | Convention | Example |
|---------|------------|---------|
| Ruby files | snake_case | `quote_requests_controller.rb` |
| Ruby classes / modules | CamelCase | `Api::QuoteRequestsController` |
| Rails routes | plural snake_case | `quote_requests`, `transport_windows` |
| API JSON keys | snake_case | `origen`, `peso_kg` |
| TypeScript files | camelCase or PascalCase (components) | `App.tsx`, `landingContent.ts` |
| TypeScript types / components | PascalCase | `LandingPage`, `QuoteDraft` |
| TypeScript variables / fns | camelCase | `themeVars`, `validateQuote` |
| CSS custom properties | `--brand-*` for palette, kebab-case otherwise | `--brand-primary` |
| Issue tags | `<PREFIX>-<SCOPE>-<NNNNN>` | `INF-GEN-00002`, `REQ-FE-00004` |
| Branch names | `<type>/<short-slug>` | `feature/bootstrap`, `fix/cors-allowlist` |

## File Organisation

- **Backend** — Rails defaults. New endpoints go under `backend/app/controllers/api/`. Models under `backend/app/models/`. Jobs under `backend/app/jobs/`. Don't fight Rails conventions.
- **Frontend** — currently single-file (`frontend/src/App.tsx`). When a second route appears, split: `src/router.tsx`, `src/pages/<feature>/`, `src/components/`, `src/lib/api/`. Co-locate styles.
- **Docs** — Typst sources under `docs/artifacts/` (one `.typ` per artifact), prompts under `docs/prompts/` (auto-generated from `docs/raw/*.json` via `docs/scripts/chat_json2typ.py`). All artifacts share `docs/template.typ` config (`#import "../template.typ": conf` then `#show: conf`).
- **Skills** — one folder per skill: `<.agents|frontend/.agents>/skills/<name>/SKILL.md` (+ optional `reference/`, `scripts/`).
- **Issues** — `.gdsi-sdlc/issues/<status>/<TAG>-<slug>.issue.md`.

## Typst-Specific

- Special-character escaping: `\"`, `\#`, `\$`, `\@`, `\\`.
- All artifact `.typ` files import the shared template:
  ```typ
  #import "../template.typ": conf
  #show: conf
  ```
- Build invocations always pass `--root docs` (the `justfile` does this — don't bypass it).

## Common Patterns (Do / Don't)

| Do | Don't |
|----|-------|
| Restrict routes with `only:` / `except:` | Mount full `resources :foo` if you only need `:index` |
| Validate JSON shape on the frontend with a type guard | Trust `await response.json()` to match the declared TS type |
| Read brand colors via `var(--brand-*)` | Hardcode `#FF0000` in component CSS |
| Push commit history through Conventional Commits | Use free-form commit subjects on `main` |
| Move issue files between status folders | Track issue state inline inside the file body |
| Delete unused symbols outright | Leave `_unused`, `// removed` comments, or backwards-compat shims |
| Add a skill folder for new AI capability | Embed the skill prompt in chat / commit history |
| Generate PDFs at release time | Commit `*.pdf` to git (already in `.gitignore`) |

## Comments

Default: write none. Add a one-liner only when **why** is non-obvious (hidden constraint, subtle invariant, workaround). Never describe what the code does — names should do that. Don't reference the current task or PR — that belongs in the commit message.

## Testing Conventions

See `05-testing-strategy.md`. Short version: backend uses **RSpec** exclusively — specs live under `backend/spec/`. Frontend tests are not yet wired.
