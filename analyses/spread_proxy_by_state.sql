-- ============================================================================
-- TODO: Spread proxy: Medicaid reimbursement minus NADAC, by state
-- When:  Week 3, Sun Dec 6 (see PLAN.md)
-- ============================================================================
-- Goal
--   Rank states and drugs by reimbursement above acquisition cost, with caveats.
--
-- Grain:  state (and state x drug)
-- Inputs:
--   - mart_reimbursement_vs_nadac
-- Materialization: analysis
--
-- Definition of done
--   [ ] Top 10 states by gap_share for generics; top 20 drug-states by total gap dollars.
--   [ ] Caveat table: rebates, dispensing fees, suppression, unit mismatches, MCO vs FFS.
--
-- Hints
--   * Generic dispensing fees (~$10/rx) can dominate the gap for cheap generics; try gap per rx too.
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================

{{ config(enabled=false) }}

select 1 as todo_replace_me
