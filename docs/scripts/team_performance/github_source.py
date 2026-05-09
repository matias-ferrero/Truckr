"""Fetch issues from GitHub via the ``gh`` CLI.

The ``runner`` parameter is a seam for tests: pass a fake that returns a
``CompletedProcess`` instead of shelling out.
"""

from __future__ import annotations

import json
import logging
import shutil
import subprocess
from collections.abc import Callable, Sequence
from datetime import datetime
from typing import Any

from team_performance.errors import DataSourceError
from team_performance.models import Issue

logger = logging.getLogger(__name__)

Runner = Callable[..., subprocess.CompletedProcess[str]]

_REQUIRED_FIELDS = (
    "number",
    "title",
    "state",
    "stateReason",
    "createdAt",
    "closedAt",
    "labels",
)
_GH_FIELDS_ARG = ",".join(_REQUIRED_FIELDS)


def _default_runner(cmd: Sequence[str], *, timeout: float) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        list(cmd),
        capture_output=True,
        text=True,
        timeout=timeout,
        check=False,
    )


def _parse_dt(value: object, *, field: str, issue_number: int | None) -> datetime | None:
    if value is None or value == "":
        return None
    if not isinstance(value, str):
        raise DataSourceError(
            f"issue #{issue_number}: {field} expected ISO-8601 string, got {type(value).__name__}"
        )
    try:
        return datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError as exc:
        raise DataSourceError(f"issue #{issue_number}: invalid {field} {value!r}: {exc}") from exc


def _parse_labels(value: object) -> tuple[str, ...]:
    if value is None:
        return ()
    if not isinstance(value, list):
        raise DataSourceError(f"labels expected list, got {type(value).__name__}")
    out: list[str] = []
    for item in value:
        if isinstance(item, dict):
            name = item.get("name")
            if isinstance(name, str):
                out.append(name)
        elif isinstance(item, str):
            out.append(item)
    return tuple(out)


def _parse_issue(raw: dict[str, Any]) -> Issue:
    number_raw = raw.get("number")
    if not isinstance(number_raw, int):
        raise DataSourceError(f"issue is missing integer 'number': {raw!r}")
    title = raw.get("title", "")
    if not isinstance(title, str):
        raise DataSourceError(f"issue #{number_raw}: title must be string")
    state = raw.get("state", "")
    if not isinstance(state, str):
        raise DataSourceError(f"issue #{number_raw}: state must be string")
    state_reason_raw = raw.get("stateReason")
    if state_reason_raw is None or state_reason_raw == "":
        state_reason: str | None = None
    elif isinstance(state_reason_raw, str):
        state_reason = state_reason_raw.upper()
    else:
        raise DataSourceError(
            f"issue #{number_raw}: stateReason must be string or null, "
            f"got {type(state_reason_raw).__name__}"
        )
    created_at = _parse_dt(raw.get("createdAt"), field="createdAt", issue_number=number_raw)
    if created_at is None:
        raise DataSourceError(f"issue #{number_raw}: createdAt is required")
    closed_at = _parse_dt(raw.get("closedAt"), field="closedAt", issue_number=number_raw)
    return Issue(
        number=number_raw,
        title=title,
        state=state.lower(),
        state_reason=state_reason,
        created_at=created_at,
        closed_at=closed_at,
        labels=_parse_labels(raw.get("labels")),
    )


def fetch_issues(
    repo: str,
    *,
    limit: int = 1000,
    gh_bin: str = "gh",
    runner: Runner = _default_runner,
    timeout: float = 30.0,
) -> tuple[Issue, ...]:
    """Return all issues for ``repo``. Raises ``DataSourceError`` on any failure."""
    if shutil.which(gh_bin) is None and runner is _default_runner:
        raise DataSourceError(f"gh CLI not found in PATH (looked for {gh_bin!r})")

    cmd = [
        gh_bin,
        "issue",
        "list",
        "--repo",
        repo,
        "--state",
        "all",
        "--limit",
        str(limit),
        "--json",
        _GH_FIELDS_ARG,
    ]
    logger.debug("running: %s", " ".join(cmd))

    try:
        result = runner(cmd, timeout=timeout)
    except FileNotFoundError as exc:
        raise DataSourceError(f"gh CLI not found: {exc}") from exc
    except subprocess.TimeoutExpired as exc:
        raise DataSourceError(f"gh CLI timed out after {timeout}s") from exc

    if result.returncode != 0:
        stderr = (result.stderr or "").strip()
        raise DataSourceError(f"gh exited with code {result.returncode}: {stderr or '<no stderr>'}")

    try:
        payload = json.loads(result.stdout or "[]")
    except json.JSONDecodeError as exc:
        raise DataSourceError(f"gh returned invalid JSON: {exc}") from exc

    if not isinstance(payload, list):
        raise DataSourceError(f"gh returned {type(payload).__name__}, expected list")

    return tuple(_parse_issue(item) for item in payload if isinstance(item, dict))
