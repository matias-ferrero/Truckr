import os
import sys
import textwrap

import pandas as pd

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
        '#import "template.typ": conf',
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
        '#import "template.typ": conf',
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
        '#import "template.typ": conf',
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
        '#import "template.typ": conf',
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

    # The USM has a hierarchical grid structure:
    # Row 0: Role header (e.g. "ROL: Productor")
    # Row 1: Top-level activity groups (epic-level, span multiple columns)
    # Row 2: Activity sub-groups
    # Row 3: User tasks headers per column
    # Rows 4+: Individual user stories/tasks

    # Extract role
    role = ""
    for c in range(df.shape[1]):
        val = _clean(df.iloc[0, c])
        if val.startswith("ROL:"):
            role = val.replace("ROL:", "").strip()
            break

    # Row 1: top-level activities (epics)
    # Row 2: sub-activities
    # Row 3: task group labels per column
    # Rows 3+: tasks

    # Build column groups by scanning rows 1-2 for non-empty cells
    # Each non-empty cell in row 1 starts a new epic that spans until the next non-empty cell
    epics = []  # (name, start_col, end_col)
    activities = []  # (name, start_col, end_col)

    # Scan row 1 for epic-level headers
    for c in range(df.shape[1]):
        val = _clean(df.iloc[1, c])
        if val:
            epics.append({"name": val, "start": c})
    # Set end columns
    for i, ep in enumerate(epics):
        if i + 1 < len(epics):
            ep["end"] = epics[i + 1]["start"] - 1
        else:
            ep["end"] = df.shape[1] - 1

    # Scan row 2 for activity-level headers
    for c in range(df.shape[1]):
        val = _clean(df.iloc[2, c])
        if val:
            activities.append({"name": val, "start": c})
    for i, act in enumerate(activities):
        if i + 1 < len(activities):
            act["end"] = activities[i + 1]["start"] - 1
        else:
            act["end"] = df.shape[1] - 1

    # Scan row 3 for task-group labels (one per column)
    task_groups = {}  # col -> label
    for c in range(df.shape[1]):
        val = _clean(df.iloc[3, c])
        if val:
            task_groups[c] = val

    # Detect MVP release boundary
    mvp_row = None
    for r in range(4, df.shape[0]):
        for c in range(df.shape[1]):
            val = _clean(df.iloc[r, c])
            if val.lower().startswith("release"):
                mvp_row = r
                break
        if mvp_row is not None:
            break

    # Collect tasks per column, split by MVP boundary
    tasks_mvp = {}  # col -> list of tasks (above MVP line)
    tasks_post = {}  # col -> list of tasks (below MVP line)
    for c in range(df.shape[1]):
        tasks_mvp[c] = []
        tasks_post[c] = []
        for r in range(4, df.shape[0]):
            if r == mvp_row:
                continue
            val = _clean(df.iloc[r, c])
            if val:
                if mvp_row is not None and r > mvp_row:
                    tasks_post[c].append(val)
                else:
                    tasks_mvp[c].append(val)

    lines = [
        '#import "template.typ": conf',
        "#show: conf",
        "",
        f"= User Story Map — {role}",
        "",
    ]

    for ep in epics:
        lines.append(f"== {ep['name']}")
        lines.append("")
        # Find activities under this epic
        for act in activities:
            if act["start"] >= ep["start"] and act["start"] <= ep["end"]:
                lines.append(f"=== {act['name']}")
                lines.append("")
                # Find task groups under this activity
                for c in range(act["start"], act["end"] + 1):
                    label = task_groups.get(c, "")
                    mvp_items = tasks_mvp.get(c, [])
                    post_items = tasks_post.get(c, [])
                    if not label and not mvp_items and not post_items:
                        continue
                    if label:
                        lines.append(f"==== {label}")
                        lines.append("")
                    if mvp_items:
                        lines.append("*MVP:*")
                        for t in mvp_items:
                            lines.append(f"- {t}")
                        lines.append("")
                    if post_items:
                        lines.append("*Post-MVP:*")
                        for t in post_items:
                            lines.append(f"- {t}")
                        lines.append("")

    _write(output_name, "\n".join(lines))


def gen_usm_productor():
    _gen_usm("USM (Productor)", "usm-productor.typ")


def gen_usm_transportista():
    _gen_usm("USM (Transportista)", "usm-transportista.typ")


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
        '#import "template.typ": conf',
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
        "usm-productor": gen_usm_productor,
        "usm-transportista": gen_usm_transportista,
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
