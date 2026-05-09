"""Bootstrap projection tests."""

from __future__ import annotations

import pytest

from team_performance.errors import InsufficientDataError
from team_performance.projection import bootstrap_forward, bootstrap_inverse

# ── Forward (fixed horizon) ────────────────────────────────────────────────


def test_forward_certain_hit_when_throughput_constant():
    out = bootstrap_forward([3, 3, 3], target_issues=15, remaining_sprints=5, samples=1000, seed=42)
    assert out.p_meet_or_exceed_target == 1.0
    assert out.total_projected_p50 == 15


def test_forward_certain_miss_when_throughput_zero():
    out = bootstrap_forward([0, 0, 0], target_issues=1, remaining_sprints=5, samples=1000, seed=42)
    assert out.p_meet_or_exceed_target == 0.0


def test_forward_same_seed_byte_identical():
    a = bootstrap_forward([1, 5], target_issues=10, remaining_sprints=3, samples=1000, seed=42)
    b = bootstrap_forward([1, 5], target_issues=10, remaining_sprints=3, samples=1000, seed=42)
    assert a == b


def test_forward_single_sprint_raises_insufficient():
    with pytest.raises(InsufficientDataError):
        bootstrap_forward([3], target_issues=10, remaining_sprints=3)


# ── Inverse (sample-until-target) ──────────────────────────────────────────


def test_inverse_target_zero_finishes_in_one_sprint():
    out = bootstrap_inverse([3, 3, 3], target_issues=0, samples=500, seed=42)
    # Even with 0 throughput we record 1 sprint because 0 ≥ 0 after first sample.
    assert out.p50 == 1
    assert out.did_not_finish_pct == 0.0


def test_inverse_constant_throughput_deterministic():
    out = bootstrap_inverse([5, 5, 5], target_issues=20, samples=500, seed=42)
    # 20/5 = 4 sprints exactly, every trial.
    assert out.p50 == 4
    assert out.p85 == 4
    assert out.p95 == 4
    assert out.did_not_finish_pct == 0.0


def test_inverse_zero_throughput_never_finishes():
    out = bootstrap_inverse([0, 0, 0], target_issues=1, samples=200, seed=42, horizon_hint=10)
    assert out.did_not_finish_pct == 1.0
    assert out.p50 == out.cap_sprints


def test_inverse_seed_determinism():
    a = bootstrap_inverse([1, 5], target_issues=20, samples=500, seed=42)
    b = bootstrap_inverse([1, 5], target_issues=20, samples=500, seed=42)
    assert a == b


def test_inverse_insufficient_sample_raises():
    with pytest.raises(InsufficientDataError):
        bootstrap_inverse([3], target_issues=10)


def test_inverse_with_scope_growth_takes_longer():
    no_growth = bootstrap_inverse([5, 5, 5], target_issues=20, samples=500, seed=42)
    with_growth = bootstrap_inverse(
        [5, 5, 5],
        target_issues=20,
        samples=500,
        seed=42,
        created_throughput=[2, 2, 2],
    )
    # Adding 2 to target each sprint while delivering 5 → net 3/sprint → ~7 sprints
    # vs 4 sprints without growth.
    assert with_growth.p50 > no_growth.p50


def test_scope_growth_throughput_length_mismatch_raises():
    with pytest.raises(ValueError, match="same length"):
        bootstrap_inverse([5, 5, 5], target_issues=10, created_throughput=[2, 2], samples=100)


def test_forward_with_scope_growth_lowers_p_meet():
    no_growth = bootstrap_forward(
        [5, 5, 5], target_issues=20, remaining_sprints=4, samples=500, seed=42
    )
    with_growth = bootstrap_forward(
        [5, 5, 5],
        target_issues=20,
        remaining_sprints=4,
        samples=500,
        seed=42,
        created_throughput=[2, 2, 2],
    )
    assert no_growth.p_meet_or_exceed_target == 1.0
    assert with_growth.p_meet_or_exceed_target < no_growth.p_meet_or_exceed_target
