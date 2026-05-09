"""Frozen, slotted dataclasses describing the domain.

All datetime fields are timezone-aware UTC. Collections are tuples to keep
``frozen=True`` instances hashable and shareable across threads/tests.
"""

from dataclasses import dataclass
from datetime import datetime


@dataclass(frozen=True, slots=True)
class Issue:
    number: int
    title: str
    state: str
    state_reason: str | None  # GitHub: COMPLETED | NOT_PLANNED | DUPLICATE | REOPENED | None
    created_at: datetime
    closed_at: datetime | None
    labels: tuple[str, ...]


@dataclass(frozen=True, slots=True)
class Sprint:
    index: int
    start: datetime
    end: datetime
    closed: tuple[Issue, ...]  # Only state_reason ∈ {COMPLETED, None} — wontfix excluded
    closed_excluded: tuple[Issue, ...]  # Closed in window but excluded (not_planned, duplicate)
    created: tuple[Issue, ...]
    wip_at_end: int


@dataclass(frozen=True, slots=True)
class Breakdown:
    by_prefix: dict[str, int]
    by_scope: dict[str, int]
    by_priority: dict[str, int]


@dataclass(frozen=True, slots=True)
class ThroughputStats:
    mean: float
    median: float
    stdev: float | None
    min: int
    max: int


@dataclass(frozen=True, slots=True)
class CycleTimePercentiles:
    p50: float
    p75: float
    p90: float


@dataclass(frozen=True, slots=True)
class AggregateStats:
    throughput: ThroughputStats | None  # Issues *delivered* per sprint
    created_per_sprint: ThroughputStats | None  # Items added per sprint (scope-growth source)
    cycle_time_days: CycleTimePercentiles | None
    sample_size_sprints: int
    closed_excluded_total: int  # Wontfix/duplicate count across the sample


@dataclass(frozen=True, slots=True)
class SprintsToTarget:
    """Inverse projection: how many sprints to close ≥ target."""

    p50: int
    p85: int
    p95: int
    p99: int
    did_not_finish_pct: float  # Fraction of trials that hit the cap without finishing
    cap_sprints: int  # Per-trial sprint cap


@dataclass(frozen=True, slots=True)
class ForwardOutcome:
    """Forward projection: given N future sprints, P(close ≥ target)."""

    remaining_sprints: int
    p_meet_or_exceed_target: float
    total_projected_p10: int
    total_projected_p50: int
    total_projected_p90: int


@dataclass(frozen=True, slots=True)
class ScopeGrowthStats:
    """Distribution of items *added* per sprint, used to grow the target during inverse trials."""

    created_per_sprint_mean: float
    created_per_sprint_median: float
    created_per_sprint_min: int
    created_per_sprint_max: int


@dataclass(frozen=True, slots=True)
class Projection:
    target_issues: int  # Initial target (before scope growth)
    bootstrap_samples: int
    method: str
    scope_growth_enabled: bool
    sprints_to_target: SprintsToTarget  # Always present when projecting
    forward: ForwardOutcome | None  # Present iff --remaining-sprints given
    scope_growth: ScopeGrowthStats | None  # Present iff scope growth enabled


@dataclass(frozen=True, slots=True)
class Report:
    schema_version: str
    generated_at: datetime
    config_snapshot: dict[str, object]
    sprints: tuple[Sprint, ...]
    aggregate: AggregateStats
    projection: Projection | None
