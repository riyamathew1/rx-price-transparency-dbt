"""Download CMS Medicare Drug Price Negotiation: selected drugs and negotiated prices.

Source page (Selected Drugs and Negotiated Prices):
  https://www.cms.gov/initiatives/medicare-prescription-drug-affordability/overview/medicare-drug-price-negotiation-program/selected-drugs-negotiated-prices
The page links a ZIP called "Selected Drug List and Negotiated Prices, also known
as Maximum Fair Prices in Statute" (CSV + XLSX). Its file name carries a date
(for example ...-data-file-20261102.zip), so the link is scraped from the page.

The file covers every price applicability year (IPAY). IPAY 2026 is the first
10 drugs whose negotiated prices (Maximum Fair Prices, MFP) took effect on
Jan 1, 2026: Eliquis, Jardiance, Xarelto, Januvia, Farxiga, Entresto, Enbrel,
Imbruvica, Stelara and Fiasp/NovoLog. Grain: one row per IPAY x NDC-11 x MFP
effective period (prices are inflation-adjusted each Jan 1, so expect several
rows per NDC: that is a small SCD2 in its own right).

Examples:
    python ingest/cms_mfp.py
    python ingest/cms_mfp.py --limit 50
"""

from __future__ import annotations

import argparse
import re
import zipfile
from urllib.parse import urljoin

from _common import RAW_DIR, REPO_ROOT, add_limit_arg, download_file, log, session, write_manifest

PAGE = ("https://www.cms.gov/initiatives/medicare-prescription-drug-affordability/overview/"
        "medicare-drug-price-negotiation-program/selected-drugs-negotiated-prices")
LINK_RE = re.compile(r'href="([^"]*maximum-fair-price-data-file[^"]*\.zip)"', re.IGNORECASE)


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    add_limit_arg(p)
    args = p.parse_args()

    sess = session()
    html = sess.get(PAGE, timeout=120)
    html.raise_for_status()
    links = sorted(set(LINK_RE.findall(html.text)))
    if not links:
        raise SystemExit(f"Could not find the MFP data-file ZIP link on {PAGE}")
    url = urljoin(PAGE, links[-1])
    log(f"CMS MFP zip: {url}")

    out_dir = RAW_DIR / "cms_mfp"
    zpath = out_dir / "mfp.zip"
    z_entry = download_file(sess, url, zpath)
    with zipfile.ZipFile(zpath) as zf:
        csvs = [n for n in zf.namelist() if n.lower().endswith(".csv")]
        if len(csvs) != 1:
            raise SystemExit(f"Expected one CSV in {url}, found {csvs}")
        # utf-8-sig strips a byte-order mark if CMS adds one.
        text = zf.read(csvs[0]).decode("utf-8-sig", errors="replace")
    lines = [ln for ln in text.splitlines() if ln.strip()]
    if args.limit is not None:
        lines = lines[: args.limit + 1]
    dest = out_dir / "cms_mfp.csv"
    dest.write_text("\n".join(lines) + "\n", encoding="utf-8")
    zpath.unlink()
    write_manifest("cms_mfp", [{"url": url, "zip_member": csvs[0], "file": str(dest.relative_to(REPO_ROOT)),
                                "rows": len(lines) - 1, "bytes": dest.stat().st_size,
                                "sampled": args.limit is not None}],
                   {"source_page": PAGE, "zip_sha256": z_entry["sha256"]})


if __name__ == "__main__":
    main()
