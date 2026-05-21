"""Throughput / lead-time aggregation tests."""

from __future__ import annotations

from datetime import date

from team_performance.metrics import (
    compute_aggregate,
    lead_time_percentiles,
    throughput_stats,
)
from team_performance.models import Sprint


def _sprint(
    index: int,
    completed: list[str],
    in_progress: list[str] | None = None,
) -> Sprint:
    return Sprint(
        index=index,
        phase="development",
        status="closed",
        window_start=date(2026, 5, 1),
        window_end=date(2026, 5, 7),
        completed=tuple(completed),
        in_progress=tuple(in_progress or []),
    )


def test_throughput_stats_basic():
    sprints = (
        _sprint(1, ["US1", "US2"]),
        _sprint(2, ["US3", "US4", "US5"]),
        _sprint(3, ["US6", "US7", "US8", "US9", "US10"]),
        _sprint(4, ["US11", "US12", "US13", "US14"]),
    )
    stats = throughput_stats(sprints)
    assert stats is not None
    assert stats.mean == 3.5
    assert stats.median == 3.5
    assert stats.min == 2
    assert stats.max == 5
    assert stats.stdev is not None


def test_throughput_stats_single_sprint_no_stdev():
    stats = throughput_stats((_sprint(1, ["US1", "US2"]),))
    assert stats is not None
    assert stats.stdev is None
    assert stats.min == stats.max == 2


def test_throughput_stats_zero_sprints_returns_none():
    assert throughput_stats(()) is None


def test_lead_time_counts_carry_over_in_sprints():
    # US7 first seen in sprint 1 (in_progress), completed in sprint 2 -> lead 1.
    # US1, US2, US3 completed in their first-seen sprint -> lead 0.
    sprints = (
        _sprint(1, ["US1", "US2"], in_progress=["US7"]),
        _sprint(2, ["US7", "US3"]),
    )
    lead = lead_time_percentiles(sprints)
    assert lead is not None
    assert lead.p50 == 0.0
    assert lead.p90 > 0.0  # the single carry-over US7 pulls the tail up


def test_lead_time_none_when_nothing_completed():
    assert lead_time_percentiles((_sprint(1, [], in_progress=["US1"]),)) is None


def test_compute_aggregate_empty():
    agg = compute_aggregate(())
    assert agg.throughput is None
    assert agg.lead_time_sprints is None
    assert agg.sample_size_sprints == 0


def test_compute_aggregate_with_data():
    sprints = (
        _sprint(1, ["US1", "US2"], in_progress=["US3"]),
        _sprint(2, ["US3"]),
    )
    agg = compute_aggregate(sprints)
    assert agg.sample_size_sprints == 2
    assert agg.throughput is not None
    assert agg.throughput.mean == 1.5
    assert agg.lead_time_sprints is not None
    assert agg.lead_time_sprints.p50 >= 0.0
