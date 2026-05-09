"""Config layering tests."""

from __future__ import annotations

from argparse import Namespace
from datetime import date
from pathlib import Path

import pytest

from team_performance.config import load_config
from team_performance.errors import ConfigError


def _ns(**kw: object) -> Namespace:
    defaults: dict[str, object] = {
        "repo": None,
        "gh_bin": None,
        "sprint_start": None,
        "sprint_length_days": None,
        "as_of": None,
        "target_issues": None,
        "remaining_sprints": None,
        "bootstrap_samples": None,
        "seed": None,
        "output_format": None,
        "no_color": False,
        "verbosity": 0,
        "scope_growth": False,
    }
    defaults.update(kw)
    return Namespace(**defaults)


@pytest.fixture
def empty_pyproject(tmp_path: Path) -> Path:
    p = tmp_path / "pyproject.toml"
    p.write_text("", encoding="utf-8")
    return p


@pytest.fixture
def populated_pyproject(tmp_path: Path) -> Path:
    p = tmp_path / "pyproject.toml"
    p.write_text(
        '[tool.team_performance]\nrepo = "x/y"\nsprint_length_days = 7\n',
        encoding="utf-8",
    )
    return p


def test_cli_overrides_env_and_pyproject(populated_pyproject: Path):
    args = _ns(repo="cli/repo", sprint_start="2026-04-21")
    cfg = load_config(
        args,
        env={"TEAM_PERF_REPO": "env/repo"},
        pyproject_path=populated_pyproject,
        today=date(2026, 5, 19),
    )
    assert cfg.repo == "cli/repo"


def test_env_overrides_pyproject(populated_pyproject: Path):
    args = _ns(sprint_start="2026-04-21")
    cfg = load_config(
        args,
        env={"TEAM_PERF_REPO": "env/repo"},
        pyproject_path=populated_pyproject,
        today=date(2026, 5, 19),
    )
    assert cfg.repo == "env/repo"


def test_pyproject_used_when_no_cli_or_env(populated_pyproject: Path):
    args = _ns(sprint_start="2026-04-21")
    cfg = load_config(args, env={}, pyproject_path=populated_pyproject, today=date(2026, 5, 19))
    assert cfg.repo == "x/y"
    assert cfg.sprint_length_days == 7


def test_missing_repo_raises(empty_pyproject: Path):
    args = _ns(sprint_start="2026-04-21")
    with pytest.raises(ConfigError, match="repo"):
        load_config(args, env={}, pyproject_path=empty_pyproject)


def test_missing_sprint_start_raises(populated_pyproject: Path):
    args = _ns()
    with pytest.raises(ConfigError, match="sprint-start"):
        load_config(args, env={}, pyproject_path=populated_pyproject)


def test_remaining_sprints_alone_raises(populated_pyproject: Path):
    args = _ns(sprint_start="2026-04-21", remaining_sprints=5)
    with pytest.raises(ConfigError, match="target-issues"):
        load_config(args, env={}, pyproject_path=populated_pyproject, today=date(2026, 5, 19))


def test_target_issues_alone_is_allowed(populated_pyproject: Path):
    args = _ns(sprint_start="2026-04-21", target_issues=10)
    cfg = load_config(args, env={}, pyproject_path=populated_pyproject, today=date(2026, 5, 19))
    assert cfg.target_issues == 10
    assert cfg.remaining_sprints is None
    assert cfg.scope_growth is False


def test_sprint_start_after_as_of_raises(populated_pyproject: Path):
    args = _ns(sprint_start="2026-06-01", as_of="2026-05-01")
    with pytest.raises(ConfigError, match="after as-of"):
        load_config(args, env={}, pyproject_path=populated_pyproject)


def test_invalid_format_raises(populated_pyproject: Path):
    args = _ns(sprint_start="2026-04-21", output_format="xml")
    with pytest.raises(ConfigError, match="format"):
        load_config(args, env={}, pyproject_path=populated_pyproject, today=date(2026, 5, 19))


def test_no_color_env_respected(populated_pyproject: Path):
    args = _ns(sprint_start="2026-04-21")
    cfg = load_config(
        args,
        env={"NO_COLOR": "1"},
        pyproject_path=populated_pyproject,
        today=date(2026, 5, 19),
    )
    assert cfg.no_color is True


def test_defaults_applied(populated_pyproject: Path):
    args = _ns(sprint_start="2026-04-21")
    cfg = load_config(args, env={}, pyproject_path=populated_pyproject, today=date(2026, 5, 19))
    assert cfg.bootstrap_samples == 10_000
    assert cfg.seed == 42
    assert cfg.output_format == "json"
    assert cfg.gh_bin == "gh"
