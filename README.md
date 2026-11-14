# Rx Price Transparency (dbt + Snowflake + DuckDB)

**What does a drug really cost, how fast do prices fall after a generic launches, and where do
state Medicaid programs pay far above acquisition cost?**

This project models CMS's weekly **NADAC** (National Average Drug Acquisition Cost) survey,
**Medicaid State Drug Utilization Data**, the **FDA NDC Directory** and the **Medicare negotiated
prices** that took effect on Jan 1, 2026, with dbt Core. It runs free on DuckDB and on Snowflake.

> Status: **work in progress** (started Nov 16, 2026). The ingestion, Snowflake setup, CI and the
> NADAC staging layer are done; everything else is a marked `TODO` that I am building step by
> step in [PLAN.md](PLAN.md). Findings will go in `FINDINGS.md`.

## Why this data is interesting

- **Bitemporal SCD Type 2.** Every NADAC row has an `effective_date` (when the price applied) and an
  `as_of_date` (the weekly file it was published in). Rebuilding price history needs both.
- **Restatements.** CMS re-publishes whole years of Medicaid utilization (all years were restated
  in July 2026), so loads must merge, not append.
- **Messy keys.** FDA NDCs are 10 digits with hyphens in three layouts (4-4-2, 5-3-2, 5-4-1);
  NADAC and SDUD use 11 digits (5-4-2). Prices are per unit (EA, ML or GM), not per package.
- **Natural experiments.** First-generic launches (staggered event study) and the 10 drugs whose
  Medicare negotiated prices started Jan 1, 2026 (difference-in-differences).

## Architecture

```text
 data.medicaid.gov ─┐                                     ┌─> mart_reimbursement_vs_nadac ─┐
 fda.gov ───────────┼─ ingest/*.py ─> data/raw ─┬─> RAW ─>│   mart_generic_entry_panel ────┼─> Tableau Public
 cms.gov ───────────┘                           │ (text)  │   mart_negotiated_price_panel ─┤   notebooks/ (statsmodels)
                                                │         │   semantic layer (MetricFlow) ─┘
             DuckDB: ingest/load_duckdb.py ─────┤         │
             Snowflake: PUT + COPY INTO ────────┘         │
                                                          │
 staging (views)          intermediate                    marts/core
 stg_nadac__weekly  ✅    int_ndc__normalized             dim_drug (contract)
 stg_sdud__quarterly      int_units__reconciled           fct_nadac_price_history (bitemporal SCD2)
 stg_fda_ndc__*           int_nadac__price_changes        fct_nadac_weekly (incremental append)
 stg_cms__negotiated_*    int_sdud__restated              fct_medicaid_utilization (incremental merge)
 stg_nadac__first_time_*  int_drug__generic_launches      snapshots: snap_fda__ndc_products
```

Lineage graph screenshot: TODO (week 4, `dbt docs generate`).

## Datasets

