-- ============================================================================
-- TODO: fct_nadac_weekly (incremental append)
-- When:  Week 2, Sat Nov 28 (see PLAN.md)
-- ============================================================================
-- Goal
--   Incremental copy of the weekly NADAC rows: each run only processes new as_of_dates.
--
-- Grain:  ndc_11 x as_of_date
-- Inputs:
--   - stg_nadac__weekly
-- Materialization: incremental (append, or merge on the grain)
--
-- Definition of done
--   [ ] Inside an is_incremental() block, filter on as_of_date > the max already in `this`, minus a lookback you justify.
--   [ ] Proof in the README: rows and seconds for a full refresh vs an incremental run (Snowflake Query History).
--   [ ] on_schema_change chosen and documented; --full-refresh policy documented.
--
-- Hints
--   * Load 2024+2025 first, build, then load 2026 and build again to see the incremental path.
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================

{{ config(enabled=false, materialized='incremental') }}

select 1 as todo_replace_me
