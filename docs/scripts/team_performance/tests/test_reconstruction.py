"""Reconstruction derivation tests."""

from __future__ import annotations

from datetime import date

import pytest

from team_performance.errors import DataSourceError
from team_performance.models import Sprint
from team_performance.reconstruction import build_reconstruction, resolve_as_of

MVP = frozenset({1, 2, 3, 4, 5})


def _sprint(index: int, completed: tuple[str, ...], in_progress: tuple[str, ...] = ()) -> Sprint:
    start = date(2026, 5, 7)
    return Sprint(
        index=index,
        phase="development",
        status="closed",
        window_start=start,
        window_end=start,
        completed=completed,
        in_progress=in_progress,
    )


def _ledger() -> tuple[Sprint, ...]:
    return (
        _sprint(1, ("US1", "US2"), ("US3",)),
        _sprint(2, ("US3", "US4"), ("US5",)),
        _sprint(3, ("US5",)),
    )


# ── resolve_as_of ────────────────────────────────────────────────────────────


def test_resolve_latest_sentinel_maps_to_latest():
    assert resolve_as_of(0, 3) == 3


def test_resolve_explicit_within_bounds():
    assert resolve_as_of(2, 3) == 2


def test_resolve_beyond_latest_raises():
    with pytest.raises(DataSourceError, match="exceeds the latest closed sprint"):
        resolve_as_of(4, 3)


def test_resolve_no_closed_sprints_raises():
    with pytest.raises(DataSourceError, match="nothing to reconstruct"):
        resolve_as_of(0, 0)


# ── build_reconstruction ─────────────────────────────────────────────────────


def test_truncates_and_derives_midstream():
    window, rec = build_reconstruction(_ledger(), as_of_sprint=2, total_dev_sprints=6, mvp_ids=MVP)
    assert tuple(s.index for s in window) == (1, 2)  # sprint 3 dropped (hindsight)
    assert rec.mvp_completed_through == 4  # US1..US4
    assert rec.derived_target_user_stories == 1  # 5 - 4
    assert rec.derived_remaining_sprints == 4  # 6 - 2
    assert rec.already_complete is False
    assert rec.velocity_scope == "mvp"
    assert rec.scope_yardstick == "current"


def test_already_complete_when_mvp_burned_down():
    _, rec = build_reconstruction(_ledger(), as_of_sprint=3, total_dev_sprints=6, mvp_ids=MVP)
    assert rec.derived_target_user_stories == 0
    assert rec.already_complete is True


def test_horizon_none_at_or_past_total():
    _, rec = build_reconstruction(_ledger(), as_of_sprint=3, total_dev_sprints=3, mvp_ids=MVP)
    assert rec.derived_remaining_sprints is None


def test_velocity_is_mvp_scoped():
    ledger = (
        _sprint(1, ("US1", "US6")),  # US6 is non-MVP
        _sprint(2, ("US2",)),
    )
    window, rec = build_reconstruction(ledger, as_of_sprint=2, total_dev_sprints=6, mvp_ids=MVP)
    assert [len(s.completed) for s in window] == [1, 1]  # US6 dropped from sprint 1
    assert rec.mvp_completed_through == 2  # US1, US2


def test_reopened_us_not_double_counted():
    # US2 completed in sprint 1, reopened in sprint 2 (in_progress), re-completed in sprint 3.
    # Throughput: sprint 1 = 2, sprint 3 = 0 (US2 already counted), not 1.
    ledger = (
        _sprint(1, ("US1", "US2")),
        _sprint(2, ("US3",), in_progress=("US2",)),
        _sprint(3, ("US2", "US4")),
    )
    window, rec = build_reconstruction(ledger, as_of_sprint=3, total_dev_sprints=6, mvp_ids=MVP)
    assert [len(s.completed) for s in window] == [2, 1, 1]  # sprint 3: only US4 counts
    assert rec.mvp_completed_through == 4  # US1, US2, US3, US4 (US2 not double-counted)
