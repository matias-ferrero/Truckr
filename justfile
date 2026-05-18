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

# ── Frontend (React + Vite + Deno) ──────────────────────────────────────────

# Install frontend dependencies (uses Deno's npm interop)
frontend-install:
    cd frontend && deno install

# Run the frontend dev server (Vite, defaults to http://localhost:5173)
frontend-dev:
    cd frontend && deno task dev

# Build the frontend for production (outputs to frontend/dist)
frontend-build:
    cd frontend && deno task build

# Preview the production build locally
frontend-preview:
    cd frontend && deno task preview

# Lint frontend CSS against the DESIGN.md design-system rules (stylelint)
frontend-lint-css:
    cd frontend && deno task lint:css

# Run frontend unit/component tests (Vitest, single run)
frontend-test:
    cd frontend && deno task test:run

# Run frontend tests with coverage
frontend-test-coverage:
    cd frontend && deno task test:coverage

# Run frontend E2E tests (Playwright, chromium only)
frontend-test-e2e:
    cd frontend && deno task test:e2e

# Install Playwright browsers (run once before frontend-test-e2e)
frontend-test-e2e-install:
    cd frontend && deno task test:e2e:install

# ── Backend (Rails 8 API) ───────────────────────────────────────────────────

# Install backend gems
backend-install:
    cd backend && bundle install

# Run the backend dev server (Puma on http://localhost:3000 + dartsass watch via foreman)
backend-dev: backend-assets-build
    cd backend && bin/dev

# Compile backend SCSS (ActiveAdmin) to app/assets/builds/ — Propshaft does not transform Sass
backend-assets-build:
    cd backend && bin/rails dartsass:build

# Watch backend SCSS and rebuild on change (standalone — bin/dev already does this via Procfile.dev)
backend-assets-watch:
    cd backend && bin/rails dartsass:watch

# Open the Rails console
backend-console:
    cd backend && bin/rails console

# Run database migrations
backend-migrate:
    cd backend && bin/rails db:migrate

# Run the backend test suite (RSpec)
backend-test:
    cd backend && bundle exec rspec

# ── Team performance (throughput-based projection CLI) ─────────────────────

# Run the team-performance CLI (pass extra flags via ARGS)
team-performance *ARGS:
    uv run team-performance {{ ARGS }}

# Run the team_performance test suite with coverage
team-performance-test:
    uv run pytest docs/scripts/team_performance --cov=team_performance --cov-report=term-missing

# Lint + format-check + type-check team_performance
team-performance-lint:
    uv run ruff check docs/scripts/team_performance
    uv run ruff format --check docs/scripts/team_performance
    uv run mypy docs/scripts/team_performance

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
