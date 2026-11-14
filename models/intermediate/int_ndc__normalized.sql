-- ============================================================================
-- TODO: int_ndc__normalized
-- When:  Week 1, Sat Nov 21 (see PLAN.md)
-- ============================================================================
-- Goal
--   One conformed row per 11-digit package NDC seen in ANY source (NADAC, SDUD, FDA, CMS),
--   with FDA product attributes attached where they exist.
--
-- Grain:  one row per ndc_11
-- Inputs:
--   - stg_nadac__weekly
--   - stg_sdud__quarterly
--   - stg_fda_ndc__packages
--   - stg_fda_ndc__products
--   - stg_cms__negotiated_prices
-- Materialization: table
--
-- Definition of done
--   [ ] Flags: in_nadac, in_sdud, in_fda, is_mfp_selected_drug.
--   [ ] Match-rate query in analyses/: % of SDUD dollars whose NDC matches FDA, and % that match NADAC.
--   [ ] is_valid_ndc_11 passes; ndc_11 unique; documented why some NDCs never match (delisted products, etc.).
--
-- Hints
--   * FDA only lists currently marketed products; old NDCs in NADAC/SDUD may be missing. That's a finding, not a bug.
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================

{{ config(enabled=false) }}

select 1 as todo_replace_me
