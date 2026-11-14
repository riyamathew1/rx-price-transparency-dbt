-- ============================================================================
-- TODO: snap_fda__ndc_products (dbt snapshot, SCD2)
-- When:  Week 2, Wed Nov 25 (see PLAN.md)
-- ============================================================================
-- Goal
--   Capture changes in FDA product attributes over time (names, marketing category, end dates).
--
-- Grain:  productid x dbt_valid_from
-- Inputs:
--   - stg_fda_ndc__products
-- Materialization: snapshot
--
-- Definition of done
--   [ ] strategy='check' on the attributes you care about (list them and say why).
--   [ ] Run it on two different days' FDA downloads and show at least one changed product.
--   [ ] Explain in the README how this differs from fct_nadac_price_history (observed vs reconstructed history).
--
-- Hints
--   * dbt 1.9+ snapshot configs: unique_key, strategy, check_cols, hard_deletes.
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================
{% snapshot snap_fda__ndc_products %}

{{ config(enabled=false, unique_key='todo', strategy='check', check_cols='all') }}

select 1 as todo

{% endsnapshot %}
