import os
import sys
import textwrap

import pandas as pd
from openpyxl import load_workbook

XLSX_PATH = "docs/raw/Lean Artifacts.xlsx"
ARTIFACTS_DIR = "docs/artifacts"


def cmd_list_sheets():
    """List all sheet names in the workbook."""
    xl = pd.ExcelFile(XLSX_PATH)
    for i, name in enumerate(xl.sheet_names):
        print(f"{i}: {name}")


def cmd_dump_sheet(sheet):
    """Dump a sheet's contents for inspection."""
    df = pd.read_excel(XLSX_PATH, sheet_name=sheet, header=None)
    pd.set_option("display.max_columns", None)
    pd.set_option("display.max_rows", None)
    pd.set_option("display.width", 200)
    pd.set_option("display.max_colwidth", 80)
    print(df.to_string())


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _clean(val) -> str:
    """Return a cleaned string from a cell value, or empty string for NaN."""
    if pd.isna(val):
        return ""
    return str(val).strip()


def _write(path: str, content: str):
    os.makedirs(ARTIFACTS_DIR, exist_ok=True)
    full = os.path.join(ARTIFACTS_DIR, path)
    with open(full, "w", encoding="utf-8") as f:
        f.write(content)
    print(f"  -> {full}")


# ---------------------------------------------------------------------------
# Product Vision
# ---------------------------------------------------------------------------


def gen_product_vision():
    df = pd.read_excel(XLSX_PATH, sheet_name="Product Vision", header=None)
    rows = []
    for _, row in df.iterrows():
        key = _clean(row[0])
        val = _clean(row[1])
        if key and val:
            rows.append((key, val))
        elif key:
            rows.append((key, ""))

    lines = [
        '#import "../template.typ": conf',
        "#show: conf",
        "",
        "= Product Vision",
        "",
        "#table(",
        "  columns: (auto, 1fr),",
        "  align: (right, left),",
        "  stroke: 0.5pt,",
    ]
    for key, val in rows:
        # Escape Typst special chars in values
        val_escaped = val.replace('"', '\\"')
        key_escaped = key.replace('"', '\\"')
        lines.append(f"  [*{key_escaped}*], [{val_escaped}],")
    lines.append(")")
    lines.append("")

    _write("product-vision.typ", "\n".join(lines))


# ---------------------------------------------------------------------------
# Personas
# ---------------------------------------------------------------------------


def gen_personas():
    df = pd.read_excel(XLSX_PATH, sheet_name="Personas", header=None)

    # The Personas sheet has a grid layout:
    # Columns 0-1 are left persona, columns 3-4 are right persona
    # Every 7 rows is a new persona pair (with header rows)
    personas = []
    num_rows = len(df)
    block_size = 7  # rows per persona-pair block

    for block_start in range(0, num_rows, block_size):
        for col_name, col_profile in [(0, 1), (3, 4)]:
            if block_start + 4 >= num_rows:
                continue
            name = _clean(df.iloc[block_start + 2, col_name])
            profile = (
                _clean(df.iloc[block_start + 1, col_profile])
                if block_start + 1 < num_rows
                else ""
            )
            # Sometimes profile is in the col next to name's col
            if not profile:
                profile = _clean(df.iloc[block_start + 1, col_name])
            behavior = _clean(df.iloc[block_start + 4, col_name])
            needs = (
                _clean(df.iloc[block_start + 4, col_profile])
                if block_start + 4 < num_rows
                else ""
            )
            if not needs:
                needs = (
                    _clean(df.iloc[block_start + 4, col_name + 1])
                    if col_name + 1 < df.shape[1]
                    else ""
                )

            if not name:
                continue
            personas.append(
                {
                    "name": name,
                    "profile": profile,
                    "behavior": behavior,
                    "needs": needs,
                }
            )

    lines = [
        '#import "../template.typ": conf',
        "#show: conf",
        "",
        "= Personas",
        "",
    ]
    for p in personas:
        lines.append(f"== {p['name']}")
        lines.append("")
        if p["profile"]:
            lines.append(f"*Profile:* {p['profile']}")
            lines.append("")
        if p["behavior"]:
            lines.append(f"*Behavior:* {p['behavior']}")
            lines.append("")
        if p["needs"]:
            lines.append(f"*Needs:* {p['needs']}")
            lines.append("")

    _write("personas.typ", "\n".join(lines))


