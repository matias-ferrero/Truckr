"""CLI smoke tests — exercises argparse + main() + exit-code mapping."""

from __future__ import annotations

import json
from pathlib import Path

import pytest

from team_performance import __version__
from team_performance.cli import (
    EXIT_DATA,
    EXIT_INSUFFICIENT_SAMPLE,
    EXIT_OK,
    EXIT_USAGE,
    main,
)
from team_performance.tests.conftest import SprintWriter


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
    assert __version__ in capsys.readouterr().out


def test_remaining_sprints_alone_is_usage_error(
    capsys: pytest.CaptureFixture[str],
    sprints_fixture_dir: Path,
    backlog_us_fixture: Path,
):
    with pytest.raises(SystemExit) as exc_info:
        main(
            [
                "--sprints-dir",
                str(sprints_fixture_dir),
                "--backlog-us",
                str(backlog_us_fixture),
                "--remaining-sprints",
                "5",
            ]
        )
    assert exc_info.value.code == EXIT_USAGE
    assert "target-user-stories" in capsys.readouterr().err.lower()


def _base_args(sprints_dir: Path, backlog: Path) -> list[str]:
    return [
        "--sprints-dir",
        str(sprints_dir),
        "--backlog-us",
        str(backlog),
        "--format",
        "json",
    ]


def test_end_to_end_stats_only(
    capsys: pytest.CaptureFixture[str],
    sprints_fixture_dir: Path,
    backlog_us_fixture: Path,
):
    rc = main(_base_args(sprints_fixture_dir, backlog_us_fixture))
    assert rc == EXIT_OK
    payload = json.loads(capsys.readouterr().out)
    assert payload["schema_version"] == "3"
    assert len(payload["sprints"]) == 3
    assert payload["sprints"][0]["completed_count"] == 2
    assert payload["sprints"][2]["completed_count"] == 1
    assert payload["projection"] is None


def test_projection_emitted_with_target_and_horizon(
    capsys: pytest.CaptureFixture[str],
    sprints_fixture_dir: Path,
    backlog_us_fixture: Path,
):
    rc = main(
        [
            *_base_args(sprints_fixture_dir, backlog_us_fixture),
            "--target-user-stories",
            "5",
            "--remaining-sprints",
            "3",
            "--bootstrap-samples",
            "1000",
        ]
    )
    assert rc == EXIT_OK
    proj = json.loads(capsys.readouterr().out)["projection"]
    assert proj is not None
    assert proj["target_user_stories"] == 5
    assert proj["method"] == "bootstrap_throughput"
    for k in ("p50", "p85", "p95", "p99"):
        assert isinstance(proj["sprints_to_target"][k], int)
    assert proj["forward"]["remaining_sprints"] == 3


def test_inverse_only_when_no_horizon(
    capsys: pytest.CaptureFixture[str],
    sprints_fixture_dir: Path,
    backlog_us_fixture: Path,
):
    rc = main(
        [
            *_base_args(sprints_fixture_dir, backlog_us_fixture),
            "--target-user-stories",
            "5",
            "--bootstrap-samples",
            "1000",
        ]
    )
    assert rc == EXIT_OK
    proj = json.loads(capsys.readouterr().out)["projection"]
    assert proj["forward"] is None
    assert proj["sprints_to_target"]["p50"] >= 1


def test_insufficient_sample_exits_4(
    tmp_path: Path,
    backlog_us_fixture: Path,
    make_sprint: SprintWriter,
):
    make_sprint(tmp_path, 1, completed=["US1"])  # only one closed sprint
    rc = main([*_base_args(tmp_path, backlog_us_fixture), "--target-user-stories", "5"])
    assert rc == EXIT_INSUFFICIENT_SAMPLE


def test_data_source_failure_exits_3(
    tmp_path: Path,
    backlog_us_fixture: Path,
    make_sprint: SprintWriter,
):
    make_sprint(tmp_path, 1, completed=[], raw="---\nsprint: 1\n")  # unterminated frontmatter
    rc = main(_base_args(tmp_path, backlog_us_fixture))
    assert rc == EXIT_DATA


def test_unknown_us_id_exits_3_by_default(
    tmp_path: Path,
    backlog_us_fixture: Path,
    make_sprint: SprintWriter,
):
    make_sprint(tmp_path, 1, completed=["US1"])
    make_sprint(tmp_path, 2, completed=["US99"])  # not in the US1..US5 fixture catalogue
    assert main(_base_args(tmp_path, backlog_us_fixture)) == EXIT_DATA


def test_no_us_validation_skips_catalog(
    tmp_path: Path,
    backlog_us_fixture: Path,
    make_sprint: SprintWriter,
):
    make_sprint(tmp_path, 1, completed=["US1"])
    make_sprint(tmp_path, 2, completed=["US99"])
    rc = main([*_base_args(tmp_path, backlog_us_fixture), "--no-us-validation"])
    assert rc == EXIT_OK
