"""Download NADAC (National Average Drug Acquisition Cost) weekly files.

Source: data.medicaid.gov, one dataset per calendar year, titled
"NADAC (National Average Drug Acquisition Cost) <year>". CMS republishes the
current-year file every week with a new file name, so the URL is resolved from
the DKAN catalog at run time. Also downloads "First Time NADAC Rates" (new
drugs and first generics), which feeds the generic-entry event study.

Grain of the raw file: one row per NDC per weekly `As of Date` (plus the
`Effective Date` on which that rate started). Prices are per pricing unit
(EA, ML or GM), not per package.

Examples:
    python ingest/nadac.py --years 2026 --limit 50000   # quick sample
    python ingest/nadac.py --years 2024 2025 2026       # full history used in PLAN.md
"""

from __future__ import annotations

import argparse
import datetime as dt

from _common import (RAW_DIR, add_limit_arg, download_csv, log, medicaid_datasets,
                     resolve_medicaid_csv, session, write_manifest)


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--years", nargs="+", type=int, default=[dt.date.today().year])
    p.add_argument("--skip-first-time", action="store_true",
                   help="Do not download the First Time NADAC Rates file.")
    add_limit_arg(p)
    args = p.parse_args()

    sess = session()
    catalog = medicaid_datasets(sess)

    entries = []
    for year in args.years:
        meta = resolve_medicaid_csv(catalog, rf"NADAC \(National Average Drug Acquisition Cost\) {year}")
        log(f"NADAC {year}: dataset {meta['dataset_id']} modified {meta['modified']}")
        e = download_csv(sess, meta["url"], RAW_DIR / "nadac" / f"nadac_{year}.csv", args.limit)
        entries.append({**meta, **e})
    write_manifest("nadac", entries)

    if not args.skip_first_time:
        meta = resolve_medicaid_csv(catalog, r"First Time NADAC Rates")
        e = download_csv(sess, meta["url"], RAW_DIR / "nadac_first_time" / "first_time_nadac.csv", args.limit)
        write_manifest("nadac_first_time", [{**meta, **e}])


if __name__ == "__main__":
    main()
