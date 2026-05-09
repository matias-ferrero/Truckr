"""Renderer tests."""

from __future__ import annotations

import io
import json
from datetime import UTC, datetime

from rich.console import Console

from team_performance.models import (
    AggregateStats,
    CycleTimePercentiles,
    ForwardOutcome,
    Issue,
    Projection,
    Report,
    ScopeGrowthStats,
    Sprint,
    SprintsToTarget,
    ThroughputStats,
)
from team_performance.render.json_renderer import render_json
from team_performance.render.text_renderer import render_text


def _sample_report(*, include_scope_growth: bool = False) -> Report:
    issue = Issue(
        number=1,
        title="x",
        state="closed",
        state_reason="COMPLETED",
        created_at=datetime(2026, 4, 21, tzinfo=UTC),
        closed_at=datetime(2026, 4, 25, tzinfo=UTC),
        labels=(),
    )
    sprint = Sprint(
        index=1,
        start=datetime(2026, 4, 21, tzinfo=UTC),
        end=datetime(2026, 5, 5, tzinfo=UTC),
        closed=(issue,),
        closed_excluded=(),
        created=(issue,),
        wip_at_end=0,
    )
    return Report(
        schema_version="2",
        generated_at=datetime(2026, 5, 19, 12, 0, tzinfo=UTC),
        config_snapshot={
            "repo": "x/y",
            "sprint_start": "2026-04-21",
            "scope_growth": include_scope_growth,
        },
        sprints=(sprint,),
        aggregate=AggregateStats(
            throughput=ThroughputStats(mean=1.0, median=1.0, stdev=None, min=1, max=1),
            created_per_sprint=ThroughputStats(mean=1.0, median=1.0, stdev=None, min=1, max=1),
            cycle_time_days=CycleTimePercentiles(p50=4.0, p75=4.0, p90=4.0),
            sample_size_sprints=1,
            closed_excluded_total=0,
        ),
        projection=Projection(
            target_issues=10,
            bootstrap_samples=1000,
            method="split_bootstrap_throughput" if include_scope_growth else "bootstrap_throughput",
            scope_growth_enabled=include_scope_growth,
            sprints_to_target=SprintsToTarget(
                p50=4, p85=6, p95=7, p99=8, did_not_finish_pct=0.0, cap_sprints=50
            ),
            forward=ForwardOutcome(
                remaining_sprints=5,
                p_meet_or_exceed_target=0.5,
                total_projected_p10=8,
                total_projected_p50=10,
                total_projected_p90=12,
            ),
            scope_growth=ScopeGrowthStats(
                created_per_sprint_mean=2.0,
                created_per_sprint_median=2,
                created_per_sprint_min=1,
                created_per_sprint_max=3,
            )
            if include_scope_growth
            else None,
        ),
    )


def test_render_json_is_valid_with_schema_version():
    out = render_json(_sample_report())
    payload = json.loads(out)
    assert payload["schema_version"] == "2"
    assert payload["sprints"][0]["closed_count"] == 1
    assert payload["projection"]["target_issues"] == 10


def test_render_json_inverse_block_includes_meanings():
    out = render_json(_sample_report(), include_generated_at=False)
    payload = json.loads(out)
    inv = payload["projection"]["sprints_to_target"]
    for key in ("p50", "p85", "p95", "p99", "did_not_finish_pct", "cap_sprints"):
        assert key in inv, f"missing {key}"
        assert f"{key}_meaning" in inv, f"missing {key}_meaning"
    assert payload["projection"]["forward"]["p_meet_or_exceed_target_meaning"]


def test_render_json_scope_growth_block_present_when_enabled():
    out = render_json(_sample_report(include_scope_growth=True), include_generated_at=False)
    payload = json.loads(out)
    sg = payload["projection"]["scope_growth"]
    assert sg["created_per_sprint_mean"] == 2.0
    assert sg["created_per_sprint_mean_meaning"]


def test_render_json_byte_identical_when_excluding_generated_at():
    a = render_json(_sample_report(), include_generated_at=False)
    b = render_json(_sample_report(), include_generated_at=False)
    assert a == b


def test_render_text_no_ansi_when_force_terminal_false():
    buf = io.StringIO()
    console = Console(file=buf, force_terminal=False, no_color=True, width=120)
    render_text(_sample_report(), console)
    output = buf.getvalue()
    assert "\x1b[" not in output
    assert "Sprints completados" in output
    assert "Sprints para cerrar" in output
    assert "Horizonte fijo" in output
    assert "Throughput" in output


def test_render_text_includes_scope_growth_section():
    buf = io.StringIO()
    console = Console(file=buf, force_terminal=False, no_color=True, width=140)
    render_text(_sample_report(include_scope_growth=True), console)
    output = buf.getvalue()
    assert "Crecimiento de alcance" in output
