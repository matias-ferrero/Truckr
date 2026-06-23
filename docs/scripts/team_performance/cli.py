"""argparse + main() + error → exit-code mapping."""

from __future__ import annotations

import argparse
import logging
import sys
from datetime import UTC, datetime

from rich.console import Console

from team_performance import __version__
from team_performance.config import AS_OF_LATEST, AppConfig, load_config
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
from team_performance.mvp_scope import load_mvp_scope
from team_performance.projection import bootstrap_forward, bootstrap_inverse
from team_performance.reconstruction import build_reconstruction, resolve_as_of
from team_performance.render.json_renderer import render_json
from team_performance.render.text_renderer import render_text
from team_performance.us_catalog import load_us_catalog

EXIT_OK = 0
EXIT_USAGE = 2
EXIT_DATA = 3
EXIT_INSUFFICIENT_SAMPLE = 4

SCHEMA_VERSION = "4"

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

    rec = p.add_argument_group("Reconstruction (optional)")
    rec.add_argument(
        "--as-of-sprint",
        dest="as_of_sprint",
        type=int,
        nargs="?",
        const=AS_OF_LATEST,
        help="Reconstruct the report as it stood at the end of sprint N (bare flag = latest "
        "closed sprint). Derives the target (remaining MVP) and horizon from N; cannot be "
        "combined with --target-user-stories / --remaining-sprints.",
    )
    rec.add_argument(
        "--total-dev-sprints",
        dest="total_dev_sprints",
        type=int,
        help="Development-phase length, for the derived horizon (default: 6; Sprint 7 is "
        "artifact-polish, not development).",
    )

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


def _project(
    throughput: list[int],
    *,
    target: int,
    horizon: int | None,
    samples: int,
    seed: int,
) -> Projection | None:
    """Bootstrap a projection for an explicit target/horizon. None on insufficient sample."""
    try:
        inverse = bootstrap_inverse(
            throughput,
            target_user_stories=target,
            samples=samples,
            seed=seed,
            horizon_hint=horizon,
        )
    except InsufficientDataError as exc:
        logger.warning("%s", exc)
        return None

    forward = None
    if horizon is not None:
        forward = bootstrap_forward(
            throughput,
            target_user_stories=target,
            remaining_sprints=horizon,
            samples=samples,
            seed=seed,
        )

    return Projection(
        target_user_stories=target,
        bootstrap_samples=samples,
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

    if cfg.as_of_sprint is not None:
        return _build_reconstruction_report(cfg, sprints, now=now)

    aggregate = compute_aggregate(sprints)
    throughput = [len(s.completed) for s in sprints]
    projection = (
        _project(
            throughput,
            target=cfg.target_user_stories,
            horizon=cfg.remaining_sprints,
            samples=cfg.bootstrap_samples,
            seed=cfg.seed,
        )
        if cfg.target_user_stories is not None
        else None
    )
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


def _build_reconstruction_report(
    cfg: AppConfig, sprints: tuple[Sprint, ...], *, now: datetime | None = None
) -> tuple[Report, bool]:
    """Reconstruct the report as of sprint N: truncate, MVP-scope, derive target + horizon."""
    assert cfg.as_of_sprint is not None  # guarded by the caller
    latest_closed = sprints[-1].index if sprints else 0
    as_of = resolve_as_of(cfg.as_of_sprint, latest_closed)
    mvp_ids = load_mvp_scope(cfg.backlog_us)

    window, recon = build_reconstruction(
        sprints,
        as_of_sprint=as_of,
        total_dev_sprints=cfg.total_dev_sprints,
        mvp_ids=mvp_ids,
    )
    aggregate = compute_aggregate(window)
    throughput = [len(s.completed) for s in window]

    if recon.already_complete:
        projection, insufficient = None, False
    elif len(window) < 2:
        projection, insufficient = None, True
    else:
        projection = _project(
            throughput,
            target=recon.derived_target_user_stories,
            horizon=recon.derived_remaining_sprints,
            samples=cfg.bootstrap_samples,
            seed=cfg.seed,
        )
        insufficient = projection is None

    report = Report(
        schema_version=SCHEMA_VERSION,
        generated_at=now or datetime.now(UTC),
        config_snapshot=cfg.config_snapshot,
        sprints=window,
        aggregate=aggregate,
        projection=projection,
        reconstruction=recon,
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
