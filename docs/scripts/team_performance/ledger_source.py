"""Read the per-sprint User Story ledger (``docs/progress-reports/sprint-NN.md``).

Each sprint is one Markdown file with a YAML-ish frontmatter block followed by
a free-form retro body (the body is ignored). The frontmatter is intentionally
restricted to scalar values and inline lists so it can be parsed without a
YAML dependency::

    ---
    sprint: 1
    phase: development
    status: closed
    window: 2026-05-07 -> 2026-05-13
    in_progress_user_stories: [US7]
    completed_user_stories: [US1, US2, US14]
    ---

Only files with ``status: closed`` and a matching ``--phase`` feed the
throughput sample. Every failure raises ``DataSourceError`` (CLI exit 3).
"""

from __future__ import annotations

import logging
import re
from datetime import date
from pathlib import Path

from team_performance.errors import DataSourceError
from team_performance.models import Sprint

logger = logging.getLogger(__name__)

_US_ID = re.compile(r"^US\d+$")
_WINDOW_SEPARATORS = ("→", "->")  # "→" or ASCII arrow
_REQUIRED_KEYS = ("sprint", "phase", "status", "window", "completed_user_stories")
_VALID_STATUSES = frozenset({"closed", "in_progress"})


def _split_frontmatter(text: str, *, name: str) -> str:
    """Return the text between the opening and closing ``---`` fences."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        raise DataSourceError(f"{name}: file must start with a '---' frontmatter fence")
    for idx in range(1, len(lines)):
        if lines[idx].strip() == "---":
            return "\n".join(lines[1:idx])
    raise DataSourceError(f"{name}: unterminated frontmatter (missing closing '---')")


def _parse_frontmatter(block: str, *, name: str) -> dict[str, object]:
    """Parse ``key: value`` lines. Values wrapped in ``[...]`` become lists."""
    out: dict[str, object] = {}
    for raw in block.splitlines():
        if not raw.strip():
            continue
        if ":" not in raw:
            raise DataSourceError(f"{name}: malformed frontmatter line: {raw!r}")
        key, _, value = raw.partition(":")
        key = key.strip()
        value = value.strip()
        if value.startswith("[") and value.endswith("]"):
            inner = value[1:-1].strip()
            out[key] = [item.strip() for item in inner.split(",") if item.strip()]
        else:
            out[key] = value
    return out


def _require(fm: dict[str, object], key: str, *, name: str) -> object:
    if key not in fm:
        raise DataSourceError(f"{name}: missing required frontmatter key {key!r}")
    return fm[key]


def _as_int(value: object, key: str, *, name: str) -> int:
    if isinstance(value, bool) or not isinstance(value, str) or not value.strip():
        raise DataSourceError(f"{name}: {key} must be an integer, got {value!r}")
    try:
        return int(value)
    except ValueError as exc:
        raise DataSourceError(f"{name}: {key} must be an integer, got {value!r}") from exc


def _as_str(value: object, key: str, *, name: str) -> str:
    if not isinstance(value, str):
        raise DataSourceError(f"{name}: {key} must be a string, got {value!r}")
    return value


def _as_us_list(value: object, key: str, *, name: str) -> tuple[str, ...]:
    if not isinstance(value, list):
        raise DataSourceError(f"{name}: {key} must be an inline list like [US1, US2]")
    ids: list[str] = []
    for item in value:
        if not isinstance(item, str) or not _US_ID.match(item):
            raise DataSourceError(f"{name}: {key} contains an invalid US id: {item!r}")
        ids.append(item)
    return tuple(ids)


def _parse_window(value: str, *, name: str) -> tuple[date, date]:
    for sep in _WINDOW_SEPARATORS:
        if sep in value:
            start_raw, _, end_raw = value.partition(sep)
            try:
                return date.fromisoformat(start_raw.strip()), date.fromisoformat(end_raw.strip())
            except ValueError as exc:
                raise DataSourceError(f"{name}: invalid window dates in {value!r}: {exc}") from exc
    raise DataSourceError(f"{name}: window must be 'YYYY-MM-DD -> YYYY-MM-DD', got {value!r}")


def _build_sprint(fm: dict[str, object], *, name: str) -> Sprint:
    for key in _REQUIRED_KEYS:
        _require(fm, key, name=name)

    index = _as_int(fm["sprint"], "sprint", name=name)
    if index < 1:
        raise DataSourceError(f"{name}: sprint must be >= 1, got {index}")

    phase = _as_str(fm["phase"], "phase", name=name).strip()
    if not phase:
        raise DataSourceError(f"{name}: phase must not be empty")

    status = _as_str(fm["status"], "status", name=name).strip()
    if status not in _VALID_STATUSES:
        raise DataSourceError(
            f"{name}: status must be one of {sorted(_VALID_STATUSES)}, got {status!r}"
        )

    window_start, window_end = _parse_window(_as_str(fm["window"], "window", name=name), name=name)
    if window_end < window_start:
        raise DataSourceError(f"{name}: window end is before window start")

    completed = _as_us_list(fm["completed_user_stories"], "completed_user_stories", name=name)
    in_progress = _as_us_list(
        fm.get("in_progress_user_stories", []), "in_progress_user_stories", name=name
    )

    overlap = set(completed) & set(in_progress)
    if overlap:
        raise DataSourceError(
            f"{name}: {sorted(overlap)} appear in both completed and in_progress "
            "(in_progress is carry-over WIP only)"
        )

    return Sprint(
        index=index,
        phase=phase,
        status=status,
        window_start=window_start,
        window_end=window_end,
        completed=completed,
        in_progress=in_progress,
    )


def _validate_run(sprints: list[Sprint], *, us_catalog: frozenset[str] | None) -> None:
    """Cross-file validation over the closed sprints selected for one run."""
    indices = [s.index for s in sprints]
    if indices != list(range(1, len(sprints) + 1)):
        raise DataSourceError(
            f"closed sprint indices must be contiguous from 1, got {indices} — "
            "a gap usually means a sprint file is missing or still in_progress"
        )

    completed_at: dict[str, int] = {}
    for sprint in sprints:
        for us in sprint.completed:
            if us in completed_at:
                raise DataSourceError(
                    f"{us} is completed in both sprint {completed_at[us]} and sprint "
                    f"{sprint.index} — a US can only be completed once"
                )
            completed_at[us] = sprint.index

    for sprint in sprints:
        for us in sprint.in_progress:
            done = completed_at.get(us)
            if done is not None and done < sprint.index:
                raise DataSourceError(
                    f"{us} is in_progress in sprint {sprint.index} but was already "
                    f"completed in sprint {done}"
                )
            if done is None and sprint.index < len(sprints):
                logger.warning(
                    "%s is in_progress in sprint %d but never completed in the ledger",
                    us,
                    sprint.index,
                )

    if us_catalog is not None:
        for sprint in sprints:
            for us in (*sprint.completed, *sprint.in_progress):
                if us not in us_catalog:
                    raise DataSourceError(
                        f"sprint {sprint.index}: {us} is not declared in the US backlog"
                    )


def load_sprints(
    sprints_dir: Path,
    *,
    phase: str,
    us_catalog: frozenset[str] | None = None,
) -> tuple[Sprint, ...]:
    """Load, filter (phase + status=closed) and validate the sprint ledger."""
    if not sprints_dir.is_dir():
        raise DataSourceError(f"sprints directory not found: {sprints_dir}")

    parsed: list[Sprint] = []
    for path in sorted(sprints_dir.glob("sprint-*.md")):
        try:
            text = path.read_text(encoding="utf-8")
        except OSError as exc:
            raise DataSourceError(f"failed to read {path}: {exc}") from exc
        fm = _parse_frontmatter(_split_frontmatter(text, name=path.name), name=path.name)
        parsed.append(_build_sprint(fm, name=path.name))

    selected = sorted(
        (s for s in parsed if s.phase == phase and s.status == "closed"),
        key=lambda s: s.index,
    )
    _validate_run(selected, us_catalog=us_catalog)
    return tuple(selected)
