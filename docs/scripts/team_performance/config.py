"""Configuration layering.

Resolution order: CLI > env (TEAM_PERF_*) > pyproject [tool.team_performance] > defaults.
"""

from __future__ import annotations

import os
import tomllib
from argparse import Namespace
from dataclasses import dataclass, field
from datetime import date, datetime
from pathlib import Path
from typing import Any

from team_performance.errors import ConfigError

DEFAULT_REPO: str | None = None
DEFAULT_SPRINT_LENGTH_DAYS: int = 14
DEFAULT_BOOTSTRAP_SAMPLES: int = 10_000
DEFAULT_SEED: int = 42
DEFAULT_GH_BIN: str = "gh"
DEFAULT_FORMAT: str = "json"


@dataclass(frozen=True, slots=True)
class AppConfig:
    repo: str
    gh_bin: str
    sprint_start: date
    sprint_length_days: int
    as_of: date
    target_issues: int | None
    remaining_sprints: int | None
    scope_growth: bool
    bootstrap_samples: int
    seed: int
    output_format: str
    no_color: bool
    verbosity: int
    config_snapshot: dict[str, object] = field(default_factory=dict)


def _read_pyproject(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {}
    try:
        with path.open("rb") as f:
            data = tomllib.load(f)
    except (OSError, tomllib.TOMLDecodeError) as exc:
        raise ConfigError(f"failed to read {path}: {exc}") from exc
    tool = data.get("tool", {})
    section = tool.get("team_performance", {})
    if not isinstance(section, dict):
        raise ConfigError(f"[tool.team_performance] in {path} must be a table")
    return section


def _coerce_int(value: object, *, name: str) -> int:
    if isinstance(value, bool):
        raise ConfigError(f"{name} must be an integer, got bool")
    if isinstance(value, int):
        return value
    if isinstance(value, str) and value.strip():
        try:
            return int(value)
        except ValueError as exc:
            raise ConfigError(f"{name} must be an integer, got {value!r}") from exc
    raise ConfigError(f"{name} must be an integer, got {value!r}")


def _coerce_date(value: object, *, name: str) -> date:
    if isinstance(value, datetime):
        return value.date()
    if isinstance(value, date):
        return value
    if isinstance(value, str):
        try:
            return date.fromisoformat(value)
        except ValueError as exc:
            raise ConfigError(f"{name} must be ISO YYYY-MM-DD, got {value!r}") from exc
    raise ConfigError(f"{name} must be ISO YYYY-MM-DD, got {value!r}")


def _coalesce(*values: object) -> object | None:
    for v in values:
        if v is not None:
            return v
    return None


def load_config(
    args: Namespace,
    *,
    env: dict[str, str] | None = None,
    pyproject_path: Path | None = None,
    today: date | None = None,
) -> AppConfig:
    env = env if env is not None else dict(os.environ)
    pyproject_path = pyproject_path if pyproject_path is not None else Path("pyproject.toml")
    today = today or date.today()

    pyproject = _read_pyproject(pyproject_path)

    repo_raw = _coalesce(
        getattr(args, "repo", None),
        env.get("TEAM_PERF_REPO"),
        pyproject.get("repo"),
        DEFAULT_REPO,
    )
    if not isinstance(repo_raw, str) or "/" not in repo_raw:
        raise ConfigError(
            "repo is required as 'OWNER/REPO' (set --repo, TEAM_PERF_REPO, or "
            "[tool.team_performance].repo)"
        )

    gh_bin_raw = _coalesce(
        getattr(args, "gh_bin", None),
        env.get("TEAM_PERF_GH_BIN"),
        pyproject.get("gh_bin"),
        DEFAULT_GH_BIN,
    )
    gh_bin = str(gh_bin_raw)

    sprint_start_raw = _coalesce(
        getattr(args, "sprint_start", None),
        env.get("TEAM_PERF_SPRINT_START"),
        pyproject.get("sprint_start"),
    )
    if sprint_start_raw is None:
        raise ConfigError(
            "sprint-start is required (set --sprint-start, TEAM_PERF_SPRINT_START, or "
            "[tool.team_performance].sprint_start)"
        )
    sprint_start = _coerce_date(sprint_start_raw, name="sprint-start")

    sprint_length_days_raw = _coalesce(
        getattr(args, "sprint_length_days", None),
        env.get("TEAM_PERF_SPRINT_LENGTH_DAYS"),
        pyproject.get("sprint_length_days"),
        DEFAULT_SPRINT_LENGTH_DAYS,
    )
    sprint_length_days = _coerce_int(sprint_length_days_raw, name="sprint-length-days")
    if sprint_length_days <= 0:
        raise ConfigError("sprint-length-days must be positive")

    as_of_raw = _coalesce(getattr(args, "as_of", None), env.get("TEAM_PERF_AS_OF"))
    as_of = _coerce_date(as_of_raw, name="as-of") if as_of_raw is not None else today

    if sprint_start > as_of:
        raise ConfigError(
            f"sprint-start ({sprint_start.isoformat()}) is after as-of ({as_of.isoformat()})"
        )

    target_issues_raw = _coalesce(
        getattr(args, "target_issues", None), env.get("TEAM_PERF_TARGET_ISSUES")
    )
    target_issues = (
        _coerce_int(target_issues_raw, name="target-issues")
        if target_issues_raw is not None
        else None
    )

    remaining_sprints_raw = _coalesce(
        getattr(args, "remaining_sprints", None), env.get("TEAM_PERF_REMAINING_SPRINTS")
    )
    remaining_sprints = (
        _coerce_int(remaining_sprints_raw, name="remaining-sprints")
        if remaining_sprints_raw is not None
        else None
    )

    # Inverse projection requires only --target-issues. Forward (P-meet-by-horizon)
    # additionally requires --remaining-sprints. --remaining-sprints alone is not useful.
    if remaining_sprints is not None and target_issues is None:
        raise ConfigError("--remaining-sprints requires --target-issues")
    if target_issues is not None and target_issues < 0:
        raise ConfigError("target-issues must be non-negative")
    if remaining_sprints is not None and remaining_sprints <= 0:
        raise ConfigError("remaining-sprints must be positive")

    bootstrap_samples_raw = _coalesce(
        getattr(args, "bootstrap_samples", None),
        env.get("TEAM_PERF_BOOTSTRAP_SAMPLES"),
        DEFAULT_BOOTSTRAP_SAMPLES,
    )
    bootstrap_samples = _coerce_int(bootstrap_samples_raw, name="bootstrap-samples")
    if bootstrap_samples <= 0:
        raise ConfigError("bootstrap-samples must be positive")

    seed_raw = _coalesce(getattr(args, "seed", None), env.get("TEAM_PERF_SEED"), DEFAULT_SEED)
    seed = _coerce_int(seed_raw, name="seed")

    output_format = getattr(args, "output_format", None) or env.get(
        "TEAM_PERF_FORMAT", DEFAULT_FORMAT
    )
    if output_format not in {"json", "text", "both"}:
        raise ConfigError(f"format must be one of json|text|both, got {output_format!r}")

    no_color = bool(getattr(args, "no_color", False)) or "NO_COLOR" in env

    verbosity = int(getattr(args, "verbosity", 0))

    scope_growth = bool(getattr(args, "scope_growth", False)) or env.get(
        "TEAM_PERF_SCOPE_GROWTH", ""
    ).lower() in {"1", "true", "yes"}

    snapshot: dict[str, object] = {
        "repo": repo_raw,
        "sprint_start": sprint_start.isoformat(),
        "sprint_length_days": sprint_length_days,
        "as_of": as_of.isoformat(),
        "target_issues": target_issues,
        "remaining_sprints": remaining_sprints,
        "scope_growth": scope_growth,
        "bootstrap_samples": bootstrap_samples,
        "seed": seed,
        "format": output_format,
    }

    return AppConfig(
        repo=repo_raw,
        gh_bin=gh_bin,
        sprint_start=sprint_start,
        sprint_length_days=sprint_length_days,
        as_of=as_of,
        target_issues=target_issues,
        remaining_sprints=remaining_sprints,
        scope_growth=scope_growth,
        bootstrap_samples=bootstrap_samples,
        seed=seed,
        output_format=output_format,
        no_color=no_color,
        verbosity=verbosity,
        config_snapshot=snapshot,
    )
