-- ============================================================================
-- TODO: int_sdud__restated
-- When:  Week 2, Fri Nov 27 (see PLAN.md)
-- ============================================================================
-- Goal
--   Keep only the latest published version of each SDUD key when CMS restates a year.
--
-- Grain:  utilization_type x state x ndc_11 x year x quarter
-- Inputs:
--   - stg_sdud__quarterly
-- Materialization: view
--
-- Definition of done
--   [ ] If two files cover the same year, rows from the newer file win (by _source_file publication date or _loaded_at).
--   [ ] Unique on the grain; a singular test proves no key comes from two files.
--
-- Hints
--   * Simulate a restatement: copy tests/fixtures/sdud/sdud_quarterly.csv, change a few amounts, load both.
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================

{{ config(enabled=false) }}

select 1 as todo_replace_me
