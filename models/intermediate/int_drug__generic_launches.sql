-- ============================================================================
-- TODO: int_drug__generic_launches
-- When:  Week 3, Thu Dec 3 (see PLAN.md)
-- ============================================================================
-- Goal
--   One row per molecule (ingredient x strength x form) with its first-generic launch date.
--
-- Grain:  one row per drug group
-- Inputs:
--   - stg_nadac__first_time_rates
--   - stg_nadac__weekly
--   - dim_drug
-- Materialization: table
--
-- Definition of done
--   [ ] launch_week = first as_of_date a generic (rate_setting_class = 'G') appears for a group that had only brands.
--   [ ] Cross-checked against First Time NADAC Rates ('New Drug/New Generic'): agreement rate documented.
--   [ ] Only launches with >= 12 weeks of pre-period brand prices kept for the event study (filter documented).
--
-- Hints
--   * corresponding_generic_nadac_per_unit on brand rows is another clue.
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================

{{ config(enabled=false) }}

select 1 as todo_replace_me
