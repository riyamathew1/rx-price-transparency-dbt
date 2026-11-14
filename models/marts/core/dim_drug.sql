-- ============================================================================
-- TODO: dim_drug
-- When:  Week 2, Sat Nov 28 (see PLAN.md)
-- ============================================================================
-- Goal
--   Drug dimension: ingredient x dosage form x strength, the level where brand and generic compete.
--
-- Grain:  one row per drug_key
-- Inputs:
--   - int_ndc__normalized
--   - stg_fda_ndc__products
-- Materialization: table, CONTRACT enforced
--
-- Definition of done
--   [ ] Model contract (contract: {enforced: true}) with data types and not_null constraints.
--   [ ] Every ndc_11 in int_ndc__normalized maps to exactly one drug_key (relationships + uniqueness tests).
--   [ ] Brand/generic counts per drug_key available for the event study.
--
-- Hints
--   * Normalize strength text ('5 MG' vs '5MG'); start from FDA substancename + dosageformname + strength.
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================

{{ config(enabled=false) }}

select 1 as todo_replace_me
