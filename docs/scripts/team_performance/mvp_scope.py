"""Resolve the MVP scope — the set of User Stories that define "done".

The backlog (``docs/artifacts/backlog-us.typ``) groups per-US ``#include``
directives under release-banner comments::

    // MVP — Release 1
    #include "backlog-us/US001.typ"
    ...
    // Post MVP — Release 2
    #include "backlog-us/US121.typ"

The ``MVP — Release 1`` section is the **authoritative** MVP scope (the operator
pinned it as the source of truth). Each per-US file *also* carries a
``*Release:* MVP`` line; when the two disagree we trust the section and log a
drift warning, because a mismatch means the backlog is internally inconsistent.

US ids are normalised to plain integers (``US4`` and ``US004`` → ``4``) so the
zero-padded backlog ids match the unpadded ledger ids.
"""

from __future__ import annotations

import logging
import re
from pathlib import Path

from team_performance.errors import DataSourceError

logger = logging.getLogger(__name__)

_INCLUDE = re.compile(r'#include\s+"backlog-us/(US\d+)(?:\.typ)?"')
_RELEASE_BANNER = re.compile(r"^\s*//.*Release\s*(\d+)", re.IGNORECASE)
_US_HEADER = re.compile(r"^==\s*(US\d+)\b", re.MULTILINE)
_RELEASE_TAG = re.compile(r"\*Release:\*\s*([^\\\n]+)")

_MVP_RELEASE = 1


def normalize_us(us: str) -> int:
    """``"US4"`` / ``"US004"`` → ``4``. Raises on a non-``USnn`` token."""
    match = re.fullmatch(r"US(\d+)", us.strip())
    if not match:
        raise DataSourceError(f"not a User Story id: {us!r}")
    return int(match.group(1))


def _section_mvp_ids(text: str) -> set[int]:
    """Normalised ids included under the ``Release 1`` banner."""
    current_release: int | None = None
    ids: set[int] = set()
    for line in text.splitlines():
        banner = _RELEASE_BANNER.match(line)
        if banner:
            current_release = int(banner.group(1))
            continue
        include = _INCLUDE.search(line)
        if include and current_release == _MVP_RELEASE:
            ids.add(normalize_us(include.group(1)))
    return ids


def _tag_mvp_ids(backlog_path: Path) -> set[int] | None:
    """Best-effort: normalised ids whose per-US file declares ``*Release:* MVP``.

    Returns ``None`` when the per-US directory is absent (nothing to cross-check).
    """
    per_us_dir = backlog_path.parent / "backlog-us"
    if not per_us_dir.is_dir():
        return None
    ids: set[int] = set()
    for path in per_us_dir.glob("US*.typ"):
        try:
            body = path.read_text(encoding="utf-8")
        except OSError:
            continue
        header = _US_HEADER.search(body)
        tag = _RELEASE_TAG.search(body)
        if header and tag and tag.group(1).strip().upper() == "MVP":
            ids.add(normalize_us(header.group(1)))
    return ids


def load_mvp_scope(backlog_path: Path) -> frozenset[int]:
    """Return the normalised US-id set of the ``MVP — Release 1`` backlog section.

    Logs a warning if the per-US ``*Release:* MVP`` tags disagree with the
    section (the section wins). Raises ``DataSourceError`` if the section is
    empty or the file is unreadable.
    """
    try:
        text = backlog_path.read_text(encoding="utf-8")
    except OSError as exc:
        raise DataSourceError(f"failed to read backlog {backlog_path}: {exc}") from exc

    section = _section_mvp_ids(text)
    if not section:
        raise DataSourceError(
            f"no '#include' directives found under a 'Release 1' banner in {backlog_path} — "
            "cannot resolve the MVP scope"
        )

    tagged = _tag_mvp_ids(backlog_path)
    if tagged is not None and tagged != section:
        only_section = sorted(section - tagged)
        only_tagged = sorted(tagged - section)
        logger.warning(
            "MVP scope drift: %d US in the 'Release 1' section vs %d tagged '*Release:* MVP'. "
            "Section wins. In section only: %s. Tagged only: %s.",
            len(section),
            len(tagged),
            [f"US{n}" for n in only_section] or "—",
            [f"US{n}" for n in only_tagged] or "—",
        )

    return frozenset(section)
