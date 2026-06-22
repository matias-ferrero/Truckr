"""Convert Claude Code session transcripts (.jsonl) to Typst (.typ) files.

Usage:
    python docs/scripts/claude_jsonl2typ.py docs/prompts/raw/claude/**/*.jsonl
    python docs/scripts/claude_jsonl2typ.py --no-redact <files...>   # skip PII scrub

Claude Code stores each session as a JSON-Lines transcript: one JSON object per
line, with many line `type`s (user, assistant, system, attachment, ai-title,
file-history-snapshot, ...). This script keeps only the *conversation* — the
human prompts and the assistant's visible text — and strips everything else:
internal `thinking` blocks, `tool_use` / `tool_result` rounds, injected
`<system-reminder>` context, meta lines (`isMeta`), and sub-agent sidechain
lines (`isSidechain`, which are captured in their own `subagents/*.jsonl`).

Each `<id>.jsonl` produces `<id>.typ` next to it. A `main.typ` aggregator is
written at the root of the scanned tree, grouping sessions by their origin
sub-directory (main checkout vs. each git worktree) and ordering them by date.

Extracted text is run through a best-effort PII scrub (emails, secrets/tokens,
URL credentials, home-directory usernames, public IPs, international phones)
plus a course-rebrand normalisation (c9y -> gdsi) before rendering — see
`_redact_pii`. Pass `--no-redact` to disable it.

This mirrors `chat_json2typ.py` (the Copilot exporter) — same cmarker raw-block
wrapping and markdown sanitisation — but speaks the Claude transcript schema.
"""

import json
import re
import sys
from collections import Counter, defaultdict
from datetime import datetime
from pathlib import Path

# Root of the gitignored raw transcript tree; the aggregator main.typ lands here.
CLAUDE_ROOT = Path("docs/prompts/raw/claude")


# ── Typst / markdown helpers (shared idioms with chat_json2typ.py) ────────────


def _typst_raw_block(text: str) -> str:
    """Wrap text in a Typst raw text block with a backtick fence that can't clash."""
    fence = "```"
    while fence in text:
        fence += "`"
    return f"{fence}\n{text}\n{fence}"


# cmarker derives Typst labels from markdown headings ("github" anchors). When
# many sessions are aggregated into one document, identical heading slugs collide.
# A process-wide unique prefix per render call keeps every label distinct.
_LABEL_SEQ = 0


def _wrap_cmarker(text: str) -> str:
    """Render markdown text through cmarker, demoting its headings under ours."""
    global _LABEL_SEQ
    _LABEL_SEQ += 1
    prefix = f"cc{_LABEL_SEQ}-"
    return (
        f"#cmarker.render({_typst_raw_block(text)}, "
        f'h1-level: 4, label-prefix: "{prefix}")'
    )


def _sanitize_markdown(text: str) -> str:
    """Strip markdown constructs that break Typst/cmarker (remote/HTML images)."""

    def repl_html_img(match: re.Match[str]) -> str:
        tag = match.group(0)
        src_match = re.search(r'src\s*=\s*"([^"]+)"', tag, flags=re.IGNORECASE)
        alt_match = re.search(r'alt\s*=\s*"([^"]*)"', tag, flags=re.IGNORECASE)
        src = src_match.group(1).strip() if src_match else ""
        alt = alt_match.group(1).strip() if alt_match else "Imagen"
        return f"[{alt}]({src})" if src else alt

    sanitized = re.sub(r"<img\b[^>]*>", repl_html_img, text, flags=re.IGNORECASE)
    sanitized = re.sub(
        r"!\[([^\]]*)\]\((https?://[^)\s]+)\)",
        lambda m: f"[{m.group(1).strip() or 'Imagen'}]({m.group(2).strip()})",
        sanitized,
    )
    return sanitized


# ── PII redaction ─────────────────────────────────────────────────────────────
#
# Best-effort, high-precision scrubbing of personal/secret data before it lands
# in committable-adjacent docs. Tuned to favour *precision* (few false positives)
# over recall — it is a safety net for an academic corpus, not a DLP guarantee.
# Disable with `--no-redact`.

REDACT_PII = True
_REDACTION_COUNTS: Counter = Counter()

