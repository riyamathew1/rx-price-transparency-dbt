-- ============================================================================
-- TODO: snap_nadac__latest_rates (stretch: snapshot vs reconstruction)
-- When:  Week 2, Wed Nov 25 (stretch) (see PLAN.md)
-- ============================================================================
-- Goal
--   Snapshot the latest weekly NADAC rate per NDC, then compare with fct_nadac_price_history.
--
-- Grain:  ndc_11 x dbt_valid_from
-- Inputs:
--   - stg_nadac__weekly (latest as_of_date only)
-- Materialization: snapshot
--
-- Definition of done
--   [ ] A query that lists where the snapshot and the reconstructed SCD2 disagree, with an explanation.
--
-- Hints
--   * A snapshot only knows what it saw when it ran. NADAC lets you rebuild history from effective_date.
--
-- To start: delete `enabled=false` below, write the SQL, add a YAML entry with
-- description, tests (and a contract where noted), then `dbt build -s <this model>+`.
-- ============================================================================
{% snapshot snap_nadac__latest_rates %}

{{ config(enabled=false, unique_key='todo', strategy='check', check_cols='all') }}

select 1 as todo

{% endsnapshot %}
