"""Shared pytest fixtures."""

from __future__ import annotations

from collections.abc import Callable
from datetime import UTC, date, datetime, timedelta
from pathlib import Path

import pytest

FIXTURES_DIR = Path(__file__).parent / "fixtures"

# Signature of the make_sprint factory: (directory, index, **kwargs) -> written path.
SprintWriter = Callable[..., Path]


@pytest.fixture
def frozen_now() -> datetime:
    return datetime(2026, 5, 28, 12, 0, tzinfo=UTC)


@pytest.fixture
def sprints_fixture_dir() -> Path:
    """A clean, valid 3-sprint development ledger checked into the repo."""
    return FIXTURES_DIR / "sprints"


@pytest.fixture
def backlog_us_fixture() -> Path:
    """A minimal backlog-us.typ declaring US1..US5."""
    return FIXTURES_DIR / "backlog-us.typ"


@pytest.fixture
def make_sprint() -> SprintWriter:
    """Factory writing an ad-hoc sprint-NN.md into ``directory`` for a test."""

    def _write(
        directory: Path,
        index: int,
        *,
        completed: list[str],
        in_progress: list[str] | None = None,
        phase: str = "development",
        status: str = "closed",
        window: str | None = None,
        raw: str | None = None,
    ) -> Path:
        directory.mkdir(parents=True, exist_ok=True)
        path = directory / f"sprint-{index:02d}.md"
        if raw is not None:
            path.write_text(raw, encoding="utf-8")
            return path
        in_progress = in_progress or []
        if window is None:
            start = date(2026, 5, 7) + timedelta(days=7 * (index - 1))
            window = f"{start.isoformat()} → {(start + timedelta(days=6)).isoformat()}"
        body = (
            "---\n"
            f"sprint: {index}\n"
            f"phase: {phase}\n"
            f"status: {status}\n"
            f"window: {window}\n"
            f"in_progress_user_stories: [{', '.join(in_progress)}]\n"
            f"completed_user_stories: [{', '.join(completed)}]\n"
            "---\n\n## Retro\n- ok\n"
        )
        path.write_text(body, encoding="utf-8")
        return path

    return _write
