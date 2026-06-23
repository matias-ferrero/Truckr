"""Replay the ledger *as of* a past sprint to reconstruct the report it would
have produced back then.

Given the full closed-sprint ledger, an as-of sprint ``N``, the MVP scope and
the development-phase length, this:

1. **truncates** history to sprints ``1..N`` (everything after ``N`` is hindsight),
2. **scopes velocity** to MVP-tagged completions (the numerator must match the
   MVP target denominator),
3. **derives the target** as the MVP still unfinished at the end of ``N``, and
4. **derives the horizon** as ``total_dev_sprints - N``.

The throughput the bootstrap resamples is therefore *MVP User Stories completed
per sprint, in the window that was visible at the end of sprint N* — exactly the
information the team had at the time.
"""

from __future__ import annotations

from team_performance.errors import DataSourceError
from team_performance.models import Reconstruction, Sprint
from team_performance.mvp_scope import normalize_us

LATEST_SENTINEL = 0  # ``--as-of-sprint`` with no value → reconstruct as of the latest sprint


def _mvp_filter(ids: tuple[str, ...], mvp_ids: frozenset[int]) -> tuple[str, ...]:
    return tuple(us for us in ids if normalize_us(us) in mvp_ids)


def resolve_as_of(as_of_sprint: int, latest_closed: int) -> int:
    """Map the latest-sentinel to the real sprint number and bounds-check it."""
    if latest_closed < 1:
        raise DataSourceError("no closed sprints in the ledger — nothing to reconstruct")
    target = latest_closed if as_of_sprint == LATEST_SENTINEL else as_of_sprint
    if target < 1:
        raise DataSourceError(f"--as-of-sprint must be >= 1, got {target}")
    if target > latest_closed:
        raise DataSourceError(
            f"--as-of-sprint {target} exceeds the latest closed sprint ({latest_closed}) — "
            "the ledger has no record to reconstruct from"
        )
    return target


def build_reconstruction(
    sprints: tuple[Sprint, ...],
    *,
    as_of_sprint: int,
    total_dev_sprints: int,
    mvp_ids: frozenset[int],
) -> tuple[tuple[Sprint, ...], Reconstruction]:
    """Return the MVP-scoped, truncated sprint window and its derived context.

    ``sprints`` must be the full, index-contiguous closed-sprint tuple (as
    ``load_sprints`` returns it). ``as_of_sprint`` is already resolved (no
    sentinel).
    """
    window = tuple(s for s in sprints if s.index <= as_of_sprint)

    scoped: list[Sprint] = []
    completed_mvp: set[int] = set()
    for sprint in window:
        all_completed = _mvp_filter(sprint.completed, mvp_ids)
        # Only count a US in the sprint where it was first completed; re-completions
        # (US reopened after approval and approved again) don't add to throughput.
        new_completed = tuple(us for us in all_completed if normalize_us(us) not in completed_mvp)
        completed_mvp.update(normalize_us(us) for us in all_completed)
        scoped.append(
            Sprint(
                index=sprint.index,
                phase=sprint.phase,
                status=sprint.status,
                window_start=sprint.window_start,
                window_end=sprint.window_end,
                completed=new_completed,
                in_progress=_mvp_filter(sprint.in_progress, mvp_ids),
            )
        )

    mvp_total = len(mvp_ids)
    mvp_done = len(completed_mvp)
    target = max(0, mvp_total - mvp_done)
    horizon = total_dev_sprints - as_of_sprint

    reconstruction = Reconstruction(
        as_of_sprint=as_of_sprint,
        history_from=1,
        history_to=as_of_sprint,
        total_dev_sprints=total_dev_sprints,
        mvp_total=mvp_total,
        mvp_completed_through=mvp_done,
        derived_target_user_stories=target,
        derived_remaining_sprints=horizon if horizon > 0 else None,
        already_complete=target == 0,
    )
    return tuple(scoped), reconstruction
