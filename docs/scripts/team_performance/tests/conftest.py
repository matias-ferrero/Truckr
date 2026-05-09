"""Shared pytest fixtures."""

from __future__ import annotations

import json
import subprocess
from collections.abc import Callable
from datetime import UTC, datetime
from pathlib import Path

import pytest

FIXTURES_DIR = Path(__file__).parent / "fixtures"


@pytest.fixture
def sample_issues_json() -> str:
    return (FIXTURES_DIR / "sample_issues.json").read_text(encoding="utf-8")


@pytest.fixture
def frozen_now() -> datetime:
    return datetime(2026, 5, 19, 12, 0, tzinfo=UTC)


@pytest.fixture
def fake_gh_runner(sample_issues_json: str) -> Callable[..., subprocess.CompletedProcess[str]]:
    def runner(cmd: list[str], *, timeout: float) -> subprocess.CompletedProcess[str]:
        return subprocess.CompletedProcess(
            args=cmd, returncode=0, stdout=sample_issues_json, stderr=""
        )

    return runner


@pytest.fixture
def failing_gh_runner() -> Callable[..., subprocess.CompletedProcess[str]]:
    def runner(cmd: list[str], *, timeout: float) -> subprocess.CompletedProcess[str]:
        return subprocess.CompletedProcess(
            args=cmd, returncode=1, stdout="", stderr="repo not found"
        )

    return runner


@pytest.fixture
def malformed_gh_runner() -> Callable[..., subprocess.CompletedProcess[str]]:
    def runner(cmd: list[str], *, timeout: float) -> subprocess.CompletedProcess[str]:
        return subprocess.CompletedProcess(args=cmd, returncode=0, stdout="not-json{", stderr="")

    return runner


@pytest.fixture
def parsed_sample_issues(sample_issues_json: str) -> list[dict[str, object]]:
    return json.loads(sample_issues_json)
