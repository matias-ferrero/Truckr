"""Typed exception hierarchy for team_performance.

Raised by domain layers and mapped to POSIX exit codes by ``cli.main``.
"""


class TeamPerfError(Exception):
    """Root of every domain-specific failure raised by this package."""


class ConfigError(TeamPerfError):
    """Invalid CLI/env configuration. Maps to exit 2."""


class DataSourceError(TeamPerfError):
    """Sprint ledger could not be read or failed validation. Maps to exit 3."""


class InsufficientDataError(TeamPerfError):
    """Sample too small to produce a projection. Maps to exit 4."""
