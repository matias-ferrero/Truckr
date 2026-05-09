"""Sprint-window assignment tests."""

from __future__ import annotations

from datetime import UTC, date, datetime

import pytest

from team_performance.models import Issue
from team_performance.sprints import assign_to_sprints, sprint_windows


def _issue(
    number: int, created: str, closed: str | None, *, state_reason: str | None = "COMPLETED"
) -> Issue:
    return Issue(
        number=number,
        title=f"i{number}",
        state="closed" if closed else "open",
        state_reason=state_reason if closed else None,
        created_at=datetime.fromisoformat(created).replace(tzinfo=UTC),
        closed_at=datetime.fromisoformat(closed).replace(tzinfo=UTC) if closed else None,
        labels=(),
    )


def test_sprint_windows_only_includes_complete_sprints():
    windows = sprint_windows(date(2026, 4, 21), 14, date(2026, 5, 19))
    assert len(windows) == 2
    indices = [w[0] for w in windows]
    assert indices == [1, 2]
    assert windows[0][1].date() == date(2026, 4, 21)
    assert windows[0][2].date() == date(2026, 5, 5)


def test_sprint_windows_partial_sprint_excluded():
    windows = sprint_windows(date(2026, 4, 21), 14, date(2026, 5, 18))
    assert len(windows) == 1


def test_sprint_windows_zero_length_raises():
    with pytest.raises(ValueError, match="positive"):
        sprint_windows(date(2026, 4, 21), 0, date(2026, 5, 19))


def test_assign_inclusive_start_exclusive_end():
    boundary_issue = _issue(1, "2026-05-05T00:00:00", "2026-05-05T00:00:00")
    sprints = assign_to_sprints((boundary_issue,), date(2026, 4, 21), 14, date(2026, 5, 19))
    assert any(boundary_issue in s.created for s in sprints)
    assert sprints[1].closed == (boundary_issue,)
    assert boundary_issue not in sprints[0].closed


def test_assign_to_sprints_counts_and_wip():
    issues = (
        _issue(101, "2026-04-21T10:00:00", "2026-04-29T15:00:00"),
        _issue(102, "2026-04-22T09:00:00", "2026-05-02T12:00:00"),
        _issue(103, "2026-04-23T11:00:00", "2026-04-25T16:00:00"),
        _issue(104, "2026-04-24T08:00:00", "2026-05-08T10:00:00"),
        _issue(105, "2026-04-30T09:00:00", "2026-05-12T13:00:00"),
        _issue(106, "2026-05-10T14:00:00", None),
    )
    sprints = assign_to_sprints(issues, date(2026, 4, 21), 14, date(2026, 5, 19))
    assert len(sprints) == 2
    assert len(sprints[0].closed) == 3
    assert len(sprints[1].closed) == 2
    assert sprints[1].wip_at_end == 1
    assert sprints[0].wip_at_end == 2


def test_not_planned_closures_excluded_from_throughput():
    issues = (
        _issue(101, "2026-04-21T10:00:00", "2026-04-29T15:00:00"),
        _issue(102, "2026-04-22T09:00:00", "2026-04-30T15:00:00", state_reason="NOT_PLANNED"),
        _issue(103, "2026-04-23T11:00:00", "2026-05-01T16:00:00", state_reason="DUPLICATE"),
    )
    sprints = assign_to_sprints(issues, date(2026, 4, 21), 14, date(2026, 5, 5))
    assert len(sprints) == 1
    assert len(sprints[0].closed) == 1
    assert sprints[0].closed[0].number == 101
    excluded_numbers = sorted(i.number for i in sprints[0].closed_excluded)
    assert excluded_numbers == [102, 103]


def test_missing_state_reason_treated_as_delivered():
    issue = _issue(201, "2026-04-21T09:00:00", "2026-04-25T09:00:00", state_reason=None)
    sprints = assign_to_sprints((issue,), date(2026, 4, 21), 14, date(2026, 5, 5))
    assert len(sprints[0].closed) == 1
    assert sprints[0].closed_excluded == ()
