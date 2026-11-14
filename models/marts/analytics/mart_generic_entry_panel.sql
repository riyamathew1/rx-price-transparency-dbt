-- ============================================================================
-- TODO: mart_generic_entry_panel
-- When:  Week 3, Thu Dec 3 (see PLAN.md)
-- ============================================================================
-- Goal
--   Event-time panel: each drug group x week relative to its first-generic launch.
--
-- Grain:  drug_key x relative_week (-26 .. +52)
-- Inputs:
--   - int_drug__generic_launches
--   - fct_nadac_price_history
-- Materialization: table
--
-- Definition of done
--   [ ] relative_week, brand and generic NADAC per unit, generic count, log price index (pre-period mean = 0).
--   [ ] Balanced window: drugs missing any week flagged, not silently dropped.
--
-- Hints
--   * Use dbt_utils.date_spine or a generated week series to fill weeks with no rate change.
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================

{{ config(enabled=false) }}

select 1 as todo_replace_me
