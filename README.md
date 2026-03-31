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

## Previewing Typst files

### VS Code (recommended)

Install the [Tinymist](https://marketplace.visualstudio.com/items?itemName=myriad-dreamin.tinymist) extension. Once installed, open any `.typ` file and either:

- Click the preview button in the editor toolbar, or
- Open the command palette (`Ctrl+Shift+P`) and run **Tinymist: Preview current file**.

The preview updates live as you edit.
