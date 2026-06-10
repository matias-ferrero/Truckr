"""
Compiles wbs.typ to a high-quality PNG and auto-trims bottom whitespace.
Usage: uv run --with pillow docs/scripts/wbs_typ2png.py
Output: docs/artifacts/wbs.png
"""

import subprocess
from pathlib import Path

from PIL import Image, ImageChops

REPO_ROOT = Path(__file__).resolve().parents[2]
WBS_TYP = REPO_ROOT / "docs/artifacts/wbs.typ"
OUT = REPO_ROOT / "docs/artifacts/wbs.png"
DOCS_ROOT = REPO_ROOT / "docs"

PPI = 300          # render at 2× for supersampling, then downscale to OUTPUT_PPI
OUTPUT_PPI = 150
TRIM_PADDING = 60  # pixels at render PPI (~5mm at 300 PPI)


def compile_png() -> None:
    subprocess.run(
        [
            "typst", "compile",
            "--root", str(DOCS_ROOT),
            "--format", "png",
            "--ppi", str(PPI),
            str(WBS_TYP),
            str(OUT),
        ],
        check=True,
    )


def trim_whitespace() -> None:
    import numpy as np

    img = Image.open(OUT).convert("RGB")
    arr = np.array(img)

    # rows that contain at least one non-white pixel
    content_rows = np.where(~np.all(arr == 255, axis=(1, 2)))[0]
    if len(content_rows) == 0:
        return

    # Find the largest vertical blank gap between content rows.
    # If it exceeds 5 % of the image height the Typst page footer is below
    # it — crop above the gap so the blank + footer are excluded.
    gaps = np.diff(content_rows)
    max_gap_idx = int(np.argmax(gaps))
    if gaps[max_gap_idx] > img.height * 0.05:
        bottom = int(content_rows[max_gap_idx]) + TRIM_PADDING
    else:
        bottom = int(content_rows[-1]) + TRIM_PADDING

    top = max(0, int(content_rows[0]) - TRIM_PADDING)
    bottom = min(img.height, bottom)

    cropped = img.crop((0, top, img.width, bottom))

    # Downscale to OUTPUT_PPI using Lanczos for sharper anti-aliased text
    scale = OUTPUT_PPI / PPI
    out_w = round(cropped.width  * scale)
    out_h = round(cropped.height * scale)
    final = cropped.resize((out_w, out_h), Image.LANCZOS)
    final.save(OUT, optimize=True)
    print(f"Trimmed & downscaled: {img.size} → {final.size}")


if __name__ == "__main__":
    compile_png()
    trim_whitespace()
    print(f"Saved → {OUT}")
