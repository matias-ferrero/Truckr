"""US catalogue parsing tests."""

from __future__ import annotations

from pathlib import Path

import pytest

from team_performance.errors import DataSourceError
from team_performance.us_catalog import load_us_catalog


def test_loads_us_ids(backlog_us_fixture: Path):
    catalog = load_us_catalog(backlog_us_fixture)
    assert catalog == frozenset({"US1", "US2", "US3", "US4", "US5"})


def test_missing_file_raises(tmp_path: Path):
    with pytest.raises(DataSourceError, match="failed to read"):
        load_us_catalog(tmp_path / "does-not-exist.typ")


def test_no_headers_raises(tmp_path: Path):
    path = tmp_path / "empty.typ"
    path.write_text("= Backlog\n\nNo user stories here.\n", encoding="utf-8")
    with pytest.raises(DataSourceError, match="no '== USnn:'"):
        load_us_catalog(path)
