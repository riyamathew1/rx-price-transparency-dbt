# PLAN: Rx Price Transparency, end to end in 4 weeks

**Dates:** Mon Nov 16 to Sun Dec 13, 2026.
**Time budget:** 2 h each weekday, 5 h each Saturday and Sunday (20 h a week, 80 h total).
**Hard deadline:** the Snowflake trial likely ends around **Thu Dec 3**. Every Snowflake-only task
(stage loading, warehouse tuning, incremental runs measured in Query History, slim CI, Snowflake
features) is in weeks 1-3 and finishes by **Wed Dec 2**. Week 4 needs only DuckDB, Tableau Public
and writing.

How to use this plan:

- Each session has a **Definition of Done (DoD)**. Tick it only when the DoD is true, not when the
  time is up. If a session runs over, push the next one and use the buffer (Thu Nov 26 and the
  "stretch" items are the slack).
- One branch and one pull request per session (`feat/stg-sdud`, ...). CI must be green before you
  merge. That gives you a commit history recruiters can read.
- Keep a `NOTES.md` scratchpad: surprises in the data, numbers, decisions. It becomes `FINDINGS.md`.
- The file for each step already exists as a `TODO` stub with hints. Remove `enabled=false` when you start it.

Legend: ❄️ = needs Snowflake (do it before the trial ends), 🦆 = DuckDB is enough.

---

## Week 1 (Nov 16-22): load and stage

Goal: all five sources typed in staging, NDCs normalized, units checked, data in Snowflake RAW.

### Mon Nov 16 (2 h) ❄️🦆 Setup and first green build
- Create the venv, `pip install -r requirements.txt`, `dbt deps`, `pre-commit install`.
- `python ingest/run_all.py --sample`, `python ingest/load_duckdb.py`, `dbt build`.
- In Snowsight, run `snowflake/setup.sql` as ACCOUNTADMIN. Create a key pair on your laptop
  (instructions in setup.sql section 7, but for your own user), fill `.env`, `dbt debug --target snowflake`.
- Read `stg_nadac__weekly.sql` and its YAML line by line; this is the pattern for every staging model.

**DoD:** `dbt build` passes on DuckDB (29 nodes, 1 expected warning on real data);
`dbt debug --target snowflake` says "All checks passed"; `show resource monitors` lists RX_MONITOR
attached to RX_WH; `.env` is not in `git status`.

### Tue Nov 17 (2 h) 🦆 NDC 10 -> 11 digit normalization
- Implement `macros/normalize_ndc_to_11.sql`: 4-4-2 -> pad the labeler (0 + 4), 5-3-2 -> pad the
  product (0 + 3), 5-4-1 -> pad the package (0 + 1), result 5-4-2 without hyphens. Text only, never numbers.
- Implement the custom generic test `tests/generic/test_is_valid_ndc_11.sql`.
- Unit test with one row per layout, an 11-digit value, a null and a malformed value.

**DoD:** unit test passes on DuckDB; a deliberately bad fixture row makes `is_valid_ndc_11` fail
(then remove it); the macro compiles on Snowflake (`dbt compile --target snowflake`).

### Wed Nov 18 (2 h) 🦆 Staging: FDA NDC Directory
- `stg_fda_ndc__products` and `stg_fda_ndc__packages` (YYYYMMDD dates, `ndc_11` via your macro,
  `ndc_layout`, generic vs brand from marketing category).
- Tests: unique/not_null keys, relationships package -> product, `is_valid_ndc_11`.

**DoD:** both models build on fixtures and on the full FDA files; you can say how many packages use
each layout (write it in NOTES.md).

### Thu Nov 19 (2 h) 🦆 Staging: SDUD
- `stg_sdud__quarterly`: numeric casts (raw values have leading zeros), `is_suppressed`,
  `is_national_total` (state `XX`), `quarter_start_date`.
- Find the real grain and test it with `dbt_utils.unique_combination_of_columns`.

**DoD:** builds on fixtures and on SDUD 2024 sample; suppressed rows keep NULL amounts (not 0); a
query in NOTES.md shows the share of rows and of dollars that are suppressed.

### Fri Nov 20 (2 h) 🦆 Staging: CMS negotiated prices and First Time NADAC
- `stg_cms__negotiated_prices`: parse `$231.00`, dates, NDC digits; `stg_nadac__first_time_rates`.
- Test that IPAY 2026 has exactly 10 selected drugs.

**DoD:** all five staging models build and test green on fixtures; CI green on the PR.

### Sat Nov 21 (5 h) ❄️ Load Snowflake through a stage, then conform NDCs
- Full downloads: `python ingest/nadac.py --years 2024 2025 2026`, `python ingest/sdud.py --years 2024 2025`,
  `python ingest/fda_ndc.py`, `python ingest/cms_mfp.py`.
