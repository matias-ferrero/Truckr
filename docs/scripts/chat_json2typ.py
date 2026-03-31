"""Convert VS Code Copilot chat session exports (-chat.json) to Typst (.typ) files.

Usage:
    python docs/scripts/chat_json2typ.py docs/raw/*-chat.json

Each JSON file produces a .typ file next to it (in docs/raw/) containing only
the user prompts and assistant responses — internal thinking, tool invocations,
and other metadata are stripped out.
"""

import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

ARTIFACTS_DIR = Path("docs/prompts")

# Response item kinds that are NOT visible text content
_SKIP_KINDS = {
    "thinking",
    "toolInvocationSerialized",
    "textEditGroup",
    "codeblockUri",
    "mcpServersStarting",
    "undoStop",
    "inlineReference",
}


def _typst_raw_block(text: str) -> str:
    """Wrap text in a Typst raw text block with a safe backtick fence."""
    fence = "```"
    while fence in text:
        fence += "`"
    return f"{fence}\n{text}\n{fence}"


def _wrap_cmarker(text: str) -> str:
    """Wrap markdown text in a cmarker.render() call."""
    raw = _typst_raw_block(text)
    return f"#cmarker.render({raw}, h1-level: 4)"


def _extract_user_prompt(request: dict) -> str:
    """Return the plain-text user message."""
    return request.get("message", {}).get("text", "").strip()


def _extract_response_text(response: list) -> str:
    """Concatenate visible markdown text from the response items."""
    parts: list[str] = []
    for item in response:
        if not isinstance(item, dict):
            continue
        kind = item.get("kind")
        if kind in _SKIP_KINDS:
            continue
        # Items without 'kind' (or with an unknown kind) that carry a 'value'
        # string are the assistant's markdown prose.
        value = item.get("value")
        if isinstance(value, str) and value.strip():
            parts.append(value)
    return "".join(parts).strip()


def _format_timestamp(ts_ms: int | None) -> str:
    if ts_ms is None:
        return ""
    dt = datetime.fromtimestamp(ts_ms / 1000, tz=timezone.utc)
    return dt.strftime("%Y-%m-%d %H:%M UTC")


def convert(json_path: str) -> str:
    """Convert a single chat JSON file and return the output path."""
    with open(json_path, encoding="utf-8") as f:
        data = json.load(f)

    requests = data.get("requests", [])
    responder = data.get("responderUsername", "Assistant")

    lines: list[str] = [
        '#import "../template.typ": conf',
        '#import "@preview/cmarker:0.1.8"',
        "#show: conf",
        "",
    ]

    # Derive a title from the filename (date portion)
    stem = Path(json_path).stem.removesuffix("-chat")
    m = re.match(r"(\d{4})_(\d{2})_(\d{2})-(\d{2})_(\d{2})_(\d{2})", stem)
    if m:
        title = f"Sesión de chat — {m[3]}/{m[2]}/{m[1]} {m[4]}:{m[5]}"
    else:
        title = f"Sesión de chat — {stem}"

    lines.append(f"= {title}")
    lines.append("")

    for i, req in enumerate(requests):
        prompt = _extract_user_prompt(req)
        response_items = req.get("response", [])
        if not isinstance(response_items, list):
            response_items = []
        response = _extract_response_text(response_items)

        if not prompt and not response:
            continue

        ts = _format_timestamp(req.get("timestamp"))
        model = req.get("modelId", "")

        # Turn header
        header_parts = [f"== Intercambio {i + 1}"]
        lines.append(header_parts[0])
        if ts or model:
            meta = " — ".join(filter(None, [ts, model]))
            lines.append(f"_{meta}_")
        lines.append("")

        # User prompt
        if prompt:
            lines.append("=== Prompt")
            lines.append("")
            lines.append(_wrap_cmarker(prompt))
            lines.append("")

        # Assistant response
        if response:
            lines.append(f"=== Respuesta ({responder})")
            lines.append("")
            lines.append(_wrap_cmarker(response))
            lines.append("")

    out_path = ARTIFACTS_DIR / f"chat-{stem}.typ"
    os.makedirs(out_path.parent, exist_ok=True)
    out_path.write_text("\n".join(lines), encoding="utf-8")
    return str(out_path)


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <file.json> [file2.json ...]", file=sys.stderr)
        sys.exit(1)

    for path in sys.argv[1:]:
        out = convert(path)
        print(f"  {path} -> {out}")


if __name__ == "__main__":
    main()
