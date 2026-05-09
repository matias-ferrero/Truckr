"""Sprint-window assignment.

Each sprint window is ``[start, end)`` (inclusive start, exclusive end). An
issue is "closed in sprint N" iff ``closed_at`` falls in N's window. "Created
in sprint N" iff ``created_at`` falls in N's window. ``wip_at_end`` is the
count of issues that were created on or before the window end and are still
open at that moment.

Throughput rule: a closed issue counts toward sprint throughput **only when**
``state_reason`` is ``COMPLETED`` (or absent, for backward compatibility with
issue trackers that do not expose the field). ``NOT_PLANNED`` and ``DUPLICATE``
closures are tracked separately as ``closed_excluded`` so the operator can
audit them but do not pollute the velocity sample.
"""

from __future__ import annotations

from datetime import UTC, date, datetime, timedelta

from team_performance.models import Issue, Sprint

DELIVERED_REASONS: frozenset[str] = frozenset({"COMPLETED"})


def _to_utc(d: date) -> datetime:
    return datetime(d.year, d.month, d.day, tzinfo=UTC)


def _counts_as_delivered(issue: Issue) -> bool:
    """An issue counts as throughput iff it was actually delivered.

    ``state_reason is None`` is treated as delivered to stay backward-compatible
    with fixtures and trackers that do not populate the field.
    """
    return issue.state_reason is None or issue.state_reason in DELIVERED_REASONS


def sprint_windows(
    sprint_start: date, sprint_length_days: int, as_of: date
) -> list[tuple[int, datetime, datetime]]:
    """Return only fully-elapsed sprint windows up to (and excluding) ``as_of``.

    A sprint counts as complete when its ``end`` is on or before ``as_of``
    (the conventional "closed sprint" convention for retros).
    """
    if sprint_length_days <= 0:
        raise ValueError("sprint_length_days must be positive")
    cursor = _to_utc(sprint_start)
    as_of_dt = _to_utc(as_of)
    windows: list[tuple[int, datetime, datetime]] = []
    index = 1
    while True:
        end = cursor + timedelta(days=sprint_length_days)
        if end > as_of_dt:
            break
        windows.append((index, cursor, end))
        cursor = end
        index += 1
    return windows


def _wip_at(moment: datetime, issues: tuple[Issue, ...]) -> int:
    return sum(
        1
        for i in issues
        if i.created_at <= moment and (i.closed_at is None or i.closed_at > moment)
    )


def assign_to_sprints(
    issues: tuple[Issue, ...], sprint_start: date, sprint_length_days: int, as_of: date
) -> tuple[Sprint, ...]:
    windows = sprint_windows(sprint_start, sprint_length_days, as_of)
    sprints: list[Sprint] = []
    for index, start, end in windows:
        in_window = tuple(
            i for i in issues if i.closed_at is not None and start <= i.closed_at < end
        )
        closed = tuple(i for i in in_window if _counts_as_delivered(i))
        closed_excluded = tuple(i for i in in_window if not _counts_as_delivered(i))
        created = tuple(i for i in issues if start <= i.created_at < end)
        sprints.append(
            Sprint(
                index=index,
                start=start,
                end=end,
                closed=closed,
                closed_excluded=closed_excluded,
                created=created,
                wip_at_end=_wip_at(end, issues),
            )
        )
    return tuple(sprints)