- Run `snowflake/load_raw.sql` and finish its section 4 (COPY INTO for the other tables, TRUNCATE
  for full-replacement files). Check every table against the row counts in `data/raw/*/_manifest.json`.
- `dbt build --target snowflake`. Open Query History: note bytes scanned and time of the biggest query.
- Build `int_ndc__normalized` (one row per 11-digit NDC across all sources, with match flags).

**DoD:** RAW row counts equal the manifests (paste the comparison in NOTES.md); staging builds on
Snowflake; you know the % of SDUD dollars whose NDC matches NADAC and FDA.

### Sun Nov 22 (5 h) 🦆❄️ Unit reconciliation and the week-1 write-up
- `int_units__reconciled`: NADAC `pricing_unit` (EA/ML/GM) vs SDUD `units_reimbursed` per prescription
  vs the FDA package description (parse "100 mL in 1 BOTTLE"). Flag inhalers, insulin pens, kits,
  creams where a "unit" means different things.
- Warn-severity test on the share of SDUD dollars flagged suspicious.
- Start the README "Data quality decisions" section (every rule and why).
- dbt Fundamentals: finish the modules on tests and documentation if not done yet.

**DoD:** each NDC has `unit_check_status` in (ok, suspicious, unknown) with the rule in YAML; you can
name three real NDCs where units disagree and why; week-1 PRs merged, CI green.

---

## Week 2 (Nov 23-29): SCD2, snapshots, incremental facts, slim CI

### Mon Nov 23 (2 h) 🦆 Collapse weekly rows into price changes
- `int_nadac__price_changes`: gaps and islands over `as_of_date`; one row per new
  `(ndc_11, effective_date, nadac_per_unit)` with first and last `as_of_date` seen.
- Handle corrections (same `effective_date`, different price) and the 36 rows whose
  `effective_date` is after `as_of_date`.

**DoD:** unit test (4 identical weeks + 1 change -> 2 rows) passes; 2026 row count noted
(expect a small fraction of 1.36M).

### Tue Nov 24 (2 h) 🦆 Bitemporal SCD Type 2: `fct_nadac_price_history`
- `valid_from`/`valid_to` from `effective_date`; `known_from`/`known_to` from `as_of_date`; `is_current`.
- Implement the generic tests `no_overlapping_windows` and `exactly_one_current_row`.
- Enforce a model contract (data types, not_null).

**DoD:** both custom tests pass; two example queries in the YAML description answer "price on
2026-03-01" and "what CMS had published as of 2026-03-01", and give different answers for at least one NDC.

### Wed Nov 25 (2 h) ❄️ Snapshot of FDA product attributes
- `snap_fda__ndc_products` with `strategy='check'` on the attributes you choose.
- Run it on Snowflake today and again after re-downloading FDA tomorrow (daily file).
- Stretch: `snap_nadac__latest_rates`, compared with `fct_nadac_price_history`.

**DoD:** the snapshot has at least one product with two versions (or you document that none changed and
show the check ran twice); README explains observed (snapshot) vs reconstructed (NADAC) history.

### Thu Nov 26 (2 h, Thanksgiving) Buffer
Catch up on anything unfinished. If you are on track: `dbt docs generate && dbt docs serve`, read
your own lineage graph, fix missing descriptions.

**DoD:** no open week-1/2 TODO older than two days.

### Fri Nov 27 (2 h) ❄️🦆 SDUD restatements: merge logic and reconciliation
- `int_sdud__restated`: when two files cover the same year, the newer file wins.
- `fct_medicaid_utilization`: `incremental_strategy='merge'`, `unique_key` = the grain, contract enforced.
- Simulate a restatement (copy the fixture, change a few amounts), run incrementally, prove rows
  updated in place. Enable `assert_sdud_states_reconcile_to_national_total` (states vs `XX`).

**DoD:** the restated rows changed and the row count did not; reconciliation test green with a
tolerance you justify in the README; same result on DuckDB and Snowflake.

### Sat Nov 28 (5 h) ❄️ Incremental NADAC, `dim_drug`, warehouse tuning
- `fct_nadac_weekly` (incremental append with a lookback). Load 2024+2025, build, then add 2026 and
  build again. Record rows processed and seconds for full refresh vs incremental (Query History).
- `dim_drug` (ingredient x form x strength) with an enforced contract.
- Warehouse tuning: run the heaviest model once on X-Small and once on Small; compare seconds and
  credits; go back to X-Small. Try clustering `fct_nadac_weekly` by `as_of_date` only if it helps
  pruning (check partitions scanned).

