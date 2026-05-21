"""Config layering tests."""

from __future__ import annotations

from argparse import Namespace
from pathlib import Path

import pytest

from team_performance.config import load_config
from team_performance.errors import ConfigError


def _ns(**kw: object) -> Namespace:
    defaults: dict[str, object] = {
        "sprints_dir": None,
        "phase": None,
        "backlog_us": None,
        "target_user_stories": None,
        "remaining_sprints": None,
        "bootstrap_samples": None,
        "seed": None,
        "output_format": None,
        "no_color": False,
        "verbosity": 0,
        "no_us_validation": False,
    }
    defaults.update(kw)
    return Namespace(**defaults)


def test_defaults_applied():
    cfg = load_config(_ns(), env={})
    assert cfg.sprints_dir == Path("docs/sprints")
    assert cfg.phase == "development"
    assert cfg.backlog_us == Path("docs/artifacts/backlog-us.typ")
    assert cfg.validate_us_ids is True
    assert cfg.bootstrap_samples == 10_000
    assert cfg.seed == 42
    assert cfg.output_format == "json"


def test_cli_overrides_env():
    cfg = load_config(_ns(sprints_dir="cli/sprints"), env={"TEAM_PERF_SPRINTS_DIR": "env/sprints"})
    assert cfg.sprints_dir == Path("cli/sprints")


def test_env_used_when_no_cli():
    cfg = load_config(_ns(), env={"TEAM_PERF_PHASE": "documentation"})
    assert cfg.phase == "documentation"


def test_remaining_sprints_alone_raises():
    with pytest.raises(ConfigError, match="target-user-stories"):
        load_config(_ns(remaining_sprints=5), env={})


def test_target_alone_is_allowed():
    cfg = load_config(_ns(target_user_stories=10), env={})
    assert cfg.target_user_stories == 10
    assert cfg.remaining_sprints is None


def test_negative_target_raises():
    with pytest.raises(ConfigError, match="non-negative"):
        load_config(_ns(target_user_stories=-1), env={})


def test_non_positive_remaining_sprints_raises():
    with pytest.raises(ConfigError, match="remaining-sprints must be positive"):
        load_config(_ns(target_user_stories=10, remaining_sprints=0), env={})


def test_invalid_format_raises():
    with pytest.raises(ConfigError, match="format"):
        load_config(_ns(output_format="xml"), env={})


def test_no_color_env_respected():
    assert load_config(_ns(), env={"NO_COLOR": "1"}).no_color is True


def test_no_us_validation_flag():
    assert load_config(_ns(no_us_validation=True), env={}).validate_us_ids is False


def test_no_us_validation_env():
    assert load_config(_ns(), env={"TEAM_PERF_NO_US_VALIDATION": "1"}).validate_us_ids is False
