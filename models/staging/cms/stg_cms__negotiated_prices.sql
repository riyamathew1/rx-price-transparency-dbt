-- ============================================================================
-- TODO: stg_cms__negotiated_prices
-- When:  Week 1, Fri Nov 20 (see PLAN.md)
-- ============================================================================
-- Goal
--   Typed CMS Maximum Fair Price (negotiated price) rows for every IPAY.
--
-- Grain:  ipay x ndc_11 x mfp_effective_date
-- Inputs:
--   - source('cms_negotiation', 'maximum_fair_prices')
-- Materialization: view
--
-- Definition of done
--   [ ] Money text like "$231.00" -> numeric (strip $ and commas); dates parsed; ndc_11 digits only.
--   [ ] `mfp_end_date` null when open-ended; test valid_from < valid_to when both present.
--   [ ] Tests: unique grain, IPAY 2026 has exactly 10 selected drugs (singular test or dbt_expectations).
--
-- Hints
--   * The file is itself a tiny SCD2: inflation adjustments end-date the old price on Dec 31.
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================

{{ config(enabled=false) }}

select 1 as todo_replace_me
