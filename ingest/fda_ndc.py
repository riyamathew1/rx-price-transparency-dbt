"""Download the FDA National Drug Code (NDC) Directory.

Source: https://www.fda.gov/drugs/drug-approvals-and-databases/national-drug-code-directory
File:   https://www.accessdata.fda.gov/cder/ndctext.zip (product.txt + package.txt,
tab-delimited, refreshed daily).

NDCs here are 10 digits WITH hyphens in one of three layouts (4-4-2, 5-3-2,
5-4-1). NADAC and SDUD use 11 digits without hyphens (5-4-2). Normalizing
between the two is a core exercise in PLAN.md (week 1).

Examples:
    python ingest/fda_ndc.py --limit 20000
    python ingest/fda_ndc.py
"""

from __future__ import annotations

import argparse
import hashlib
import io
import zipfile

from _common import RAW_DIR, REPO_ROOT, add_limit_arg, download_file, log, session, write_manifest

URL = "https://www.accessdata.fda.gov/cder/ndctext.zip"


def to_utf8(raw: bytes) -> bytes:
    """FDA files are mostly UTF-8 with a few Windows-1252 bytes (for example 0xBF).
    Re-encode each line as UTF-8 so DuckDB and Snowflake can read the file."""
    try:
        raw.decode("utf-8")
        return raw
    except UnicodeDecodeError:
        return raw.decode("cp1252", errors="replace").encode("utf-8")


MEMBERS = {"product.txt": "fda_ndc_product.txt", "package.txt": "fda_ndc_package.txt"}


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    add_limit_arg(p)
    args = p.parse_args()

    out_dir = RAW_DIR / "fda_ndc"
    zpath = out_dir / "ndctext.zip"
    z_entry = download_file(session(), URL, zpath)
    log(f"FDA NDC zip: {z_entry['bytes']:,} bytes")

    entries = []
    with zipfile.ZipFile(zpath) as zf:
        for member, target in MEMBERS.items():
            dest = out_dir / target
            sha = hashlib.sha256()
            rows = -1
            with zf.open(member) as src, dest.open("wb") as fh:
                for line in io.BufferedReader(src):
                    line = to_utf8(line.rstrip(b"\r\n")) + b"\n"
                    if line == b"\n":
                        continue
                    fh.write(line)
                    sha.update(line)
                    rows += 1
                    if args.limit is not None and rows >= args.limit:
                        break
            entries.append({"url": f"{URL}#{member}", "file": str(dest.relative_to(REPO_ROOT)),
                            "rows": rows, "bytes": dest.stat().st_size, "sha256": sha.hexdigest(),
                            "sampled": args.limit is not None})
    zpath.unlink()  # keep only the extracted text files
    write_manifest("fda_ndc", entries, {"zip_bytes": z_entry["bytes"], "zip_sha256": z_entry["sha256"]})


if __name__ == "__main__":
    main()
