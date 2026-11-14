-- ============================================================================
-- TODO: int_nadac__price_changes
-- When:  Week 2, Mon Nov 23 (see PLAN.md)
-- ============================================================================
-- Goal
--   Collapse ~45 weekly rows per NDC per year into one row per distinct rate change.
--
-- Grain:  ndc_11 x effective_date (one row per new rate)
-- Inputs:
--   - stg_nadac__weekly
-- Materialization: view (table if slow)
--
-- Definition of done
--   [ ] Rows where (ndc_11, effective_date, nadac_per_unit) repeat week after week appear once,
--   [ ]   with first_seen_as_of_date and last_seen_as_of_date.
--   [ ] Handle the same effective_date republished with a different price (a correction): keep both, flag it.
--   [ ] Row count for the 2026 file written in the YAML description (expect far fewer than 1.36M).
--
-- Hints
--   * Gaps-and-islands with lag() over (partition by ndc_11 order by as_of_date).
--   * Remember the 36 rows with effective_date after as_of_date (see the warning in staging).
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================

{{ config(enabled=false) }}

select 1 as todo_replace_me
