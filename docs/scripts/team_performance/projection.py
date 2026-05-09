"""Empirical bootstrap of throughput, with two complementary projections.

**Inverse projection** (always emitted when projecting): how many sprints to
close ≥ ``target_issues``? Sample one sprint's throughput at a time from
history (with replacement), accumulate, and record the sprint number when
the running total first meets the target. Sort the trial outcomes and read
percentiles (p50/p85/p95/p99). This is the framing the operator usually
wants ("we will finish in 6 sprints with 50% confidence, 8 with 85%").

**Forward projection** (optional, requires ``remaining_sprints``): given a
fixed horizon of ``N`` future sprints, what is P(close ≥ target)? Same
trials, different read-off.

**Scope-growth model** (optional, ``created_throughput`` provided): split
Monte Carlo. In each trial step we also sample one sprint from the
``items-created`` distribution and add it to the running target. Off by
default — turn it on when scope is known to drift.
"""

from __future__ import annotations

from random import Random

from team_performance.errors import InsufficientDataError
from team_performance.models import ForwardOutcome, SprintsToTarget

MIN_SPRINTS_FOR_PROJECTION = 2
DEFAULT_TRIAL_SPRINT_CAP_MULTIPLIER = 20
DEFAULT_TRIAL_SPRINT_CAP_FLOOR = 50


def _percentile_int(sorted_values: list[int], pct: float) -> int:
    if not sorted_values:
        raise ValueError("percentile of empty sequence")
    rank = pct * (len(sorted_values) - 1)
    lo = int(rank)
    hi = min(lo + 1, len(sorted_values) - 1)
    frac = rank - lo
    return round(sorted_values[lo] * (1 - frac) + sorted_values[hi] * frac)


def bootstrap_inverse(
    closed_throughput: list[int],
    *,
    target_issues: int,
    samples: int = 10_000,
    seed: int = 42,
    created_throughput: list[int] | None = None,
    horizon_hint: int | None = None,
) -> SprintsToTarget:
    """Sample-until-target bootstrap.

    If ``created_throughput`` is provided, the target grows during each trial
    by a per-sprint sample from that distribution (split Monte Carlo).
    """
    if len(closed_throughput) < MIN_SPRINTS_FOR_PROJECTION:
        raise InsufficientDataError(
            f"need ≥ {MIN_SPRINTS_FOR_PROJECTION} completed sprints to project, "
            f"got {len(closed_throughput)}"
        )
    if samples <= 0:
        raise ValueError("samples must be positive")
    if target_issues < 0:
        raise ValueError("target_issues must be non-negative")
    if created_throughput is not None and len(created_throughput) != len(closed_throughput):
        raise ValueError("created_throughput must have same length as closed_throughput")

    cap = max(
        DEFAULT_TRIAL_SPRINT_CAP_FLOOR,
        DEFAULT_TRIAL_SPRINT_CAP_MULTIPLIER * (horizon_hint or 1),
        DEFAULT_TRIAL_SPRINT_CAP_MULTIPLIER
        * max(1, target_issues // max(1, max(closed_throughput) or 1)),
    )

    rng = Random(seed)
    outcomes: list[int] = []
    did_not_finish = 0
    for _ in range(samples):
        delivered = 0
        target = target_issues
        for sprint_n in range(1, cap + 1):
            delivered += rng.choice(closed_throughput)
            if created_throughput is not None:
                target += rng.choice(created_throughput)
            if delivered >= target:
                outcomes.append(sprint_n)
                break
        else:
            did_not_finish += 1
            outcomes.append(cap)  # Cap-sentinel; counted in did_not_finish_pct

    outcomes.sort()
    return SprintsToTarget(
        p50=_percentile_int(outcomes, 0.50),
        p85=_percentile_int(outcomes, 0.85),
        p95=_percentile_int(outcomes, 0.95),
        p99=_percentile_int(outcomes, 0.99),
        did_not_finish_pct=did_not_finish / samples,
        cap_sprints=cap,
    )


def bootstrap_forward(
    closed_throughput: list[int],
    *,
    target_issues: int,
    remaining_sprints: int,
    samples: int = 10_000,
    seed: int = 42,
    created_throughput: list[int] | None = None,
) -> ForwardOutcome:
    """Fixed-horizon bootstrap: P(close ≥ target in `remaining_sprints` sprints)."""
    if len(closed_throughput) < MIN_SPRINTS_FOR_PROJECTION:
        raise InsufficientDataError(
            f"need ≥ {MIN_SPRINTS_FOR_PROJECTION} completed sprints to project, "
            f"got {len(closed_throughput)}"
        )
    if samples <= 0:
        raise ValueError("samples must be positive")
    if remaining_sprints <= 0:
        raise ValueError("remaining_sprints must be positive")
    if created_throughput is not None and len(created_throughput) != len(closed_throughput):
        raise ValueError("created_throughput must have same length as closed_throughput")

    rng = Random(seed)
    totals: list[int] = []
    hits = 0
    for _ in range(samples):
        delivered = 0
        target = target_issues
        for _ in range(remaining_sprints):
            delivered += rng.choice(closed_throughput)
            if created_throughput is not None:
                target += rng.choice(created_throughput)
        totals.append(delivered)
        if delivered >= target:
            hits += 1

    totals.sort()
    return ForwardOutcome(
        remaining_sprints=remaining_sprints,
        p_meet_or_exceed_target=hits / samples,
        total_projected_p10=totals[int(0.10 * samples)],
        total_projected_p50=totals[int(0.50 * samples)],
        total_projected_p90=totals[int(0.90 * samples)],
    )
