"""Empirical bootstrap of throughput, with two complementary projections.

**Inverse projection** (always emitted when projecting): how many sprints to
complete >= ``target_user_stories``? Sample one sprint's throughput at a time
from history (with replacement), accumulate, and record the sprint number
when the running total first meets the target. Sort the trial outcomes and
read percentiles (p50/p85/p95/p99). This is the framing the operator usually
wants ("we will finish in 6 sprints with 50% confidence, 8 with 85%").

**Forward projection** (optional, requires ``remaining_sprints``): given a
fixed horizon of ``N`` future sprints, what is P(complete >= target)? Same
trials, different read-off.

The bootstrap is a pure historical replay: each future sprint is resampled
from the observed per-sprint throughput. It does not model capacity changes,
holidays, or scope drift.
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
    throughput: list[int],
    *,
    target_user_stories: int,
    samples: int = 10_000,
    seed: int = 42,
    horizon_hint: int | None = None,
) -> SprintsToTarget:
    """Sample-until-target bootstrap over the observed per-sprint throughput."""
    if len(throughput) < MIN_SPRINTS_FOR_PROJECTION:
        raise InsufficientDataError(
            f"need >= {MIN_SPRINTS_FOR_PROJECTION} closed sprints to project, got {len(throughput)}"
        )
    if samples <= 0:
        raise ValueError("samples must be positive")
    if target_user_stories < 0:
        raise ValueError("target_user_stories must be non-negative")

    cap = max(
        DEFAULT_TRIAL_SPRINT_CAP_FLOOR,
        DEFAULT_TRIAL_SPRINT_CAP_MULTIPLIER * (horizon_hint or 1),
        DEFAULT_TRIAL_SPRINT_CAP_MULTIPLIER
        * max(1, target_user_stories // max(1, max(throughput) or 1)),
    )

    rng = Random(seed)
    outcomes: list[int] = []
    did_not_finish = 0
    for _ in range(samples):
        delivered = 0
        for sprint_n in range(1, cap + 1):
            delivered += rng.choice(throughput)
            if delivered >= target_user_stories:
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
    throughput: list[int],
    *,
    target_user_stories: int,
    remaining_sprints: int,
    samples: int = 10_000,
    seed: int = 42,
) -> ForwardOutcome:
    """Fixed-horizon bootstrap: P(complete >= target in `remaining_sprints` sprints)."""
    if len(throughput) < MIN_SPRINTS_FOR_PROJECTION:
        raise InsufficientDataError(
            f"need >= {MIN_SPRINTS_FOR_PROJECTION} closed sprints to project, got {len(throughput)}"
        )
    if samples <= 0:
        raise ValueError("samples must be positive")
    if remaining_sprints <= 0:
        raise ValueError("remaining_sprints must be positive")

    rng = Random(seed)
    totals: list[int] = []
    hits = 0
    for _ in range(samples):
        delivered = sum(rng.choice(throughput) for _ in range(remaining_sprints))
        totals.append(delivered)
        if delivered >= target_user_stories:
            hits += 1

    totals.sort()
    return ForwardOutcome(
        remaining_sprints=remaining_sprints,
        p_meet_or_exceed_target=hits / samples,
        total_projected_p10=totals[int(0.10 * samples)],
        total_projected_p50=totals[int(0.50 * samples)],
        total_projected_p90=totals[int(0.90 * samples)],
    )
