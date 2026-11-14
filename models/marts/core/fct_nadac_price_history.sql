-- ============================================================================
-- TODO: fct_nadac_price_history (bitemporal SCD Type 2)
-- When:  Week 2, Tue Nov 24 (see PLAN.md)
-- ============================================================================
-- Goal
--   Price history per NDC with BOTH time axes:
--     valid_from / valid_to       = when the rate applied (from effective_date)
--     known_from / known_to       = when CMS had published it (from as_of_date)
--
-- Grain:  ndc_11 x valid_from (one row per price validity window)
-- Inputs:
--   - int_nadac__price_changes
-- Materialization: table (incremental later), CONTRACT enforced
--
-- Definition of done
--   [ ] valid_to = next valid_from (exclusive) or null for the current row; is_current flag.
--   [ ] Custom generic tests pass: exactly_one_current_row (per ndc_11) and no_overlapping_windows.
--   [ ] A query can answer 'what was the price on 2026-03-01?' AND 'what did we believe it was on 2026-03-01?'
--   [ ] Contract with data types; unique (ndc_11, valid_from).
--
-- Hints
--   * lead() over (partition by ndc_11 order by effective_date).
--   * Read about bitemporal modeling first; write the two example queries into the YAML description.
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================

{{ config(enabled=false) }}

select 1 as todo_replace_me
