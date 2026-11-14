-- ============================================================================
-- TODO: fct_medicaid_utilization (incremental merge)
-- When:  Week 2, Fri Nov 27 (see PLAN.md)
-- ============================================================================
-- Goal
--   Medicaid utilization facts that absorb restatements.
--
-- Grain:  utilization_type x state x ndc_11 x year x quarter
-- Inputs:
--   - int_sdud__restated
--   - dim_drug
-- Materialization: incremental, incremental_strategy='merge', unique_key = the grain, CONTRACT enforced
--
-- Definition of done
--   [ ] A restated row updates in place (no duplicates) on an incremental run: proven with the fixture trick from int_sdud__restated.
--   [ ] Reconciliation test: sum of state rows ~= the XX national row per NDC-quarter (tolerance you justify).
--   [ ] Contract enforced; national total rows excluded or flagged.
--
-- Hints
--   * dbt-duckdb supports merge too, so you can test it locally before Snowflake.
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================

{{ config(enabled=false, materialized='incremental', incremental_strategy='merge') }}

select 1 as todo_replace_me
