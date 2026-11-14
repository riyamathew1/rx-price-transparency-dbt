-- ============================================================================
-- TODO: mart_reimbursement_vs_nadac (spread proxy)
-- When:  Week 3, Mon Nov 30 (see PLAN.md)
-- ============================================================================
-- Goal
--   Compare what state Medicaid paid per unit with NADAC per unit, by state x drug x quarter.
--
-- Grain:  state x drug_key x quarter
-- Inputs:
--   - fct_medicaid_utilization
--   - fct_nadac_price_history
--   - int_units__reconciled
-- Materialization: table
--
-- Definition of done
--   [ ] reimbursed_per_unit, nadac_per_unit (time-weighted over the quarter), gap_per_unit, gap_share.
--   [ ] Suppressed rows and unit mismatches excluded, and the excluded share reported.
--   [ ] YAML description lists the caveats: pre-rebate amounts, dispensing fees included, suppression, MCO vs FFS.
--
-- Hints
--   * A quarter has ~13 weekly NADAC rows: average by days valid, not by row.
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================

{{ config(enabled=false) }}

select 1 as todo_replace_me
