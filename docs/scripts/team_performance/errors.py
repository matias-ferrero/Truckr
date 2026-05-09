"""Typed exception hierarchy for team_performance.

Raised by domain layers and mapped to POSIX exit codes by ``cli.main``.
"""


class TeamPerfError(Exception):
    """Root of every domain-specific failure raised by this package."""


class ConfigError(TeamPerfError):
    """Invalid CLI/env/pyproject configuration. Maps to exit 2."""


class DataSourceError(TeamPerfError):
    """Upstream data source failed (gh missing, repo invalid, parse error). Maps to exit 3."""


class InsufficientDataError(TeamPerfError):
    """Sample too small to produce a projection. Maps to exit 4."""
