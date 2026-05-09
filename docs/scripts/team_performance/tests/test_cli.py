"""CLI smoke tests — exercises argparse + main() + exit-code mapping."""

from __future__ import annotations

import json
import subprocess
from collections.abc import Callable

import pytest

from team_performance import __version__
from team_performance.cli import (
    EXIT_DATA,
    EXIT_INSUFFICIENT_SAMPLE,
    EXIT_OK,
    EXIT_USAGE,
    main,
)


def test_help_exits_zero(capsys: pytest.CaptureFixture[str]):
    with pytest.raises(SystemExit) as exc_info:
        main(["--help"])
    assert exc_info.value.code == 0
    out = capsys.readouterr().out
    assert "team-performance" in out
    assert "Exit codes" in out


def test_version_exits_zero(capsys: pytest.CaptureFixture[str]):
    with pytest.raises(SystemExit) as exc_info:
        main(["--version"])
    assert exc_info.value.code == 0
    out = capsys.readouterr().out
    assert __version__ in out


def test_remaining_sprints_alone_is_usage_error(capsys: pytest.CaptureFixture[str]):
    with pytest.raises(SystemExit) as exc_info:
        main(["--repo", "x/y", "--sprint-start", "2026-04-21", "--remaining-sprints", "5"])
    assert exc_info.value.code == EXIT_USAGE
    err = capsys.readouterr().err
    assert "target-issues" in err.lower()


def test_end_to_end_with_fake_runner(
    fake_gh_runner: Callable[..., subprocess.CompletedProcess[str]],
    capsys: pytest.CaptureFixture[str],
):
    rc = main(
        [
            "--repo",
            "x/y",
            "--sprint-start",
            "2026-04-21",
            "--as-of",
            "2026-05-19",
            "--format",
            "json",
        ],
        runner=fake_gh_runner,
    )
    assert rc == EXIT_OK
    captured = capsys.readouterr()
    payload = json.loads(captured.out)
    assert payload["schema_version"] == "2"
    assert len(payload["sprints"]) == 2
    # Issue 107 (NOT_PLANNED) closed in sprint 1 → counted as excluded, not throughput.
    assert payload["sprints"][0]["closed_count"] == 3
    assert payload["sprints"][0]["closed_excluded_count"] == 1
    assert payload["sprints"][1]["closed_count"] == 2
    assert payload["projection"] is None


def test_projection_emitted_when_target_provided(
    fake_gh_runner: Callable[..., subprocess.CompletedProcess[str]],
    capsys: pytest.CaptureFixture[str],
):
    rc = main(
        [
            "--repo",
            "x/y",
            "--sprint-start",
            "2026-04-21",
            "--as-of",
            "2026-05-19",
            "--target-issues",
            "10",
            "--remaining-sprints",
            "5",
            "--bootstrap-samples",
            "1000",
            "--format",
            "json",
        ],
        runner=fake_gh_runner,
    )
    assert rc == EXIT_OK
    payload = json.loads(capsys.readouterr().out)
    proj = payload["projection"]
    assert proj is not None
    assert proj["target_issues"] == 10
    assert proj["scope_growth_enabled"] is False
    inv = proj["sprints_to_target"]
    for k in ("p50", "p85", "p95", "p99"):
        assert isinstance(inv[k], int)
    assert proj["forward"]["remaining_sprints"] == 5
    assert "p_meet_or_exceed_target" in proj["forward"]


def test_inverse_only_when_no_horizon(
    fake_gh_runner: Callable[..., subprocess.CompletedProcess[str]],
    capsys: pytest.CaptureFixture[str],
):
    rc = main(
        [
            "--repo",
            "x/y",
            "--sprint-start",
            "2026-04-21",
            "--as-of",
            "2026-05-19",
            "--target-issues",
            "10",
            "--bootstrap-samples",
            "1000",
            "--format",
            "json",
        ],
        runner=fake_gh_runner,
    )
    assert rc == EXIT_OK
    payload = json.loads(capsys.readouterr().out)
    assert payload["projection"]["forward"] is None
    assert payload["projection"]["sprints_to_target"]["p50"] >= 1


def test_scope_growth_flag_enables_split_bootstrap(
    fake_gh_runner: Callable[..., subprocess.CompletedProcess[str]],
    capsys: pytest.CaptureFixture[str],
):
    rc = main(
        [
            "--repo",
            "x/y",
            "--sprint-start",
            "2026-04-21",
            "--as-of",
            "2026-05-19",
            "--target-issues",
            "10",
            "--scope-growth",
            "--bootstrap-samples",
            "1000",
            "--format",
            "json",
        ],
        runner=fake_gh_runner,
    )
    assert rc == EXIT_OK
    payload = json.loads(capsys.readouterr().out)
    assert payload["projection"]["scope_growth_enabled"] is True
    assert payload["projection"]["method"] == "split_bootstrap_throughput"
    assert payload["projection"]["scope_growth"]["created_per_sprint_mean"] >= 0


def test_insufficient_sample_exits_4(
    fake_gh_runner: Callable[..., subprocess.CompletedProcess[str]],
):
    rc = main(
        [
            "--repo",
            "x/y",
            "--sprint-start",
            "2026-04-21",
            "--as-of",
            "2026-04-29",
            "--target-issues",
            "10",
            "--remaining-sprints",
            "5",
            "--format",
            "json",
        ],
        runner=fake_gh_runner,
    )
    assert rc == EXIT_INSUFFICIENT_SAMPLE


def test_data_source_failure_exits_3(
    failing_gh_runner: Callable[..., subprocess.CompletedProcess[str]],
):
    rc = main(
        ["--repo", "x/y", "--sprint-start", "2026-04-21", "--as-of", "2026-05-19"],
        runner=failing_gh_runner,
    )
    assert rc == EXIT_DATA