# High-confidence secret/token shapes.
_PEM_KEY = re.compile(r"-----BEGIN [^-\n]+-----.*?-----END [^-\n]+-----", re.DOTALL)
_TOKEN_PATTERNS = [
    re.compile(r"\bAKIA[0-9A-Z]{16}\b"),  # AWS access key id
    re.compile(r"\bgh[pousr]_[A-Za-z0-9]{20,}\b"),  # GitHub PAT / OAuth
    re.compile(r"\bglpat-[A-Za-z0-9_-]{20,}\b"),  # GitLab PAT
    re.compile(r"\bsk-ant-[A-Za-z0-9_-]{20,}\b"),  # Anthropic
    re.compile(r"\bsk-[A-Za-z0-9]{20,}\b"),  # OpenAI-style
    re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{10,}\b"),  # Slack
    re.compile(  # JWT (header.payload.signature)
        r"\beyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\b"
    ),
]
# `key = value` style secrets: only when the value looks secret (quoted, or a
# long unbroken token) so we don't shred ordinary prose like "password: required".
_KV_SECRET = re.compile(
    r"(?i)((?:api[_-]?key|secret|client[_-]?secret|access[_-]?key|auth[_-]?token"
    r"|token|password|passwd|pwd)\b\s*[:=]\s*)"
    r"""(?:"[^"\n]{6,}"|'[^'\n]{6,}'|[A-Za-z0-9_\-./+=]{16,})"""
)
_URL_CREDS = re.compile(r"\b([a-z][a-z0-9+.-]*://)[^/\s:@]+:[^/\s:@]+@")
_EMAIL = re.compile(r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b")
# Home directories leak the OS username; keep the path shape, drop the name.
_HOME_NIX = re.compile(r"(/home/|/Users/)([^/\s\"']+)")
_HOME_WIN = re.compile(r"([A-Za-z]:\\Users\\)([^\\\s\"']+)")
_IPV4 = re.compile(
    r"\b(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}(?:25[0-5]|2[0-4]\d|1?\d?\d)\b"
)
_IP_PRIVATE = re.compile(
    r"^(?:127\.|10\.|192\.168\.|169\.254\.|172\.(?:1[6-9]|2\d|3[01])\.|0\.0\.0\.0$)"
)
# International phone numbers (require a leading + to stay precise).
_PHONE = re.compile(
    r"(?<![\w+])\+\d{1,3}[\s.\-]?\(?\d{2,4}\)?(?:[\s.\-]?\d{2,4}){2,4}(?!\w)"
)
# Course rebrand: the SDLC tooling was renamed c9y-sdlc -> gdsi-sdlc. Normalise
# every mention so the corpus matches the current ".gdsi-sdlc" naming.
_C9Y = re.compile(r"c9y", re.IGNORECASE)


def _c9y_repl(match: re.Match[str]) -> str:
    """Replace c9y -> gdsi, preserving the matched casing."""
    src = match.group(0)
    if src.isupper():
        return "GDSI"
    if src[0].isupper():
        return "Gdsi"
    return "gdsi"


def _ip_repl(match: re.Match[str]) -> str:
    ip = match.group(0)
    if _IP_PRIVATE.match(ip):  # loopback / RFC1918 / link-local are not PII
        return ip
    _REDACTION_COUNTS["ip"] += 1
    return "[REDACTED_IP]"


def _redact_pii(text: str) -> str:
    """Scrub emails, secrets, credentials, home usernames, public IPs, phones."""
    if not REDACT_PII or not text:
        return text

    def count(pattern, repl, s, key):
        s, n = pattern.subn(repl, s)
        _REDACTION_COUNTS[key] += n
        return s

    text = count(_PEM_KEY, "[REDACTED_PRIVATE_KEY]", text, "private_key")
    for pat in _TOKEN_PATTERNS:
        text = count(pat, "[REDACTED_SECRET]", text, "secret")
    text = count(_KV_SECRET, lambda m: f"{m.group(1)}[REDACTED_SECRET]", text, "secret")
    text = count(
        _URL_CREDS, lambda m: f"{m.group(1)}[REDACTED_CREDENTIALS]@", text, "credentials"
    )
    text = count(_EMAIL, "[REDACTED_EMAIL]", text, "email")
    text = count(_HOME_NIX, r"\1[user]", text, "home_path")
    text = count(_HOME_WIN, r"\1[user]", text, "home_path")
    text = _IPV4.sub(_ip_repl, text)  # counts only non-private hits
    text = count(_PHONE, "[REDACTED_PHONE]", text, "phone")
    text = count(_C9Y, _c9y_repl, text, "c9y_rebrand")
    return text


# ── Transcript parsing ───────────────────────────────────────────────────────

# Wrapper tags Claude Code injects around slash-command stdout and harness
# context. We drop the noise but keep the slash command itself as a marker.
_DROP_BLOCKS = re.compile(
    r"<(system-reminder|local-command-stdout|local-command-caveat|command-message"
    r"|command-stdout)>.*?</\1>",
    flags=re.DOTALL,
)
_CMD_NAME = re.compile(r"<command-name>(.*?)</command-name>", flags=re.DOTALL)
_CMD_ARGS = re.compile(r"<command-args>(.*?)</command-args>", flags=re.DOTALL)
_ANY_TAG = re.compile(r"</?(command-[a-z]+|local-command-[a-z]+)>")


def _clean_user_text(text: str) -> str:
    """Reduce a raw user message to the human-authored part.

    Slash-command invocations become a `**Comando:** `/name args`` marker; the
    surrounding harness stdout/caveat/reminder wrappers are discarded.
    """
    cmd = _CMD_NAME.search(text)
    marker = ""
    if cmd:
        name = cmd.group(1).strip()
        args_m = _CMD_ARGS.search(text)
        args = (args_m.group(1).strip() if args_m else "").strip()
        slash = name if name.startswith("/") else f"/{name}"
        marker = f"**Comando:** `{slash}{(' ' + args) if args else ''}`"

    text = _DROP_BLOCKS.sub("", text)
    text = _CMD_NAME.sub("", text)
    text = _CMD_ARGS.sub("", text)
    text = _ANY_TAG.sub("", text)
    text = text.strip()

    if marker and text:
        return f"{marker}\n\n{text}"
    return marker or text


def _blocks_text(content, kinds: set[str]) -> str:
    """Join the text of message-content blocks whose type is in `kinds`."""
    if isinstance(content, str):
        return content if "text" in kinds else ""
    if not isinstance(content, list):
        return ""
    parts = []
    for block in content:
        if isinstance(block, dict) and block.get("type") in kinds:
            value = block.get("text", "")
            if isinstance(value, str) and value.strip():
                parts.append(value)
    return "\n\n".join(parts)


def parse_transcript(path: Path) -> dict:
    """Parse one .jsonl transcript into session metadata + ordered exchanges."""
    meta: dict = {
        "session_id": "",
        "title": "",
        "ai_title": "",
        "custom_title": "",
        "branch": "",
        "version": "",
        "model": "",
        "first_ts": None,
    }
    # Ordered list of ("user"|"assistant", text) conversation events.
    events: list[tuple[str, str]] = []

    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
            except json.JSONDecodeError:
                continue

            t = obj.get("type")
            if t == "ai-title":
                meta["ai_title"] = obj.get("aiTitle", "") or meta["ai_title"]
                continue
            if t == "custom-title":
                meta["custom_title"] = obj.get("customTitle", "") or meta["custom_title"]
                continue
            if t not in ("user", "assistant"):
                continue

            # Capture session-level metadata from the first conversational lines.
            meta["session_id"] = meta["session_id"] or obj.get("sessionId", "")
            meta["branch"] = meta["branch"] or obj.get("gitBranch", "")
            meta["version"] = meta["version"] or obj.get("version", "")
            if meta["first_ts"] is None and obj.get("timestamp"):
                meta["first_ts"] = obj["timestamp"]

            # Drop injected meta lines and sub-agent sidechains (kept separately).
            if obj.get("isMeta") or obj.get("isSidechain"):
                continue

            msg = obj.get("message")
            if not isinstance(msg, dict):
                continue
            content = msg.get("content")

            if t == "user":
                raw = _blocks_text(content, {"text"})
                cleaned = _clean_user_text(raw) if raw else ""
                if cleaned:
                    events.append(("user", cleaned))
            else:  # assistant
                model = msg.get("model")
                if model and model != "<synthetic>" and not meta["model"]:
                    meta["model"] = model
                text = _blocks_text(content, {"text"})
                if text.strip():
                    events.append(("assistant", text.strip()))

    meta["title"] = meta["custom_title"] or meta["ai_title"]
    meta["events"] = events
    return meta


def _format_ts(ts: str | None) -> str:
    if not ts:
        return ""
    try:
        dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
        return dt.strftime("%Y-%m-%d %H:%M UTC")
    except (ValueError, AttributeError):
        return ""


def _date_label(ts: str | None) -> str:
    if not ts:
        return "fecha desconocida"
    try:
        dt = datetime.fromisoformat(ts.replace("Z", "+00:00"))
        return dt.strftime("%d/%m/%Y %H:%M")
    except (ValueError, AttributeError):
        return "fecha desconocida"


# ── Rendering ────────────────────────────────────────────────────────────────


def render_session(meta: dict) -> str:
    """Render a parsed transcript to a standalone (includable) .typ document."""
    lines = ['#import "@preview/cmarker:0.1.8"', ""]

    title = (
        _redact_pii(meta["title"])
        or f"Sesión Claude Code — {_date_label(meta['first_ts'])}"
    )
    lines.append(f"= {title}")
    lines.append("")

    sub = " — ".join(
        filter(
            None,
            [
                _format_ts(meta["first_ts"]),
                f"rama `{meta['branch']}`" if meta["branch"] else "",
                meta["model"],
            ],
        )
    )
    if sub:
        lines.append(f"_{sub}_")
        lines.append("")

    if not meta["events"]:
        lines.append("_(Sesión sin contenido conversacional.)_")
        lines.append("")
        return "\n".join(lines)

    exchange = 0
    pending_user = False
    for role, text in meta["events"]:
        text = _sanitize_markdown(_redact_pii(text))
        if role == "user":
            exchange += 1
            lines.append(f"== Intercambio {exchange}")
            lines.append("")
            lines.append("=== Prompt")
            lines.append("")
            lines.append(_wrap_cmarker(text))
            lines.append("")
            pending_user = True
        else:  # assistant
            if not pending_user and exchange == 0:
                exchange += 1
                lines.append(f"== Intercambio {exchange}")
                lines.append("")
            lines.append("=== Respuesta (Claude)")
            lines.append("")
            lines.append(_wrap_cmarker(text))
            lines.append("")
            pending_user = False

    return "\n".join(lines)


def render_main(by_origin: dict[str, list[dict]], root: Path) -> str:
    """Build the aggregator main.typ that includes every session .typ."""
    depth = len(root.parts)  # docs/prompts/raw/claude -> 4 -> ../../../../? no
    # root is relative to repo; template.typ lives at docs/template.typ.
    # Compute relative path from root back up to docs/.
    rel_to_docs = "/".join([".."] * (depth - 1))  # parts: docs,prompts,raw,claude
    template = f"{rel_to_docs}/template.typ"

    lines = [
        f'#import "{template}": conf',
        "#show: conf",
        "",
        "= Sesiones de Claude Code",
        "",
        "Transcripciones de las sesiones de Claude Code del proyecto, agrupadas por",
        "origen (checkout principal y cada _git worktree_). Sólo se conservan los",
        "_prompts_ humanos y las respuestas visibles del asistente.",
        "",
    ]

    first = True
    for origin in sorted(by_origin):
        sessions = sorted(by_origin[origin], key=lambda m: m["first_ts"] or "")
        pretty = "Checkout principal" if origin == "main" else origin
        lines.append("#pagebreak()")
        lines.append("")
        lines.append(f"= Origen: {pretty}")
        lines.append("")
        for meta in sessions:
            rel = meta["typ_path"].relative_to(root).as_posix()
            if not first:
                lines.append("#pagebreak()")
                lines.append("")
            lines.append(f'#include "{rel}"')
            first = False
        lines.append("")

    return "\n".join(lines)


def main():
    global REDACT_PII
    if "--no-redact" in sys.argv[1:]:
        REDACT_PII = False
    paths = [Path(p) for p in sys.argv[1:] if p.endswith(".jsonl")]
    if not paths:
        print(
            f"Usage: {sys.argv[0]} [--no-redact] <transcript.jsonl> [more.jsonl ...]",
            file=sys.stderr,
        )
        sys.exit(1)

    by_origin: dict[str, list[dict]] = defaultdict(list)
    written = 0
    for path in sorted(paths):
        meta = parse_transcript(path)
        out_path = path.with_suffix(".typ")
        out_path.write_text(render_session(meta), encoding="utf-8")
        written += 1

        # Origin label = first path segment under CLAUDE_ROOT (main / worktree-*).
        try:
            rel = path.relative_to(CLAUDE_ROOT)
            origin = rel.parts[0] if len(rel.parts) > 1 else "main"
        except ValueError:
            origin = "main"
        meta["typ_path"] = out_path
        by_origin[origin].append(meta)

    main_path = CLAUDE_ROOT / "main.typ"
    main_path.write_text(render_main(by_origin, CLAUDE_ROOT), encoding="utf-8")

    total = sum(len(v) for v in by_origin.values())
    print(f"  converted {written} transcript(s) across {len(by_origin)} origin(s)")
    print(f"  -> aggregator: {main_path} ({total} sessions)")
    if not REDACT_PII:
        print("  PII redaction: DISABLED (--no-redact)")
    elif _REDACTION_COUNTS:
        summary = ", ".join(f"{k}={v}" for k, v in sorted(_REDACTION_COUNTS.items()))
        print(f"  PII redacted: {summary}")
    else:
        print("  PII redacted: none matched")


if __name__ == "__main__":
    main()
