"""argparse + main() + error → exit-code mapping."""

from __future__ import annotations

import argparse
import logging
import sys
from datetime import UTC, datetime

from rich.console import Console

from team_performance import __version__
from team_performance.config import AppConfig, load_config
from team_performance.errors import (
    ConfigError,
    DataSourceError,
    InsufficientDataError,
    TeamPerfError,
)
from team_performance.ledger_source import load_sprints
from team_performance.logging_setup import configure_logging
from team_performance.metrics import compute_aggregate
from team_performance.models import Projection, Report, Sprint
from team_performance.projection import bootstrap_forward, bootstrap_inverse
from team_performance.render.json_renderer import render_json
from team_performance.render.text_renderer import render_text
from team_performance.us_catalog import load_us_catalog

EXIT_OK = 0
EXIT_USAGE = 2
EXIT_DATA = 3
EXIT_INSUFFICIENT_SAMPLE = 4

SCHEMA_VERSION = "3"

logger = logging.getLogger(__name__)


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="team-performance",
        description=(
            "User-Story throughput metrics + bootstrap projection, from the per-sprint ledger."
        ),
        epilog="Exit codes: 0 ok, 2 usage, 3 data source, 4 insufficient sample for projection.",
    )
    p.add_argument("--version", action="version", version=f"team-performance {__version__}")

    src = p.add_argument_group("Data source")
    src.add_argument(
        "--sprints-dir",
        dest="sprints_dir",
        help="Directory of sprint ledger files (default: docs/progress-reports)",
    )
    src.add_argument(
        "--phase",
        dest="phase",
        help="Sprint phase to score: development | documentation (default: development)",
    )
    src.add_argument(
        "--backlog-us",
        dest="backlog_us",
        help="Path to the US backlog artifact, used to validate ids "
        "(default: docs/artifacts/backlog-us.typ)",
    )
    src.add_argument(
        "--no-us-validation",
        dest="no_us_validation",
        action="store_true",
        help="Skip checking ledger US ids against the backlog artifact "
        "(use while the backlog is behind the ledger).",
    )

    pj = p.add_argument_group("Projection (optional)")
    pj.add_argument(
        "--target-user-stories",
        dest="target_user_stories",
        type=int,
        help="User Stories to reach. Triggers an inverse projection "
        "(sprints needed at p50/p85/p95/p99).",
    )
    pj.add_argument(
        "--remaining-sprints",
        dest="remaining_sprints",
        type=int,
        help="Optional fixed horizon. Adds a forward projection (P[>= target] in N sprints).",
    )
    pj.add_argument(
        "--bootstrap-samples",
        dest="bootstrap_samples",
        type=int,
        help="Bootstrap samples (default: 10000)",
    )
    pj.add_argument("--seed", type=int, help="RNG seed (default: 42)")

    out = p.add_argument_group("Output")
    out.add_argument(
        "--format",
        dest="output_format",
        choices=("json", "text", "both"),
        help="Output format (default: json)",
    )
    out.add_argument(
        "--no-color", dest="no_color", action="store_true", help="Disable color (also NO_COLOR env)"
    )
    out.add_argument(
        "-v",
        "--verbose",
        dest="verbosity",
        action="count",
        default=0,
        help="Increase verbosity (can be repeated)",
    )
    out.add_argument(
        "-q",
        "--quiet",
        dest="quiet",
        action="store_true",
        help="Only show errors (overrides --verbose)",
    )
    return p


def _build_projection(cfg: AppConfig, throughput: list[int]) -> Projection | None:
    """Build a Projection if --target-user-stories was given. None on insufficient sample."""
    if cfg.target_user_stories is None:
        return None

    try:
        inverse = bootstrap_inverse(
            throughput,
            target_user_stories=cfg.target_user_stories,
            samples=cfg.bootstrap_samples,
            seed=cfg.seed,
            horizon_hint=cfg.remaining_sprints,
        )
    except InsufficientDataError as exc:
        logger.warning("%s", exc)
        return None

    forward = None
    if cfg.remaining_sprints is not None:
        forward = bootstrap_forward(
            throughput,
            target_user_stories=cfg.target_user_stories,
            remaining_sprints=cfg.remaining_sprints,
            samples=cfg.bootstrap_samples,
            seed=cfg.seed,
        )

    return Projection(
        target_user_stories=cfg.target_user_stories,
        bootstrap_samples=cfg.bootstrap_samples,
        method="bootstrap_throughput",
        sprints_to_target=inverse,
        forward=forward,
    )


def _build_report(cfg: AppConfig, *, now: datetime | None = None) -> tuple[Report, bool]:
    """Build the report. Returns (report, insufficient_sample_for_projection)."""
    us_catalog = load_us_catalog(cfg.backlog_us) if cfg.validate_us_ids else None
    sprints: tuple[Sprint, ...] = load_sprints(
        cfg.sprints_dir, phase=cfg.phase, us_catalog=us_catalog
    )
    aggregate = compute_aggregate(sprints)

    throughput = [len(s.completed) for s in sprints]
    projection = _build_projection(cfg, throughput)
    insufficient = cfg.target_user_stories is not None and projection is None

    report = Report(
        schema_version=SCHEMA_VERSION,
        generated_at=now or datetime.now(UTC),
        config_snapshot=cfg.config_snapshot,
        sprints=sprints,
        aggregate=aggregate,
        projection=projection,
    )
    return report, insufficient


def _emit(report: Report, cfg: AppConfig) -> None:
    if cfg.output_format in {"text", "both"}:
        console = Console(file=sys.stderr, no_color=cfg.no_color, force_terminal=not cfg.no_color)
        render_text(report, console)
    if cfg.output_format in {"json", "both"}:
        sys.stdout.write(render_json(report))
        sys.stdout.write("\n")


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    if getattr(args, "quiet", False):
        args.verbosity = -1

    try:
        cfg = load_config(args)
    except ConfigError as exc:
        parser.error(str(exc))
        return EXIT_USAGE  # parser.error() calls sys.exit(2); kept for type-checkers

    configure_logging(cfg.verbosity)

    try:
        report, insufficient = _build_report(cfg)
    except DataSourceError as exc:
        logger.error("data source: %s", exc)
        return EXIT_DATA
    except TeamPerfError as exc:
        logger.error("%s", exc)
        return EXIT_DATA

    _emit(report, cfg)

    if insufficient:
        return EXIT_INSUFFICIENT_SAMPLE
    return EXIT_OK


if __name__ == "__main__":  # pragma: no cover
    sys.exit(main())
