"""Aggregate throughput statistics and cycle-time percentiles."""

from __future__ import annotations

import statistics
from collections.abc import Callable

from team_performance.models import (
    AggregateStats,
    CycleTimePercentiles,
    Sprint,
    ThroughputStats,
)


def _percentile(sorted_values: list[float], pct: float) -> float:
    if not sorted_values:
        raise ValueError("percentile of empty sequence")
    if len(sorted_values) == 1:
        return sorted_values[0]
    rank = pct * (len(sorted_values) - 1)
    lo = int(rank)
    hi = min(lo + 1, len(sorted_values) - 1)
    frac = rank - lo
    return sorted_values[lo] * (1 - frac) + sorted_values[hi] * frac


def cycle_time_percentiles(sprints: tuple[Sprint, ...]) -> CycleTimePercentiles | None:
    durations: list[float] = []
    for sprint in sprints:
        for issue in sprint.closed:
            if issue.closed_at is None:
                continue
            seconds = (issue.closed_at - issue.created_at).total_seconds()
            durations.append(seconds / 86400.0)
    if not durations:
        return None
    durations.sort()
    return CycleTimePercentiles(
        p50=_percentile(durations, 0.50),
        p75=_percentile(durations, 0.75),
        p90=_percentile(durations, 0.90),
    )


def _stats_from_counts(counts: list[int]) -> ThroughputStats | None:
    if not counts:
        return None
    return ThroughputStats(
        mean=statistics.fmean(counts),
        median=statistics.median(counts),
        stdev=statistics.stdev(counts) if len(counts) >= 2 else None,
        min=min(counts),
        max=max(counts),
    )


def _per_sprint(sprints: tuple[Sprint, ...], extractor: Callable[[Sprint], int]) -> list[int]:
    return [extractor(s) for s in sprints]


def throughput_stats(sprints: tuple[Sprint, ...]) -> ThroughputStats | None:
    return _stats_from_counts(_per_sprint(sprints, lambda s: len(s.closed)))


def created_per_sprint_stats(sprints: tuple[Sprint, ...]) -> ThroughputStats | None:
    return _stats_from_counts(_per_sprint(sprints, lambda s: len(s.created)))


def compute_aggregate(sprints: tuple[Sprint, ...]) -> AggregateStats:
    closed_excluded_total = sum(len(s.closed_excluded) for s in sprints)
    return AggregateStats(
        throughput=throughput_stats(sprints),
        created_per_sprint=created_per_sprint_stats(sprints),
        cycle_time_days=cycle_time_percentiles(sprints),
        sample_size_sprints=len(sprints),
        closed_excluded_total=closed_excluded_total,
    )
