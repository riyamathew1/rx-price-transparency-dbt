-- ============================================================================
-- TODO: stg_fda_ndc__packages
-- When:  Week 1, Wed Nov 18 (see PLAN.md)
-- ============================================================================
-- Goal
--   One row per FDA package NDC, with the 10-digit hyphenated code AND its 11-digit form.
--
-- Grain:  one row per package NDC (ndcpackagecode)
-- Inputs:
--   - source('fda_ndc', 'package')
--   - macros/normalize_ndc_to_11.sql (you implement it on Tue Nov 17)
-- Materialization: view
--
-- Definition of done
--   [ ] `ndc_10_hyphenated` kept as delivered, `ndc_11` from normalize_ndc_to_11(), `ndc_layout` (4-4-2 / 5-3-2 / 5-4-1).
--   [ ] is_valid_ndc_11 (your custom generic test) passes on ndc_11; ndc_11 is unique.
--   [ ] relationships test: productid exists in stg_fda_ndc__products.
--
-- Hints
--   * Is ndc_11 really unique here? If not, find out why before you 'fix' it.
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================

{{ config(enabled=false) }}

select 1 as todo_replace_me
