"""Aggregate throughput statistics and lead-time percentiles.

Throughput is User Stories *completed* per sprint. Lead time is measured in
whole sprints: for a completed US, ``completion sprint - first-seen sprint``,
where "first seen" is the earliest sprint the US appeared in either the
``in_progress`` or ``completed`` list (0 when it started and finished in the
same sprint).
"""

from __future__ import annotations

import statistics

from team_performance.models import (
    AggregateStats,
    LeadTimePercentiles,
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


def throughput_stats(sprints: tuple[Sprint, ...]) -> ThroughputStats | None:
    return _stats_from_counts([len(s.completed) for s in sprints])


def lead_time_percentiles(sprints: tuple[Sprint, ...]) -> LeadTimePercentiles | None:
    """Percentiles of per-US lead time, in sprints. ``sprints`` must be index-ordered."""
    first_seen: dict[str, int] = {}
    for sprint in sprints:
        for us in (*sprint.in_progress, *sprint.completed):
            first_seen.setdefault(us, sprint.index)

    leads: list[float] = [
        float(sprint.index - first_seen[us]) for sprint in sprints for us in sprint.completed
    ]
    if not leads:
        return None
    leads.sort()
    return LeadTimePercentiles(
        p50=_percentile(leads, 0.50),
        p75=_percentile(leads, 0.75),
        p90=_percentile(leads, 0.90),
    )


def compute_aggregate(sprints: tuple[Sprint, ...]) -> AggregateStats:
    return AggregateStats(
        throughput=throughput_stats(sprints),
        lead_time_sprints=lead_time_percentiles(sprints),
        sample_size_sprints=len(sprints),
    )