# ---------------------------------------------------------------------------
# Es - No Es - Hace - No Hace
# ---------------------------------------------------------------------------


def gen_es_no_es():
    df = pd.read_excel(XLSX_PATH, sheet_name="Es - No Es - Hace - No Hace", header=None)
    # Row 0: title, Row 1: blank, Row 2: "Es" / "No Es", Row 3: content,
    # Row 4: "Hace" / "No Hace", Row 5: content
    es = _clean(df.iloc[2, 0])
    no_es = _clean(df.iloc[2, 1])
    hace = _clean(df.iloc[4, 0])
    no_hace = _clean(df.iloc[4, 1])

    def _format_bullets(text: str) -> str:
        """Convert \\n-separated bullet lines into Typst list items."""
        items = []
        for line in text.split("\n"):
            line = line.strip().lstrip("-").strip()
            if line:
                items.append(f"- {line}")
        return "\n".join(items)

    lines = [
        '#import "../template.typ": conf',
        "#show: conf",
        "",
        "= Es / No Es / Hace / No Hace",
        "",
        "#table(",
        "  columns: (1fr, 1fr),",
        "  stroke: 0.5pt,",
        "  align: left,",
        "  [*Es*], [*No Es*],",
        f"  [{_format_bullets(es)}], [{_format_bullets(no_es)}],",
        "  [*Hace*], [*No Hace*],",
        f"  [{_format_bullets(hace)}], [{_format_bullets(no_hace)}],",
        ")",
        "",
    ]
    _write("es-no-es-hace-no-hace.typ", "\n".join(lines))


# ---------------------------------------------------------------------------
# Features
# ---------------------------------------------------------------------------


def gen_features():
    df = pd.read_excel(XLSX_PATH, sheet_name="Features", header=None)

    # Row 0: headers  — col 0 is "Features\n---\nPersonas", cols 1..N are feature names
    # Rows 1..M-1: persona rows — col 0 is persona name, cols 1..N are scores
    # Last row: averages
    header_cell = _clean(df.iloc[0, 0])  # noqa: F841
    observation = _clean(df.iloc[0, df.shape[1] - 1])  # last col has observation
    feature_names = [_clean(df.iloc[0, c]) for c in range(1, df.shape[1] - 1)]
    # Filter out empty feature names
    feature_names = [f for f in feature_names if f]
    num_features = len(feature_names)

    persona_rows = []
    avg_row = None
    for r in range(1, df.shape[0]):
        name = _clean(df.iloc[r, 0])
        scores = []
        for c in range(1, 1 + num_features):
            val = df.iloc[r, c]
            if pd.isna(val):
                scores.append("")
            else:
                scores.append(str(val))
        if not name:
            # Row with no name but with scores is the averages row
            if any(s for s in scores):
                avg_row = scores
            continue
        persona_rows.append((name, scores))

    lines = [
        '#import "../template.typ": conf',
        "#show: conf",
        "",
        "= Features Matrix",
        "",
    ]
    if observation:
        lines.append(f"_{observation}_")
        lines.append("")

    # Build table
    ncols = num_features + 1
    col_spec = ", ".join(["auto"] * ncols)
    lines.append(f"#table(")
    lines.append(f"  columns: ({col_spec}),")
    lines.append(f"  stroke: 0.5pt,")
    lines.append(f"  align: center,")
    # Header row
    header_cells = "[*Persona*]"
    for fn in feature_names:
        header_cells += f", [*{fn}*]"
    lines.append(f"  {header_cells},")
    # Data rows
    for name, scores in persona_rows:
        cells = f"[{name}]"
        for s in scores:
            cells += f", [{s}]"
        lines.append(f"  {cells},")
    # Averages row
    if avg_row:
        cells = "[*Average*]"
        for s in avg_row:
            cells += f", [*{s}*]"
        lines.append(f"  {cells},")
    lines.append(")")
    lines.append("")

    _write("features.typ", "\n".join(lines))


# ---------------------------------------------------------------------------
# USM (User Story Map)
# ---------------------------------------------------------------------------


