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
from team_performance.github_source import Runner, fetch_issues
from team_performance.logging_setup import configure_logging
from team_performance.metrics import compute_aggregate
from team_performance.models import Projection, Report, ScopeGrowthStats
from team_performance.projection import bootstrap_forward, bootstrap_inverse
from team_performance.render.json_renderer import render_json
from team_performance.render.text_renderer import render_text
from team_performance.sprints import assign_to_sprints

EXIT_OK = 0
EXIT_USAGE = 2
EXIT_DATA = 3
EXIT_INSUFFICIENT_SAMPLE = 4

SCHEMA_VERSION = "2"

logger = logging.getLogger(__name__)


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="team-performance",
        description="Throughput-based team performance metrics + bootstrap projection.",
        epilog=("Exit codes: 0 ok, 2 usage, 3 data source, 4 insufficient sample for projection."),
    )
    p.add_argument("--version", action="version", version=f"team-performance {__version__}")

    src = p.add_argument_group("Data source")
    src.add_argument("--repo", help="OWNER/REPO (default: pyproject [tool.team_performance].repo)")
    src.add_argument("--gh-bin", dest="gh_bin", help="Path to gh CLI (default: 'gh')")

    sp = p.add_argument_group("Sprint definition")
    sp.add_argument("--sprint-start", dest="sprint_start", help="YYYY-MM-DD start of Sprint 1")
    sp.add_argument(
        "--sprint-length-days",
        dest="sprint_length_days",
        type=int,
        help="Length of each sprint in days (default: 14)",
    )
    sp.add_argument("--as-of", dest="as_of", help="YYYY-MM-DD cutoff for completed sprints")

    pj = p.add_argument_group("Projection (optional)")
    pj.add_argument(
        "--target-issues",
        dest="target_issues",
        type=int,
        help="Issues to reach. Triggers an inverse projection (sprints needed at p50/p85/p95/p99).",
    )
    pj.add_argument(
        "--remaining-sprints",
        dest="remaining_sprints",
        type=int,
        help="Optional fixed horizon. Adds a forward projection (P[≥ target] in N sprints).",
    )
    pj.add_argument(
        "--scope-growth",
        dest="scope_growth",
        action="store_true",
        help=(
            "Split Monte Carlo: also sample items-created per sprint and grow the target "
            "during each trial. Off by default."
        ),
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


def _build_projection(
    cfg: AppConfig,
    closed_throughput: list[int],
    created_throughput: list[int],
) -> Projection | None:
    """Build a Projection if --target-issues was given. Returns None on insufficient sample."""
    if cfg.target_issues is None:
        return None

    created_for_sim = created_throughput if cfg.scope_growth else None

    try:
        inverse = bootstrap_inverse(
            closed_throughput,
            target_issues=cfg.target_issues,
            samples=cfg.bootstrap_samples,
            seed=cfg.seed,
            created_throughput=created_for_sim,
            horizon_hint=cfg.remaining_sprints,
        )
    except InsufficientDataError as exc:
        logger.warning("%s", exc)
        return None

    forward = None
    if cfg.remaining_sprints is not None:
        forward = bootstrap_forward(
            closed_throughput,
            target_issues=cfg.target_issues,
            remaining_sprints=cfg.remaining_sprints,
            samples=cfg.bootstrap_samples,
            seed=cfg.seed,
            created_throughput=created_for_sim,
        )

    scope_growth_stats = None
    if cfg.scope_growth and created_throughput:
        sorted_created = sorted(created_throughput)
        scope_growth_stats = ScopeGrowthStats(
            created_per_sprint_mean=sum(sorted_created) / len(sorted_created),
            created_per_sprint_median=sorted_created[len(sorted_created) // 2],
            created_per_sprint_min=sorted_created[0],
            created_per_sprint_max=sorted_created[-1],
        )

    return Projection(
        target_issues=cfg.target_issues,
        bootstrap_samples=cfg.bootstrap_samples,
        method=("split_bootstrap_throughput" if cfg.scope_growth else "bootstrap_throughput"),
        scope_growth_enabled=cfg.scope_growth,
        sprints_to_target=inverse,
        forward=forward,
        scope_growth=scope_growth_stats,
    )


def _build_report(
    cfg: AppConfig,
    *,
    runner: Runner | None = None,
    now: datetime | None = None,
) -> tuple[Report, bool]:
    """Build the report. Returns (report, insufficient_sample_for_projection)."""
    fetch_kwargs: dict[str, object] = {"gh_bin": cfg.gh_bin}
    if runner is not None:
        fetch_kwargs["runner"] = runner
    issues = fetch_issues(cfg.repo, **fetch_kwargs)  # type: ignore[arg-type]
    sprints = assign_to_sprints(issues, cfg.sprint_start, cfg.sprint_length_days, cfg.as_of)
    aggregate = compute_aggregate(sprints)

    closed_throughput = [len(s.closed) for s in sprints]
    created_throughput = [len(s.created) for s in sprints]

    projection = _build_projection(cfg, closed_throughput, created_throughput)
    insufficient = cfg.target_issues is not None and projection is None

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


def main(argv: list[str] | None = None, *, runner: Runner | None = None) -> int:
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
        report, insufficient = _build_report(cfg, runner=runner)
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
