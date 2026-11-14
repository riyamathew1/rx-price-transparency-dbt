-- ============================================================================
-- TODO: int_units__reconciled
-- When:  Week 1, Sun Nov 22 (see PLAN.md)
-- ============================================================================
-- Goal
--   Check that NADAC's pricing unit (EA/ML/GM) matches the unit SDUD counts in units_reimbursed,
--   and flag NDCs where they disagree (inhalers, insulin pens, kits, creams).
--
-- Grain:  one row per ndc_11
-- Inputs:
--   - stg_nadac__weekly
--   - stg_sdud__quarterly
--   - stg_fda_ndc__packages
-- Materialization: view
--
-- Definition of done
--   [ ] `implied_units_per_rx` = units_reimbursed / number_of_prescriptions, compared with the FDA package size.
--   [ ] `unit_check_status` in (ok, suspicious, unknown) with the rule documented in YAML.
--   [ ] A warn-severity test that the share of suspicious SDUD dollars stays under a threshold you choose.
--
-- Hints
--   * Parse quantity + unit from FDA packagedescription (e.g. '100 mL in 1 BOTTLE'). Regex practice.
--   * Do not 'fix' units silently; flag them and exclude them downstream with a documented filter.
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================

{{ config(enabled=false) }}

select 1 as todo_replace_me