def _gen_usm(sheet_name: str, output_name: str):
    df = pd.read_excel(XLSX_PATH, sheet_name=sheet_name, header=None)

    # Load workbook to read colors
    wb = load_workbook(XLSX_PATH)
    ws = wb[sheet_name]

    # The USM has a table structure:
    # Column 0: Release markers (Release MVP, 2do Release, etc) - IGNORE
    # Row 0: Épicos (starting from col 1)
    # Row 1: Actividades (one per column)
    # Row 2+: Tasks per column, with MVP/Post-MVP boundaries marked by "Release" rows

    # Map column -> color from tasks row (row 3 in Excel, row 2 in pandas) - the lighter tones
    col_colors = {}  # col -> hex color (e.g., "FCE5CD" without FF prefix)
    for c in range(1, df.shape[1]):
        cell = ws.cell(3, c + 1)  # row 3 (first tasks), column c+1 (because pandas is 0-indexed)
        if cell.fill and cell.fill.start_color:
            color = cell.fill.start_color.rgb
            if color and color != "00000000":
                # Remove FF prefix and convert to rgb
                col_colors[c] = color[2:] if len(color) > 2 else color

    # Get epic row color
    epic_color = None
    cell = ws.cell(1, 2)  # row 1, column 2 for first epic
    if cell.fill and cell.fill.start_color:
        color = cell.fill.start_color.rgb
        if color and color != "00000000":
            epic_color = color[2:] if len(color) > 2 else color

    # Get activity row colors (for the headers)
    activity_colors = {}  # col -> hex color
    for c in range(1, df.shape[1]):
        cell = ws.cell(2, c + 1)  # row 2 (activities), column c+1
        if cell.fill and cell.fill.start_color:
            color = cell.fill.start_color.rgb
            if color and color != "00000000":
                activity_colors[c] = color[2:] if len(color) > 2 else color

    # Get release marker color
    release_color = None
    for r in range(7, df.shape[0] + 1):
        cell = ws.cell(r, 1)
        if cell.value and "release" in str(cell.value).lower():
            if cell.fill and cell.fill.start_color:
                color = cell.fill.start_color.rgb
                if color and color != "00000000":
                    release_color = color[2:] if len(color) > 2 else color
            break

    # Scan row 0 for épicos (starting from column 1, skip column 0)
    epics = []  # (name, start_col, end_col)
    for c in range(1, df.shape[1]):
        val = _clean(df.iloc[0, c])
        if val:
            # Check if this epic is already in the list (same name)
            if not epics or epics[-1]["name"] != val:
                epics.append({"name": val, "start": c})
    # Set end columns
    for i, ep in enumerate(epics):
        if i + 1 < len(epics):
            ep["end"] = epics[i + 1]["start"] - 1
        else:
            ep["end"] = df.shape[1] - 1

    # Scan row 1 for actividades (one per column, starting from column 1)
    actividades = {}  # col -> name
    for c in range(1, df.shape[1]):
        val = _clean(df.iloc[1, c])
        if val:
            actividades[c] = val

    # Detect MVP/Post-MVP boundaries (from column 0)
    # Look for rows that start with "Release" and extract the release number
    release_rows = []
    release_numbers = []
    for r in range(2, df.shape[0]):
        val = _clean(df.iloc[r, 0]).lower()
        if val.startswith("release"):
            release_rows.append(r)
            # Extract release number (e.g., "Release 1" -> 1)
            parts = _clean(df.iloc[r, 0]).split()
            if len(parts) > 1:
                try:
                    release_num = int(parts[-1])
                    release_numbers.append(release_num)
                except ValueError:
                    release_numbers.append(len(release_numbers) + 1)

    # Group tasks by release: everything between row 2 and first release,
    # then between releases, then after last release
    tasks_by_release = {}  # release_index -> {col -> [tasks]}

    for release_idx, release_row in enumerate(release_rows):
        tasks_by_release[release_idx] = {}
        for c in range(1, df.shape[1]):
            tasks_by_release[release_idx][c] = []

        # Get task rows for this release
        task_start = 2 if release_idx == 0 else (release_rows[release_idx - 1] + 1)
        task_end = release_row

        for r in range(task_start, task_end):
            for c in range(1, df.shape[1]):
                val = _clean(df.iloc[r, c])
                if val and "release" not in val.lower():
                    tasks_by_release[release_idx][c].append(val)

    # Handle post-release tasks (after last release marker)
    if release_rows:
        last_release_idx = len(release_rows) - 1

        for r in range(release_rows[-1] + 1, df.shape[0]):
            for c in range(1, df.shape[1]):
                val = _clean(df.iloc[r, c])
                if val and "release" not in val.lower():
                    tasks_by_release[last_release_idx][c].append(val)

    # Count columns (excluding column 0)
    num_cols = df.shape[1] - 1

    lines = [
        '#import "../template.typ": c-activ, c-epic, c-mvp, c-mvp-lane, c-post, c-post-lane, c-task, conf',
        "#show: conf",
        "",
        "#set page(flipped: true, margin: (x: 0.8cm, y: 1.2cm))",
        "",
        "= User Story Map",
        "",
        f"#set text(size: 7.5pt)",
        "",
        "#table(",
        f"  columns: (1fr,) * {num_cols},",
        "  inset: (x: 6pt, y: 5pt),",
        "",
        "  // ── Row 1: Backbone — Epics ─────────────────────────────────────────────",
    ]

    # Generate epics row with colspan and colors
    for ep in epics:
        col_span = ep["end"] - ep["start"] + 1
        color_hex = epic_color if epic_color else "9FC5E8"
        lines.append(f"  table.cell(colspan: {col_span}, fill: rgb(\"#{color_hex}\"), align: center)[")
        lines.append(f"    #text(fill: black, weight: \"bold\")[{ep['name']}]")
        lines.append("  ],")

    # Generate actividades row with column colors
    for c in range(1, df.shape[1]):
        name = actividades.get(c, "")
        color_hex = activity_colors.get(c, "F9CB9C")  # Default color if not found
        if name:
            lines.append(f"  table.cell(fill: rgb(\"#{color_hex}\"), align: center)[")
            lines.append(f"    #text(fill: black, weight: \"bold\")[{name}]")
            lines.append("  ],")
        else:
            lines.append(f"  table.cell(fill: rgb(\"#{color_hex}\"))[],")

    lines.append("")

    # Generate rows for each release
    # Release 1 is MVP, others are Post-MVP
    for idx, release_idx in enumerate(sorted(tasks_by_release.keys())):
        release_num = release_numbers[idx] if idx < len(release_numbers) else idx + 1
        is_mvp = release_num == 1
        release_marker_color = release_color if release_color else "6AA84F"

        if is_mvp:
            release_label = f"MVP — Release {release_num}"
        else:
            release_label = f"Post MVP — Release {release_num}"

        # Generate rows for this release (tasks first)
        lines.append(f"  // ── {release_label} Stories ──────────────────────────────────────────────────────────")
        for c in range(1, df.shape[1]):
            tasks = tasks_by_release[release_idx].get(c, [])
            color_hex = col_colors.get(c, "FCE5CD")
            if tasks:
                items = "\n    - ".join(tasks)
                lines.append(f"  table.cell(fill: rgb(\"#{color_hex}\"))[")
                lines.append(f"    - {items}")
                lines.append("  ],")
            else:
                lines.append(f"  table.cell(fill: rgb(\"#{color_hex}\"))[],")

        # Add release marker row after tasks
        lines.append("")
        lines.append(f"  // ── {release_label} Marker ────────────────────────────────────────────────────────")
        lines.append(f"  table.cell(colspan: {num_cols}, fill: rgb(\"#{release_marker_color}\"), align: center)[")
        lines.append(f"    #text(fill: black, weight: \"bold\")[{release_label}]")
        lines.append("  ],")

    lines.append(")")

    _write(output_name, "\n".join(lines))


