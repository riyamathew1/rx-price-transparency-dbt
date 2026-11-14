"""Download Medicaid State Drug Utilization Data (SDUD).

Source: data.medicaid.gov, one dataset per year, titled
"State Drug Utilization Data <year>". CMS restates older years (every year was
re-published in July 2026), so file names change and are resolved at run time.

Grain of the raw file: utilization type (FFSU / MCOU) x state (plus "XX" for
the national total) x NDC x year x quarter. Amounts are what Medicaid paid
pharmacies BEFORE manufacturer rebates, including dispensing fees. Rows with
fewer than 11 prescriptions are suppressed (`Suppression Used` = true, amounts blank).

A full year is about 5.3M rows (about 0.5 GB; 2024 was 5,308,407 rows / 504 MB on Nov 14, 2026). Use --limit while developing.

Examples:
    python ingest/sdud.py --years 2024 --limit 50000
    python ingest/sdud.py --years 2024 2025
"""

from __future__ import annotations

import argparse

from _common import (RAW_DIR, add_limit_arg, download_csv, log, medicaid_datasets,
                     resolve_medicaid_csv, session, write_manifest)


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--years", nargs="+", type=int, default=[2024])
    add_limit_arg(p)
    args = p.parse_args()

    sess = session()
    catalog = medicaid_datasets(sess)
    entries = []
    for year in args.years:
        meta = resolve_medicaid_csv(catalog, rf"State Drug Utilization Data {year}")
        log(f"SDUD {year}: dataset {meta['dataset_id']} modified {meta['modified']}")
        e = download_csv(sess, meta["url"], RAW_DIR / "sdud" / f"sdud_{year}.csv", args.limit)
        entries.append({**meta, **e})
    write_manifest("sdud", entries)


if __name__ == "__main__":
    main()
