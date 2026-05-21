"""Configuration layering.

Resolution order per setting: CLI flag > env (TEAM_PERF_*) > built-in default.
"""

from __future__ import annotations

import os
from argparse import Namespace
from dataclasses import dataclass, field
from pathlib import Path

from team_performance.errors import ConfigError

DEFAULT_SPRINTS_DIR = "docs/sprints"
DEFAULT_PHASE = "development"
DEFAULT_BACKLOG_US = "docs/artifacts/backlog-us.typ"
DEFAULT_BOOTSTRAP_SAMPLES = 10_000
DEFAULT_SEED = 42
DEFAULT_OUTPUT_FORMAT = "json"


@dataclass(frozen=True, slots=True)
class AppConfig:
    sprints_dir: Path
    phase: str
    backlog_us: Path
    validate_us_ids: bool
    target_user_stories: int | None
    remaining_sprints: int | None
    bootstrap_samples: int
    seed: int
    output_format: str
    no_color: bool
    verbosity: int
    config_snapshot: dict[str, object] = field(default_factory=dict)


def _coalesce(*values: object) -> object | None:
    for value in values:
        if value is not None:
            return value
    return None


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


def load_config(args: Namespace, *, env: dict[str, str] | None = None) -> AppConfig:
    env = env if env is not None else dict(os.environ)

    sprints_dir = Path(
        str(
            _coalesce(
                getattr(args, "sprints_dir", None),
                env.get("TEAM_PERF_SPRINTS_DIR"),
                DEFAULT_SPRINTS_DIR,
            )
        )
    )

    phase = str(
        _coalesce(getattr(args, "phase", None), env.get("TEAM_PERF_PHASE"), DEFAULT_PHASE)
    ).strip()
    if not phase:
        raise ConfigError("phase must not be empty")

    backlog_us = Path(
        str(
            _coalesce(
                getattr(args, "backlog_us", None),
                env.get("TEAM_PERF_BACKLOG_US"),
                DEFAULT_BACKLOG_US,
            )
        )
    )

    target_raw = _coalesce(
        getattr(args, "target_user_stories", None), env.get("TEAM_PERF_TARGET_USER_STORIES")
    )
    target_user_stories = (
        _coerce_int(target_raw, name="target-user-stories") if target_raw is not None else None
    )

    remaining_raw = _coalesce(
        getattr(args, "remaining_sprints", None), env.get("TEAM_PERF_REMAINING_SPRINTS")
    )
    remaining_sprints = (
        _coerce_int(remaining_raw, name="remaining-sprints") if remaining_raw is not None else None
    )

    # Inverse projection needs only --target-user-stories. Forward additionally
    # needs --remaining-sprints; --remaining-sprints alone is not useful.
    if remaining_sprints is not None and target_user_stories is None:
        raise ConfigError("--remaining-sprints requires --target-user-stories")
    if target_user_stories is not None and target_user_stories < 0:
        raise ConfigError("target-user-stories must be non-negative")
    if remaining_sprints is not None and remaining_sprints <= 0:
        raise ConfigError("remaining-sprints must be positive")

    bootstrap_samples = _coerce_int(
        _coalesce(
            getattr(args, "bootstrap_samples", None),
            env.get("TEAM_PERF_BOOTSTRAP_SAMPLES"),
            DEFAULT_BOOTSTRAP_SAMPLES,
        ),
        name="bootstrap-samples",
    )
    if bootstrap_samples <= 0:
        raise ConfigError("bootstrap-samples must be positive")

    seed = _coerce_int(
        _coalesce(getattr(args, "seed", None), env.get("TEAM_PERF_SEED"), DEFAULT_SEED),
        name="seed",
    )

    output_format = getattr(args, "output_format", None) or env.get(
        "TEAM_PERF_FORMAT", DEFAULT_OUTPUT_FORMAT
    )
    if output_format not in {"json", "text", "both"}:
        raise ConfigError(f"format must be one of json|text|both, got {output_format!r}")

    no_color = bool(getattr(args, "no_color", False)) or "NO_COLOR" in env
    verbosity = int(getattr(args, "verbosity", 0))

    validate_us_ids = not (
        bool(getattr(args, "no_us_validation", False))
        or env.get("TEAM_PERF_NO_US_VALIDATION", "").lower() in {"1", "true", "yes"}
    )

    snapshot: dict[str, object] = {
        "sprints_dir": str(sprints_dir),
        "phase": phase,
        "backlog_us": str(backlog_us),
        "validate_us_ids": validate_us_ids,
        "target_user_stories": target_user_stories,
        "remaining_sprints": remaining_sprints,
        "bootstrap_samples": bootstrap_samples,
        "seed": seed,
        "format": output_format,
    }

    return AppConfig(
        sprints_dir=sprints_dir,
        phase=phase,
        backlog_us=backlog_us,
        validate_us_ids=validate_us_ids,
        target_user_stories=target_user_stories,
        remaining_sprints=remaining_sprints,
        bootstrap_samples=bootstrap_samples,
        seed=seed,
        output_format=output_format,
        no_color=no_color,
        verbosity=verbosity,
        config_snapshot=snapshot,
    )
