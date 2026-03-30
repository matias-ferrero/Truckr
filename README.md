# TP - Gestión del Desarrollo de Sistemas Informáticos (GDSI)

## Prerequisites

This project uses [mise](https://mise.jdx.dev/) to manage tool versions. Install all required tools (typst, gh, uv) by running:

```sh
mise install
```

## Previewing Typst files

### VS Code (recommended)

Install the [Tinymist](https://marketplace.visualstudio.com/items?itemName=myriad-dreamin.tinymist) extension. Once installed, open any `.typ` file and either:

- Click the preview button in the editor toolbar, or
- Open the command palette (`Ctrl+Shift+P`) and run **Tinymist: Preview current file**.

The preview updates live as you edit.

### Command line

To compile a `.typ` file to PDF:

```sh
typst compile docs/artifacts/<file>.typ
```

To watch for changes and recompile automatically:

```sh
typst watch docs/artifacts/<file>.typ
```
