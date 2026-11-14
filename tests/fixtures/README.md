# CI fixtures

Tiny extracts of the real public-domain files, with the original headers, laid out like `data/raw/`, so CI can run
`dbt build` in seconds without downloading anything or touching Snowflake.

| File | Rows | What is in it |
|---|---|---|
| `nadac/nadac_weekly.csv` | 48 | 6 NDCs x 8 weekly `As of Date`s (Jan 7 - Feb 25, 2026): generic tablet (EA), OTC tablet, suspension (ML), cream (GM), Eliquis (brand, IPAY 2026), Abilify (brand with a corresponding generic) |
| `sdud/sdud_quarterly.csv` | 168 | The same NDCs in SDUD 2024 for AK, CA, NY, TX and the national total `XX`, both utilization types, including suppressed rows |
| `fda_ndc/fda_ndc_product.txt` / `fda_ndc_package.txt` | 6 / 12 | FDA NDC Directory rows for those products (10-digit, hyphenated NDCs) |
| `cms_mfp/cms_mfp.csv` | 62 | Eliquis and Januvia rows from the CMS negotiated-price (MFP) file |
| `nadac_first_time/nadac_first_time_rates.csv` | 3 | First Time NADAC Rates rows |

Extracted on Nov 14, 2026. Load them with `python ingest/load_duckdb.py --fixtures --db ci.duckdb`.

When you add a model, add the fixture rows it needs here (keep each file small) so CI keeps
exercising it. Edge cases you discover in the full data (see PLAN.md) are great fixture rows.
