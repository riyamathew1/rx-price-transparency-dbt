-- ============================================================================
-- TODO: mart_negotiated_price_panel
-- When:  Week 3, Tue Dec 1 (see PLAN.md)
-- ============================================================================
-- Goal
--   Weekly panel for the 10 IPAY 2026 drugs and comparison brand drugs, before and after Jan 1, 2026.
--
-- Grain:  drug_key x as_of_date
-- Inputs:
--   - fct_nadac_price_history
--   - stg_cms__negotiated_prices
--   - dim_drug
-- Materialization: table
--
-- Definition of done
--   [ ] treated flag, post flag (as_of_date >= var('mfp_ipay_2026_effective_date')), NADAC, MFP per unit.
--   [ ] Comparison group rule documented (for example brand-only drugs in the same classes not selected).
--   [ ] Covers at least 52 pre weeks (needs NADAC 2025) and all 2026 weeks.
--
-- Hints
--   * Negotiated prices reach pharmacies through refunds, so NADAC may not move. A null result is a finding.
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================

{{ config(enabled=false) }}

select 1 as todo_replace_me
