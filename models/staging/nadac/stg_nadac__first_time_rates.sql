-- ============================================================================
-- TODO: stg_nadac__first_time_rates
-- When:  Week 1, Fri Nov 20 (see PLAN.md)
-- ============================================================================
-- Goal
--   Typed First Time NADAC Rates: when a new drug or first generic got its first NADAC.
--
-- Grain:  drug_product x as_of_date (verify)
-- Inputs:
--   - source('nadac', 'first_time_rates')
-- Materialization: view
--
-- Definition of done
--   [ ] Rename the very long column to something readable; parse dates; numeric rate.
--   [ ] accepted_values on primary_reason_code and classification_for_rate_setting (explore first).
--
-- Hints
--   * There is no NDC column. How will you join this to NADAC rows? (drug_product vs ndc_description)
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================

{{ config(enabled=false) }}

select 1 as todo_replace_me