def gen_usm():
    _gen_usm("USM", "usm.typ")


# ---------------------------------------------------------------------------
# Backlog-US
# ---------------------------------------------------------------------------


def gen_backlog_us():
    df = pd.read_excel(XLSX_PATH, sheet_name="Backlog-US", header=None)

    # Structure: groups of 4 rows per user story:
    # Row 0: "Nro:\n" | "Título: <title>" | "Prioridad: <p>" | "Estimación:"
    # Row 1: "Descripción:\n..." | NaN | NaN | NaN
    # Row 2: "Criterios de Aceptación:\n..." | NaN | NaN | NaN
    # Row 3: NaN (separator)

    stories = []
    r = 0
    while r < len(df):
        cell0 = _clean(df.iloc[r, 0])

        # Look for row starting with "Nro:"
        if cell0.startswith("Nro:"):
            title_raw = _clean(df.iloc[r, 1]) if df.shape[1] > 1 else ""
            priority_raw = _clean(df.iloc[r, 2]) if df.shape[1] > 2 else ""
            estimation_raw = _clean(df.iloc[r, 3]) if df.shape[1] > 3 else ""

            title = title_raw.replace("Título:", "").strip()
            priority = priority_raw.replace("Prioridad:", "").strip()
            estimation = estimation_raw.replace("Estimación:", "").strip()

            # Skip empty template rows
            if not title:
                r += 1
                continue

            # Next row: description
            desc = ""
            if r + 1 < len(df):
                desc_raw = _clean(df.iloc[r + 1, 0])
                desc = desc_raw.replace("Descripción:", "").strip()

            # Next row: acceptance criteria
            criteria = ""
            if r + 2 < len(df):
                crit_raw = _clean(df.iloc[r + 2, 0])
                criteria = crit_raw.replace("Criterios de Aceptación:", "").strip()

            stories.append(
                {
                    "title": title,
                    "priority": priority,
                    "estimation": estimation,
                    "description": desc,
                    "criteria": criteria,
                }
            )
            r += 4
        else:
            r += 1

    lines = [
        '#import "../template.typ": conf',
        "#show: conf",
        "",
        "= Backlog — User Stories",
        "",
    ]
    for i, s in enumerate(stories, 1):
        lines.append(f"== US{i}: {s['title']}")
        lines.append("")
        if s["priority"]:
            lines.append(f"*Priority:* {s['priority']}")
            lines.append("")
        if s["estimation"]:
            lines.append(f"*Estimation:* {s['estimation']}")
            lines.append("")
        if s["description"]:
            lines.append(f"*Description:*")
            # Parse "Como X quiero Y para Z" format
            lines.append(f"{s['description']}")
            lines.append("")
        if s["criteria"]:
            lines.append(f"*Acceptance Criteria:*")
            for crit_line in s["criteria"].split("\n"):
                crit_line = crit_line.strip()
                if not crit_line:
                    continue
                # Detect sub-items (starting with - after stripping number prefix)
                stripped = crit_line.lstrip("0123456789.").strip()
                if stripped.startswith("- "):
                    lines.append(f"  {stripped}")
                else:
                    lines.append(f"- {stripped}")
            lines.append("")

    _write("backlog-us.typ", "\n".join(lines))


