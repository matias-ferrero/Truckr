# ── Truckr® Documentation Automation ────────────────────────────────────────
# Run `just` or `just --list` to see available recipes.

root := "docs"

# List available recipes
default:
    @just --list

# ── Build everything ────────────────────────────────────────────────────────

# Build all documentation (artifacts + chat sessions)
build: build-artifacts build-chats

# ── Artifacts ───────────────────────────────────────────────────────────────

# Compile the main artifacts report (includes all sub-artifacts)
build-artifacts:
    typst compile --root {{ root }} {{ root }}/artifacts/main.typ

# Compile a single artifact by name (e.g. `just build-artifact wbs`)
build-artifact name:
    typst compile --root {{ root }} {{ root }}/artifacts/{{ name }}.typ

# Watch the main artifacts report for live reload
watch-artifacts:
    typst watch --root {{ root }} {{ root }}/artifacts/main.typ

# Watch a single artifact for live reload (e.g. `just watch-artifact wbs`)
watch-artifact name:
    typst watch --root {{ root }} {{ root }}/artifacts/{{ name }}.typ

# ── Chat sessions ───────────────────────────────────────────────────────────

# Convert raw JSON exports and compile the chat sessions report
build-chats: convert-chats
    typst compile --root {{ root }} {{ root }}/prompts/main.typ

# Convert raw chat JSON exports to .typ (regenerates prompts/main.typ)
convert-chats:
    python3 {{ root }}/scripts/chat_json2typ.py {{ root }}/raw/*-chat.json

# Watch the chat sessions report for live reload
watch-chats:
    typst watch --root {{ root }} {{ root }}/prompts/main.typ

# ── Utilities ───────────────────────────────────────────────────────────────

# Format all .typ files with typstyle
fmt:
    pre-commit run typstyle --all-files

# Run all pre-commit hooks
lint:
    pre-commit run --all-files

# Remove generated PDFs
clean:
    find {{ root }} -name '*.pdf' -delete
