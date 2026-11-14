"""Load landed files into the `raw` schema of a local DuckDB database.

This is the DuckDB twin of snowflake/load_raw.sql (PUT + COPY INTO): every
column lands as text, plus `_source_file` and `_loaded_at`, and dbt staging
models do all the typing. Keeping RAW untyped on both engines means the same
staging SQL runs on DuckDB and Snowflake.

    python ingest/load_duckdb.py                       # data/raw -> rx.duckdb
    python ingest/load_duckdb.py --fixtures --db ci.duckdb   # tests/fixtures -> ci.duckdb (CI)

The database path defaults to $DUCKDB_PATH, then rx.duckdb (same as profiles.yml).
"""

from __future__ import annotations

import argparse
import os
import re
import sys
from pathlib import Path

import duckdb

REPO_ROOT = Path(__file__).resolve().parents[1]

# raw table -> (glob relative to the data root, delimiter)
TABLES = {
    "nadac_weekly": ("nadac/*.csv", ","),
    "nadac_first_time_rates": ("nadac_first_time/*.csv", ","),
    "sdud_quarterly": ("sdud/*.csv", ","),
    "fda_ndc_product": ("fda_ndc/fda_ndc_product*.txt", "\t"),
    "fda_ndc_package": ("fda_ndc/fda_ndc_package*.txt", "\t"),
    "cms_mfp": ("cms_mfp/*.csv", ","),
}


def snake(name: str) -> str:
    return re.sub(r"_+", "_", re.sub(r"[^0-9a-z]+", "_", name.strip().lower())).strip("_")


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--fixtures", action="store_true", help="Load tests/fixtures instead of data/raw.")
    p.add_argument("--db", default=os.environ.get("DUCKDB_PATH", "rx.duckdb"))
    p.add_argument("--only", nargs="*", help="Subset of raw tables to load.")
    args = p.parse_args()

    root = REPO_ROOT / ("tests/fixtures" if args.fixtures else "data/raw")
    con = duckdb.connect(args.db)
    con.execute("create schema if not exists raw")
    loaded = 0
    for table, (pattern, delim) in TABLES.items():
        if args.only and table not in args.only:
            continue
        files = sorted(root.glob(pattern))
        if not files:
            print(f"skip   raw.{table:<24} no files match {root.name}/{pattern}", file=sys.stderr)
            continue
        file_list = "[" + ", ".join("'" + str(f).replace("'", "''") + "'" for f in files) + "]"
        quote = "'\"'" if delim == "," else "''"
        reader = (
            f"read_csv({file_list}, header=true, all_varchar=true, delim='{delim}', "
            f"quote={quote}, union_by_name=true, filename=true, encoding='utf-8')"
        )
        cols = [r[0] for r in con.execute(f"describe select * from {reader}").fetchall()]
        select = ", ".join(f'"{c}" as {snake(c)}' for c in cols if c != "filename")
        con.execute(
            f"create or replace table raw.{table} as "
            f"select {select}, regexp_extract(filename, '[^/]+$') as _source_file, "
            f"current_timestamp as _loaded_at from {reader}"
        )
        n = con.execute(f"select count(*) from raw.{table}").fetchone()[0]
        print(f"loaded raw.{table:<24} {n:>10,} rows from {len(files)} file(s)", file=sys.stderr)
        loaded += 1
    con.close()
    if loaded == 0:
        raise SystemExit(f"Nothing loaded from {root}. Run the ingest scripts first.")


if __name__ == "__main__":
    main()
