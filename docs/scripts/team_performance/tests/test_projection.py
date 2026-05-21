"""Bootstrap projection tests."""

from __future__ import annotations

import pytest

from team_performance.errors import InsufficientDataError
from team_performance.projection import bootstrap_forward, bootstrap_inverse

# ── Forward (fixed horizon) ────────────────────────────────────────────────


def test_forward_certain_hit_when_throughput_constant():
    out = bootstrap_forward(
        [3, 3, 3], target_user_stories=15, remaining_sprints=5, samples=1000, seed=42
    )
    assert out.p_meet_or_exceed_target == 1.0
    assert out.total_projected_p50 == 15


def test_forward_certain_miss_when_throughput_zero():
    out = bootstrap_forward(
        [0, 0, 0], target_user_stories=1, remaining_sprints=5, samples=1000, seed=42
    )
    assert out.p_meet_or_exceed_target == 0.0


def test_forward_same_seed_byte_identical():
    kw = {"target_user_stories": 10, "remaining_sprints": 3, "samples": 1000, "seed": 42}
    assert bootstrap_forward([1, 5], **kw) == bootstrap_forward([1, 5], **kw)


def test_forward_single_sprint_raises_insufficient():
    with pytest.raises(InsufficientDataError):
        bootstrap_forward([3], target_user_stories=10, remaining_sprints=3)


# ── Inverse (sample-until-target) ──────────────────────────────────────────


def test_inverse_target_zero_finishes_in_one_sprint():
    out = bootstrap_inverse([3, 3, 3], target_user_stories=0, samples=500, seed=42)
    assert out.p50 == 1
    assert out.did_not_finish_pct == 0.0


def test_inverse_constant_throughput_deterministic():
    out = bootstrap_inverse([5, 5, 5], target_user_stories=20, samples=500, seed=42)
    assert out.p50 == 4  # 20 / 5 = 4 sprints exactly, every trial
    assert out.p85 == 4
    assert out.p95 == 4
    assert out.did_not_finish_pct == 0.0


def test_inverse_zero_throughput_never_finishes():
    out = bootstrap_inverse([0, 0, 0], target_user_stories=1, samples=200, seed=42, horizon_hint=10)
    assert out.did_not_finish_pct == 1.0
    assert out.p50 == out.cap_sprints


def test_inverse_seed_determinism():
    a = bootstrap_inverse([1, 5], target_user_stories=20, samples=500, seed=42)
    b = bootstrap_inverse([1, 5], target_user_stories=20, samples=500, seed=42)
    assert a == b


def test_inverse_insufficient_sample_raises():
    with pytest.raises(InsufficientDataError):
        bootstrap_inverse([3], target_user_stories=10)


def test_inverse_lumpy_throughput_with_zero_sprints():
    # Big USs span sprints: many 0-completion sprints, a few productive ones.
    out = bootstrap_inverse([0, 0, 2, 0, 3], target_user_stories=10, samples=1000, seed=42)
    assert out.p50 >= 1
    assert out.p99 >= out.p50
