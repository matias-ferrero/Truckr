"""MVP scope resolution tests."""

from __future__ import annotations

import logging
from pathlib import Path

import pytest

from team_performance.errors import DataSourceError
from team_performance.mvp_scope import load_mvp_scope, normalize_us


@pytest.mark.parametrize(
    ("raw", "expected"),
    [("US4", 4), ("US004", 4), ("US066", 66), (" US7 ", 7)],
)
def test_normalize_us(raw: str, expected: int):
    assert normalize_us(raw) == expected


def test_normalize_us_rejects_garbage():
    with pytest.raises(DataSourceError, match="not a User Story id"):
        normalize_us("INF-1")


def test_load_mvp_scope_reads_release_1_section(backlog_mvp_fixture: Path):
    assert load_mvp_scope(backlog_mvp_fixture) == frozenset({1, 2, 3, 4, 5})


def test_load_mvp_scope_missing_file_raises(tmp_path: Path):
    with pytest.raises(DataSourceError, match="failed to read backlog"):
        load_mvp_scope(tmp_path / "nope.typ")


def test_load_mvp_scope_no_section_raises(tmp_path: Path):
    path = tmp_path / "backlog.typ"
    path.write_text("= Backlog\n\nNo includes, no banners.\n", encoding="utf-8")
    with pytest.raises(DataSourceError, match="cannot resolve the MVP scope"):
        load_mvp_scope(path)


def test_load_mvp_scope_warns_on_tag_drift(tmp_path: Path, caplog: pytest.LogCaptureFixture):
    backlog = tmp_path / "backlog.typ"
    backlog.write_text(
        '// MVP — Release 1\n#include "backlog-us/US001.typ"\n#include "backlog-us/US002.typ"\n',
        encoding="utf-8",
    )
    per_us = tmp_path / "backlog-us"
    per_us.mkdir()
    # US1 MVP (agrees); US3 MVP (tag-only); US2 Release 2 (section-only).
    (per_us / "US001.typ").write_text("== US1: A\n\n*Release:* MVP\n", encoding="utf-8")
    (per_us / "US002.typ").write_text("== US2: B\n\n*Release:* Release 2\n", encoding="utf-8")
    (per_us / "US003.typ").write_text("== US3: C\n\n*Release:* MVP\n", encoding="utf-8")

    with caplog.at_level(logging.WARNING):
        scope = load_mvp_scope(backlog)

    assert scope == frozenset({1, 2})  # section wins
    assert "MVP scope drift" in caplog.text
    assert "US3" in caplog.text  # tagged-only
    assert "US2" in caplog.text  # section-only
