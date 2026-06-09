"""Renderer tests."""

from __future__ import annotations

import io
import json
from datetime import UTC, date, datetime

from rich.console import Console

from team_performance.models import (
    AggregateStats,
    ForwardOutcome,
    LeadTimePercentiles,
    Projection,
    Report,
    Sprint,
    SprintsToTarget,
    ThroughputStats,
)
from team_performance.render.json_renderer import render_json
from team_performance.render.text_renderer import render_text


def _sample_report(*, with_projection: bool = True) -> Report:
    sprint = Sprint(
        index=1,
        phase="development",
        status="closed",
        window_start=date(2026, 5, 7),
        window_end=date(2026, 5, 13),
        completed=("US1", "US2"),
        in_progress=("US3",),
    )
    projection = (
        Projection(
            target_user_stories=10,
            bootstrap_samples=1000,
            method="bootstrap_throughput",
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
        )
        if with_projection
        else None
    )
    return Report(
        schema_version="3",
        generated_at=datetime(2026, 5, 28, 12, 0, tzinfo=UTC),
        config_snapshot={
            "sprints_dir": "docs/progress-reports",
            "phase": "development",
            "target_user_stories": 10,
        },
        sprints=(sprint,),
        aggregate=AggregateStats(
            throughput=ThroughputStats(mean=2.0, median=2.0, stdev=None, min=2, max=2),
            lead_time_sprints=LeadTimePercentiles(p50=0.0, p75=1.0, p90=1.0),
            sample_size_sprints=1,
        ),
        projection=projection,
    )


def test_render_json_schema_v3():
    payload = json.loads(render_json(_sample_report()))
    assert payload["schema_version"] == "3"
    assert payload["sprints"][0]["completed_count"] == 2
    assert payload["sprints"][0]["completed_user_stories"] == ["US1", "US2"]
    assert payload["sprints"][0]["wip_at_end"] == 1
    assert payload["projection"]["target_user_stories"] == 10


def test_render_json_inverse_block_includes_meanings():
    payload = json.loads(render_json(_sample_report(), include_generated_at=False))
    inv = payload["projection"]["sprints_to_target"]
    for key in ("p50", "p85", "p95", "p99", "did_not_finish_pct", "cap_sprints"):
        assert key in inv, f"missing {key}"
        assert f"{key}_meaning" in inv, f"missing {key}_meaning"
    assert payload["projection"]["forward"]["p_meet_or_exceed_target_meaning"]


def test_render_json_aggregate_meanings():
    payload = json.loads(render_json(_sample_report(), include_generated_at=False))
    agg = payload["aggregate"]
    assert agg["throughput"]["mean_meaning"]
    assert agg["lead_time_sprints"]["p50_meaning"]


def test_render_json_byte_identical_when_excluding_generated_at():
    a = render_json(_sample_report(), include_generated_at=False)
    b = render_json(_sample_report(), include_generated_at=False)
    assert a == b


def test_render_json_no_projection():
    payload = json.loads(render_json(_sample_report(with_projection=False)))
    assert payload["projection"] is None


def test_render_text_no_ansi_when_force_terminal_false():
    buf = io.StringIO()
    console = Console(file=buf, force_terminal=False, no_color=True, width=120)
    render_text(_sample_report(), console)
    output = buf.getvalue()
    assert "\x1b[" not in output
    assert "Sprints completados" in output
    assert "Sprints para completar" in output
    assert "Horizonte fijo" in output
    assert "Throughput" in output


def test_render_text_projection_withheld_message():
    buf = io.StringIO()
    console = Console(file=buf, force_terminal=False, no_color=True, width=120)
    render_text(_sample_report(with_projection=False), console)
    assert "Proyección retenida" in buf.getvalue()
