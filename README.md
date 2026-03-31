# TP - Gestión del Desarrollo de Sistemas Informáticos (GDSI)

## Prerequisites

This project uses [mise](https://mise.jdx.dev/) to manage tool versions. Install all required tools (typst, gh, uv, just) by running:

```sh
mise install
```

## Building Documentation

All build tasks are managed with [just](https://just.systems/). Run `just` to see available recipes.

### Build everything

```sh
just build
```

This compiles the artifacts report and converts + compiles the chat session logs.

### Artifacts only

```sh
just build-artifacts          # compile the full report
just build-artifact wbs       # compile a single artifact
just watch-artifacts          # live-reload the full report
just watch-artifact wbs       # live-reload a single artifact
```

### Chat sessions only

```sh
just build-chats              # convert JSON exports → .typ, then compile
just convert-chats            # convert JSON exports only (no PDF)
just watch-chats              # live-reload the chat sessions report
```

### Utilities

```sh
just fmt                      # format .typ files with typstyle
just lint                     # run all pre-commit hooks
just clean                    # remove generated PDFs
```

## Releases

This project uses [release-please](https://github.com/googleapis/release-please) for automated versioning and releases based on [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

### How it works

1. Push commits to the `release` branch using conventional commit messages via a PR from main.
2. release-please automatically opens/updates a Release PR with a changelog and version bump.
3. Merge the Release PR to create a GitHub Release with a semver tag (`vX.Y.Z`).
4. A CI workflow then builds `artifacts.pdf` and `prompts.pdf` and attaches them to the release.

### Commit message → version bump

| Commit prefix                 | Version bump  | Example                        |
|-------------------------------|---------------|--------------------------------|
| `fix:`                        | Patch (0.0.X) | `fix: correct typo in persona` |
| `feat:`                       | Minor (0.X.0) | `feat: add new user story`     |
| `feat!:` / `BREAKING CHANGE:` | Major (X.0.0) | `feat!: restructure artifacts` |
| `docs:`, `chore:`, `ci:`      | No release    | Grouped into the next release  |

## Previewing Typst files

### VS Code (recommended)

Install the [Tinymist](https://marketplace.visualstudio.com/items?itemName=myriad-dreamin.tinymist) extension. Once installed, open any `.typ` file and either:

- Click the preview button in the editor toolbar, or
- Open the command palette (`Ctrl+Shift+P`) and run **Tinymist: Preview current file**.

The preview updates live as you edit.
