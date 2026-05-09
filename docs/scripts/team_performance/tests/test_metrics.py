"""Throughput / cycle-time aggregation tests."""

from __future__ import annotations

from datetime import UTC, datetime

from team_performance.metrics import compute_aggregate, throughput_stats
from team_performance.models import Issue, Sprint


def _sprint(index: int, closed_count: int, *, created_count: int = 0) -> Sprint:
    closed = tuple(
        Issue(
            number=i,
            title=f"i{i}",
            state="closed",
            state_reason="COMPLETED",
            created_at=datetime(2026, 4, 21, tzinfo=UTC),
            closed_at=datetime(2026, 4, 25 + i % 3, tzinfo=UTC),
            labels=(),
        )
        for i in range(closed_count)
    )
    created = tuple(
        Issue(
            number=1000 + i,
            title=f"c{i}",
            state="open",
            state_reason=None,
            created_at=datetime(2026, 4, 22, tzinfo=UTC),
            closed_at=None,
            labels=(),
        )
        for i in range(created_count)
    )
    return Sprint(
        index=index,
        start=datetime(2026, 4, 21, tzinfo=UTC),
        end=datetime(2026, 5, 5, tzinfo=UTC),
        closed=closed,
        closed_excluded=(),
        created=created,
        wip_at_end=0,
    )


def test_throughput_stats_basic():
    sprints = (_sprint(1, 2), _sprint(2, 3), _sprint(3, 5), _sprint(4, 4))
    stats = throughput_stats(sprints)
    assert stats is not None
    assert stats.mean == 3.5
    assert stats.median == 3.5
    assert stats.min == 2
    assert stats.max == 5
    assert stats.stdev is not None


def test_throughput_stats_single_sprint_no_stdev():
    sprints = (_sprint(1, 7),)
    stats = throughput_stats(sprints)
    assert stats is not None
    assert stats.stdev is None
    assert stats.min == 7
    assert stats.max == 7


def test_throughput_stats_zero_sprints_returns_none():
    assert throughput_stats(()) is None


def test_compute_aggregate_no_sprints():
    agg = compute_aggregate(())
    assert agg.throughput is None
    assert agg.created_per_sprint is None
    assert agg.cycle_time_days is None
    assert agg.sample_size_sprints == 0
    assert agg.closed_excluded_total == 0


def test_compute_aggregate_with_data():
    sprints = (_sprint(1, 2, created_count=4), _sprint(2, 3, created_count=2))
    agg = compute_aggregate(sprints)
    assert agg.sample_size_sprints == 2
    assert agg.throughput is not None
    assert agg.created_per_sprint is not None
    assert agg.created_per_sprint.mean == 3.0
    assert agg.created_per_sprint.min == 2
    assert agg.created_per_sprint.max == 4
    assert agg.cycle_time_days is not None
    assert agg.cycle_time_days.p50 >= 0
