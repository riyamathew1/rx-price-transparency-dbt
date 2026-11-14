"""Shared helpers for the ingestion scripts.

Every script lands files under data/raw/<dataset>/ (git-ignored) and writes a
small JSON manifest next to them (source URL, rows, bytes, sha256, time), so a
reviewer can see exactly what was downloaded and when.

No credentials are needed: every source here is US public-domain open data.
Requests honours the standard HTTP(S)_PROXY environment variables.
"""

from __future__ import annotations

import datetime as dt
import hashlib
import json
import re
import sys
import time
from pathlib import Path
from typing import Iterator

import requests

REPO_ROOT = Path(__file__).resolve().parents[1]
RAW_DIR = REPO_ROOT / "data" / "raw"
USER_AGENT = "rx-price-transparency-dbt/0.1 (portfolio project; github.com/riyamathew1)"

MEDICAID_METASTORE = (
    "https://data.medicaid.gov/api/1/metastore/schemas/dataset/items?show-reference-ids=true"
)


def session() -> requests.Session:
    s = requests.Session()
    s.headers["User-Agent"] = USER_AGENT
    adapter = requests.adapters.HTTPAdapter(
        max_retries=requests.adapters.Retry(
            total=4, backoff_factor=2, status_forcelist=(429, 500, 502, 503, 504)
        )
    )
    s.mount("https://", adapter)
    return s


def log(msg: str) -> None:
    print(f"[{dt.datetime.now():%H:%M:%S}] {msg}", file=sys.stderr, flush=True)


def medicaid_datasets(sess: requests.Session) -> list[dict]:
    """Return the data.medicaid.gov DKAN catalog (about 560 datasets)."""
    r = sess.get(MEDICAID_METASTORE, timeout=120)
    r.raise_for_status()
    return r.json()


def resolve_medicaid_csv(catalog: list[dict], title_regex: str) -> dict:
    """Find one dataset by title and return its id, title, modified date and CSV URL.

    Dataset ids and CSV file names change (for example the NADAC file is renamed
    every week), so we always resolve them from the catalog instead of hard-coding.
    """
    pattern = re.compile(title_regex, re.IGNORECASE)
    hits = [d for d in catalog if pattern.fullmatch(d.get("title", "").strip())]
    if len(hits) != 1:
        titles = [d.get("title") for d in hits]
        raise SystemExit(f"Expected exactly one dataset matching {title_regex!r}, got {titles}")
    d = hits[0]
    urls = [
        (dist.get("data") or {}).get("downloadURL")
        for dist in d.get("distribution", [])
        if str((dist.get("data") or {}).get("downloadURL", "")).lower().endswith(".csv")
    ]
    if not urls:
        raise SystemExit(f"No CSV distribution for {d.get('title')}")
    return {
        "dataset_id": d["identifier"],
        "title": d["title"],
        "modified": d.get("modified"),
        "url": urls[0],
    }


def stream_lines(sess: requests.Session, url: str) -> Iterator[bytes]:
    with sess.get(url, stream=True, timeout=300) as r:
        r.raise_for_status()
        yield from r.iter_lines(chunk_size=1 << 20, delimiter=b"\n")


def download_csv(
    sess: requests.Session, url: str, dest: Path, limit: int | None = None
) -> dict:
    """Stream a CSV to dest. With limit, keep the header plus the first `limit` rows."""
    dest.parent.mkdir(parents=True, exist_ok=True)
    tmp = dest.with_suffix(dest.suffix + ".part")
    sha = hashlib.sha256()
    rows = -1  # header line does not count
    started = time.time()
    with tmp.open("wb") as fh:
        for line in stream_lines(sess, url):
            line = line.rstrip(b"\r")
            if not line:
                continue
            out = line + b"\n"
            fh.write(out)
            sha.update(out)
            rows += 1
            if limit is not None and rows >= limit:
                break
    tmp.replace(dest)
    return {
        "url": url,
        "file": str(dest.relative_to(REPO_ROOT)),
        "rows": max(rows, 0),
        "bytes": dest.stat().st_size,
        "sha256": sha.hexdigest(),
        "sampled": limit is not None,
        "seconds": round(time.time() - started, 1),
    }


def download_file(sess: requests.Session, url: str, dest: Path) -> dict:
    dest.parent.mkdir(parents=True, exist_ok=True)
    sha = hashlib.sha256()
    with sess.get(url, stream=True, timeout=300) as r:
        r.raise_for_status()
        with dest.open("wb") as fh:
            for chunk in r.iter_content(1 << 20):
                fh.write(chunk)
                sha.update(chunk)
    return {"url": url, "file": str(dest.relative_to(REPO_ROOT)), "bytes": dest.stat().st_size,
            "sha256": sha.hexdigest()}


def write_manifest(dataset: str, entries: list[dict], extra: dict | None = None) -> Path:
    path = RAW_DIR / dataset / "_manifest.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    # Merge with earlier runs so downloading one year does not forget the others.
    previous = json.loads(path.read_text()).get("files", []) if path.exists() else []
    new_files = {e["file"] for e in entries}
    entries = [e for e in previous if e.get("file") not in new_files] + entries
    payload = {
        "dataset": dataset,
        "downloaded_at": dt.datetime.now(dt.timezone.utc).isoformat(timespec="seconds"),
        **(extra or {}),
        "files": entries,
    }
    path.write_text(json.dumps(payload, indent=2) + "\n")
    for e in entries:
        if e["file"] not in new_files:
            continue
        rows = f"{e['rows']:,} rows, " if "rows" in e else ""
        log(f"{dataset}: {e['file']} ({rows}{e['bytes']:,} bytes)")
    return path


def add_limit_arg(parser) -> None:
    parser.add_argument(
        "--limit", "--sample", dest="limit", type=int, nargs="?", const=20000, default=None,
        help="Keep only the first N data rows per file (default 20000 when given without N). "
             "Omit for the full download.",
    )
