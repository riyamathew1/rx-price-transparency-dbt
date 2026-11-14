-- ============================================================================
-- TODO: stg_fda_ndc__products
-- When:  Week 1, Wed Nov 18 (see PLAN.md)
-- ============================================================================
-- Goal
--   Typed FDA product attributes (names, dosage form, route, marketing category, labeler, strength).
--
-- Grain:  one row per productid
-- Inputs:
--   - source('fda_ndc', 'product')
-- Materialization: view
--
-- Definition of done
--   [ ] Dates parsed from YYYYMMDD (a second date macro, dispatched like parse_mdy_date).
--   [ ] `is_generic` derived from marketing category (ANDA, NDA AUTHORIZED GENERIC, ...). Document the rule.
--   [ ] unique + not_null on productid; accepted_values on product type.
--
-- Hints
--   * Explore distinct marketingcategoryname values before deciding the brand/generic rule.
--   * This is the input to the FDA snapshot (snapshots/snap_fda__ndc_products.sql).
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================

{{ config(enabled=false) }}

select 1 as todo_replace_me
