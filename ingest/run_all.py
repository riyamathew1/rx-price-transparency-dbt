"""Run every downloader. `--sample` keeps 20,000 rows per file (fast, ~15 MB total).

    python ingest/run_all.py --sample      # development
    python ingest/run_all.py               # full: NADAC 2024-2026, SDUD 2024-2025 (several GB)
"""

from __future__ import annotations

import argparse
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent


def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--sample", action="store_true")
    p.add_argument("--rows", type=int, default=20000, help="Rows per file in --sample mode.")
    args = p.parse_args()
    lim = ["--limit", str(args.rows)] if args.sample else []
    steps = [
        ["nadac.py", "--years", "2024", "2025", "2026", *lim],
        ["sdud.py", "--years", "2024", "2025", *lim],
        ["fda_ndc.py", *lim],
        ["cms_mfp.py"],  # about 550 rows: always download in full
    ]
    for step in steps:
        print(f"$ python ingest/{' '.join(step)}", flush=True)
        subprocess.run([sys.executable, str(HERE / step[0]), *step[1:]], check=True)


if __name__ == "__main__":
    main()
