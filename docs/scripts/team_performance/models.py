"""Frozen, slotted dataclasses describing the domain.

The unit of throughput is the *User Story*: a US is "completed" in sprint N
when the team records it in that sprint's ledger file. Collections are tuples
of US ids (e.g. ``("US1", "US14")``) to keep ``frozen=True`` instances
hashable and shareable across threads/tests.
"""

from dataclasses import dataclass
from datetime import date, datetime


@dataclass(frozen=True, slots=True)
class Sprint:
    index: int
    phase: str  # "development" | "documentation"
    status: str  # "closed" (counted) | "in_progress" (skipped)
    window_start: date
    window_end: date
    completed: tuple[str, ...]  # US ids finished in this sprint
    in_progress: tuple[str, ...]  # US ids worked but NOT finished (carry-over WIP)


@dataclass(frozen=True, slots=True)
class ThroughputStats:
    mean: float
    median: float
    stdev: float | None
    min: int
    max: int


@dataclass(frozen=True, slots=True)
class LeadTimePercentiles:
    """Lead time measured in whole sprints: completion sprint - first-seen sprint."""

    p50: float
    p75: float
    p90: float


@dataclass(frozen=True, slots=True)
class AggregateStats:
    throughput: ThroughputStats | None  # User Stories completed per sprint
    lead_time_sprints: LeadTimePercentiles | None
    sample_size_sprints: int


@dataclass(frozen=True, slots=True)
class SprintsToTarget:
    """Inverse projection: how many sprints to complete >= target user stories."""

    p50: int
    p85: int
    p95: int
    p99: int
    did_not_finish_pct: float  # Fraction of trials that hit the cap without finishing
    cap_sprints: int  # Per-trial sprint cap


@dataclass(frozen=True, slots=True)
class ForwardOutcome:
    """Forward projection: given N future sprints, P(complete >= target)."""

    remaining_sprints: int
    p_meet_or_exceed_target: float
    total_projected_p10: int
    total_projected_p50: int
    total_projected_p90: int


@dataclass(frozen=True, slots=True)
class Projection:
    target_user_stories: int
    bootstrap_samples: int
    method: str
    sprints_to_target: SprintsToTarget  # Always present when projecting
    forward: ForwardOutcome | None  # Present iff --remaining-sprints given


@dataclass(frozen=True, slots=True)
class Reconstruction:
    """Point-in-time context for an ``--as-of-sprint N`` run.

    Everything here is *derived* from ``N``: the history window, the remaining
    MVP target, and the horizon. Emitted so the rendered report can show its
    own arithmetic.
    """

    as_of_sprint: int
    history_from: int  # First sprint in the replayed window (always 1)
    history_to: int  # Last sprint in the window (== as_of_sprint)
    total_dev_sprints: int  # Course-defined development phase length (default 6)
    mvp_total: int  # User Stories in the MVP — Release 1 backlog section
    mvp_completed_through: int  # MVP US completed in sprints 1..N
    derived_target_user_stories: int  # max(0, mvp_total - mvp_completed_through)
    derived_remaining_sprints: int | None  # total_dev_sprints - N; None if <= 0
    already_complete: bool  # True when no MVP remained at the end of sprint N
    velocity_scope: str = "mvp"  # Throughput counts MVP-tagged completions only
    scope_yardstick: str = "current"  # MVP measured against today's backlog


@dataclass(frozen=True, slots=True)
class Report:
    schema_version: str
    generated_at: datetime
    config_snapshot: dict[str, object]
    sprints: tuple[Sprint, ...]
    aggregate: AggregateStats
    projection: Projection | None
    reconstruction: Reconstruction | None = None
