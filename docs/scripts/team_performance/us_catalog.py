"""Parse the catalogue of valid User Story ids from the backlog artifact.

The backlog lives in ``docs/artifacts/backlog-us.typ`` as Typst headings of
the form ``== US7: Ofertar Retiro de una Carga``. The set of ids parsed here
is used to validate the sprint ledger — a typo like ``US41`` that does not
exist in the backlog is rejected instead of silently inflating throughput.
"""

from __future__ import annotations

import re
from pathlib import Path

from team_performance.errors import DataSourceError

_US_HEADER = re.compile(r"^==\s*(US\d+)\s*:", re.MULTILINE)


def load_us_catalog(path: Path) -> frozenset[str]:
    """Return the set of US ids declared in the backlog artifact at ``path``."""
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as exc:
        raise DataSourceError(f"failed to read US catalogue {path}: {exc}") from exc
    ids = frozenset(match.group(1) for match in _US_HEADER.finditer(text))
    if not ids:
        raise DataSourceError(f"no '== USnn:' headings found in {path}")
    return ids
