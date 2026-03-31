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
- **just** — Task runner (see `justfile`)

Install everything: `mise install`

## Document Conventions (Typst)

- All `.typ` artifacts live in `docs/artifacts/` and import the shared config from [docs/template.typ](docs/template.typ) (`lang: "es"`, 10pt, 2cm margins, justified).
- Chat session `.typ` files live in `docs/prompts/` and are auto-generated from JSON exports in `docs/raw/`.
- Import pattern: `#import "../template.typ": conf` then `#show: conf`.
- Escape special characters in data: `\"`, `\#`, `\$`, `\@`, `\\`.
- Pre-commit auto-formats `.typ` files with typstyle — don't fight the formatter.

## Build & Compile

All build tasks are managed with `just`. Run `just` to list recipes.

```sh
just build                    # build everything (artifacts + chat sessions)
just build-artifacts          # compile the artifacts report
just build-artifact <name>    # compile a single artifact (e.g. wbs)
just build-chats              # convert chat JSON → .typ and compile
just convert-chats            # convert chat JSON → .typ only
just watch-artifacts          # live-reload artifacts report
just watch-chats              # live-reload chat sessions report
just fmt                      # format .typ files with typstyle
just lint                     # run all pre-commit hooks
just clean                    # remove generated PDFs
```

## Conventions

- User stories follow "Como X quiero Y para Z" format with numbered acceptance criteria.
- User Story Maps are hierarchical: Epic → Activity → Task Group → MVP / Post-MVP tasks.
- Feature matrices score personas × features on a 1–5 scale.