**DoD:** README has a small table (full refresh vs incremental, XS vs S) with real numbers;
`dim_drug` contract enforced; credits used so far < 50% of RX_MONITOR.

### Sun Nov 29 (5 h) ❄️ Slim CI on Snowflake
- Create the `RX_CI` service user with a key pair (setup.sql section 7).
- Add GitHub secrets yourself in the repo settings (never in chat or code): `SNOWFLAKE_ACCOUNT`,
  `SNOWFLAKE_USER`, `SNOWFLAKE_PRIVATE_KEY`, `SNOWFLAKE_PRIVATE_KEY_PASSPHRASE` (if any),
  `SNOWFLAKE_ROLE`, `SNOWFLAKE_WAREHOUSE`, `SNOWFLAKE_DATABASE`.
- Add a deploy job on push to main (`SNOWFLAKE_SCHEMA=PROD`, upload `manifest.json`), then switch the
  Snowflake job to `dbt build --select state:modified+ --defer --state prod-artifacts/` into `PR_<n>`
  schemas, plus a cleanup step that drops them.

**DoD:** a test PR that changes one model shows the Snowflake job building only that model and its
children; the PR schema is dropped afterwards; the workflow log never prints a secret.

---

## Week 3 (Nov 30-Dec 6): marts, Snowflake wrap-up, metrics, analysis

### Mon Nov 30 (2 h) ❄️ Spread proxy: `mart_reimbursement_vs_nadac`
- State x drug x quarter: reimbursed per unit vs time-weighted NADAC per unit, `gap_per_unit`, `gap_share`.
- Exclude suppressed rows and suspicious units; report the excluded share.
- Document caveats in YAML: pre-rebate amounts, dispensing fees, suppression, FFS vs managed care.

**DoD:** mart builds on Snowflake; top 5 states by generic `gap_share` in NOTES.md with the caveats next to them.

### Tue Dec 1 (2 h) ❄️ Negotiated-price panel and Snowflake features
- `mart_negotiated_price_panel`: 10 IPAY 2026 drugs + a documented comparison group, weekly, 2025-2026.
- Snowflake features worth one paragraph each in the README: zero-copy clone of PROD into a dev
  database, Time Travel to show a table before the restatement merge, query tags in Query History.

**DoD:** panel has >= 52 pre weeks; README has a screenshot or query for clone and Time Travel.

### Wed Dec 2 (2 h) ❄️ Snowflake wrap-up (last Snowflake session)
- Final `dbt build --target snowflake` with `SNOWFLAKE_SCHEMA=PROD`; save `target/manifest.json` and
  `run_results.json` to `docs/snowflake-run/`.
- Export the marts (COPY INTO @stage as Parquet + GET, or `dbt show`) to `data/exports/` (git-ignored).
- Screenshot Query History and the resource monitor (credits used). Set the Snowflake CI job back to
  manual so CI stays green after the trial.

**DoD:** everything needed for weeks 3-4 runs on DuckDB; README states total credits used; no
Snowflake dependency left in the default CI path.

### Thu Dec 3 (2 h) 🦆 Generic launches and the event panel (trial ends ~today)
- `int_drug__generic_launches` (first generic per drug group, cross-checked with First Time NADAC).
- `mart_generic_entry_panel`: drug x relative week (-26 .. +52), price index, generic count.

**DoD:** N launches with full windows listed in NOTES.md; balanced-panel flag tested.

### Fri Dec 4 (2 h) 🦆 Semantic layer and metrics
- Uncomment and finish `models/marts/_semantic_models.yml`: a time spine, two semantic models,
  simple, ratio and derived metrics (`medicaid_spend`, `gap_share`, `avg_reimbursed_per_unit`,
  quarter-over-quarter change).
- `pip install dbt-metricflow` (pin it), `mf validate-configs`, two `mf query` examples.

**DoD:** `mf validate-configs` passes; the two query outputs are in the README.

### Sat Dec 5 (5 h) 🦆 Event study: price drops after first-generic launch
- `analyses/event_study_first_generic.sql` + `notebooks/event_study.ipynb` (statsmodels).
- Plot the price index by relative week with 95% CIs, clustered by drug; check pre-trends; read
  about staggered-adoption pitfalls and pick an estimator you can explain.

**DoD:** one chart + one sentence: "N weeks after first generic entry, acquisition cost was X% lower
(95% CI a to b, N launches)"; limits listed.

### Sun Dec 6 (5 h) 🦆 Jan 1, 2026 negotiated prices (DiD) and the spread story
- `analyses/did_negotiated_prices.sql` + notebook: DiD on NADAC (and Medicaid units where 2026
  quarters exist) for the 10 drugs vs the comparison group; event-study plot of weekly coefficients.
