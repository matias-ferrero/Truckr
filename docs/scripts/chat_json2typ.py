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


def _sanitize_markdown(text: str) -> str:
    """Sanitize markdown that breaks Typst/cmarker rendering.

    - Convert HTML <img ...> tags into plain links.
    - Convert remote markdown images ![alt](https://...) into plain links.
    """

    def repl_html_img(match: re.Match[str]) -> str:
        tag = match.group(0)
        src_match = re.search(r'src\s*=\s*"([^"]+)"', tag, flags=re.IGNORECASE)
        alt_match = re.search(r'alt\s*=\s*"([^"]*)"', tag, flags=re.IGNORECASE)
        src = src_match.group(1).strip() if src_match else ""
        alt = alt_match.group(1).strip() if alt_match else "Imagen"
        if src:
            return f"[{alt}]({src})"
        return alt

    sanitized = re.sub(r"<img\b[^>]*>", repl_html_img, text, flags=re.IGNORECASE)

    sanitized = re.sub(
        r"!\[([^\]]*)\]\((https?://[^)\s]+)\)",
        lambda m: f"[{m.group(1).strip() or 'Imagen'}]({m.group(2).strip()})",
        sanitized,
    )

    return sanitized


def _extract_user_prompt(request: dict) -> str:
    """Return the plain-text user message."""
    return request.get("message", {}).get("text", "").strip()


def _extract_response_text(response: list) -> str:
    """Concatenate visible markdown text from the response items."""
    parts: list[str] = []
    for item in response:
        if not isinstance(item, dict):
            continue
        value = item.get("response")
        if isinstance(value, str) and value.strip():
            parts.append(value)
    return "\n\n".join(parts).strip()


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
        '#import "@preview/cmarker:0.1.8"',
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
        response_items = (
            req.get("result", {}).get("metadata", {}).get("toolCallRounds", [])
        )
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
            prompt = _sanitize_markdown(prompt)
            lines.append("=== Prompt")
            lines.append("")
            lines.append(_wrap_cmarker(prompt))
            lines.append("")

        # Assistant response
        if response:
            response = _sanitize_markdown(response)
            lines.append(f"=== Respuesta ({responder})")
            lines.append("")
            lines.append(_wrap_cmarker(response))
            lines.append("")

    out_path = ARTIFACTS_DIR / f"chat-{stem}.typ"
    os.makedirs(out_path.parent, exist_ok=True)
    out_path.write_text("\n".join(lines), encoding="utf-8")
    return str(out_path)


def _create_main(chat_files: list[str], out_path: Path):
    """Create main.typ from scratch with the given chat session files."""
    lines = [
        '#import "../template.typ": conf',
        "#show: conf",
        "",
        "= Sesiones de Chat con GitHub Copilot",
        "",
    ]
    for i, path in enumerate(chat_files):
        name = Path(path).name
        if i > 0:
            lines.append("#pagebreak()")
            lines.append("")
        lines.append(f'#include "{name}"')
    lines.append("")
    out_path.write_text("\n".join(lines), encoding="utf-8")


def _update_main(chat_files: list[str], out_path: Path):
    """Insert new chat session files into an existing main.typ, sorted by filename."""
    existing = out_path.read_text(encoding="utf-8")
    already_included = set(re.findall(r'#include "([^"]+)"', existing))
    new_names = {Path(p).name for p in chat_files} - already_included
    if not new_names:
        return

    all_names = sorted(already_included | new_names)

    # Preserve the header (everything before the first #include line)
    first_include = re.search(r'^#include "', existing, re.MULTILINE)
    header = (
        existing[: first_include.start()]
        if first_include
        else existing.rstrip("\n") + "\n"
    )

    include_lines: list[str] = []
    for i, name in enumerate(all_names):
        if i > 0:
            include_lines.append("#pagebreak()")
            include_lines.append("")
        include_lines.append(f'#include "{name}"')
    include_lines.append("")

    out_path.write_text(header + "\n".join(include_lines), encoding="utf-8")


def generate_main(chat_files: list[str]):
    """Generate or update main.typ with chat session files."""
    chat_files = sorted(chat_files)
    out_path = ARTIFACTS_DIR / "main.typ"

    if not out_path.exists():
        _create_main(chat_files, out_path)
    else:
        _update_main(chat_files, out_path)

    print(f"  -> {out_path}")


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <file.json> [file2.json ...]", file=sys.stderr)
        sys.exit(1)

    outputs = []
    for path in sys.argv[1:]:
        out = convert(path)
        outputs.append(out)
        print(f"  {path} -> {out}")

    generate_main(outputs)


if __name__ == "__main__":
    main()