# ---------------------------------------------------------------------------
# Generate all
# ---------------------------------------------------------------------------


def cmd_generate(which: str = "all"):
    generators = {
        "product-vision": gen_product_vision,
        "personas": gen_personas,
        "es-no-es": gen_es_no_es,
        "features": gen_features,
        "usm": gen_usm,
        "backlog-us": gen_backlog_us,
    }
    if which == "all":
        for name, fn in generators.items():
            print(f"Generating {name}...")
            fn()
    elif which in generators:
        print(f"Generating {which}...")
        generators[which]()
    else:
        print(f"Unknown artifact: {which}")
        print(f"Available: {', '.join(generators.keys())}")
        sys.exit(1)


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: artifact_xlsx2typ.py <command> [args]")
        print("Commands:")
        print("  list-sheets              List all sheets in the workbook")
        print("  dump-sheet <name|index>   Dump a sheet's raw content")
        print("  generate [artifact|all]   Generate .typ files")
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "list-sheets":
        cmd_list_sheets()
    elif cmd == "dump-sheet":
        sheet = sys.argv[2]
        try:
            sheet = int(sheet)
        except ValueError:
            pass
        cmd_dump_sheet(sheet)
    elif cmd == "generate":
        which = sys.argv[2] if len(sys.argv) > 2 else "all"
        cmd_generate(which)
    else:
        print(f"Unknown command: {cmd}")
        sys.exit(1)