- `analyses/spread_proxy_by_state.sql`: final tables for the dashboard.

**DoD:** DiD estimate with CI and an honest interpretation (a null result is fine: Medicare refunds
flow through the Medicare Transaction Facilitator, not through acquisition cost); spread tables exported.

---

## Week 4 (Dec 7-13): docs, quality gates, dashboard, write-up (no Snowflake needed)

### Mon Dec 7 (2 h) 🦆 Exposures, docs and lineage
- Uncomment `models/exposures.yml` (dashboard + notebook). `dbt docs generate`; publish to GitHub
  Pages from main (a small workflow, or commit `target/` to a `gh-pages` branch).

**DoD:** docs site live; lineage screenshot in the README shows sources -> marts -> exposures.

### Tue Dec 8 (2 h) 🦆 Contracts and quality gates review
- Contracts enforced on `dim_drug`, `fct_nadac_price_history`, `fct_medicaid_utilization`.
- Add `dbt-project-evaluator` to CI and fix what it flags (or document exceptions).
- Source freshness (`dbt source freshness`) and a count of tests by type for the README.

**DoD:** CI green with the evaluator; README lists N tests (generic, custom, unit, singular).

### Wed Dec 9 (2 h) 🦆 Data for Tableau
- Export the marts from DuckDB (`copy (select ...) to 'data/exports/x.csv'`) in the shape Tableau
  needs (Tableau Public cannot connect live to Snowflake or DuckDB).

**DoD:** 3-4 tidy CSV extracts, each under Tableau Public's limits, with a data dictionary.

### Thu Dec 10 (2 h) 🦆 Tableau: price history and generic-entry curve
**DoD:** two finished views (NDC price history with SCD2 steps; event-study curve with CI band).

### Fri Dec 11 (2 h) 🦆 Tableau: reimbursement gap map and negotiated-price view; publish
**DoD:** dashboard published on Tableau Public; URL in README and in `models/exposures.yml`.

### Sat Dec 12 (5 h) Findings write-up (`FINDINGS.md`)
Write it for a hiring manager at a pharmacy-benefits or health-tech company:
- 3-5 findings, each with a number, a chart and one line of "so what" (for example: how fast generic
  entry cuts acquisition cost; which states pay most above NADAC for generics and why that is only a
  proxy; whether the Jan 1, 2026 negotiated prices moved pharmacy acquisition cost).
- Methods in plain language, data-quality decisions, limitations, what you would do next.
- Resume bullets with your real numbers (rows modeled, tests, runtime savings from incremental).

**DoD:** FINDINGS.md reviewed by one other person (or read aloud in 5 minutes); resume bullets final.

### Sun Dec 13 (5 h) Polish and ship
- Fresh clone on a clean machine: follow the README quickstart exactly; fix every snag.
- README top section: pitch, dashboard link, lineage image, key results, "how to run".
- Tag `v1.0`; pin the repo on your GitHub profile; record a 3-minute walkthrough (optional).
- Practice the interview story: SCD2 bitemporal design, restatement merge, slim CI, one finding.

**DoD:** fresh-clone quickstart works in < 15 minutes; CI green on main; v1.0 tagged.

---

## Coverage checklist

| Topic | Session |
|---|---|
| NDC 10/11-digit normalization (4-4-2, 5-3-2, 5-4-1 -> 5-4-2) | Tue Nov 17, Wed Nov 18, Sat Nov 21 |
| Unit reconciliation (NADAC EA/ML/GM vs SDUD units) | Sun Nov 22 |
| SCD2 NADAC history from effective date and as-of date | Mon Nov 23, Tue Nov 24 |
| Snapshot (FDA attributes) | Wed Nov 25 |
| SDUD restatements, suppression, incremental merge | Thu Nov 19, Fri Nov 27 |
| Incremental models, warehouse tuning ❄️ | Sat Nov 28 |
| Slim CI on Snowflake ❄️ | Sun Nov 29 |
| Spread proxy with caveats (rebates, dispensing fees, suppression) | Mon Nov 30, Sun Dec 6 |
| Jan 1, 2026 Medicare negotiated prices | Tue Dec 1, Sun Dec 6 |
| Event study after first-generic launches | Thu Dec 3, Sat Dec 5 |
| Semantic layer / metrics | Fri Dec 4 |
| Data contracts, custom tests, unit tests | Tue Nov 17, Tue Nov 24, Sat Nov 28, Tue Dec 8 |
| Exposures, docs, lineage | Mon Dec 7 |
| Tableau Public dashboard | Wed Dec 9 - Fri Dec 11 |
| Findings write-up | Sat Dec 12 |
| All Snowflake-only work done before the trial ends (~Dec 3) | last ❄️ session Wed Dec 2 |
