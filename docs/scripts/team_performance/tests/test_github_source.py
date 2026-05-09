"""GitHub source tests — `gh` is mocked via the ``runner`` seam."""

from __future__ import annotations

import subprocess
from collections.abc import Callable

import pytest

from team_performance.errors import DataSourceError
from team_performance.github_source import fetch_issues


def test_parses_fixture(
    fake_gh_runner: Callable[..., subprocess.CompletedProcess[str]],
):
    issues = fetch_issues("x/y", runner=fake_gh_runner)
    assert len(issues) == 7
    closed_numbers = sorted(i.number for i in issues if i.closed_at is not None)
    assert closed_numbers == [101, 102, 103, 104, 105, 107]
    open_only = [i for i in issues if i.closed_at is None]
    assert len(open_only) == 1
    assert open_only[0].number == 106
    assert open_only[0].state == "open"


def test_state_reason_parsed_and_uppercased(
    fake_gh_runner: Callable[..., subprocess.CompletedProcess[str]],
):
    issues = fetch_issues("x/y", runner=fake_gh_runner)
    by_number = {i.number: i for i in issues}
    assert by_number[101].state_reason == "COMPLETED"
    assert by_number[107].state_reason == "NOT_PLANNED"
    assert by_number[106].state_reason is None


def test_failing_runner_raises_data_source(
    failing_gh_runner: Callable[..., subprocess.CompletedProcess[str]],
):
    with pytest.raises(DataSourceError, match="exited with code 1"):
        fetch_issues("x/y", runner=failing_gh_runner)


def test_malformed_json_raises_data_source(
    malformed_gh_runner: Callable[..., subprocess.CompletedProcess[str]],
):
    with pytest.raises(DataSourceError, match="invalid JSON"):
        fetch_issues("x/y", runner=malformed_gh_runner)


def test_timeout_raises_data_source():
    def runner(cmd: list[str], *, timeout: float):
        raise subprocess.TimeoutExpired(cmd, timeout)

    with pytest.raises(DataSourceError, match="timed out"):
        fetch_issues("x/y", runner=runner)


def test_non_list_payload_raises():
    def runner(cmd: list[str], *, timeout: float):
        return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="{}", stderr="")

    with pytest.raises(DataSourceError, match="expected list"):
        fetch_issues("x/y", runner=runner)


def test_missing_required_field_raises():
    def runner(cmd: list[str], *, timeout: float):
        return subprocess.CompletedProcess(
            args=cmd,
            returncode=0,
            stdout='[{"number": 1, "title": "x", "state": "OPEN", "labels": []}]',
            stderr="",
        )

    with pytest.raises(DataSourceError, match="createdAt"):
        fetch_issues("x/y", runner=runner)
