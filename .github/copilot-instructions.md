# Project Guidelines — Truckr®

## Overview

Truckr® is a transportation services marketplace connecting independent transporters with clients. This repository contains **project planning artifacts** for a FIUBA GDSI (Gestión del Desarrollo de Sistemas Informáticos) course — no application source code yet.

All written content is in **Spanish** (es-AR).

## Tooling

Managed via [mise.toml](mise.toml):
- **typst** — Document typesetting (artifacts → PDF)
- **typstyle** — Typst formatter (enforced by pre-commit)
- **uv** — Python package manager
- **gh** — GitHub CLI
- **prek** — Pre-commit hooks

Install everything: `mise install`

## Document Conventions (Typst)

- All `.typ` artifacts live in `docs/artifacts/` and import the shared config from [docs/artifacts/template.typ](docs/artifacts/template.typ) (`lang: "es"`, 10pt, 2cm margins, justified).
- Import pattern: `#import "template.typ": conf` then `#show: conf`.
- Escape special characters in data: `\"`, `\#`, `\$`, `\@`, `\\`.
- Pre-commit auto-formats `.typ` files with typstyle — don't fight the formatter.

## Build & Compile

```sh
typst compile docs/artifacts/<file>.typ    # one-shot PDF
typst watch docs/artifacts/<file>.typ      # live reload
pre-commit run --all-files                 # lint & format
```

## Conventions

- User stories follow "Como X quiero Y para Z" format with numbered acceptance criteria.
- User Story Maps are hierarchical: Epic → Activity → Task Group → MVP / Post-MVP tasks.
- Feature matrices score personas × features on a 1–5 scale.
