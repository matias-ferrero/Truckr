"""Configure stderr logging with a rich handler. Stdout is reserved for JSON data."""

import logging
import sys

from rich.console import Console
from rich.logging import RichHandler


def configure_logging(verbosity: int) -> None:
    if verbosity < 0:
        level = logging.ERROR
    elif verbosity == 0:
        level = logging.WARNING
    elif verbosity == 1:
        level = logging.INFO
    else:
        level = logging.DEBUG

    handler = RichHandler(
        console=Console(file=sys.stderr, force_terminal=False),
        show_time=False,
        show_path=False,
        markup=False,
        rich_tracebacks=False,
    )
    root = logging.getLogger()
    root.handlers.clear()
    root.addHandler(handler)
    root.setLevel(level)