| Dataset | Source | Grain | Size (checked Nov 14, 2026) |
|---|---|---|---|
| NADAC weekly, one file per year | [data.medicaid.gov, NADAC 2026](https://data.medicaid.gov/dataset/fbb83258-11c7-47f5-8b18-5f8e79f7e704) | NDC x weekly `as_of_date` | 2026: 1,358,735 rows (118 MB), 45 weeks so far |
| First Time NADAC Rates | [data.medicaid.gov](https://data.medicaid.gov/dataset/e3af839d-8175-5be0-b94e-4a302ed7a035) | new drug / first generic | 1,419 rows |
| State Drug Utilization Data | [data.medicaid.gov, SDUD 2024](https://data.medicaid.gov/dataset/61729e5a-7aa8-448c-8903-ba3e0cd0ea3c) | type x state x NDC x quarter | 2024: 5,308,407 rows (504 MB) |
| FDA NDC Directory | [fda.gov](https://www.fda.gov/drugs/drug-approvals-and-databases/national-drug-code-directory) (`ndctext.zip`) | product / package | 116,697 products, 219,262 packages |
| Medicare negotiated prices (MFP) | [cms.gov, Selected Drugs and Negotiated Prices](https://www.cms.gov/initiatives/medicare-prescription-drug-affordability/overview/medicare-drug-price-negotiation-program/selected-drugs-negotiated-prices) | IPAY x NDC-11 x price period | 556 rows; IPAY 2026: 10 drugs, 151 NDCs |

All sources are US government open data (public domain). Dataset ids and file names change, so
the scripts resolve them from the data.medicaid.gov catalog and the CMS page at run time.

## Quickstart (free, DuckDB)

```bash
git clone https://github.com/riyamathew1/rx-price-transparency-dbt && cd rx-price-transparency-dbt
python3.12 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
dbt deps

python ingest/run_all.py --sample      # 20,000 rows per file, about 20 MB, a few seconds
python ingest/load_duckdb.py           # data/raw -> rx.duckdb, schema raw
dbt build                              # default target: duckdb

pre-commit install                     # sqlfluff + safety hooks on every commit
```

Full downloads: `python ingest/run_all.py` (NADAC 2024-2026 and SDUD 2024-2025, a few GB), or one
script at a time, e.g. `python ingest/nadac.py --years 2026`. Each folder in `data/raw/` gets a
`_manifest.json` with URL, rows, bytes and sha256. `data/raw/` and `*.duckdb` are git-ignored.

CI fixtures (no download): `python ingest/load_duckdb.py --fixtures --db ci.duckdb && dbt build --target ci`.

## Snowflake path

1. Run [`snowflake/setup.sql`](snowflake/setup.sql) once as ACCOUNTADMIN: role `RX_TRANSFORMER`,
   X-Small warehouse `RX_WH` (auto-suspend 60 s), resource monitor `RX_MONITOR`, database
   `RX_PRICES` with schemas RAW, STAGING, INTERMEDIATE, MARTS, SNAPSHOTS, file formats and a stage.
2. `cp .env.example .env`, fill it in (never commit it), then `set -a; source .env; set +a`.
   `profiles.yml` only reads environment variables:
   `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PRIVATE_KEY_PATH` (+ optional
   `SNOWFLAKE_PRIVATE_KEY_PASSPHRASE`) or `SNOWFLAKE_PASSWORD`, `SNOWFLAKE_ROLE`,
   `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE`, `SNOWFLAKE_SCHEMA`.
3. Load: `snow sql -f snowflake/load_raw.sql -D "repo_root=$(pwd)"` (PUT + COPY INTO).
4. `dbt debug --target snowflake && dbt build --target snowflake` (key pair) or
   `--target snowflake_password`.

Schemas: with `SNOWFLAKE_SCHEMA=DEV`, models land in `DEV_STAGING`, `DEV_MARTS`, ...; with `PROD`
they land in `STAGING`, `MARTS`, ... (see `macros/generate_schema_name.sql`).

The trial ends around Dec 3, 2026, so all Snowflake-only work is scheduled in weeks 1-3.
After that the DuckDB target keeps everything reproducible for free.

## CI

[`.github/workflows/ci.yml`](.github/workflows/ci.yml) runs on every pull request and push to main:
`pip install`, `dbt deps`, fixtures into DuckDB, `dbt build --target ci`, `sqlfluff lint`.
No secrets needed. A manual Snowflake slim-CI job is sketched (TODO, week 2) and expects these
repository secrets: `SNOWFLAKE_ACCOUNT`, `SNOWFLAKE_USER`, `SNOWFLAKE_PRIVATE_KEY`,
`SNOWFLAKE_PRIVATE_KEY_PASSPHRASE` (optional), `SNOWFLAKE_ROLE`, `SNOWFLAKE_WAREHOUSE`,
`SNOWFLAKE_DATABASE`.

## Where the TODOs are

Every TODO file has a header with the goal, grain, inputs, definition of done and hints, and is
disabled (`enabled=false` or commented YAML) so `dbt build` stays green until I build it.

```bash
grep -rln "TODO" models macros snapshots analyses tests snowflake notebooks .github
```

| Area | Files |
|---|---|
| Staging (4 of 5 sources) | `models/staging/{sdud,fda_ndc,cms}/stg_*.sql`, `stg_nadac__first_time_rates.sql` |
| NDC normalization | `macros/normalize_ndc_to_11.sql`, `tests/generic/test_is_valid_ndc_11.sql` |
| Intermediate | `models/intermediate/int_*.sql`, `_intermediate__unit_tests.yml` |
| SCD2, incremental, contracts | `models/marts/core/*.sql`, `snapshots/*.sql`, `tests/generic/*` |
| Marts and analyses | `models/marts/analytics/*.sql`, `analyses/*.sql`, `notebooks/` |
| Semantic layer, exposures | `models/marts/_semantic_models.yml`, `models/exposures.yml` |
| Snowflake loads, slim CI | `snowflake/load_raw.sql` (section 4), `.github/workflows/ci.yml` |

## Data caveats (read before quoting a number)

- SDUD amounts are **before manufacturer rebates** and **include dispensing fees**, so
  "Medicaid reimbursement minus NADAC" is a **spread proxy**, not a pharmacy margin.
- SDUD suppresses rows with fewer than 11 prescriptions; `XX` is the national total.
- Medicare negotiated prices reach pharmacies through refunds (the Medicare Transaction
  Facilitator), so NADAC may not move at all. A null result is an honest finding.
- NADAC is a national average from a voluntary survey of retail pharmacies.

## Project layout

```text
ingest/            downloaders (+ DuckDB loader)        snowflake/   setup, load, teardown SQL
models/staging     one folder per source                tests/       generic + singular tests, CI fixtures
models/intermediate, models/marts/{core,analytics}       analyses/    event study, DiD, spread proxy
snapshots/         dbt snapshots                         notebooks/   statistics (TODO)
PLAN.md            4-week build plan with definitions of done
```
