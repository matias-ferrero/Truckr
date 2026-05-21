"""Sprint ledger parsing + validation tests."""

from __future__ import annotations

from datetime import date
from pathlib import Path

import pytest

from team_performance.errors import DataSourceError
from team_performance.ledger_source import load_sprints
from team_performance.tests.conftest import SprintWriter

# ── Happy path ─────────────────────────────────────────────────────────────


def test_loads_and_orders_by_index(tmp_path: Path, make_sprint: SprintWriter):
    make_sprint(tmp_path, 2, completed=["US3", "US4"])
    make_sprint(tmp_path, 1, completed=["US1", "US2"], in_progress=["US3"])
    sprints = load_sprints(tmp_path, phase="development")
    assert [s.index for s in sprints] == [1, 2]
    assert sprints[0].completed == ("US1", "US2")
    assert sprints[0].in_progress == ("US3",)
    assert sprints[0].window_start == date(2026, 5, 7)
    assert sprints[0].window_end == date(2026, 5, 13)


def test_checked_in_fixture_ledger(sprints_fixture_dir: Path):
    sprints = load_sprints(sprints_fixture_dir, phase="development")
    assert [len(s.completed) for s in sprints] == [2, 2, 1]
    assert [len(s.in_progress) for s in sprints] == [1, 1, 0]


def test_in_progress_status_is_skipped(tmp_path: Path, make_sprint: SprintWriter):
    make_sprint(tmp_path, 1, completed=["US1"])
    make_sprint(tmp_path, 2, completed=["US2"], status="in_progress")
    sprints = load_sprints(tmp_path, phase="development")
    assert [s.index for s in sprints] == [1]


def test_phase_filter(tmp_path: Path, make_sprint: SprintWriter):
    make_sprint(tmp_path, 1, completed=["US1"])
    make_sprint(tmp_path, 2, completed=["US2"], phase="documentation")
    assert [s.index for s in load_sprints(tmp_path, phase="development")] == [1]


def test_us_catalog_accepts_known_ids(tmp_path: Path, make_sprint: SprintWriter):
    make_sprint(tmp_path, 1, completed=["US1"])
    make_sprint(tmp_path, 2, completed=["US2"])
    sprints = load_sprints(tmp_path, phase="development", us_catalog=frozenset({"US1", "US2"}))
    assert len(sprints) == 2


# ── Structural errors ──────────────────────────────────────────────────────


def test_missing_directory_raises(tmp_path: Path):
    with pytest.raises(DataSourceError, match="sprints directory not found"):
        load_sprints(tmp_path / "nope", phase="development")


def test_missing_opening_fence_raises(tmp_path: Path, make_sprint: SprintWriter):
    make_sprint(tmp_path, 1, completed=[], raw="sprint: 1\n")
    with pytest.raises(DataSourceError, match="frontmatter fence"):
        load_sprints(tmp_path, phase="development")


def test_unterminated_frontmatter_raises(tmp_path: Path, make_sprint: SprintWriter):
    make_sprint(tmp_path, 1, completed=[], raw="---\nsprint: 1\nphase: development\n")
    with pytest.raises(DataSourceError, match="unterminated frontmatter"):
        load_sprints(tmp_path, phase="development")


def test_missing_required_key_raises(tmp_path: Path, make_sprint: SprintWriter):
    make_sprint(
        tmp_path,
        1,
        completed=[],
        raw="---\nsprint: 1\nphase: development\nstatus: closed\n---\n",
    )
    with pytest.raises(DataSourceError, match="missing required frontmatter key"):
        load_sprints(tmp_path, phase="development")


def test_bad_window_raises(tmp_path: Path, make_sprint: SprintWriter):
    make_sprint(tmp_path, 1, completed=["US1"], window="2026-05-07 only")
    with pytest.raises(DataSourceError, match="window must be"):
        load_sprints(tmp_path, phase="development")


def test_invalid_us_id_raises(tmp_path: Path, make_sprint: SprintWriter):
    make_sprint(tmp_path, 1, completed=["banana"])
    with pytest.raises(DataSourceError, match="invalid US id"):
        load_sprints(tmp_path, phase="development")


def test_invalid_status_raises(tmp_path: Path, make_sprint: SprintWriter):
    make_sprint(tmp_path, 1, completed=["US1"], status="wibble")
    with pytest.raises(DataSourceError, match="status must be one of"):
        load_sprints(tmp_path, phase="development")


# ── Cross-file validation ──────────────────────────────────────────────────


def test_overlap_completed_and_in_progress_raises(tmp_path: Path, make_sprint: SprintWriter):
    make_sprint(tmp_path, 1, completed=["US1"], in_progress=["US1"])
    with pytest.raises(DataSourceError, match="both completed and in_progress"):
        load_sprints(tmp_path, phase="development")


def test_double_complete_raises(tmp_path: Path, make_sprint: SprintWriter):
    make_sprint(tmp_path, 1, completed=["US1"])
    make_sprint(tmp_path, 2, completed=["US1"])
    with pytest.raises(DataSourceError, match="completed in both sprint"):
        load_sprints(tmp_path, phase="development")


def test_non_contiguous_indices_raises(tmp_path: Path, make_sprint: SprintWriter):
    make_sprint(tmp_path, 1, completed=["US1"])
    make_sprint(tmp_path, 3, completed=["US2"])
    with pytest.raises(DataSourceError, match="contiguous from 1"):
        load_sprints(tmp_path, phase="development")


def test_in_progress_after_completed_raises(tmp_path: Path, make_sprint: SprintWriter):
    make_sprint(tmp_path, 1, completed=["US1"])
    make_sprint(tmp_path, 2, completed=["US2"], in_progress=["US1"])
    with pytest.raises(DataSourceError, match=r"already.*completed in sprint"):
        load_sprints(tmp_path, phase="development")


def test_us_catalog_rejects_unknown_id(tmp_path: Path, make_sprint: SprintWriter):
    make_sprint(tmp_path, 1, completed=["US1"])
    make_sprint(tmp_path, 2, completed=["US99"])
    with pytest.raises(DataSourceError, match="not declared in the US backlog"):
        load_sprints(tmp_path, phase="development", us_catalog=frozenset({"US1"}))
