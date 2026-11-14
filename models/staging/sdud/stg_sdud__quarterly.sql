-- ============================================================================
-- TODO: stg_sdud__quarterly
-- When:  Week 1, Thu Nov 19 (see PLAN.md)
-- ============================================================================
-- Goal
--   Typed, renamed SDUD rows. Same rules as stg_nadac__weekly: no joins, no filters.
--
-- Grain:  utilization_type x state x ndc_11 x year x quarter (check it! is it unique per file?)
-- Inputs:
--   - source('sdud', 'quarterly')
-- Materialization: view
--
-- Definition of done
--   [ ] Numbers cast to numeric; leading zeros in raw amounts handled (raw looks like 00000000226.000).
--   [ ] `is_suppressed` boolean from suppression_used; amounts stay NULL when suppressed (never 0).
--   [ ] `is_national_total` flag for state = 'XX' so nobody double counts it.
--   [ ] `quarter_start_date` derived from year + quarter (cross-database: write a macro if needed).
--   [ ] Tests: unique combination of the grain, accepted_values on utilization_type and quarter,
--   [ ]   not_null where the data allows it, a regex test on ndc_11. All pass on fixtures and real data.
--
-- Hints
--   * Look at the fixture rows in tests/fixtures/sdud/ first: what does a suppressed row look like?
--   * Model the file version too (_source_file): restatements arrive as new files (week 2).
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================

{{ config(enabled=false) }}

select 1 as todo_replace_me
