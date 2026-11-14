-- ============================================================================
-- TODO: Difference-in-differences: Jan 1, 2026 Medicare negotiated prices
-- When:  Week 3, Sun Dec 6 (see PLAN.md)
-- ============================================================================
-- Goal
--   Did NADAC (or Medicaid volume) for the 10 IPAY 2026 drugs change vs comparison brands after Jan 1, 2026?
--
-- Grain:  treated x period
-- Inputs:
--   - mart_negotiated_price_panel
--   - fct_medicaid_utilization
-- Materialization: analysis
--
-- Definition of done
--   [ ] DiD estimate with CI, an event-study plot of weekly coefficients, and the parallel-trends caveat.
--   [ ] Honest write-up if the effect is ~0 (refund mechanism, Medicare is not Medicaid).
--
-- Hints
--   * Medicaid SDUD 2026 is only partly published; say which quarters you have.
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================

{{ config(enabled=false) }}

select 1 as todo_replace_me
